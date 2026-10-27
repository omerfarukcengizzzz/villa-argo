extends Level
## Venice, book 4 (docs/book4-design.md). Pass A: the Metis's hidden mooring
## under a palazzo and the passage with the Door back to Villa Argo. Two
## Venetian beggars and their dog slip through the Door left ajar (canon names
## ✅; dog LOW); Jason runs after them and the Door shuts behind him, splitting
## the twins. Julia and Rick stay. Pass B, Julia's half (steps 8-11): the campo
## of masks where Count Cenere patrols, the Callers' print shop and the
## forbidden Encyclopedie, the lowercase "d", the flooded boat shed and the
## hidden print room, and Penelope's house. Pass C (steps 12-14, 17): Turtle
## Park and the pigeon at the well, the Master Watchmaker, the Black Gondolier
## on the Fondamenta of the Masks (to the isle_of_masks level), and, after the
## fire, the Metis home.
## No exact year or canal routes (ref §5).
##
## Map (north = -z): the mooring z 0..12 with the Metis to the south; the
## Door passage z -8..0 (Door on its west wall); the campo z -8..-34
## (x -20..20); north of it the Callers' print shop (x -6..6), the flooded boat
## shed (x 6..16) and the hidden print room (x 16..20); Penelope's house on
## the west side (x -20..-10, z -24..-12). East through a gap in the campo wall:
## Turtle Park (x 20..42, z -8..-24), the Master Watchmaker's shop (x 34..42,
## z -24..-32) and the Fondamenta of the Masks (z -34..-44).

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"
const ISLE := "res://scenes/levels/isle_of_masks.tscn"
const UNDERGROUND := "res://scenes/levels/argo_underground.tscn"
const STONE := Color(0.7, 0.62, 0.55)
## Count Cenere's round of the campo, one leg every CENERE_SECONDS.
const CENERE_ROUTE := [Vector3(-8, 1, -13), Vector3(10, 1, -13), Vector3(10, 1, -28), Vector3(-8, 1, -28)]
const CENERE_SECONDS := 6.0
const CAMPO_ENTRY := Vector3(0, 1, -6)
## Type trays at the Callers'. Only Julia sees the letters up close.
const TRAYS := [
	["Tray A", "d: a plain, straight stem."],
	["Tray B", "d: a little flag at the top of the stem."],
	["Tray C", "d: the stem curls back over the bowl, like a shepherd's crook."],
	["Tray D", "d: round and fat, with a short stem."],
]
const RIGHT_TRAY := "Tray C"

var _cenere_t := 0.0


func _init() -> void:
	origin = Vector3(15000, 0, 0)


func _build() -> void:
	entries = {"default": {"jason": Vector3(-1, 1, 9), "julia": Vector3(1, 1, 9)}}
	fall_y = -10.0
	add_environment(Color(0.55, 0.65, 0.8))

	# The mooring.
	add_box(Vector3(10, 0.5, 12), Vector3(0, -0.25, 6), STONE)
	add_box(Vector3(0.5, 6, 12), Vector3(-5, 3, 6), STONE)
	add_box(Vector3(0.5, 6, 12), Vector3(5, 3, 6), STONE)
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 14)
	water.mesh = plane
	water.material_override = Vis.material(Color(0.15, 0.35, 0.4))
	water.position = Vector3(0, -0.6, 19)
	add_child(water)
	add_box(Vector3(4, 2, 10), Vector3(0, 0, 18), Color(0.4, 0.28, 0.18))
	add_label("METIS", Vector3(2.05, 0.3, 18), 90)

	# The passage with the Door back to Villa Argo.
	add_box(Vector3(6, 0.5, 8), Vector3(0, -0.25, -4), STONE)
	add_box(Vector3(0.5, 5, 8), Vector3(-3, 2.5, -4), STONE)
	add_box(Vector3(0.5, 5, 8), Vector3(3, 2.5, -4), STONE)
	add_box(Vector3(0.2, 2.6, 1.6), Vector3(-2.75, 1.3, -4), Color(0.28, 0.18, 0.1))
	add_label("the Door", Vector3(-2.6, 2.9, -4), 90)

	var chase := LevelExit.new()
	chase.who = "jason"
	chase.solo = true
	chase.level = VILLA_ARGO
	chase.entry = "door"
	chase.requires = "b4.intruders_through & !b4.split"
	chase.prompt = "Run after them through the Door!"
	chase.on_used = _split
	place(chase, "ChaseThroughDoor", Vector3(-2, 1, -4))

	_build_intruders()
	_build_campo()
	_build_callers()
	_build_print_room()
	_build_penelope_house()
	_build_east()
	_build_rick()


