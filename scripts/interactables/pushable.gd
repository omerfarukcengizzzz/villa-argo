class_name Pushable
extends Interactable
## Heavy furniture (gray-box box) that one push slides by `offset` once
## `moved_flag` is set. Jason's job by default.

@export var size := Vector3(1, 2, 1)
@export var offset := Vector3(0, 0, 2)
@export var moved_flag := ""
@export var color := Color(0.4, 0.28, 0.18)

var _body: StaticBody3D
var _moved := false


func _init() -> void:
	prompt = "Push"
	who = "jason"
	reach = 1.8


func _available() -> bool:
	return not GameState.get_flag(moved_flag, false)


func _build() -> void:
	_body = StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = Vis.material(color)
	_body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	_body.add_child(shape)
	add_child(_body)


func refresh() -> void:
	if _moved or not GameState.get_flag(moved_flag, false):
		return
	_moved = true
	if is_node_ready():
		create_tween().tween_property(_body, "position", offset, 1.2)
	else:
		_body.position = offset


func _host_interact(_player: Node3D) -> void:
	GameState.set_flag(moved_flag)
