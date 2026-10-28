extends SceneTree
# Headless two-process test of book 6 Pass C. Usage: -s tests/book6_pass_c.gd -- host|client

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


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	# End of book 6 Pass B: Rick is on the train; Jason knows about the knot.
	for f in ["argo.met_nestor", "argo.rick_here", "argo_door.open", "b2.home", "b3.started", "b3.escaped", "b4.started", "b4.home",
			"b5.started", "b5.met_minaxo", "b5.recovered", "b5.station_open", "b5.train_awake", "b5.oblivia_ahead", "b5.sailed", "b5.away", "b5.cloister",
			"b6.started", "maze.arrived", "maze.portcullis", "b6.caught", "b6.playing_rick", "b6.photo", "b6.met_ulysses", "b6.father", "b6.horse_open",
			"b6.met_vulcano", "b6.knot_known"]:
		gs().set_flag(f)
	gs().add_journal("nestor_is_ulysses", "Rick: Nestor is Ulysses Moore", "...", "julia")
	game().change_level("res://scenes/levels/maze_town.tscn")
	await until(func() -> bool: return level_name() == "maze_town.tscn", "the maze-town")
	await wait(0.5)
	gs().set_flag("b6.rick_ready")

	# Step 13: the train bursts into the square, with Rick and Ulysses.
	await until(func() -> bool: return gs().get_flag("b6.arrived", false), "the train arrives", 8)
	await wait(0.4)
	check(toast().contains("My name is Ulysses Moore") and journal_ids("jason").has("ulysses_jason") and node("Ulysses").visible, "Jason sees Nestor get off the train")

	# Step 14: a sword from the guards' rack; the knot, cut the right way.
	await move_me(Vector3(49, 1, -15.8))
	await use("Sword")
	check(gs().has_item("blade"), "a guard's sword")
	await move_me(Vector3(1.2, 1, -34.8))
	node("CutKnot").submit("Hack at it as hard as you can, again and again")
	await wait(0.3)
	check(toast().contains("Ask Rick") and not gs().get_flag("b6.knot_cut", false), "the knot just pulls tighter")
	await until(func() -> bool: return journal_ids("julia").has("knot_legend"), "Rick reads the legend", 20)
	node("CutKnot").submit("Straight through the middle, in one stroke")
	await wait(0.4)
	check(gs().get_flag("b6.knot_cut", false) and not gs().get_flag("b6.playing_rick", false) and node("Rick").visible, "Julia is free; Rick is Rick again")
	check(journal_ids("jason").has("nestor_is_ulysses") and journal_ids("jason").has("reunited"), "one journal again")

	# Step 15: the truth, with everyone there.
	await move_me(Vector3(46, 1, -45.6))
	await use("BlackVulcano")
	check(not gs().get_flag("b6.truth", false), "not without Julia")
	gs().set_flag("test.court")
	await until(func() -> bool: return _julia_near(Vector3(47.5, 1, -45.6)), "Julia in the court", 20)
	await use("BlackVulcano")
	check(gs().get_flag("b6.truth", false) and journal_ids("both").has("truth") and toast().contains("I quit"), "the truth: nobody ever found the First Key")

	# Home on the train.
	await move_me(Vector3(-14.5, 1, -37))
	gs().set_flag("test.home")
	await until(func() -> bool: return _julia_near(Vector3(-14.5, 1, -36.8)), "Julia at the train", 20)
	await use("TrainHome")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "home to Kilmore Cove", 5)
	await wait(0.5)
	check(gs().get_flag("b6.home", false) and node("Fred").visible, "home")

	# Step 16: the epilogue.
	await move_me(Vector3(-26, 1, 13))
	await until(func() -> bool: return gs().get_flag("b6.manfred_gone", false), "Manfred and Gwendaline", 5)
	check(journal_ids("both").has("manfred_punt") and toast().contains("Cat Door"), "off to Punt through the Cat Door")
	await move_me(Vector3(-29.4, 1, -28.2))
	node("NudgeMinaxo").submit("Tell Calypso he's been practising for forty years")
	await wait(0.3)
	check(journal_ids("both").has("minaxo_calypso"), "Minaxo and Calypso")
	gs().set_flag("test.rick")
	await until(func() -> bool: return gs().get_flag("b6.end", false), "the end", 30)
	await until(func() -> bool: return toast().contains("End of book 6"), "end of book 6", 8)
	check(journal_ids("both").has("julia_rick") and journal_ids("both").has("the_end"), "the end of book 6")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("b6.arrived", false), "the train arrives (client)", 30)
	await wait(0.5)
	check(toast().contains("anything for a camera") and gs().get_flag("b6.playing_rick", false), "Rick watches Jason's face")
	await move_me(Vector3(-1.5, 1, -34.8))
	await use("KnotLegend")
	check(journal_ids("julia").has("knot_legend"), "Rick: Alexander cut it through the middle")
	await until(func() -> bool: return gs().get_flag("b6.knot_cut", false), "the knot is cut", 30)
	await wait(0.4)
	check(local_pos().distance_to(Vector3(0, 1, -38.5)) < 1.0 and toast().contains("JULIA again"), "Julia again, in the tower doorway")
	await until(func() -> bool: return gs().get_flag("test.court", false), "to the court", 30)
	await move_me(Vector3(47.5, 1, -45.6))
	await until(func() -> bool: return gs().get_flag("test.home", false), "to the train", 30)
	await move_me(Vector3(-14.5, 1, -36.8))
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Kilmore Cove (client)", 20)
	await until(func() -> bool: return gs().get_flag("test.rick", false), "Rick", 40)
	await until(func() -> bool: return node("Rick").position.distance_to(Vector3(-21, 1, 4)) < 0.5, "Rick walks over", 15)
	await move_me(Vector3(-21, 1, 5.3))
	await use("Rick")
	check(journal_ids("julia").has("julia_rick"), "a walk along the harbour")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
