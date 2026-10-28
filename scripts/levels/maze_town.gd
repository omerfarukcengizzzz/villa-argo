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
const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"
## Book 6 step 10: Prester John's guards walk up and down the court, one stop
## every GUARD_SECONDS; the second guard is half a round behind the first.
const GUARD_ROUTE := [Vector3(0, 1, -20), Vector3(0, 1, -32), Vector3(0, 1, -44), Vector3(0, 1, -32)]
const GUARD_X := [24.0, 38.0]
const GUARD_SECONDS := 3.0
const COURT_ENTRANCE := Vector3(19, 1, -32)

var _portcullis: StaticBody3D
var _knot: Node3D
var _split_t := 0.0
var _guard_t := 0.0


func _init() -> void:
	origin = Vector3(30000, 0, 0)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.2, 1, 10), "julia": Vector3(1.2, 1, 10), "yaw": 0.0},
	}
	add_environment(Color(0.75, 0.78, 0.7))
	add_box(Vector3(36, 0.5, 60), Vector3(0, -0.25, -17), Color(0.55, 0.5, 0.42))
	add_box(Vector3(0.4, 8, 60), Vector3(-17, 4, -17), Color(0.6, 0.58, 0.52))
	add_box(Vector3(0.4, 8, 43), Vector3(17, 4, -8.5), Color(0.6, 0.58, 0.52))
	add_box(Vector3(0.4, 8, 13), Vector3(17, 4, -40.5), Color(0.6, 0.58, 0.52))
	add_box(Vector3(0.4, 4, 4), Vector3(17, 6, -32), Color(0.6, 0.58, 0.52))
	add_box(Vector3(34, 8, 0.4), Vector3(0, 4, 13), Color(0.6, 0.58, 0.52))
	add_box(Vector3(34, 8, 0.4), Vector3(0, 4, -47), Color(0.6, 0.58, 0.52))
	add_label("THE TOWN OF PRESTER JOHN", Vector3(0, 6.5, 12.7), 180)

	_build_streets()
	_build_watchtower()
	_build_square()
	_build_court()
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
	var gate: StaticBody3D = get_node("CourtGate")
	var open: bool = GameState.get_flag("b6.playing_rick", false)
	gate.visible = not open
	gate.get_child(1).disabled = open


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not GameState.get_flag("b6.caught", false):
		for p in Game.current.get_players():
			if p.role == "julia" and Game.current.level_for("julia") == self and to_local(p.global_position).z < -27.0:
				_caught(p)
		return
	if not GameState.get_flag("b6.playing_rick", false):
		_split_t += delta
		if _split_t > 6.0:
			_start_split()
		return
	_run_guards(delta)


## Step 3 (adaptation): Manfred grabs Julia and locks her in the bell tower.
func _caught(julia: Node3D) -> void:
	GameState.set_flag("b6.caught")
	julia.teleport.rpc(to_global(TOWER), 0.0)
	Game.current.say("A hand like a shovel closes on Julia's arm: Manfred! He drags her into the bell tower and slams the door. When she gets up, she's alone in a little stone room, and the door won't move.", "julia")
	Game.current.say("A shout from the square: Manfred has burst out of a doorway, grabbed Julia and dragged her into the bell tower! By the time you could get there, the door is tied shut with a huge knot.", "jason")
	GameState.add_journal("julia_caught", "Julia caught",
		"In the bell-tower square, Manfred grabbed Julia and locked her in the bell tower. The door is tied shut with a knot as big as a man's head, so tangled you can't see where the rope begins or ends.\nOblivia must want something from her. Or from us.")


## Book 6 step 4: the split (decision 1: Julia's player plays Rick while Julia
## is held). Canon: Rick is in Kilmore Cove at the start of book 6 (HIGH).
func _start_split() -> void:
	GameState.set_flag("b6.playing_rick")
	GameState.set_flag("b6.nestor_away")
	GameState.add_journal("rick_alone", "Rick: on my own",
		"Meanwhile, in Kilmore Cove. I'm Rick, and the twins haven't come back.\nThey went through the Door after Oblivia days ago. Nestor won't say a word about it, and now he's gone off somewhere without telling anyone. Jason left me the half-burned photo from the Isle of Masks to keep safe.\nWhat I know about Nestor: tall, for an old man; limps; a ring with a little anchor on his left hand, and a pale scar across the back of it. He knew Dedalus. He knew all of them, he says.\nHis cottage is locked. But there's a back window...", "julia")
	GameState.add_journal("jason_alone", "Alone",
		"Julia is locked in the bell tower and I can't untie the knot. I can't even find the end of the rope.\nThere's a gate on the east side of the square that wasn't open before: the court of Prester John. Guards walk up and down inside it. If Black Vulcano is anywhere in this town, he's in there.", "jason")
	Game.current.move_twin("julia", VILLA_ARGO, "gate")
	Game.current.say("Meanwhile, in Kilmore Cove... You are RICK now, until Julia is free. The twins went through the Door days ago and haven't come back, and Nestor has disappeared. Start with his cottage.", "julia")
	Game.current.say("You're on your own. The knot won't budge. But the gate on the east side of the square has swung open: the court of Prester John.", "jason")


# --- Book 6 steps 10-12: Jason alone in the court of Prester John -----------------

