class_name Dial
extends Interactable
## A hand on a dial (a clock hand, a combination wheel). Each use moves it one
## step clockwise as seen from the front (+z). GameState: `flag` = 0..steps-1.
## The level checks the combination it cares about.

@export var flag := ""
@export var steps := 12
@export var length := 0.8
@export var width := 0.08
@export var color := Color(0.15, 0.12, 0.1)

var _pivot: Node3D


func _init() -> void:
	prompt = "Turn the hand"
	reach = 1.8


func value() -> int:
	return GameState.get_flag(flag, 0)


func _build() -> void:
	_pivot = Node3D.new()
	add_child(_pivot)
	var hand := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(width, length, 0.04)
	hand.mesh = b
	hand.position.y = length / 2.0
	hand.material_override = Vis.material(color)
	_pivot.add_child(hand)


func refresh() -> void:
	_pivot.rotation.z = -TAU * value() / float(steps)


func _host_interact(_player: Node3D) -> void:
	GameState.set_flag(flag, (value() + 1) % steps)