func _host_setup() -> void:
	if not GameState.get_flag("b4.intruders_seen", false):
		GameState.set_flag("b4.intruders_seen")
		_intruders_slip_through()


## Step 3 (canon names ✅): two Venetians and a dog slip into the Door passage.
func _intruders_slip_through() -> void:
	await get_tree().create_timer(4.0).timeout
	Game.current.say("Two ragged figures and a scruffy dog dart past the Metis and into the passage: the Door! Rick: \"It's still open... they're going to the house!\"")
	GameState.set_flag("b4.intruders_through")


## The Door slams behind Jason; the twins are split.
func _split(_player: Node3D) -> void:
	GameState.set_flag("b4.split")
	Game.current.say("Jason dives through the Door after them, and it slams shut behind him. Julia and Rick are on their own in Venice.")
	Game.current.say("Villa Argo. The stone sitting room has been turned upside down. Somewhere in the house, a dog barks.", "jason")


func _build_intruders() -> void:
	var names := [["Don Diego Valente", Vector3(-1.5, 1, 4)], ["Dieguita", Vector3(-0.5, 1, 4.5)]]
	for n in names:
		var npc := Npc.new()
		npc.npc_name = n[0]
		npc.color = Color(0.45, 0.35, 0.25)
		npc.who = "nobody"
		npc.present = "!b4.intruders_through"
		place(npc, n[0].replace(" ", ""), n[1])


func respawn_point(role: String, fell_from: Vector3) -> Vector3:
	if fell_from.x > 5.5 and fell_from.z < -33.0:
		return Vector3(5, 1, -40)
	return spawn_point(role, "default")


# --- The campo and Count Cenere (step 8) ---------------------------------------

