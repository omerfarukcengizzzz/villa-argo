class_name Level
extends Node3D
## Base for gray-box levels built in code. Game loads one level at a time on
## every peer (same node names everywhere, so interactable RPCs line up).
## Levels must not keep state of their own: anything that changes goes in
## GameState, so the level can be rebuilt on a rejoin or a return visit.

## entry name -> {"jason": Vector3, "julia": Vector3, "yaw": float (radians)}
var entries := {}


func _ready() -> void:
	_build()
	if multiplayer.is_server():
		_host_setup()


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


func _entry(entry: String) -> Dictionary:
	return entries.get(entry, entries.get("default", {}))


func add_environment(background: Color) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = background
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)


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
