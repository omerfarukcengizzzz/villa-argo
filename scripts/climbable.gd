class_name Climbable
extends Node3D
## A box-shaped zone Jason can climb in: while he's inside, forward moves him up,
## back moves him down, and gravity is off. It reaches a little above the
## climbable surface so he can step off onto the top. Julia ignores it.
## Not rotated; `size` is in world axes.

@export var size := Vector3.ONE


func _enter_tree() -> void:
	add_to_group("climbables")


func contains(point: Vector3) -> bool:
	var d := (point - global_position).abs()
	return d.x <= size.x / 2.0 and d.y <= size.y / 2.0 and d.z <= size.z / 2.0
