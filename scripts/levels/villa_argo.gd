extends Level
## Villa Argo, book 1 (docs/book1-design.md, steps 1-8): arrival and Nestor,
## footsteps in the tower at night, the cliff box, the parchment cipher, the
## wardrobe, the tower diary and the four-key door. The post office trip is
## the kilmore_cove level. Behind the Door is the argo_underground level.
## Book 2 (docs/book2-design.md, steps 13-17) also happens here: Julia alone
## with Nestor on a storm night, Ulysses's notes, Manfred at the windows, the
## stolen Owl key and the chase to the cliff, and reopening the Door.
## Layout is adaptation (no canon floor plan); rooms and objects follow the
## story reference.
##
## Map (y up, north = -z): courtyard z 10..26 with the gate south; house
## x -12..12, z -10..10 (hall in the middle, library west, stone sitting room
## east); stair hall and tower north of the house (tower room floor y 4.5);
## garden west, fenced at x = -21, with the cliff top and cliff path beyond.

const KILMORE_COVE := "res://scenes/levels/kilmore_cove.tscn"
const UNDERGROUND := "res://scenes/levels/argo_underground.tscn"
const ATTIC := "res://scenes/levels/argo_attic.tscn"
## Book 4: where the beggars stashed what they took: [item id, name, where].
const LOOT := [
	["telescope", "Ulysses's brass telescope", Vector3(-2, 5.4, -27.5)],
	["candlesticks", "the silver candlesticks", Vector3(-10.8, 1.0, -1.5)],
	["jewellery_box", "Mum's jewellery box", Vector3(-8, 0.4, 14)],
]
## The dog's patrol along the hall, one step every DOG_SECONDS.
const DOG_ROUTE := [Vector3(0, 0.5, -8), Vector3(0, 0.5, -1), Vector3(0, 0.5, 6), Vector3(0, 0.5, -1)]
const DOG_SECONDS := 3.0
const KEYS := ["owl_key", "porcupine_key", "elephant_key", "newt_key"]
## Parchment cipher (adaptation; the reference says the real alphabet is
## unknown). The parchment reads CAVE SHIP; the extra pairs are decoys.
const CIPHER := {"#": "C", "@": "A", "%": "V", "&": "E", "$": "S", "*": "H", "!": "I", "?": "P",
	"+": "R", "=": "T", "~": "O", "^": "N", ">": "D", "<": "K"}
const PARCHMENT := "#  @  %  &        $  *  !  ?"
## Book 2: from the house side, the Door opens with the keys "backwards".
const KEYS_BACKWARDS := ["newt_key", "elephant_key", "porcupine_key", "owl_key"]

## Book 2 storm windows: [inside position, yaw, where Manfred stands outside, name].
const WINDOWS := [
	[Vector3(-11.6, 2, -5), 90.0, Vector3(-13.5, 1, -5), "library"],
	[Vector3(-2.6, 2, 9.6), 0.0, Vector3(-2.6, 1, 11.5), "hall, left of the front door"],
	[Vector3(2.6, 2, 9.6), 0.0, Vector3(2.6, 1, 11.5), "hall, right of the front door"],
	[Vector3(11.6, 2, -8.5), 90.0, Vector3(13.5, 1, -8.5), "stone sitting room"],
	[Vector3(-3.6, 2, -14), 90.0, Vector3(-5.5, 1, -14), "west side of the tower stairs"],
	[Vector3(3.6, 2, -14), 90.0, Vector3(5.5, 1, -14), "east side of the tower stairs"],
]
## The order Manfred tries them, one every WINDOW_SECONDS.
const WINDOW_ORDER := [1, 2, 3, 5, 4, 0]
const WINDOW_SECONDS := 7.0
## Manfred's run from the stone sitting room to the cliff edge.
const CHASE := [Vector3(0, 1, 4), Vector3(0, 1, 13), Vector3(-14, 1, 12), Vector3(-20, 1, 0.5), Vector3(-23.2, 1, 0.5)]
const CHASE_SECONDS := 2.2

const WALL := Color(0.62, 0.58, 0.52)
const WOOD := Color(0.42, 0.3, 0.2)
const GROUND := Color(0.45, 0.5, 0.38)

var _parchment_label: Label3D
var _storm_t := 0.0
var _dog_t := 0.0


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.5, 1, 22), "julia": Vector3(1.5, 1, 22)},
		"gate": {"jason": Vector3(-1.5, 1, 23.5), "julia": Vector3(1.5, 1, 23.5)},
		"attic": {"jason": Vector3(-2.6, 1, 6.6), "julia": Vector3(-1.4, 1, 6.6)},
		"door": {"jason": Vector3(10, 1, -6), "julia": Vector3(10, 1, -4), "yaw": PI / 2},
	}
	fall_y = -20.0
	add_environment(Color(0.55, 0.7, 0.85))

	add_box(Vector3(40, 0.5, 59), Vector3(-4, -0.25, -2.5), GROUND)
	_build_courtyard()
	_build_house()
	_build_tower()
	_build_cliff()
	_build_storm()
	_build_intruders()

	GameState.changed.connect(_on_state_changed)
	_on_state_changed("")


func respawn_point(role: String, fell_from: Vector3) -> Vector3:
	if fell_from.x < -23.0:
		return Vector3(-22.5, 1, -0.5 if role == "jason" else 0.8)
	return spawn_point(role, "default")


