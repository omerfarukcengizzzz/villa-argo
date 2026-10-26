class_name Interactable
extends Node3D
## Something a twin can use with the interact button. The owning player picks
## the nearest available one in reach and calls request(); the host validates
## who pressed it and from where, then calls _host_interact(). Subclasses change
## GameState there and redraw from GameState in refresh(), which runs on every
## peer whenever state changes.

## Shown as "[E] / (X) <prompt>".
@export var prompt := "Use"
## "both", "jason" or "julia".
@export var who := "both"
@export var reach := 1.6

## Extra distance the host allows, since it sees the other twin slightly late.
const LAG_TOLERANCE := 1.5


func _enter_tree() -> void:
	add_to_group("interactables")


func _ready() -> void:
	GameState.changed.connect(func(_key: String) -> void: refresh())
	_build()
	refresh()


func allows(role: String) -> bool:
	return who == "both" or who == role


## Override: false hides the prompt (already used, locked behind something...).
func is_available() -> bool:
	return true


## Override: create meshes and collision. Runs once on every peer.
func _build() -> void:
	pass


## Override: update visuals from GameState. Runs on every peer.
func refresh() -> void:
	pass


## Override: host-only reaction to a validated press.
func _host_interact(_player: Node3D) -> void:
	pass


func request() -> void:
	if multiplayer.is_server():
		_handle(multiplayer.get_unique_id())
	else:
		_request.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _request() -> void:
	if multiplayer.is_server():
		_handle(multiplayer.get_remote_sender_id())


func _handle(peer_id: int) -> void:
	var player := Game.current.get_player(peer_id)
	if player == null or not allows(player.role) or not is_available():
		return
	if player.global_position.distance_to(global_position) > reach + LAG_TOLERANCE:
		return
	_host_interact(player)
