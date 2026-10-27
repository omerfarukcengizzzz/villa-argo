extends SceneTree
# Headless two-process test of book 4 Pass A. Usage: -s tests/book4_pass_a.gd -- host|client

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


func dog_at(i: int) -> bool:
	return int(gs().get_flag("b4.dog", 0)) == i


func _host() -> void:
	root.get_node("/root/Net").host()
	change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and game().get_players().size() == 2, "both players", 25)
	# End of book 3, with books 1-2's underground already solved.
	for f in ["argo.rick_here", "argo.wardrobe_moved", "argo_door.open", "argo.mirror_door_open", "metis.log_read", "metis.sailed", "stones.solved",
			"b2.home", "b3.started", "b3.escaped"]:
		gs().set_flag(f)
	for k in [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"]]:
		gs().give_item(k[0], k[1])
	await wait(0.5)

	# Step 1: the attic.
	await move_me(Vector3(-2.8, 1, 7.6))
	gs().set_flag("test.attic")
	await until(func() -> bool: return _julia_near(Vector3(-2.8, 1, 8.4)), "Julia at the attic stairs")
	await use("AtticStairs")
	await until(func() -> bool: return level_name() == "argo_attic.tscn", "the attic")
	await wait(0.4)
	check(gs().get_flag("b4.started", false) and journal_ids("both").has("b4_mission") and toast().contains("Book 4"), "book 4 starts in the attic")
	await move_me(Vector3(-4, 1, 2.7))
	await use("OwlSlip")
	check(journal_ids("both").has("old_owl_slip") and not node("OwlKeyhole").is_available(), "the Old Owl: DEDA, with the right key")

	# Step 2: the Metis to Venice.
	await move_me(Vector3(-0.8, 1, 4.6))
	await until(func() -> bool: return _julia_near(Vector3(0, 1, 5)), "Julia at the attic door")
	await use("StairsDown")
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "down in the hall")
	game().change_level("res://scenes/levels/argo_underground.tscn")
	await wait(0.5)
	await move_me(Vector3(0, -13.4, -51))
	gs().set_flag("test.ship")
	await until(func() -> bool: return _julia_near(Vector3(0, -13.4, -52)), "Julia aboard")
	node("HelmVenice").submit("Egypt")
	await wait(0.3)
	check(toast().contains("won't turn") and level_name() == "argo_underground.tscn", "the Metis won't go back to Egypt")
	node("HelmVenice").submit("Venice")
	await until(func() -> bool: return level_name() == "venice.tscn", "Venice", 5)
	check(gs().get_flag("b4.away", false), "Rick has left Villa Argo")

	# Step 3: the beggars slip through; Jason follows; split.
	await until(func() -> bool: return gs().get_flag("b4.intruders_through", false), "the beggars run for the Door", 8)
	await move_me(Vector3(-1.4, 1, -4))
	await use("ChaseThroughDoor")
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "Jason back at the villa", 5)
	await wait(0.5)
	check(gs().get_flag("b4.split", false) and game().level_for("julia").scene_file_path.ends_with("venice.tscn"), "split: Jason at Argo, Julia in Venice")
	check(node("Nestor").current_line().contains("Mmmf"), "Nestor is tied up")

	# The dog sees Jason in the hall.
	var dog: Node3D = node("Dog")
	var forward := -dog.global_transform.basis.z
	forward.y = 0
	me().global_position = dog.global_position + forward.normalized() * 2.5 + Vector3(0, 0.5, 0)
	await wait(0.4)
	check(toast().contains("barks") and local_pos().distance_to(Vector3(9, 1, -5)) < 1.0, "the dog spots Jason; back to the stone room")

	# Step 4: Nestor. Step 6: the library. Step 5: the loot.
	await move_me(Vector3(10, 1, -6.8))
	await use("UntieNestor")
	check(gs().get_flag("b4.nestor_free", false) and node("Nestor").current_line().contains("locusts"), "Jason unties Nestor")
	await move_me(Vector3(-8, 1, -5))
	await use("MaskBook")
	check(journal_ids("jason").has("cenere_mask") and not journal_ids("julia").has("cenere_mask"), "Count Cenere's mask, for Jason to pass on")
	for spot in [[Vector3(-2, 5.4, -26.6), "Loot_telescope"], [Vector3(-10, 1, -1.5), "Loot_candlesticks"], [Vector3(-8, 1, 13.2), "Loot_jewellery_box"]]:
		await move_me(spot[0])
		await use(spot[1])
	check(gs().has_item("telescope") and gs().has_item("candlesticks") and gs().has_item("jewellery_box"), "the loot is back")

	# Without the mask, the beggars just laugh.
	await until(func() -> bool: return dog_at(0), "dog at the far end", 15)
	await move_me(Vector3(-1.2, 1, 7.6))
	await use("DonDiego")
	check(toast().contains("Go away, boy") and not gs().get_flag("b4.intruders_gone", false), "the beggars laugh at a boy")

	# The attic alone: the mask, the keyhole, DEDA.
	await move_me(Vector3(-2.8, 1, 7.8))
	await use("AtticStairs")
	await until(func() -> bool: return level_name() == "argo_attic.tscn", "the attic, alone", 5)
	check(game().level_for("julia").scene_file_path.ends_with("venice.tscn"), "Julia's still in Venice")
	await move_me(Vector3(4.3, 1, 3))
	await use("GuardMask")
	check(gs().has_item("guard_mask"), "the secret guard's mask")
	await move_me(Vector3(-2.6, 1, 1))
	node("OwlKeyhole").submit("Porcupine key")
	await wait(0.3)
	check(toast().contains("doesn't fit") and not gs().get_flag("owl.key_in", false), "the wrong key doesn't fit")
	node("OwlKeyhole").submit("Owl key")
	await wait(0.3)
	await move_me(Vector3(-4, 1, 2.6))
	node("OwlKeys").submit("deda")
	await wait(0.3)
	check(journal_ids("jason").has("owl_printout") and not journal_ids("julia").has("owl_printout"), "the Old Owl prints the Gondolier's word")

	# Back down; the mask sends them packing.
	await move_me(Vector3(0, 1, 4.6))
	await use("StairsDown")
	await until(func() -> bool: return level_name() == "villa_argo.tscn", "back in the hall", 5)
	await until(func() -> bool: return dog_at(0), "dog at the far end again", 15)
	await move_me(Vector3(-1.2, 1, 7.6))
	await use("DonDiego")
	check(gs().get_flag("b4.intruders_gone", false) and toast().contains("La guardia"), "La guardia! They bolt")
	check(gs().get_flag("b4.argo_safe", false) and journal_ids("jason").has("argo_safe"), "the house is safe")
	gs().set_flag("test.done")
	await until(func() -> bool: return game().get_players().size() == 1, "client finished", 30)
	finished = true


