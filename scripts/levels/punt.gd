extends Level
## The Land of Punt, book 2 (docs/book2-design.md). Pass A: Part 1, together:
## the hidden harbour where the Metis lands, the chest of local clothes, the
## hall with the Door back to Villa Argo, the town street, the mastaba and the
## wall that collapses, splitting the twins (Julia through the Door, Jason and
## Rick stuck here). Pass B, Jason's half (steps 4-9): Maruk under the beam,
## the House of Life and Ulysses's note, Oblivia in the market, the map shop,
## the errands, and the legend with the Ballad. The corridors under the map
## shop are the punt_corridors level (Pass C); with the map gone to Oblivia,
## Jason comes home through the Door once Julia has opened it from the house
## (step 18). No date or pharaoh for Punt (ref §5).
## Punt journal entries are Jason's alone: Julia only learns them if he tells her.
##
## Map (north = -z): harbour z -2..10 with the Metis moored to the south;
## the Door hall z -10..-2 (Door on its west wall); the town street
## z -42..-10 with the old wall on the east side and the mastaba at the end.
## Behind the old wall, a lane east to the House of Life (x 14..30); through a
## gap in the west houses, the market square (x -24..-7) with the map shop.

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"
const CORRIDORS := "res://scenes/levels/punt_corridors.tscn"

const STONE := Color(0.78, 0.68, 0.5)
const SAND := Color(0.88, 0.78, 0.55)

var _old_wall: StaticBody3D
var _rubble: Node3D


func _init() -> void:
	origin = Vector3(3000, 0, 0)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1, 1, 8), "julia": Vector3(1, 1, 8)},
		"map_shop": {"jason": Vector3(-20, 1, -23.5), "julia": Vector3(-19, 1, -23.5)},
	}
	fall_y = -10.0
	add_environment(Color(0.75, 0.85, 0.95))
	_sun.light_energy = 1.3

	_build_harbour()
	_build_hall()
	_build_town()
	_build_house_of_life()
	_build_market()
	_build_rick()

	GameState.changed.connect(_on_state_changed)
	_on_state_changed("")


func respawn_point(role: String, _fell_from: Vector3) -> Vector3:
	return spawn_point(role, "default")


func _on_state_changed(_key: String) -> void:
	var fallen: bool = GameState.get_flag("punt.wall_fell", false)
	_old_wall.visible = not fallen
	_old_wall.get_child(1).disabled = fallen
	_rubble.visible = fallen


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server() or GameState.get_flag("punt.wall_fell", false):
		return
	if not GameState.has_journal("mastaba"):
		return
	var players := Game.current.get_players()
	if players.size() == 2 and players.all(func(p: Node3D) -> bool:
			return Game.current.level_for(p.role) == self and to_local(p.global_position).z < -30.0):
		_collapse()


## Step 3 (canon, MEDIUM): the wall collapses and everyone runs for the Door.
func _collapse() -> void:
	GameState.set_flag("punt.wall_fell")
	Game.current.say("With a roar, the old wall collapses! Stones bounce down the street. Rick shouts: \"Back to the Door!\"")


func _home(_player: Node3D) -> void:
	for f in ["b2.split", "b2.away", "punt.disguised", "argo.night"]:
		GameState.set_flag(f, false)
	GameState.set_flag("b2.home")
	Game.current.say("The Door swings open, and Jason and Rick tumble through into Villa Argo, sunburnt and dusty. Outside, the storm is over.")
	GameState.add_journal("home_again", "Home again",
		"We're all back at Villa Argo. Julia held the house against Manfred in the storm and opened the Door from this side. Jason and Rick found the map of Kilmore Cove in the room that isn't there, and lost it straight away to Oblivia Newton.\nShe has the map now. Whatever it shows, she knows it too.")
	Game.current.say_later("End of book 2: The Long-Lost Map. (Book 3, The House of Mirrors, comes next.)", 4.0)


