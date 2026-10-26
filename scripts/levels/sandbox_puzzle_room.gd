extends Level
## Milestone 1 room: Julia sees a big shape on the west wall (private to her).
## Jason climbs the stairs on the east side and presses the matching shape,
## which opens the north door. Past the door is the way to the key room.
## Sandbox: replaced by the Villa Argo hub once the story is in.

const PUZZLE := "symbol_puzzle"
const BUTTON_Z := [-8.4, -7.6, -6.8, -6.0]
const KEY_ROOM := "res://scenes/levels/sandbox_key_room.tscn"

var _clue: MeshInstance3D


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.5, 1, 0), "julia": Vector3(1.5, 1, 0)},
		"from_key_room": {"jason": Vector3(-0.6, 1, -12), "julia": Vector3(0.6, 1, -12), "yaw": PI},
	}
	add_environment(Color(0.15, 0.17, 0.2))

	var wall := Color(0.4, 0.4, 0.45)
	add_box(Vector3(20, 0.5, 20), Vector3(0, -0.25, 0), Color(0.55, 0.55, 0.55))
	# North wall has a gap (x -1.5..1.5) that the door fills.
	add_box(Vector3(8.5, 4, 0.5), Vector3(-5.75, 2, -10), wall)
	add_box(Vector3(8.5, 4, 0.5), Vector3(5.75, 2, -10), wall)
	add_box(Vector3(20, 4, 0.5), Vector3(0, 2, 10), wall)
	add_box(Vector3(0.5, 4, 20), Vector3(-10, 2, 0), wall)
	add_box(Vector3(0.5, 4, 20), Vector3(10, 2, 0), wall)
	# Corridor behind the door, leading to the key room.
	add_box(Vector3(3, 0.5, 4), Vector3(0, -0.25, -12), Color(0.8, 0.7, 0.3))
	add_box(Vector3(0.5, 4, 4), Vector3(-1.75, 2, -12), wall)
	add_box(Vector3(0.5, 4, 4), Vector3(1.75, 2, -12), wall)
	add_box(Vector3(4, 4, 0.5), Vector3(0, 2, -14.25), wall)
	# Stairs up to the button panel (Jason's climb).
	var wood := Color(0.6, 0.5, 0.35)
	add_box(Vector3(3, 1, 3), Vector3(4, 0.5, -4), wood)
	add_box(Vector3(3, 2, 3), Vector3(7, 1, -4), wood)
	add_box(Vector3(2.5, 3, 3.5), Vector3(8.5, 1.5, -7.25), wood)

	for i in Shapes.COUNT:
		var b := SymbolButton.new()
		b.puzzle = PUZZLE
		b.index = i
		b.who = "jason"
		place(b, "Button%d" % i, Vector3(9.6, 3.9, BUTTON_Z[i]))

	var door := Door.new()
	door.open_flag = PUZZLE + ".solved"
	place(door, "Door", Vector3(0, 0, -10))

	var exit := LevelExit.new()
	exit.level = KEY_ROOM
	exit.requires_flag = PUZZLE + ".solved"
	place(exit, "ExitToKeyRoom", Vector3(0, 1, -12.8))

	GameState.changed.connect(_on_state_changed)
	_show_clue()


func _host_setup() -> void:
	if GameState.get_flag(PUZZLE + ".target") == null:
		GameState.set_flag(PUZZLE + ".target", randi() % Shapes.COUNT)


func _on_state_changed(key: String) -> void:
	if key == "" or key == PUZZLE + ".target":
		_show_clue()


func _show_clue() -> void:
	var target: int = GameState.get_flag(PUZZLE + ".target", -1)
	if _clue:
		_clue.queue_free()
		_clue = null
	if target < 0:
		return
	_clue = MeshInstance3D.new()
	_clue.mesh = Shapes.mesh(target, 1.6)
	_clue.rotation_degrees = Shapes.rotation(target)
	_clue.position = Vector3(-9.3, 2.5, 0)
	_clue.material_override = Vis.material(Color(0.4, 0.9, 1.0))
	Vis.make_private(_clue, "julia")
	add_child(_clue)
