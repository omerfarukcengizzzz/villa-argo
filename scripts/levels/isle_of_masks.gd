extends Level
## The Isle of Masks, book 4 (docs/book4-design.md, steps 15-16): Dedalus's
## workshop full of masks and machines. Julia (with Rick) finds Peter Dedalus;
## Oblivia arrives; the workshop catches fire and they escape through the back,
## past an old photograph of a young man labelled "Ulysses", to the Black
## Gondolier. Dedalus: "Black Vulcano has the keys, even the First."
## Canon: the Gondolier takes them to Dedalus, Oblivia closes in, the fire, a
## photo of Ulysses, Dedalus's line, Dedalus was Oblivia's former lover
## (MEDIUM / HIGH). Layout, the escape and the timer are adaptation.
## Phases (flag isle.phase): "" -> oblivia -> fire -> escaped.
##
## Map (north = -z): the front jetty z 2..8; the workshop x -8..8, z -16..2;
## behind it the corridor of masks z -32..-16 to the back jetty.

const VENICE := "res://scenes/levels/venice.tscn"
const FIRE_SECONDS := 60
const WORKSHOP := Vector3(0, 1, -6)
const WOOD := Color(0.4, 0.3, 0.22)

var _phase_t := 0.0


func _init() -> void:
	origin = Vector3(18000, 0, 0)


func _build() -> void:
	entries = {"default": {"jason": Vector3(-1, 1, 5), "julia": Vector3(1, 1, 5), "yaw": 0.0}}
	fall_y = -10.0
	add_environment(Color(0.12, 0.12, 0.2))
	_env.ambient_light_color = Color(0.35, 0.33, 0.4)
	_sun.light_energy = 0.3
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.8, 0.55)
	lamp.omni_range = 14.0
	lamp.position = Vector3(0, 3, -8)
	add_child(lamp)

	add_box(Vector3(6, 0.5, 6), Vector3(0, -0.25, 5), WOOD)
	add_box(Vector3(16, 0.5, 18), Vector3(0, -0.25, -7), Color(0.45, 0.42, 0.4))
	add_box(Vector3(6, 4, 0.5), Vector3(-5, 2, 2), WOOD)
	add_box(Vector3(6, 4, 0.5), Vector3(5, 2, 2), WOOD)
	add_box(Vector3(0.5, 4, 18), Vector3(-8, 2, -7), WOOD)
	add_box(Vector3(0.5, 4, 18), Vector3(8, 2, -7), WOOD)
	add_box(Vector3(6.5, 4, 0.5), Vector3(-4.75, 2, -16), WOOD)
	add_box(Vector3(6.5, 4, 0.5), Vector3(4.75, 2, -16), WOOD)
	add_label("masks on every wall: laughing, weeping, golden, plain", Vector3(-7.7, 2.6, -7), 90).font_size = 26
	add_box(Vector3(3, 1, 1.5), Vector3(4, 0.5, -10), Color(0.5, 0.42, 0.3))
	add_label("half-built machines", Vector3(4, 1.6, -10)).billboard = BaseMaterial3D.BILLBOARD_ENABLED

	_build_people()
	_build_escape()


func respawn_point(_role: String, _fell_from: Vector3) -> Vector3:
	return WORKSHOP


# --- Dedalus and Oblivia (step 15) ----------------------------------------------

func _build_people() -> void:
	var dedalus := Npc.new()
	dedalus.npc_name = "Peter Dedalus"
	dedalus.color = Color(0.6, 0.55, 0.4)
	dedalus.walk_speed = 4.0
	dedalus.present = "!b4.isle_escaped"
	dedalus.stations = [["", Vector3(-3, 1, -11)], ["isle.phase=fire", Vector3(0, 1, -30)]]
	dedalus.lines = [
		["", "Who... Children? From Kilmore Cove? Ulysses sent you! No, don't tell me, I don't want to know how. You came about Oblivia, didn't you. Oblivia and I... we were close, once. A long time ago. Before I knew what she wanted."],
		["isle.phase=fire", "This way! Out the back, through the masks! Mind the flames!"],
	]
	dedalus.on_used = func(_p: Node3D) -> void:
		if str(GameState.get_flag("isle.phase", "")) == "":
			GameState.add_journal("dedalus_found", "Peter Dedalus",
				"On the Isle of Masks, in a workshop full of masks and half-built machines: Peter Dedalus himself. Small, quick, nervous, inky fingers. He admitted that he and Oblivia Newton were close once, a long time ago.")
			GameState.set_flag("isle.phase", "oblivia")
			_phase_t = 0.0
	place(dedalus, "Dedalus", Vector3(-3, 1, -11))

	var oblivia := Npc.new()
	oblivia.npc_name = "Oblivia Newton"
	oblivia.color = Color(0.6, 0.15, 0.3)
	oblivia.who = "nobody"
	oblivia.present = "!isle.phase= & !isle.phase=escaped"
	oblivia.walk_speed = 2.5
	oblivia.stations = [["", Vector3(0, 1, 4)], ["isle.phase=oblivia", Vector3(0, 1, 0)], ["isle.phase=fire", Vector3(0, 1, 4)]]
	place(oblivia, "Oblivia", Vector3(0, 1, 4))

	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.walk_speed = 4.0
	rick.stations = [["", Vector3(2, 1, 3)], ["isle.phase=fire", Vector3(1.5, 1, -30)]]
	rick.lines = [
		["", "The Isle of Masks... Julia, there he is, at the back!"],
		["isle.phase=fire", "Fire! Get out the back, quick!"],
	]
	place(rick, "Rick", Vector3(2, 1, 3))


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_phase_t += delta
	match str(GameState.get_flag("isle.phase", "")):
		"oblivia":
			if _phase_t > 3.0 and not GameState.get_flag("isle.oblivia_spoke", false):
				GameState.set_flag("isle.oblivia_spoke")
				Game.current.say("\"Peter, darling. You always did like a dramatic hiding place.\" Oblivia Newton stands in the doorway. \"Now: where is the First Key?\"", "julia")
			elif _phase_t > 7.0:
				_start_fire()
		"fire":
			if _phase_t >= 1.0:
				_phase_t = 0.0
				var left: int = GameState.get_flag("isle.fire_left", FIRE_SECONDS) - 1
				GameState.set_flag("isle.fire_left", left)
				if left > 0 and left % 20 == 0:
					Game.current.say("The fire roars! %d seconds!" % left, "julia")
				elif left <= 0:
					_fire_lost()


