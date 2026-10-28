extends Level
## Kilmore Cove. Book 1 step 7: the post office, where the receipt from the
## tower diary gets the twins the parcel with the four animal keys and a second
## coded message (canon, ref B1 scene 8). Book 3 (docs/book3-design.md, steps
## 3-6): the impossible village (no maps, no signal, tracks to nowhere, the
## statue of a king who never reigned), Calypso's old tourist guide, the marks
## Jason remembers from the map, and the old residents who knew Ulysses and
## Dedalus, then the way into the House of Mirrors (the mirror_house level).
## Layout is adaptation.
##
## Map (north = -z): the main street (x -6..6) from the gate road (z 12) to the
## post office (z -8..-14). West: the square with the statue, phone box,
## Calypso's bookshop and Miss Biggles's house; north of it, the lighthouse.
## East: the railway to a sealed tunnel, and the House of Mirrors.

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"
const MIRROR_HOUSE := "res://scenes/levels/mirror_house.tscn"
const SCHOOL := "res://scenes/levels/school.tscn"
const STATION := "res://scenes/levels/station.tscn"
## Book 5 step 4: Dad's walk across the square, one stop every DAD_SECONDS.
const DAD_ROUTE := [Vector3(-12, 1, 3), Vector3(-22, 1, 3), Vector3(-32, 1, 0), Vector3(-32, 1, -14), Vector3(-22, 1, -15)]
const DAD_SECONDS := 4.0
const WALL := Color(0.75, 0.68, 0.6)
const ROAD := Color(0.5, 0.5, 0.5)

## Book 3 step 3: [flag, what's wrong]. Ticked off in the "kilmore_wrong" entry.
const IMPOSSIBLE := [
	["b3.no_maps", "It isn't in any atlas or on any map."],
	["b3.no_signal", "The telephone gets nothing but a hum."],
	["b3.tracks", "The railway runs straight into a sealed tunnel."],
	["b3.king", "Its statue is of King William V, who never existed."],
]
## Book 3 steps 4-5: the guide's landmarks; the map marked 3, 6 and 8.
const GUIDE := "AN ILLUSTRATED GUIDE TO KILMORE COVE (price sixpence)\n\n1. The statue of His Majesty King William V, in the square.\n2. The harbour and the fish market.\n3. The lighthouse on the northern headland, kept by Mr Leonard Minaxo.\n4. The post office.\n5. The church.\n6. Miss Biggles's house, famous for its cats.\n7. Calypso's bookshop.\n8. The House of Mirrors, home of Mr Peter Dedalus, inventor and watchmaker. Open to visitors daily at a quarter past four.\n9. The old mill.\n\nUseful numbers: the House of Mirrors, Kilmore Cove 77."
const MARKS := "368"

var _ruins: Node3D
var _dad_t := 0.0
var _hid_t := 0.0
var _turtle_key: Label3D


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.2, 1, 8), "julia": Vector3(1.2, 1, 8), "yaw": 0.0},
		"mirror_house": {"jason": Vector3(32, 1, -13.5), "julia": Vector3(34, 1, -13.5), "yaw": PI},
		"school": {"jason": Vector3(-24, 1, 11.5), "julia": Vector3(-22, 1, 11.5), "yaw": PI},
		"station": {"jason": Vector3(21, 1, 3), "julia": Vector3(23, 1, 3), "yaw": 0.0},
	}
	add_environment(Color(0.6, 0.72, 0.85))

	add_box(Vector3(100, 0.5, 60), Vector3(7, -0.25, -13), ROAD)
	add_box(Vector3(100, 2, 0.4), Vector3(7, 1, 17), WALL)
	add_box(Vector3(100, 2, 0.4), Vector3(7, 1, -43), WALL)
	add_box(Vector3(0.4, 2, 60), Vector3(-43, 1, -13), WALL)
	add_box(Vector3(0.4, 2, 60), Vector3(57, 1, -13), WALL)

	_build_street()
	_build_square()
	_build_lighthouse()
	_build_railway()
	_build_mirror_house()
	_build_school_town()
	_build_rick()
	_build_epilogue()


# --- Main street and post office (book 1) ----------------------------------------

