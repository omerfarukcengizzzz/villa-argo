extends SceneTree
# Headless two-process test of book 2 Pass B. Usage: -s tests/book2_pass_b.gd -- host|client

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
	# End of book 2 Part 1: in Punt, disguised, the wall has fallen.
	for f in ["argo.rick_here", "argo.wardrobe_moved", "b2.started", "punt.disguised", "punt.wall_fell"]:
		gs().set_flag(f)
	for k in [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"]]:
		gs().give_item(k[0], k[1])
	gs().add_journal("mastaba", "Mastaba", "...")
	game().change_level("res://scenes/levels/punt.tscn")
	await wait(0.5)
	gs().set_flag("b2.split")
	gs().set_flag("argo.night")
	game().move_twin("julia", "res://scenes/levels/villa_argo.tscn", "door")
	gs().set_flag("test.split")
	await wait(0.5)

	# Step 5 before step 4: the guards won't let strangers in alone.
	await move_me(Vector3(11.2, 1, -23))
	await use("Micerinus")
	check(toast().contains("Nobody enters") and not gs().get_flag("punt.guards_passed", false), "guards refuse without Maruk")

	# Step 4: Maruk.
	check(node("Rick").current_line().contains("calling for help"), "Rick hears Maruk")
	await move_me(Vector3(8.6, 1, -24.9))
	await use("Beam")
	check(gs().get_flag("punt.maruk_free", false) and toast().contains("I am Maruk"), "Jason frees Maruk")
	check(journal_ids("jason").has("maruk") and not journal_ids("julia").has("maruk"), "Maruk entry is Jason's")

	# Step 5: Maruk talks the guards round.
	await move_me(Vector3(11.2, 1, -23))
	await use("Micerinus")
	check(gs().get_flag("punt.guards_passed", false) and toast().contains("step aside"), "guards let them in")
	await wait(1.2)
	check(node("HouseOfLifeDoor")._opened, "House of Life door open")

	# Step 6: the archive.
	await move_me(Vector3(17.8, 1, -29))
	await use("MetisDrawing")
	check(journal_ids("jason").has("metis_drawing"), "drawing of the Metis")
	await move_me(Vector3(26.7, 1, -20), -PI / 2)
	Input.action_press("move_forward")
	await until(func() -> bool: return local_pos().y > 5.6, "Jason climbs to the niche", 8)
	await wait(0.4)
	Input.action_release("move_forward")
	await wait(0.6)
	await move_me(Vector3(28.9, 5.9, -20))
	await use("ArchiveNote")
	check(journal_ids("jason").has("door_backwards") and not journal_ids("julia").has("door_backwards"), "Ulysses's archive note is Jason's")
	check(node("Rick").current_line().contains("ask it backwards"), "Rick: tell Julia")

	# Step 7: Oblivia in the market.
	await move_me(Vector3(-12, 1, -30))
	await use("Oblivia")
	check(journal_ids("jason").has("oblivia_market"), "Jason sees the woman with the lighters")

	# Pacing: Julia's storm waits until Jason reaches the map shop.
	await until(func() -> bool: return gs().has_journal("sound_key_notes"), "Julia reads the notes", 20)
	await wait(4.0)
	check(str(gs().get_flag("storm.phase", "")) == "", "storm waits for Jason")

	# Step 8: the map shop and the errands.
	await move_me(Vector3(-17.5, 1, -23.3))
	await use("MapSeller")
	check(gs().has_item("parcel") and gs().has_item("ointment") and gs().get_flag("punt.map_shop", false), "errands given")
	await wait(0.4)
	check(not node("Oblivia").visible, "Oblivia was there first, and is gone")
	await until(func() -> bool: return str(gs().get_flag("storm.phase", "")) == "arriving", "storm starts at Villa Argo", 3)
	await use("MapSeller")
	check(not gs().get_flag("punt.legend", false), "no legend before the errands")
	await move_me(Vector3(-3.5, 1, 3.2))
	await use("Sailor")
	await move_me(Vector3(-9, 1, -34.8))
	await use("Doctor")
	check(gs().get_flag("punt.delivered_sailor", false) and gs().get_flag("punt.delivered_doctor", false) and not gs().has_item("parcel") and not gs().has_item("ointment"), "both errands delivered")

	# Step 9: the legend and the Ballad.
	await move_me(Vector3(-17.5, 1, -23.3))
	await use("MapSeller")
	check(gs().get_flag("punt.legend", false) and journal_ids("jason").has("ballad") and not journal_ids("julia").has("ballad"), "the Ballad is Jason's")
	await wait(2.0)
	check(node("Talos").position.distance_to(Vector3(-22.8, 0.4, -24)) < 0.2, "Talos moves aside")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("test.split", false) and level_name() == "villa_argo.tscn", "Julia at Villa Argo", 20)
	await wait(0.5)
	await move_me(Vector3(-8, 1, -2.6))
	await use("BalladNotes")
	await use("SoundKeyNotes")
	check(journal_ids("julia").has("ballad_notes"), "Julia reads Ulysses's notes")
	await until(func() -> bool: return str(gs().get_flag("storm.phase", "")) != "", "storm (client)", 90)
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 60)
	var punt := ["maruk", "metis_drawing", "door_backwards", "oblivia_market", "ballad"]
	check(punt.all(func(id: String) -> bool: return not journal_ids("julia").has(id)), "none of Jason's Punt entries in Julia's journal")
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