func _build_campo() -> void:
	add_box(Vector3(40, 0.5, 26), Vector3(0, -0.25, -21), STONE)
	add_box(Vector3(26, 0.5, 10), Vector3(-7, -0.25, -39), STONE)
	add_box(Vector3(4, 0.5, 10), Vector3(18, -0.25, -39), STONE)
	add_box(Vector3(17, 4, 0.5), Vector3(-11.5, 2, -8), STONE)
	add_box(Vector3(17, 4, 0.5), Vector3(11.5, 2, -8), STONE)
	add_box(Vector3(0.5, 4, 36), Vector3(-20, 2, -26), STONE)
	add_box(Vector3(0.5, 4, 7), Vector3(20, 2, -11.5), STONE)
	add_box(Vector3(0.5, 4, 25), Vector3(20, 2, -31.5), STONE)
	add_box(Vector3(40, 4, 0.5), Vector3(0, 2, -44), STONE)
	add_label("Campo Santa Marina", Vector3(0, 3.4, -8.3), 180)

	# Carnival crowd: harmless, except one.
	var crowd := [
		["Masked man (white mask)", Vector3(-5, 1, -17)], ["Masked woman (gold mask, feathers)", Vector3(4, 1, -20)],
		["Masked man (white mask)", Vector3(13, 1, -18)], ["Masked woman (black velvet mask)", Vector3(-12, 1, -27)],
		["Masked man (red mask, long nose)", Vector3(6, 1, -31)],
	]
	for i in crowd.size():
		var npc := Npc.new()
		npc.npc_name = crowd[i][0]
		npc.color = Color(0.6, 0.5, 0.65)
		npc.present = "b4.split"
		npc.lines = [["", ["Buona sera! Lovely mask, signorina.", "Have you seen the fireworks?", "Shh. The guard is about tonight.", "Mind your purse in the crowd.", "Carnival! Carnival!"][i]]]
		place(npc, "Reveller%d" % i, crowd[i][1])

	var cenere := Npc.new()
	cenere.npc_name = "Masked man (ash-grey mask, silver tear)"
	cenere.color = Color(0.35, 0.35, 0.38)
	cenere.who = "nobody"
	cenere.present = "b4.split"
	cenere.walk_speed = 3.0
	var stations := [["", CENERE_ROUTE[0]]]
	for i in CENERE_ROUTE.size():
		stations.append(["venice.cenere=%d" % i, CENERE_ROUTE[i]])
	cenere.stations = stations
	place(cenere, "Cenere", CENERE_ROUTE[0])


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or not GameState.get_flag("b4.split", false):
		return
	_cenere_t += delta
	if _cenere_t >= CENERE_SECONDS:
		_cenere_t = 0.0
		GameState.set_flag("venice.cenere", (int(GameState.get_flag("venice.cenere", 0)) + 1) % CENERE_ROUTE.size())
	for p in Game.current.get_players():
		if p.role == "julia" and Game.current.level_for("julia") == self and sees(get_node("Cenere"), p, 5.0, 100.0):
			p.teleport.rpc(to_global(CAMPO_ENTRY), PI)
			Game.current.say("The man in the ash-grey mask turns. \"You, girl! Who are you with?\" Two guards in white masks hustle you back to the canal steps.", "julia")


# --- The Callers' print shop (steps 9-10) --------------------------------------

