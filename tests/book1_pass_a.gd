extends SceneTree
# Headless two-process test of book 1 Pass A. Usage: -s tests/book1_pass_a.gd -- host|client

var role := ""
var fails := 0


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


func move_me(pos: Vector3, yaw := 0.0) -> void:
	var p := me()
	p.global_position = pos
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
	log_("DONE fails=%d" % fails)
	quit(1 if fails else 0)


func _julia_near(pos: Vector3) -> bool:
	for p in game().get_players():
		if p.role == "julia":
			return p.global_position.distance_to(pos) < 3.0
	return false


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	check(level_name() == "villa_argo.tscn", "starts in Villa Argo")

	# Step 1: Nestor.
	await move_me(Vector3(4, 1, 18.5))
	await use("Nestor")
	check(toast().contains("Nestor: Nestor, the gardener"), "Nestor intro line")
	check(journal_ids("both").has("scarred_door"), "scarred door journal")
	await until(func() -> bool: return gs().get_flag("argo.night", false), "night falls")
	check(lvl()._sun.light_energy < 0.5, "night lighting")

	# Step 2: footsteps (Jason only), then morning and Rick.
	await move_me(Vector3(0, 1, -12))
	await until(func() -> bool: return gs().get_flag("argo.footsteps", false), "footsteps")
	await wait(0.2)
	check(toast().contains("Footsteps"), "Jason hears footsteps")
	check(journal_ids("jason").has("footsteps") and not journal_ids("julia").has("footsteps"), "footsteps entry is Jason's only")
	await until(func() -> bool: return gs().get_flag("argo.rick_here", false), "Rick arrives", 10)
	check(not gs().get_flag("argo.night", false) and lvl()._sun.light_energy > 0.5, "morning")
	check(node("Rick").visible, "Rick visible")

	# Step 3: cliff gate, ledges, falls, the crevice, the climb back.
	await move_me(Vector3(-20, 1, 0))
	await use("CliffGate")
	check(gs().get_flag("argo.cliff_gate_open", false), "cliff gate opens")
	await move_me(Vector3(-26.5, -1, 1))
	await wait(0.8)
	check(absf(me().global_position.y - (-1.1)) < 0.3, "stands on a real ledge (y=%.2f)" % me().global_position.y)
	await move_me(Vector3(-30, -3, 1))
	await until(func() -> bool: return me().global_position.x > -23.5, "fall through cracked ledge and respawn", 6)
	check(me().global_position.y > -1 and me().global_position.x > -23.5, "respawned at cliff top")
	await move_me(Vector3(-30, -9, 11))
	await use("ClayBox")
	await use("Parchment")
	check(gs().has_item("clay") and gs().has_item("parchment"), "box and parchment taken")
	check(journal_ids("both").has("cliff_box"), "cliff box journal")
	await move_me(Vector3(-30, -9.1, 12.4), PI)
	Input.action_press("move_forward")
	await until(func() -> bool: return me().global_position.y > -0.5, "Jason climbs the pillar", 8)
	await wait(0.6)
	Input.action_release("move_forward")
	await wait(0.6)
	check(me().global_position.y > -0.5 and me().global_position.y < 3, "Jason on top of the pillar (y=%.2f)" % me().global_position.y)

	# Step 4 is Julia's (client). Step 5 needs it.
	await until(func() -> bool: return gs().get_flag("argo.cipher_solved", false), "Julia decodes the parchment", 20)
	check(journal_ids("both").has("parchment"), "parchment journal")
	await move_me(Vector3(10.0, 1, -5))
	await use("Wardrobe")
	check(gs().get_flag("argo.wardrobe_moved", false), "wardrobe pushed")

	# Step 6: tower.
	await move_me(Vector3(0, 5.4, -20.5))
	await use("MirrorDoor")
	check(gs().get_flag("argo.mirror_door_open", false), "mirror door opens")
	await move_me(Vector3(2.5, 8.4, -29.2))
	await use("ShipModel")
	check(gs().has_item("receipt"), "receipt found")
	check(journal_ids("both").has("tower_diary") and not journal_ids("jason").has("handwriting"), "diary entry; handwriting is Julia's")

	# Step 7: post office.
	await move_me(Vector3(-0.8, 1, 24.5))
	await until(func() -> bool: return _julia_near(Vector3(0, 1, 25)), "Julia at the gate")
	await use("GateToKilmoreCove")
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "Kilmore Cove loaded")
	await move_me(Vector3(0, 1, -11))
	await use("Clerk")
	check(toast().contains("waiting here for years"), "clerk receipt line")
	check(gs().has_item("owl_key") and gs().has_item("newt_key"), "four keys")
	check(not journal_ids("jason").has("second_message"), "second message hidden from Jason")
	await move_me(Vector3(-0.8, 1, 12))
	await until(func() -> bool: return _julia_near(Vector3(0, 1, 12)), "Julia at the street exit")
	await use("ExitToVilla")
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "back at Villa Argo")
	check(me().global_position.z > 22, "arrived at the gate")

	# Step 8: the four keys. Wrong order first.
	await move_me(Vector3(10.9, 1, -5))
	await use("Lock0")
	await use("Lock0")
	await use("Lock1")
	await use("Lock2")
	await use("Lock3")
	check(toast().contains("spring back"), "wrong order fails")
	await wait(1.0)
	check(gs().get_flag("argo_door.slot0", "x") == "" and int(gs().get_flag("argo_door.fails", 0)) == 1, "locks cleared, fail counted")
	check(node("Rick").current_line().contains("first letters"), "Rick's OPEN hint after a failure")
	for i in 4:
		await use("Lock%d" % i)
	check(gs().get_flag("argo_door.open", false), "O-P-E-N opens the door")
	await wait(1.8)
	check(node("ArgoDoor")._body.position.y < -1.0, "door sank")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 25)


