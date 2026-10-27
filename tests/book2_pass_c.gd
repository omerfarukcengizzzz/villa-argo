extends SceneTree
# Headless two-process test of book 2 Pass C. Usage: -s tests/book2_pass_c.gd -- host|client

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
	# Jason has the legend; Julia has the Owl key back, Door shut.
	for f in ["argo.rick_here", "argo.wardrobe_moved", "b2.started", "b2.away", "punt.disguised", "punt.wall_fell", "b2.split", "argo.night",
			"punt.maruk_free", "punt.guards_passed", "punt.map_shop", "punt.errands_given", "punt.delivered_sailor", "punt.delivered_doctor", "punt.legend"]:
		gs().set_flag(f)
	gs().set_flag("storm.phase", "fallen")
	for k in [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"]]:
		gs().give_item(k[0], k[1])
	gs().add_journal("door_backwards", "Ulysses's note in the archive", "...", "jason")
	game().change_level("res://scenes/levels/punt.tscn", "map_shop")
	await wait(0.5)
	game().move_twin("julia", "res://scenes/levels/villa_argo.tscn", "door")
	await wait(0.5)

	# Down to the corridors.
	await move_me(Vector3(-20.6, 1, -22.4))
	await use("StepsDown")
	await until(func() -> bool: return level_name() == "punt_corridors.tscn", "corridors loaded")
	await wait(0.3)
	check(lvl().position.x == 6000.0 and local_pos().distance_to(Vector3(0, 1, 5)) < 0.6, "Jason at the foot of the steps")
	check(not lvl().trace()[1] and lvl()._beam.get_child_count() > 0, "the light shines, but not into his eyes")

	# Step 10: three mirrors, three turns.
	var want := [3, 2, 1]
	for i in 3:
		var m: Node3D = node("Mirror%d" % i)
		await move_me(lvl().to_local(m.global_position) + Vector3(0, -0.5, 1.2))
		for t in 4:
			if m.facing() == want[i]:
				break
			await use("Mirror%d" % i)
	await wait(0.3)
	check(gs().get_flag("corr.solved", false) and toast().contains("Their eyes meet"), "the light joins the lovers' eyes")
	await wait(1.2)
	check(node("HiddenWall")._opened, "the hidden wall slides open")

	# Step 11: the room, the lamp, the snakes.
	await move_me(Vector3(-12, 1, -4.5))
	await wait(0.3)
	check(int(gs().get_flag("room.lamp", -1)) > 50 and toast().contains("gutters"), "the lamp starts to fail")
	var snake: Node3D = node("Snake1")
	me().global_position = snake.global_position
	await wait(0.3)
	check(local_pos().distance_to(Vector3(-11.6, 1, -4.5)) < 1.0 and toast().contains("snake"), "a snake sends Jason back to the door")
	gs().set_flag("room.lamp", 2)
	await until(func() -> bool: return toast().contains("lamp goes out"), "the lamp goes out", 5)
	await wait(0.3)
	check(local_pos().x > -10.5 and int(gs().get_flag("room.lamp", 0)) == -1, "back in the mirror hall in the dark")
	await move_me(Vector3(-12, 1, -4.5))
	await wait(0.3)
	check(int(gs().get_flag("room.lamp", -1)) > 50, "relit lamp burns again")

	# The sound key: MOON, SUN, STAR, SUN. One wrong strike first.
	var plate_z := {"SUN": -6.5, "MOON": -4.5, "STAR": -2.5}
	await move_me(Vector3(-20.9, 1, plate_z["SUN"]))
	await use("PlateSUN")
	check(toast().contains("jar") and str(gs().get_flag("room.seq", "")) == "", "wrong plate resets")
	for s in ["MOON", "SUN", "STAR", "SUN"]:
		await move_me(Vector3(-20.9, 1, plate_z[s]))
		await use("Plate" + s)
	check(gs().get_flag("room.solved", false) and node("Map").visible, "the altar opens: the map")

	# Step 12: Oblivia takes the map.
	await move_me(Vector3(-20.6, 1, -4.5))  # behind the altar, out of the snakes' way
	await use("Map")
	check(node("Oblivia").visible, "Oblivia steps out of the dark")
	await until(func() -> bool: return gs().get_flag("b2.map_taken", false), "the map is taken", 5)
	check(not gs().has_item("map") and journal_ids("jason").has("map_taken") and not journal_ids("julia").has("map_taken"), "map gone, Jason's entry")
	await until(func() -> bool: return not node("Oblivia").visible, "Oblivia leaves", 6)

	# Step 18: home, once Julia has opened the Door.
	await move_me(Vector3(0, 1, 6))
	await use("StepsUp")
	await until(func() -> bool: return level_name() == "punt.tscn", "back in Punt")
	await move_me(Vector3(-2, 1, -6.4))
	check(not node("DoorHome").is_available() and node("Rick").current_line().contains("still shut"), "the Door waits for Julia")
	check(node("Maruk").current_line().contains("go well"), "Maruk says goodbye")
	gs().set_flag("test.need_door")
	await until(func() -> bool: return gs().get_flag("argo_door.open", false), "Julia opens the Door", 40)
	await use("DoorHome")
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "Jason home", 5)
	await wait(0.5)
	check(game().together() and game()._levels.size() == 1 and lvl().visible, "both twins at Villa Argo again")
	check(gs().get_flag("b2.home", false) and not gs().get_flag("b2.split", true) and journal_ids("jason").has("home_again") and journal_ids("julia").has("home_again"), "home again, for both")
	check(node("Rick").visible and node("Nestor").current_line().contains("sunburnt"), "Rick is back; Nestor grumbles")
	await until(func() -> bool: return toast().contains("End of book 2"), "end of book 2", 8)
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "Julia at Villa Argo", 20)
	await until(func() -> bool: return gs().get_flag("test.need_door", false), "Jason at the Door in Punt", 200)
	await move_me(Vector3(10.9, 1, -5))
	var order := ["newt_key", "elephant_key", "porcupine_key", "owl_key"]
	for i in 4:
		await set_slot(i, order[i])
	check(gs().get_flag("argo_door.open", false), "Julia opens the Door backwards")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 40)
	check(game().together() and not lvl()._sun.light_energy < 0.5, "together again, and the storm is over")
	check(journal_ids("julia").has("home_again"), "Julia's journal: home again")
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
