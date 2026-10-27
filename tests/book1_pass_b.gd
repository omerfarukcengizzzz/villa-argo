extends SceneTree
# Headless two-process test of book 1 Pass B. Usage: -s tests/book1_pass_b.gd -- host|client

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
	gs().set_flag("argo.wardrobe_moved")
	gs().set_flag("argo_door.open")
	gs().give_item("clay", "box of glowing clay")
	gs().add_journal("handwriting", "The diary's handwriting", "...", "julia")
	gs().set_flag("test.ready")
	await move_me(Vector3(14, 1, -5.6))
	await until(func() -> bool: return _julia_near(Vector3(14.5, 1, -5)), "Julia behind the Door")
	await use("StepsDown")
	await until(func() -> bool: return level_name() == "argo_underground.tscn", "underground loaded")
	check(lvl()._candle.visible, "candle lit in the round room")
	check(lvl().get_node("Rick").position.distance_to(Vector3(3.5, 1, 3.5)) < 0.1, "Rick in the round room")

	# Step 9: wrong exit loops back.
	await until(func() -> bool: return gs().has_journal("floor_inscription"), "Julia reads the floor", 20)
	check(not journal_ids("jason").has("floor_inscription"), "inscription entry is Julia's")
	await move_me(Vector3(8.3, 1, -0.6))
	await until(func() -> bool: return _julia_near(Vector3(8.3, 1, 0)), "Julia in the wave passage")
	var old := lvl().get_instance_id()
	await use("WavePassage")
	await until(func() -> bool: return lvl() != null and lvl().get_instance_id() != old, "round room reloaded")
	await wait(0.3)
	check(toast().contains("brings you back"), "wave passage loops back")
	check(me().global_position.distance_to(Vector3(-0.8, 1, 2)) < 0.6, "back in the round room")

	# Step 10: the candle goes out on the stair; Julia lights the niches.
	await move_me(Vector3(0, 1, -9.5))
	await until(func() -> bool: return gs().get_flag("under.candle_out", false), "candle out")
	await wait(0.2)
	check(not lvl()._candle.visible and toast().contains("candle out"), "candle blown out")
	await until(func() -> bool: return gs().get_flag("under.niche3", false), "all niches lit", 25)
	check(lvl().get_node("Niche3")._light.visible, "niche light shows on Jason's side")
	await move_me(Vector3(0, -1, -13.25))
	await until(func() -> bool: return me().global_position.distance_to(Vector3(-0.5, 1, -10.5)) < 1.0, "fall into a gap and respawn", 6)
	check(true, "gap fall respawns at the top of the stair")

	# Step 11: Jason's ledge, then Julia's stones.
	await move_me(Vector3(4.0, -7.1, -31.5), -PI / 2)
	Input.action_press("move_forward")
	await until(func() -> bool: return me().global_position.y > -4.2, "Jason climbs the ledge", 8)
	await wait(0.5)
	Input.action_release("move_forward")
	await wait(0.6)
	check(me().global_position.y > -4.2 and me().global_position.y < -2.5, "Jason on the ledge (y=%.2f)" % me().global_position.y)
	await move_me(Vector3(5.2, -3.6, -31.5))
	await use("PaintedCeiling")
	check(journal_ids("jason").has("ceiling_arrows") and not journal_ids("julia").has("ceiling_arrows"), "ceiling arrows are Jason's")
	gs().set_flag("test.arrows")
	await until(func() -> bool: return gs().get_flag("stones.solved", false), "stones solved", 25)
	await wait(0.3)
	check(not lvl()._hatch.visible, "hatch opens")

	# Step 12: drop to the beach, the log.
	await move_me(Vector3(0, -7, -39))
	await until(func() -> bool: return me().is_on_floor() and me().global_position.y < -14.5, "land on the beach", 6)
	check(me().global_position.y > -16, "standing on the beach (y=%.2f)" % me().global_position.y)
	await move_me(Vector3(0, -13.5, -56.3))
	await use("CaptainsLog")
	check(gs().get_flag("metis.log_read", false), "captain's log read")
	check(journal_ids("julia").has("same_handwriting") and not journal_ids("jason").has("same_handwriting"), "handwriting match is Julia's")

	# Step 13: the helm needs both aboard.
	await move_me(Vector3(0, -13.4, -51))
	node("Helm").submit("Egypt")
	await wait(0.3)
	check(toast().contains("isn't aboard") and not gs().get_flag("metis.sailed", false), "helm waits for Julia")
	gs().set_flag("test.refused")
	await until(func() -> bool: return _julia_near(Vector3(0, -13.4, -52)), "Julia aboard")
	node("Helm").submit("Egypt")
	await wait(0.3)
	check(gs().get_flag("metis.sailed", false) and toast().contains("Egypt"), "the Metis sails for Egypt")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 25)


func _client() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
	await until(func() -> bool: return gs().get_flag("test.ready", false), "test state")
	await move_me(Vector3(14, 1, -4.4))
	await until(func() -> bool: return level_name() == "argo_underground.tscn", "client underground")
	await wait(0.3)
	check(node("Rick").current_line().contains("letters all over the floor"), "Rick's round room hint")
	await move_me(Vector3(0, 1, -0.3))
	await use("Inscription")
	check(journal_ids("julia").has("floor_inscription"), "Julia reads the inscription")
	check(node("Rick").current_line().contains("the moon"), "Rick reacts to the inscription")
	var old := lvl().get_instance_id()
	await move_me(Vector3(8.0, 1, 0.8))
	await until(func() -> bool: return lvl() != null and lvl().get_instance_id() != old, "client round room reloaded")
	await until(func() -> bool: return gs().get_flag("under.candle_out", false), "candle out (client)")
	for i in 4:
		var top: float = [0.0, -2.0, -4.0, -6.0][i]
		var z: float = [-10.75, -15.75, -20.75, -25.75][i]
		await move_me(Vector3(-0.4, top + 1, z - 1.2))
		await use("Niche%d" % i)
	check(gs().get_flag("under.niche3", false) and node("Niche0")._light.visible, "niches lit")

	await until(func() -> bool: return gs().get_flag("test.arrows", false), "Jason reads the arrows", 20)
	await move_me(Vector3(-3.9, -7, -34.5))
	await use("Stone1")
	check(toast().contains("grind back"), "out-of-order stone resets")
	var turns := {4: 1, 3: 2, 2: 3, 1: 1}
	for n in [4, 3, 2, 1]:
		await move_me(Vector3(-3.9 + (n - 1) * 2.6, -7, -34.5))
		for t in turns[n]:
			await use("Stone%d" % n)
	check(gs().get_flag("stones.solved", false), "stones set in order 4-3-2-1 open the hatch")
	await wait(0.4)
	check(absf(node("Stone2")._arrow.rotation_degrees.y - (-270.0)) < 1.0, "stone 2 arrow points west")

	await until(func() -> bool: return gs().get_flag("test.refused", false), "helm refusal", 25)
	await move_me(Vector3(1, -13.4, -53))
	await until(func() -> bool: return gs().get_flag("metis.sailed", false), "sailed (client)")
	await wait(0.3)
	check(toast().contains("Egypt") and journal_ids("julia").has("book1_end"), "Julia sees the departure")
	root.get_node("/root/Net").disconnect_from_game()
