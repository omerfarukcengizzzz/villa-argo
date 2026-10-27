extends Level
## Behind the scarred Door, book 1 (docs/book1-design.md, steps 9-13): the round
## room with four exits, the dark stair lit by glowing clay, the chamber of four
## turning floor stones, the hatch, the sea cave and the Metis. Canon sequence
## per the story reference (§5 "Behind the Door", MEDIUM); layout, exit symbols
## and the stone solution are adaptation.
##
## Map (north = -z): entry corridor z 6..12 at floor 0; round room x/z -6..6;
## dark stair north from z -6, down to the chamber (floor -8) at z -29..-41;
## the hatch drops into the sea cave (beach at -16) with the Metis to the north.

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"
const SELF := "res://scenes/levels/argo_underground.tscn"
const PUNT := "res://scenes/levels/punt.tscn"
const VENICE := "res://scenes/levels/venice.tscn"
const STAIR_TOPS := [0.0, -2.0, -4.0, -6.0]
const STAIR_Z := [-10.75, -15.75, -20.75, -25.75]
## Floor stone targets (0 north, 1 east, 2 south, 3 west), stone 1 first.
const STONE_TARGETS := [1, 3, 2, 1]

const ROCK := Color(0.35, 0.33, 0.3)
const SAND := Color(0.75, 0.68, 0.5)

var _candle: OmniLight3D
var _hatch: StaticBody3D


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-0.6, 1, 10), "julia": Vector3(0.6, 1, 10)},
		"round_room": {"jason": Vector3(-0.8, 1, 2), "julia": Vector3(0.8, 1, 2)},
		"beach": {"jason": Vector3(-1.5, -15, -40), "julia": Vector3(1.5, -15, -46)},
	}
	fall_y = -25.0
	add_environment(Color(0.0, 0.0, 0.0))
	_env.ambient_light_color = Color(0.03, 0.03, 0.04)
	_sun.light_energy = 0.0

	_build_round_room()
	_build_stair()
	_build_chamber()
	_build_cave()
	_build_rick()

	GameState.changed.connect(_on_state_changed)
	_on_state_changed("")


func respawn_point(role: String, fell_from: Vector3) -> Vector3:
	var side := -0.5 if role == "jason" else 0.5
	if fell_from.z < -35.0:
		return Vector3(side, -15, -40)
	if fell_from.z < -6.0:
		return Vector3(side, 1, -10.5)
	return spawn_point(role, "round_room")


func _on_state_changed(_key: String) -> void:
	_candle.visible = not GameState.get_flag("under.candle_out", false)
	var open: bool = GameState.get_flag("stones.solved", false)
	_hatch.visible = not open
	_hatch.get_child(1).disabled = open


func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		_check_reunion()
	if not multiplayer.is_server() or GameState.get_flag("under.candle_out", false):
		return
	for p in Game.current.get_players():
		if Game.current.level_for(p.role) == self and to_local(p.global_position).z < -9.0:
			GameState.set_flag("under.candle_out")
			Game.current.say("A cold draught rushes up the stairs and blows the candle out. Pitch black.")
			return


# --- Round room (step 9) ------------------------------------------------------------

