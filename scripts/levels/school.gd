extends Level
## Kilmore Cove school, book 5 (docs/book5-design.md, steps 2, 4-5). Canon:
## Jason sneaks off to the lighthouse while Julia covers for him; he's caught and
## the headteacher confiscates the keys, the photo and the charm (MEDIUM). How
## Julia covers and how the things are recovered is adaptation:
## - Julia asks the teacher a question; while the teacher's at her desk, Jason
##   slips out of the classroom window (to the kilmore_cove level).
## - Julia keeps the headteacher talking in the corridor (three questions; a
##   wrong answer and he goes back) while Jason climbs in through the office
##   window. If the headteacher is in his office and sees Jason, he's sent out.
##
## Map (north = -z): classroom x -6..6, z -6..6 (window west); headteacher's
## office x 6..14, z -6..6 (window east, onto the yard); corridor z 6..10;
## the yard x 14..22.

const KILMORE_COVE := "res://scenes/levels/kilmore_cove.tscn"
const WALL := Color(0.75, 0.72, 0.65)
const TEACHER_DESK := Vector3(0, 1, -4.5)
const JULIA_DESK := Vector3(3, 1, 2.6)
const OFFICE := Vector3(10, 1, -3)
const CORRIDOR := Vector3(9, 1, 8)
const DISTRACT_SECONDS := 7.0
const LINGER_SECONDS := 12.0
## The headteacher's three questions: [question, [answer, right?]...].
const TALK := [
	["Well, Miss Covenant? What is it?", [["I wanted to ask about a school trip, sir.", true], ["Can my brother have his keys back?", false], ["Nothing, sir.", false]]],
	["A school trip? Where to?", [["The lighthouse: Mr Minaxo could show us how the lamp works.", true], ["Venice.", false], ["Egypt.", false]]],
	["Hmm. And who would organise it?", [["Calypso from the bookshop said she'd help.", true], ["Nobody, really.", false], ["My brother.", false]]],
]

var _distract_t := 0.0
var _linger_t := 0.0


func _init() -> void:
	origin = Vector3(21000, 0, 0)


func _build() -> void:
	entries = {
		"default": {"jason": Vector3(17, 1, 8), "julia": Vector3(18.5, 1, 8), "yaw": PI / 2},
		"restroom": {"jason": Vector3(-4, 1, 8), "julia": Vector3(-3, 1, 8), "yaw": -PI / 2},
	}
	add_environment(Color(0.6, 0.7, 0.85))
	add_box(Vector3(28, 0.5, 18), Vector3(8, -0.25, 2), Color(0.5, 0.48, 0.45))

	# Classroom.
	add_box(Vector3(12, 4, 0.4), Vector3(0, 2, -6), WALL)
	add_box(Vector3(0.4, 4, 5), Vector3(-6, 2, -3.5), WALL)
	add_box(Vector3(0.4, 4, 5), Vector3(-6, 2, 3.5), WALL)
	add_box(Vector3(0.4, 1, 2), Vector3(-6, 0.5, 0), WALL)
	add_box(Vector3(0.1, 3, 2), Vector3(-6, 2.5, 0), Color(0.7, 0.85, 0.95))
	add_box(Vector3(5, 4, 0.4), Vector3(-3.5, 2, 6), WALL)
	add_box(Vector3(5, 4, 0.4), Vector3(3.5, 2, 6), WALL)
	add_box(Vector3(0.4, 4, 12), Vector3(6, 2, 0), WALL)
	add_label("classroom window", Vector3(-5.7, 2.3, 0), 90).font_size = 24
	add_box(Vector3(2, 0.9, 1), Vector3(0, 0.45, -5), Color(0.45, 0.32, 0.2))
	for x in [-3.0, 3.0]:
		for z in [-1.0, 2.6]:
			add_box(Vector3(1.4, 0.8, 0.8), Vector3(x, 0.4, z), Color(0.55, 0.42, 0.28))

	# Office.
	add_box(Vector3(8, 4, 0.4), Vector3(10, 2, -6), WALL)
	add_box(Vector3(3, 4, 0.4), Vector3(7.5, 2, 6), WALL)
	add_box(Vector3(3, 4, 0.4), Vector3(12.5, 2, 6), WALL)
	add_box(Vector3(0.4, 4, 5), Vector3(14, 2, -3.5), WALL)
	add_box(Vector3(0.4, 4, 5), Vector3(14, 2, 3.5), WALL)
	add_box(Vector3(0.4, 1.6, 2), Vector3(14, 0.8, 0), WALL)
	add_box(Vector3(0.4, 0.4, 2), Vector3(14, 3.8, 0), WALL)
	add_label("HEADTEACHER", Vector3(10, 3.4, 6.3), 0).font_size = 28
	add_label("office window", Vector3(14.3, 3.1, 0), 90).font_size = 22
	add_climb_wall(Vector3(1, 1.6, 2), Vector3(15, 0.8, 0))
	add_climb_wall(Vector3(1, 1.6, 2), Vector3(13, 0.8, 0))
	add_box(Vector3(2, 0.9, 1), Vector3(9, 0.45, -4.5), Color(0.4, 0.28, 0.18))

	# Corridor and yard.
	add_box(Vector3(20, 4, 0.4), Vector3(4, 2, 10), WALL)
	add_box(Vector3(0.4, 4, 4), Vector3(-6, 2, 8), WALL)
	add_box(Vector3(0.4, 4, 18), Vector3(22, 2, 2), WALL)
	add_box(Vector3(8, 4, 0.4), Vector3(18, 2, 11), WALL)
	add_box(Vector3(8, 4, 0.4), Vector3(18, 2, -7), WALL)
	add_label("restrooms", Vector3(-5.7, 2.6, 8), 90).font_size = 24
	var out := LevelExit.new()
	out.level = KILMORE_COVE
	out.entry = "school"
	out.requires = "!b5.jason_out"
	out.prompt = "Leave school"
	place(out, "LeaveSchool", Vector3(20.5, 1, 9))

	_build_class()
	_build_office()
	_build_rick()