func _build_court() -> void:
	var stone := Color(0.6, 0.58, 0.52)
	add_box(Vector3(34, 0.5, 40), Vector3(34, -0.25, -32), Color(0.45, 0.55, 0.38))
	add_box(Vector3(34, 6, 0.4), Vector3(34, 3, -52), stone)
	add_box(Vector3(34, 6, 0.4), Vector3(34, 3, -12), stone)
	add_box(Vector3(0.4, 6, 40), Vector3(51, 3, -32), stone)
	var gate := add_box(Vector3(0.3, 4, 4), Vector3(17, 2, -32), Color(0.35, 0.25, 0.15))
	gate.name = "CourtGate"
	add_label("the court of Prester John", Vector3(16.6, 4.8, -32), -90).font_size = 30
	# Hedges to hide behind.
	for h in [[Vector3(31, 1.1, -23), Vector3(3, 2.2, 4)], [Vector3(31, 1.1, -41), Vector3(3, 2.2, 4)], [Vector3(31, 1.1, -32), Vector3(2, 2.2, 3)], [Vector3(44.5, 1.1, -32), Vector3(3, 2.2, 6)]]:
		add_box(h[1], h[0], Color(0.2, 0.4, 0.2))
	# Black Vulcano's pavilion, in the far corner.
	add_box(Vector3(6, 0.3, 6), Vector3(47, 0.15, -48), Color(0.75, 0.72, 0.65))
	for c in [Vector3(44.5, 2, -45.5), Vector3(49.5, 2, -45.5), Vector3(44.5, 2, -50.5), Vector3(49.5, 2, -50.5)]:
		add_box(Vector3(0.4, 4, 0.4), c, Color(0.8, 0.78, 0.72))
	add_box(Vector3(6, 0.3, 6), Vector3(47, 4.15, -48), Color(0.6, 0.3, 0.2))

	for i in GUARD_X.size():
		var guard := Npc.new()
		guard.npc_name = "Prester John's guard"
		guard.color = Color(0.5, 0.45, 0.2)
		guard.who = "nobody"
		guard.walk_speed = 4.5
		var stations := [["", GUARD_ROUTE[i * 2] + Vector3(GUARD_X[i], 0, 0)]]
		for k in GUARD_ROUTE.size():
			stations.append(["court.g%d=%d" % [i, k], GUARD_ROUTE[k] + Vector3(GUARD_X[i], 0, 0)])
		guard.stations = stations
		place(guard, "Guard%d" % i, stations[0][1])

	var vulcano := Npc.new()
	vulcano.npc_name = "Black Vulcano"
	vulcano.color = Color(0.15, 0.15, 0.17)
	vulcano.lines = [
		["", "Hm? A boy? Out here?"],
		["b6.met_vulcano", "A knot nobody can untie. Think, boy. What did Alexander do?"],
	]
	vulcano.on_used = func(_p: Node3D) -> void:
		if GameState.get_flag("b6.playing_rick", false) and not GameState.get_flag("b6.met_vulcano", false):
			_vulcano_truth()
	place(vulcano, "BlackVulcano", Vector3(47, 1, -48))

	# The knot on Julia's tower door.
	var knot := Interactable.new()
	knot.who = "jason"
	knot.requires = "b6.playing_rick & !b6.knot_cut"
	knot.prompt = "Try to untie the knot"
	knot.on_used = func(_p: Node3D) -> void:
		if GameState.get_flag("b6.knot_known", false):
			Game.current.say("A Gordian knot. Untying it is hopeless; Alexander didn't even try. But you've nothing to cut it with. Not yet.", "jason")
		else:
			Game.current.say("You pull at the knot until your fingers hurt. There's no end to it anywhere. From behind the door, muffled: \"Jason? I'm all right! Get me OUT of here!\"", "jason")
	place(knot, "TowerKnot", Vector3(0, 1, -35.8))


## Host: the guards walk their rounds; one that sees Jason sends him back out.
func _run_guards(delta: float) -> void:
	_guard_t += delta
	if _guard_t >= GUARD_SECONDS:
		_guard_t = 0.0
		for i in GUARD_X.size():
			var k := int(GameState.get_flag("court.g%d" % i, i * 2))
			GameState.set_flag("court.g%d" % i, (k + 1) % GUARD_ROUTE.size())
	var jason := Game.current.get_player(1)
	if jason == null or Game.current.level_for("jason") != self or to_local(jason.global_position).x < 17.5:
		return
	for i in GUARD_X.size():
		if sees(get_node("Guard%d" % i), jason, 9.0, 100.0):
			jason.teleport.rpc(to_global(COURT_ENTRANCE), -PI / 2)
			Game.current.say("\"HALT!\" A guard with a pike marches you straight back out of the court. Wait for them to turn their backs, and use the hedges.", "jason")
			return


## Book 6 steps 11-12 (canon: Black Vulcano never had the First Key, MEDIUM;
## he is Oblivia's father ✅, "Fathers and Daughters" LOW; a Gordian knot
## appears, MEDIUM). The dialogue is adaptation.
func _vulcano_truth() -> void:
	GameState.set_flag("b6.met_vulcano")
	GameState.set_flag("b6.knot_known")
	GameState.add_journal("vulcano_truth", "Black Vulcano",
		"In a pavilion at the far end of the court, an old man with a railwayman's hands: Black Vulcano, who drove the trains at Clark Beamish Station.\nI asked him for the First Key. He laughed until he coughed. \"The First Key? I never had it, boy. None of us ever found it: not Ulysses, not Peter, not me. People just like to think somebody has it.\"\nAnd Oblivia Newton? He went quiet. \"Oblivia is my daughter. She was always going to come after me, one way or another.\"", "jason")
	GameState.add_journal("gordian", "The Gordian knot",
		"Black Vulcano knows the knot on Julia's door. \"Prester John's guards tie it. Nobody has ever untied one. There was a king once, Alexander, who met a knot like that. He didn't untie it at all.\"\nHe cut it. I need a blade.", "jason")
	Game.current.say("Black Vulcano: \"The First Key? I never had it. None of us ever found it.\" ...And Oblivia Newton is his daughter.", "jason")