func _on_state_changed(_key: String) -> void:
	set_night(GameState.get_flag("argo.night", false))
	_parchment_label.visible = GameState.has_item("parchment")


# --- Story --------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_check_footsteps()
	_run_storm(delta)
	_run_intruders(delta)


func _check_footsteps() -> void:
	if not GameState.get_flag("argo.night", false) or GameState.get_flag("argo.footsteps", false):
		return
	var jason := Game.current.get_player(1)
	if jason == null or Game.current.level_for("jason") != self:
		return
	var at := to_local(jason.global_position)
	if absf(at.x) < 4.0 and at.z < -10.5:
		_hear_footsteps()


## Step 2: only Jason hears footsteps in the tower; then morning comes, the
## parents leave and Rick turns up (canon: B1 scenes 2-3).
func _hear_footsteps() -> void:
	GameState.set_flag("argo.footsteps")
	Game.current.say("Footsteps... slow and heavy, somewhere above you in the tower. But there's nobody there.", "jason")
	GameState.add_journal("footsteps", "Footsteps in the night",
		"I heard footsteps in the tower last night, slow and heavy. Julia didn't hear a thing. When I looked, there was nobody there.", "jason")
	await get_tree().create_timer(5.0).timeout
	GameState.set_flag("argo.night", false)
	GameState.set_flag("argo.rick_here")
	Game.current.say("Morning. Mum and Dad catch the train back to London, and a red-haired boy from the village knocks at the door: Rick Banner.")


func _talk_nestor(_player: Node3D) -> void:
	if GameState.get_flag("b2.home", false) and not GameState.get_flag("b3.started", false):
		_breakfast()
		return
	if GameState.get_flag("b4.home", false) and not GameState.get_flag("b5.started", false):
		_start_book5()
		return
	if GameState.get_flag("argo.met_nestor", false):
		return
	GameState.set_flag("argo.met_nestor")
	GameState.add_journal("scarred_door", "The scarred door",
		"In the stone sitting room there's an old wooden door covered in scratches and burn marks, with four keyholes. Nestor says it only leads to a cistern and the keys were lost years ago. The wardrobe stands in front of it again.")
	await get_tree().create_timer(4.0).timeout
	GameState.set_flag("argo.night")
	Game.current.say("Night falls over Villa Argo.")


# --- Courtyard and garden -------------------------------------------------------

func _build_courtyard() -> void:
	# Boundary: south fence with the gate, east and north walls.
	add_box(Vector3(22.5, 1.8, 0.4), Vector3(-12.75, 0.9, 26.5), WALL)
	add_box(Vector3(14.5, 1.8, 0.4), Vector3(8.75, 0.9, 26.5), WALL)
	add_box(Vector3(0.4, 1.8, 59), Vector3(16, 0.9, -2.5), WALL)
	add_box(Vector3(40, 1.8, 0.4), Vector3(-4, 0.9, -32), WALL)
	add_label("Kilmore Cove", Vector3(0, 2.6, 26.5), 180)

	var exit := LevelExit.new()
	exit.level = KILMORE_COVE
	exit.requires = "item:receipt"
	exit.prompt = "Cycle down to Kilmore Cove"
	place(exit, "GateToKilmoreCove", Vector3(0, 1, 25))

	# Statue of a woman mending a fishing net (canon, ref §5).
	var statue := add_box(Vector3(0.8, 2.2, 0.8), Vector3(-6, 1.1, 16), Color(0.75, 0.75, 0.72))
	statue.name = "Statue"
	add_label("statue: a woman mending a net", Vector3(-6, 2.6, 16.6), 0).font_size = 28

	add_box(Vector3(5, 3, 5), Vector3(11, 1.5, 20), Color(0.55, 0.45, 0.35))
	add_label("Nestor's cottage", Vector3(11, 3.4, 17.4), 0)

	var nestor := Npc.new()
	nestor.npc_name = "Nestor"
	nestor.color = Color(0.45, 0.4, 0.3)
	nestor.lines = [
		["", "Nestor, the gardener. Your mother asked about that old door in the stone sitting room. It leads to a cistern, nothing more, and the keys were lost years ago. We've put the wardrobe back in front of it."],
		["argo.night", "It's late. Off to bed, you two. Your rooms are up the stairs."],
		["argo.rick_here", "Your parents caught the early train to London. They'll be a few days. I'll be in the garden. And stay off that cliff path."],
		["argo.cipher_solved", "Hmph. Reading old papers, are we? Mind the dust."],
		["argo_door.open", "Hmph."],
		["b2.split", "Julia? Soaked through, and alone? Where are the boys?... Never mind that now. There's a storm coming in off the sea. Stay inside, away from the windows."],
		["journal:ballad_notes", "That's Ulysses's hand. He and Penelope used to sit in the library on stormy nights, reading old songs to each other. She's gone now. Long gone."],
		["storm.phase=windows", "Shut the windows, girl! I'll hold the front door!"],
		["storm.phase=chase", "After him! The brute's heading for the cliff!"],
		["storm.phase=fallen", "Over the cliff? His sort always crawl out of the sea. Have you got the key back?"],
		["b2.split & argo_door.open", "You opened it from this side... Then we wait for the boys."],
		["b2.home", "Back, are you? All three of you, sunburnt in a storm. I won't ask. Sit down, there's breakfast."],
		["b3.started", "Off to the village, are you? Mind the cliff road."],
		["b3.dedalus", "Dedalus... Yes, I knew him. I knew all of them, once. That was a long time ago."],
		["b4.split", "Mmmf! Mmmmf!"],
		["b4.nestor_free", "A man, a girl and a mangy dog, out of that door! They tied me up and went through the house like locusts: the tower, the library, the garden. Mind the dog. It barks at anything that moves."],
		["b4.argo_safe", "Gone, the lot of them. Well done, boy. Hmph. Your sister had better be all right."],
		["b4.home", "Black Vulcano? Hmph. Drove the trains, years ago, when there were trains. Now get some sleep: it's school tomorrow, and your parents have written to the headteacher."],
		["b5.started", "School. Go. And don't bring anything home I'll have to explain."],
		["b5.oblivia_ahead", "Through the Door, the pair of them. Hmph. Be careful where it takes you. And come back."],
	]
	nestor.stations = [["", Vector3(4, 1, 17)], ["b2.split", Vector3(1.5, 1, 7)], ["b4.split", Vector3(10, 1, -8.6)], ["b4.nestor_free", Vector3(8, 1, -2)]]
	nestor.on_used = _talk_nestor
	place(nestor, "Nestor", Vector3(4, 1, 17))

	# Garden fence along the cliff top, with a gate to the cliff path.
	add_box(Vector3(0.4, 1.8, 30.5), Vector3(-21, 0.9, -16.25), WALL)
	add_box(Vector3(0.4, 1.8, 25.5), Vector3(-21, 0.9, 13.75), WALL)
	var gate := Door.new()
	gate.size = Vector3(2, 1.8, 0.2)
	gate.free = true
	gate.open_flag = "argo.cliff_gate_open"
	gate.requires = "argo.rick_here"
	gate.prompt = "Open the garden gate"
	gate.color = Color(0.2, 0.2, 0.22)
	place(gate, "CliffGate", Vector3(-21, 0, 0)).rotation_degrees.y = 90
	add_label("cliff path", Vector3(-20.7, 2.2, 0), 90)


