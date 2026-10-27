class_name KeyLock
extends Interactable
## One keyhole of a multi-lock door. Each use puts the next held key that isn't
## already in another lock of the same door into this one (then empty again).
## When every lock holds a key the host checks the order: right opens the door
## (`<door>.open`), wrong makes the locks spring back and counts `<door>.fails`.
## GameState: "<door>.slot<index>" = key item id or "".

@export var door := "argo_door"
@export var index := 0
## The key item ids in the right order, one per lock.
var solution: Array = []
## While GameState condition `alt_when` holds, `alt_solution` is the right order
## instead (book 2: opening the Door from the house side).
var alt_solution: Array = []
@export var alt_when := ""

var _label: Label3D


func _init() -> void:
	prompt = "Try a key"
	reach = 1.8


func _available() -> bool:
	return not GameState.get_flag(door + ".open", false) and solution.any(func(k: String) -> bool: return GameState.has_item(k))


func _solution() -> Array:
	return alt_solution if alt_when != "" and GameState.check(alt_when) else solution


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.09
	cyl.height = 0.08
	mesh.mesh = cyl
	mesh.rotation_degrees.z = 90
	mesh.material_override = Vis.material(Color(0.15, 0.12, 0.1))
	add_child(mesh)
	var number := Label3D.new()
	number.text = str(index + 1)
	number.position = Vector3(-0.06, -0.25, 0)
	number.rotation_degrees.y = -90
	number.font_size = 32
	add_child(number)
	_label = Label3D.new()
	_label.position = Vector3(-0.06, 0.22, 0)
	_label.rotation_degrees.y = -90
	_label.font_size = 28
	add_child(_label)


func refresh() -> void:
	var key: String = GameState.get_flag(_slot(index), "")
	_label.text = GameState.inventory.get(key, "").trim_suffix(" key")


func _slot(i: int) -> String:
	return "%s.slot%d" % [door, i]


func _host_interact(_player: Node3D) -> void:
	var used := []
	for i in solution.size():
		if i != index:
			used.append(GameState.get_flag(_slot(i), ""))
	var choices: Array = [""]
	for k in solution:
		if GameState.has_item(k) and not used.has(k):
			choices.append(k)
	var current: String = GameState.get_flag(_slot(index), "")
	var next: String = choices[(choices.find(current) + 1) % choices.size()]
	GameState.set_flag(_slot(index), next)
	_check_door()


func _check_door() -> void:
	var placed := []
	for i in solution.size():
		placed.append(GameState.get_flag(_slot(i), ""))
	if placed.has(""):
		return
	if placed == _solution():
		GameState.set_flag(door + ".open")
		Game.current.say("Click, click, click, click. The scarred door swings open.")
		return
	GameState.set_flag(door + ".fails", int(GameState.get_flag(door + ".fails", 0)) + 1)
	Game.current.say("The keys turn halfway... and the locks spring back.")
	await get_tree().create_timer(0.8).timeout
	for i in solution.size():
		GameState.set_flag(_slot(i), "")
