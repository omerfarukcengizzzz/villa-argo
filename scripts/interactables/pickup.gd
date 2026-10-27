class_name Pickup
extends Interactable
## An item that goes into the twins' shared inventory when picked up.

@export var item_id := ""
@export var item_name := "key"
@export var color := Color(0.95, 0.8, 0.25)
## Non-zero: drawn as a still box of this size instead of a spinning key.
@export var box_size := Vector3.ZERO
## GameState condition for the item to be here at all (e.g. after it's dropped).
@export var appears := ""

var _key: Node3D


func _init() -> void:
	prompt = "Pick up"


func _available() -> bool:
	return not GameState.has_item(item_id) and GameState.check(appears)


## Gray-box key (an upright ring with a shaft below it), or a plain box.
func _build() -> void:
	var mat := Vis.material(color)
	_key = Node3D.new()
	add_child(_key)
	if box_size != Vector3.ZERO:
		var item := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = box_size
		item.mesh = b
		item.material_override = mat
		_key.add_child(item)
		set_process(false)
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.12
	torus.outer_radius = 0.22
	ring.mesh = torus
	ring.rotation_degrees.x = 90
	ring.material_override = mat
	_key.add_child(ring)
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.5, 0.06)
	shaft.mesh = box
	shaft.position.y = -0.45
	shaft.material_override = mat
	_key.add_child(shaft)


func _process(delta: float) -> void:
	_key.rotate_y(delta * 1.5)


func refresh() -> void:
	visible = not GameState.has_item(item_id) and GameState.check(appears)


func _host_interact(player: Node3D) -> void:
	GameState.give_item(item_id, item_name)
	Game.current.say("%s found the %s." % [player.role.capitalize(), item_name])
