extends SceneTree
# Headless two-process test of book 3 Pass C. Usage: -s tests/book3_pass_c.gd -- host|client

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
	for f in ["argo.rick_here", "b2.home", "b3.started", "b3.marks", "b3.dedalus", "clock.solved", "phone.solved", "chess.solved"]:
		gs().set_flag(f)
	gs().set_flag("chess.step", 3)
	game().change_level("res://scenes/levels/mirror_house.tscn")
	await wait(0.6)

	# Step 11's last notes start the finale.
	await move_me(Vector3(-12, 1, -31.8))
	await use("Notebooks")
	await use("Photograph")
	check(str(gs().get_flag("b3.phase", "")) == "crew" and gs().has_item("dedalus_notebook") and toast().contains("hide"), "engines outside: hide!")
	check(not node("ExitToVillage").is_available(), "no leaving while Oblivia is coming")

	# Step 13: hide and watch.
	await move_me(Vector3(-12, 1, -34.6))
	await use("HideDesk")
	await until(func() -> bool: return str(gs().get_flag("b3.phase", "")) == "oblivia", "Julia hides too", 20)
	await wait(0.4)
	check(node("Oblivia").visible and node("Manfred").visible, "Oblivia and Manfred walk in")
	await until(func() -> bool: return gs().get_flag("lion.open", false), "the Lion Door opens", 8)
	check(not lvl()._lion.visible, "the mirror swings open")
	await until(func() -> bool: return gs().has_journal("lion_door"), "Oblivia goes through", 8)
	await wait(0.5)
	check(not node("Oblivia").visible and toast().contains("Bring it down"), "she's gone; Manfred orders the demolition")

	# Step 12: the race. Running out of time first.
	await until(func() -> bool: return str(gs().get_flag("b3.phase", "")) == "race", "the race starts", 8)
	check(lvl()._lion.visible, "the Lion Door is shut again")
	await move_me(Vector3(0, 1, -20))
	gs().set_flag("race.left", 2)
	await until(func() -> bool: return toast().contains("come round in the study"), "time runs out", 5)
	await wait(0.4)
	check(local_pos().distance_to(Vector3(-17, 1, -31)) < 1.0 and int(gs().get_flag("race.left", 0)) > 140, "back in the study, clock reset")
	var plaster: Node3D = node("Plaster0")
	me().global_position = plaster.global_position
	await wait(0.3)
	check(toast().contains("Plaster crashes") and local_pos().distance_to(Vector3(-16, 1, -26.5)) < 1.0, "falling plaster knocks Jason back")

	# Out through the front, both together.
	await move_me(Vector3(-0.8, 1, 4.5))
	gs().set_flag("test.out")
	await until(func() -> bool: return _julia_near(Vector3(0, 1, 5)), "Julia in the hall", 20)
	await use("ExitToVillage")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "out in the village", 5)
	await wait(1.5)
	check(gs().get_flag("b3.escaped", false) and journal_ids("both").has("book3_end"), "escaped; what we know now")
	check(lvl()._ruins.visible and not node("MirrorHouseDoor").is_available(), "half the house is rubble")
	check(node("Minaxo").position.distance_to(Vector3(36, 1, -12)) < 0.5 and node("Calypso").current_line().contains("mended"), "Minaxo and Calypso came running")
	check(node("Rick").current_line().contains("Venice"), "Rick: Venice next")
	await until(func() -> bool: return toast().contains("End of book 3"), "end of book 3", 8)
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return level_name() == "mirror_house.tscn", "inside (client)", 20)
	await until(func() -> bool: return str(gs().get_flag("b3.phase", "")) == "crew", "hide (client)", 20)
	await move_me(Vector3(-9.6, 1, -35.5))
	await use("HideCurtain")
	check(gs().get_flag("hide.julia", false), "Julia hides behind the curtain")
	await until(func() -> bool: return gs().get_flag("test.out", false), "race (client)", 60)
	await move_me(Vector3(0.8, 1, 4.5))
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	check(level_name() == "kilmore_cove.tscn" and journal_ids("julia").has("lion_door"), "Julia saw the Lion Door too")
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