func _build_callers() -> void:
	var shop := Color(0.6, 0.5, 0.45)
	add_box(Vector3(5, 4, 0.5), Vector3(-3.5, 2, -34), shop)
	add_box(Vector3(5, 4, 0.5), Vector3(3.5, 2, -34), shop)
	add_box(Vector3(0.5, 4, 10), Vector3(-6, 2, -39), shop)
	add_box(Vector3(0.5, 4, 4), Vector3(6, 2, -36), shop)
	add_box(Vector3(0.5, 4, 4), Vector3(6, 2, -42), shop)
	add_label("A. & R. CALLER, PRINTERS", Vector3(0, 3.5, -33.7), 0)
	add_box(Vector3(3, 1, 1), Vector3(0, 0.5, -41.5), Color(0.4, 0.3, 0.2))
	add_label("something under a cloth", Vector3(0, 1.4, -41.5)).billboard = BaseMaterial3D.BILLBOARD_ENABLED

	var alberto := Npc.new()
	alberto.npc_name = "Alberto Caller"
	alberto.color = Color(0.4, 0.35, 0.3)
	alberto.present = "b4.split"
	alberto.lines = [
		["", "We print almanacs and wedding notices, signorina. Nothing more. Good evening."],
		["journal:encyclopedie", "Put that cloth back! Do you want the guard to hang us all?"],
		["venice.d_match", "You've a sharp eye. Yes: I printed that book myself, on a machine a foreigner built for me. Signor Dedalus. Come, through the boat shed. Mind the water."],
		["venice.printroom", "Penelope? There was a Penelope, years ago, in the house with the blue door on the west side of the campo. Her family's long gone. Here, the key."],
	]
	place(alberto, "Alberto", Vector3(-3, 1, -38))

	var rossella := Npc.new()
	rossella.npc_name = "Rossella Caller"
	rossella.color = Color(0.55, 0.4, 0.4)
	rossella.present = "b4.split"
	rossella.lines = [
		["", "Strangers in carnival time... You haven't seen two beggars and a dog, have you? They were sniffing round here this morning. Beggars! They fear nothing in this city but the secret guard. One glimpse of a guard's white mask and they run."],
	]
	rossella.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("beggars_fear", "What Venetian beggars fear",
			"Rossella Caller: beggars in Venice fear nothing but the secret guard. One glimpse of a guard's white mask and they run.\nJason needs to know this.", "julia")
	place(rossella, "Rossella", Vector3(3, 1, -38))

	var book := JournalNote.new()
	book.who = "julia"
	book.requires = "b4.split"
	book.entry_id = "encyclopedie"
	book.title = "The forbidden book"
	book.body = "Under the cloth in the Callers' shop: big volumes of the Encyclopedie of Diderot and d'Alembert, forbidden in Venice. Freshly printed. Every lowercase d in it has the same odd shape: the stem curls back over the bowl, like a shepherd's crook."
	book.prompt = "Lift the cloth"
	book.size = Vector3(0.01, 0.01, 0.01)
	place(book, "Encyclopedie", Vector3(0, 1, -40.6))

	# The type trays: close-up, only Julia can make out the letters.
	var text := "Type trays on the shelf:\n"
	for t in TRAYS:
		text += "%s - %s\n" % t
	var trays := add_label(text, Vector3(5.6, 2, -39), -90)
	trays.font_size = 26
	Vis.make_private(trays, "julia")
	var compare := ChoicePoint.new()
	compare.who = "julia"
	compare.requires = "journal:encyclopedie & journal:old_owl_slip & !venice.d_match"
	compare.prompt = "Compare the type with the Old Owl's slip"
	compare.question = "Which tray's d matches the slip from the Old Owl?"
	compare.options_for = func() -> Array: return TRAYS.map(func(t: Array) -> Array: return [t[0], true])
	compare.on_choice = func(_p: Node3D, choice: String) -> void:
		if choice == RIGHT_TRAY:
			GameState.set_flag("venice.d_match")
			Game.current.say("The slip's d and Tray C's d are the same letter: Dedalus's type. And it's the type of the forbidden book. Alberto goes very still.", "julia")
		else:
			Game.current.say("No... the d on the slip curls back on itself. That's not it.", "julia")
	place(compare, "TypeTrays", Vector3(5, 1, -39))

	var shed_door := Door.new()
	shed_door.size = Vector3(2, 3, 0.3)
	shed_door.open_flag = "venice.d_match"
	shed_door.color = Color(0.35, 0.25, 0.18)
	place(shed_door, "ShedDoor", Vector3(6, 0, -39)).rotation_degrees.y = 90


# --- The flooded boat shed and the hidden print room (step 10) -----------------

