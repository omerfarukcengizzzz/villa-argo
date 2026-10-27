class_name FloorStone
extends Interactable
## One of a set of floor stones with an arrow that turns 90° clockwise per use.
## Stones must be set from the highest number down: turning a stone while any
## higher-numbered stone is still wrong makes them all grind back to the start.
## When every arrow matches `targets`, "<puzzle>.solved" is set.
## GameState: "<puzzle>.dir<number>" = 0 north, 1 east, 2 south, 3 west.

@export var puzzle := "stones"
## Shown on the stone; 1-based.
@export var number := 1
## Target direction per stone, index 0 = stone 1.
var targets: Array = []

var _arrow: Node3D


func _init() -> void:
	prompt = "Turn the stone"
	who = "julia"
	reach = 1.6


func _available() -> bool:
	return not GameState.get_flag(puzzle + ".solved", false)


func _build() -> void:
	var stone := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.2, 1.6)
	stone.mesh = box
	stone.position.y = -0.8
	stone.material_override = Vis.material(Color(0.5, 0.48, 0.45))
	add_child(stone)
	_arrow = Node3D.new()
	_arrow.position.y = -0.68
	add_child(_arrow)
	var shaft := MeshInstance3D.new()
	var s := BoxMesh.new()
	s.size = Vector3(0.18, 0.04, 0.9)
	shaft.mesh = s
	shaft.material_override = Vis.material(Color(0.15, 0.12, 0.1))
	_arrow.add_child(shaft)
	var head := MeshInstance3D.new()
	var h := PrismMesh.new()
	h.size = Vector3(0.5, 0.4, 0.04)
	head.mesh = h
	head.rotation_degrees.x = -90
	head.position.z = -0.55
	head.material_override = shaft.material_override
	_arrow.add_child(head)
	var label := Label3D.new()
	label.text = str(number)
	label.position = Vector3(0, -0.67, 0.55)
	label.rotation_degrees.x = -90
	label.font_size = 64
	add_child(label)


func refresh() -> void:
	var yaw := -90.0 * _dir(number)
	if is_node_ready():
		create_tween().tween_property(_arrow, "rotation_degrees:y", yaw, 0.3)
	else:
		_arrow.rotation_degrees.y = yaw


func _dir(n: int) -> int:
	return GameState.get_flag("%s.dir%d" % [puzzle, n], 0)


func _host_interact(_player: Node3D) -> void:
	for n in range(number + 1, targets.size() + 1):
		if _dir(n) != targets[n - 1]:
			for m in range(1, targets.size() + 1):
				GameState.set_flag("%s.dir%d" % [puzzle, m], 0)
			Game.current.say("The stones grind back to where they started.")
			return
	GameState.set_flag("%s.dir%d" % [puzzle, number], (_dir(number) + 1) % 4)
	for n in range(1, targets.size() + 1):
		if _dir(n) != targets[n - 1]:
			return
	GameState.set_flag(puzzle + ".solved")
