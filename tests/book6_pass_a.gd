extends SceneTree
# Headless two-process test of book 6 Pass A. Usage: -s tests/book6_pass_a.gd -- host|client

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


## A street cell of the maze (row, column), in maze_town coordinates.
func cell(r: int, c: int) -> Vector3:
	return Vector3((c - 5) * 3.0, 1, (r - 8) * 3.0)


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	# End of book 5: shut in the cloister.
	for f in ["argo.met_nestor", "argo_door.open", "b2.home", "b3.started", "b3.escaped", "b4.started", "b4.home",
			"b5.started", "b5.recovered", "b5.train_awake", "b5.oblivia_ahead", "b5.sailed", "b5.away", "garden.arrived", "garden.bar", "garden.gate_open"]:
		gs().set_flag(f)
	game().change_level("res://scenes/levels/garden.tscn")
	await until(func() -> bool: return level_name() == "garden.tscn", "the Garden")
	await move_me(Vector3(-1, 1, -56))
	gs().set_flag("test.cloister")
	await until(func() -> bool: return gs().get_flag("b5.cloister", false), "the cloister", 10)

	# Step 1: book 6 starts; Oblivia and Manfred have gone.
	await until(func() -> bool: return gs().get_flag("b6.started", false), "book 6 starts", 15)
	check(toast().contains("Book 6") and journal_ids("both").has("b6_start") and not node("Oblivia").visible, "book 6: Oblivia and Manfred slip away")
	await move_me(Vector3(-0.8, 1, -69.6))
	gs().set_flag("test.door")
	await until(func() -> bool: return _julia_near(Vector3(0.8, 1, -69.6)), "Julia at the small door")
	await use("CloisterDoor")
	await until(func() -> bool: return level_name() == "maze_town.tscn", "the maze-town")
	await wait(0.4)
	check(toast().contains("watchtower"), "a town of crooked houses")

	# Step 2: Jason climbs the watchtower, sees the way, raises the portcullis.
	check(node("Portcullis").visible, "the portcullis is down")
	await move_me(Vector3(-9, 1, 9), 0.0)
	Input.action_press("move_forward")
	await until(func() -> bool: return local_pos().y > 12.0, "Jason climbs the watchtower", 10)
	Input.action_release("move_forward")
	await move_me(Vector3(-9, 13.4, 7))
	await use("RooftopView")
	check(journal_ids("jason").has("rooftops") and not journal_ids("julia").has("rooftops"), "only Jason sees the way from above")
	await use("PortcullisWinch")
	check(not node("Portcullis").visible, "the portcullis goes up")
	gs().set_flag("test.walk")

	# Step 3: Julia reaches the square, and Manfred grabs her.
	await until(func() -> bool: return gs().get_flag("b6.caught", false), "Julia reaches the square", 30)
	await wait(0.4)
	check(journal_ids("both").has("julia_caught") and node("Manfred").visible, "Manfred locks Julia in the bell tower")
	check(toast().contains("shout from the square"), "Jason hears it")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("test.cloister", false), "the cloister (client)", 30)
	await move_me(Vector3(1, 1, -56))
	await until(func() -> bool: return gs().get_flag("test.door", false), "to the small door", 30)
	await move_me(Vector3(0.8, 1, -69.6))
	await until(func() -> bool: return level_name() == "maze_town.tscn", "the maze-town (client)", 20)
	await until(func() -> bool: return gs().get_flag("test.walk", false), "the way through", 40)
	# The way Jason called out, cell by cell, walking for real between them.
	var path := [[8, 5], [7, 5], [7, 4], [7, 3], [6, 3], [5, 3], [4, 3], [3, 3], [3, 4], [3, 5], [2, 5], [1, 5]]
	var ok := true
	await move_me(cell(8, 5) + Vector3(0, 0, 1.5))
	for step in path:
		var target: Vector3 = cell(step[0], step[1])
		var t := 0.0
		while Vector2(local_pos().x - target.x, local_pos().z - target.z).length() > 0.4 and t < 6.0:
			var d: Vector3 = lvl().to_global(target) - me().global_position
			me().rotation.y = atan2(-d.x, -d.z)
			Input.action_press("move_forward")
			await wait(0.05)
			t += 0.05
		Input.action_release("move_forward")
		ok = ok and t < 6.0
	check(ok, "Julia walks the streets Jason called out")
	await move_me(Vector3(0, 1, -29))
	await wait(0.5)
	check(local_pos().distance_to(Vector3(0, 1, -40)) < 1.0, "Julia is shut in the tower")
	check(toast().contains("door won't move"), "alone in a little stone room")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
