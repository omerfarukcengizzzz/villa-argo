extends Level
## The Garden of Prester John, book 5 (docs/book5-design.md, step 13). Canon:
## the twins reach it through the Argo Door, with Oblivia and Manfred there too
## (ref ✅); a medieval walled garden with stone guardians, a garden gate, the
## corridor of death and a cloister (chapter titles Castaway, Corridor of Death,
## Intruders, Guardians of Time, Cloister: HIGH; contents adaptation):
## - Castaway: the Metis leaves the twins on the shore and slips back into the mist.
## - The gate yard: stone guardians that move only while no twin is looking at
##   them. Jason climbs the gatehouse to lift the bar while Julia watches his
##   back; then she pulls the gate open while he watches hers.
## - The corridor of death: false flagstones that only Julia sees are cracked,
##   then swinging blades both must time.
## - The cloister: the gate slams behind them; across the cloister, Oblivia and
##   Manfred. End of book 5.
##
## Map (north = -z): shore z 6..20; the gate yard x -12..12, z -24..6, with the
## gate and gatehouse at z -24; the corridor x -3..3, z -24..-50; the cloister
## x -12..12, z -50..-72.

const MAZE_TOWN := "res://scenes/levels/maze_town.tscn"
const STONE := Color(0.6, 0.58, 0.52)
const FLAG := Color(0.55, 0.52, 0.47)
const GRASS := Color(0.35, 0.5, 0.3)
const YARD_START := Vector3(0, 1, 5)
const CORRIDOR_START := Vector3(0, 1, -25.5)
## Guardian homes: two by the gate, two near the yard's entrance.
const GUARDIANS := [Vector3(-9, 1, -19), Vector3(9, 1, -19), Vector3(-9, 1, -5), Vector3(9, 1, -5)]
## One guardian step every STEP_SECONDS, STEP metres toward the nearest twin.
const STEP_SECONDS := 0.75
const STEP := 1.5
const CATCH := 1.4
## A twin watches what's within WATCH_FOV degrees of where they look.
const WATCH_FOV := 50.0
const WATCH_RANGE := 30.0
## The false flagstones: [row][column] true = false stone (x -2, 0, 2).
const FALSE_STONES := [[true, false, true], [false, true, true], [true, true, false], [true, false, true], [false, true, true]]

var _step_t := 0.0
var _b6_t := 0.0


func _init() -> void:
	origin = Vector3(27000, 0, 0)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(-1.2, 1, 15), "julia": Vector3(1.2, 1, 15), "yaw": 0.0},
	}
	add_environment(Color(0.75, 0.78, 0.7))
	_build_shore()
	_build_yard()
	_build_corridor()
	_build_cloister()
	GameState.changed.connect(_on_state_changed)
	_on_state_changed("")


func _host_setup() -> void:
	if not GameState.get_flag("garden.arrived", false):
		GameState.set_flag("garden.arrived")
		_reset_guardians()
		Game.current.say("The Metis noses onto a misty shore under a high stone wall... and when you look round, it has slipped back into the mist without you. Castaways.")
		GameState.add_journal("castaways", "Castaways",
			"The Metis brought us to the Garden of Prester John and left us here. No ship, no Rick, no way back that we know of. Somewhere ahead are Oblivia and Manfred.\nAbove the gate in the wall stand stone statues, guardians. I could swear the nearest one was facing the other way a moment ago.")


func respawn_point(role: String, fell_from: Vector3) -> Vector3:
	if fell_from.z < -24.0:
		return CORRIDOR_START
	return spawn_point(role, "default")


# --- Castaway: the shore -----------------------------------------------------------

func _build_shore() -> void:
	add_box(Vector3(30, 0.5, 14), Vector3(0, -0.25, 13), Color(0.75, 0.7, 0.55))
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 20)
	sea.mesh = plane
	sea.material_override = Vis.material(Color(0.5, 0.6, 0.65))
	sea.position = Vector3(0, -0.4, 30)
	add_child(sea)
	add_box(Vector3(30, 2, 0.4), Vector3(0, 1, 20.2), Color(0.5, 0.6, 0.65)).visible = false
	for x in [-15.0, 15.0]:
		add_box(Vector3(0.4, 3, 14), Vector3(x, 1.5, 13), STONE)
		add_box(Vector3(3, 3, 0.4), Vector3(x * 0.9, 1.5, 6), STONE)
	add_label("mist", Vector3(0, 3, 19)).billboard = BaseMaterial3D.BILLBOARD_ENABLED


# --- The gate yard and the stone guardians ----------------------------------------