# --- The house ------------------------------------------------------------------

func _build_house() -> void:
	var w := WALL
	# Outer walls: front door gap in the south wall, tower gap in the north.
	add_box(Vector3(10.5, 4, 0.5), Vector3(-6.75, 2, 10), w)
	add_box(Vector3(10.5, 4, 0.5), Vector3(6.75, 2, 10), w)
	add_box(Vector3(10.5, 4, 0.5), Vector3(-6.75, 2, -10), w)
	add_box(Vector3(10.5, 4, 0.5), Vector3(6.75, 2, -10), w)
	add_box(Vector3(0.5, 4, 20), Vector3(-12, 2, 0), w)
	# East wall with the scarred door's opening (z -5.8..-4.2).
	add_box(Vector3(0.5, 4, 4.2), Vector3(12, 2, -7.9), w)
	add_box(Vector3(0.5, 4, 14.2), Vector3(12, 2, 2.9), w)
	add_box(Vector3(0.5, 1.4, 1.6), Vector3(12, 3.3, -5), w)
	# Hall walls with doorways into the library (west) and stone sitting room (east).
	for x in [-4.0, 4.0]:
		add_box(Vector3(0.5, 4, 7), Vector3(x, 2, -6.5), w)
		add_box(Vector3(0.5, 4, 11), Vector3(x, 2, 4.5), w)
		add_box(Vector3(8, 4, 0.5), Vector3(x * 2.0, 2, 0), w)
	add_label("Library", Vector3(-3.7, 3.3, -2), 90)
	add_label("Stone sitting room", Vector3(3.7, 3.3, -2), -90)

	# Main hall: Venetian chandelier and the Indian and African figures (canon).
	var chandelier := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	chandelier.mesh = sphere
	chandelier.material_override = Vis.material(Color(1.0, 0.9, 0.6))
	chandelier.position = Vector3(0, 3.4, 4)
	add_child(chandelier)
	for z in [2.0, 4.0, 6.0]:
		add_box(Vector3(0.4, 1.2, 0.4), Vector3(-3.4, 0.6, z), Color(0.35, 0.25, 0.15))
	add_label("Indian and African figures", Vector3(-3.6, 1.8, 4), 90).font_size = 28

	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.present = "argo.rick_here & !b2.away & !b4.away"
	rick.lines = [
		["argo.rick_here", "I'm Rick, Rick Banner. Everybody in Kilmore Cove talks about this house. They say Ulysses Moore used to go down the cliff path behind the garden."],
		["item:parchment", "Those symbols... There's a huge old dictionary in your library. Julia, you're good at this sort of thing."],
		["argo.cipher_solved", "Wood that hides a door? That wardrobe in the stone sitting room is enormous. Jason, think you can shift it?"],
		["argo.wardrobe_moved", "Four keyholes and no keys. Ulysses must have left something. What about the tower, with all those ship models?"],
		["item:receipt", "A post office receipt! The post office is down in Kilmore Cove. The gate's at the end of the drive."],
		["item:owl_key", "Four keys, four locks. Let's try them!"],
		["argo_door.fails", "Owl, Porcupine, Elephant, Newt... Hang on. Look at the first letters!"],
		["argo_door.open", "It actually opened! Where do you think it goes?"],
		["b3.escaped", "Venice... We need a plan. Let's meet in the attic: the stairs are by the front door."],
	]
	place(rick, "Rick", Vector3(2.2, 1, 5))

	_build_library()
	_build_stone_room()


