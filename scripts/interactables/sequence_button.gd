class_name SequenceButton
extends Interactable
## One of a set of plates, bells or buttons that must be struck in an order.
## Every press appends `symbol` to "<puzzle>.seq"; a wrong one clears it, and
## the full `solution` sets "<puzzle>.solved".

@export var puzzle := ""
@export var symbol := ""
var solution: Array = []


func _init() -> void:
	prompt = "Strike the plate"
	reach = 1.8


func _available() -> bool:
	return not GameState.get_flag(puzzle + ".solved", false)


func _build() -> void:
	var disc := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.45
	c.bottom_radius = 0.45
	c.height = 0.08
	disc.mesh = c
	disc.rotation_degrees.x = 90
	var bronze := Vis.material(Color(0.75, 0.5, 0.25))
	bronze.metallic = 0.8
	disc.material_override = bronze
	add_child(disc)
	var label := Label3D.new()
	label.text = symbol
	label.position = Vector3(0, -0.7, 0.05)
	label.font_size = 40
	add_child(label)


func _host_interact(_player: Node3D) -> void:
	var seq: String = GameState.get_flag(puzzle + ".seq", "")
	var struck := Array(seq.split(",", false))
	struck.append(symbol)
	if struck != solution.slice(0, struck.size()):
		GameState.set_flag(puzzle + ".seq", "")
		Game.current.say("BONG... the notes jar against each other, and die away. Nothing happens.")
	elif struck.size() == solution.size():
		GameState.set_flag(puzzle + ".seq", ",".join(struck))
		GameState.set_flag(puzzle + ".solved")
	else:
		GameState.set_flag(puzzle + ".seq", ",".join(struck))
		Game.current.say("BONG. A deep note hangs in the air: %s." % symbol)
