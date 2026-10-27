extends Level
## The maze-town of the Garden of Prester John, book 6 (docs/book6-design.md,
## steps 1-3). Canon: a labyrinthine medieval town (HIGH); the maze itself and
## everything in it is adaptation (ref: the maze is to be invented):
## - Jason climbs the watchtower by the town gate and sees the streets from
##   above; Julia, down in the streets, can't see over the houses and follows
##   his directions. The winch for the portcullis at the far end of the streets
##   is up on the watchtower too.
## - Step 3: in the bell-tower square Manfred grabs Julia and locks her in the
##   bell tower; the door is tied shut with a huge knot. (Book 6 Pass B: while
##   she's held, Julia's player plays Rick in Kilmore Cove.)
##
## Map (north = -z): the town gate yard z 3..12; the streets, a grid of 3 m
## cells, x -16.5..16.5, z -25.5..1.5 (MAZE row 8 at z 0, row 0 at z -24); the
## bell-tower square z -26..-46 with the tower at its north end.

const CELL := 3.0
const HOUSE_HEIGHT := 6.0
## The streets, north (row 0) to south (row 8): # = houses, . = street. The way
## through: up from the gate, left, up the third street, right, up to the exit.
const MAZE := [
	"#####.#####",
	"#.....#...#",
	"#.###.#.#.#",
	"#.#...#.#.#",
	"#.#.###.#.#",
	"#...#...#.#",
	"###.#.###.#",
	"#.....#...#",
	"#####.#####",
]
const HOUSE_COLORS := [Color(0.72, 0.62, 0.5), Color(0.66, 0.58, 0.5), Color(0.75, 0.68, 0.58), Color(0.6, 0.52, 0.45)]
const TOWER := Vector3(0, 1, -40)

var _portcullis: StaticBody3D
var _knot: Node3D


func _init() -> void:
	origin = Vector3(30000, 0, 0)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.2, 1, 10), "julia": Vector3(1.2, 1, 10), "yaw": 0.0},
	}
	add_environment(Color(0.75, 0.78, 0.7))
	add_box(Vector3(36, 0.5, 60), Vector3(0, -0.25, -17), Color(0.55, 0.5, 0.42))
	for x in [-17.0, 17.0]:
		add_box(Vector3(0.4, 8, 60), Vector3(x, 4, -17), Color(0.6, 0.58, 0.52))
	add_box(Vector3(34, 8, 0.4), Vector3(0, 4, 13), Color(0.6, 0.58, 0.52))
	add_box(Vector3(34, 8, 0.4), Vector3(0, 4, -47), Color(0.6, 0.58, 0.52))
	add_label("THE TOWN OF PRESTER JOHN", Vector3(0, 6.5, 12.7), 180)

	_build_streets()
	_build_watchtower()
	_build_square()
	GameState.changed.connect(_on_state_changed)
	_on_state_changed("")


func _host_setup() -> void:
	if not GameState.get_flag("maze.arrived", false):
		GameState.set_flag("maze.arrived")
		Game.current.say("A town of crooked houses packed so tight their roofs nearly touch, and streets that twist away out of sight. Over it all, a bell tower. There's a watchtower right by the gate...")


## The cell (row, column) of MAZE, in level coordinates.
static func cell(row: int, col: int) -> Vector3:
	return Vector3((col - 5) * CELL, 1, (row - 8) * CELL)


func _build_streets() -> void:
	for r in MAZE.size():
		for c in MAZE[r].length():
			if MAZE[r][c] != "#":
				continue
			var at := cell(r, c)
			add_box(Vector3(CELL, HOUSE_HEIGHT, CELL), Vector3(at.x, HOUSE_HEIGHT / 2.0, at.z), HOUSE_COLORS[(r * 3 + c) % HOUSE_COLORS.size()])
	# The portcullis across the last street, raised from the watchtower.
	var exit := cell(0, 5)
	_portcullis = add_box(Vector3(CELL, 4, 0.3), Vector3(exit.x, 2, exit.z - 1.2), Color(0.25, 0.25, 0.27))
	_portcullis.name = "Portcullis"
	add_label("portcullis", Vector3(exit.x, 4.4, exit.z - 1.0)).font_size = 26


