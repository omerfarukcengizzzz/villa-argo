class_name Game
extends Node
## Session root, alive from Host/Join until returning to the menu. Owns the
## twins (Players + MultiplayerSpawner), the loaded levels and the HUD.
## The host decides which level each twin is in and tells every peer
## (`_set_where`). Usually both share one level; when the story splits them
## (book 2), each twin is in a different level. The host keeps every occupied
## level loaded so it can validate and own all state; Julia's machine loads only
## hers. Levels sit at their own `origin`, so two can be loaded at once without
## overlapping. Twins persist across levels and are teleported to entry points.
## The client announces it has loaded this scene; only then does the host send
## the state snapshot and levels and spawn both twins, so nothing arrives before
## the client is ready for it.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const START_LEVEL := "res://scenes/levels/villa_argo.tscn"
const TOAST_SECONDS := 5.0
const MAX_TOASTS := 3

static var current: Game

## True while a menu (journal, text box) has focus; players ignore movement input.
var input_blocked := false

## The level this peer's twin is in.
var level: Level:
	get:
		return level_for(Net.my_role())
## role -> level path, and role -> the entry point it arrived at.
var _where := {"jason": "", "julia": ""}
var _entries := {"jason": "default", "julia": "default"}
## level path -> loaded Level
var _levels := {}
var _players: Node3D
var _spawner: MultiplayerSpawner
var _status: Label
var _prompt: Label
var _toast: Label
## Recent messages, oldest first: [text, seconds left].
var _toasts: Array = []
var _journal: JournalUI
var _ask: PanelContainer
var _ask_label: Label
var _ask_field: LineEdit
var _ask_callback := Callable()
var _choice: PanelContainer
var _choice_box: VBoxContainer


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
		_set_where({"jason": START_LEVEL, "julia": START_LEVEL})
		_status.text = "Hosting. Waiting for Julia to join..."
	else:
		_status.text = "You are Julia."
		_client_ready.rpc_id(1)


func _process(delta: float) -> void:
	# Each level has its own lighting; this peer's camera uses its twin's level.
	var cam := get_viewport().get_camera_3d()
	if cam and level and cam.environment != level.environment:
		cam.environment = level.environment
	if _toasts.is_empty():
		return
	for t in _toasts:
		t[1] -= delta
	if _toasts[0][1] <= 0.0:
		_toasts.pop_front()
		_update_toast()


func _unhandled_input(event: InputEvent) -> void:
	if _ask.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_ask("")
		return
	if _choice.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_choice()
		return
	if event.is_action_pressed("journal"):
		_set_journal_open(not _journal.visible)
	elif _journal.visible and event.is_action_pressed("ui_cancel"):
		_set_journal_open(false)


func level_for(role: String) -> Level:
	return _levels.get(_where.get(role, ""))


## True when both twins are in the same level.
func together() -> bool:
	return _where["jason"] == _where["julia"]


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


## Opens a text box on this peer's screen; `callback` gets the text on submit.
func ask_text(question: String, callback: Callable) -> void:
	if _journal.visible:
		return
	_ask_label.text = question
	_ask_field.text = ""
	_ask_callback = callback
	_ask.visible = true
	input_blocked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ask_field.grab_focus()


## Opens a list of choices on this peer's screen. `options` are
## [label, enabled] pairs; `callback` gets the chosen label.
func ask_choice(question: String, options: Array, callback: Callable) -> void:
	if _journal.visible or _ask.visible:
		return
	for child in _choice_box.get_children():
		child.queue_free()
	var label := Label.new()
	label.text = question
	_choice_box.add_child(label)
	var first: Button = null
	for option in options:
		var b := Button.new()
		b.text = option[0]
		b.disabled = not option[1]
		b.pressed.connect(func() -> void:
			_close_choice()
			callback.call(option[0]))
		_choice_box.add_child(b)
		if first == null and option[1]:
			first = b
	var cancel := Button.new()
	cancel.text = "Cancel (Esc)"
	cancel.pressed.connect(_close_choice)
	_choice_box.add_child(cancel)
	_choice.visible = true
	input_blocked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if first:
		first.grab_focus.call_deferred()


