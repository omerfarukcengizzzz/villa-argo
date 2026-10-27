extends CharacterBody3D
## Twin player. The owning peer simulates movement and replicates position/yaw
## to the other peer. Only the owner gets a camera, input and interaction.

const COLORS := {"jason": Color(0.25, 0.5, 0.9), "julia": Color(0.95, 0.55, 0.2)}
## Local clothes in Punt (book 2), while GameState flag "punt.disguised" is set.
const DISGUISED_COLORS := {"jason": Color(0.85, 0.8, 0.65), "julia": Color(0.9, 0.85, 0.7)}
const GRAVITY := 20.0
const MOUSE_SENS := 0.003
const STICK_LOOK_SPEED := 2.5
const CLIMB_SPEED := 3.0

var role := "jason"
var speed := 6.0
var jump_velocity := 7.0

var _pivot: Node3D
var _body_mat: StandardMaterial3D
var _camera: Camera3D


func _ready() -> void:
	_build_body()
	_build_sync()
	if is_multiplayer_authority():
		_build_camera()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	add_child(shape)

	var mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.8
	_body_mat = StandardMaterial3D.new()
	cm.material = _body_mat
	GameState.changed.connect(func(_key: String) -> void: _update_color())
	_update_color()
	mesh.mesh = cm
	add_child(mesh)

	# A nose so facing direction is visible on the other player's screen.
	var nose := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(0.2, 0.2, 0.3)
	nose.mesh = nm
	nose.position = Vector3(0, 0.5, -0.45)
	add_child(nose)


func _update_color() -> void:
	var colors := DISGUISED_COLORS if GameState.get_flag("punt.disguised", false) else COLORS
	_body_mat.albedo_color = colors.get(role, Color.WHITE)


func _build_sync() -> void:
	var cfg := SceneReplicationConfig.new()
	for prop in [^":position", ^":rotation:y"]:
		cfg.add_property(prop)
		cfg.property_set_replication_mode(prop, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.replication_config = cfg
	sync.set_multiplayer_authority(get_multiplayer_authority())
	add_child(sync)


func _build_camera() -> void:
	_pivot = Node3D.new()
	_pivot.position = Vector3(0, 0.8, 0)
	add_child(_pivot)
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 0.8, 4.5)
	_pivot.add_child(_camera)
	# Each twin's camera skips the other twin's private render layer.
	_camera.set_cull_mask_value(Vis.hidden_layer_for(role), false)
	_camera.make_current()


## Host-only call; used when moving between levels.
@rpc("any_peer", "call_local", "reliable")
func teleport(pos: Vector3, yaw: float) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	position = pos
	rotation.y = yaw
	velocity = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority() or Game.current.input_blocked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(-event.relative.x * MOUSE_SENS, -event.relative.y * MOUSE_SENS)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _look(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	_pivot.rotation.x = clampf(_pivot.rotation.x + pitch, -1.2, 0.6)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	var active := not Game.current.input_blocked

	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if active and stick != Vector2.ZERO:
		_look(-stick.x * STICK_LOOK_SPEED * delta, -stick.y * STICK_LOOK_SPEED * delta)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if active else Vector2.ZERO
	if is_climbing():
		velocity.y = -input.y * CLIMB_SPEED
	elif not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif active and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

	var level := Game.current.level_for(role)
	if level and global_position.y < level.fall_y:
		position = level.to_global(level.respawn_point(role, level.to_local(global_position)))
		velocity = Vector3.ZERO
		Game.current.announce_fall.rpc(role)
	for hazard in get_tree().get_nodes_in_group("hazards"):
		if hazard.contains(global_position):
			var at: Level = hazard.get_parent()
			position = at.to_global(hazard.respawn)
			velocity = Vector3.ZERO
			Game.current.show_message(hazard.message)
			break

	_update_focus(active)


## Only Jason climbs: inside a climb zone while touching the wall or already
## off the ground (so standing on top of a climbable crate is just standing).
func is_climbing() -> bool:
	if role != "jason" or (is_on_floor() and not is_on_wall()):
		return false
	for zone in get_tree().get_nodes_in_group("climbables"):
		if zone.contains(global_position):
			return true
	return false


## Shows a prompt for the nearest interactable this twin may use, and asks the
## host to use it on interact.
func _update_focus(active: bool) -> void:
	var best: Interactable = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("interactables"):
		var it := node as Interactable
		if not it.allows(role) or not it.is_available():
			continue
		var d := global_position.distance_to(it.global_position)
		if d <= it.reach and d < best_d:
			best = it
			best_d = d
	Game.current.show_prompt("[E] / (X) " + best.prompt if best and active else "")
	if best and active and Input.is_action_just_pressed("interact"):
		best.request()
