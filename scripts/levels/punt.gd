extends Level
## The Land of Punt, book 2 (docs/book2-design.md). Pass A: Part 1, together:
## the hidden harbour where the Metis lands, the chest of local clothes, the
## hall with the Door back to Villa Argo, the town street, the mastaba and the
## wall that collapses, splitting the twins (Julia through the Door, Jason and
## Rick stuck here). Jason's half (Maruk, the House of Life, the map shop...)
## is Pass B. No date or pharaoh for Punt (ref §5).
##
## Map (north = -z): harbour z -2..10 with the Metis moored to the south;
## the Door hall z -10..-2 (Door on its west wall); the town street
## z -42..-10 with the old wall on the east side and the mastaba at the end.

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"

const STONE := Color(0.78, 0.68, 0.5)
const SAND := Color(0.88, 0.78, 0.55)

var _old_wall: StaticBody3D
var _rubble: Node3D


func _init() -> void:
	origin = Vector3(3000, 0, 0)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1, 1, 8), "julia": Vector3(1, 1, 8)},
	}
	fall_y = -10.0
	add_environment(Color(0.75, 0.85, 0.95))
	_sun.light_energy = 1.3

	_build_harbour()
	_build_hall()
	_build_town()
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
	door.requires = "punt.wall_fell & !b2.split"
	door.prompt = "Run through the Door!"
	door.on_used = _split
	place(door, "TheDoor", Vector3(-3, 1, -6))

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
		add_box(Vector3(3, 4, 4), Vector3(-6.5, 2, z), colors[i % 3])
		if z > -21.0 or z < -29.0:
			add_box(Vector3(3, 4, 4), Vector3(6.5, 2, z), colors[(i + 1) % 3])

	_old_wall = add_box(Vector3(0.6, 3.5, 7), Vector3(5.2, 1.75, -25), Color(0.7, 0.6, 0.45))
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

	# Jason's half starts here. Pass B moves this note into the House of Life.
	var note := JournalNote.new()
	note.who = "jason"
	note.entry_who = "jason"
	note.entry_id = "door_backwards"
	note.title = "Ulysses's note about the Door"
	note.body = "Wedged among the fallen stones, a scrap of paper in Ulysses Moore's handwriting:\n\"If ever the Door shuts with friends still on the far side, it can be opened from the house: ask it backwards.\"\n\nJulia needs to know this."
	note.prompt = "Pick up the scrap of paper"
	note.requires = "b2.split"
	note.size = Vector3(0.3, 0.05, 0.25)
	place(note, "DoorNote", Vector3(3.2, 0.7, -24))


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.walk_speed = 5.0
	rick.stations = [
		["", Vector3(2, 1, 6.5)],
		["punt.disguised", Vector3(-2.5, 1, -14)],
		["punt.wall_fell", Vector3(-2.5, 1, -27)],
	]
	rick.lines = [
		["", "The Metis brought us to Egypt. Real Egypt! We can't walk about dressed like this, though. There's a chest of clothes on the quay."],
		["punt.disguised", "Look at that low stone building at the end of the street. I'll check the Dictionary."],
		["journal:mastaba", "A tomb! This whole place is ancient. Let's keep going."],
		["punt.wall_fell", "The wall! Back to the Door, quick!"],
		["b2.split", "Julia made it through, but the Door won't budge for us. Ulysses must have thought of this. Look around the rubble."],
		["journal:door_backwards", "Ask it backwards? Tell Julia! Meanwhile, let's find out where we are."],
	]
	place(rick, "Rick", Vector3(2, 1, 6.5))
