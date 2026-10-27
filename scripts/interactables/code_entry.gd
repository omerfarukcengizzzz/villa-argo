class_name CodeEntry
extends Interactable
## Something a twin types an answer into (a decoded word, a combination).
## Using it opens a text box on that twin's screen; the answer goes to the host,
## which compares it to `answer` (letters and digits only, case ignored).
## Right sets `solved_flag`; story effects go in `on_used`, as with any
## interactable.

@export var answer := ""
@export var solved_flag := ""
@export var question := "Your answer:"
@export var wrong_text := "That doesn't make sense yet."
@export var size := Vector3(0.8, 0.15, 0.6)
@export var color := Color(0.35, 0.22, 0.12)


func _init() -> void:
	prompt = "Write an answer"


func _available() -> bool:
	return not GameState.get_flag(solved_flag, false)


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = Vis.material(color)
	add_child(mesh)


## Opens the text box locally instead of asking the host straight away.
func request() -> void:
	Game.current.ask_text(question, submit)


func submit(text: String) -> void:
	if multiplayer.is_server():
		_handle_answer(multiplayer.get_unique_id(), text)
	else:
		_submit.rpc_id(1, text)


@rpc("any_peer", "call_remote", "reliable")
func _submit(text: String) -> void:
	if multiplayer.is_server():
		_handle_answer(multiplayer.get_remote_sender_id(), text)


## Host; override to add checks before the answer is compared.
func _handle_answer(peer_id: int, text: String) -> void:
	var player := _validate(peer_id)
	if player == null:
		return
	if _normalize(text) == _normalize(answer):
		GameState.set_flag(solved_flag)
		if on_used.is_valid():
			on_used.call(player)
	else:
		Game.current.say(wrong_text, player.role)


static func _normalize(text: String) -> String:
	var out := ""
	for c in text.to_upper():
		if (c >= "A" and c <= "Z") or (c >= "0" and c <= "9"):
			out += c
	return out
