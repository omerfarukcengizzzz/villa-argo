class_name Helm
extends CodeEntry
## A ship's helm: using it offers a list of destinations instead of a text box.
## The right one (`answer`) only counts while both twins are aboard, within
## `aboard_radius`.

## [label, enabled] pairs; see Game.ask_choice.
var options: Array = []
@export var aboard_radius := 7.0


func _init() -> void:
	prompt = "Take the helm"
	who = "jason"
	reach = 1.6


func _build() -> void:
	var wheel := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.45
	wheel.mesh = torus
	wheel.rotation_degrees.x = 90
	wheel.material_override = Vis.material(Color(0.45, 0.3, 0.15))
	add_child(wheel)


func request() -> void:
	Game.current.ask_choice(question, options, submit)


func _handle_answer(peer_id: int, text: String) -> void:
	var aboard := Game.current.get_players().all(
		func(p: Node3D) -> bool: return p.global_position.distance_to(global_position) <= aboard_radius)
	if Game.current.get_players().size() < 2 or not aboard:
		Game.current.say("Wait. Julia isn't aboard yet.", "jason")
		return
	super(peer_id, text)
