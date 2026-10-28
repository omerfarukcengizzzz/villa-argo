extends Level
## Clark Beamish Station, book 5 (docs/book5-design.md, steps 6-11). Canon
## (ref §5, HIGH): the overgrown hall with its roof lantern, the chandelier full
## of birds, flowers through the marble and the giant iron timetable board on
## chains; the ticket office with the 1936 perpetual timetable, the moving iron
## bookstand (Julia sets it off, Rick works it out) and Dedalus's ticket printer;
## the control room with red switch levers and red and blue valves (Fred turns
## them twice a week: red closed, blue open); the tunnel to the Horse Door; the
## riddle ("half of sand and half of wind... fill your heart... a hundred"); the
## Train of Eternal Youth comes back to life. Adaptation: what's on the board,
## the ticket code, the route through the points, what the valves do, and the
## firebox (coal and bellows, in turn, past a hundred).
##
## Map (north = -z): the hall x -12..12, z -12..10 (entrance south, back to
## Kilmore Cove); the ticket office west (x -20..-12), the control room east
## (x 12..20); a gap in the north wall (x 6..10) to the platform and the tunnel,
## with the locomotive and, at the end, the boarded-up Horse Door.

const KILMORE_COVE := "res://scenes/levels/kilmore_cove.tscn"
const WALL := Color(0.62, 0.58, 0.52)
const IRON := Color(0.22, 0.22, 0.25)
const BOARD_UP := 8.2
const BOARD_DOWN := 2.8
## The firebox: each stoke in turn adds STOKE; the same twice chokes the fire.
const STOKE := 12
const CHOKE := 30
const HUNDRED := 100
const BOARD := "CLARK BEAMISH STATION: DEPARTURES\n\n06:10   Harbour Halt ........ plat. 1 ..... KA-LO 1\n07:45   Old Mill ............ plat. 2 ..... TE-RU 2\n09:30   Lighthouse siding ... plat. 1 ..... NE-KA 1\n12:15   Quarry .............. plat. 2 ..... LO-TE 2\n25:00   ..................... plat. 3 ..... MI-RA-SO 3\n\nOne train leaves at twenty-five o'clock, from platform 3, for nowhere at all. Its ticket code is MI-RA-SO 3."
const TRACK_MODEL := "A model of the whole line on a table, with tiny painted points:\n\nPoints 1, just out of the station: LEFT to the Harbour, RIGHT to the Old Mill.\nPoints 2, past the Old Mill: LEFT to the Lighthouse siding, RIGHT to the Quarry.\nPoints 3, past the Quarry: LEFT into the Tunnel, RIGHT back round to the Harbour.\n\nA brass plate: \"Points worked by pressure. RED valve OPEN to move them, CLOSED to lock them. BLUE valve OPEN always.\""
const RIDDLE := "Words cut into the brass of the locomotive's cab, under the dust:\n\nHalf of sand and half of wind:\nfill your heart, if you would ride.\nBrave traveller, trust your friend:\na hundred, at the least, inside.\n\nThe heart must be the firebox. The coal in the tender is as fine as black sand; the wind is the bellows. And the hundred... the pressure gauge. Half and half: one of us shovels, the other pumps, turn and turn about."

var _board: Node3D
var _gauge: Label3D
var _decay_t := 0.0
var _boards: Array = []


func _init() -> void:
	origin = Vector3(24000, 0, 0)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.2, 1, 7.5), "julia": Vector3(1.2, 1, 7.5), "yaw": 0.0},
	}
	add_environment(Color(0.55, 0.62, 0.7))
	add_box(Vector3(44, 0.5, 60), Vector3(0, -0.25, -16), Color(0.82, 0.8, 0.76))

	_build_hall()
	_build_ticket_office()
	_build_control_room()
	_build_tunnel()
	_build_people()

	var out := LevelExit.new()
	out.level = KILMORE_COVE
	out.entry = "station"
	out.prompt = "Back out to Kilmore Cove"
	out.solo_when = "b6.playing_rick"
	place(out, "LeaveStation", Vector3(0, 1, 9))


