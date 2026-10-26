class_name Pickup
extends Interactable
## An item that goes into the twins' shared inventory when picked up.

@export var item_id := ""
@export var item_name := "key"
@export var color := Color(0.95, 0.8, 0.25)

var _key: Node3D


func _init() -> void:
	prompt = "Pick up"


func is_available() -> bool:
	return not GameState.has_item(item_id)


## Gray-box key: an upright ring with a shaft below it.
func _build() -> void:
	var mat := Vis.material(color)
	_key = Node3D.new()
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
	add_child(_key)


func _process(delta: float) -> void:
	_key.rotate_y(delta * 1.5)


func refresh() -> void:
	visible = is_available()


func _host_interact(player: Node3D) -> void:
	GameState.give_item(item_id, item_name)
	Game.current.say("%s found the %s." % [player.role.capitalize(), item_name])
