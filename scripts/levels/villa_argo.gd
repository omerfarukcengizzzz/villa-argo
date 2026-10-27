extends Level
## Villa Argo, book 1 (docs/book1-design.md, steps 1-8): arrival and Nestor,
## footsteps in the tower at night, the cliff box, the parchment cipher, the
## wardrobe, the tower diary and the four-key door. The post office trip is
## the kilmore_cove level. Behind the Door is Pass B (not built yet).
## Layout is adaptation (no canon floor plan); rooms and objects follow the
## story reference.
##
## Map (y up, north = -z): courtyard z 10..26 with the gate south; house
## x -12..12, z -10..10 (hall in the middle, library west, stone sitting room
## east); stair hall and tower north of the house (tower room floor y 4.5);
## garden west, fenced at x = -21, with the cliff top and cliff path beyond.

const KILMORE_COVE := "res://scenes/levels/kilmore_cove.tscn"
const KEYS := ["owl_key", "porcupine_key", "elephant_key", "newt_key"]
## Parchment cipher (adaptation; the reference says the real alphabet is
## unknown). The parchment reads CAVE SHIP; the extra pairs are decoys.
const CIPHER := {"#": "C", "@": "A", "%": "V", "&": "E", "$": "S", "*": "H", "!": "I", "?": "P",
	"+": "R", "=": "T", "~": "O", "^": "N", ">": "D", "<": "K"}
const PARCHMENT := "#  @  %  &        $  *  !  ?"

const WALL := Color(0.62, 0.58, 0.52)
const WOOD := Color(0.42, 0.3, 0.2)
const GROUND := Color(0.45, 0.5, 0.38)

var _parchment_label: Label3D


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.5, 1, 22), "julia": Vector3(1.5, 1, 22)},
		"gate": {"jason": Vector3(-1.5, 1, 23.5), "julia": Vector3(1.5, 1, 23.5)},
	}
	fall_y = -20.0
	add_environment(Color(0.55, 0.7, 0.85))

	add_box(Vector3(40, 0.5, 59), Vector3(-4, -0.25, -2.5), GROUND)
	_build_courtyard()
	_build_house()
	_build_tower()
	_build_cliff()

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

func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server() or not GameState.get_flag("argo.night", false) or GameState.get_flag("argo.footsteps", false):
		return
	var jason := Game.current.get_player(1)
	if jason and absf(jason.global_position.x) < 4.0 and jason.global_position.z < -10.5:
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
	]
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
	rick.present = "argo.rick_here"
	rick.lines = [
		["argo.rick_here", "I'm Rick, Rick Banner. Everybody in Kilmore Cove talks about this house. They say Ulysses Moore used to go down the cliff path behind the garden."],
		["item:parchment", "Those symbols... There's a huge old dictionary in your library. Julia, you're good at this sort of thing."],
		["argo.cipher_solved", "Wood that hides a door? That wardrobe in the stone sitting room is enormous. Jason, think you can shift it?"],
		["argo.wardrobe_moved", "Four keyholes and no keys. Ulysses must have left something. What about the tower, with all those ship models?"],
		["item:receipt", "A post office receipt! The post office is down in Kilmore Cove. The gate's at the end of the drive."],
		["item:owl_key", "Four keys, four locks. Let's try them!"],
		["argo_door.fails", "Owl, Porcupine, Elephant, Newt... Hang on. Look at the first letters!"],
		["argo_door.open", "It actually opened! Where do you think it goes?"],
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
		lock.requires = "argo.wardrobe_moved"
		place(lock, "Lock%d" % i, Vector3(11.75, 1.3, -5.6 + 0.4 * i))

	# Behind the Door: Pass B (round room, dark stair, floor stones, the Metis).
	add_box(Vector3(4, 0.5, 4), Vector3(14.25, -0.25, -5), Color(0.3, 0.3, 0.32))
	add_box(Vector3(0.5, 4, 4), Vector3(16.25, 2, -5), w_dark())
	add_box(Vector3(4, 4, 0.5), Vector3(14.25, 2, -7.25), w_dark())
	add_box(Vector3(4, 4, 0.5), Vector3(14.25, 2, -2.75), w_dark())
	add_label("Stone steps lead down into the dark...\n(to be continued)", Vector3(15.9, 2, -5), -90)


func w_dark() -> Color:
	return Color(0.25, 0.25, 0.28)


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