## Step 4: Jason sees the parchment's symbols, Julia sees the Dictionary's table.
func _build_library() -> void:
	for z in [-9.4, -6.4]:
		add_box(Vector3(2.5, 3, 0.6), Vector3(-8, 1.5, z), WOOD)
	add_box(Vector3(2, 0.9, 1.2), Vector3(-8, 0.45, -3.5), WOOD)

	_parchment_label = add_label(PARCHMENT, Vector3(-8, 1.6, -3.5))
	_parchment_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_parchment_label.font_size = 64
	Vis.make_private(_parchment_label, "jason")

	var table := "Dictionary of Forgotten Languages\n\n"
	var signs := CIPHER.keys()
	signs.sort()
	for s in signs:
		table += "%s  =  %s\n" % [s, CIPHER[s]]
	var dict_label := add_label(table, Vector3(-11.6, 2.2, -6), 90)
	dict_label.font_size = 30
	Vis.make_private(dict_label, "julia")

	var dictionary := CodeEntry.new()
	dictionary.who = "julia"
	dictionary.requires = "item:parchment"
	dictionary.answer = "CAVE SHIP"
	dictionary.solved_flag = "argo.cipher_solved"
	dictionary.prompt = "Decode the parchment"
	dictionary.question = "The parchment says (use the Dictionary):"
	dictionary.wrong_text = "The words don't fit together. Check the symbols again."
	dictionary.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("parchment", "The parchment, decoded",
			"With the Dictionary of Forgotten Languages, the symbols become words: CAVE SHIP.\nIn the margin, smaller signs: \"the wood that hides the door\".\nA dark cave, a ship... and a door behind wood.")
	place(dictionary, "Dictionary", Vector3(-10.6, 1.0, -6))


## Steps 5 and 8: the wardrobe and the four-key door.
func _build_stone_room() -> void:
	add_box(Vector3(3, 0.8, 1.5), Vector3(7, 0.4, -2), WOOD)

	var wardrobe := Pushable.new()
	wardrobe.size = Vector3(1, 2.6, 2.2)
	wardrobe.offset = Vector3(0, 0, 2.6)
	wardrobe.moved_flag = "argo.wardrobe_moved"
	wardrobe.requires = "argo.cipher_solved"
	wardrobe.prompt = "Push the wardrobe"
	place(wardrobe, "Wardrobe", Vector3(11.2, 1.3, -5))

	var door := Door.new()
	door.size = Vector3(1.6, 2.6, 0.3)
	door.open_flag = "argo_door.open"
	door.color = Color(0.28, 0.18, 0.1)
	place(door, "ArgoDoor", Vector3(12, 0, -5)).rotation_degrees.y = 90

	for i in KEYS.size():
		var lock := KeyLock.new()
		lock.door = "argo_door"
		lock.index = i
		lock.solution = KEYS
		lock.alt_solution = KEYS_BACKWARDS
		lock.alt_when = "b2.split"
		lock.requires = "argo.wardrobe_moved"
		place(lock, "Lock%d" % i, Vector3(11.75, 1.3, -5.6 + 0.4 * i))

	# Behind the Door: stone steps down to the argo_underground level.
	var dark := Color(0.25, 0.25, 0.28)
	add_box(Vector3(4, 0.5, 4), Vector3(14.25, -0.25, -5), dark)
	add_box(Vector3(0.5, 4, 4), Vector3(16.25, 2, -5), dark)
	add_box(Vector3(4, 4, 0.5), Vector3(14.25, 2, -7.25), dark)
	add_box(Vector3(4, 4, 0.5), Vector3(14.25, 2, -2.75), dark)
	var steps := LevelExit.new()
	steps.level = UNDERGROUND
	steps.requires = "argo_door.open"
	steps.prompt = "Go down the stone steps"
	steps.gather_radius = 6.0
	place(steps, "StepsDown", Vector3(14.5, 1, -5))
	var to_beach := LevelExit.new()
	to_beach.who = "jason"
	to_beach.solo = true
	to_beach.level = UNDERGROUND
	to_beach.entry = "beach"
	to_beach.requires = "b4.julia_home & !b4.home"
	to_beach.prompt = "Run down to the beach"
	place(to_beach, "RunToBeach", Vector3(13.8, 1, -3.6))


# --- Tower ----------------------------------------------------------------------

