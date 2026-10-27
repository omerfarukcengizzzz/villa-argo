extends Level
## Under the map shop, book 2 (docs/book2-design.md, steps 10-12): the
## abandoned corridors with the two lovers' statues and the mirrors, then the
## room that isn't there (failing lamp, snakes, the sound key) where Oblivia
## takes the map. Jason's alone here (Julia is at Villa Argo), so he needs her
## readings of Ulysses's notes. Canon: mirrors and light, statues, the room, the
## altar, the lamp, the snakes, the sound key, the theft (ref B2 scenes 12-14,
## LOW to HIGH); every mechanism is adaptation.
##
## Map (north = -z): entry steps z 0..8; the mirror hall, a 7x7 grid of 3 m
## cells (x -10.5..10.5, z -21..0); behind its west wall, the room that isn't
## there (x -22..-10.5, z -10..1).

const PUNT := "res://scenes/levels/punt.tscn"
const PUZZLE := "corr"
const CELL := 3.0
const GRID := 7
## Light comes off her face moving east, must turn at exactly three mirrors,
## and arrive at his face moving south (he faces north). Ref Ballad: "She looks
## to the morning, he looks to the night... three times on the way".
const SHE := Vector2i(0, 3)
const HE := Vector2i(2, 5)
const TURNS := 3
## [cell, starting facing]. The first three are on the solution path (they
## must face NW, SW, SE: 3, 2, 1); the last two are decoys.
const MIRRORS := [
	[Vector2i(4, 3), 1],
	[Vector2i(4, 1), 0],
	[Vector2i(2, 1), 3],
	[Vector2i(4, 5), 2],
	[Vector2i(6, 1), 1],
]
const BEAM_Y := 1.5
const LAMP_SECONDS := 60
const PLATES := ["SUN", "MOON", "STAR"]
const SOUND_KEY := ["MOON", "SUN", "STAR", "SUN"]
const ROOM_DOOR := Vector3(-11.6, 1, -4.5)

const STONE := Color(0.55, 0.48, 0.38)

var _beam: Node3D
var _lamp: OmniLight3D
var _lamp_t := 0.0


func _init() -> void:
	origin = Vector3(6000, 0, 0)


func _build() -> void:
	entries = {"default": {"jason": Vector3(0, 1, 5), "julia": Vector3(1, 1, 5)}}
	fall_y = -10.0
	add_environment(Color(0.02, 0.02, 0.02))
	_env.ambient_light_color = Color(0.12, 0.1, 0.08)
	_sun.light_energy = 0.0

	_build_entry()
	_build_hall()
	_build_room()

	GameState.changed.connect(_on_state_changed)
	_on_state_changed("")


func respawn_point(_role: String, _fell_from: Vector3) -> Vector3:
	return entries["default"]["jason"]


func cell_pos(c: Vector2i) -> Vector3:
	return Vector3(-9.0 + CELL * c.x, BEAM_Y, -19.5 + CELL * c.y)


func _on_state_changed(_key: String) -> void:
	_draw_beam()
	var lamp: int = GameState.get_flag("room.lamp", -1)
	_lamp.light_energy = 1.4 if lamp < 0 else 1.4 * lamp / float(LAMP_SECONDS)


# --- Light and mirrors (step 10) -------------------------------------------------

## Follows the light from her face. Returns [points, solved].
func trace() -> Array:
	var mirrors := {}
	for i in MIRRORS.size():
		mirrors[MIRRORS[i][0]] = node_mirror(i).facing()
	var pos := SHE
	var dir := Vector2i(1, 0)
	var turns := 0
	var points := [cell_pos(SHE)]
	for _step in 40:
		pos += dir
		if pos.x < 0 or pos.y < 0 or pos.x >= GRID or pos.y >= GRID:
			points.append(cell_pos(pos - dir) + Vector3(dir.x, 0, dir.y) * CELL / 2.0)
			return [points, false]
		if pos == HE:
			points.append(cell_pos(pos))
			return [points, dir == Vector2i(0, 1) and turns == TURNS]
		if mirrors.has(pos):
			points.append(cell_pos(pos))
			var n: Vector2i = Mirror.NORMALS[mirrors[pos]]
			var d := dir.x * n.x + dir.y * n.y
			if d >= 0:
				return [points, false]
			dir = dir - d * n
			turns += 1
	return [points, false]


func node_mirror(i: int) -> Mirror:
	return get_node("Mirror%d" % i)


func _draw_beam() -> void:
	for child in _beam.get_children():
		child.queue_free()
	var result := trace()
	var points: Array = result[0]
	var glow := Vis.material(Color(1.0, 0.9, 0.5))
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.85, 0.4)
	glow.emission_energy_multiplier = 3.0
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var seg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.12, a.distance_to(b))
		seg.mesh = box
		seg.material_override = glow
		seg.position = (a + b) / 2.0
		_beam.add_child(seg)
		seg.look_at_from_position(seg.position, b, Vector3.UP)
	if multiplayer.is_server() and result[1] and not GameState.get_flag(PUZZLE + ".solved", false):
		GameState.set_flag(PUZZLE + ".solved")
		Game.current.say("The light leaves her eyes, flashes from mirror to mirror and strikes his. Their eyes meet... and with a grinding of stone, part of the west wall slides away.")


