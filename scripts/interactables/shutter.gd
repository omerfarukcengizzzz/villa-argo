class_name Shutter
extends Interactable
## A window someone can shut (book 2: Julia against Manfred in the storm).
## Open while GameState flag `closed_flag` is unset; using it sets the flag.
## Something else (the level) may clear the flag to blow it open again.

@export var closed_flag := ""
@export var size := Vector3(1.4, 1.4, 0.15)

var _glass: MeshInstance3D
var _boards: MeshInstance3D


func _init() -> void:
	prompt = "Shut the window"
	reach = 1.8


func _available() -> bool:
	return not GameState.get_flag(closed_flag, false)


func _build() -> void:
	_glass = MeshInstance3D.new()
	var g := BoxMesh.new()
	g.size = size
	_glass.mesh = g
	var glass := Vis.material(Color(0.55, 0.7, 0.9, 0.5))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.material_override = glass
	add_child(_glass)
	_boards = MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size + Vector3(0.1, 0.1, 0.05)
	_boards.mesh = b
	_boards.material_override = Vis.material(Color(0.35, 0.22, 0.12))
	add_child(_boards)


func refresh() -> void:
	var closed: bool = GameState.get_flag(closed_flag, false)
	_boards.visible = closed
	_glass.visible = not closed


func _host_interact(_player: Node3D) -> void:
	GameState.set_flag(closed_flag)