## Steps 2 and 6: stairs with portraits, the mirror door, the ship model on the
## diary with the receipt.
func _build_tower() -> void:
	for x in [-4.0, 4.0]:
		add_box(Vector3(0.5, 8.5, 20), Vector3(x, 4.25, -20), WALL)
	add_box(Vector3(8.5, 8.5, 0.5), Vector3(0, 4.25, -30), WALL)
	add_ramp(3, 8, 4.5, Vector3(-2, 0, -11), WOOD)
	add_box(Vector3(7.5, 0.5, 3), Vector3(0, 4.25, -20.5), WOOD)
	add_box(Vector3(7.5, 4.5, 8), Vector3(0, 2.25, -26), WALL)

	for i in 4:
		add_box(Vector3(0.1, 0.9, 0.7), Vector3(-3.7, 2.2 + i * 1.1, -12.5 - i * 2), Color(0.5, 0.35, 0.25))
	add_label("portraits of the former owners", Vector3(-3.6, 1.6, -14), 90).font_size = 28

	# Tower wall with the mirror door.
	add_box(Vector3(3, 4, 0.5), Vector3(-2.5, 6.5, -22), WALL)
	add_box(Vector3(3, 4, 0.5), Vector3(2.5, 6.5, -22), WALL)
	add_box(Vector3(2, 1, 0.5), Vector3(0, 8, -22), WALL)
	var mirror := Door.new()
	mirror.size = Vector3(2, 3, 0.2)
	mirror.free = true
	mirror.open_flag = "argo.mirror_door_open"
	mirror.prompt = "Open the mirror door"
	mirror.color = Color(0.75, 0.82, 0.88)
	place(mirror, "MirrorDoor", Vector3(0, 4.5, -22))

	# Tower room: ship models, and a tall bookcase Jason can climb.
	for x in [-3.0, -1.5]:
		add_box(Vector3(0.9, 0.9, 0.9), Vector3(x, 4.95, -29), WOOD)
		add_box(Vector3(0.7, 0.35, 0.25), Vector3(x, 5.6, -29), Color(0.8, 0.8, 0.75))
	add_label("ship models", Vector3(-2.2, 6.3, -28.6), 0).font_size = 28
	add_climb_wall(Vector3(2.4, 3, 1.2), Vector3(2.5, 6, -29.3))

	var ship := Pickup.new()
	ship.who = "jason"
	ship.requires = "argo.wardrobe_moved"
	ship.item_id = "receipt"
	ship.item_name = "post office receipt"
	ship.prompt = "Lift the ship model"
	ship.box_size = Vector3(0.9, 0.45, 0.3)
	ship.color = Color(0.85, 0.85, 0.8)
	ship.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("tower_diary", "Ulysses Moore's diary",
			"Under the ship model on the tower bookcase lay one of Ulysses Moore's diaries. Tucked inside: a receipt from the Kilmore Cove post office, for a parcel nobody ever collected.")
		GameState.add_journal("handwriting", "The diary's handwriting",
			"Tall, slanted letters, a looping capital U, and every t crossed twice. I'd know this handwriting anywhere now.", "julia")
	place(ship, "ShipModel", Vector3(2.5, 7.8, -29.4))


# --- Cliff ----------------------------------------------------------------------

## Step 3: ledges down the cliff. Cracked ones (no collision) are marked only
## on Julia's screen. The box and parchment are in the crevice at the bottom;
## Jason climbs the rock pillar and crosses back to the cliff top.
func _build_cliff() -> void:
	add_box(Vector3(1, 40, 60), Vector3(-24.5, -20, -2.5), Color(0.5, 0.48, 0.42))
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	sea.mesh = plane
	sea.material_override = Vis.material(Color(0.15, 0.35, 0.55))
	sea.position = Vector3(-110, -30, 0)
	add_child(sea)

	var rock := Color(0.55, 0.5, 0.42)
	# Real ledges, top heights -2, -4, -6, -8, then the crevice at -10.
	var real := [Vector3(-26.5, -2, 1), Vector3(-26.5, -4, 4.5), Vector3(-30, -6, 4.5), Vector3(-30, -8, 8)]
	var cracked := [Vector3(-30, -4, 1), Vector3(-26.5, -6, 8), Vector3(-33.5, -8, 4.5)]
	for top in real:
		add_box(Vector3(3, 0.5, 3), top - Vector3(0, 0.25, 0), rock)
	for top in cracked:
		_add_cracked_ledge(top, rock)

	add_box(Vector3(3, 0.5, 3), Vector3(-30, -10.25, 11.5), rock)
	add_box(Vector3(0.5, 2, 3), Vector3(-31.75, -9, 11.5), rock)
	add_climb_wall(Vector3(3, 10, 1), Vector3(-30, -5, 13.5))
	add_box(Vector3(4.5, 0.5, 1.6), Vector3(-26.25, -0.25, 13.5), rock)

	var clay := Pickup.new()
	clay.who = "jason"
	clay.item_id = "clay"
	clay.item_name = "box of glowing clay"
	clay.prompt = "Open the box"
	clay.box_size = Vector3(0.6, 0.3, 0.4)
	clay.color = Color(0.95, 0.9, 0.55)
	place(clay, "ClayBox", Vector3(-30.6, -9.6, 10.8))

	var parchment := Pickup.new()
	parchment.who = "jason"
	parchment.item_id = "parchment"
	parchment.item_name = "coded parchment"
	parchment.prompt = "Take the parchment"
	parchment.box_size = Vector3(0.5, 0.05, 0.4)
	parchment.color = Color(0.92, 0.88, 0.75)
	parchment.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("cliff_box", "The box in the cliff",
			"Wedged in a crevice halfway down the cliff: a box of clay balls that glow softly in the dark, and a parchment covered in strange symbols.")
	place(parchment, "Parchment", Vector3(-29.3, -9.9, 11.6))


func _add_cracked_ledge(top: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3, 0.5, 3)
	mesh.mesh = box
	mesh.material_override = Vis.material(color)
	mesh.position = top - Vector3(0, 0.25, 0)
	add_child(mesh)
	for angle in [45.0, -45.0]:
		var crack := MeshInstance3D.new()
		var line := BoxMesh.new()
		line.size = Vector3(3.6, 0.05, 0.25)
		crack.mesh = line
		crack.material_override = Vis.material(Color(0.8, 0.1, 0.1))
		crack.position = top + Vector3(0, 0.03, 0)
		crack.rotation_degrees.y = angle
		Vis.make_private(crack, "julia")
		add_child(crack)


# --- Book 5: the new goal -----------------------------------------------------------

