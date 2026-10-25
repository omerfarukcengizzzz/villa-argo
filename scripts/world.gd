extends Node3D
## Gray-box room. The host is authoritative for spawning players.
## The client announces it has loaded this scene; only then does the host spawn
## both twins, so spawn packets never arrive before the client's spawner exists.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var _players: Node3D
var _spawner: MultiplayerSpawner
var _hud: Label
var _puzzle: Node3D


func _ready() -> void:
	_build_room()

	_players = Node3D.new()
	_players.name = "Players"
	add_child(_players)

	_spawner = MultiplayerSpawner.new()
	_spawner.name = "Spawner"
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(_players)
	_spawner.spawn_function = _spawn_player

	_puzzle = preload("res://scripts/puzzle.gd").new()
	_puzzle.name = "Puzzle"
	add_child(_puzzle)

	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	var layer := CanvasLayer.new()
	layer.add_child(_hud)
	add_child(layer)

	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if multiplayer.is_server():
		_hud.text = "Hosting. Waiting for Julia to join..."
	else:
		_hud.text = "You are Julia."
		_client_ready.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _client_ready() -> void:
	if not multiplayer.is_server():
		return
	var client_id := multiplayer.get_remote_sender_id()
	if _players.has_node(str(client_id)):
		return
	if not _players.has_node(str(1)):
		_spawner.spawn({"id": 1, "role": "jason", "pos": Vector3(-1.5, 1.0, 0)})
	_spawner.spawn({"id": client_id, "role": "julia", "pos": Vector3(1.5, 1.0, 0)})
	_puzzle.host_start()
	_hud.text = "You are Jason. Julia joined."


## Runs on every peer with the same data, so the player node is identical everywhere.
func _spawn_player(data: Dictionary) -> Node:
	var p := PLAYER_SCENE.instantiate()
	p.name = str(data["id"])
	p.role = data["role"]
	p.position = data["pos"]
	p.set_multiplayer_authority(data["id"])
	return p


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var p := _players.get_node_or_null(str(id))
		if p:
			p.queue_free()
		_hud.text = "Julia left. Waiting for her to rejoin..."


func _on_server_disconnected() -> void:
	Net.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _build_room() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.15, 0.17, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	_add_box(Vector3(20, 0.5, 20), Vector3(0, -0.25, 0), Color(0.55, 0.55, 0.55))
	# North wall has a gap (x -1.5..1.5) that the puzzle door fills.
	_add_box(Vector3(8.5, 4, 0.5), Vector3(-5.75, 2, -10), Color(0.4, 0.4, 0.45))
	_add_box(Vector3(8.5, 4, 0.5), Vector3(5.75, 2, -10), Color(0.4, 0.4, 0.45))
	_add_box(Vector3(3, 0.5, 4), Vector3(0, -0.25, -12), Color(0.8, 0.7, 0.3))
	_add_box(Vector3(20, 4, 0.5), Vector3(0, 2, 10), Color(0.4, 0.4, 0.45))
	_add_box(Vector3(0.5, 4, 20), Vector3(-10, 2, 0), Color(0.4, 0.4, 0.45))
	_add_box(Vector3(0.5, 4, 20), Vector3(10, 2, 0), Color(0.4, 0.4, 0.45))
	# Stairs up to the button panel (Jason's climb).
	_add_box(Vector3(3, 1, 3), Vector3(4, 0.5, -4), Color(0.6, 0.5, 0.35))
	_add_box(Vector3(3, 2, 3), Vector3(7, 1, -4), Color(0.6, 0.5, 0.35))
	# Top step, beside the button panel on the east wall.
	_add_box(Vector3(2.5, 3, 3.5), Vector3(8.5, 1.5, -7.25), Color(0.6, 0.5, 0.35))


func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	box.material = mat
	mesh.mesh = box
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	add_child(body)