func _client() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
	await wait(0.5)
	check(level_name() == "villa_argo.tscn", "client in Villa Argo")
	check(lvl()._parchment_label.layers == 4, "parchment symbols on Jason's layer")
	check(not me()._camera.get_cull_mask_value(3), "Julia's camera skips Jason's layer")

	await until(func() -> bool: return gs().get_flag("argo.night", false), "night (client)")
	check(lvl()._sun.light_energy < 0.5, "night lighting (client)")
	await wait(0.6)
	check(not toast().contains("Footsteps"), "Julia doesn't hear footsteps")

	await until(func() -> bool: return gs().has_item("parchment"), "parchment (client)", 40)
	await wait(0.3)
	check(lvl()._parchment_label.visible, "parchment shown once taken")
	await move_me(Vector3(-9.8, 1, -6))
	node("Dictionary").submit("cave hips")
	await wait(0.4)
	check(toast().contains("The words don't fit"), "wrong decode rejected")
	node("Dictionary").submit("Cave ship!")
	await until(func() -> bool: return gs().get_flag("argo.cipher_solved", false), "cipher solved (client)")

	await until(func() -> bool: return gs().has_item("receipt"), "receipt (client)", 30)
	check(journal_ids("julia").has("handwriting"), "Julia's handwriting entry")
	await move_me(Vector3(0.8, 1, 24.5))
	await until(func() -> bool: return level_name() == "kilmore_cove.tscn", "client in Kilmore Cove")
	await until(func() -> bool: return gs().has_item("owl_key"), "keys (client)")
	check(journal_ids("julia").has("second_message"), "Julia reads the second message")
	await move_me(Vector3(0.8, 1, 12))
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "client back at the villa")
	await until(func() -> bool: return gs().get_flag("argo_door.open", false), "door open (client)", 30)
	await wait(1.8)
	check(node("ArgoDoor")._body.position.y < -1.0, "door sank (client)")
	root.get_node("/root/Net").disconnect_from_game()
