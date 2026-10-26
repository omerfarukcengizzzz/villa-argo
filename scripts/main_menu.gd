extends Control
## Host / Join menu. UI is built in code to keep the scene file trivial.
## Command-line shortcuts (after "--", or per instance in Debug > Customize Run
## Instances): "--host" hosts, "--join=IP" joins. Used once per launch.

const GAME_SCENE := "res://scenes/game.tscn"

var _ip_field: LineEdit
var _host_button: Button
var _join_button: Button
var _status: Label

static var _autostarted := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_autostart.call_deferred()


func _autostart() -> void:
	if _autostarted:
		return
	_autostarted = true
	for arg in OS.get_cmdline_user_args():
		if arg == "--host":
			_on_host_pressed()
		elif arg.begins_with("--join="):
			_ip_field.text = arg.trim_prefix("--join=")
			_on_join_pressed()


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "Villa Argo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)

	_host_button = Button.new()
	_host_button.text = "Host (play Jason)"
	_host_button.pressed.connect(_on_host_pressed)
	box.add_child(_host_button)

	_ip_field = LineEdit.new()
	_ip_field.placeholder_text = "Host IP (Tailscale), e.g. 100.x.y.z"
	_ip_field.text = "127.0.0.1"
	box.add_child(_ip_field)

	_join_button = Button.new()
	_join_button.text = "Join (play Julia)"
	_join_button.pressed.connect(_on_join_pressed)
	box.add_child(_join_button)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)


func _on_host_pressed() -> void:
	var err := Net.host()
	if err != OK:
		_status.text = "Could not host (error %d)" % err
		return
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_join_pressed() -> void:
	var ip := _ip_field.text.strip_edges()
	if ip.is_empty():
		_status.text = "Enter the host's IP."
		return
	var err := Net.join(ip)
	if err != OK:
		_status.text = "Could not join (error %d)" % err
		return
	_set_busy(true)
	_status.text = "Connecting to %s..." % ip


func _on_connected() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_connection_failed() -> void:
	Net.disconnect_from_game()
	_set_busy(false)
	_status.text = "Connection failed."


func _set_busy(busy: bool) -> void:
	_host_button.disabled = busy
	_join_button.disabled = busy
	_ip_field.editable = not busy
