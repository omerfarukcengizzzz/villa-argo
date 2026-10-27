class_name Game
extends Node
## Session root, alive from Host/Join until returning to the menu. Owns the
## twins (Players + MultiplayerSpawner), the current level and the HUD.
## The host decides which level is loaded and tells every peer (`_load_level`);
## twins persist across levels and are teleported to the level's entry point.
## The client announces it has loaded this scene; only then does the host send
## the state snapshot and level and spawn both twins, so nothing arrives before
## the client is ready for it.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const START_LEVEL := "res://scenes/levels/sandbox_puzzle_room.tscn"
const TOAST_SECONDS := 3.0

static var current: Game

## True while a menu (journal) has focus; players ignore movement input.
var input_blocked := false

var level: Level
var _level_path := ""
var _entry := "default"
var _players: Node3D
var _spawner: MultiplayerSpawner
var _status: Label
var _prompt: Label
var _toast: Label
var _toast_left := 0.0
var _journal: JournalUI


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	_players = Node3D.new()
	_players.name = "Players"
	add_child(_players)

	_spawner = MultiplayerSpawner.new()
	_spawner.name = "Spawner"
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(_players)
	_spawner.spawn_function = _spawn_player

	_build_hud()

	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if multiplayer.is_server():
		GameState.reset()
		_load_level(START_LEVEL, "default")
		_status.text = "Hosting. Waiting for Julia to join..."
	else:
		_status.text = "You are Julia."
		_client_ready.rpc_id(1)


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		_set_journal_open(not _journal.visible)
	elif _journal.visible and event.is_action_pressed("ui_cancel"):
		_set_journal_open(false)


func get_player(peer_id: int) -> Node3D:
	return _players.get_node_or_null(str(peer_id))


func get_players() -> Array[Node]:
	return _players.get_children()


func show_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = text != ""


## Host: show `text` to both twins, or only to `who` ("jason" / "julia").
func say(text: String, who := "both") -> void:
	_toast_rpc.rpc(text, who)


## Host: move both twins to another level.
func change_level(path: String, entry := "default") -> void:
	assert(multiplayer.is_server())
	_load_level.rpc(path, entry)
	for p in get_players():
		p.teleport.rpc(level.spawn_point(p.role, entry), level.spawn_yaw(entry))


@rpc("authority", "call_local", "reliable")
func _load_level(path: String, entry: String) -> void:
	if level:
		remove_child(level)
		level.queue_free()
	_level_path = path
	_entry = entry
	level = load(path).instantiate()
	level.name = "Level"
	add_child(level)


@rpc("authority", "call_local", "reliable")
func _toast_rpc(text: String, who: String) -> void:
	if who == "both" or who == Net.my_role():
		_show_local_toast(text)


@rpc("any_peer", "call_remote", "reliable")
func _client_ready() -> void:
	if not multiplayer.is_server():
		return
	var client_id := multiplayer.get_remote_sender_id()
	if _players.has_node(str(client_id)):
		return
	GameState.send_snapshot(client_id)
	_load_level.rpc_id(client_id, _level_path, _entry)
	if not _players.has_node(str(1)):
		_spawn("jason", 1)
	_spawn("julia", client_id)
	_status.text = "You are Jason. Julia joined."


func _spawn(role: String, peer_id: int) -> void:
	_spawner.spawn({
		"id": peer_id,
		"role": role,
		"pos": level.spawn_point(role, _entry),
		"yaw": level.spawn_yaw(_entry),
	})


## Runs on every peer with the same data, so the player node is identical everywhere.
func _spawn_player(data: Dictionary) -> Node:
	var p := PLAYER_SCENE.instantiate()
	p.name = str(data["id"])
	p.role = data["role"]
	p.position = data["pos"]
	p.rotation.y = data["yaw"]
	p.set_multiplayer_authority(data["id"])
	return p


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var p := get_player(id)
		if p:
			p.queue_free()
		_status.text = "Julia left. Waiting for her to rejoin..."


func _on_server_disconnected() -> void:
	Net.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _set_journal_open(open: bool) -> void:
	_journal.visible = open
	input_blocked = open
	if open:
		_journal.refresh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	_status = Label.new()
	_status.position = Vector2(12, 8)
	layer.add_child(_status)

	var hint := Label.new()
	hint.text = "[J] / (Back) Journal"
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hint.position.x -= 170
	hint.position.y += 8
	layer.add_child(hint)

	_prompt = Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position.y -= 80
	_prompt.visible = false
	layer.add_child(_prompt)

	_toast = Label.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.position.y += 40
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_toast)

	_journal = JournalUI.new()
	_journal.visible = false
	_journal.entry_added.connect(func() -> void: _show_local_toast("Journal updated. Press [J] / (Back)."))
	layer.add_child(_journal)


func _show_local_toast(text: String) -> void:
	_toast.text = text
	_toast_left = TOAST_SECONDS
	_toast.modulate.a = 1.0