func _host_setup() -> void:
	if GameState.get_flag("b5.started", false) and not GameState.get_flag("school.arrived", false):
		GameState.set_flag("school.arrived")
		Game.current.say("School. Rick waves from his desk. The teacher is watching the class like a hawk, and the classroom window is right behind Jason's desk...")


# --- Step 2: Julia covers, Jason slips out ----------------------------------------

func _build_class() -> void:
	var teacher := Npc.new()
	teacher.npc_name = "The teacher"
	teacher.color = Color(0.5, 0.45, 0.55)
	teacher.walk_speed = 3.0
	teacher.stations = [["", TEACHER_DESK], ["school.distracted", JULIA_DESK + Vector3(0, 0, -1.1)]]
	teacher.lines = [["", "Eyes on the board, please."]]
	place(teacher, "Teacher", TEACHER_DESK)

	var ask := ChoicePoint.new()
	ask.who = "julia"
	ask.requires = "b5.started & !b5.jason_out & !b5.met_minaxo & !school.distracted"
	ask.prompt = "Put your hand up and ask a question"
	ask.question = "Ask the teacher..."
	ask.options_for = func() -> Array:
		return [["...about the history of Kilmore Cove", true], ["...about the old railway", true], ["...to explain that again, slowly", true]]
	ask.on_choice = func(_p: Node3D, _c: String) -> void:
		_distract_t = 0.0
		GameState.set_flag("school.distracted")
		Game.current.say("The teacher comes over to Julia's desk, delighted that someone is interested. Her back is to the window...")
	place(ask, "AskQuestion", JULIA_DESK + Vector3(0, 0, 0.8))

	var window := LevelExit.new()
	window.who = "jason"
	window.solo = true
	window.level = KILMORE_COVE
	window.entry = "school"
	window.requires = "school.distracted & b5.started & !b5.met_minaxo"
	window.prompt = "Slip out of the window"
	window.on_used = func(_p: Node3D) -> void:
		GameState.set_flag("b5.jason_out")
		GameState.set_flag("school.distracted", false)
		Game.current.say("When the teacher turns back to the board, Jason's desk is empty. Julia puts her coat over the chair.", "julia")
		Game.current.say("Out of the window and away across the square: to the lighthouse, to ask Mr Minaxo about Black Vulcano.", "jason")
	place(window, "ClassroomWindow", Vector3(-5.2, 1, 0))


# --- Step 5: the headteacher and the office window --------------------------------

