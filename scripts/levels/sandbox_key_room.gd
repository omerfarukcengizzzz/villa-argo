extends Level
## Second sandbox room, exercising the shared building blocks: Julia reads a
## note only she can decipher (private journal entry), Jason climbs crates to a
## ledge for the key, and the key opens the locked north door.
## Sandbox: replaced by the Villa Argo hub once the story is in.

const PUZZLE_ROOM := "res://scenes/levels/sandbox_puzzle_room.tscn"


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.5, 1, 5), "julia": Vector3(1.5, 1, 5)},
	}
	add_environment(Color(0.18, 0.15, 0.2))

	var wall := Color(0.42, 0.4, 0.45)
	add_box(Vector3(14, 0.5, 14), Vector3(0, -0.25, 0), Color(0.5, 0.5, 0.52))
	add_box(Vector3(5.5, 4, 0.5), Vector3(-4.25, 2, -7), wall)
	add_box(Vector3(5.5, 4, 0.5), Vector3(4.25, 2, -7), wall)
	add_box(Vector3(14, 4, 0.5), Vector3(0, 2, 7), wall)
	add_box(Vector3(0.5, 4, 14), Vector3(-7, 2, 0), wall)
	add_box(Vector3(0.5, 4, 14), Vector3(7, 2, 0), wall)
	# Corridor behind the locked door.
	add_box(Vector3(3, 0.5, 4), Vector3(0, -0.25, -9), Color(0.8, 0.7, 0.3))
	add_box(Vector3(0.5, 4, 4), Vector3(-1.75, 2, -9), wall)
	add_box(Vector3(0.5, 4, 4), Vector3(1.75, 2, -9), wall)
	add_box(Vector3(4, 4, 0.5), Vector3(0, 2, -11.25), wall)

	# Crates up to a ledge along the west wall (Jason's climb).
	var wood := Color(0.6, 0.5, 0.35)
	add_box(Vector3(2, 1, 2), Vector3(-5.5, 0.5, 2), wood)
	add_box(Vector3(2, 2, 2), Vector3(-5.5, 1, -1), wood)
	add_box(Vector3(2.5, 3, 4), Vector3(-5.5, 1.5, -4.5), wood)
	var scuffs := add_label("scuff marks: climb here", Vector3(-4.45, 1.3, 2), 90)
	Vis.make_private(scuffs, "jason")

	var key := Pickup.new()
	key.item_id = "brass_key"
	key.item_name = "brass key"
	key.who = "jason"
	place(key, "BrassKey", Vector3(-5.5, 3.9, -5.5))

	var note := JournalNote.new()
	note.who = "julia"
	note.entry_who = "julia"
	note.entry_id = "sandbox_key_note"
	note.title = "A note in mirror writing"
	note.body = "Held up to the light, the scribbles read:\n\"The key sleeps on the highest crate. Only a climber will reach it.\""
	place(note, "Note", Vector3(6.7, 1.6, 0)).rotation_degrees.y = 90

	var door := Door.new()
	door.open_flag = "key_room.door_open"
	door.key_item = "brass_key"
	door.key_name = "the brass key"
	place(door, "LockedDoor", Vector3(0, 0, -7))

	var exit := LevelExit.new()
	exit.level = PUZZLE_ROOM
	exit.entry = "from_key_room"
	exit.requires_flag = "key_room.door_open"
	place(exit, "ExitToPuzzleRoom", Vector3(0, 1, -9.8))
