extends SceneTree
# Headless two-process test of book 5 Pass B. Usage: -s tests/book5_pass_b.gd -- host|client

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


func dad_at(i: int) -> bool:
	return int(gs().get_flag("b5.dad", 0)) == i


func keys_held() -> int:
	return ["owl_key", "porcupine_key", "elephant_key", "newt_key"].filter(func(k: String) -> bool: return gs().has_item(k)).size()


func pressure() -> int:
	return int(gs().get_flag("station.pressure", 0))


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	# End of book 5 Pass A: the keys are back.
	for f in ["argo.met_nestor", "argo.footsteps", "argo.rick_here", "argo_door.open", "b2.home", "b3.started", "b3.escaped", "b4.started", "b4.home",
			"b5.started", "b5.met_minaxo", "b5.dad_gone", "b5.confiscated", "b5.recovered"]:
		gs().set_flag(f)
	for k in [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"]]:
		gs().give_item(k[0], k[1])
	game().change_level("res://scenes/levels/kilmore_cove.tscn", "station")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Kilmore Cove")
	await wait(0.5)

	# Step 6: Fred opens the station.
	check(not node("StationDoor").is_available(), "the station is chained shut")
	await move_me(Vector3(16, 1, -5.6))
	await use("Fred")
	check(gs().get_flag("b5.station_open", false) and journal_ids("both").has("fred"), "Fred has the keys")
	await move_me(Vector3(21.4, 1, 3.6))
	gs().set_flag("test.station")
	await until(func() -> bool: return _julia_near(Vector3(22.6, 1, 3.6)), "Julia at the station door")
	await use("StationDoor")
	await until(func() -> bool: return level_name() == "station.tscn", "the station")
	await wait(0.4)
	check(toast().contains("roof lantern"), "the overgrown hall")

	# Fred's valves.
	await move_me(Vector3(-5, 1, 7.2))
	await use("Fred")
	check(journal_ids("both").has("fred_valves"), "red closed, blue open")

	# Step 8: Julia sets off the bookstand; only she reads the board.
	gs().set_flag("test.bookstand")
	await until(func() -> bool: return journal_ids("julia").has("the_board"), "Julia reads the board", 20)
	check(not journal_ids("jason").has("the_board"), "the board is Julia's to read")
	check(toast().contains("counterweight") or toast().contains("Julia's looking at him"), "Rick works it out")

	# Step 9: the ticket printer.
	await move_me(Vector3(-14, 1, 0))
	node("TicketPrinter").submit("KA-LO 1")
	await wait(0.3)
	check(toast().contains("blank ticket") and not gs().has_item("ticket"), "a wrong train prints nothing")
	node("TicketPrinter").submit("mi ra so 3")
	await wait(0.3)
	check(gs().has_item("ticket") and journal_ids("both").has("ticket"), "a ticket to nowhere")

	# Step 10: the control room. Levers are stuck until the red valve opens.
	gs().set_flag("test.model")
	await move_me(Vector3(13.5, 1, -6.2))
	await use("Lever1")
	check(toast().contains("won't budge") and not gs().get_flag("station.lever1", false), "the levers are locked")
	await move_me(Vector3(18.2, 1, -5), -PI / 2)
	Input.action_press("move_forward")
	await until(func() -> bool: return local_pos().y > 4.6, "Jason climbs to the pipes", 8)
	Input.action_release("move_forward")
	await move_me(Vector3(19.2, 5, -5))
	await use("Valve_red")
	check(gs().get_flag("station.red_open", false), "red valve open")
	for i in [1, 2]:
		await move_me(Vector3(12 + i * 1.5, 1, -6.2))
		await use("Lever%d" % i)
	check(not gs().get_flag("station.route", false), "not locked while the red valve's open")
	await move_me(Vector3(19.2, 5, -5))
	await use("Valve_red")
	await wait(0.2)
	check(gs().get_flag("station.route", false) and journal_ids("both").has("route"), "the route is set and locked")

	# Step 11: the riddle and the firebox.
	await move_me(Vector3(8, 1, -18.8))
	await use("Riddle")
	check(journal_ids("both").has("riddle"), "half of sand and half of wind")
	await move_me(Vector3(6.6, 1, -18.8))
	await use("Shovel")
	await use("Shovel")
	check(toast().contains("chokes") and pressure() == 0, "coal twice chokes the fire")
	gs().set_flag("test.stoke")
	var t := 0.0
	while not gs().get_flag("b5.train_awake", false) and t < 40.0:
		if gs().get_flag("station.last_stoke", "") != "coal":
			node("Shovel").request()
		await wait(0.2)
		t += 0.2
	check(gs().get_flag("b5.train_awake", false) and journal_ids("both").has("train_awake"), "the Train of Eternal Youth wakes")
	check(node("Rick").current_line().contains("Horse key"), "Rick: it needs the Horse key")
	await move_me(Vector3(8, 1, -39.5))
	await use("HorseDoor")
	check(journal_ids("both").has("horse_door"), "the boarded-up Horse Door")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("test.station", false), "to the station", 30)
	await move_me(Vector3(22.6, 1, 3.6))
	await until(func() -> bool: return level_name() == "station.tscn", "the station (client)", 20)
	await until(func() -> bool: return gs().get_flag("test.bookstand", false), "the bookstand", 20)
	check(not node("ReadBoard").is_available(), "the board is too high to read")
	await move_me(Vector3(-16, 1, -6.4))
	await use("Bookstand")
	await wait(2.5)
	check(node("Board").position.y < 4.0, "the board comes down on its chains")
	await move_me(Vector3(-3, 1, -9.6))
	await use("ReadBoard")
	check(journal_ids("julia").has("the_board"), "Julia reads the board")
	await until(func() -> bool: return gs().get_flag("test.model", false), "the control room", 30)
	await move_me(Vector3(15, 1, 0.6))
	await use("TrackModel")
	check(journal_ids("julia").has("track_model"), "Julia studies the track model")
	await until(func() -> bool: return gs().get_flag("test.stoke", false), "the firebox", 60)
	await move_me(Vector3(9.4, 1, -18.8))
	var t := 0.0
	while not gs().get_flag("b5.train_awake", false) and t < 40.0:
		if gs().get_flag("station.last_stoke", "") == "coal":
			node("Bellows").request()
			await wait(0.3)
		await wait(0.1)
		t += 0.1
	check(gs().get_flag("b5.train_awake", false), "the train wakes (client)")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
