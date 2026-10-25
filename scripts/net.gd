extends Node
## Autoload "Net": connection setup and shared input map.
## Host is peer 1 and plays Jason; the joining client plays Julia.

const PORT := 7777
const MAX_CLIENTS := 1


func _ready() -> void:
	_register_input()


func host() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func join(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func disconnect_from_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null


func _register_input() -> void:
	_add_action("move_forward", KEY_W, JOY_AXIS_LEFT_Y, -1.0)
	_add_action("move_back", KEY_S, JOY_AXIS_LEFT_Y, 1.0)
	_add_action("move_left", KEY_A, JOY_AXIS_LEFT_X, -1.0)
	_add_action("move_right", KEY_D, JOY_AXIS_LEFT_X, 1.0)
	_add_action("look_up", KEY_UP, JOY_AXIS_RIGHT_Y, -1.0)
	_add_action("look_down", KEY_DOWN, JOY_AXIS_RIGHT_Y, 1.0)
	_add_action("look_left", KEY_LEFT, JOY_AXIS_RIGHT_X, -1.0)
	_add_action("look_right", KEY_RIGHT, JOY_AXIS_RIGHT_X, 1.0)

	_add_action("jump", KEY_SPACE)
	var jump_pad := InputEventJoypadButton.new()
	jump_pad.button_index = JOY_BUTTON_A
	InputMap.action_add_event("jump", jump_pad)

	_add_action("interact", KEY_E)
	var interact_pad := InputEventJoypadButton.new()
	interact_pad.button_index = JOY_BUTTON_X
	InputMap.action_add_event("interact", interact_pad)


func _add_action(action: String, key: Key, axis: JoyAxis = JOY_AXIS_INVALID, axis_value := 0.0) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	var k := InputEventKey.new()
	k.physical_keycode = key
	InputMap.action_add_event(action, k)
	if axis != JOY_AXIS_INVALID:
		var j := InputEventJoypadMotion.new()
		j.axis = axis
		j.axis_value = axis_value
		InputMap.action_add_event(action, j)