func _split(_player: Node3D) -> void:
	GameState.set_flag("b2.split")
	GameState.set_flag("argo_door.open", false)
	GameState.set_flag("argo.night")
	Game.current.say("Julia dives through the Door, and it slams shut behind her. Jason and Rick are on the wrong side.")
	Game.current.say("Villa Argo, at night. Rain hammers on the windows: a storm is breaking over the house. Nestor will be about somewhere.", "julia")


# --- Harbour (steps 1-2) ----------------------------------------------------------

func _build_harbour() -> void:
	add_box(Vector3(12, 0.5, 12), Vector3(0, -0.25, 4), STONE)
	add_box(Vector3(0.5, 6, 12), Vector3(-6, 3, 4), STONE)
	add_box(Vector3(0.5, 6, 12), Vector3(6, 3, 4), STONE)
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 20)
	sea.mesh = plane
	sea.material_override = Vis.material(Color(0.15, 0.45, 0.6))
	sea.position = Vector3(0, -0.6, 20)
	add_child(sea)
	add_box(Vector3(4, 2, 10), Vector3(0, 0, 18), Color(0.4, 0.28, 0.18))
	add_box(Vector3(0.3, 7, 0.3), Vector3(0, 4.5, 19), Color(0.35, 0.25, 0.15))
	add_label("METIS", Vector3(2.05, 0.3, 18), 90)

	var chest := JournalNote.new()
	chest.entry_id = "local_clothes"
	chest.title = "Dressed for Punt"
	chest.body = "In a chest unloaded from the Metis: linen tunics, sandals and headcloths in the local style. We change. Rick looks almost Egyptian. Nobody will stare at us now."
	chest.prompt = "Open the chest of clothes"
	chest.size = Vector3(1.2, 0.7, 0.7)
	chest.on_used = func(_p: Node3D) -> void: GameState.set_flag("punt.disguised")
	place(chest, "ClothesChest", Vector3(3.5, 0.35, 8))

	var sailor := Npc.new()
	sailor.npc_name = "Sailor"
	sailor.color = Color(0.35, 0.4, 0.6)
	sailor.present = "b2.split"
	sailor.lines = [
		["", "Fine ship, that. Never seen her come in."],
		["punt.delivered_sailor", "Tell the old man I'll pay him at the next full moon."],
	]
	sailor.on_used = func(_p: Node3D) -> void: _deliver("parcel", "punt.delivered_sailor", "The sailor takes the parcel. \"From the old map-seller? About time.\"")
	place(sailor, "Sailor", Vector3(-3.5, 1, 2))


# --- The Door hall ------------------------------------------------------------------

func _build_hall() -> void:
	add_box(Vector3(8, 0.5, 8), Vector3(0, -0.25, -6), STONE)
	add_box(Vector3(0.5, 5, 8), Vector3(-4, 2.5, -6), STONE)
	add_box(Vector3(0.5, 5, 8), Vector3(4, 2.5, -6), STONE)
	add_box(Vector3(2.5, 5, 0.5), Vector3(-2.75, 2.5, -10), STONE)
	add_box(Vector3(2.5, 5, 0.5), Vector3(2.75, 2.5, -10), STONE)
	# The Door to Time, Punt side.
	add_box(Vector3(0.2, 2.6, 1.6), Vector3(-3.7, 1.3, -6), Color(0.28, 0.18, 0.1))
	add_label("the Door", Vector3(-3.55, 2.9, -6), 90)

	var door := LevelExit.new()
	door.who = "julia"
	door.solo = true
	door.level = VILLA_ARGO
	door.entry = "door"
	door.requires = "punt.wall_fell & !b2.split & !b2.home"
	door.prompt = "Run through the Door!"
	door.on_used = _split
	place(door, "TheDoor", Vector3(-3, 1, -6))

	# Step 18 (canon ✅): the boys come home through the Argo Door, once Julia
	# has opened it from the house.
	var home := LevelExit.new()
	home.who = "jason"
	home.solo = true
	home.level = VILLA_ARGO
	home.entry = "door"
	home.requires = "b2.map_taken & argo_door.open & b2.split"
	home.prompt = "Go home through the Door"
	home.on_used = _home
	place(home, "DoorHome", Vector3(-2.9, 1, -6.4))

	# Guards turn away anyone not dressed like a local.
	var line := Door.new()
	line.size = Vector3(3, 3, 0.3)
	line.open_flag = "punt.disguised"
	line.color = Color(0.55, 0.45, 0.3)
	place(line, "GuardLine", Vector3(0, 0, -10))
	var guard := Npc.new()
	guard.npc_name = "Guard"
	guard.color = Color(0.6, 0.45, 0.25)
	guard.lines = [
		["", "Strangers, dressed like that? Go back where you came from."],
		["punt.disguised", "Move along, move along."],
	]
	place(guard, "Guard", Vector3(2.2, 1, -11.2))