func _build_entry() -> void:
	add_box(Vector3(3, 0.5, 8), Vector3(0, -0.25, 4), STONE)
	add_box(Vector3(0.5, 4, 8), Vector3(-1.75, 2, 4), STONE)
	add_box(Vector3(0.5, 4, 8), Vector3(1.75, 2, 4), STONE)
	add_box(Vector3(4, 4, 0.5), Vector3(0, 2, 8.25), STONE)
	var torch := OmniLight3D.new()
	torch.light_color = Color(1.0, 0.7, 0.4)
	torch.omni_range = 6.0
	torch.position = Vector3(0, 3, 6)
	add_child(torch)
	var up := LevelExit.new()
	up.who = "jason"
	up.solo = true
	up.level = PUNT
	up.entry = "map_shop"
	up.prompt = "Climb back up to the map shop"
	place(up, "StepsUp", Vector3(0, 1, 7))


func _build_hall() -> void:
	add_box(Vector3(21, 0.5, 21), Vector3(0, -0.25, -10.5), STONE)
	add_box(Vector3(9.5, 5, 0.5), Vector3(-5.75, 2.5, 0), STONE)
	add_box(Vector3(9.5, 5, 0.5), Vector3(5.75, 2.5, 0), STONE)
	add_box(Vector3(21, 5, 0.5), Vector3(0, 2.5, -21), STONE)
	add_box(Vector3(0.5, 5, 21), Vector3(10.5, 2.5, -10.5), STONE)
	# West wall, with the hidden opening (z -6..-3) into the room that isn't there.
	add_box(Vector3(0.5, 5, 15), Vector3(-10.5, 2.5, -13.5), STONE)
	add_box(Vector3(0.5, 5, 3), Vector3(-10.5, 2.5, -1.5), STONE)
	var hidden := Door.new()
	hidden.size = Vector3(3, 5, 0.5)
	hidden.open_flag = PUZZLE + ".solved"
	hidden.color = STONE
	place(hidden, "HiddenWall", Vector3(-10.5, 0, -4.5)).rotation_degrees.y = 90

	var shaft := SpotLight3D.new()
	shaft.light_color = Color(1.0, 0.95, 0.8)
	shaft.spot_range = 8.0
	shaft.spot_angle = 18.0
	shaft.light_energy = 4.0
	shaft.position = cell_pos(SHE) + Vector3(0, 4, 0)
	shaft.rotation_degrees.x = -90
	add_child(shaft)
	add_label("light falls through a hole in the roof", cell_pos(SHE) + Vector3(0.4, 2.6, 0), 90).font_size = 24

	_add_statue("SHE", SHE, 90.0)
	_add_statue("HE", HE, 0.0)

	for i in MIRRORS.size():
		var m := Mirror.new()
		m.puzzle = PUZZLE
		m.index = i
		m.start_facing = MIRRORS[i][1]
		place(m, "Mirror%d" % i, cell_pos(MIRRORS[i][0]))

	_beam = Node3D.new()
	_beam.name = "Beam"
	add_child(_beam)


## A statue whose face looks along yaw_degrees (0 = north, 90 = east... as in
## Godot: the face is local -z).
func _add_statue(text: String, c: Vector2i, facing_yaw: float) -> void:
	var p := cell_pos(c)
	var statue := add_box(Vector3(0.9, 2.4, 0.9), Vector3(p.x, 1.2, p.z), Color(0.8, 0.75, 0.65))
	statue.rotation_degrees.y = -facing_yaw
	var face := MeshInstance3D.new()
	var f := BoxMesh.new()
	f.size = Vector3(0.5, 0.4, 0.1)
	face.mesh = f
	face.position = Vector3(0, 0.6, -0.5)
	face.material_override = Vis.material(Color(0.95, 0.9, 0.8))
	statue.add_child(face)
	var tag := add_label(text, Vector3(p.x, 2.9, p.z))
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED


# --- The room that isn't there (steps 11-12) -------------------------------------