func _build_yard() -> void:
	add_box(Vector3(24, 0.5, 30), Vector3(0, -0.25, -9), GRASS)
	for x in [-12.0, 12.0]:
		add_box(Vector3(0.4, 7, 30), Vector3(x, 3.5, -9), STONE)
	add_box(Vector3(10, 7, 1), Vector3(-7, 3.5, -24), STONE)
	add_box(Vector3(10, 7, 1), Vector3(7, 3.5, -24), STONE)
	add_box(Vector3(4, 2, 1), Vector3(0, 6, -24), STONE)
	add_label("THE GARDEN GATE", Vector3(0, 7.4, -23.4), 0)

	# The gate itself, and the gatehouse Jason climbs to reach the bar.
	var gate := add_box(Vector3(4, 5, 0.3), Vector3(0, 2.5, -24), Color(0.35, 0.25, 0.15))
	gate.name = "Gate"
	add_climb_wall(Vector3(2, 6, 1), Vector3(-4, 3, -23))
	add_box(Vector3(3, 0.3, 2), Vector3(-3.5, 6.15, -23.6), STONE)
	var bar := Switch.new()
	bar.who = "jason"
	bar.flag = "garden.bar"
	bar.prompt = "Lift the bar off the gate"
	bar.size = Vector3(1.6, 0.2, 0.2)
	bar.color = Color(0.3, 0.3, 0.3)
	bar.on_used = func(_p: Node3D) -> void:
		Game.current.say("Jason heaves the great iron bar out of its brackets. It falls into the grass with a thud. Julia: the ring!")
	place(bar, "GateBar", Vector3(-2.5, 7, -23.6))
	var ring := Switch.new()
	ring.who = "julia"
	ring.flag = "garden.gate_open"
	ring.requires = "garden.bar"
	ring.prompt = "Pull the iron ring"
	ring.size = Vector3(0.4, 0.4, 0.1)
	ring.color = Color(0.3, 0.3, 0.3)
	ring.on_used = func(_p: Node3D) -> void:
		GameState.add_journal("guardians", "The guardians of time",
			"The stone guardians move, but only when nobody is looking at them. We crossed the yard back to back: one of us watching while the other worked. Jason lifted the bar from the gatehouse, Julia pulled the gate open, and the statues froze where they stood.")
		Game.current.say("The gate grinds open. Behind you, every stone guardian is suddenly perfectly still, as if it had never moved at all.")
	place(ring, "GateRing", Vector3(1.2, 1.2, -23.7))

	for i in GUARDIANS.size():
		var g := Node3D.new()
		g.name = "Guardian%d" % i
		g.position = GUARDIANS[i]
		var body := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.5
		cm.height = 2.4
		body.mesh = cm
		body.position.y = 0.2
		body.material_override = Vis.material(Color(0.7, 0.7, 0.66))
		g.add_child(body)
		var face := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(0.5, 0.3, 0.2)
		face.mesh = fb
		face.position = Vector3(0, 1.0, -0.45)
		face.material_override = Vis.material(Color(0.45, 0.45, 0.42))
		g.add_child(face)
		var tag := Label3D.new()
		tag.text = "stone guardian"
		tag.position.y = 1.8
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size = 28
		g.add_child(tag)
		add_child(g)


## Every peer: guardians stand where GameState says, turning toward where they went.
func _on_state_changed(_key: String) -> void:
	for i in GUARDIANS.size():
		var g: Node3D = get_node("Guardian%d" % i)
		var pos: Vector3 = GameState.get_flag("garden.g%d" % i, GUARDIANS[i])
		if g.position.is_equal_approx(pos):
			continue
		var dir := pos - g.position
		if Vector2(dir.x, dir.z).length() > 0.01:
			g.rotation.y = atan2(-dir.x, -dir.z)
		if is_node_ready() and g.position.distance_to(pos) < STEP * 1.5:
			create_tween().tween_property(g, "position", pos, STEP_SECONDS * 0.8)
		else:
			g.position = pos
	var shut: bool = GameState.get_flag("garden.gate_open", false)
	var gate: StaticBody3D = get_node("Gate")
	gate.visible = not shut
	gate.get_child(1).disabled = shut
	var behind: StaticBody3D = get_node("CloisterGate")
	var closed: bool = GameState.get_flag("b5.cloister", false)
	behind.visible = closed
	behind.get_child(1).disabled = not closed


## Host: whether any twin in this level is looking at the guardian.
func watched(g: Node3D) -> bool:
	for p in Game.current.get_players():
		if Game.current.level_for(p.role) == self and sees(p, g, WATCH_RANGE, WATCH_FOV):
			return true
	return false