# --- Town (steps 2-3) ---------------------------------------------------------------

func _build_town() -> void:
	add_box(Vector3(14, 0.5, 32), Vector3(0, -0.25, -26), SAND)
	add_box(Vector3(14, 4, 0.5), Vector3(0, 2, -42), STONE)
	var colors := [Color(0.85, 0.75, 0.55), Color(0.8, 0.65, 0.45), Color(0.9, 0.8, 0.6)]
	for i in 6:
		var z := -13.5 - i * 5.0
		if absf(z + 28.5) > 0.1:
			add_box(Vector3(3, 4, 5), Vector3(-6.5, 2, z), colors[i % 3])
		if z > -21.0 or z < -29.0:
			add_box(Vector3(3, 4, 5), Vector3(6.5, 2, z), colors[(i + 1) % 3])
	add_label("market", Vector3(-5.2, 3.2, -28.5), 90)

	_old_wall = add_box(Vector3(0.6, 3.5, 10), Vector3(5.2, 1.75, -26), Color(0.7, 0.6, 0.45))
	add_label("an old wall", Vector3(4.8, 3.8, -25), -90).font_size = 28
	_rubble = Node3D.new()
	add_child(_rubble)
	for i in 5:
		var rock := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.0 + i * 0.15, 0.6, 1.1)
		rock.mesh = b
		rock.material_override = Vis.material(Color(0.7, 0.6, 0.45))
		rock.position = Vector3(3.8 - i * 0.6, 0.3, -22.5 - i * 1.3)
		rock.rotation_degrees.y = i * 23.0
		_rubble.add_child(rock)

	add_box(Vector3(6, 2, 3.5), Vector3(0, 1, -38), Color(0.75, 0.68, 0.55))
	add_label("a low stone building", Vector3(0, 2.6, -36.2), 0).font_size = 28
	var mastaba := JournalNote.new()
	mastaba.entry_id = "mastaba"
	mastaba.title = "Mastaba"
	mastaba.body = "Rick looks it up in the Dictionary of Forgotten Languages: a mastaba is a low, flat-topped tomb of stone or mud brick, where important people were buried."
	mastaba.prompt = "Look it up in the Dictionary"
	mastaba.requires = "punt.disguised"
	mastaba.size = Vector3(0.01, 0.01, 0.01)
	place(mastaba, "Mastaba", Vector3(0, 1, -35.8))



# --- The lane and the House of Life (steps 4-6) -----------------------------------

