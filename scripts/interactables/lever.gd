class_name Lever
extends Interactable
## A lever or valve with two positions. Each use flips GameState `flag`
## (false/true, shown as `off_text`/`on_text` on its label), unless the
## condition `stuck_when` holds: then it says `stuck_text` to that twin instead.

@export var flag := ""
@export var off_text := "LEFT"
@export var on_text := "RIGHT"
@export var stuck_when := ""
@export var stuck_text := "It won't budge."
@export var color := Color(0.75, 0.15, 0.12)

var _pivot: Node3D
var _label: Label3D


func _init() -> void:
	prompt = "Pull the lever"
	reach = 1.6


func _build() -> void:
	var base := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.4, 0.2, 0.4)
	base.mesh = b
	base.material_override = Vis.material(Color(0.25, 0.25, 0.27))
	add_child(base)
	_pivot = Node3D.new()
	add_child(_pivot)
	var stick := MeshInstance3D.new()
	var s := BoxMesh.new()
	s.size = Vector3(0.08, 0.8, 0.08)
	stick.mesh = s
	stick.position.y = 0.4
	stick.material_override = Vis.material(color)
	_pivot.add_child(stick)
	_label = Label3D.new()
	_label.position = Vector3(0, 1.1, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	add_child(_label)


func refresh() -> void:
	var on: bool = GameState.get_flag(flag, false)
	_pivot.rotation.z = -0.5 if on else 0.5
	_label.text = on_text if on else off_text


func _host_interact(player: Node3D) -> void:
	if stuck_when != "" and GameState.check(stuck_when):
		Game.current.say(stuck_text, player.role)
		return
	GameState.set_flag(flag, not GameState.get_flag(flag, false))