func _host_setup() -> void:
	if not GameState.get_flag("station.arrived", false):
		GameState.set_flag("station.arrived")
		Game.current.say("Clark Beamish Station. Light falls through a roof lantern of glass and iron; birds are nesting in the great chandelier, and wildflowers push up through the cracks in the marble.")


# --- Step 7: the hall --------------------------------------------------------------

func _build_hall() -> void:
	add_box(Vector3(10, 10, 0.4), Vector3(-7, 5, 10), WALL)
	add_box(Vector3(10, 10, 0.4), Vector3(7, 5, 10), WALL)
	add_box(Vector3(18, 10, 0.4), Vector3(-3, 5, -12), WALL)
	add_box(Vector3(2, 10, 0.4), Vector3(11, 5, -12), WALL)
	add_box(Vector3(4, 6, 0.4), Vector3(8, 7, -12), WALL)
	for x in [-12.0, 12.0]:
		add_box(Vector3(0.4, 10, 8), Vector3(x, 5, -8), WALL)
		add_box(Vector3(0.4, 10, 10), Vector3(x, 5, 5), WALL)
		add_box(Vector3(0.4, 6, 4), Vector3(x, 7, -2), WALL)
	add_label("CLARK BEAMISH STATION", Vector3(0, 9, 9.7), 180)
	add_label("glass-and-iron roof lantern overhead", Vector3(0, 9.6, 0)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_box(Vector3(2.4, 0.6, 2.4), Vector3(0, 7.2, 2), Color(0.7, 0.6, 0.3))
	add_label("a chandelier, full of nesting birds", Vector3(0, 6.4, 2)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	for i in 9:
		var flower := add_box(Vector3(0.3, 0.4, 0.3), Vector3(-9 + i * 2.2, 0.2, 4 - (i % 3) * 4.5), Color(0.8, 0.3 + (i % 3) * 0.2, 0.5))
		flower.get_child(1).disabled = true
	for x in [-7.0, 7.0]:
		add_box(Vector3(3, 0.5, 0.8), Vector3(x, 0.25, 5), IRON)
	add_label("ticket office", Vector3(-11.7, 3.4, -2), 90).font_size = 30
	add_label("control room", Vector3(11.7, 3.4, -2), -90).font_size = 30
	add_label("platforms", Vector3(8, 3.4, -11.7), 0).font_size = 30

	# The giant iron timetable board on its chains: too high to read until the
	# bookstand lowers it.
	_board = Node3D.new()
	_board.name = "Board"
	_board.position = Vector3(-3, BOARD_UP, -11.5)
	add_child(_board)
	var plate := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(8, 3, 0.3)
	plate.mesh = b
	plate.material_override = Vis.material(IRON)
	_board.add_child(plate)
	var title := Label3D.new()
	title.text = "TRAINS TO, FROM AND THROUGH KILMORE COVE"
	title.position = Vector3(0, 1.0, 0.2)
	title.font_size = 30
	_board.add_child(title)
	var rows := Label3D.new()
	rows.text = "06:10 . . . 1 . . KA-LO 1\n07:45 . . . 2 . . TE-RU 2\n09:30 . . . 1 . . NE-KA 1\n12:15 . . . 2 . . LO-TE 2\n25:00 . . . 3 . . MI-RA-SO 3"
	rows.position = Vector3(0, -0.4, 0.2)
	rows.font_size = 22
	_board.add_child(rows)
	# Only Julia makes sense of the columns (canon: the reader).
	Vis.make_private(rows, "julia")
	for x in [-3.5, 3.5]:
		var chain := MeshInstance3D.new()
		var c := BoxMesh.new()
		c.size = Vector3(0.08, 10, 0.08)
		chain.mesh = c
		chain.position = Vector3(x, 6.5, 0)
		chain.material_override = Vis.material(IRON)
		_board.add_child(chain)

	var read := JournalNote.new()
	read.who = "julia"
	read.entry_who = "julia"
	read.requires = "station.bookstand"
	read.entry_id = "the_board"
	read.title = "The timetable board"
	read.body = BOARD
	read.prompt = "Read the timetable board"
	read.reach = 2.4
	read.size = Vector3(0.01, 0.01, 0.01)
	place(read, "ReadBoard", Vector3(-3, 1, -10.4))
	GameState.changed.connect(func(_k: String) -> void: _move_board())
	_board.position.y = BOARD_DOWN if GameState.get_flag("station.bookstand", false) else BOARD_UP


func _move_board() -> void:
	var y := BOARD_DOWN if GameState.get_flag("station.bookstand", false) else BOARD_UP
	if is_equal_approx(_board.position.y, y):
		return
	create_tween().tween_property(_board, "position:y", y, 2.0)


# --- Steps 8-9: the ticket office ---------------------------------------------------

func _build_ticket_office() -> void:
	add_box(Vector3(8, 6, 0.4), Vector3(-16, 3, -8), WALL)
	add_box(Vector3(8, 6, 0.4), Vector3(-16, 3, 2), WALL)
	add_box(Vector3(0.4, 6, 10), Vector3(-20, 3, -3), WALL)
	add_box(Vector3(6, 1.1, 0.8), Vector3(-16, 0.55, -1), Color(0.45, 0.32, 0.2))

	var timetable := JournalNote.new()
	timetable.entry_id = "perpetual_timetable"
	timetable.title = "The perpetual timetable"
	timetable.body = "A great ledger chained to the counter: \"Perpetual timetable of all trains to, from and through Kilmore Cove. In force from 18 January 1936.\" Page after page of trains to places that aren't on any map. And none of them has run for years."
	timetable.prompt = "Read the ledger on the counter"
	timetable.size = Vector3(0.8, 0.1, 0.6)
	place(timetable, "Timetable1936", Vector3(-17.5, 1.15, -1))

	# The moving iron bookstand: Julia leans on it and it swings, and out in the
	# hall the board comes down on its chains (canon).
	var stand := Switch.new()
	stand.who = "julia"
	stand.flag = "station.bookstand"
	stand.prompt = "Lean on the iron bookstand"
	stand.size = Vector3(1.2, 1.8, 0.4)
	stand.color = IRON
	stand.on_used = func(_p: Node3D) -> void:
		Game.current.say("The bookstand swings round with a groan of iron. Out in the hall, chains rattle: the great timetable board is coming down!")
		Game.current.say_later("Rick: \"It's a counterweight! The bookstand's chain runs up through the ceiling to the board. Dedalus, I bet. Julia, you found it!\"", 2.5)
		Game.current.say_later("Rick worked it out, of course. And Julia's looking at him as if he'd invented trains.", 4.0, "jason")
	place(stand, "Bookstand", Vector3(-16, 0.9, -7.4))

	# Dedalus's ticket printer (canon: odd syllables and the numbers 1-3).
	var printer := CodeEntry.new()
	printer.who = "jason"
	printer.answer = "MIRASO3"
	printer.solved_flag = "station.ticket"
	printer.prompt = "Use the ticket printer"
	printer.question = "Dedalus's ticket printer. Its keys are marked with odd syllables (KA, LO, MI, NE, RA, RU, SO, TE) and the numbers 1, 2 and 3. Type a ticket:"
	printer.wrong_text = "Clack-clack... the printer spits out a blank ticket. That's not a train it knows."
	printer.size = Vector3(0.9, 0.7, 0.7)
	printer.color = Color(0.3, 0.3, 0.32)
	printer.on_used = func(_p: Node3D) -> void:
		GameState.give_item("ticket", "a ticket for the 25:00")
		GameState.add_journal("ticket", "A ticket to nowhere",
			"The printer clattered and pushed out one ticket, in violet ink:\nFROM Kilmore Cove, VIA the Old Mill and the Quarry, TO the Tunnel. Platform 3, departs 25:00. Single.\nA route. The control room must be where you set it.")
		Game.current.say("Clack-clack-clack, ding! A ticket, in violet ink: Kilmore Cove, via the Old Mill and the Quarry, to the Tunnel.")
	place(printer, "TicketPrinter", Vector3(-14, 1.45, -1))


# --- Step 10: the control room ------------------------------------------------------

func _build_control_room() -> void:
	add_box(Vector3(8, 6, 0.4), Vector3(16, 3, -8), WALL)
	add_box(Vector3(8, 6, 0.4), Vector3(16, 3, 2), WALL)
	add_box(Vector3(0.4, 6, 10), Vector3(20, 3, -3), WALL)

	# The track model: Julia reads it.
	add_box(Vector3(3, 0.9, 2), Vector3(15, 0.45, -1.5), Color(0.35, 0.5, 0.3))
	var model := Label3D.new()
	model.text = "1: L Harbour / R Old Mill\n2: L Lighthouse / R Quarry\n3: L TUNNEL / R Harbour\nRED open = move, closed = lock\nBLUE open always"
	model.position = Vector3(15, 1.6, -1.5)
	model.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	model.font_size = 22
	add_child(model)
	Vis.make_private(model, "julia")
	var note := JournalNote.new()
	note.who = "julia"
	note.entry_who = "julia"
	note.entry_id = "track_model"
	note.title = "The track model"
	note.body = TRACK_MODEL
	note.prompt = "Study the track model"
	note.size = Vector3(0.01, 0.01, 0.01)
	place(note, "TrackModel", Vector3(15, 1, -0.2))

	# The red switch levers (Jason works them).
	for i in 3:
		var lever := Lever.new()
		lever.who = "jason"
		lever.flag = "station.lever%d" % (i + 1)
		lever.prompt = "Pull red lever %d" % (i + 1)
		lever.stuck_when = "!station.red_open"
		lever.stuck_text = "Lever %d won't budge, as if something holds the points fast." % (i + 1)
		place(lever, "Lever%d" % (i + 1), Vector3(13.5 + i * 1.5, 0.1, -7))
		add_label("%d" % (i + 1), Vector3(13.5 + i * 1.5, 1.6, -7.7)).font_size = 30

	# The red and blue pipes, high up on the east wall: Jason climbs to them.
	add_climb_wall(Vector3(1, 4, 6), Vector3(19.3, 2, -3))
	for v in [["red", Color(0.75, 0.15, 0.12), -5.0], ["blue", Color(0.2, 0.35, 0.8), -1.0]]:
		add_box(Vector3(0.25, 2, 0.25), Vector3(19.7, 5.5, v[2]), v[1]).get_child(1).disabled = true
		var valve := Lever.new()
		valve.who = "jason"
		valve.color = v[1]
		valve.prompt = "Turn the %s valve" % v[0]
		if v[0] == "red":
			valve.flag = "station.red_open"
			valve.off_text = "red: CLOSED"
			valve.on_text = "red: OPEN"
		else:
			valve.flag = "station.blue_shut"
			valve.off_text = "blue: OPEN"
			valve.on_text = "blue: CLOSED"
		place(valve, "Valve_" + v[0], Vector3(19.4, 4.2, v[2]))
	add_label("red and blue pipes", Vector3(19.7, 6.8, -3), -90).font_size = 26


## Host: the route from the ticket is set (levers right, right, left) and locked
## (red closed again, blue open: Fred's routine is the resting state).
func _check_route() -> void:
	if GameState.get_flag("station.route", false) or not GameState.get_flag("station.ticket", false):
		return
	var levers := GameState.check("station.lever1 & station.lever2 & !station.lever3")
	if levers and GameState.check("!station.red_open & !station.blue_shut"):
		GameState.set_flag("station.route")
		GameState.add_journal("route", "The route is set",
			"Points 1 right to the Old Mill, points 2 right to the Quarry, points 3 left into the Tunnel; then the red valve closed to lock them, the blue one open. Somewhere out in the dark, a signal lamp came on over the tunnel mouth.")
		Game.current.say("Clunk... clunk... CLUNK. The points lock one after another, and out on the platform a green lamp comes on over the tunnel.")


# --- Step 11: the tunnel, the riddle and the train ---------------------------------

func _build_tunnel() -> void:
	add_box(Vector3(0.4, 6, 30), Vector3(3.8, 3, -27), WALL)
	add_box(Vector3(0.4, 6, 30), Vector3(12.2, 3, -27), WALL)
	add_box(Vector3(8.8, 0.4, 30), Vector3(8, 6.2, -27), Color(0.3, 0.28, 0.26))
	for x in [7.3, 8.7]:
		var rail := add_box(Vector3(0.12, 0.12, 30), Vector3(x, 0.06, -27), Color(0.35, 0.3, 0.28))
		rail.get_child(1).disabled = true
	add_label("platform 3", Vector3(4.1, 3, -14), 90).font_size = 30
	var lamp := add_box(Vector3(0.4, 0.4, 0.2), Vector3(8, 5.4, -12.4), Color(0.2, 0.2, 0.2))
	GameState.changed.connect(func(_k: String) -> void:
		lamp.get_child(0).material_override = Vis.material(Color(0.2, 0.9, 0.3) if GameState.get_flag("station.route", false) else Color(0.2, 0.2, 0.2)))

	# The locomotive, its cab at the south end.
	add_box(Vector3(3, 3.2, 8), Vector3(8, 1.6, -24), Color(0.12, 0.13, 0.15))
	add_box(Vector3(1, 1.2, 1), Vector3(8, 3.8, -26.5), Color(0.12, 0.13, 0.15))
	add_label("THE TRAIN OF ETERNAL YOUTH", Vector3(6.4, 2.6, -24), -90).font_size = 26

	var riddle := JournalNote.new()
	riddle.requires = "station.route"
	riddle.entry_id = "riddle"
	riddle.title = "Half of sand and half of wind"
	riddle.body = RIDDLE
	riddle.prompt = "Read the words on the cab"
	riddle.size = Vector3(0.6, 0.4, 0.05)
	place(riddle, "Riddle", Vector3(8, 2.2, -19.9))

	var coal := Interactable.new()
	coal.who = "jason"
	coal.requires = "journal:riddle & !b5.train_awake"
	coal.prompt = "Shovel coal into the firebox"
	coal.on_used = func(_p: Node3D) -> void: _stoke("coal")
	place(coal, "Shovel", Vector3(6.6, 1, -19.4))
	add_box(Vector3(0.8, 0.5, 0.8), Vector3(6.2, 0.25, -18.6), Color(0.08, 0.08, 0.08))
	var bellows := Interactable.new()
	bellows.who = "julia"
	bellows.requires = "journal:riddle & !b5.train_awake"
	bellows.prompt = "Pump the bellows"
	bellows.on_used = func(_p: Node3D) -> void: _stoke("wind")
	place(bellows, "Bellows", Vector3(9.4, 1, -19.4))
	add_box(Vector3(0.6, 0.4, 0.9), Vector3(9.8, 0.2, -18.6), Color(0.45, 0.3, 0.2))
	_gauge = add_label("", Vector3(8, 3.4, -19.7))
	_gauge.font_size = 36
	GameState.changed.connect(func(_k: String) -> void: _show_gauge())
	_show_gauge()

	# The dead end of the tunnel: the Horse Door, boarded up (canon, MEDIUM).
	add_box(Vector3(8.4, 6, 0.4), Vector3(8, 3, -41.8), Color(0.4, 0.38, 0.35))
	add_box(Vector3(2.4, 3.4, 0.3), Vector3(8, 1.7, -41.4), Color(0.35, 0.25, 0.15))
	for y in [0.8, 1.8, 2.8]:
		var board := add_box(Vector3(3, 0.25, 0.1), Vector3(8, y, -41.2), Color(0.5, 0.4, 0.25))
		board.rotation.z = 0.15
		_boards.append(board)
	GameState.changed.connect(func(_k: String) -> void:
		for b in _boards:
			b.visible = not GameState.get_flag("b6.horse_open", false))
	for b in _boards:
		b.visible = not GameState.get_flag("b6.horse_open", false)
	add_label("a door with a horse carved on it", Vector3(8, 4, -41.5)).font_size = 26
	var door := JournalNote.new()
	door.entry_id = "horse_door"
	door.title = "The Horse Door"
	door.body = "At the dead end of the tunnel, where the rails stop: a door. Old, dark wood, with a horse carved on it, and boarded across. It's like the Door at Argo.\nRick: \"Then it needs its own key. The Horse key. And if anybody had it, it was Black Vulcano.\""
	door.prompt = "Look at the boarded-up door"
	door.size = Vector3(0.01, 0.01, 0.01)
	place(door, "HorseDoor", Vector3(8, 1, -40.2))


func _show_gauge() -> void:
	var p := int(GameState.get_flag("station.pressure", 0))
	if GameState.get_flag("b5.train_awake", false):
		_gauge.text = "PRESSURE: 100+ !"
	else:
		_gauge.text = "PRESSURE: %d" % p


## Host: one shovel of coal or one pump of the bellows. In turn, each adds
## STOKE; the same twice in a row chokes the fire (half and half, as the riddle
## says). Past a hundred, the train wakes.
func _stoke(kind: String) -> void:
	if GameState.get_flag("b5.train_awake", false):
		return
	var p := int(GameState.get_flag("station.pressure", 0))
	if GameState.get_flag("station.last_stoke", "") == kind:
		GameState.set_flag("station.pressure", max(0, p - CHOKE))
		GameState.set_flag("station.last_stoke", "")
		Game.current.say("Too much coal: the fire chokes and smokes, and the needle drops." if kind == "coal" else "Too much air: the flames gutter, and the needle drops.")
		return
	p += STOKE
	GameState.set_flag("station.last_stoke", kind)
	GameState.set_flag("station.pressure", p)
	if p >= HUNDRED:
		_wake_train()


func _wake_train() -> void:
	GameState.set_flag("b5.train_awake")
	GameState.add_journal("train_awake", "The Train of Eternal Youth",
		"A hundred! The needle swung over, the whistle shrieked, and the old locomotive woke up, steaming and shaking, its lamp shining down the tunnel at the boarded-up Horse Door.\nBut nobody can ride it anywhere: the Door needs the Horse key, and Black Vulcano had the keys. Wherever he is, he isn't here.\nBack to Argo, to tell Nestor.")
	Game.current.say("PHWEEEEE! The needle swings past a hundred, the whistle shrieks and the Train of Eternal Youth shudders awake, steam pouring from every joint!")


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_check_route()
	# The fire dies down if nobody tends it.
	var p := int(GameState.get_flag("station.pressure", 0))
	if p <= 0 or GameState.get_flag("b5.train_awake", false):
		return
	_decay_t += delta
	if _decay_t >= 1.0:
		_decay_t = 0.0
		GameState.set_flag("station.pressure", max(0, p - 4))


# --- Fred and Rick ----------------------------------------------------------------

func _build_people() -> void:
	var fred := Npc.new()
	fred.npc_name = "Fred Dormiveglia"
	fred.color = Color(0.55, 0.5, 0.4)
	fred.lines = [
		["", "*yaaawn* Take your time, take your time. I'll just... rest my eyes."],
	]
	fred.on_used = func(_p: Node3D) -> void:
		if GameState.has_journal("fred_valves"):
			return
		GameState.add_journal("fred_valves", "Fred's valves",
			"Fred, yawning: \"Twice a week I come down here and turn the valves in the control room. Red closed, blue open. Mr Vulcano paid me in advance, years and years of it, before he went away. What for? Haven't the foggiest.\"\nHe's been doing it for decades without knowing why.")
		Game.current.say("Fred Dormiveglia: \"The valves? Twice a week: red closed, blue open. Mr Vulcano paid me in advance, years of it. What for? Haven't the foggiest. *yaaawn*\"")
	place(fred, "Fred", Vector3(-5, 1, 6))

	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.walk_speed = 4.0
	rick.present = "!b6.playing_rick"
	rick.stations = [
		["", Vector3(2.5, 1, 4)],
		["station.bookstand", Vector3(-14.5, 1, -4)],
		["station.ticket", Vector3(14, 1, -4)],
		["station.route", Vector3(10.5, 1, -17)],
	]
	rick.lines = [
		["", "Look at this place. The board up there must be the timetable, but you'd need a ladder to read it. Let's try the ticket office."],
		["station.bookstand", "A counterweight! Julia, read the board out. Jason, there's a printer on the counter with letters on its keys."],
		["station.ticket", "Kilmore Cove to the Tunnel, via the Old Mill and the Quarry. The control room: the points must be set from there. Julia, the model shows which lever does what."],
		["station.route", "The lamp's green. There's writing on the cab of the locomotive: let's read it."],
		["journal:riddle", "Half and half. Jason shovels, Julia pumps, turn and turn about. Don't let the fire die down!"],
		["b5.train_awake", "It's alive! But look where the rails go: straight to that door. It's a Door, like yours. We'd need the Horse key... Let's get back to Argo and tell Nestor."],
	]
	place(rick, "Rick", Vector3(2.5, 1, 4))

	# Book 6 step 9: Ulysses Moore and the Horse key (canon: Ulysses and Rick go
	# through the station Door, MEDIUM ✅; the Horse key and the train ride are
	# adaptation). For Rick (Julia's player) only.
	var ulysses := Npc.new()
	ulysses.npc_name = "Ulysses Moore"
	ulysses.color = Color(0.45, 0.4, 0.3)
	ulysses.present = "b6.father"
	ulysses.lines = [
		["b6.father", "Leonard told you. Good. Now: hold on to something."],
		["b6.horse_open", "All aboard, Rick. Next stop, the Garden of Prester John."],
	]
	ulysses.on_used = func(_p: Node3D) -> void:
		if GameState.get_flag("b6.horse_open", false):
			return
		GameState.set_flag("b6.horse_open")
		GameState.add_journal("horse_key", "Rick: the Horse key",
			"Ulysses took a key out of his waistcoat: old iron, with a horse's head. \"Victor left it with me, the last time he went through. He never trusted himself to keep it.\" He walked down the tunnel, tore the boards off the Horse Door and unlocked it. Behind it: mist, and the smell of grass.\n(Victor? Black Vulcano's real name, he says.)", "julia")
		Game.current.say("Ulysses takes out an iron key with a horse's head, rips the boards off the Horse Door and turns the key. Mist rolls into the tunnel. \"All aboard.\"", "julia")
	place(ulysses, "Ulysses", Vector3(10.5, 1, -18.5))
	var board := Switch.new()
	board.who = "julia"
	board.flag = "b6.rick_ready"
	board.requires = "b6.horse_open"
	board.prompt = "Climb aboard the train"
	board.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("aboard", "Rick: through the Horse Door",
			"Ulysses opened the regulator, the Train of Eternal Youth shrieked, and we rolled down the tunnel straight at the open Horse Door, and through it, into the mist.\nHang on, Julia. We're coming.", "julia")
		Game.current.say("The whistle shrieks, the wheels bite, and the Train of Eternal Youth plunges through the Horse Door into the mist...", "julia")
	place(board, "BoardTrain", Vector3(7.2, 1, -19.4))