func _build_house_of_life() -> void:
	add_box(Vector3(24, 0.5, 26), Vector3(19, -0.25, -25), SAND)
	add_box(Vector3(0.5, 4, 26), Vector3(31, 2, -25), STONE)
	add_box(Vector3(24, 4, 0.5), Vector3(19, 2, -12), STONE)
	add_box(Vector3(24, 4, 0.5), Vector3(19, 2, -38), STONE)

	# Step 4: Maruk, pinned under a beam from the collapse.
	var beam := Pushable.new()
	beam.size = Vector3(3.5, 0.35, 0.35)
	beam.offset = Vector3(0, 0, 2.4)
	beam.moved_flag = "punt.maruk_free"
	beam.requires = "b2.split"
	beam.prompt = "Heave the beam aside"
	beam.on_used = func(_p: Node3D) -> void:
		Game.current.say("Jason heaves the beam aside. A girl about his age scrambles free, coughing dust: \"Thank you! I am Maruk.\"")
		GameState.add_journal("maruk", "Maruk",
			"When the wall fell, a girl was pinned under a beam. Her name is Maruk. Her father is a scribe at the House of Life, where the old writings are kept, and she's offered to take us there.", "jason")
	place(beam, "Beam", Vector3(9.5, 0.35, -26))

	var maruk := Npc.new()
	maruk.npc_name = "Maruk"
	maruk.color = Color(0.9, 0.75, 0.45)
	maruk.present = "b2.split"
	maruk.walk_speed = 5.0
	maruk.stations = [
		["", Vector3(9.5, 1, -27.2)],
		["punt.maruk_free", Vector3(11.5, 1, -21.5)],
		["punt.guards_passed", Vector3(16.5, 1, -27.5)],
		["journal:door_backwards", Vector3(-11, 1, -24.5)],
		["b2.map_taken", Vector3(1.5, 1, -4)],
	]
	maruk.lines = [
		["", "Help! My leg... the beam!"],
		["punt.maruk_free", "The House of Life is just there. The guards are grumpy, but they know me. Let me talk to them."],
		["punt.guards_passed", "My father copies the old papyri here. If your friend left something, it will be in the niches."],
		["journal:door_backwards", "A room that isn't there? The old map-seller in the market knows every strange story in Punt. Come, I'll show you."],
		["punt.errands_given", "Poor old man, his feet are so swollen he can barely walk. Errands are how he gets by."],
		["punt.legend", "That ballad... my mother used to sing it. Nobody knows what it means."],
		["b2.map_taken", "You're going home? Then go well, Jason, and you too, Rick. Punt will remember you."],
	]
	place(maruk, "Maruk", Vector3(9.5, 1, -27.2))

	# Step 5: the House of Life (x 14..30, z -36..-14), door on the west side.
	var hall := Color(0.82, 0.74, 0.58)
	add_box(Vector3(0.5, 6, 10), Vector3(14, 3, -19), hall)
	add_box(Vector3(0.5, 6, 10), Vector3(14, 3, -31), hall)
	add_box(Vector3(16, 6, 0.5), Vector3(22, 3, -14), hall)
	add_box(Vector3(16, 6, 0.5), Vector3(22, 3, -36), hall)
	add_box(Vector3(0.5, 6, 22), Vector3(30, 3, -25), hall)
	add_label("HOUSE OF LIFE", Vector3(13.7, 5, -25), -90)
	var doorway := Door.new()
	doorway.size = Vector3(2, 3, 0.3)
	doorway.open_flag = "punt.guards_passed"
	doorway.color = Color(0.55, 0.45, 0.3)
	place(doorway, "HouseOfLifeDoor", Vector3(14, 0, -25)).rotation_degrees.y = 90

	var micerinus := Npc.new()
	micerinus.npc_name = "Micerinus"
	micerinus.color = Color(0.6, 0.45, 0.25)
	micerinus.present = "b2.split"
	micerinus.lines = [
		["", "Nobody enters the House of Life without business here. Off with you."],
		["punt.guards_passed", "Don't touch anything."],
	]
	micerinus.on_used = func(_p: Node3D) -> void:
		if GameState.get_flag("punt.maruk_free", false) and not GameState.get_flag("punt.guards_passed", false):
			GameState.set_flag("punt.guards_passed")
			Game.current.say("Maruk talks quickly with the guards. \"The scribe's daughter and her cousins from the coast,\" grumbles Pipi. They step aside.")
	place(micerinus, "Micerinus", Vector3(12.5, 1, -23))
	var pipi := Npc.new()
	pipi.npc_name = "Pipi"
	pipi.color = Color(0.6, 0.45, 0.25)
	pipi.present = "b2.split"
	pipi.lines = [["", "Ask Micerinus. He's in charge. Supposedly."]]
	place(pipi, "Pipi", Vector3(12.5, 1, -27))

	# Step 6: the archive. Papyri, statues, niches; Ulysses's note up high.
	for z in [-16.0, -21.0, -29.0, -34.0]:
		add_box(Vector3(1.2, 2.5, 3), Vector3(16, 1.25, z), Color(0.6, 0.48, 0.3))
	add_label("papyri", Vector3(16.7, 2.8, -16), -90).font_size = 28
	for z in [-18.0, -32.0]:
		add_box(Vector3(1, 3, 1), Vector3(23, 1.5, z), Color(0.8, 0.78, 0.72))
	add_label("statues of scribes", Vector3(23, 3.4, -25), 0).font_size = 28

	var scribe := Npc.new()
	scribe.npc_name = "Scribe (Maruk's father)"
	scribe.color = Color(0.85, 0.85, 0.8)
	scribe.present = "punt.guards_passed"
	scribe.lines = [
		["", "My daughter says you saved her. Look wherever you like, but carefully: some of these papyri are older than the city."],
		["journal:door_backwards", "A foreigner, many years ago, did ask about the map-seller in the market. That's all I remember."],
	]
	place(scribe, "Scribe", Vector3(20, 1, -17))

	var drawing := JournalNote.new()
	drawing.who = "jason"
	drawing.entry_who = "jason"
	drawing.requires = "punt.guards_passed"
	drawing.entry_id = "metis_drawing"
	drawing.title = "A drawing of the Metis"
	drawing.body = "Among the papyri, a drawing of a ship with a curved prow and a single sail: the Metis, unmistakably. Ulysses Moore was here."
	drawing.prompt = "Look through the papyri"
	drawing.size = Vector3(0.6, 0.05, 0.4)
	place(drawing, "MetisDrawing", Vector3(17, 1.2, -29))

	add_climb_wall(Vector3(2, 5, 2.5), Vector3(28.9, 2.5, -20))
	add_label("a high niche", Vector3(28.9, 5.8, -18.6), 0).font_size = 28
	var note := JournalNote.new()
	note.who = "jason"
	note.entry_who = "jason"
	note.requires = "punt.guards_passed"
	note.entry_id = "door_backwards"
	note.title = "Ulysses's note in the archive"
	note.body = "Rolled up in a high niche, a note in Ulysses Moore's handwriting:\n\"The map is no longer here. I have moved it to the room that isn't there.\"\nAnd underneath: \"If ever the Door shuts with friends still on the far side, it can be opened from the house: ask it backwards.\"\n\nJulia needs to know the second part."
	note.prompt = "Unroll the note"
	note.size = Vector3(0.3, 0.1, 0.3)
	place(note, "ArchiveNote", Vector3(28.9, 5.6, -20))


