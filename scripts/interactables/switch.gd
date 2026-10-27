class_name Switch
extends Interactable
## The simplest interactable: using it sets GameState `flag` (once). For hiding
## places, levers, bells: anything whose effect the level or a condition
## handles. With `size` non-zero it's drawn as a box; otherwise it's invisible.

@export var flag := ""
@export var size := Vector3.ZERO
@export var color := Color(0.5, 0.5, 0.5)


func _available() -> bool:
	return not GameState.get_flag(flag, false)


func _build() -> void:
	if size == Vector3.ZERO:
		return
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = Vis.material(color)
	add_child(mesh)


func _host_interact(_player: Node3D) -> void:
	GameState.set_flag(flag)
