class_name Mirror
extends Interactable
## A one-sided mirror on a stand. Each use turns it a quarter turn; its shiny
## front faces one of four diagonals. The level traces the light from it.
## GameState: "<puzzle>.m<index>" = facing (see NORMALS).

## Front normal per facing, in grid steps (x east, y = z south): NE, SE, SW, NW.
const NORMALS := [Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]

@export var puzzle := ""
@export var index := 0
## Facing before anyone has touched it.
@export var start_facing := 0

var _pivot: Node3D


func _init() -> void:
	prompt = "Turn the mirror"
	who = "jason"
	reach = 1.8


func facing() -> int:
	return GameState.get_flag("%s.m%d" % [puzzle, index], start_facing)


func _available() -> bool:
	return not GameState.get_flag(puzzle + ".solved", false)


func _build() -> void:
	_pivot = Node3D.new()
	add_child(_pivot)
	var front := MeshInstance3D.new()
	var f := BoxMesh.new()
	f.size = Vector3(1.4, 1.6, 0.06)
	front.mesh = f
	front.position.z = 0.04
	var shine := Vis.material(Color(0.85, 0.9, 0.95))
	shine.metallic = 1.0
	shine.roughness = 0.1
	front.material_override = shine
	_pivot.add_child(front)
	var back := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(1.5, 1.7, 0.08)
	back.mesh = b
	back.position.z = -0.04
	back.material_override = Vis.material(Color(0.25, 0.18, 0.1))
	_pivot.add_child(back)


func refresh() -> void:
	var n: Vector2i = NORMALS[facing()]
	var yaw := atan2(float(n.x), float(n.y))
	if is_node_ready():
		create_tween().tween_property(_pivot, "rotation:y", yaw, 0.25)
	else:
		_pivot.rotation.y = yaw


func _host_interact(_player: Node3D) -> void:
	GameState.set_flag("%s.m%d" % [puzzle, index], (facing() + 1) % 4)