func _host_setup() -> void:
	if GameState.get_flag("b5.train_awake", false) and not GameState.get_flag("b5.oblivia_ahead", false):
		_oblivia_ahead()


## Book 5 step 12 (canon ✅: Oblivia and Manfred reach the Garden through the
## Argo Door too). How they got in is adaptation.
func _oblivia_ahead() -> void:
	GameState.set_flag("b5.oblivia_ahead")
	GameState.add_journal("oblivia_ahead", "Oblivia went first",
		"Back at Villa Argo, Nestor was waiting at the gate, furious. While we were at the station, Oblivia Newton and Manfred walked into the house as if they owned it and went straight through the Door in the stone room. Nestor couldn't stop them.\nThey're ahead of us. Down to the Metis, quick.")
	Game.current.say("Nestor is at the gate, grim. \"That woman. And her driver. Straight past me and through the Door, not an hour ago. Go, if you're going.\"")


## Book 5 step 1 (canon ✅): find Black Vulcano before Oblivia does.
func _start_book5() -> void:
	GameState.set_flag("b5.started")
	GameState.add_journal("b5_goal", "Find Black Vulcano",
		"Dedalus says Black Vulcano has all the keys, even the First. Nestor says he drove the trains in Kilmore Cove, years ago, when there were trains. Oblivia and Manfred will be looking for him too.\nBut first: school. Our parents have written to the headteacher.")
	Game.current.say("Book 5: The Stone Guardians. Tomorrow is school, in Kilmore Cove, and the headteacher has been told to keep an eye on the Covenant twins.")


# --- Book 3: breakfast -------------------------------------------------------------

## Book 3 steps 1-2 (canon: the reunion breakfast, comparing stories; Jason can
## no longer read Egyptian, HIGH). From here on both twins see every entry.
func _breakfast() -> void:
	GameState.set_flag("b3.started")
	GameState.share_journal()
	GameState.add_journal("breakfast", "Breakfast at Villa Argo",
		"Nestor's breakfast, and we tell each other everything: the storm, Manfred and the Owl key, Punt, Maruk, the map-seller, the room that isn't there, and Oblivia Newton walking off with the map. From now on we keep one journal between us.")
	GameState.add_journal("lost_in_translation", "Lost in translation",
		"Jason looks at the Egyptian signs he copied from the drawing of the Metis. In Punt he could understand every word anyone said. Now the signs are just little pictures. Nobody can explain it.")
	GameState.add_journal("map_memory", "What I remember of the map",
		"I only held the map for about ten seconds, but I remember three little drawings on it:\n- right on the coast at the top of the map, something tall and thin with lines coming out of the top, like rays;\n- in the west of the village, a small sitting animal with pointed ears;\n- in the east, a big house with a lion's head drawn on its door.\nJulia should check them against something.", "jason")
	Game.current.say("Book 3: The House of Mirrors. Over breakfast, the three of you compare everything. Rick: \"Something about Kilmore Cove doesn't add up.\"")


# --- Book 4: intruders (Jason's half) -----------------------------------------------

## Steps 4-6 (canon: two Venetians come through the open Door, tie up Nestor and
## loot the house; Jason goes back alone to deal with them, LOW-MEDIUM). The
## dog's patrol, the stashed loot and the mask are adaptation.
func _build_intruders() -> void:
	var stairs := LevelExit.new()
	stairs.level = ATTIC
	stairs.requires = "b3.escaped"
	stairs.solo_when = "b4.split"
	stairs.prompt = "Climb the attic stairs"
	place(stairs, "AtticStairs", Vector3(-2.8, 1, 8.4))
	add_label("attic stairs", Vector3(-3.6, 2.6, 8.4), 90).font_size = 28

	var untie := Switch.new()
	untie.who = "jason"
	untie.flag = "b4.nestor_free"
	untie.requires = "b4.split"
	untie.prompt = "Untie Nestor"
	place(untie, "UntieNestor", Vector3(10, 1, -7.6))

	for item in LOOT:
		var loot := Pickup.new()
		loot.who = "jason"
		loot.requires = "b4.nestor_free"
		loot.appears = "b4.split"
		loot.item_id = item[0]
		loot.item_name = item[1]
		loot.prompt = "Take back %s" % item[1]
		loot.box_size = Vector3(0.5, 0.4, 0.4)
		loot.color = Color(0.8, 0.75, 0.4)
		loot.on_used = func(_p: Node3D) -> void: _check_argo_safe()
		place(loot, "Loot_" + item[0], item[2])

	var dog := Npc.new()
	dog.npc_name = "Diogo (a dog)"
	dog.color = Color(0.5, 0.4, 0.3)
	dog.who = "nobody"
	dog.present = "b4.split & !b4.intruders_gone"
	dog.walk_speed = 3.0
	var stations := [["", DOG_ROUTE[0]]]
	for i in DOG_ROUTE.size():
		stations.append(["b4.dog=%d" % i, DOG_ROUTE[i]])
	dog.stations = stations
	place(dog, "Dog", DOG_ROUTE[0])

	var npcs := [["DonDiego", "Don Diego Valente", Vector3(-1.2, 1, 9)], ["Dieguita", "Dieguita", Vector3(1.2, 1, 9)]]
	for n in npcs:
		var npc := Npc.new()
		npc.npc_name = n[1]
		npc.color = Color(0.45, 0.35, 0.25)
		npc.who = "jason"
		npc.present = "b4.split & !b4.intruders_gone"
		npc.lines = [["", "Ha! A boy! Go away, boy, before the dog eats you."]]
		npc.on_used = _scare_intruders
		place(npc, n[0], n[2])

	var masks := JournalNote.new()
	masks.who = "jason"
	masks.entry_who = "jason"
	masks.requires = "b4.split"
	masks.entry_id = "cenere_mask"
	masks.title = "Masks of the Venetian secret guard"
	masks.body = "In Ulysses's library, a book of old Venetian masks. The secret guard wore plain white masks... except their captains. One of them, Count Cenere, \"Count Ash\", wore one all of his own: ash-grey, with a single silver tear under the left eye.\nJulia needs to know this."
	masks.prompt = "Leaf through a book of Venetian masks"
	masks.size = Vector3(0.5, 0.1, 0.35)
	place(masks, "MaskBook", Vector3(-8, 1.2, -5.8))