func _reset_guardians() -> void:
	for i in GUARDIANS.size():
		GameState.set_flag("garden.g%d" % i, GUARDIANS[i])


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_check_cloister(delta)
	if GameState.get_flag("garden.gate_open", false):
		return
	var twins := Game.current.get_players().filter(func(p: Node3D) -> bool: return Game.current.level_for(p.role) == self)
	if twins.is_empty():
		return
	# Caught: a stone hand on your shoulder, and you're back at the yard's edge.
	for i in GUARDIANS.size():
		var at: Vector3 = GameState.get_flag("garden.g%d" % i, GUARDIANS[i])
		for p in twins:
			var d := to_local(p.global_position) - at
			if Vector2(d.x, d.z).length() < CATCH:
				p.teleport.rpc(to_global(YARD_START + Vector3(-1.2 if p.role == "jason" else 1.2, 0, 0)), 0.0)
				Game.current.say("A cold stone hand closes on %s's shoulder... and %s is back at the edge of the yard, the guardians back in their places. Don't take your eyes off them!" % [p.role.capitalize(), p.role.capitalize()])
				_reset_guardians()
				return
	_step_t += delta
	if _step_t < STEP_SECONDS:
		return
	_step_t = 0.0
	for i in GUARDIANS.size():
		var g: Node3D = get_node("Guardian%d" % i)
		if watched(g):
			continue
		var at: Vector3 = GameState.get_flag("garden.g%d" % i, GUARDIANS[i])
		var nearest: Vector3
		var best := INF
		for p in twins:
			var to := to_local(p.global_position)
			to.y = at.y
			if to.distance_to(at) < best:
				best = to.distance_to(at)
				nearest = to
		if best < INF:
			GameState.set_flag("garden.g%d" % i, at + (nearest - at).limit_length(STEP))


# --- The corridor of death --------------------------------------------------------

func _build_corridor() -> void:
	add_box(Vector3(6, 0.5, 26), Vector3(0, -0.25, -37), Color(0.2, 0.18, 0.16))
	for x in [-3.2, 3.2]:
		add_box(Vector3(0.4, 6, 26), Vector3(x, 3, -37), STONE)
	add_label("the corridor of death", Vector3(0, 4.5, -25), 0).font_size = 34
	var fall := "The flagstone tips under your feet! You scramble back to the start of the corridor."
	var warn := ""
	for r in FALSE_STONES.size():
		for c in 3:
			var pos := Vector3(-2 + c * 2, 0, -27 - r * 2)
			add_box(Vector3(1.9, 0.1, 1.9), pos + Vector3(0, 0.05, 0), FLAG)
			if not FALSE_STONES[r][c]:
				continue
			var trap := Hazard.new()
			trap.size = Vector3(1.7, 1.0, 1.7)
			trap.color = FLAG
			trap.respawn = CORRIDOR_START
			trap.message = fall
			place(trap, "FalseStone%d_%d" % [r, c], pos + Vector3(0, 0.5, 0))
			# Only Julia sees the hairline cracks.
			var crack := MeshInstance3D.new()
			var cb := BoxMesh.new()
			cb.size = Vector3(1.6, 0.02, 0.08)
			crack.mesh = cb
			crack.material_override = Vis.material(Color(0.1, 0.08, 0.06))
			crack.position = pos + Vector3(0, 0.13, 0)
			crack.rotation_degrees.y = 35 + 50 * ((r + c) % 2)
			Vis.make_private(crack, "julia")
			add_child(crack)
		warn += "%s\n" % " ".join(Array(FALSE_STONES[r]).map(func(f: bool) -> String: return "x" if f else "o"))
	var note := JournalNote.new()
	note.who = "julia"
	note.entry_who = "julia"
	note.entry_id = "false_stones"
	note.title = "The cracked flagstones"
	note.body = "Words cut over the corridor: \"Who walks blind walks to his death.\" Looking closely, I can see hairline cracks in some of the flagstones. Those must be the ones that tip. From the gate end, left to right (x = cracked, o = sound):\n" + warn + "Jason can't see the cracks at all. I'll have to call out every step."
	note.prompt = "Read the words over the corridor"
	note.size = Vector3(0.01, 0.01, 0.01)
	place(note, "CorridorWords", Vector3(0, 1, -25))

	# Then the blades, swinging across the corridor: wait for the gap.
	for i in 3:
		var blade := Hazard.new()
		blade.size = Vector3(1.2, 2.0, 0.4)
		blade.color = Color(0.75, 0.75, 0.8)
		blade.label = "blade"
		blade.respawn = Vector3(0, 1, -37.5)
		blade.message = "A blade swings out of the wall and sends you sprawling back! Watch the rhythm."
		blade.travel = Vector3(5, 0, 0)
		blade.period = 2.4
		blade.phase = i * 2.0
		place(blade, "Blade%d" % i, Vector3(-2.5, 1, -40 - i * 3))