func _build_watchtower() -> void:
	# By the town gate: Jason climbs it and sees the whole maze from the top.
	add_climb_wall(Vector3(2.4, 12, 2.4), Vector3(-9, 6, 7))
	add_box(Vector3(2.4, 0.1, 2.4), Vector3(-9, 12.05, 7), Color(0.5, 0.4, 0.3))
	add_label("watchtower", Vector3(-9, 2.5, 8.3)).font_size = 30
	var winch := Lever.new()
	winch.who = "jason"
	winch.flag = "maze.portcullis"
	winch.prompt = "Turn the portcullis winch"
	winch.off_text = "portcullis: DOWN"
	winch.on_text = "portcullis: UP"
	place(winch, "PortcullisWinch", Vector3(-8.2, 12.2, 6.2))
	var view := JournalNote.new()
	view.who = "jason"
	view.entry_who = "jason"
	view.entry_id = "rooftops"
	view.title = "The town from above"
	view.body = "From the top of the watchtower the town is a maze of streets between the roofs, and I can see the whole of it. Julia can't, down there. The way through, from the gate: straight on, left at the first turning, up the third street, right along to the end, then up to the portcullis and the bell-tower square.\nThere's a winch up here for the portcullis."
	view.prompt = "Look out over the roofs"
	view.size = Vector3(0.01, 0.01, 0.01)
	place(view, "RooftopView", Vector3(-9.8, 12.8, 7.6))


func _build_square() -> void:
	add_label("the bell-tower square", Vector3(0, 5, -26.5)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# The bell tower, hollow: a little room at the bottom with one door.
	var stone := Color(0.62, 0.6, 0.55)
	add_box(Vector3(6, 16, 0.6), Vector3(0, 8, -43), stone)
	add_box(Vector3(0.6, 16, 6), Vector3(-3, 8, -40), stone)
	add_box(Vector3(0.6, 16, 6), Vector3(3, 8, -40), stone)
	add_box(Vector3(2, 16, 0.6), Vector3(-2, 8, -37), stone)
	add_box(Vector3(2, 16, 0.6), Vector3(2, 8, -37), stone)
	add_box(Vector3(2, 13.4, 0.6), Vector3(0, 9.3, -37), stone)
	add_box(Vector3(2, 2.6, 0.3), Vector3(0, 1.3, -37), Color(0.35, 0.25, 0.15)).name = "TowerDoor"
	add_label("BELL TOWER", Vector3(0, 15, -36.6), 0)

	_knot = Node3D.new()
	_knot.position = Vector3(0, 1.4, -36.6)
	add_child(_knot)
	var rope := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.0
	rope.mesh = sphere
	rope.material_override = Vis.material(Color(0.6, 0.5, 0.3))
	_knot.add_child(rope)
	var tag := Label3D.new()
	tag.text = "a huge, impossible knot"
	tag.position.y = 1.0
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 26
	_knot.add_child(tag)

	var manfred := Npc.new()
	manfred.npc_name = "Manfred"
	manfred.color = Color(0.2, 0.2, 0.2)
	manfred.who = "nobody"
	manfred.present = "b6.caught"
	place(manfred, "Manfred", Vector3(2.5, 1, -34))


func _on_state_changed(_key: String) -> void:
	var up: bool = GameState.get_flag("maze.portcullis", false)
	_portcullis.visible = not up
	_portcullis.get_child(1).disabled = up
	_knot.visible = GameState.get_flag("b6.caught", false)


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server() or GameState.get_flag("b6.caught", false):
		return
	for p in Game.current.get_players():
		if p.role == "julia" and Game.current.level_for("julia") == self and to_local(p.global_position).z < -27.0:
			_caught(p)


## Step 3 (adaptation): Manfred grabs Julia and locks her in the bell tower.
func _caught(julia: Node3D) -> void:
	GameState.set_flag("b6.caught")
	julia.teleport.rpc(to_global(TOWER), 0.0)
	Game.current.say("A hand like a shovel closes on Julia's arm: Manfred! He drags her into the bell tower and slams the door. When she gets up, she's alone in a little stone room, and the door won't move.", "julia")
	Game.current.say("A shout from the square: Manfred has burst out of a doorway, grabbed Julia and dragged her into the bell tower! By the time you could get there, the door is tied shut with a huge knot.", "jason")
	GameState.add_journal("julia_caught", "Julia caught",
		"In the bell-tower square, Manfred grabbed Julia and locked her in the bell tower. The door is tied shut with a knot as big as a man's head, so tangled you can't see where the rope begins or ends.\nOblivia must want something from her. Or from us.")