func _build_round_room() -> void:
	add_box(Vector3(3, 0.5, 7), Vector3(0, -0.25, 9.5), ROCK)
	add_box(Vector3(0.5, 4, 7), Vector3(-1.75, 2, 9.5), ROCK)
	add_box(Vector3(0.5, 4, 7), Vector3(1.75, 2, 9.5), ROCK)
	add_box(Vector3(4, 4, 0.5), Vector3(0, 2, 13.25), ROCK)
	var back := LevelExit.new()
	back.level = VILLA_ARGO
	back.entry = "door"
	back.prompt = "Climb back up to the house"
	place(back, "BackToHouse", Vector3(0, 1, 12))

	add_box(Vector3(12, 0.5, 12), Vector3(0, -0.25, 0), ROCK)
	# Four walls, each with a 2 m exit in the middle.
	for side in [-1.0, 1.0]:
		add_box(Vector3(5, 5, 0.5), Vector3(side * 3.5, 2.5, -6), ROCK)
		add_box(Vector3(5, 5, 0.5), Vector3(side * 3.5, 2.5, 6), ROCK)
		add_box(Vector3(0.5, 5, 5), Vector3(-6, 2.5, side * 3.5), ROCK)
		add_box(Vector3(0.5, 5, 5), Vector3(6, 2.5, side * 3.5), ROCK)
	add_label("SUN", Vector3(0, 3.2, 5.7), 180)
	add_label("MOON", Vector3(0, 3.2, -5.7), 0)
	add_label("FLAME", Vector3(-5.7, 3.2, 0), 90)
	add_label("WAVE", Vector3(5.7, 3.2, 0), -90)

	_candle = OmniLight3D.new()
	_candle.light_color = Color(1.0, 0.75, 0.45)
	_candle.omni_range = 11.0
	_candle.position = Vector3(0, 2.5, 0)
	add_child(_candle)

	# The floor inscription, letters run together; only Julia can make it out.
	var letters := add_label("BYNIGHTWEMOVE\nQUICKLYFEARING\nTHEBURNINGFIRE", Vector3(0, 0.02, -1.5))
	letters.rotation_degrees.x = -90
	letters.font_size = 72
	letters.modulate = Color(0.9, 0.85, 0.7)
	Vis.make_private(letters, "julia")
	var inscription := JournalNote.new()
	inscription.who = "julia"
	inscription.entry_who = "julia"
	inscription.entry_id = "floor_inscription"
	inscription.title = "The floor inscription"
	inscription.body = "Letters run together across the floor of the round room. Split into words:\n\"By night we move quickly, fearing the burning fire.\""
	inscription.prompt = "Read the floor"
	inscription.size = Vector3(0.01, 0.01, 0.01)
	place(inscription, "Inscription", Vector3(0, 1, -1.5))

	# Wrong exits wind round and come back here.
	for exit_name in ["Flame", "Wave"]:
		var x := -7.75 if exit_name == "Flame" else 7.75
		add_box(Vector3(3.5, 0.5, 2.5), Vector3(x, -0.25, 0), ROCK)
		add_box(Vector3(0.5, 5, 2.5), Vector3(x * 1.23, 2.5, 0), ROCK)
		add_box(Vector3(3.5, 5, 0.5), Vector3(x, 2.5, -1.25), ROCK)
		add_box(Vector3(3.5, 5, 0.5), Vector3(x, 2.5, 1.25), ROCK)
		var loop := LevelExit.new()
		loop.level = SELF
		loop.entry = "round_room"
		loop.prompt = "Follow the passage"
		loop.on_used = func(_p: Node3D) -> void:
			Game.current.say("The passage twists and turns in the dark... and brings you back to the round room.")
		place(loop, exit_name + "Passage", Vector3(x * 1.08, 1, 0))


# --- Dark stair (step 10) ------------------------------------------------------------

func _build_stair() -> void:
	add_box(Vector3(0.5, 13, 23), Vector3(-1.75, -3.5, -17.5), ROCK)
	add_box(Vector3(0.5, 13, 23), Vector3(1.75, -3.5, -17.5), ROCK)
	add_box(Vector3(3, 0.5, 3), Vector3(0, -0.25, -7.5), ROCK)
	for i in STAIR_TOPS.size():
		var top: float = STAIR_TOPS[i]
		add_box(Vector3(3, 0.5, 3.5), Vector3(0, top - 0.25, STAIR_Z[i]), ROCK)
		var socket := LightSocket.new()
		socket.who = "julia"
		socket.requires = "item:clay"
		socket.lit_flag = "under.niche%d" % i
		place(socket, "Niche%d" % i, Vector3(-1.2, top + 1.2, STAIR_Z[i] - 1.2))
	# Between platforms: 1.5 m gaps and 2 m drops; falling sends you back up.


# --- Chamber of the four stones (step 11) ------------------------------------------

