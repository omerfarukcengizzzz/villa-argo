extends Level
## Kilmore Cove. Book 1 step 7: the post office, where the receipt from the
## tower diary gets the twins the parcel with the four animal keys and a second
## coded message (canon, ref B1 scene 8). Book 3 (docs/book3-design.md, steps
## 3-6): the impossible village (no maps, no signal, tracks to nowhere, the
## statue of a king who never reigned), Calypso's old tourist guide, the marks
## Jason remembers from the map, and the old residents who knew Ulysses and
## Dedalus. The House of Mirrors opens in book 3 Pass B. Layout is adaptation.
##
## Map (north = -z): the main street (x -6..6) from the gate road (z 12) to the
## post office (z -8..-14). West: the square with the statue, phone box,
## Calypso's bookshop and Miss Biggles's house; north of it, the lighthouse.
## East: the railway to a sealed tunnel, and the House of Mirrors.

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"
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


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.2, 1, 8), "julia": Vector3(1.2, 1, 8), "yaw": 0.0},
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
	_build_rick()


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
	]
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
	]
	minaxo.on_used = func(_p: Node3D) -> void: _met("b3.met_minaxo")
	place(minaxo, "Minaxo", Vector3(-30, 1, -30.8))


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
	add_label("(locked)", Vector3(33, 3.3, -15.5), 0).font_size = 24


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
	rick.present = "b3.started"
	rick.walk_speed = 5.0
	rick.stations = [
		["", Vector3(2.5, 1, 6)],
		["item:tourist_guide", Vector3(-17.5, 1, -2.5)],
		["b3.dedalus", Vector3(31, 1, -14)],
	]
	rick.lines = [
		["b3.started", "Let's make a list of everything that's strange about this place. I've lived here all my life and I never noticed. The bookshop has atlases, there's the phone box, the old railway, and that statue in the square..."],
		["b3.no_maps & b3.no_signal & b3.tracks & b3.king", "That's all four. Let's show Calypso: she knows everything about this village."],
		["item:tourist_guide", "Jason, you saw the map in Punt. Can you remember where the marks were? Julia, check them against the guide."],
		["journal:three_marks", "The lighthouse, the cat house and the House of Mirrors. Let's ask the people who live there."],
		["b3.dedalus", "The House of Mirrors, then. It's locked... for now."],
	]
	place(rick, "Rick", Vector3(2.5, 1, 6))
