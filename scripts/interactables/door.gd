class_name Door
extends Interactable
## A door that sinks into the floor once GameState flag `open_flag` is set.
## With `key_item` set it is a locked door: interacting while the twins hold that
## item opens it. With `free` it opens on interact. Otherwise it only opens from
## elsewhere (e.g. a puzzle).

@export var size := Vector3(3, 4, 0.5)
@export var open_flag := ""
@export var key_item := ""
@export var key_name := "a key"
@export var free := false
@export var color := Color(0.45, 0.3, 0.15)

var _body: StaticBody3D
var _opened := false


func _init() -> void:
	prompt = "Unlock"
	reach = 2.2


func is_open() -> bool:
	return GameState.get_flag(open_flag, false)


func _available() -> bool:
	return (key_item != "" or free) and not is_open()


func _build() -> void:
	_body = StaticBody3D.new()
	_body.position.y = size.y / 2.0
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
	if _opened or not is_open():
		return
	_opened = true
	var open_y := -size.y / 2.0 - 0.1
	if is_node_ready():
		create_tween().tween_property(_body, "position:y", open_y, 1.5)
	else:
		_body.position.y = open_y


func _host_interact(player: Node3D) -> void:
	if free:
		GameState.set_flag(open_flag)
	elif GameState.has_item(key_item):
		GameState.set_flag(open_flag)
		Game.current.say("The %s turns. The door opens." % key_name)
	else:
		Game.current.say("Locked. It needs %s." % key_name, player.role)