func _build_chamber() -> void:
	var floor_y := -8.0
	# Floor around the hatch hole (x -1..1, z -40..-38).
	add_box(Vector3(12, 0.5, 9), Vector3(0, floor_y - 0.25, -33.5), ROCK)
	add_box(Vector3(12, 0.5, 1), Vector3(0, floor_y - 0.25, -40.5), ROCK)
	add_box(Vector3(5, 0.5, 2), Vector3(-3.5, floor_y - 0.25, -39), ROCK)
	add_box(Vector3(5, 0.5, 2), Vector3(3.5, floor_y - 0.25, -39), ROCK)
	_hatch = add_box(Vector3(2, 0.5, 2), Vector3(0, floor_y - 0.25, -39), Color(0.4, 0.3, 0.2))
	add_box(Vector3(0.5, 6, 12), Vector3(-6, floor_y + 3, -35), ROCK)
	add_box(Vector3(0.5, 6, 12), Vector3(6, floor_y + 3, -35), ROCK)
	add_box(Vector3(12, 6, 0.5), Vector3(0, floor_y + 3, -41), ROCK)
	add_box(Vector3(4.25, 6, 0.5), Vector3(-3.875, floor_y + 3, -29), ROCK)
	add_box(Vector3(4.25, 6, 0.5), Vector3(3.875, floor_y + 3, -29), ROCK)
	add_label("N", Vector3(0, floor_y + 4.5, -40.7), 0)

	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.9, 0.8, 0.6)
	lamp.omni_range = 9.0
	lamp.light_energy = 0.8
	lamp.position = Vector3(0, floor_y + 4.5, -35)
	add_child(lamp)

	for n in range(1, 5):
		var stone := FloorStone.new()
		stone.number = n
		stone.targets = STONE_TARGETS
		place(stone, "Stone%d" % n, Vector3(-3.9 + (n - 1) * 2.6, floor_y + 1, -35.5))

	# Jason's ledge: from up here the painted ceiling makes sense.
	add_climb_wall(Vector3(1.6, 3.5, 3), Vector3(5.2, floor_y + 1.75, -31.5))
	var ceiling := JournalNote.new()
	ceiling.who = "jason"
	ceiling.entry_who = "jason"
	ceiling.entry_id = "ceiling_arrows"
	ceiling.title = "The painted ceiling"
	ceiling.body = "From the ledge, the faded painting on the ceiling lines up: four arrows over four stones.\nStone 1 points east. Stone 2 points west. Stone 3 points south. Stone 4 points east."
	ceiling.prompt = "Study the painted ceiling"
	ceiling.size = Vector3(0.6, 0.05, 0.6)
	place(ceiling, "PaintedCeiling", Vector3(5.2, floor_y + 4.4, -31.5))
	var hint := add_label("arrows painted on the ceiling", Vector3(5.6, floor_y + 5.6, -31.5), -90)
	hint.font_size = 28
	Vis.make_private(hint, "jason")


# --- Sea cave and the Metis (steps 12-13) -----------------------------------------

func _build_cave() -> void:
	var beach_y := -16.0
	add_box(Vector3(20, 0.5, 16), Vector3(0, beach_y - 0.25, -42), SAND)
	add_box(Vector3(0.5, 10, 30), Vector3(-10, beach_y + 5, -47), ROCK)
	add_box(Vector3(0.5, 10, 30), Vector3(10, beach_y + 5, -47), ROCK)
	add_box(Vector3(20, 10, 0.5), Vector3(0, beach_y + 5, -62), ROCK)
	add_box(Vector3(20, 7.5, 0.5), Vector3(0, beach_y + 3.75, -34), ROCK)
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 12)
	sea.mesh = plane
	sea.material_override = Vis.material(Color(0.1, 0.3, 0.45))
	sea.position = Vector3(0, beach_y - 0.5, -56)
	add_child(sea)
	var sea_light := OmniLight3D.new()
	sea_light.light_color = Color(0.5, 0.75, 0.9)
	sea_light.omni_range = 18.0
	sea_light.position = Vector3(0, beach_y + 5, -48)
	add_child(sea_light)

	# The Metis: hull, mast, cabin; a gangplank from the beach.
	var deck_y := beach_y + 1.5
	add_box(Vector3(4, 2, 10), Vector3(0, deck_y - 1, -55), Color(0.4, 0.28, 0.18))
	add_box(Vector3(0.3, 7, 0.3), Vector3(0, deck_y + 3.5, -54), Color(0.35, 0.25, 0.15))
	add_box(Vector3(3, 2, 2.5), Vector3(0, deck_y + 1, -58.5), Color(0.5, 0.36, 0.22))
	add_ramp(1.5, 2.5, 1.5, Vector3(0, beach_y, -47.5), Color(0.45, 0.32, 0.2))
	add_label("METIS", Vector3(2.05, deck_y - 0.8, -55), 90)

	var log := JournalNote.new()
	log.entry_id = "captains_log"
	log.title = "The captain's log"
	log.body = "In the Metis's cabin, the captain's log: \"The Metis will not sail by oar or wind alone. Whoever stands at the helm must choose where to go.\""
	log.prompt = "Read the captain's log"
	log.size = Vector3(0.5, 0.08, 0.35)
	log.on_used = func(_p: Node3D) -> void:
		GameState.set_flag("metis.log_read")
		if GameState.has_journal("handwriting"):
			GameState.add_journal("same_handwriting", "The same handwriting",
				"The captain's log is written in the same tall, slanted hand as Ulysses Moore's diary: the looping U, every t crossed twice. Ulysses Moore sailed this ship.", "julia")
	place(log, "CaptainsLog", Vector3(0, deck_y + 1, -57))

	var helm := Helm.new()
	helm.requires = "metis.log_read"
	helm.answer = "Egypt"
	helm.solved_flag = "metis.sailed"
	helm.question = "Where should the Metis sail?"
	helm.options = [["Egypt", true], ["Somewhere else... (the helm won't turn)", false]]
	helm.on_used = _sail
	place(helm, "Helm", Vector3(0, deck_y + 1.2, -52))

	# Book 4: the Metis to Venice (canon: the Argo Door and the Metis, MEDIUM).
	var to_venice := Helm.new()
	to_venice.requires = "b4.started & !b4.sailed"
	to_venice.answer = "Venice"
	to_venice.solved_flag = "b4.sailed"
	to_venice.question = "Where should the Metis sail?"
	to_venice.wrong_text = "The helm won't turn. The Metis seems to know where you need to go."
	to_venice.options = [["Egypt", true], ["Venice", true]]
	to_venice.on_used = func(_p: Node3D) -> void:
		GameState.set_flag("b4.away")
		Game.current.change_level(VENICE)
		Game.current.say("The helm shudders, the mist closes in... and opens on a lagoon full of bells: Venice.")
	place(to_venice, "HelmVenice", Vector3(0, deck_y + 1.2, -52))