func _build_office() -> void:
	var head := Npc.new()
	head.npc_name = "The headteacher"
	head.color = Color(0.3, 0.3, 0.35)
	head.walk_speed = 3.0
	head.stations = [["", OFFICE], ["school.talking", CORRIDOR]]
	head.lines = [
		["", "Back to your classroom, please."],
		["b5.confiscated", "End of term, Miss Covenant. Not a day before."],
	]
	place(head, "Headteacher", OFFICE)

	var talk := ChoicePoint.new()
	talk.who = "julia"
	talk.requires = "b5.confiscated & !b5.recovered"
	talk.reach = 2.4
	talk.prompt = "Knock on the headteacher's door"
	talk.options_for = func() -> Array:
		var step: int = GameState.get_flag("school.talk_step", 0)
		return TALK[min(step, TALK.size() - 1)][1].map(func(a: Array) -> Array: return [a[0], true])
	talk.question_for = func() -> String:
		return "The headteacher: \"%s\"" % TALK[min(int(GameState.get_flag("school.talk_step", 0)), TALK.size() - 1)][0]
	talk.on_choice = _answer
	place(talk, "TalkToHead", Vector3(10, 1, 7.2))

	var box := Switch.new()
	box.who = "jason"
	box.flag = "b5.recovered"
	box.requires = "b5.confiscated"
	box.prompt = "Take back the confiscated things"
	box.on_used = func(_p: Node3D) -> void:
		for k in [["owl_key", "Owl key"], ["porcupine_key", "Porcupine key"], ["elephant_key", "Elephant key"], ["newt_key", "Newt key"]]:
			GameState.give_item(k[0], k[1])
		GameState.add_journal("recovered", "Got them back",
			"While Julia kept the headteacher talking about a school trip that will never happen, Jason climbed in through his office window and took everything back out of the drawer: the four keys, the photo and the charm.")
		Game.current.say("Jason scoops the keys, the photo and the charm out of the drawer and climbs back out of the window. Got them!")
	place(box, "ConfiscatedDrawer", Vector3(9, 1, -3.6))


## Host: one answer to the headteacher. Each right one keeps him in the
## corridor; a wrong one sends him straight back to his office.
func _answer(_player: Node3D, choice: String) -> void:
	var step: int = GameState.get_flag("school.talk_step", 0)
	var right := false
	for a in TALK[min(step, TALK.size() - 1)][1]:
		if a[0] == choice:
			right = a[1]
	if not right:
		GameState.set_flag("school.talk_step", 0)
		GameState.set_flag("school.talking", false)
		Game.current.say("The headteacher's eyes narrow. \"Back to your classroom, Miss Covenant.\" He goes back into his office.")
		return
	_linger_t = 0.0
	GameState.set_flag("school.talking")
	GameState.set_flag("school.talk_step", step + 1)
	if step + 1 < TALK.size():
		Game.current.say("The headteacher steps out into the corridor. \"%s\"" % TALK[step + 1][0])
	else:
		Game.current.say("\"Well... I'll think about it. Run along.\" He lingers a moment in the corridor, frowning at a notice board.")


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if GameState.get_flag("school.distracted", false):
		_distract_t += delta
		if _distract_t > DISTRACT_SECONDS:
			GameState.set_flag("school.distracted", false)
	var step: int = GameState.get_flag("school.talk_step", 0)
	if GameState.get_flag("school.talking", false) and step >= TALK.size():
		_linger_t += delta
		if _linger_t > LINGER_SECONDS:
			GameState.set_flag("school.talking", false)
			GameState.set_flag("school.talk_step", 0)
	# The headteacher, at his desk, sees anyone climbing into his office.
	var jason := Game.current.get_player(1)
	if jason == null or Game.current.level_for("jason") != self or GameState.get_flag("school.talking", false) \
			or GameState.get_flag("b5.recovered", false) or not GameState.get_flag("b5.confiscated", false):
		return
	var at := to_local(jason.global_position)
	if at.x > 6.3 and at.x < 13.7 and at.z < 5.8 and sees(get_node("Headteacher"), jason, 12.0, 360.0):
		jason.teleport.rpc(to_global(Vector3(17, 1, 0)), -PI / 2)
		Game.current.say("\"MR COVENANT!\" Jason is out of the window again before the headteacher is out of his chair.", "jason")


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.present = "!b4.away"
	rick.lines = [
		["", "Psst! If someone keeps the teacher busy, Jason could be out of that window in a second. Julia, ask her something!"],
		["b5.jason_out", "He's gone! Nice one, Julia. ...You're good at this. Really good."],
		["b5.confiscated", "The keys are in his office. Julia, if you keep him talking at his door, Jason can climb in through the window from the yard."],
		["b5.recovered", "We've got them back! Now: Fred at the town hall, and the station."],
	]
	place(rick, "Rick", Vector3(-3, 1, 3.6))
