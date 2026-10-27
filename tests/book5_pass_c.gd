extends SceneTree
# Headless two-process test of book 5 Pass C. Usage: -s tests/book5_pass_c.gd -- host|client

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


func guardian(i: int) -> Vector3:
	return gs().get_flag("garden.g%d" % i, Vector3.ZERO)


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	# End of book 5 Pass B: the train is awake.
	for f in ["argo.met_nestor", "argo.footsteps", "argo.rick_here", "argo_door.open", "b2.home", "b3.started", "b3.escaped", "b4.started", "b4.home",
			"metis.log_read", "metis.sailed", "b4.sailed", "under.candle_out", "stones.solved",
			"b5.started", "b5.met_minaxo", "b5.dad_gone", "b5.confiscated", "b5.recovered", "b5.station_open", "b5.train_awake"]:
		gs().set_flag(f)
	for k in [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"]]:
		gs().give_item(k[0], k[1])

	# Step 12: home to Villa Argo; Oblivia went first.
	game().change_level("res://scenes/levels/kilmore_cove.tscn")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Kilmore Cove")
	await wait(0.3)
	game().change_level("res://scenes/levels/villa_argo.tscn", "gate")
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "Villa Argo")
	await wait(0.5)
	check(gs().get_flag("b5.oblivia_ahead", false) and journal_ids("both").has("oblivia_ahead") and toast().contains("Straight past me"), "Oblivia and Manfred went through the Door")
	check(node("Nestor").current_line().contains("Through the Door"), "Nestor: be careful")
	game().change_level("res://scenes/levels/argo_underground.tscn")
	await until(func() -> bool: return level_name() == "argo_underground.tscn", "under Argo")
	await wait(0.5)
	check(not node("HelmGarden").is_available(), "the helm doesn't know where to go yet")
	await move_me(Vector3(1, -13.4, -55.6))
	await use("PerfumedPage")
	check(journal_ids("both").has("perfumed_page"), "a perfumed page: the Garden of Prester John")
	check(node("Rick").current_line().contains("stay"), "Rick stays behind")
	await move_me(Vector3(0, -13.4, -51))
	gs().set_flag("test.ship")
	await until(func() -> bool: return _julia_near(Vector3(0, -13.4, -52)), "Julia aboard")
	node("HelmGarden").submit("Venice")
	await wait(0.3)
	check(toast().contains("won't turn") and level_name() == "argo_underground.tscn", "not Venice this time")
	node("HelmGarden").submit("The Garden of Prester John")
	await until(func() -> bool: return level_name() == "garden.tscn", "the Garden", 5)
	await wait(0.5)
	check(journal_ids("both").has("castaways") and toast().contains("Castaways"), "castaways")

	# Step 13: the stone guardians move only when nobody's looking.
	await move_me(Vector3(-1.2, 1, 5), 0.0)
	gs().set_flag("test.yard")
	await wait(2.5)
	check(guardian(0).is_equal_approx(Vector3(-9, 1, -19)) and guardian(1).is_equal_approx(Vector3(9, 1, -19)), "watched guardians stay still")
	check(not guardian(2).is_equal_approx(Vector3(-9, 1, -5)) and not guardian(3).is_equal_approx(Vector3(9, 1, -5)), "unwatched guardians creep closer")
	await until(func() -> bool: return toast().contains("stone hand"), "a guardian catches a twin", 15)
	await wait(0.3)
	check(guardian(2).is_equal_approx(Vector3(-9, 1, -5)), "and they're all back in their places")

	# The gate: Jason climbs the gatehouse for the bar, then Julia pulls the ring.
	check(not node("GateRing").is_available(), "the gate is barred")
	await move_me(Vector3(-4, 1, -21.8), 0.0)
	Input.action_press("move_forward")
	await until(func() -> bool: return local_pos().y > 6.2, "Jason climbs the gatehouse", 8)
	Input.action_release("move_forward")
	await move_me(Vector3(-2.8, 7.4, -23.6))
	await use("GateBar")
	gs().set_flag("test.ring")
	await until(func() -> bool: return gs().get_flag("garden.gate_open", false), "Julia opens the gate", 10)
	check(journal_ids("both").has("guardians"), "the guardians of time")

	# The corridor of death: a false flagstone, then the sound ones.
	await move_me(Vector3(0, 1, -25.3))
	await move_me(Vector3(-2, 1, -27))
	await wait(0.3)
	check(local_pos().z > -26.0, "a cracked flagstone tips Jason back")
	var safe := true
	for step in [Vector3(0, 1, -27), Vector3(-2, 1, -29), Vector3(2, 1, -31), Vector3(0, 1, -33), Vector3(-2, 1, -35)]:
		await move_me(step)
		safe = safe and local_pos().distance_to(step) < 0.6
	check(safe, "Julia's path across the flagstones")
	await move_me(Vector3(0, 1, -48))
	gs().set_flag("test.cloister")
	await move_me(Vector3(-1, 1, -55))
	await until(func() -> bool: return gs().get_flag("b5.cloister", false), "the cloister", 10)
	check(journal_ids("both").has("cloister") and node("Oblivia").visible and node("CloisterGate").visible, "the gate slams; Oblivia and Manfred")
	await until(func() -> bool: return toast().contains("End of book 5"), "end of book 5", 8)
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("test.ship", false), "the Metis", 30)
	await move_me(Vector3(0, -13.4, -52))
	await until(func() -> bool: return level_name() == "garden.tscn", "the Garden (client)", 20)
	await until(func() -> bool: return gs().get_flag("test.yard", false), "the yard", 20)
	await move_me(Vector3(1.2, 1, 5), 0.0)
	await until(func() -> bool: return gs().get_flag("test.ring", false), "the bar", 40)
	await move_me(Vector3(1.2, 1, -22.8))
	await use("GateRing")
	check(gs().get_flag("garden.gate_open", false), "Julia pulls the gate open")
	await move_me(Vector3(0.5, 1, -25.3))
	await use("CorridorWords")
	check(journal_ids("julia").has("false_stones") and not journal_ids("jason").has("false_stones"), "only Julia sees the cracks")
	await until(func() -> bool: return gs().get_flag("test.cloister", false), "to the cloister", 40)
	await move_me(Vector3(1, 1, -55))
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
