extends SceneTree
# Headless two-process test of book 2 Pass A. Usage: -s tests/book2_pass_a.gd -- host|client

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
	# End of book 1.
	for f in ["argo.met_nestor", "argo.footsteps", "argo.rick_here", "argo.cliff_gate_open", "argo.cipher_solved", "argo.wardrobe_moved", "argo_door.open", "metis.sailed", "b2.started"]:
		gs().set_flag(f)
	for i in 4:
		gs().set_flag("argo_door.slot%d" % i, ["owl_key", "porcupine_key", "elephant_key", "newt_key"][i])
	for k in [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"], ["clay", "box of glowing clay"]]:
		gs().give_item(k[0], k[1])
	game().change_level("res://scenes/levels/punt.tscn")
	await wait(0.5)
	check(level_name() == "punt.tscn" and lvl().position.x == 3000.0, "Punt loaded at its origin")
	check(local_pos().distance_to(Vector3(-1, 1, 8)) < 0.5, "Jason on the quay")

	# Step 1: guards turn strangers away; the chest of clothes.
	check(not node("GuardLine")._opened and node("Guard").current_line().contains("Strangers"), "guards block strangers")
	var before: Color = me()._body_mat.albedo_color
	await move_me(Vector3(3.5, 1, 7))
	await use("ClothesChest")
	await wait(1.2)
	check(gs().get_flag("punt.disguised", false) and node("GuardLine")._opened, "disguised; guards let us pass")
	check(me()._body_mat.albedo_color != before, "Jason wears local clothes")

	# Step 2: mastaba. Step 3: the wall.
	await move_me(Vector3(0, 1, -34.6))
	await use("Mastaba")
	check(journal_ids("both").has("mastaba"), "mastaba entry")
	gs().set_flag("test.go_town")
	await until(func() -> bool: return gs().get_flag("punt.wall_fell", false), "the wall collapses")
	check(toast().contains("collapses"), "the wall collapses (message)")

	# Julia runs through the Door; the twins are split.
	await until(func() -> bool: return gs().get_flag("b2.split", false), "split", 20)
	await wait(0.6)
	check(game().level_for("julia").scene_file_path.ends_with("villa_argo.tscn") and level_name() == "punt.tscn", "Julia at Villa Argo, Jason in Punt")
	check(game()._levels.size() == 2 and not game().level_for("julia").visible, "host keeps both levels, shows only Punt")
	check(not gs().get_flag("argo_door.open", true), "the Door is shut")
	gs().set_flag("punt.map_shop")  # Pass B: the storm waits for Jason at the map shop

	# Julia's half runs on the client; wait for her to reopen the Door.
	await until(func() -> bool: return gs().get_flag("argo_door.open", false), "Julia reopens the Door", 200)
	check(level_name() == "punt.tscn", "Jason still in Punt")
	await until(func() -> bool: return game().get_players().size() == 1, "client left", 20)
	await until(func() -> bool: return game().get_players().size() == 2, "client rejoined", 30)
	await wait(1.0)
	check(level_name() == "punt.tscn" and game().level_for("julia").scene_file_path.ends_with("villa_argo.tscn"), "after rejoin: still split")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return level_name() == "punt.tscn", "client in Punt", 20)
	await wait(0.5)
	check(local_pos().distance_to(Vector3(1, 1, 8)) < 0.5, "Julia on the quay")
	await until(func() -> bool: return gs().get_flag("test.go_town", false), "host at the mastaba", 30)
	await move_me(Vector3(1.5, 1, -33))
	await until(func() -> bool: return gs().get_flag("punt.wall_fell", false), "collapse (client)")
	check(node("Rick").current_line().contains("Back to the Door"), "Rick: back to the Door")
	await move_me(Vector3(-2.2, 1, -6))
	await use("TheDoor")
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "Julia arrives home", 10)
	await wait(0.5)
	check(game()._levels.size() == 1, "Julia's machine loads only her level")
	check(local_pos().distance_to(Vector3(10, 1, -4)) < 0.6, "Julia in the stone sitting room")
	check(not node("ArgoDoor")._opened and lvl()._sun.light_energy < 0.5, "Door shut, night")
	check(node("Nestor").current_line().contains("alone"), "Nestor finds Julia")

	# Step 14: Ulysses's notes.
	await move_me(Vector3(-8, 1, -2.6))
	await use("BalladNotes")
	await use("SoundKeyNotes")
	check(journal_ids("julia").has("ballad_notes") and journal_ids("julia").has("sound_key_notes"), "Julia reads Ulysses's notes")
	check(node("Nestor").current_line().contains("Penelope"), "Nestor mentions Penelope")

	# Step 15: the windows. Leave the first one open to see Manfred get in.
	await until(func() -> bool: return str(gs().get_flag("storm.phase", "")) == "windows", "Manfred arrives", 10)
	check(node("Manfred").visible, "Manfred appears")
	await until(func() -> bool: return toast().contains("Nestor drives him back out"), "open window lets him in", 10)
	check(int(gs().get_flag("storm.step", -1)) == 0, "round starts over")
	for i in 6:
		var w: Node3D = node("Window%d" % i)
		await move_me(lvl().to_local(w.global_position) + Vector3(0, -1, 0) + w.global_transform.basis.z * 0.9)
		await use("Window%d" % i)
	check(range(6).all(func(i: int) -> bool: return gs().get_flag("storm.window%d" % i, false)), "all windows shut")
	await until(func() -> bool: return str(gs().get_flag("storm.phase", "")) == "chase", "break-in and theft", 60)
	check(not gs().has_item("owl_key") and toast().contains("Owl key"), "Manfred steals the Owl key")

	# Step 16: the chase.
	await until(func() -> bool: return str(gs().get_flag("storm.phase", "")) == "edge", "Manfred at the cliff", 20)
	await move_me(Vector3(-21.8, 1, 0.5))
	await until(func() -> bool: return str(gs().get_flag("storm.phase", "")) == "fallen", "Manfred falls", 5)
	await wait(0.3)
	check(not node("Manfred").visible and node("DroppedOwlKey").visible, "Manfred gone, key on the rocks")
	await move_me(Vector3(-22.4, 1, 1.2))
	await use("DroppedOwlKey")
	check(gs().has_item("owl_key"), "Julia gets the Owl key back")

	# Step 17: the Door, backwards: N-E-P-O.
	await move_me(Vector3(10.9, 1, -5))
	for i in 4:
		await set_slot(i, "")
	var order := ["newt_key", "elephant_key", "porcupine_key", "owl_key"]
	for i in 4:
		await set_slot(i, order[i])
	await wait(0.3)
	check(gs().get_flag("argo_door.open", false), "the Door opens backwards from the house")
	await wait(1.2)
	check(node("ArgoDoor")._opened, "Door open (client)")

	# Rejoin while split.
	root.get_node("/root/Net").disconnect_from_game()
	change_scene_to_file("res://scenes/main_menu.tscn")
	await wait(1.5)
	await _join()
	await wait(0.5)
	check(level_name() == "villa_argo.tscn" and game()._levels.size() == 1, "rejoin lands back at Villa Argo")
	check(node("ArgoDoor")._opened and gs().has_item("owl_key"), "rejoin keeps the open Door and the key")
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
