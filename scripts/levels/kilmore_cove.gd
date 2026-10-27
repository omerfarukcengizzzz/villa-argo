extends Level
## Kilmore Cove, book 1 step 7: the post office, where the receipt from the
## tower diary gets the twins the parcel with the four animal keys and a second
## coded message. Street layout is adaptation; the post office and the parcel
## are canon (ref B1 scene 8).

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"

const WALL := Color(0.75, 0.68, 0.6)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.2, 1, 8), "julia": Vector3(1.2, 1, 8), "yaw": 0.0},
	}
	add_environment(Color(0.6, 0.72, 0.85))

	add_box(Vector3(24, 0.5, 30), Vector3(0, -0.25, 0), Color(0.5, 0.5, 0.5))
	add_box(Vector3(0.4, 2, 30), Vector3(-12, 1, 0), WALL)
	add_box(Vector3(0.4, 2, 30), Vector3(12, 1, 0), WALL)
	add_box(Vector3(24, 2, 0.4), Vector3(0, 1, 15), WALL)
	# Painted houses along the street.
	var colors := [Color(0.85, 0.55, 0.5), Color(0.55, 0.7, 0.85), Color(0.9, 0.85, 0.55), Color(0.6, 0.8, 0.6)]
	for i in 4:
		add_box(Vector3(4, 5, 4), Vector3(-9, 2.5, 9 - i * 5), colors[i])
		add_box(Vector3(4, 5, 4), Vector3(9, 2.5, 9 - i * 5), colors[3 - i])

	# Post office at the end of the street, open to the south.
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
