extends SceneTree
# Headless two-process test of book 4 Pass B. Usage: -s tests/book4_pass_b.gd -- host|client

var role := ""
var fails := 0
## Set at the very end of _host/_client; a script error aborts them early.
var finished := false


func _initialize() -> void:
	role = OS.get_cmdline_user_args()[0]
	_run.call_deferred()


func log_(msg: String) -> void:
	print("[%s] %s" % [role, msg])


func check(cond: bool, what: String) -> void:
	if cond:
		log_("PASS " + what)
	else:
		fails += 1
		log_("FAIL " + what)


func wait(sec: float) -> void:
	await create_timer(sec).timeout


func until(cond: Callable, what: String, timeout := 15.0) -> bool:
	var t := 0.0
	while not cond.call():
		await create_timer(0.1).timeout
		t += 0.1
		if t > timeout:
			check(false, "timeout waiting for " + what)
			return false
	return true


func game() -> Node:
	return root.get_node_or_null("/root/Game")


func gs() -> Node:
	return root.get_node("/root/GameState")


func me() -> Node3D:
	var g := game()
	return g.get_player(g.multiplayer.get_unique_id()) if g else null


func lvl() -> Node:
	return game().level if game() else null


func node(n: String) -> Node:
	return lvl().get_node(n)


## Positions are local to this twin's level.
func move_me(pos: Vector3, yaw := 0.0) -> void:
	var p := me()
	p.global_position = lvl().to_global(pos)
	p.rotation.y = yaw
	p.velocity = Vector3.ZERO
	await wait(0.4)


func use(n: String) -> void:
	node(n).request()
	await wait(0.3)


func level_name() -> String:
	return lvl().scene_file_path.get_file() if lvl() else ""


func toast() -> String:
	return game()._toast.text


func journal_ids(r: String) -> Array:
	return gs().journal_for(r).map(func(e: Dictionary) -> String: return e["id"])


func _run() -> void:
	if role == "host":
		await _host()
	else:
		await _client()
	if not finished:
		check(false, "script stopped early (see SCRIPT ERROR above)")
	log_("DONE fails=%d" % fails)
	quit(1 if fails else 0)


func _julia_near(pos: Vector3) -> bool:
	for p in game().get_players():
		if p.role == "julia":
			return p.global_position.distance_to(lvl().to_global(pos)) < 3.0
	return false


func local_pos() -> Vector3:
	return lvl().to_local(me().global_position)


func set_slot(i: int, key: String) -> void:
	for n in 6:
		if str(gs().get_flag("argo_door.slot%d" % i, "")) == key:
			return
		await use("Lock%d" % i)
	check(false, "could not set lock %d to %s" % [i, key])


func cenere_at(i: int) -> bool:
	return int(gs().get_flag("venice.cenere", 0)) == i


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	# Book 4 Pass A done: Jason at Argo, Julia in Venice.
	for f in ["argo.rick_here", "argo_door.open", "b3.escaped", "b4.started", "b4.sailed", "b4.away", "b4.intruders_seen", "b4.intruders_through"]:
		gs().set_flag(f)
	gs().add_journal("old_owl_slip", "The Old Owl", "...")
	gs().add_journal("cenere_mask", "Masks of the Venetian secret guard", "...", "jason")
	game().change_level("res://scenes/levels/venice.tscn")
	await wait(0.5)
	gs().set_flag("b4.split")
	game().move_twin("jason", "res://scenes/levels/villa_argo.tscn", "door")
	gs().set_flag("test.split")
	await until(func() -> bool: return gs().get_flag("b4.penelope", false), "Julia reads Penelope's letters", 240)
	check(journal_ids("jason").has("penelope_letters"), "the letters are for both twins")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("test.split", false) and level_name() == "venice.tscn", "Julia in Venice", 20)
	await wait(0.5)
	check(node("Rick").current_line().contains("grey mask"), "Rick: someone in a grey mask")

	# Step 8: Count Cenere sees Julia and sends her back.
	var cenere: Node3D = node("Cenere")
	var forward := -cenere.global_transform.basis.z
	forward.y = 0
	me().global_position = cenere.global_position + forward.normalized() * 2.5
	await until(func() -> bool: return toast().contains("hustle you back"), "Count Cenere spots Julia", 4)
	await wait(0.3)
	check(local_pos().distance_to(Vector3(0, 1, -6)) < 1.0, "back at the canal steps")

	# Step 9: the Callers.
	await until(func() -> bool: return cenere_at(1) or cenere_at(2), "Cenere on the far side", 30)
	await move_me(Vector3(2.5, 1, -36.6))
	await use("Rossella")
	check(journal_ids("julia").has("beggars_fear") and not journal_ids("jason").has("beggars_fear"), "Rossella: beggars fear the guard (for Jason)")
	await move_me(Vector3(0, 1, -39.8))
	await use("Encyclopedie")
	check(journal_ids("julia").has("encyclopedie") and node("Alberto").current_line().contains("cloth back"), "the forbidden Encyclopedie")

	# Step 10: the d.
	var trays: Label3D = null
	for child in lvl().get_children():
		if child is Label3D and child.text.begins_with("Type trays"):
			trays = child
	check(trays != null and trays.layers == 2, "only Julia can read the type trays")
	await move_me(Vector3(4.2, 1, -39))
	node("TypeTrays").submit("Tray A")
	await wait(0.4)
	check(toast().contains("curls back") and not gs().get_flag("venice.d_match", false), "wrong tray")
	node("TypeTrays").submit("Tray C")
	await wait(1.4)
	check(gs().get_flag("venice.d_match", false) and node("ShedDoor")._opened, "Tray C: Dedalus's d; the boat shed opens")
	check(node("Alberto").current_line().contains("I printed that book myself"), "Alberto confesses")

	# The flooded boat shed: fall in, then cross.
	me().global_position = lvl().to_global(Vector3(8.2, 1, -39))
	var back := await until(func() -> bool: return local_pos().distance_to(Vector3(5, 1, -40)) < 1.0, "a splash, and back in the shop", 6)
	check(back, "falling in the water puts Julia back in the shop")
	await move_me(Vector3(18.5, 1, -40.2))
	await use("Press")
	await move_me(Vector3(19, 1, -40))
	await use("BrassPlate")
	check(journal_ids("julia").has("right_key") and node("Rick").current_line().contains("Dedalus built this press"), "the print room: Dedalus's gears, the right key (for Jason)")

	# Step 11: Penelope's house.
	await until(func() -> bool: return cenere_at(1), "Cenere far from the blue door", 30)
	await move_me(Vector3(-8.4, 1, -18))
	await use("BlueDoorLock")
	await wait(1.2)
	check(node("BlueDoor")._opened, "the blue door opens")
	await move_me(Vector3(-15.5, 1, -16))
	await use("GirlsRoom")
	await move_me(Vector3(-18.3, 1, -20))
	await use("Frame")
	await move_me(Vector3(-18.3, 1, -20.6))
	await use("Letters")
	check(gs().get_flag("b4.penelope", false) and journal_ids("julia").has("penelope_letters"), "Penelope was born in Venice")
	check(node("Rick").current_line().contains("Peter Dedalus"), "Rick: Peter feeds the pigeons")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host saw it", 10)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