func _build_street() -> void:
	# Painted houses, with gaps west (to the square) and east (to the railway).
	var colors := [Color(0.85, 0.55, 0.5), Color(0.55, 0.7, 0.85), Color(0.9, 0.85, 0.55), Color(0.6, 0.8, 0.6)]
	for i in 2:
		var z := 9.0 - i * 15.0
		add_box(Vector3(4, 5, 4), Vector3(-9, 2.5, z), colors[i])
		add_box(Vector3(4, 5, 4), Vector3(9, 2.5, z), colors[3 - i])

	add_box(Vector3(10, 4, 0.5), Vector3(0, 2, -14), WALL)
	add_box(Vector3(0.5, 4, 6), Vector3(-5, 2, -11), WALL)
	add_box(Vector3(0.5, 4, 6), Vector3(5, 2, -11), WALL)
	add_box(Vector3(3.5, 4, 0.5), Vector3(-3.25, 2, -8), WALL)
	add_box(Vector3(3.5, 4, 0.5), Vector3(3.25, 2, -8), WALL)
	add_label("POST OFFICE", Vector3(0, 4.4, -7.7), 0)
	add_box(Vector3(6, 1.1, 0.8), Vector3(0, 0.55, -12), Color(0.45, 0.32, 0.2))

	var clerk := Npc.new()
	clerk.npc_name = "Post office clerk"
	clerk.color = Color(0.4, 0.45, 0.6)
	clerk.lines = [
		["", "Afternoon! Something to post?"],
		["item:receipt", "A receipt for... my word, this parcel has been waiting here for years. It's for whoever brought this receipt. Here you are."],
		["item:owl_key", "Mind how you go up that hill."],
		["b3.started", "Maps? Of Kilmore Cove? Funny, nobody's ever asked."],
	]
	clerk.on_used = _hand_over_parcel
	place(clerk, "Clerk", Vector3(0, 1, -13))

	var exit := LevelExit.new()
	exit.level = VILLA_ARGO
	exit.entry = "gate"
	exit.prompt = "Cycle back up to Villa Argo"
	exit.solo_when = "b6.playing_rick"
	place(exit, "ExitToVilla", Vector3(0, 1, 12))


## Canon: four animal keys and a second coded message (ref §6, B1 scene 8).
## English edition animals (MEDIUM). Message wording is adaptation; it carries
## the OPEN hint and the "four, three, two, one" order for the floor stones.
func _hand_over_parcel(_player: Node3D) -> void:
	if not GameState.has_item("receipt") or GameState.has_item("owl_key"):
		return
	GameState.give_item("owl_key", "Owl key")
	GameState.give_item("porcupine_key", "Porcupine key")
	GameState.give_item("elephant_key", "Elephant key")
	GameState.give_item("newt_key", "Newt key")
	GameState.add_journal("parcel", "The parcel",
		"Inside the parcel: four old keys, each with an animal's head (an owl, a porcupine, an elephant and a newt), and a folded note in the same strange symbols as the parchment.")
	GameState.add_journal("second_message", "The second message",
		"With the Dictionary's signs I can read the note:\n\"Four locks and four keys. Ask the door, with the first letter of each, what it must do.\nThen four, three, two, one: and every path beyond must be chosen.\"", "julia")


# --- Book 3: the impossible village -----------------------------------------------

## Host: tick one impossibility off the checklist entry.
func _found(flag: String) -> void:
	if GameState.get_flag(flag, false):
		return
	GameState.set_flag(flag)
	var body := "Things that are wrong with Kilmore Cove:\n"
	var all := true
	for item in IMPOSSIBLE:
		var done := bool(GameState.get_flag(item[0], false))
		all = all and done
		body += "\n[%s] %s" % ["x" if done else "  ", item[1] if done else "?"]
	if all:
		body += "\n\nA whole village that nobody knows is here. Calypso at the bookshop might know why."
	GameState.update_journal("kilmore_wrong", "Things that are wrong with Kilmore Cove", body)