# --- The market and the map shop (steps 7-9) ---------------------------------------

func _build_market() -> void:
	add_box(Vector3(17, 0.5, 18), Vector3(-15.5, -0.25, -29), SAND)
	add_box(Vector3(0.5, 4, 18), Vector3(-24, 2, -29), STONE)
	add_box(Vector3(17, 4, 0.5), Vector3(-15.5, 2, -20), STONE)
	add_box(Vector3(17, 4, 0.5), Vector3(-15.5, 2, -38), STONE)
	for x in [-11.0, -15.0]:
		add_box(Vector3(2.5, 1, 1.5), Vector3(x, 0.5, -33), Color(0.7, 0.5, 0.3))
	add_label("market stalls", Vector3(-13, 1.6, -33), 0).font_size = 28

	# Step 7: Oblivia trading lighters for gold (canon, MEDIUM).
	var oblivia := Npc.new()
	oblivia.npc_name = "A foreign woman"
	oblivia.color = Color(0.6, 0.15, 0.3)
	oblivia.present = "b2.split & !punt.map_shop"
	oblivia.walk_speed = 3.0
	oblivia.stations = [["", Vector3(-13, 1, -31)], ["journal:oblivia_market", Vector3(-19, 1, -26.5)]]
	oblivia.lines = [
		["", "Gold for a little flame, look: click, and fire! A bargain. Now, little man, where is this famous shop of forgotten maps?"],
		["journal:oblivia_market", "Run along, boy. Grown-ups are talking."],
	]
	oblivia.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("oblivia_market", "A woman in the market",
			"A tall foreign woman in sunglasses is trading cheap plastic lighters for the merchants' gold. She keeps asking the way to the shop of forgotten maps. She doesn't belong here any more than we do.", "jason")
	place(oblivia, "Oblivia", Vector3(-13, 1, -31))

	var doctor := Npc.new()
	doctor.npc_name = "Doctor"
	doctor.color = Color(0.4, 0.55, 0.5)
	doctor.present = "b2.split"
	doctor.lines = [
		["", "Sore feet? Sore head? Come back when you're ill."],
		["punt.delivered_doctor", "Tell the old man to keep his feet up!"],
	]
	doctor.on_used = func(_p: Node3D) -> void: _deliver("ointment", "punt.delivered_doctor", "The doctor takes the jar of ointment and sniffs it. \"Finally.\"")
	place(doctor, "Doctor", Vector3(-9, 1, -36))

	# The shop of forgotten maps (x -23..-15, z -20.5..-26), open to the south.
	var shop := Color(0.7, 0.6, 0.45)
	add_box(Vector3(0.5, 4, 5.5), Vector3(-15, 2, -23.25), shop)
	add_box(Vector3(3, 4, 0.5), Vector3(-21.5, 2, -26), shop)
	add_box(Vector3(3, 4, 0.5), Vector3(-16.5, 2, -26), shop)
	add_label("SHOP OF FORGOTTEN MAPS", Vector3(-19, 4.4, -26.3), 180)
	add_box(Vector3(3, 1, 0.8), Vector3(-17.5, 0.5, -22.5), Color(0.45, 0.32, 0.2))
	add_box(Vector3(1.2, 2, 0.1), Vector3(-21, 1, -20.6), Color(0.15, 0.12, 0.1))
	add_label("steps down into the dark", Vector3(-21, 2.3, -20.8), 0).font_size = 24
	var steps := LevelExit.new()
	steps.who = "jason"
	steps.solo = true
	steps.level = CORRIDORS
	steps.requires = "punt.legend"
	steps.prompt = "Go down the steps"
	place(steps, "StepsDown", Vector3(-21, 1, -21.3))

	var seller := Npc.new()
	seller.npc_name = "The map-seller"
	seller.color = Color(0.55, 0.5, 0.45)
	seller.present = "b2.split"
	seller.lines = [
		["", "Maps, maps, forgotten maps... You're the second foreigners today. The first was a lady who paid in little fires. Information costs, young man. My feet are too swollen to walk: run my errands, and then we'll talk."],
		["punt.errands_given", "The parcel goes to the sailor on the quay, the ointment to the doctor in the square. Off you go."],
		["punt.delivered_sailor & punt.delivered_doctor", "Good boy. Now listen, and I'll tell you what I told your friend with the ship, years ago."],
		["punt.legend", "Talos will let you by now. The old corridors are under the market. Mind the dark, and mind the snakes."],
	]
	seller.on_used = _talk_seller
	place(seller, "MapSeller", Vector3(-17.5, 1, -21.6))

	var talos := Npc.new()
	talos.npc_name = "Talos (a crocodile)"
	talos.color = Color(0.3, 0.45, 0.25)
	talos.present = "b2.split"
	talos.walk_speed = 1.5
	talos.stations = [["", Vector3(-21, 0.4, -21.8)], ["punt.legend", Vector3(-22.8, 0.4, -24)]]
	talos.lines = [
		["", "Talos opens one yellow eye. He's lying right across the back-room door."],
		["punt.legend", "Talos has shuffled aside. The steps behind him lead down into the dark."],
	]
	place(talos, "Talos", Vector3(-21, 0.4, -21.8))


