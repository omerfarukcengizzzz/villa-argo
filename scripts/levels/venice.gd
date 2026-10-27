extends Level
## Venice, book 4 (docs/book4-design.md). Pass A: the Metis's hidden mooring
## under a palazzo and the passage with the Door back to Villa Argo. Two
## Venetian beggars and their dog slip through the Door left ajar (canon names
## ✅; dog LOW); Jason runs after them and the Door shuts behind him, splitting
## the twins. Julia and Rick stay. The streets, the Callers and Penelope's house
## are Pass B. No exact year or canal routes (ref §5).
##
## Map (north = -z): the mooring z 0..12 with the Metis to the south; the
## Door passage z -8..0 (Door on its west wall); the way into the city north.

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"
const STONE := Color(0.7, 0.62, 0.55)


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
	add_box(Vector3(6, 5, 0.5), Vector3(0, 2.5, -8), STONE)
	add_label("(the city: book 4 Pass B)", Vector3(0, 2.5, -7.7), 0).font_size = 24

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
	_build_temporary_notes()
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


## Temporary until Pass B: what Julia learns at the Callers' (what frightens
## the beggars) and in the hidden print room (the right key for the Old Owl).
func _build_temporary_notes() -> void:
	var proverb := JournalNote.new()
	proverb.who = "julia"
	proverb.entry_who = "julia"
	proverb.requires = "b4.split"
	proverb.entry_id = "beggars_fear"
	proverb.title = "What Venetian beggars fear"
	proverb.body = "A Venetian boatman by the mooring laughs: \"Beggars? They fear nothing in this city but the secret guard. One glimpse of a guard's white mask and they run.\"\nJason needs to know this."
	proverb.prompt = "Ask the boatman about beggars"
	proverb.size = Vector3(0.01, 0.01, 0.01)
	place(proverb, "BeggarsFear", Vector3(3.5, 1, 7))
	var plate := JournalNote.new()
	plate.who = "julia"
	plate.entry_who = "julia"
	plate.requires = "b4.split"
	plate.entry_id = "right_key"
	plate.title = "The right key"
	plate.body = "Engraved on a brass plate, with Dedalus's \"d\": \"My Old Owl answers only to its own key.\"\nIts own key: the Owl key! Jason needs to know this."
	plate.prompt = "Read the brass plate"
	plate.size = Vector3(0.4, 0.3, 0.05)
	place(plate, "BrassPlate", Vector3(2.7, 1.5, -2))


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.walk_speed = 4.0
	rick.stations = [["", Vector3(2, 1, 8)], ["b4.split", Vector3(1, 1, -2)]]
	rick.lines = [
		["", "Venice! Two hundred years ago, by the look of it. Look at all those masks."],
		["b4.intruders_through", "They went through the Door! Somebody has to go after them!"],
		["b4.split", "The Door's shut and Jason's on the other side. It's up to us now, Julia. Let's find out what we can."],
	]
	place(rick, "Rick", Vector3(2, 1, 8))