## Step 16 (canon chapter "Fuoco e fiamme", HIGH): the workshop catches fire.
func _start_fire() -> void:
	_phase_t = 0.0
	GameState.set_flag("isle.fire_left", FIRE_SECONDS)
	GameState.set_flag("isle.back_open")
	GameState.set_flag("isle.phase", "fire")
	Game.current.say("Dedalus sweeps a lamp off the bench. Oil, flame, a wall of fire between you and Oblivia! \"Out the back!\" he shouts. You have %d seconds." % FIRE_SECONDS, "julia")


func _fire_lost() -> void:
	for p in Game.current.get_players():
		if p.role == "julia" and Game.current.level_for("julia") == self:
			p.teleport.rpc(to_global(WORKSHOP), PI)
	GameState.set_flag("isle.fire_left", FIRE_SECONDS)
	Game.current.say("The smoke is too thick... Rick drags you back into the workshop, coughing. Try again, quickly!", "julia")


# --- The corridor of masks and the escape (step 16) ------------------------------

func _build_escape() -> void:
	var back := Door.new()
	back.size = Vector3(3, 3, 0.3)
	back.open_flag = "isle.back_open"
	back.color = WOOD
	place(back, "BackDoor", Vector3(0, 0, -16))

	add_box(Vector3(5, 0.5, 18), Vector3(0, -0.25, -24), Color(0.4, 0.38, 0.36))
	add_box(Vector3(0.5, 4, 16), Vector3(-2.5, 2, -24), WOOD)
	add_box(Vector3(0.5, 4, 16), Vector3(2.5, 2, -24), WOOD)
	add_box(Vector3(6, 0.5, 4), Vector3(0, -0.25, -33), WOOD)
	add_label("the back jetty", Vector3(0, 2.4, -34.8), 0).font_size = 28

	# Flames along the corridor: two sweep across it, one burns in place.
	var lick := "The flames leap at you! You stagger back into the workshop."
	var flames := [[Vector3(0, 0.5, -19), Vector3(0, 0, 0), 0.0], [Vector3(-1.6, 0.5, -23), Vector3(3.2, 0, 0), 2.5], [Vector3(-1.6, 0.5, -27), Vector3(3.2, 0, 0), 3.2]]
	for i in flames.size():
		var flame := Hazard.new()
		flame.active = "isle.phase=fire"
		flame.size = Vector3(1.4 if i == 0 else 1.2, 1.0, 1.2)
		flame.color = Color(0.95, 0.45, 0.1)
		flame.label = "fire"
		flame.respawn = WORKSHOP
		flame.message = lick
		flame.travel = flames[i][1]
		flame.period = flames[i][2]
		place(flame, "Flame%d" % i, flames[i][0] + (Vector3(1.6, 0, 0) if i == 0 else Vector3.ZERO))

	var photo := JournalNote.new()
	photo.requires = "isle.phase=fire"
	photo.entry_id = "ulysses_photo"
	photo.title = "A photograph in the smoke"
	photo.body = "Rick grabbed something off the corridor wall as we ran: a framed photograph, half-melted. Two young men grinning by the sea. Under one of them, in ink: \"Ulysses\". The face is too blurred by the heat to make out."
	photo.prompt = "Grab the photo off the wall"
	photo.size = Vector3(0.05, 0.4, 0.3)
	place(photo, "Photo", Vector3(-2.2, 1.6, -25))

	var away := LevelExit.new()
	away.who = "julia"
	away.solo = true
	away.level = VENICE
	away.requires = "isle.phase=fire"
	away.prompt = "Jump into the Black Gondolier's boat"
	away.on_used = _escaped
	place(away, "Gondola", Vector3(0, 1, -33.5))


func _escaped(_player: Node3D) -> void:
	GameState.set_flag("isle.phase", "escaped")
	GameState.set_flag("b4.isle_escaped")
	GameState.add_journal("black_vulcano", "Black Vulcano has the keys",
		"We got out of the burning workshop with Peter Dedalus, into the Black Gondolier's boat. Behind us the Isle of Masks was all smoke. Oblivia got away too.\nOut on the lagoon, Dedalus told us the thing he wouldn't tell her: \"I don't have the First Key. I never did. Black Vulcano has the keys. All of them, even the First.\"\nHe's staying in Venice, in hiding. We're going home.")
	Game.current.say("You tumble into the gondola as the roof caves in. Out on the lagoon, Dedalus says it quietly: \"Black Vulcano has the keys. All of them. Even the First.\" Then the Gondolier sets you down at the Metis.", "julia")
