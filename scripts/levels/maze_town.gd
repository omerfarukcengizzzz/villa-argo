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
const KILMORE_COVE := "res://scenes/levels/kilmore_cove.tscn"
const PAVILION := Vector3(47, 1, -48)

var _portcullis: StaticBody3D
var _knot: Node3D
var _split_t := 0.0
var _guard_t := 0.0
var _arrive_t := 0.0


func _init() -> void:
	origin = Vector3(30000, 0, 0)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.2, 1, 10), "julia": Vector3(1.2, 1, 10), "yaw": 0.0},
		"horse_door": {"jason": Vector3(-14, 1, -34.5), "julia": Vector3(-14, 1, -36), "yaw": -PI / 2},
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
	_build_reunion()
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
	manfred.present = "b6.caught & !b6.knot_cut"
	place(manfred, "Manfred", Vector3(2.5, 1, -34))


func _on_state_changed(_key: String) -> void:
	var up: bool = GameState.get_flag("maze.portcullis", false)
	_portcullis.visible = not up
	_portcullis.get_child(1).disabled = up
	var cut: bool = GameState.get_flag("b6.knot_cut", false)
	_knot.visible = GameState.get_flag("b6.caught", false) and not cut
	var door: StaticBody3D = get_node("TowerDoor")
	door.visible = not cut
	door.get_child(1).disabled = cut
	var gate: StaticBody3D = get_node("CourtGate")
	var open: bool = GameState.get_flag("b6.playing_rick", false) or cut
	gate.visible = not open
	gate.get_child(1).disabled = open


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not GameState.get_flag("b6.caught", false):
		for p in Game.current.get_players():
			if p.role == "julia" and Game.current.level_for("julia") == self and _in_square(to_local(p.global_position)):
				_caught(p)
		return
	if not GameState.get_flag("b6.playing_rick", false):
		_split_t += delta
		if _split_t > 6.0:
			_start_split()
		return
	if GameState.get_flag("b6.rick_ready", false) and not GameState.get_flag("b6.arrived", false):
		_arrive_t += delta
		if _arrive_t > 3.0:
			_arrive()
	if not GameState.get_flag("b6.knot_cut", false):
		_run_guards(delta)


## The bell-tower square. Checked by its bounds, not just "north of the
## streets": right after a level change the host can briefly still have a twin
## at her old level's position.
static func _in_square(at: Vector3) -> bool:
	return absf(at.x) < 17.0 and at.z < -27.0 and at.z > -47.0 and absf(at.y - 1.0) < 3.0


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
	vulcano.lines.append(["b6.knot_cut", "Ulysses. After all these years. Come here, you old pirate."])
	vulcano.lines.append(["b6.truth", "I'm staying. This garden suits an old man. Go home, all of you."])
	vulcano.on_used = func(p: Node3D) -> void:
		if GameState.get_flag("b6.playing_rick", false) and not GameState.get_flag("b6.met_vulcano", false):
			_vulcano_truth()
		elif GameState.get_flag("b6.knot_cut", false) and not GameState.get_flag("b6.truth", false):
			_try_truth(p)
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



# --- Book 6 steps 13-15: the reunion, the Gordian knot, the truth -----------------

