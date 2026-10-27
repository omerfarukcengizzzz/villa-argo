extends SceneTree
# Headless two-process test of book 3 Pass A. Usage: -s tests/book3_pass_a.gd -- host|client

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


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	# End of book 2: home at Villa Argo.
	for f in ["argo.met_nestor", "argo.footsteps", "argo.rick_here", "argo.cliff_gate_open", "argo.wardrobe_moved", "argo_door.open", "b2.started", "b2.home"]:
		gs().set_flag(f)
	gs().give_item("receipt", "post office receipt")
	gs().add_journal("maruk", "Maruk", "...", "jason")
	gs().add_journal("ballad_notes", "Ulysses's copy of the Ballad", "...", "julia")
	await wait(0.5)

	# Steps 1-2: breakfast.
	await move_me(Vector3(4, 1, 18.5))
	await use("Nestor")
	check(gs().get_flag("b3.started", false) and toast().contains("Book 3"), "breakfast starts book 3")
	check(journal_ids("julia").has("maruk") and journal_ids("jason").has("ballad_notes"), "journals shared")
	check(journal_ids("jason").has("map_memory") and not journal_ids("julia").has("map_memory"), "Jason's memory of the map is his")
	check(journal_ids("both").has("lost_in_translation"), "Egyptian is gibberish now")

	await move_me(Vector3(-0.8, 1, 24.5))
	await until(func() -> bool: return _julia_near(Vector3(0, 1, 25)), "Julia at the gate")
	await use("GateToKilmoreCove")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Kilmore Cove")
	await wait(0.4)
	check(node("Rick").visible and node("Rick").current_line().contains("make a list"), "Rick suggests a list")

	# Step 3, Jason's part: the statue, the tunnel, the phone.
	await move_me(Vector3(-26, 1, 2.2))
	Input.action_press("move_forward")
	await until(func() -> bool: return local_pos().y > 3.6, "Jason climbs the plinth", 8)
	await wait(0.3)
	Input.action_release("move_forward")
	await move_me(Vector3(-26, 3.9, -0.4))
	await use("Inscription")
	check(journal_ids("both").has("king_inscription"), "the worn inscription")
	await move_me(Vector3(50.8, 1, 0))
	await use("Tunnel")
	await move_me(Vector3(-15, 1, 4.8))
	await use("Phone")
	check(gs().get_flag("b3.tracks", false) and gs().get_flag("b3.no_signal", false), "tracks to nowhere; no signal")
	gs().set_flag("test.king")

	# Julia does the books (client). Then Calypso and the guide.
	await until(func() -> bool: return gs().get_flag("b3.no_maps", false) and gs().get_flag("b3.king", false), "Julia's two", 30)
	var list: String = gs().journal.filter(func(e: Dictionary) -> bool: return e["id"] == "kilmore_wrong")[0]["body"]
	check(list.count("[x]") == 4 and list.contains("Calypso"), "the checklist is complete")
	await move_me(Vector3(-20, 1, -5.6))
	await use("Calypso")
	check(gs().has_item("tourist_guide") and journal_ids("julia").has("tourist_guide") and not journal_ids("jason").has("tourist_guide"), "Calypso's guide, for Julia's eyes")

	# Step 5 is Julia's. Step 6: the old residents.
	await until(func() -> bool: return gs().get_flag("b3.marks", false), "the three marks", 30)
	check(journal_ids("both").has("three_marks"), "three marks entry")
	await move_me(Vector3(-30, 1, -29.6))
	await use("Minaxo")
	check(toast().contains("Dedalus"), "Minaxo talks about Dedalus")
	await move_me(Vector3(-30, 1, 10.2))
	await use("MissBiggles")
	check(toast().contains("Clio"), "Miss Biggles mentions her sister")
	check(not gs().get_flag("b3.dedalus", false), "not yet: Calypso")
	await move_me(Vector3(-20, 1, -5.6))
	await use("Calypso")
	check(gs().get_flag("b3.dedalus", false) and journal_ids("both").has("dedalus"), "Peter Dedalus entry")
	await wait(1.5)
	check(node("Rick").current_line().contains("locked"), "Rick: the House of Mirrors is locked, for now")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("b3.started", false), "breakfast (client)", 20)
	await move_me(Vector3(0.8, 1, 24.5))
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Julia in Kilmore Cove", 40)
	await move_me(Vector3(-22, 1, -7.6))
	await use("Atlases")
	check(gs().get_flag("b3.no_maps", false), "no maps")
	await until(func() -> bool: return gs().get_flag("test.king", false), "Jason read the statue", 40)
	await move_me(Vector3(-18, 1, -7.6))
	await use("HistoryOfKings")
	check(gs().get_flag("b3.king", false), "no King William V")
	await until(func() -> bool: return gs().has_item("tourist_guide"), "the guide", 30)
	await move_me(Vector3(-19, 1, -5.0))
	node("GuideTable").submit("1 2 3")
	await wait(0.4)
	check(toast().contains("not how the marks looked") and not gs().get_flag("b3.marks", false), "wrong landmarks rejected")
	node("GuideTable").submit("8, 6 and 3")
	await until(func() -> bool: return gs().get_flag("b3.marks", false), "marks accepted")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	check(journal_ids("julia").has("kilmore_wrong") and journal_ids("julia").has("dedalus"), "Julia's journal has the investigation")
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