# --- The cloister: the end of book 5 ----------------------------------------------

func _build_cloister() -> void:
	add_box(Vector3(24, 0.5, 22), Vector3(0, -0.25, -61), STONE)
	for x in [-12.0, 12.0]:
		add_box(Vector3(0.4, 6, 22), Vector3(x, 3, -61), STONE)
	add_box(Vector3(24, 6, 0.4), Vector3(0, 3, -72), STONE)
	add_box(Vector3(9, 6, 0.4), Vector3(-7.5, 3, -50), STONE)
	add_box(Vector3(9, 6, 0.4), Vector3(7.5, 3, -50), STONE)
	for x in [-8.0, -4.0, 4.0, 8.0]:
		for z in [-54.0, -68.0]:
			add_box(Vector3(0.6, 4, 0.6), Vector3(x, 2, z), Color(0.8, 0.78, 0.72))
	add_box(Vector3(10, 0.4, 8), Vector3(0, 0.2, -61), GRASS)
	add_label("the cloister", Vector3(0, 5, -50.4), 180).font_size = 34
	var gate := add_box(Vector3(6, 6, 0.4), Vector3(0, 3, -49.6), Color(0.3, 0.3, 0.32))
	gate.name = "CloisterGate"

	for who in [["Oblivia Newton", Color(0.6, 0.1, 0.3), Vector3(-2, 1, -70)], ["Manfred", Color(0.2, 0.2, 0.2), Vector3(2, 1, -70)]]:
		var npc := Npc.new()
		npc.npc_name = who[0]
		npc.color = who[1]
		npc.who = "nobody"
		npc.present = "b5.cloister & !b6.started"
		place(npc, who[0].split(" ")[0], who[2])

	# Book 6 step 1: the small door Oblivia and Manfred slipped out through.
	add_box(Vector3(1.6, 2.6, 0.2), Vector3(0, 1.3, -71.7), Color(0.35, 0.25, 0.15))
	var door := LevelExit.new()
	door.level = MAZE_TOWN
	door.requires = "b6.started"
	door.prompt = "Go through the small door"
	place(door, "CloisterDoor", Vector3(0, 1, -70.6))


## Host: both twins in the cloister: the gate slams behind them. End of book 5.
## A little later, book 6 starts there.
func _check_cloister(delta: float) -> void:
	if GameState.get_flag("b5.cloister", false):
		if not GameState.get_flag("b6.started", false):
			_b6_t += delta
			if _b6_t > 9.0:
				_start_book6()
		return
	var twins := Game.current.get_players()
	if twins.size() < 2 or not twins.all(func(p: Node3D) -> bool:
			return Game.current.level_for(p.role) == self and to_local(p.global_position).z < -52.5):
		return
	GameState.set_flag("b5.cloister")
	GameState.add_journal("cloister", "The cloister",
		"Past the corridor of death, a quiet cloister: columns, a square of grass, a well. The iron gate slammed down behind us, and there's no handle on this side.\nAnd on the far side of the cloister, two figures we know: Oblivia Newton, and Manfred. They've seen us too.\nWe're inside the Garden of Prester John. Black Vulcano must be somewhere in here. So is the way home, we hope.")
	Game.current.say("CLANG! An iron gate drops behind you. And across the cloister, turning to stare: Oblivia Newton and Manfred.")
	Game.current.say_later("End of book 5: The Stone Guardians. (Book 6 continues in the Garden.)", 5.0)


## Book 6 step 1 (canon: the twins trapped in the Garden with Oblivia and
## Manfred, HIGH; the small door is adaptation).
func _start_book6() -> void:
	GameState.set_flag("b6.started")
	GameState.add_journal("b6_start", "Trapped in the Garden",
		"While we were staring at the gate, Oblivia and Manfred slipped away through a small door at the far end of the cloister. Beyond it there's a whole medieval town: roofs and towers and streets that twist back on themselves.\nRick is back in Kilmore Cove. Nobody knows where we are, except maybe Nestor. Black Vulcano is somewhere in here, and so is the way home.")
	Game.current.say("Book 6: The First Key. When you look again, Oblivia and Manfred are gone, through a small door at the far end of the cloister.")
