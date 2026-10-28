extends SceneTree
# Headless two-process test of book 6 Pass B. Usage: -s tests/book6_pass_b.gd -- host|client

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
	# End of book 6 Pass A: Julia caught.
	for f in ["argo.met_nestor", "argo.rick_here", "argo_door.open", "b2.home", "b3.started", "b3.escaped", "b4.started", "b4.home",
			"b5.started", "b5.met_minaxo", "b5.recovered", "b5.station_open", "b5.train_awake", "b5.oblivia_ahead", "b5.sailed", "b5.away", "b5.cloister",
			"b6.started", "maze.arrived", "maze.portcullis", "b6.caught"]:
		gs().set_flag(f)
	gs().give_item("receipt", "post office receipt")
	game().change_level("res://scenes/levels/maze_town.tscn")
	await until(func() -> bool: return level_name() == "maze_town.tscn", "the maze-town")

	# Step 4: the split. Julia's player becomes Rick, in Kilmore Cove.
	await until(func() -> bool: return gs().get_flag("b6.playing_rick", false), "the split", 10)
	await wait(0.5)
	check(game().level_for("julia").scene_file_path.ends_with("villa_argo.tscn") and level_name() == "maze_town.tscn", "Rick at Villa Argo, Jason in the Garden")
	check(journal_ids("jason").has("jason_alone") and not journal_ids("jason").has("rick_alone"), "each has his own story")

	# Step 10: the knot won't come undone; the guards.
	await move_me(Vector3(0, 1, -34.8))
	await use("TowerKnot")
	check(toast().contains("Get me OUT"), "Julia, muffled, behind the door")
	var guard: Node3D = node("Guard0")
	var forward := -guard.global_transform.basis.z
	forward.y = 0
	me().global_position = guard.global_position + forward.normalized() * 3.0
	await until(func() -> bool: return toast().contains("HALT"), "a guard spots Jason", 4)
	await wait(0.3)
	check(local_pos().distance_to(Vector3(19, 1, -32)) < 1.0, "marched back out of the court")

	# Step 11-12: Black Vulcano.
	await move_me(Vector3(47, 1, -46.6))
	await use("BlackVulcano")
	check(journal_ids("jason").has("vulcano_truth") and journal_ids("jason").has("gordian") and toast().contains("never had it"), "Black Vulcano: nobody ever had the First Key")
	check(not journal_ids("julia").has("vulcano_truth"), "Rick doesn't know yet")
	await move_me(Vector3(0, 1, -34.8))
	await use("TowerKnot")
	check(toast().contains("nothing to cut"), "the Gordian knot: it needs cutting")

	await until(func() -> bool: return gs().get_flag("b6.rick_ready", false), "Rick boards the train", 120)
	check(not journal_ids("jason").has("nestor_is_ulysses") and not journal_ids("jason").has("ulysses") and not toast().contains("Rick Banner"), "Jason still doesn't know about Nestor")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("b6.playing_rick", false) and level_name() == "villa_argo.tscn", "Rick at Villa Argo", 40)
	await wait(0.4)
	check(toast().contains("You are RICK") and journal_ids("julia").has("rick_alone"), "playing Rick")

	# Steps 5-6: the cottage and the photo.
	check(not node("CottageWindow").is_available(), "the window's too high")
	await move_me(Vector3(14.6, 1, 16.8))
	await use("RainBarrel")
	await move_me(Vector3(15.3, 1, 21))
	await use("CottageWindow")
	await wait(0.4)
	check(local_pos().x < 13.3 and local_pos().x > 8.7, "Rick climbs in")
	await move_me(Vector3(9.8, 1, 21.2))
	await use("CottageThings")
	await move_me(Vector3(12.3, 1, 21.2))
	await use("Letters")
	await move_me(Vector3(9.6, 1, 18.9))
	await use("PhotoHalf")
	check(journal_ids("julia").has("cottage") and journal_ids("julia").has("letters_u") and journal_ids("julia").has("photo_half"), "a captain's coat, letters signed U., the other half")
	await move_me(Vector3(11, 1, 19.4))
	node("JoinPhoto").submit("The big one in the railwayman's cap")
	await wait(0.4)
	check(toast().contains("not him") and not gs().get_flag("b6.photo", false), "wrong face")
	node("JoinPhoto").submit("The tall one in the sailor's jersey")
	await wait(0.4)
	check(journal_ids("julia").has("nestor_is_ulysses") and node("Nestor").visible, "Nestor IS Ulysses Moore")

	# Step 7: Ulysses.
	await use("Nestor")
	check(journal_ids("julia").has("ulysses") and node("CottageDoor").is_open(), "\"Yes. I'm Ulysses Moore.\"")

	# Step 8: Minaxo.
	await move_me(Vector3(0.8, 1, 24.5))
	await use("GateToKilmoreCove")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Rick in Kilmore Cove", 5)
	await move_me(Vector3(-30, 1, -29.4))
	await use("Minaxo")
	check(journal_ids("julia").has("rick_father"), "Minaxo: Rick's father")

	# Step 9: the station, the Horse key, the train.
	await move_me(Vector3(22.6, 1, 3.6))
	await use("StationDoor")
	await until(func() -> bool: return level_name() == "station.tscn", "the station", 5)
	await move_me(Vector3(10.5, 1, -17.2))
	await use("Ulysses")
	check(gs().get_flag("b6.horse_open", false) and journal_ids("julia").has("horse_key"), "the Horse key")
	await move_me(Vector3(7.2, 1, -18.6))
	await use("BoardTrain")
	check(gs().get_flag("b6.rick_ready", false) and toast().contains("Horse Door"), "through the Horse Door")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