## Book 4 step 17 (canon chapter "Ritorni a casa", HIGH): Julia and Rick come
## home on the Metis; once Jason is down on the beach too, the twins are back
## together.
func _check_reunion() -> void:
	if not GameState.get_flag("b4.julia_home", false) or GameState.get_flag("b4.home", false):
		return
	if Game.current.level_for("jason") != self or Game.current.level_for("julia") != self:
		return
	for f in ["b4.split", "b4.away"]:
		GameState.set_flag(f, false)
	GameState.set_flag("b4.home")
	Game.current.say("Jason comes skidding down onto the beach as the Metis bumps against the sand. Julia and Rick jump down. Everyone talks at once.")
	GameState.add_journal("b4_home", "Home from Venice",
		"Together again on the beach under Villa Argo. Jason dealt with Don Diego and Dieguita and their dog, and the Old Owl gave him the Black Gondolier's word. Julia and Rick found the Callers' secret press, Penelope's house, and Peter Dedalus on the Isle of Masks.
Penelope Moore was born in Venice. Oblivia and Dedalus were close once. And Dedalus says Black Vulcano has all the keys, even the First.
So: who is Black Vulcano, and where is he?")
	Game.current.say_later("End of book 4: The Isle of Masks. (Book 5, The Stone Guardians, comes next.)", 5.0)


## End of book 1: the Metis sails, and book 2 starts in Punt.
func _sail(_player: Node3D) -> void:
	Game.current.say("Jason shouts: \"Egypt!\" The helm vibrates under his hands, and the Metis slides out into the mist.")
	GameState.add_journal("book1_end", "Towards the Ports of Dreams",
		"We chose Egypt. The Metis carried us out of the cave and into the mist.")
	await get_tree().create_timer(4.0).timeout
	GameState.set_flag("b2.started")
	GameState.set_flag("b2.away")
	Game.current.change_level(PUNT)
	Game.current.say("Book 2: The Long-Lost Map. The mist clears over a hot, bright harbour: the Land of Punt.")


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.stations = [
		["", Vector3(3.5, 1, 3.5)],
		["under.candle_out", Vector3(0.8, 1, -9.5)],
		["under.niche3", Vector3(-4.5, -7, -31)],
		["stones.solved", Vector3(-3, -15, -41)],
	]
	rick.lines = [
		["", "Four ways out, and we came in by one of them. There are letters all over the floor... Julia, can you make anything of them?"],
		["journal:floor_inscription", "By night, fearing the fire... so not the flame. And at night you'd follow... the moon?"],
		["under.candle_out", "The candle's out! Julia, you've still got that glowing clay from the cliff, haven't you?"],
		["under.niche3", "Four stones with arrows. Jason, there's a ledge up there. Maybe you can see something from it?"],
		["journal:ceiling_arrows", "Four, three, two, one... that note from the post office! Maybe the order matters."],
		["stones.solved", "A ship! A real ship, down here!"],
		["metis.log_read", "It says someone has to choose where to go. Jason, take the helm!"],
		["metis.sailed", "Egypt! I can't believe it!"],
	]
	place(rick, "Rick", Vector3(3.5, 1, 3.5))