## Steps 8-9 (canon: errands for information, MEDIUM/LOW; the three turtles and
## the Ballad, LOW; the Ballad's text is adaptation).
func _talk_seller(_player: Node3D) -> void:
	if not GameState.get_flag("punt.map_shop", false):
		GameState.set_flag("punt.map_shop")
	if not GameState.get_flag("punt.errands_given", false):
		GameState.set_flag("punt.errands_given")
		GameState.give_item("parcel", "parcel for the sailor")
		GameState.give_item("ointment", "jar of ointment for the doctor")
		return
	if GameState.get_flag("punt.delivered_sailor", false) and GameState.get_flag("punt.delivered_doctor", false) \
			and not GameState.get_flag("punt.legend", false):
		GameState.set_flag("punt.legend")
		GameState.add_journal("ballad", "The map-seller's legend",
			"Long ago, the map-seller says, a foreigner with a ship came asking about a hidden room. The old man remembers a sign of three turtles, and a riddle: \"near the mouth, under the nose\". Then he sang us a song, the Ballad of Two Lovers:\n\"She looks to the morning, he looks to the night;\nbetween them the shadows, between them the light.\nTurn the bright waters three times on the way,\nand their eyes will meet at the close of the day.\"\nWhat does it mean? Ulysses must have known. Julia has his books at home.", "jason")


