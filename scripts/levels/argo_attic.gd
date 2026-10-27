extends Level
## The attic of Villa Argo, book 4 (docs/book4-design.md): "Knights in the
## attic" (canon chapter title; contents unknown), where the three plan the
## Venice trip, and where Dedalus's Old Owl printing machine stands (the
## placement is adaptation). Step 1: Rick types DEDA and nothing happens.
## Step 5: the secret guard's mask Jason uses on the intruders. Step 7: with the
## right key (the Owl key, which Julia learns in Venice), DEDA prints where to
## find the Black Gondolier.

const VILLA_ARGO := "res://scenes/levels/villa_argo.tscn"
const KEYS := [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"]]
const WOOD := Color(0.45, 0.33, 0.22)


func _init() -> void:
	origin = Vector3(12000, 0, 0)


func _build() -> void:
	entries = {"default": {"jason": Vector3(-1, 1, 4), "julia": Vector3(1, 1, 4), "yaw": 0.0}}
	add_environment(Color(0.35, 0.3, 0.28))
	_env.ambient_light_color = Color(0.45, 0.42, 0.38)
	_sun.light_energy = 0.4

	add_box(Vector3(14, 0.5, 12), Vector3(0, -0.25, 0), WOOD)
	add_box(Vector3(14, 3, 0.4), Vector3(0, 1.5, 6), WOOD)
	add_box(Vector3(14, 3, 0.4), Vector3(0, 1.5, -6), WOOD)
	add_box(Vector3(0.4, 3, 12), Vector3(-7, 1.5, 0), WOOD)
	add_box(Vector3(0.4, 3, 12), Vector3(7, 1.5, 0), WOOD)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.85, 0.6)
	lamp.omni_range = 10.0
	lamp.position = Vector3(0, 2.6, 0)
	add_child(lamp)

	# Knights in the attic: old suits of armour, trunks.
	for x in [-5.5, -3.5]:
		add_box(Vector3(0.7, 1.9, 0.5), Vector3(x, 0.95, -5.2), Color(0.6, 0.62, 0.66))
	add_label("suits of armour", Vector3(-4.5, 2.3, -5.4), 0).font_size = 28
	add_box(Vector3(1.4, 0.8, 0.8), Vector3(5, 0.4, 3.5), WOOD.darkened(0.2))
	add_label("an old trunk", Vector3(5, 1.2, 3.5)).billboard = BaseMaterial3D.BILLBOARD_ENABLED

	var down := LevelExit.new()
	down.level = VILLA_ARGO
	down.entry = "attic"
	down.solo_when = "b4.split"
	down.prompt = "Go down to the hall"
	place(down, "StairsDown", Vector3(0, 1, 5))

	# Step 5: a secret guard's mask in the trunk (Jason, while alone).
	var mask := Pickup.new()
	mask.who = "jason"
	mask.requires = "b4.split"
	mask.appears = "b4.split"
	mask.item_id = "guard_mask"
	mask.item_name = "secret guard's mask"
	mask.prompt = "Take the mask from the trunk"
	mask.box_size = Vector3(0.4, 0.5, 0.15)
	mask.color = Color(0.95, 0.95, 0.9)
	place(mask, "GuardMask", Vector3(5, 1.0, 3.5))

	_build_old_owl()
	_build_rick()


func _host_setup() -> void:
	if GameState.get_flag("b3.escaped", false) and not GameState.get_flag("b4.started", false):
		GameState.set_flag("b4.started")
		GameState.add_journal("b4_mission", "Knights in the attic",
			"Up in the attic, among the old suits of armour, we made a plan. Oblivia has gone to Venice after Peter Dedalus. If he tells her where the First Key is, she can open every Door. We have to find him first. The Metis took us to Egypt; maybe it can take us to Venice.")
		Game.current.say("Book 4: The Isle of Masks. In the attic, among the suits of armour, stands a strange machine shaped like an owl.")


# --- The Old Owl (steps 1 and 7) ---------------------------------------------------

func _build_old_owl() -> void:
	add_box(Vector3(1.6, 1.4, 1.0), Vector3(-4, 0.7, 1), Color(0.55, 0.45, 0.3))
	add_box(Vector3(0.9, 0.9, 0.9), Vector3(-4, 1.85, 1), Color(0.6, 0.5, 0.35))
	add_label("the Old Owl", Vector3(-4, 2.8, 1)).billboard = BaseMaterial3D.BILLBOARD_ENABLED

	var slip := JournalNote.new()
	slip.requires = "b4.started"
	slip.entry_id = "old_owl_slip"
	slip.title = "The Old Owl"
	slip.body = "A machine shaped like an owl, all brass keys and gears, with Dedalus's \"d\" stamped on its side. It holds a printed slip: \"DEDA, with the right key.\"\nRick typed D, E, D, A. Nothing happened. There's a small keyhole in its side."
	slip.prompt = "Look at the owl-shaped machine"
	slip.size = Vector3(0.3, 0.05, 0.2)
	place(slip, "OwlSlip", Vector3(-4, 1.45, 1.6))

	var keyhole := ChoicePoint.new()
	keyhole.who = "jason"
	keyhole.requires = "b4.split & !owl.key_in"
	keyhole.prompt = "Try a key in the owl's keyhole"
	keyhole.question = "Which key?"
	keyhole.options_for = func() -> Array:
		return KEYS.map(func(k: Array) -> Array: return [k[1], GameState.has_item(k[0])])
	keyhole.on_choice = func(_p: Node3D, choice: String) -> void:
		if choice == "Owl key":
			GameState.set_flag("owl.key_in")
			Game.current.say("The Owl key slides in and turns. Inside the machine, something whirs awake.", "jason")
		else:
			Game.current.say("The %s doesn't fit." % choice, "jason")
	place(keyhole, "OwlKeyhole", Vector3(-3.1, 1.0, 1))

	var keys := CodeEntry.new()
	keys.who = "jason"
	keys.requires = "owl.key_in"
	keys.answer = "DEDA"
	keys.solved_flag = "owl.printed"
	keys.prompt = "Type on the Old Owl"
	keys.question = "Type:"
	keys.wrong_text = "The Old Owl clicks, and prints nothing."
	keys.size = Vector3(0.01, 0.01, 0.01)
	keys.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("owl_printout", "The Old Owl's printout",
			"With the Owl key turned, I typed DEDA and the machine printed a whole card:\n\"The Black Gondolier waits where the last lamp burns on the Fondamenta of the Masks. He rows for no one, unless they say: SERENISSIMA.\"\nJulia needs this.", "jason")
	place(keys, "OwlKeys", Vector3(-4, 1.0, 1.7))


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.present = "!b4.away"
	rick.lines = [
		["", "So this is where Ulysses kept his junk. Suits of armour! And what's that thing?"],
		["journal:old_owl_slip", "DEDA, with the right key... I don't get it. Never mind: we have to get to Venice before Oblivia finds Dedalus. Down to the Metis!"],
	]
	place(rick, "Rick", Vector3(2.5, 1, -1))
