class_name Npc
extends Interactable
## A character the twins can talk to (gray-box: a capsule with a name tag).
## `lines` is a list of [condition, text]; talking says the last line whose
## GameState condition holds, so later story states override earlier ones.
## `present` is the condition for the character to be here at all, and
## `stations` ([condition, position] pairs, last match wins) moves them along
## as the story goes on.
## Story effects of talking go in `on_used` (runs after the line is chosen).

@export var npc_name := ""
@export var color := Color(0.5, 0.65, 0.4)
@export var present := ""

var lines: Array = []
var stations: Array = []


func _init() -> void:
	prompt = "Talk"
	reach = 2.2


func _available() -> bool:
	return GameState.check(present)


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.8
	mesh.mesh = cm
	mesh.material_override = Vis.material(color)
	add_child(mesh)
	var tag := Label3D.new()
	tag.text = npc_name
	tag.position.y = 1.3
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 40
	add_child(tag)


func refresh() -> void:
	visible = GameState.check(present)
	for station in stations:
		if GameState.check(station[0]):
			position = station[1]


func current_line() -> String:
	var text := ""
	for line in lines:
		if GameState.check(line[0]):
			text = line[1]
	return text


func _host_interact(_player: Node3D) -> void:
	var text := current_line()
	if text != "":
		Game.current.say("%s: %s" % [npc_name, text])
