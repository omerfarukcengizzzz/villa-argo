class_name ChoicePoint
extends Interactable
## Something that offers a list of choices on the user's screen (where to move
## a chess piece, which lever to pull...). `options_for` builds the
## [label, enabled] list on the asking peer from GameState; the chosen label
## goes to the host, which validates the twin and calls `on_choice(player,
## label)`. No mesh of its own: the level draws whatever it stands for.

var question := ""
var options_for := Callable()
var on_choice := Callable()


func _init() -> void:
	prompt = "Choose"
	reach = 1.6


func request() -> void:
	Game.current.ask_choice(question, options_for.call(), submit)


func submit(choice: String) -> void:
	if multiplayer.is_server():
		_choose(multiplayer.get_unique_id(), choice)
	else:
		_submit.rpc_id(1, choice)


@rpc("any_peer", "call_remote", "reliable")
func _submit(choice: String) -> void:
	if multiplayer.is_server():
		_choose(multiplayer.get_remote_sender_id(), choice)


func _choose(peer_id: int, choice: String) -> void:
	var player := _validate(peer_id)
	if player and on_choice.is_valid():
		on_choice.call(player, choice)