func _build_reunion() -> void:
	# The Horse Door, from the Garden's side, in the west wall of the square.
	add_box(Vector3(0.3, 4, 3), Vector3(-16.7, 2, -36), Color(0.3, 0.22, 0.15))
	add_label("the Horse Door", Vector3(-16.5, 4.6, -36), 90).font_size = 30
	var home := LevelExit.new()
	home.level = KILMORE_COVE
	home.entry = "station"
	home.requires = "b6.truth"
	home.prompt = "Board the train home"
	home.on_used = func(_p: Node3D) -> void:
		GameState.set_flag("b6.home")
		Game.current.say("The Train of Eternal Youth carries everyone back through the Horse Door: the twins, Rick, Ulysses Moore, a sulking Oblivia Newton and a strangely cheerful Manfred. Black Vulcano waves from the platform of the Garden. Then: Kilmore Cove.")
	place(home, "TrainHome", Vector3(-14.5, 1, -38))

	var ulysses := Npc.new()
	ulysses.npc_name = "Ulysses Moore"
	ulysses.color = Color(0.45, 0.4, 0.3)
	ulysses.present = "b6.arrived & !b6.home"
	ulysses.walk_speed = 3.0
	ulysses.stations = [["", Vector3(-13, 1, -38.5)], ["b6.knot_cut", PAVILION + Vector3(-1.8, 0, 2.5)]]
	ulysses.lines = [
		["b6.arrived", "Yes, Jason. It's me. Nestor, Ulysses: both. I'll explain everything, I promise. First, your sister."],
		["b6.knot_cut", "Victor's in the court. Come. It's time we all told the truth."],
		["b6.truth", "Home, then. The train won't wait for ever."],
	]
	place(ulysses, "Ulysses", Vector3(-13, 1, -38.5))

	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.present = "b6.knot_cut & !b6.home"
	rick.walk_speed = 4.0
	rick.stations = [["", Vector3(2.5, 1, -33.5)], ["b6.truth", Vector3(-12.5, 1, -36.5)]]
	rick.lines = [
		["b6.knot_cut", "Julia! Are you all right? ...Good. Good. You should've seen Jason's face when Nestor got off the train."],
		["b6.truth", "Home. I never thought I'd be so glad to see Kilmore Cove."],
	]
	place(rick, "Rick", Vector3(2.5, 1, -33.5))

	# Rick reads the legend; Jason cuts the knot.
	var legend := JournalNote.new()
	legend.who = "julia"
	legend.entry_who = "julia"
	legend.requires = "b6.arrived & !b6.knot_cut"
	legend.entry_id = "knot_legend"
	legend.title = "Rick: the Gordian knot"
	legend.body = "Carved over the tower door, in old letters (Ulysses translated): the story of the knot of Gordium. Whoever undid it would rule all Asia, and for years nobody could even find its ends. Then Alexander came. He didn't pick at it. He drew his sword and cut it straight through the middle, in a single stroke.\nJason needs to know that: one stroke, through the middle."
	legend.prompt = "Read the words over the tower door"
	legend.size = Vector3(0.01, 0.01, 0.01)
	place(legend, "KnotLegend", Vector3(-1.5, 1, -35.8))
	var blade := Pickup.new()
	blade.who = "jason"
	blade.item_id = "blade"
	blade.item_name = "a guard's sword"
	blade.requires = "b6.knot_known & !b6.knot_cut"
	blade.prompt = "Take a sword from the rack"
	blade.box_size = Vector3(0.1, 1.0, 0.1)
	blade.color = Color(0.75, 0.75, 0.8)
	place(blade, "Sword", Vector3(49, 1.2, -14.6))
	add_box(Vector3(1.6, 1.4, 0.3), Vector3(49, 0.7, -12.5), Color(0.35, 0.25, 0.15))
	add_label("the guards' sword rack", Vector3(49, 2.4, -12.7), 180).font_size = 24
	var cut := ChoicePoint.new()
	cut.who = "jason"
	cut.requires = "item:blade & !b6.knot_cut"
	cut.prompt = "Cut the knot"
	cut.reach = 2.0
	cut.question = "The sword is heavy in your hands. How do you cut the knot?"
	cut.options_for = func() -> Array:
		return [["Saw carefully at the outside loops", true], ["Straight through the middle, in one stroke", true], ["Hack at it as hard as you can, again and again", true]]
	cut.on_choice = func(_p: Node3D, choice: String) -> void:
		if choice != "Straight through the middle, in one stroke":
			Game.current.say("The rope only seems to pull tighter, as if the knot is alive. There has to be a right way. Ask Rick: what did Alexander do?", "jason")
			return
		_free_julia()
	place(cut, "CutKnot", Vector3(1.2, 1, -35.8))

	for who in [["Oblivia Newton", Color(0.6, 0.1, 0.3), PAVILION + Vector3(2.2, 0, 2.6)], ["Manfred", Color(0.2, 0.2, 0.2), PAVILION + Vector3(3.6, 0, 3.4)]]:
		var npc := Npc.new()
		npc.npc_name = who[0]
		npc.color = who[1]
		npc.who = "nobody"
		npc.present = "b6.knot_cut & !b6.home"
		place(npc, "Court" + who[0].split(" ")[0], who[2])


