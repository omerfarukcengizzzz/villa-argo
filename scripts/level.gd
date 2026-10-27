class_name Level
extends Node3D
## Base for gray-box levels built in code. Game loads one level at a time on
## every peer (same node names everywhere, so interactable RPCs line up).
## Levels must not keep state of their own: anything that changes goes in
## GameState, so the level can be rebuilt on a rejoin or a return visit.

## entry name -> {"jason": Vector3, "julia": Vector3, "yaw": float (radians)}
var entries := {}
## A twin below this height has fallen and is put back at respawn_point().
var fall_y := -40.0
## Where Game places this level. Levels that can be loaded at the same time
## (one twin in each, see Game) need origins far enough apart not to overlap.
## Keep origins horizontal (y = 0) so fall_y still works. Set it in _init().
var origin := Vector3.ZERO
## This level's lighting; the camera of a twin in this level uses it.
var environment: Environment:
	get:
		return _env

var _env: Environment
var _sun: DirectionalLight3D
var _day_background := Color.BLACK


func _ready() -> void:
	_build()
	if multiplayer.is_server():
		_host_setup()


## An unloaded level is only freed at the end of the frame; until then it must
## not react to state changes (it's out of the tree: no multiplayer, no tweens).
func _exit_tree() -> void:
	for c in GameState.changed.get_connections():
		var target: Object = c["callable"].get_object()
		if target == self or (target is Node and is_ancestor_of(target)):
			GameState.changed.disconnect(c["callable"])


## Override: build geometry and interactables. Runs on every peer.
func _build() -> void:
	pass


## Override: host-only first-visit setup (e.g. pick a random puzzle answer).
## Guard with GameState checks; it runs on every visit.
func _host_setup() -> void:
	pass


func spawn_point(role: String, entry: String) -> Vector3:
	return _entry(entry).get(role, Vector3(0, 1, 0))


func spawn_yaw(entry: String) -> float:
	return _entry(entry).get("yaw", 0.0)


## Override for safe spots near the drop (e.g. the top of a cliff path).
## Positions here, in spawn_point and in entries are local to the level.
func respawn_point(role: String, _fell_from: Vector3) -> Vector3:
	return spawn_point(role, "default")


func _entry(entry: String) -> Dictionary:
	return entries.get(entry, entries.get("default", {}))


func add_environment(background: Color) -> void:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = background
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	_env = e
	_day_background = background

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-55, 30, 0)
	_sun.shadow_enabled = true
	add_child(_sun)


func set_night(night: bool) -> void:
	_env.background_color = Color(0.02, 0.03, 0.08) if night else _day_background
	_env.ambient_light_color = Color(0.12, 0.14, 0.25) if night else Color(0.6, 0.6, 0.65)
	_sun.light_energy = 0.15 if night else 1.0


func add_box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = Vis.material(color)
	mesh.mesh = box
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	add_child(body)
	return body


## A slope rising along -z (north) by `rise` over its length, for stairs.
func add_ramp(width: float, length: float, rise: float, start: Vector3, color: Color) -> StaticBody3D:
	var run := sqrt(length * length + rise * rise)
	var body := add_box(Vector3(width, 0.3, run), start + Vector3(0, rise / 2.0, -length / 2.0), color)
	body.rotation.x = atan2(rise, length)
	return body


## A climbable wall: a solid box plus a slightly larger Climbable zone that also
## reaches past the top, so Jason can climb up and step off.
func add_climb_wall(size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := add_box(size, pos, Color(0.3, 0.5, 0.25))
	var zone := Climbable.new()
	zone.size = size + Vector3(1.0, 1.4, 1.0)
	zone.position = pos + Vector3(0, 0.7, 0)
	add_child(zone)
	return body


## Host: whether `watcher` (facing its local -z) can see `target`: within
## `radius`, inside a cone of `fov_degrees`, and not behind a wall. For
## patrolling guards and dogs.
func sees(watcher: Node3D, target: Node3D, radius: float, fov_degrees := 120.0) -> bool:
	var to := target.global_position - watcher.global_position
	to.y = 0.0
	if to.length() > radius:
		return false
	if to.length() < 1.0:
		return true
	var forward := -watcher.global_transform.basis.z
	forward.y = 0.0
	if fov_degrees < 360.0 and rad_to_deg(forward.normalized().angle_to(to.normalized())) > fov_degrees / 2.0:
		return false
	var ray := PhysicsRayQueryParameters3D.create(watcher.global_position + Vector3.UP * 0.5, target.global_position + Vector3.UP * 0.5)
	for p in Game.current.get_players():
		ray.exclude = ray.exclude + [p.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func add_label(text: String, pos: Vector3, yaw_degrees := 0.0) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.rotation_degrees.y = yaw_degrees
	label.font_size = 48
	add_child(label)
	return label


## Adds `node` named `node_name` at `pos`. Interactables need stable names so
## RPCs resolve to the same node on both peers.
func place(node: Node3D, node_name: String, pos: Vector3) -> Node3D:
	node.name = node_name
	node.position = pos
	add_child(node)
	return node