func _deliver(item: String, flag: String, text: String) -> void:
	if GameState.has_item(item):
		GameState.take_item(item)
		GameState.set_flag(flag)
		Game.current.say(text, "jason")


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.walk_speed = 5.0
	rick.stations = [
		["", Vector3(2, 1, 6.5)],
		["punt.disguised", Vector3(-2.5, 1, -14)],
		["punt.wall_fell", Vector3(-2.5, 1, -27)],
		["b2.split", Vector3(4, 1, -21)],
		["punt.guards_passed", Vector3(17.5, 1, -23.5)],
		["journal:door_backwards", Vector3(-11, 1, -26.5)],
		["punt.legend", Vector3(-19.5, 1, -24.5)],
		["b2.map_taken", Vector3(-1.5, 1, -4)],
	]
	rick.lines = [
		["", "The Metis brought us to Egypt. Real Egypt! We can't walk about dressed like this, though. There's a chest of clothes on the quay."],
		["punt.disguised", "Look at that low stone building at the end of the street. I'll check the Dictionary."],
		["journal:mastaba", "A tomb! This whole place is ancient. Let's keep going."],
		["punt.wall_fell", "The wall! Back to the Door, quick!"],
		["b2.split", "Julia made it through, but the Door won't budge for us. Listen... someone's calling for help, behind where the wall was!"],
		["punt.maruk_free", "Maruk says her father works at the House of Life. If Ulysses left anything in Punt, it'll be somewhere like that."],
		["punt.guards_passed", "Look at all these papyri! Some of those niches are high up. You're the climber, Jason."],
		["journal:door_backwards", "The room that isn't there... Maruk says the map-seller in the market might know. And tell Julia about the Door: ask it backwards!"],
		["punt.errands_given", "Errands! Fine: the sailor's down on the quay, and the doctor's in the market square."],
		["punt.legend", "The Ballad of Two Lovers... Julia's got all Ulysses's books at home. Ask her if he wrote anything about it!"],
		["b2.map_taken", "She just took it! Well... we know where it is, at least. Let's go home, back to the Door."],
		["b2.map_taken & !argo_door.open", "The Door's still shut. Julia has to open it from her side. Did you tell her: ask it backwards?"],
	]
	place(rick, "Rick", Vector3(2, 1, 6.5))
