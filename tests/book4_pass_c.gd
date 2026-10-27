extends SceneTree
# Headless two-process test of book 4 Pass C. Usage: -s tests/book4_pass_c.gd -- host|client

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
	# Book 4 Passes A-B done.
	for f in ["argo.rick_here", "argo.wardrobe_moved", "argo_door.open", "stones.solved", "metis.sailed", "b3.escaped", "b4.started", "b4.sailed", "b4.away",
			"b4.intruders_seen", "b4.intruders_through", "b4.nestor_free", "b4.intruders_gone", "b4.argo_safe", "b4.penelope", "venice.d_match", "venice.printroom"]:
		gs().set_flag(f)
	gs().add_journal("owl_printout", "The Old Owl's printout", "...SERENISSIMA...", "jason")
	game().change_level("res://scenes/levels/venice.tscn")
	await wait(0.5)
	gs().set_flag("b4.split")
	game().move_twin("jason", "res://scenes/levels/villa_argo.tscn", "door")
	gs().set_flag("test.split")

	# Jason waits at home for the Metis.
	await until(func() -> bool: return gs().get_flag("b4.julia_home", false), "Julia sails home", 300)
	await wait(0.3)
	check(toast().contains("The Metis is back"), "Jason hears the Metis come home")
	await move_me(Vector3(13.8, 1, -2.8))
	await use("RunToBeach")
	await until(func() -> bool: return gs().get_flag("b4.home", false), "together on the beach", 8)
	await wait(0.5)
	check(level_name() == "argo_underground.tscn" and game().together() and not gs().get_flag("b4.split", true), "the twins are together again")
	check(journal_ids("jason").has("b4_home") and journal_ids("jason").has("black_vulcano"), "home from Venice; Black Vulcano has the keys")
	await until(func() -> bool: return toast().contains("End of book 4"), "end of book 4", 8)
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("test.split", false) and level_name() == "venice.tscn", "Julia in Venice", 20)
	await wait(0.5)

	# Step 12: the pigeon. Step 13: the Master Watchmaker.
	await until(func() -> bool: return cenere_at(1) or cenere_at(2), "Cenere on the far side", 30)
	await move_me(Vector3(32, 1, -15.8))
	await use("Pigeon")
	check(journal_ids("julia").has("pigeon_message"), "the pigeon's message")
	await move_me(Vector3(37.6, 1, -28))
	await use("MasterWatchmaker")
	check(gs().get_flag("b4.watchmaker", false) and toast().contains("Black Gondolier"), "the Master Watchmaker: find the Black Gondolier")

	# Step 14: the word.
	await move_me(Vector3(39, 1, -40.6))
	node("SayWord").submit("Venezia")
	await wait(0.4)
	check(toast().contains("doesn't move") and level_name() == "venice.tscn", "the wrong word")
	node("SayWord").submit("Serenissima")
	await until(func() -> bool: return level_name() == "isle_of_masks.tscn", "the Isle of Masks", 5)
	await wait(0.4)

	# Step 15: Dedalus, then Oblivia.
	await move_me(Vector3(-3, 1, -9.6))
	await use("Dedalus")
	check(journal_ids("julia").has("dedalus_found") and node("Oblivia").visible, "Peter Dedalus; Oblivia arrives")
	await until(func() -> bool: return str(gs().get_flag("isle.phase", "")) == "fire", "fire", 10)
	await wait(1.2)
	check(node("BackDoor")._opened and toast().contains("Out the back"), "fire! The back door opens")

	# Step 16: the corridor of masks.
	var flame: Node3D = node("Flame0")
	me().global_position = flame.global_position
	await wait(0.3)
	check(toast().contains("flames leap") and local_pos().distance_to(Vector3(0, 1, -6)) < 1.0, "the flames send Julia back")
	await move_me(Vector3(-1.5, 1, -25))
	await use("Photo")
	check(journal_ids("julia").has("ulysses_photo"), "a half-melted photo: \"Ulysses\"")
	await move_me(Vector3(0, 1, -32.8))
	await use("Gondola")
	await until(func() -> bool: return level_name() == "venice.tscn", "back in Venice", 5)
	await wait(0.4)
	check(gs().get_flag("b4.isle_escaped", false) and toast().contains("Black Vulcano has the keys"), "Dedalus: Black Vulcano has the keys")

	# Step 17: home.
	await move_me(Vector3(-1, 1, 9.8))
	await use("SailHome")
	await until(func() -> bool: return level_name() == "argo_underground.tscn", "the beach under Villa Argo", 5)
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	check(journal_ids("julia").has("b4_home"), "Julia's journal: home from Venice")
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