func _client() -> void:
	await _join()
	await until(func() -> bool: return gs().get_flag("test.attic", false), "to the attic", 20)
	await move_me(Vector3(-2.2, 1, 7.6))
	await until(func() -> bool: return level_name() == "argo_attic.tscn", "attic (client)", 20)
	await wait(0.6)
	await move_me(Vector3(0.6, 1, 4.6))
	await until(func() -> bool: return gs().get_flag("test.ship", false), "to the ship", 30)
	await move_me(Vector3(1, -13.4, -52.5))
	await until(func() -> bool: return level_name() == "venice.tscn", "Venice (client)", 20)
	await until(func() -> bool: return gs().get_flag("b4.split", false), "split (client)", 20)
	await wait(0.5)
	check(game()._levels.size() == 1 and level_name() == "venice.tscn", "Julia's machine loads only Venice")
	check(node("Rick").current_line().contains("up to us"), "Rick: it's up to us")
	await move_me(Vector3(3.5, 1, 6))
	await use("BeggarsFear")
	await move_me(Vector3(2.0, 1, -2))
	await use("BrassPlate")
	check(journal_ids("julia").has("beggars_fear") and journal_ids("julia").has("right_key"), "Julia learns the two things Jason needs")
	await until(func() -> bool: return gs().get_flag("b4.intruders_gone", false), "beggars gone", 120)
	await wait(0.3)
	check(toast().contains("tumbling out"), "Julia sees the beggars run back into Venice")
	await until(func() -> bool: return gs().get_flag("test.done", false), "host done", 30)
	root.get_node("/root/Net").disconnect_from_game()
	finished = true


func _join() -> void:
	root.get_node("/root/Net").join("127.0.0.1")
	await until(func() -> bool: return root.get_node("/root/Net").multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	if current_scene == null:
		change_scene_to_file("res://scenes/game.tscn")
	await until(func() -> bool: return game() != null and me() != null and lvl() != null, "spawned", 15)