func _build_print_room() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 10)
	water.mesh = plane
	water.material_override = Vis.material(Color(0.15, 0.3, 0.35))
	water.position = Vector3(11, -0.6, -39)
	add_child(water)
	add_box(Vector3(10, 4, 0.5), Vector3(11, 2, -34), STONE)
	add_label("the flooded boat shed", Vector3(11, 3.3, -34.3), 180).font_size = 28
	# Planks with 1.4 m of water between them: jump, or swim back to the shop.
	for x in [7.0, 9.4, 11.8, 14.2]:
		add_box(Vector3(1.0, 0.3, 2), Vector3(x, -0.15, -39), Color(0.45, 0.32, 0.2))
	add_box(Vector3(4, 4, 0.5), Vector3(18, 2, -34), STONE)

	add_box(Vector3(2, 2, 1.5), Vector3(18.5, 1, -42.5), Color(0.5, 0.42, 0.3))
	add_label("a printing press full of brass gears", Vector3(18.5, 2.5, -42.5)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var arrive := Switch.new()
	arrive.flag = "venice.printroom"
	arrive.requires = "venice.d_match"
	arrive.prompt = "Look at the press"
	place(arrive, "Press", Vector3(18.5, 1, -41.2))
	var plate := JournalNote.new()
	plate.who = "julia"
	plate.entry_who = "julia"
	plate.requires = "venice.printroom"
	plate.entry_id = "right_key"
	plate.title = "The right key"
	plate.body = "On the press in the Callers' hidden print room, a brass plate with Dedalus's d: \"My Old Owl answers only to its own key.\"\nIts own key: the Owl key! Jason needs to know this."
	plate.prompt = "Read the brass plate"
	plate.size = Vector3(0.05, 0.3, 0.4)
	place(plate, "BrassPlate", Vector3(19.7, 1.5, -40))


# --- Penelope's house (step 11) ------------------------------------------------

func _build_penelope_house() -> void:
	var house := Color(0.75, 0.68, 0.6)
	add_box(Vector3(10, 4, 0.5), Vector3(-15, 2, -12), house)
	add_box(Vector3(10, 4, 0.5), Vector3(-15, 2, -24), house)
	add_box(Vector3(0.5, 4, 5), Vector3(-10, 2, -14.5), house)
	add_box(Vector3(0.5, 4, 5), Vector3(-10, 2, -21.5), house)
	add_label("a house with a blue door", Vector3(-9.7, 3.4, -18), -90).font_size = 28
	var door := Door.new()
	door.size = Vector3(2, 3, 0.3)
	door.open_flag = "venice.penelope_key"
	door.color = Color(0.2, 0.3, 0.6)
	place(door, "BlueDoor", Vector3(-10, 0, -18)).rotation_degrees.y = 90
	var key := Switch.new()
	key.who = "julia"
	key.flag = "venice.penelope_key"
	key.requires = "venice.printroom"
	key.prompt = "Unlock the blue door with Alberto's key"
	place(key, "BlueDoorLock", Vector3(-9.2, 1, -18))

	add_box(Vector3(1.6, 0.6, 2.2), Vector3(-17.5, 0.3, -14.5), Color(0.6, 0.45, 0.5))
	add_label("a little bed, a doll, a sampler", Vector3(-17.5, 1.3, -14.5)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var room := JournalNote.new()
	room.who = "julia"
	room.requires = "venice.penelope_key"
	room.entry_id = "girls_room"
	room.title = "The girl's room"
	room.body = "A girl's room, kept as if she'd just stepped out: a little bed, a doll, a sampler stitched with flowers and the name PENELOPE. On the wall, a portrait of a girl with dark eyes. The frame hangs a little crooked."
	room.prompt = "Look around the girl's room"
	room.size = Vector3(0.01, 0.01, 0.01)
	place(room, "GirlsRoom", Vector3(-16, 1, -15))

	add_box(Vector3(0.1, 1.4, 1.1), Vector3(-19.7, 2, -20), Color(0.5, 0.35, 0.2))
	add_label("portrait of a girl", Vector3(-19.5, 2.9, -20), 90).font_size = 24
	var frame := Switch.new()
	frame.who = "julia"
	frame.flag = "venice.frame"
	frame.requires = "journal:girls_room"
	frame.prompt = "Look behind the frame"
	place(frame, "Frame", Vector3(-19, 1.4, -20))
	var letters := JournalNote.new()
	letters.requires = "venice.frame"
	letters.entry_id = "penelope_letters"
	letters.title = "Letters behind the frame"
	letters.body = "Tucked behind the portrait, a bundle of letters in a girl's handwriting, then a young woman's. The last one says goodbye: she is leaving Venice for good, with a young Englishman called Ulysses Moore, through a door no one else believes in.\nPenelope Moore was born here, in Venice, two hundred years ago.\nThe last letter mentions \"the turtles in the park, where Peter feeds the pigeons\"."
	letters.prompt = "Read the letters"
	letters.size = Vector3(0.3, 0.05, 0.25)
	letters.on_used = func(_p: Node3D) -> void: GameState.set_flag("b4.penelope")
	place(letters, "Letters", Vector3(-19, 1.0, -20.8))


# --- East: Turtle Park, the Master Watchmaker, the Fondamenta (steps 12-14) ---

func _build_east() -> void:
	add_box(Vector3(22, 0.5, 36), Vector3(31, -0.25, -26), STONE)
	add_box(Vector3(0.5, 4, 36), Vector3(42, 2, -26), STONE)
	add_box(Vector3(22, 4, 0.5), Vector3(31, 2, -8), STONE)
	add_box(Vector3(22, 4, 0.5), Vector3(31, 2, -44), STONE)
	add_label("Turtle Park", Vector3(20.3, 3.2, -17), 90)

	# Step 12 (chapter titles Turtle Park, The Well and the Pigeons; content
	# adaptation): stone turtles, an old well, and a pigeon with a message.
	for i in 3:
		add_box(Vector3(1.2, 0.5, 1.6), Vector3(25 + i * 3, 0.25, -12), Color(0.5, 0.55, 0.45))
	add_label("stone turtles", Vector3(28, 1.2, -12)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_box(Vector3(2, 1, 2), Vector3(32, 0.5, -18), Color(0.55, 0.5, 0.45))
	add_label("an old well, pigeons on its rim", Vector3(32, 1.8, -18)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var pigeon := JournalNote.new()
	pigeon.who = "julia"
	pigeon.requires = "b4.penelope"
	pigeon.entry_id = "pigeon_message"
	pigeon.title = "A pigeon at the well"
	pigeon.body = "One fat grey pigeon at the old well is too tame: it hops onto Julia's hand. There's a little brass ring on its leg with a rolled-up note, in a spidery hand with that same curling d:\n\"To the Master Watchmaker: wind nothing for anyone but me. P. D.\"\nThe Master Watchmaker knows where Peter is."
	pigeon.prompt = "Hold out a hand to the pigeons"
	pigeon.size = Vector3(0.01, 0.01, 0.01)
	place(pigeon, "Pigeon", Vector3(32, 1, -16.6))

	# Step 13: the Master Watchmaker (chapter title; content adaptation).
	var shop := Color(0.55, 0.5, 0.6)
	add_box(Vector3(8, 4, 0.5), Vector3(38, 2, -24), shop)
	add_box(Vector3(8, 4, 0.5), Vector3(38, 2, -32), shop)
	add_box(Vector3(0.5, 4, 3), Vector3(34, 2, -25.5), shop)
	add_box(Vector3(0.5, 4, 3), Vector3(34, 2, -30.5), shop)
	add_label("MASTER WATCHMAKER", Vector3(33.7, 3.4, -28), -90).font_size = 28
	var master := Npc.new()
	master.npc_name = "The Master Watchmaker"
	master.color = Color(0.5, 0.45, 0.55)
	master.present = "b4.split"
	master.lines = [
		["", "Clocks, watches, automata. Look, don't touch."],
		["journal:pigeon_message", "His pigeon came to you? Then he'd want you to know. I can't tell you where my master is: I truly don't know. Only one man does: the Black Gondolier. He waits by the last lamp on the Fondamenta of the Masks, and he rows for nobody without the word."],
	]
	master.on_used = func(_p: Node3D) -> void:
		if GameState.has_journal("pigeon_message"):
			GameState.set_flag("b4.watchmaker")
	place(master, "MasterWatchmaker", Vector3(39, 1, -28))

	# Step 14: the Black Gondolier (canon, HIGH) and the word from the Old Owl.
	for x in [24.0, 30.0, 36.0, 40.5]:
		add_box(Vector3(0.2, 3, 0.2), Vector3(x, 1.5, -41), Color(0.2, 0.2, 0.22))
	add_label("the last lamp", Vector3(40.5, 3.4, -41)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_label("Fondamenta of the Masks", Vector3(31, 3.2, -43.7), 0).font_size = 32
	add_box(Vector3(5, 0.6, 1.4), Vector3(38, -0.1, -43), Color(0.08, 0.08, 0.1))
	var gondolier := Npc.new()
	gondolier.npc_name = "The Black Gondolier"
	gondolier.color = Color(0.1, 0.1, 0.12)
	gondolier.present = "b4.split"
	gondolier.lines = [["", "..."], ["b4.watchmaker", "...(He waits. He's listening for a word.)"]]
	place(gondolier, "Gondolier", Vector3(40.5, 1, -42.5))
	var word := CodeEntry.new()
	word.who = "julia"
	word.requires = "b4.watchmaker"
	word.answer = "SERENISSIMA"
	word.solved_flag = "b4.gondolier"
	word.prompt = "Say the word to the Gondolier"
	word.question = "The word:"
	word.wrong_text = "The Black Gondolier doesn't move."
	word.size = Vector3(0.01, 0.01, 0.01)
	word.on_used = func(_p: Node3D) -> void:
		Game.current.move_twin("julia", ISLE)
		Game.current.say("\"Serenissima.\" The Black Gondolier bows, and rows Julia and Rick out across the dark lagoon to a little island hung with masks.", "julia")
	place(word, "SayWord", Vector3(39.4, 1, -41.6))

	# Step 17: home on the Metis, after the fire.
	var home := LevelExit.new()
	home.who = "julia"
	home.solo = true
	home.level = UNDERGROUND
	home.entry = "beach"
	home.requires = "b4.isle_escaped & b4.split"
	home.prompt = "Sail home on the Metis"
	home.on_used = func(_p: Node3D) -> void:
		GameState.set_flag("b4.julia_home")
		Game.current.say("The Metis glides out of the mist into the sea cave under Villa Argo, Julia and Rick on board.", "julia")
		Game.current.say("A voice echoes up from under the house... The Metis is back! Run down to the beach.", "jason")
	place(home, "SailHome", Vector3(-1, 1, 10.5))


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.walk_speed = 4.0
	rick.stations = [
		["", Vector3(2, 1, 8)],
		["b4.split", Vector3(1, 1, -2)],
		["journal:encyclopedie", Vector3(1.5, 1, -37)],
		["venice.printroom", Vector3(17.5, 1, -38)],
		["venice.penelope_key", Vector3(-12, 1, -18)],
		["b4.penelope", Vector3(28, 1, -16)],
		["b4.watchmaker", Vector3(37, 1, -39)],
		["b4.isle_escaped", Vector3(1, 1, 9)],
	]
	rick.lines = [
		["", "Venice! Two hundred years ago, by the look of it. Look at all those masks."],
		["b4.intruders_through", "They went through the Door! Somebody has to go after them!"],
		["b4.split", "The Door's shut and Jason's on the other side. It's up to us now, Julia. There's a guard about in a grey mask: Jason might know which one's dangerous. And the Old Owl's slip had that funny d on it: let's find who printed it."],
		["journal:encyclopedie", "Look at the d on the Old Owl's slip: the stem curls right back over the bowl. Compare it with their type trays, Julia. You've got the sharper eyes."],
		["venice.printroom", "These gears... I'd know them anywhere. Same as the House of Mirrors. Dedalus built this press! And Alberto mentioned someone called Penelope..."],
		["b4.penelope", "Penelope Moore was born here. Two hundred years ago. And \"Peter\" feeds the pigeons in a park with turtles. Peter Dedalus!"],
		["journal:pigeon_message", "The Master Watchmaker! His shop's on the far side of the park."],
		["b4.watchmaker", "The Black Gondolier needs a word. Julia, did Jason find anything at home? Ask him!"],
		["b4.isle_escaped", "Black Vulcano... Let's go home and tell Jason. The Metis is waiting."],
	]
	place(rick, "Rick", Vector3(2, 1, 8))
