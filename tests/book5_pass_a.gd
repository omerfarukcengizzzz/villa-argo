extends SceneTree
# Headless two-process test of book 5 Pass A. Usage: -s tests/book5_pass_a.gd -- host|client

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
	# End of book 4, at Villa Argo.
	for f in ["argo.met_nestor", "argo.footsteps", "argo.rick_here", "argo_door.open", "b2.home", "b3.started", "b3.escaped", "b4.started", "b4.home"]:
		gs().set_flag(f)
	for k in [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"], ["receipt", "post office receipt"]]:
		gs().give_item(k[0], k[1])
	await wait(0.5)

	# Step 1.
	await move_me(Vector3(4, 1, 18.5))
	await use("Nestor")
	check(gs().get_flag("b5.started", false) and journal_ids("both").has("b5_goal") and toast().contains("Book 5"), "book 5: find Black Vulcano")
	await move_me(Vector3(-0.8, 1, 24.5))
	gs().set_flag("test.gate")
	await until(func() -> bool: return _julia_near(Vector3(0, 1, 25)), "Julia at the gate")
	await use("GateToKilmoreCove")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Kilmore Cove")
	await move_me(Vector3(-23.6, 1, 11.4))
	await until(func() -> bool: return _julia_near(Vector3(-23, 1, 12.6)), "Julia at the school door")
	await use("SchoolDoor")
	await until(func() -> bool: return level_name() == "school.tscn", "school")
	await wait(0.4)

	# Step 2: the window only works while the teacher is at Julia's desk.
	await move_me(Vector3(-4.6, 1, 0))
	check(not node("ClassroomWindow").is_available(), "the teacher is watching: no slipping out")
	gs().set_flag("test.ask")
	await until(func() -> bool: return gs().get_flag("school.distracted", false), "Julia asks a question", 20)
	await use("ClassroomWindow")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Jason out in the village", 5)
	check(gs().get_flag("b5.jason_out", false) and game().level_for("julia").scene_file_path.ends_with("school.tscn"), "Jason out; Julia still in class")

	# Step 3: Minaxo and the Great Summer.
	await move_me(Vector3(-30, 1, -29.4))
	await use("Minaxo")
	check(journal_ids("both").has("great_summer"), "the Great Summer of 1958")
	await until(func() -> bool: return gs().get_flag("b5.dad_walk", false), "Dad appears", 5)

	# Step 4: Dad sees Jason; then Jason hides in Chubber's.
	await wait(0.5)
	var dad: Node3D = node("Dad")
	var forward := -dad.global_transform.basis.z
	forward.y = 0
	me().global_position = dad.global_position + forward.normalized() * 3.0
	await until(func() -> bool: return toast().contains("dive behind a wall"), "Dad spots Jason", 4)
	await wait(0.3)
	check(local_pos().distance_to(Vector3(-30, 1, -29)) < 1.0, "Jason runs back toward the lighthouse")
	await until(func() -> bool: return dad_at(0) or dad_at(1), "Dad at the far end", 30)
	await move_me(Vector3(-36, 1, -4))
	await use("HideInChubbers")
	await until(func() -> bool: return gs().get_flag("b5.dad_gone", false), "Dad walks on by", 10)
	check(toast().contains("restroom window"), "Dad's gone; back through the restroom window")

	# Step 4: back in, and caught.
	await move_me(Vector3(-18.5, 1, 12.0), PI)
	Input.action_press("move_forward")
	await until(func() -> bool: return local_pos().y > 3.3, "Jason climbs to the restroom window", 8)
	Input.action_release("move_forward")
	await move_me(Vector3(-18.5, 3.4, 12.9))
	await use("RestroomWindow")
	await until(func() -> bool: return level_name() == "school.tscn", "back in school", 5)
	await wait(0.4)
	check(gs().get_flag("b5.confiscated", false) and keys_held() == 0 and journal_ids("both").has("confiscated"), "caught: the keys are confiscated")
	check(game().together(), "together again in school")

	# Step 5: the office. Caught while he's at his desk...
	me().global_position = lvl().to_global(Vector3(10, 1, 0))
	await until(func() -> bool: return toast().contains("MR COVENANT"), "the headteacher sees Jason", 4)
	await wait(0.3)
	check(local_pos().x > 14, "Jason's back out in the yard")
	gs().set_flag("test.talk")
	await until(func() -> bool: return int(gs().get_flag("school.talk_step", 0)) >= 1, "Julia keeps him talking", 30)
	await wait(1.5)
	await move_me(Vector3(9, 1, -2.4))
	await use("ConfiscatedDrawer")
	check(gs().get_flag("b5.recovered", false) and keys_held() == 4, "the keys are back")
	check(node("Rick").current_line().contains("Fred"), "Rick: Fred and the station next")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("test.gate", false), "to the gate", 20)
	await move_me(Vector3(0.8, 1, 24.5))
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Kilmore Cove (client)", 20)
	await move_me(Vector3(-22.4, 1, 11.4))
	await until(func() -> bool: return level_name() == "school.tscn", "school (client)", 20)
	await until(func() -> bool: return gs().get_flag("test.ask", false), "Jason at the window", 20)
	await move_me(Vector3(3, 1, 4.2))
	node("AskQuestion").submit("...about the old railway")
	await until(func() -> bool: return gs().get_flag("b5.jason_out", false), "Jason slips out", 10)
	check(toast().contains("Jason's desk is empty"), "Julia covers for him")

	await until(func() -> bool: return gs().get_flag("test.talk", false), "time to talk", 120)
	await move_me(Vector3(10, 1, 8.6))
	node("TalkToHead").submit("Nothing, sir.")
	await wait(0.4)
	check(toast().contains("Back to your classroom") and not gs().get_flag("school.talking", false), "a wrong answer sends him back")
	for a in ["I wanted to ask about a school trip, sir.", "The lighthouse: Mr Minaxo could show us how the lamp works.", "Calypso from the bookshop said she'd help."]:
		node("TalkToHead").submit(a)
		await wait(0.5)
	check(int(gs().get_flag("school.talk_step", 0)) == 3, "three right answers")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