## Step 5: the mask scares them off (Julia's tip, canon-ish: they fear the guard).
func _scare_intruders(_player: Node3D) -> void:
	if not GameState.has_item("guard_mask") or GameState.get_flag("b4.intruders_gone", false):
		return
	GameState.set_flag("b4.intruders_gone")
	Game.current.say("Jason pulls on the white mask. Don Diego goes pale: \"La guardia!\" He, Dieguita and the dog bolt for the Door and are gone.", "jason")
	Game.current.say("Two ragged figures and a dog come tumbling out of the Door passage, look over their shoulders in terror, and run off into the alleys.", "julia")
	_check_argo_safe()


func _check_argo_safe() -> void:
	if GameState.get_flag("b4.argo_safe", false):
		return
	var all := LOOT.all(func(i: Array) -> bool: return GameState.has_item(i[0]))
	if all and GameState.get_flag("b4.intruders_gone", false) and GameState.get_flag("b4.nestor_free", false):
		GameState.set_flag("b4.argo_safe")
		GameState.add_journal("argo_safe", "The house is ours again",
			"Nestor's free, the telescope, the candlesticks and Mum's jewellery box are back, and Don Diego, Dieguita and their dog ran back through the Door the moment they saw the guard's mask.", "jason")


## Host: the dog's patrol and what it sees.
func _run_intruders(delta: float) -> void:
	if not GameState.get_flag("b4.split", false) or GameState.get_flag("b4.intruders_gone", false) \
			or Game.current.level_for("jason") != self:
		return
	_dog_t += delta
	if _dog_t >= DOG_SECONDS:
		_dog_t = 0.0
		GameState.set_flag("b4.dog", (int(GameState.get_flag("b4.dog", 0)) + 1) % DOG_ROUTE.size())
	var dog: Node3D = get_node("Dog")
	var jason := Game.current.get_player(1)
	if jason and sees(dog, jason, 5.0):
		jason.teleport.rpc(to_global(Vector3(9, 1, -5)), PI / 2)
		Game.current.say("Diogo barks his head off! Don Diego comes running, and Jason has to dive back into the stone sitting room.", "jason")


# --- Book 2: the storm (Julia's half) ----------------------------------------------

## Step 14: Ulysses's notes (only Julia is home to read them; she passes them on
## to Jason). Step 15: windows to shut, and Manfred. Step 16: the Owl key.
func _build_storm() -> void:
	var ballad := JournalNote.new()
	ballad.who = "julia"
	ballad.entry_who = "julia"
	ballad.requires = "b2.split"
	ballad.entry_id = "ballad_notes"
	ballad.title = "Ulysses's copy of the Ballad"
	ballad.body = "The Ballad of Two Lovers, in Ulysses's hand, with notes in the margin:\n\"She looks to the morning, he looks to the night;\nbetween them the shadows, between them the light.\nTurn the bright waters three times on the way,\nand their eyes will meet at the close of the day.\"\n\nMargin: \"The light from the roof falls on her face first. Bright waters = the mirrors. Three turns, no more, and the light must end in his eyes. Where their eyes meet, the room that isn't there will open.\"\n\nJason needs to hear this."
	ballad.prompt = "Read Ulysses's notes"
	ballad.size = Vector3(0.5, 0.05, 0.4)
	place(ballad, "BalladNotes", Vector3(-8.6, 0.95, -3.5))

	var sound := JournalNote.new()
	sound.who = "julia"
	sound.entry_who = "julia"
	sound.requires = "b2.split"
	sound.entry_id = "sound_key_notes"
	sound.title = "The sound key"
	sound.body = "A loose page in Ulysses's hand:\n\"The altar answers to bronze, not to iron. Strike the plates as the lovers met: MOON, SUN, STAR, SUN.\"\n\nJason needs to hear this too."
	sound.prompt = "Read the loose page"
	sound.size = Vector3(0.4, 0.05, 0.3)
	place(sound, "SoundKeyNotes", Vector3(-7.4, 0.95, -3.5))

	for i in WINDOWS.size():
		var w := Shutter.new()
		w.who = "julia"
		w.requires = "storm.phase=windows"
		w.closed_flag = "storm.window%d" % i
		place(w, "Window%d" % i, WINDOWS[i][0]).rotation_degrees.y = WINDOWS[i][1]

	var manfred := Npc.new()
	manfred.npc_name = "Manfred"
	manfred.color = Color(0.25, 0.25, 0.3)
	manfred.who = "nobody"
	manfred.present = "storm.manfred"
	manfred.walk_speed = 7.0
	var stations := [["", WINDOWS[WINDOW_ORDER[0]][2]]]
	for k in WINDOW_ORDER.size():
		stations.append(["storm.phase=windows & storm.step=%d" % k, WINDOWS[WINDOW_ORDER[k]][2]])
	stations.append(["storm.phase=breakin", Vector3(9.5, 1, -5)])
	for k in CHASE.size():
		stations.append(["storm.phase=chase & storm.chase=%d" % k, CHASE[k]])
	stations.append(["storm.phase=edge", CHASE[-1]])
	manfred.stations = stations
	place(manfred, "Manfred", WINDOWS[WINDOW_ORDER[0]][2])

	var key := Pickup.new()
	key.who = "julia"
	key.item_id = "owl_key"
	key.item_name = "Owl key"
	key.appears = "storm.phase=fallen"
	key.prompt = "Pick up the Owl key"
	place(key, "DroppedOwlKey", Vector3(-22.4, 1, 1.8))