## Host: the train comes out of the Horse Door into the square (canon:
## Ulysses and Rick arrive through the station Door, MEDIUM ✅).
func _arrive() -> void:
	GameState.set_flag("b6.arrived")
	Game.current.move_twin("julia", "res://scenes/levels/maze_town.tscn", "horse_door")
	Game.current.say("With a shriek of steam, a train bursts out of a door in the wall of the square: the Train of Eternal Youth! Rick jumps down. And behind him, stiff and limping, Nestor. \"Hello, Jason. It's time you knew. My name is Ulysses Moore.\"", "jason")
	Game.current.say("The train bursts out of the Horse Door into a square full of crooked houses, and there's Jason, staring. Not at you: at Nestor. You'd give anything for a camera.", "julia")
	GameState.add_journal("ulysses_jason", "Nestor is Ulysses Moore",
		"A train came out of the wall, the Train of Eternal Youth, with Rick on it. And Nestor. Nestor, our gardener, who said the Door led to a cistern. He's Ulysses Moore. He's been at Villa Argo all along, watching us find his Doors.\nRick found out by breaking into his cottage. Of course he did.", "jason")


## Host: Jason cuts the knot the way Alexander did (the knot's use is
## adaptation). Julia's player is Julia again; Rick is back to being Rick.
func _free_julia() -> void:
	GameState.set_flag("b6.knot_cut")
	GameState.set_flag("b6.playing_rick", false)
	GameState.take_item("blade")
	var julia: Node3D = null
	for p in Game.current.get_players():
		if p.role == "julia":
			julia = p
	if julia:
		julia.teleport.rpc(to_global(Vector3(0, 1, -38.5)), PI)
	GameState.share_journal()
	GameState.add_journal("reunited", "Together again",
		"One stroke, straight through the middle, the way Alexander did it, and the Gordian knot fell apart. Julia walked out of the bell tower, Rick grinned like an idiot, and Nestor (Ulysses!) put a hand on each of our shoulders.\nWe've told each other everything now: the cottage, the photo, Rick's father, Black Vulcano, the First Key that nobody ever found.")
	Game.current.say("One stroke, straight through the middle, and the Gordian knot falls to pieces. The tower door swings open: Julia is free! You're JULIA again. Black Vulcano is waiting in the court, and so, it seems, are Oblivia and Manfred.")


## Host: everyone at Black Vulcano's pavilion (canon: Black Vulcano never had
## the First Key, MEDIUM; Oblivia is his daughter ✅; Manfred leaves her for
## Gwendaline, ✅; decision 3: Black Vulcano stays in the Garden).
func _try_truth(player: Node3D) -> void:
	var near := Game.current.get_players().all(func(p: Node3D) -> bool:
		return Game.current.level_for(p.role) == self and to_local(p.global_position).distance_to(PAVILION) < 8.0)
	if Game.current.get_players().size() < 2 or not near:
		Game.current.say("Black Vulcano: \"Not yet. I want both of you here for this. Fetch your sister, boy.\"" if player.role == "jason" else "Black Vulcano: \"Not yet. Where's your brother? I want both of you here for this.\"", player.role)
		return
	GameState.set_flag("b6.truth")
	GameState.add_journal("truth", "The truth",
		"Under Black Vulcano's pavilion, everyone at once: Ulysses Moore and Black Vulcano, old friends from the Great Summer of 1958, shaking hands as if they'd never stop; Oblivia Newton, white with anger; Manfred, looking at his shoes.\nThe truth, all of it: nobody ever found the First Key. Not Black Vulcano, not Ulysses, not Peter Dedalus, not Rick's father, who died looking for it. Everybody just believed somebody else had it.\nAnd Oblivia is Black Vulcano's daughter. All this time, she was chasing her own father, and a key that doesn't exist.\nManfred cleared his throat and told Oblivia he quits. He has a hairdresser to see in Kilmore Cove.\nBlack Vulcano is staying here. \"The Garden suits an old man.\" The train is waiting at the Horse Door, to take everyone else home.")
	Game.current.say("Black Vulcano and Ulysses Moore, face to face after all these years. Then the truth: nobody ever found the First Key. And Oblivia Newton is Black Vulcano's daughter. Manfred clears his throat: \"Miss Newton? I quit.\"")