func _build_room() -> void:
	var dark := Color(0.35, 0.3, 0.25)
	add_box(Vector3(11.5, 0.5, 11), Vector3(-16.25, -0.25, -4.5), dark)
	add_box(Vector3(0.5, 5, 11), Vector3(-22, 2.5, -4.5), dark)
	add_box(Vector3(11.5, 5, 0.5), Vector3(-16.25, 2.5, 1), dark)
	add_box(Vector3(8.5, 5, 0.5), Vector3(-17.75, 2.5, -10), dark)
	add_label("a dark passage", Vector3(-12, 2.4, -9.7), 0).font_size = 24
	# Oblivia's way in and out: a passage that ends in a rockfall.
	add_box(Vector3(3, 0.5, 5), Vector3(-12, -0.25, -12.5), dark)
	add_box(Vector3(0.5, 5, 5), Vector3(-13.75, 2.5, -12.5), dark)
	add_box(Vector3(3.5, 5, 0.5), Vector3(-12, 2.5, -15), dark)

	_lamp = OmniLight3D.new()
	_lamp.light_color = Color(1.0, 0.75, 0.4)
	_lamp.omni_range = 9.0
	_lamp.position = Vector3(-16, 3.5, -4.5)
	add_child(_lamp)

	# The altar, with three turtles carved on it, and the bronze plates behind.
	add_box(Vector3(1.2, 1.0, 2.4), Vector3(-19.4, 0.5, -4.5), Color(0.6, 0.55, 0.45))
	add_label("three turtles carved on the altar", Vector3(-18.75, 1.3, -4.5), -90).font_size = 22
	for i in PLATES.size():
		var plate := SequenceButton.new()
		plate.who = "jason"
		plate.puzzle = "room"
		plate.symbol = PLATES[i]
		plate.solution = SOUND_KEY
		plate.requires = PUZZLE + ".solved"
		place(plate, "Plate" + PLATES[i], Vector3(-21.6, 2.0, -6.5 + 2.0 * i)).rotation_degrees.y = 90

	var map := Pickup.new()
	map.who = "jason"
	map.item_id = "map"
	map.item_name = "map of Kilmore Cove"
	map.appears = "room.solved & !b2.map_taken"
	map.prompt = "Take the map"
	map.box_size = Vector3(0.6, 0.05, 0.45)
	map.color = Color(0.85, 0.8, 0.6)
	map.on_used = _oblivia_takes_map
	place(map, "Map", Vector3(-19.4, 1.1, -4.5))

	# Snakes slither back and forth between the door and the altar.
	var bite := "A snake rears up! Jason leaps back to the doorway, heart pounding."
	for i in 3:
		var snake := Hazard.new()
		snake.respawn = ROOM_DOOR
		snake.message = bite
		snake.label = "snake"
		snake.travel = Vector3(0, 0, 8)
		snake.period = 4.0 + i
		snake.phase = i * 2.0
		place(snake, "Snake%d" % i, Vector3(-13.5 - i * 2.5, 0.5, -8.5))

	var oblivia := Npc.new()
	oblivia.npc_name = "Oblivia Newton"
	oblivia.color = Color(0.6, 0.15, 0.3)
	oblivia.who = "nobody"
	oblivia.present = "room.oblivia & !b2.oblivia_left"
	oblivia.walk_speed = 3.0
	oblivia.stations = [["", Vector3(-12.5, 1, -9)], ["b2.map_taken", Vector3(-12, 1, -13.5)]]
	place(oblivia, "Oblivia", Vector3(-12.5, 1, -9))


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or GameState.get_flag("room.solved", false):
		return
	var jason := Game.current.get_player(1)
	if jason == null or Game.current.level_for("jason") != self:
		return
	var in_room := to_local(jason.global_position).x < -10.8
	var lamp: int = GameState.get_flag("room.lamp", -1)
	if lamp < 0:
		if in_room:
			_lamp_t = 0.0
			GameState.set_flag("room.lamp", LAMP_SECONDS)
			Game.current.say("The little lamp by the door gutters. It won't burn for long.", "jason")
		return
	_lamp_t += delta
	if _lamp_t >= 1.0:
		_lamp_t = 0.0
		GameState.set_flag("room.lamp", lamp - 1)
		if lamp - 1 <= 0:
			_lamp_out(jason)


## Step 11: the lamp goes out before the altar opens.
func _lamp_out(jason: Node3D) -> void:
	GameState.set_flag("room.seq", "")
	GameState.set_flag("room.lamp", -1)
	jason.teleport.rpc(to_global(Vector3(-8.5, 1, -4.5)), PI / 2)
	Game.current.say("The lamp goes out. In the pitch dark, Jason and Rick feel their way back to the mirror hall... and Rick relights it.", "jason")


## Step 12 (canon, HIGH): Oblivia takes the map.
func _oblivia_takes_map(_player: Node3D) -> void:
	GameState.set_flag("room.oblivia")
	Game.current.say("\"Thank you, boys. You've saved me so much trouble.\" The woman from the market steps out of the dark passage.", "jason")
	await get_tree().create_timer(2.5).timeout
	GameState.take_item("map")
	GameState.set_flag("b2.map_taken")
	Game.current.say("She plucks the map out of Jason's hands. \"Oblivia Newton. Do remember the name.\" And she's gone, back into the passage.", "jason")
	GameState.add_journal("map_taken", "The map is gone",
		"In the room that isn't there, under an altar carved with three turtles, we found the map of Kilmore Cove. We held it for about ten seconds. Then the woman from the market, Oblivia Newton, took it from us and disappeared down a dark passage.\nTime to go home. Julia should have the Door open by now.", "jason")
	await get_tree().create_timer(2.5).timeout
	GameState.set_flag("b2.oblivia_left")