## Host: drives the storm while Julia is in the house. Phases (flag
## storm.phase): "" -> arriving -> windows -> breakin -> chase -> edge -> fallen.
func _run_storm(delta: float) -> void:
	if not GameState.get_flag("b2.split", false) or Game.current.level_for("julia") != self:
		return
	_storm_t += delta
	match str(GameState.get_flag("storm.phase", "")):
		"":
			# Pacing: the storm waits for Jason to reach the map shop in Punt.
			if GameState.has_journal("ballad_notes") and GameState.has_journal("sound_key_notes") \
					and GameState.get_flag("punt.map_shop", false):
				_storm_t = 0.0
				GameState.set_flag("storm.phase", "arriving")
				Game.current.say("Through the rain, headlights sweep across the garden. A huge man climbs out of a car and starts circling the house.", "julia")
		"arriving":
			if _storm_t > 4.0:
				_start_windows()
		"windows":
			if _storm_t >= WINDOW_SECONDS:
				_storm_t = 0.0
				_manfred_tries_window()
		"breakin":
			if _storm_t > 3.0:
				_steal_key()
		"chase":
			if _storm_t >= CHASE_SECONDS:
				_storm_t = 0.0
				var k: int = GameState.get_flag("storm.chase", 0)
				if k + 1 < CHASE.size():
					GameState.set_flag("storm.chase", k + 1)
				else:
					GameState.set_flag("storm.phase", "edge")
		"edge":
			var julia := _julia()
			if julia and to_local(julia.global_position).distance_to(CHASE[-1]) < 6.0:
				_manfred_falls()


func _julia() -> Node3D:
	for p in Game.current.get_players():
		if p.role == "julia":
			return p
	return null


func _start_windows() -> void:
	_storm_t = 0.0
	for i in WINDOWS.size():
		GameState.set_flag("storm.window%d" % i, false)
	GameState.set_flag("storm.step", 0)
	GameState.set_flag("storm.manfred")
	GameState.set_flag("storm.phase", "windows")
	Game.current.say("It's Manfred! Shut the windows before he gets to them! He's heading for the %s." % WINDOWS[WINDOW_ORDER[0]][3], "julia")


## Canon (MEDIUM): Julia shuts doors and windows against Manfred. Adaptation:
## he tries them in a fixed order; one left open and he's in, and Nestor drives
## him out but the wind blows every window open again.
func _manfred_tries_window() -> void:
	var step: int = GameState.get_flag("storm.step", 0)
	var w: int = WINDOW_ORDER[step]
	if not GameState.get_flag("storm.window%d" % w, false):
		for i in WINDOWS.size():
			GameState.set_flag("storm.window%d" % i, false)
		GameState.set_flag("storm.step", 0)
		Game.current.say("Manfred shoves the %s window open and climbs halfway in! Nestor drives him back out with a rake, but the wind bangs every window open again. He's going round again, starting at the %s." % [WINDOWS[w][3], WINDOWS[WINDOW_ORDER[0]][3]], "julia")
		return
	if step + 1 < WINDOW_ORDER.size():
		GameState.set_flag("storm.step", step + 1)
		Game.current.say("The %s window holds. Manfred heads for the %s." % [WINDOWS[w][3], WINDOWS[WINDOW_ORDER[step + 1]][3]], "julia")
	else:
		_storm_t = 0.0
		GameState.set_flag("storm.phase", "breakin")
		Game.current.say("Every window holds... then glass shatters at the back of the house. Manfred is inside!", "julia")


## Canon (MEDIUM): Manfred steals a key. Adaptation: the Owl key, from the Door.
func _steal_key() -> void:
	_storm_t = 0.0
	for i in KEYS.size():
		if GameState.get_flag("argo_door.slot%d" % i, "") == "owl_key":
			GameState.set_flag("argo_door.slot%d" % i, "")
	GameState.take_item("owl_key")
	GameState.set_flag("storm.chase", 0)
	GameState.set_flag("storm.phase", "chase")
	Game.current.say("Manfred wrenches the Owl key out of the Door and runs for the garden!", "julia")


## Canon (MEDIUM): he falls off the cliff and survives; Julia gets the key back.
func _manfred_falls() -> void:
	GameState.set_flag("storm.manfred", false)
	GameState.set_flag("storm.phase", "fallen")
	Game.current.say("Cornered at the edge, Manfred slips on the wet rocks and tumbles over the cliff. A moment later you hear a splash and a lot of cursing. He'll live. The Owl key lies on the rocks.", "julia")
