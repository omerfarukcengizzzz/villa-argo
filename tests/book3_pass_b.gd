extends SceneTree
# Headless two-process test of book 3 Pass B. Usage: -s tests/book3_pass_b.gd -- host|client

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


## True if a ray at chest height between two level-local points hits nothing.
func clear_between(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(lvl().to_global(a + Vector3(0, 1, 0)), lvl().to_global(b + Vector3(0, 1, 0)))
	for p in game().get_players():
		q.exclude = q.exclude + [p.get_rid()]
	return lvl().get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	for f in ["argo.rick_here", "b2.home", "b3.started", "b3.no_maps", "b3.no_signal", "b3.tracks", "b3.king", "b3.marks", "b3.dedalus"]:
		gs().set_flag(f)
	gs().give_item("tourist_guide", "old tourist guide")
	game().change_level("res://scenes/levels/kilmore_cove.tscn", "mirror_house")
	await wait(0.6)
	await move_me(Vector3(32.5, 1, -14))
	await until(func() -> bool: return _julia_near(Vector3(33, 1, -14.8)), "Julia at the door")
	await use("MirrorHouseDoor")
	await until(func() -> bool: return level_name() == "mirror_house.tscn", "inside the House of Mirrors")
	await wait(0.4)

	# Step 7: the maze. The true path is open; other walls are real; each twin
	# sees only some of them.
	var path: Array = lvl().PATH
	var open := true
	for i in path.size() - 1:
		open = open and clear_between(lvl().cell_center(path[i]), lvl().cell_center(path[i + 1]))
	check(open, "the true path through the maze is open")
	check(not clear_between(lvl().cell_center(Vector2i(2, 4)), lvl().cell_center(Vector2i(3, 4))), "a wall off the path is solid")
	var mine := 0
	var theirs := 0
	for child in lvl().get_children():
		if child is MeshInstance3D and child.layers == 4:
			mine += 1
		elif child is MeshInstance3D and child.layers == 2:
			theirs += 1
	check(mine > 8 and theirs > 8, "each twin has walls the other can't see (%d / %d)" % [mine, theirs])
	gs().set_flag("test.maze")

	# Step 8: the owl clock.
	await move_me(Vector3(0, 1, -22.6))
	Input.action_press("move_forward")
	await until(func() -> bool: return local_pos().y > 5.5, "Jason climbs the cabinet", 8)
	await wait(0.3)
	Input.action_release("move_forward")
	await move_me(Vector3(0, 5.9, -24.1))
	for i in 4:
		await use("HourHand")
	await use("MinuteHand")
	check(gs().get_flag("clock.solved", false) and toast().contains("telephone"), "a quarter past four: the telephone rings")

	# Step 9 is Julia's. Step 10: the chess game.
	await until(func() -> bool: return gs().get_flag("phone.solved", false), "Julia dials", 30)
	await wait(1.2)
	check(node("ChessDoor")._opened, "the chess room opens")
	await move_me(lvl().square_pos("f1") + Vector3(0, 1, 0.9))
	node("WhiteBishop").submit("d3")
	await wait(0.3)
	check(int(gs().get_flag("chess.step", -1)) == 0 and toast().contains("slides back"), "a wrong move resets the board")
	node("WhiteBishop").submit("c4")
	await wait(0.3)
	check(int(gs().get_flag("chess.step", 0)) == 1 and toast().contains("b8 to c6"), "Bishop to c4; black answers")
	await move_me(lvl().square_pos("d1") + Vector3(0, 1, 0.9))
	node("WhiteQueen").submit("h5")
	await wait(0.3)
	check(node("WhiteQueen").options_for.call().any(func(o: Array) -> bool: return o[0] == "f7"), "the queen can reach f7")
	await move_me(lvl().square_pos("h5") + Vector3(0, 1, 0.9))
	node("WhiteQueen").submit("f7")
	await wait(0.3)
	check(gs().get_flag("chess.solved", false) and toast().contains("Checkmate"), "Queen takes f7: checkmate")
	await wait(1.2)
	check(node("StudyDoor")._opened and lvl().board_at(3).get("f7", "") == "wQ", "the study opens; the queen stands on f7")

	# Step 11: the study.
	await move_me(Vector3(-12, 1, -31.8))
	await use("Notebooks")
	await use("Photograph")
	check(gs().get_flag("b3.study_done", false) and journal_ids("both").has("other_doors") and journal_ids("both").has("venice_photo"), "other Doors, the First Key, and Venice")
	await wait(1.5)
	check(node("Rick").current_line().contains("Oblivia"), "Rick worries about Oblivia")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Kilmore Cove (client)", 20)
	await move_me(Vector3(33.5, 1, -14))
	await until(func() -> bool: return level_name() == "mirror_house.tscn", "inside (client)", 20)
	await wait(0.5)
	check(not me()._camera.get_cull_mask_value(3), "Julia's camera skips Jason's walls")
	var moves: Label3D = null
	for child in lvl().get_children():
		if child is Label3D and child.text.begins_with("In the mirror"):
			moves = child
	check(moves != null and moves.layers == 2, "the moves in the mirror are Julia's")
	await until(func() -> bool: return gs().get_flag("test.maze", false), "maze checked", 20)
	await move_me(Vector3(5, 1, -17.6))
	await until(func() -> bool: return gs().get_flag("clock.solved", false), "telephone rings (client)", 30)
	await use("Telephone")
	check(journal_ids("julia").has("dedalus_voice"), "Julia answers the telephone")
	node("Dial").submit("12")
	await wait(0.4)
	check(toast().contains("Wrong number"), "wrong number")
	node("Dial").submit("77")
	await until(func() -> bool: return gs().get_flag("phone.solved", false), "Kilmore Cove 77")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