func _close_choice() -> void:
	_choice.visible = false
	input_blocked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _close_ask(text: String) -> void:
	_ask.visible = false
	input_blocked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if text.strip_edges() != "" and _ask_callback.is_valid():
		_ask_callback.call(text)
	_ask_callback = Callable()


## Sent by a twin's own peer after it fell and was put back at a safe spot.
@rpc("any_peer", "call_local", "reliable")
func announce_fall(role: String) -> void:
	_show_local_toast("%s slips, and scrambles back to safety." % role.capitalize())


## Host: move both twins to `path` (or within it, if they're already there).
func change_level(path: String, entry := "default") -> void:
	_move({"jason": path, "julia": path}, ["jason", "julia"], entry)


## Host: move only one twin, splitting them up or bringing them back together.
func move_twin(role: String, path: String, entry := "default") -> void:
	var where := _where.duplicate()
	where[role] = path
	_move(where, [role], entry)


func _move(where: Dictionary, roles: Array, entry: String) -> void:
	assert(multiplayer.is_server())
	for role in roles:
		_entries[role] = entry
	_set_where.rpc(where)
	for p in get_players():
		if roles.has(p.role):
			var l := level_for(p.role)
			p.teleport.rpc(l.to_global(l.spawn_point(p.role, entry)), l.spawn_yaw(entry))


## Loads the levels this peer needs and frees the rest. A level that stays
## occupied is kept as it is.
@rpc("authority", "call_local", "reliable")
func _set_where(where: Dictionary) -> void:
	_where = where
	var needed := {}
	if multiplayer.is_server():
		for role in where:
			needed[where[role]] = true
	else:
		needed[where["julia"]] = true
	for path in _levels.keys():
		if not needed.has(path):
			var old: Level = _levels[path]
			_levels.erase(path)
			remove_child(old)
			old.queue_free()
	for path in needed:
		if path != "" and not _levels.has(path):
			var l: Level = load(path).instantiate()
			l.name = "Level_" + path.get_file().get_basename()
			add_child(l)
			l.position = l.origin
			_levels[path] = l
	# The host's own view shows only Jason's level (the other stays loaded and solid).
	for path in _levels:
		_levels[path].visible = _levels[path] == level


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
	_set_where.rpc_id(client_id, _where)
	if not _players.has_node(str(1)):
		_spawn("jason", 1)
	_spawn("julia", client_id)
	_status.text = "You are Jason. Julia joined."


func _spawn(role: String, peer_id: int) -> void:
	var l := level_for(role)
	_spawner.spawn({
		"id": peer_id,
		"role": role,
		"pos": l.to_global(l.spawn_point(role, _entries[role])),
		"yaw": l.spawn_yaw(_entries[role]),
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
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.custom_minimum_size.x = 900
	layer.add_child(_toast)

	_ask = PanelContainer.new()
	_ask.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_ask.custom_minimum_size = Vector2(420, 0)
	_ask.position -= Vector2(210, 60)
	_ask.visible = false
	var box := VBoxContainer.new()
	_ask.add_child(box)
	_ask_label = Label.new()
	box.add_child(_ask_label)
	_ask_field = LineEdit.new()
	_ask_field.text_submitted.connect(_close_ask)
	box.add_child(_ask_field)
	var ok := Button.new()
	ok.text = "OK  (Enter)  /  Cancel (Esc)"
	ok.pressed.connect(func() -> void: _close_ask(_ask_field.text))
	box.add_child(ok)
	layer.add_child(_ask)

	_choice = PanelContainer.new()
	_choice.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_choice.custom_minimum_size = Vector2(420, 0)
	_choice.position -= Vector2(210, 80)
	_choice.visible = false
	_choice_box = VBoxContainer.new()
	_choice.add_child(_choice_box)
	layer.add_child(_choice)

	_journal = JournalUI.new()
	_journal.visible = false
	_journal.entry_added.connect(func() -> void: _show_local_toast("Journal updated. Press [J] / (Back)."))
	layer.add_child(_journal)


## Messages stack (newest last) so one doesn't hide another.
func _show_local_toast(text: String) -> void:
	_toasts.append([text, TOAST_SECONDS])
	if _toasts.size() > MAX_TOASTS:
		_toasts.pop_front()
	_update_toast()


func _update_toast() -> void:
	_toast.text = "\n".join(_toasts.map(func(t: Array) -> String: return t[0]))
