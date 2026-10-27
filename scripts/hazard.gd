class_name Hazard
extends Node3D
## Something a twin must not touch (book 2: snakes). Touching it puts the twin
## back at `respawn` (local to the level it's in) with `message`. It can swing
## back and forth along `travel` every `period` seconds. Each twin's own peer
## checks its own twin against what it sees, like falls. Not rotated.

@export var size := Vector3(1.2, 1.0, 1.2)
@export var respawn := Vector3.ZERO
@export var message := "Ouch!"
@export var travel := Vector3.ZERO
@export var period := 0.0
@export var phase := 0.0
@export var color := Color(0.25, 0.4, 0.15)
@export var label := ""

var _base: Vector3


func _enter_tree() -> void:
	add_to_group("hazards")


func _ready() -> void:
	_base = position
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, 0.25, size.z)
	mesh.mesh = box
	mesh.position.y = -size.y / 2.0 + 0.12
	mesh.material_override = Vis.material(color)
	add_child(mesh)
	if label != "":
		var tag := Label3D.new()
		tag.text = label
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size = 32
		add_child(tag)


func _process(_delta: float) -> void:
	if period > 0.0:
		var t := Time.get_ticks_msec() / 1000.0
		position = _base + travel * (0.5 - 0.5 * cos(TAU * t / period + phase))


func contains(point: Vector3) -> bool:
	var d := (point - global_position).abs()
	return d.x <= size.x / 2.0 + 0.3 and d.y <= size.y / 2.0 + 0.5 and d.z <= size.z / 2.0 + 0.3