func _build_square() -> void:
	# The statue of the king who never reigned (canon, HIGH): Jason climbs the
	# plinth to read the worn inscription; Julia checks the history of kings.
	add_climb_wall(Vector3(3, 3, 3), Vector3(-26, 1.5, 0))
	add_box(Vector3(0.9, 2.4, 0.9), Vector3(-26, 4.2, 0.6), Color(0.6, 0.62, 0.6))
	add_label("statue of a king", Vector3(-26, 6, 0.6)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var inscription := JournalNote.new()
	inscription.who = "jason"
	inscription.requires = "b3.started"
	inscription.entry_id = "king_inscription"
	inscription.title = "The statue in the square"
	inscription.body = "From the top of the plinth I can just read the worn letters: \"HIS MAJESTY KING WILLIAM V, WHO REIGNED OVER KILMORE COVE\"."
	inscription.prompt = "Read the worn inscription"
	inscription.size = Vector3(0.6, 0.05, 0.3)
	place(inscription, "Inscription", Vector3(-26, 3.3, -0.6))

	add_box(Vector3(1.2, 2.6, 1.2), Vector3(-15, 1.3, 7), Color(0.75, 0.15, 0.12))
	add_label("telephone box", Vector3(-15, 3, 7)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var phone := JournalNote.new()
	phone.requires = "b3.started"
	phone.entry_id = "phone_box"
	phone.title = "The telephone box"
	phone.body = "The telephone in the square gets nothing but a low hum. No dialling tone, no operator. Rick says it's always like that. So is everyone's mobile."
	phone.prompt = "Try the telephone"
	phone.size = Vector3(0.01, 0.01, 0.01)
	phone.on_used = func(_p: Node3D) -> void: _found("b3.no_signal")
	place(phone, "Phone", Vector3(-15, 1, 5.9))

	# Calypso's bookshop (x -24..-16, z -10..-4), door on the south side.
	var shop := Color(0.55, 0.45, 0.6)
	add_box(Vector3(8, 4, 0.5), Vector3(-20, 2, -10), shop)
	add_box(Vector3(0.5, 4, 6), Vector3(-24, 2, -7), shop)
	add_box(Vector3(0.5, 4, 6), Vector3(-16, 2, -7), shop)
	add_box(Vector3(3, 4, 0.5), Vector3(-22.5, 2, -4), shop)
	add_box(Vector3(3, 4, 0.5), Vector3(-17.5, 2, -4), shop)
	add_label("CALYPSO'S BOOKSHOP", Vector3(-20, 4.4, -3.7), 0)
	add_box(Vector3(6, 2.5, 0.6), Vector3(-20, 1.25, -9.4), Color(0.4, 0.28, 0.18))

	var atlases := JournalNote.new()
	atlases.who = "julia"
	atlases.requires = "b3.started"
	atlases.entry_id = "atlases"
	atlases.title = "The atlases"
	atlases.body = "I went through every atlas and road map in the bookshop. Cornwall is there, every bay and village... except Kilmore Cove. It isn't in a single one."
	atlases.prompt = "Look through the atlases"
	atlases.size = Vector3(0.6, 0.15, 0.4)
	atlases.on_used = func(_p: Node3D) -> void: _found("b3.no_maps")
	place(atlases, "Atlases", Vector3(-22, 1.0, -8.6))

	var kings := JournalNote.new()
	kings.who = "julia"
	kings.requires = "journal:king_inscription"
	kings.entry_id = "history_of_kings"
	kings.title = "A History of the Kings of England"
	kings.body = "William I, William II, William III, William IV... and that's the last William. There has never been a King William V. Not of England, and certainly not of Kilmore Cove."
	kings.prompt = "Look up King William V"
	kings.size = Vector3(0.5, 0.15, 0.35)
	kings.on_used = func(_p: Node3D) -> void: _found("b3.king")
	place(kings, "HistoryOfKings", Vector3(-18, 1.0, -8.6))

	var calypso := Npc.new()
	calypso.npc_name = "Calypso"
	calypso.color = Color(0.7, 0.45, 0.6)
	calypso.lines = [
		["", "Welcome to the bookshop, dears. Browse all you like."],
		["b3.started", "Kilmore Cove in an atlas? Ha. Look for yourselves, dears."],
		["b3.no_maps & b3.no_signal & b3.tracks & b3.king", "So you've noticed. Most people never do. Here: this was printed long before you were born. Ulysses Moore used to come in for these."],
		["journal:three_marks", "The House of Mirrors... Peter Dedalus. Clever, kind, impossible man. He built that house and then, one day, he simply wasn't there any more. Ulysses was his friend."],
		["b3.dedalus", "If anyone could find out where Peter went, it's you three."],
		["b3.escaped", "Thank goodness you're safe. Peter's house... Well, houses can be mended. People are harder."],
	]
	calypso.lines.append(["b6.home", "Oh! You're back! Leonard said... Leonard and I were just talking. About nothing. Nothing at all."])
	calypso.stations = [["", Vector3(-20, 1, -7)], ["b3.escaped", Vector3(34, 1, -11)], ["b5.started", Vector3(-20, 1, -7)], ["b6.home", Vector3(-28.4, 1, -30.2)]]
	calypso.on_used = _talk_calypso
	place(calypso, "Calypso", Vector3(-20, 1, -7))

	var guide_page := CodeEntry.new()
	guide_page.who = "julia"
	guide_page.requires = "item:tourist_guide"
	guide_page.answer = MARKS
	guide_page.any_order = true
	guide_page.solved_flag = "b3.marks"
	guide_page.prompt = "Mark the guide"
	guide_page.question = "Which three landmarks were marked on the map? (their numbers in the guide)"
	guide_page.wrong_text = "Jason shakes his head. \"No... that's not how the marks looked.\""
	guide_page.size = Vector3(1.2, 0.8, 0.8)
	guide_page.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("three_marks", "Three marks",
			"Jason's memory and the guide agree: the map in Punt had marks at the lighthouse, at Miss Biggles's house with all the cats, and at the House of Mirrors, home of Peter Dedalus.\nWhat do they have in common? Someone should ask the people who live there.")
	place(guide_page, "GuideTable", Vector3(-19, 0.4, -6.2))

	# Miss Biggles's house, famous for its cats (canon, MEDIUM).
	add_box(Vector3(8, 4, 7), Vector3(-36, 2, 9), Color(0.85, 0.75, 0.7))
	add_label("Miss Biggles", Vector3(-31.8, 3.6, 9), 90)
	for i in 5:
		var cat := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.4, 0.35, 0.7)
		cat.mesh = b
		cat.material_override = Vis.material([Color(0.2, 0.2, 0.2), Color(0.9, 0.6, 0.3), Color(0.95, 0.95, 0.95)][i % 3])
		cat.position = Vector3(-31 + (i % 2) * 0.8, 0.18, 6 + i * 1.3)
		cat.rotation_degrees.y = i * 37.0
		add_child(cat)
	add_label("cats", Vector3(-30.6, 1.0, 8.5)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var biggles := Npc.new()
	biggles.npc_name = "Miss Biggles"
	biggles.color = Color(0.75, 0.7, 0.8)
	biggles.lines = [
		["", "Mind the cats, dears. Mind the cats."],
		["journal:three_marks", "Ulysses Moore? Of course I knew him. My sister knew him better. Clio, that is; she doesn't come to the village any more. And Peter Dedalus... that house of his! Mirrors everywhere. He used to bring the cats fish."],
	]
	biggles.on_used = func(_p: Node3D) -> void: _met("b3.met_biggles")
	place(biggles, "MissBiggles", Vector3(-30, 1, 11.5))


func _build_lighthouse() -> void:
	add_box(Vector3(4, 14, 4), Vector3(-30, 7, -34), Color(0.92, 0.92, 0.9))
	add_box(Vector3(4.4, 1.5, 4.4), Vector3(-30, 14.75, -34), Color(0.75, 0.15, 0.12))
	add_label("LIGHTHOUSE", Vector3(-30, 3, -31.8), 0)
	var minaxo := Npc.new()
	minaxo.npc_name = "Leonard Minaxo"
	minaxo.color = Color(0.3, 0.35, 0.45)
	minaxo.lines = [
		["", "This is a lighthouse, not a playground. Off you go."],
		["journal:three_marks", "Ulysses sent you, did he? No... he couldn't have. Hmph. Yes, I knew him. And Peter Dedalus: the best watchmaker this coast ever had. His house is full of tricks. Mind you don't believe everything you see in there."],
		["b3.escaped", "Bulldozers, on Peter's house! That woman will answer for it. Venice, you say? Then she's gone after him."],
	]
	minaxo.stations = [["", Vector3(-30, 1, -30.8)], ["b3.escaped", Vector3(36, 1, -12)], ["b5.started", Vector3(-30, 1, -30.8)]]
	minaxo.lines.append(["b5.jason_out", "You should be at school, boy. ...Black Vulcano. Hmph. Sit down, then. I'll tell you once."])
	minaxo.lines.append(["b5.met_minaxo", "Clark Beamish Station. Fred has the keys. Now get back to school before somebody sees you."])
	minaxo.lines.append(["b6.met_ulysses", "He told you, did he? Then I'll tell you the rest. Sit down, lad."])
	minaxo.lines.append(["b6.father", "Go on. Ulysses is waiting at the station. Bring those twins home."])
	minaxo.on_used = func(_p: Node3D) -> void:
		if GameState.get_flag("b6.met_ulysses", false) and not GameState.get_flag("b6.father", false):
			_rick_father()
			return
		_met("b3.met_minaxo")
		if GameState.get_flag("b5.jason_out", false) and not GameState.get_flag("b5.met_minaxo", false):
			_great_summer()
	place(minaxo, "Minaxo", Vector3(-30, 1, -30.8))


# --- Book 5: school trouble (steps 2-4) -------------------------------------------

## Step 3 (canon: Jason sneaks to the lighthouse; the 1958 group, MEDIUM; exact
## members LOW, so only ones the twins know of are named).
func _great_summer() -> void:
	GameState.set_flag("b5.met_minaxo")
	GameState.add_journal("great_summer", "The Great Summer of 1958",
		"Minaxo told me, grudgingly. In the summer of 1958 a group of friends from Kilmore Cove found the Doors: Ulysses Moore, Peter Dedalus, Black Vulcano, Clio Biggles, Leonard Minaxo himself, and others he wouldn't name. They swore to keep the Doors secret and safe. They called themselves the Imaginary Travellers.\nBlack Vulcano ran the trains at Clark Beamish Station, before it was shut. Only Fred at the town hall has the keys to it now.")
	await get_tree().create_timer(2.0).timeout
	GameState.set_flag("b5.dad", 0)
	GameState.set_flag("b5.dad_walk")
	Game.current.say("Walking back past the square... that's Dad! What's he doing in Kilmore Cove? If he sees you, you're done for. Chubber's pastry shop, quick!", "jason")


# --- Book 6 step 16: the epilogue ------------------------------------------------

func _build_epilogue() -> void:
	# Manfred and Gwendaline, off to Punt through Miss Biggles's Cat Door
	# (canon ✅, two wikis).
	for who in [["Manfred", Color(0.2, 0.2, 0.2), Vector3(-26.5, 1, 8.6)], ["Gwendaline Mainoff", Color(0.9, 0.5, 0.7), Vector3(-25.3, 1, 9.4)]]:
		var npc := Npc.new()
		npc.npc_name = who[0]
		npc.color = who[1]
		npc.who = "nobody"
		npc.present = "b6.home & !b6.manfred_gone"
		place(npc, "Epilogue" + who[0].split(" ")[0], who[2])

	# Fred asleep on a bench, with the First Key on his ring and nobody the
	# wiser (canon: Fred has the First Key at the end of book 6, MEDIUM ✅; how
	# he got it, LOW, isn't told).
	add_box(Vector3(2, 0.5, 0.7), Vector3(-17, 0.25, -2), Color(0.4, 0.3, 0.2))
	_turtle_key = Label3D.new()
	_turtle_key.text = "on Fred's key ring, among a hundred others:\na small key with three turtles"
	_turtle_key.position = Vector3(-17, 2.5, -1.2)
	_turtle_key.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_turtle_key.font_size = 22
	add_child(_turtle_key)
	GameState.changed.connect(_show_turtle_key)
	_show_turtle_key("")

	# Minaxo and Calypso (decision 4: a full scene; LOW–MEDIUM, adaptation).
	var nudge := ChoicePoint.new()
	nudge.requires = "b6.home & !b6.minaxo_calypso"
	nudge.prompt = "Give Mr Minaxo a push"
	nudge.reach = 2.4
	nudge.question = "Mr Minaxo is turning his cap round and round in his hands. Calypso is pretending to look at the sea. What do you do?"
	nudge.options_for = func() -> Array:
		return [["Tell him to just say it", true], ["Tell Calypso he's been practising for forty years", true], ["Tactfully leave them to it", true]]
	nudge.on_choice = func(_p: Node3D, choice: String) -> void: _minaxo_calypso(choice)
	place(nudge, "NudgeMinaxo", Vector3(-29.4, 1, -29.4))


func _show_turtle_key(_key: String) -> void:
	_turtle_key.visible = GameState.get_flag("b6.home", false)


## Host: the lighthouse scene (LOW–MEDIUM: they're together by the end of
## book 6; the scene is adaptation).
func _minaxo_calypso(choice: String) -> void:
	GameState.set_flag("b6.minaxo_calypso")
	var opening := {
		"Tell him to just say it": "\"Just say it, Mr Minaxo!\" He glares at you. Then he takes a deep breath.",
		"Tell Calypso he's been practising for forty years": "\"He's been practising for forty years, Calypso.\" Minaxo goes purple. Calypso laughs, then stops laughing, and looks at him.",
		"Tactfully leave them to it": "You start to tiptoe away, very tactfully, and fall over a lobster pot. In the silence after the crash, Minaxo clears his throat.",
	}
	Game.current.say(opening.get(choice, opening["Tell him to just say it"]))
	Game.current.say_later("Minaxo: \"Calypso. I'm an old fool with one lighthouse and a bad temper. I should have asked you this in 1958. Will you... would you... have dinner with me?\"", 3.0)
	Game.current.say_later("Calypso: \"Leonard Minaxo. I have been waiting for you to ask me that since I was seventeen.\" She takes his arm.", 6.5)
	GameState.add_journal("minaxo_calypso", "The lighthouse",
		"Mr Minaxo, who once told us a lighthouse is not a playground, stood at the bottom of his lighthouse turning his cap round and round, and finally asked Calypso to dinner. She said she'd been waiting since she was seventeen.\nThey walked off along the headland arm in arm, and he didn't even tell us to clear off.")


func _run_epilogue() -> void:
	if not GameState.get_flag("b6.home", false) or GameState.get_flag("b6.end", false):
		return
	if not GameState.get_flag("b6.manfred_gone", false):
		for p in Game.current.get_players():
			var at := to_local(p.global_position)
			if Game.current.level_for(p.role) == self and absf(at.y - 1.0) < 3.0 and at.distance_to(Vector3(-26, 1, 9)) < 7.0:
				_manfred_goes()
				break
	if ["b6.manfred_gone", "b6.julia_rick", "b6.minaxo_calypso"].all(func(f: String) -> bool: return GameState.get_flag(f, false)):
		GameState.set_flag("b6.end")
		GameState.add_journal("the_end", "The First Key",
			"Kilmore Cove, the morning after. Ulysses Moore is back in his gardener's hat, grumbling at the roses as if nothing had happened, but he lets us call him Ulysses when nobody's listening. Oblivia Newton has gone back to her house on the hill to sulk. Black Vulcano stayed in the Garden.\nNobody has the First Key. Nobody ever did.\nFred is asleep on the bench in the square, as usual, with his enormous ring of keys in his lap.\nThe Doors are still there, all of them. Somebody has to keep them safe. Ulysses says it might as well be us.")
		Game.current.say_later("End of book 6: The First Key. Thank you for playing Ulysses Moore, books 1 to 6. (Look closely at Fred's key ring.)", 4.0)


## Manfred leaves Oblivia for Gwendaline the hairdresser and takes her to Punt
## through the Cat Door (canon ✅, LOW–MEDIUM on the details).
func _manfred_goes() -> void:
	GameState.set_flag("b6.manfred_gone")
	GameState.add_journal("manfred_punt", "Manfred and Gwendaline",
		"By Miss Biggles's house: Manfred, in a clean shirt, holding hands with Gwendaline the hairdresser. He tipped his cap to us, very politely, and the two of them went into Miss Biggles's house. Through the window we saw them open the door with the cat on it, and walk through, into the sunshine of Punt.\nGwendaline says she's going to open a beauty salon there.")
	Game.current.say("Manfred, in a clean shirt, hand in hand with Gwendaline the hairdresser, tips his cap to you. The pair of them walk into Miss Biggles's house... and out through the Cat Door, into the sunshine of Punt.")


## Book 6 step 8 (canon MEDIUM ✅: Rick's father died searching for the First
## Key, with Minaxo). The scene is adaptation; for Rick (Julia's player) only.
func _rick_father() -> void:
	GameState.set_flag("b6.father")
	GameState.add_journal("rick_father", "Rick: my father",
		"Mr Minaxo looked at the sea for a long time before he said anything.\n\"Your father was my friend. Years after that summer, he and I went looking for the First Key, the one that opens every Door. We never found it. He didn't come back. I did. I should have told you a long time ago, lad. I'm sorry.\"\nNobody ever found the First Key. Not Dad, not Minaxo, not any of them.", "julia")
	Game.current.say("Minaxo, quietly: \"Your father was my friend. We went looking for the First Key together, years ago. He didn't come back.\" Then: \"Go on. Ulysses is waiting at the station.\"", "julia")


func _build_school_town() -> void:
	# The school, on the south side of the square.
	add_box(Vector3(12, 5, 3), Vector3(-23, 2.5, 15), Color(0.7, 0.6, 0.5))
	add_label("KILMORE COVE SCHOOL", Vector3(-23, 4.4, 13.4), 180)
	var door := LevelExit.new()
	door.level = SCHOOL
	door.requires = "b5.started & !b5.jason_out"
	door.prompt = "Go into school"
	place(door, "SchoolDoor", Vector3(-23, 1, 12.6))
	add_box(Vector3(1.2, 0.8, 0.1), Vector3(-18.5, 3.0, 13.45), Color(0.6, 0.75, 0.85))
	add_label("restroom window", Vector3(-18.5, 3.7, 13.4), 180).font_size = 22
	add_climb_wall(Vector3(1.4, 2.5, 0.6), Vector3(-18.5, 1.25, 13.1))
	var window := LevelExit.new()
	window.who = "jason"
	window.solo = true
	window.level = SCHOOL
	window.entry = "restroom"
	window.requires = "b5.dad_gone & b5.jason_out"
	window.prompt = "Climb in through the restroom window"
	window.on_used = _caught
	place(window, "RestroomWindow", Vector3(-18.5, 3.4, 12.6))

	# Chubber's pastry shop, on the west side of the square (canon, MEDIUM).
	var shop := Color(0.85, 0.65, 0.55)
	add_box(Vector3(7, 4, 0.5), Vector3(-36.5, 2, -8), shop)
	add_box(Vector3(7, 4, 0.5), Vector3(-36.5, 2, 0), shop)
	add_box(Vector3(0.5, 4, 3), Vector3(-33, 2, -6.5), shop)
	add_box(Vector3(0.5, 4, 3), Vector3(-33, 2, -1.5), shop)
	add_label("CHUBBER'S PASTRIES", Vector3(-32.7, 3.5, -4), -90).font_size = 30
	var hide := Switch.new()
	hide.who = "jason"
	hide.flag = "b5.hid"
	hide.requires = "b5.dad_walk & !b5.dad_gone"
	hide.prompt = "Duck behind the cake counter"
	place(hide, "HideInChubbers", Vector3(-37, 1, -4))

	var dad := Npc.new()
	dad.npc_name = "Mr Covenant (Dad!)"
	dad.color = Color(0.3, 0.4, 0.55)
	dad.who = "nobody"
	dad.present = "b5.dad_walk & !b5.dad_gone"
	dad.walk_speed = 2.5
	var stations := [["", DAD_ROUTE[0]]]
	for i in DAD_ROUTE.size():
		stations.append(["b5.dad=%d" % i, DAD_ROUTE[i]])
	dad.stations = stations
	place(dad, "Dad", DAD_ROUTE[0])


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_run_epilogue()
	if not multiplayer.is_server() or not GameState.get_flag("b5.dad_walk", false) or GameState.get_flag("b5.dad_gone", false):
		return
	var jason := Game.current.get_player(1)
	if jason == null or Game.current.level_for("jason") != self:
		return
	if GameState.get_flag("b5.hid", false):
		_hid_t += delta
		if _hid_t > 6.0:
			GameState.set_flag("b5.dad_gone")
			Game.current.say("Through the shop window you watch Dad stroll past, buy a newspaper and wander off. Phew. Now: back into school, through the restroom window.", "jason")
		return
	_dad_t += delta
	if _dad_t >= DAD_SECONDS:
		_dad_t = 0.0
		GameState.set_flag("b5.dad", (int(GameState.get_flag("b5.dad", 0)) + 1) % DAD_ROUTE.size())
	if sees(get_node("Dad"), jason, 7.0):
		jason.teleport.rpc(to_global(Vector3(-30, 1, -29)), 0.0)
		Game.current.say("\"Jason?\" You dive behind a wall just in time and run back toward the lighthouse. Did he see you? Try again: Chubber's pastry shop, on the west side of the square.", "jason")


## Step 4 (canon, MEDIUM): caught, and the headteacher confiscates the keys,
## the half-burned photo and the Egyptian charm.
func _caught(_player: Node3D) -> void:
	GameState.set_flag("b5.jason_out", false)
	GameState.set_flag("b5.confiscated")
	for k in ["owl_key", "porcupine_key", "elephant_key", "newt_key"]:
		GameState.take_item(k)
	GameState.add_journal("confiscated", "Confiscated",
		"Jason climbed back in through the restroom window... straight into the headteacher. He turned out Jason's pockets on the spot: the four keys from Villa Argo, the half-burned photograph from the Isle of Masks, and the little Egyptian charm from Punt. \"You'll have these back at the end of term, Mr Covenant.\" They're locked in his office.\nWithout the keys, we can't open the Door.")
	Game.current.say("Jason drops in through the restroom window, right at the headteacher's feet. \"Empty your pockets, Mr Covenant.\"")


func _build_railway() -> void:
	# Tracks from the street east to a sealed tunnel (canon, HIGH). The station
	# is book 5: closed and boarded up.
	for z in [-0.7, 0.7]:
		add_box(Vector3(40, 0.12, 0.12), Vector3(33, 0.06, z), Color(0.35, 0.3, 0.28))
	for i in 20:
		add_box(Vector3(0.4, 0.06, 2), Vector3(14 + i * 2, 0.03, 0), Color(0.4, 0.3, 0.2))
	add_box(Vector3(2, 8, 10), Vector3(54, 4, 0), Color(0.45, 0.42, 0.38))
	add_box(Vector3(0.3, 3.5, 3), Vector3(52.9, 1.75, 0), Color(0.35, 0.25, 0.15))
	add_label("tunnel (boarded up)", Vector3(52.6, 4, 0), -90)
	add_box(Vector3(6, 4, 4), Vector3(22, 2, 7), Color(0.6, 0.55, 0.5))
	add_label("STATION (CLOSED)", Vector3(22, 4.4, 4.8), 0)
	_build_town_hall()
	var tunnel := JournalNote.new()
	tunnel.who = "jason"
	tunnel.requires = "b3.started"
	tunnel.entry_id = "tunnel"
	tunnel.title = "Tracks to nowhere"
	tunnel.body = "I followed the railway out of the village. It doesn't go to any other town: it runs straight into a tunnel in the hill, and the tunnel is boarded up. Rusty rails, no trains. Where was it ever supposed to go?"
	tunnel.prompt = "Look at the boarded-up tunnel"
	tunnel.size = Vector3(0.01, 0.01, 0.01)
	tunnel.on_used = func(_p: Node3D) -> void: _found("b3.tracks")
	place(tunnel, "Tunnel", Vector3(51.8, 1, 0))


## Book 5 step 6 (canon, HIGH): sleepy Fred Dormiveglia, the town hall clerk
## with all the keys, opens the chained station.
func _build_town_hall() -> void:
	add_box(Vector3(6, 5, 5), Vector3(16, 2.5, -10.5), Color(0.8, 0.78, 0.7))
	add_label("TOWN HALL", Vector3(16, 4.4, -7.9), 0)
	add_box(Vector3(2, 3, 0.2), Vector3(22, 1.5, 4.9), Color(0.3, 0.3, 0.3))
	add_label("chains and a padlock", Vector3(22, 3.3, 4.7), 0).font_size = 22
	var fred := Npc.new()
	fred.npc_name = "Fred Dormiveglia"
	fred.color = Color(0.55, 0.5, 0.4)
	fred.walk_speed = 1.5
	fred.stations = [["", Vector3(16, 1, -6.8)], ["b5.station_open", Vector3(20, 1, 4)], ["b6.home", Vector3(-17, 1, -1.2)]]
	fred.lines = [
		["", "*yaaawn* Town hall's closed for lunch. Or... is it open? Come back later."],
		["b5.recovered", "Clark Beamish Station? Nobody's asked for that in years. Yes, yes, I've got the keys. I've got all the keys. Come along, then... slowly."],
		["b5.station_open", "There you are, all open. Mind the birds. I'll be inside, resting my eyes."],
		["b6.home", "Zzzz... hm? Oh, it's you. Back from wherever it was. Zzzz..."],
	]
	fred.on_used = func(_p: Node3D) -> void:
		if GameState.get_flag("b5.recovered", false) and not GameState.get_flag("b5.station_open", false):
			GameState.set_flag("b5.station_open")
			GameState.add_journal("fred", "Fred Dormiveglia",
				"Fred from the town hall is the sleepiest man in Kilmore Cove, and he carries a ring of about a hundred keys. Ordinary keys: he found the right one for the station's padlock on only the eleventh try. The chains are off. Clark Beamish Station is open.")
			Game.current.say_later("Fred yawns his way down to the station, tries eleven keys, and the chains fall off the door. \"There you are.\"", 1.5)
	place(fred, "Fred", Vector3(16, 1, -6.8))

	var door := LevelExit.new()
	door.level = STATION
	door.requires = "b5.station_open"
	door.prompt = "Go into the station"
	door.solo_when = "b6.playing_rick"
	place(door, "StationDoor", Vector3(22, 1, 3.8))


func _build_mirror_house() -> void:
	# The House of Mirrors (canon, HIGH): the inside is book 3 Pass B.
	add_box(Vector3(16, 7, 12), Vector3(33, 3.5, -22), Color(0.7, 0.75, 0.8))
	for x in [27.0, 39.0]:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(2.5, 3.5, 0.1)
		m.mesh = b
		var shine := Vis.material(Color(0.85, 0.9, 0.95))
		shine.metallic = 1.0
		shine.roughness = 0.1
		m.material_override = shine
		m.position = Vector3(x, 2.5, -15.9)
		add_child(m)
	add_label("THE HOUSE OF MIRRORS", Vector3(33, 6, -15.7), 0)
	add_box(Vector3(2, 3, 0.3), Vector3(33, 1.5, -15.8), Color(0.3, 0.2, 0.12))
	var enter := LevelExit.new()
	enter.level = MIRROR_HOUSE
	enter.requires = "b3.dedalus & !b3.escaped"
	enter.prompt = "Go into the House of Mirrors"
	place(enter, "MirrorHouseDoor", Vector3(33, 1, -14.8))
	# After book 3: half the house is rubble.
	_ruins = Node3D.new()
	add_child(_ruins)
	for i in 7:
		var rock := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(2.5 + (i % 3), 1.2 + (i % 2), 2.0)
		rock.mesh = b
		rock.material_override = Vis.material(Color(0.6, 0.62, 0.66))
		rock.position = Vector3(27 + i * 2, 0.6, -17.5 - (i % 3) * 1.5)
		rock.rotation_degrees.y = i * 29.0
		_ruins.add_child(rock)
	GameState.changed.connect(func(_k: String) -> void: _ruins.visible = GameState.get_flag("b3.escaped", false))
	_ruins.visible = GameState.get_flag("b3.escaped", false)


func _talk_calypso(_player: Node3D) -> void:
	var all := IMPOSSIBLE.all(func(i: Array) -> bool: return GameState.get_flag(i[0], false))
	if all and not GameState.has_item("tourist_guide"):
		GameState.give_item("tourist_guide", "old tourist guide")
		GameState.add_journal("tourist_guide", "An old tourist guide", GUIDE, "julia")
	if GameState.has_journal("three_marks"):
		_met("b3.calypso_dedalus")


## Book 3 step 6: once all three have talked about Dedalus.
func _met(flag: String) -> void:
	if not GameState.has_journal("three_marks"):
		return
	GameState.set_flag(flag)
	if GameState.get_flag("b3.dedalus", false):
		return
	if ["b3.met_biggles", "b3.met_minaxo", "b3.calypso_dedalus"].all(func(f: String) -> bool: return GameState.get_flag(f, false)):
		GameState.set_flag("b3.dedalus")
		GameState.add_journal("dedalus", "Peter Dedalus",
			"Calypso, Mr Minaxo and Miss Biggles all knew Ulysses Moore, and all of them knew Peter Dedalus: inventor, watchmaker, builder of the House of Mirrors, and Ulysses's friend. One day he just vanished.\nThe map marked his house. We have to get inside.")


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.present = "b3.started & !b6.playing_rick"
	rick.walk_speed = 5.0
	rick.stations = [
		["", Vector3(2.5, 1, 6)],
		["item:tourist_guide", Vector3(-17.5, 1, -2.5)],
		["b3.dedalus", Vector3(31, 1, -14)],
		["b3.escaped", Vector3(30, 1, -12)],
		["b5.recovered", Vector3(14, 1, -5.5)],
		["b6.home", Vector3(-21, 1, 4)],
	]
	rick.lines = [
		["b3.started", "Let's make a list of everything that's strange about this place. I've lived here all my life and I never noticed. The bookshop has atlases, there's the phone box, the old railway, and that statue in the square..."],
		["b3.no_maps & b3.no_signal & b3.tracks & b3.king", "That's all four. Let's show Calypso: she knows everything about this village."],
		["item:tourist_guide", "Jason, you saw the map in Punt. Can you remember where the marks were? Julia, check them against the guide."],
		["journal:three_marks", "The lighthouse, the cat house and the House of Mirrors. Let's ask the people who live there."],
		["b3.dedalus", "The House of Mirrors, then. Come on: the door's not even locked."],
		["b3.escaped", "Venice. If Oblivia's gone after Dedalus, we'll have to go too. The Metis took us to Egypt... maybe it can take us there."],
		["b5.recovered", "Fred's at the town hall. He's got the keys to everything in Kilmore Cove... if you can keep him awake long enough."],
		["b5.station_open", "The station! I've never been inside. Nobody has, not for years."],
		["b5.train_awake", "Back to Argo. Nestor needs to hear about this."],
		["b6.home", "So, um. Julia. Do you want to go for a walk? Along the harbour. Just a walk."],
		["b6.julia_rick", "Tomorrow, then. The harbour. ...Stop grinning, Jason."],
	]
	rick.on_used = func(p: Node3D) -> void:
		if p.role == "julia" and GameState.get_flag("b6.home", false) and not GameState.get_flag("b6.julia_rick", false):
			GameState.set_flag("b6.julia_rick")
			GameState.add_journal("julia_rick", "A walk along the harbour",
				"Rick went red to the roots of his red hair and asked me to go for a walk along the harbour. Just a walk. I said yes.\nJason pretended to be sick into a flowerbed. He's going to be unbearable about this.")
			Game.current.say("Julia says yes. Rick turns the colour of his hair. Behind them, Jason pretends to be sick into a flowerbed.")
	place(rick, "Rick", Vector3(2.5, 1, 6))
