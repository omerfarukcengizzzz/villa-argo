extends Level
## Inside Peter Dedalus's House of Mirrors, book 3 (docs/book3-design.md,
## steps 7-11): the split-view maze (each twin sees a different house, neither
## true), the owl clock, the Bakelite telephone, the chess game across the
## centuries, and Dedalus's study. Canon: illusions, machines, the owl clock,
## the telephone, the chess game, the study's revelations (ref B3, HIGH/MEDIUM);
## every mechanism and solution is adaptation. Then (steps 12-13) Oblivia
## arrives with a demolition crew: the twins hide, watch her go through the
## Lion Door to Venice (canon, MEDIUM-HIGH; they don't follow), and race out
## before the house comes down (the race is adaptation). Phases (flag
## b3.phase): "" -> crew -> oblivia -> race -> escaped.
##
## Map (north = -z): entrance hall z 0..6; the maze, 5x5 cells of 3 m
## (x -7.5..7.5, z -15..0); the clock room north of it (z -25..-15); the chess
## room west (x -25..-7.5, z -28..-12); the study north of that (z -37..-28).

const KILMORE_COVE := "res://scenes/levels/kilmore_cove.tscn"
const MIRROR := Color(0.78, 0.84, 0.9)
const RACE_SECONDS := 150
const STUDY := Vector3(-16, 1, -31)
const PLAIN := Color(0.6, 0.6, 0.65)

## The maze's true path, as cells (col, row; row 0 is north). Entrance south of
## (2, 4), exit north of (2, 0).
const PATH := [Vector2i(2, 4), Vector2i(2, 3), Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 1),
	Vector2i(2, 1), Vector2i(3, 1), Vector2i(3, 0), Vector2i(2, 0)]

## Owl clock: a quarter past four (the guide's opening time).
const CLOCK_HOUR := 4
const CLOCK_QUARTER := 1
const PHONE_NUMBER := "77"

## Chess: the game starts after 1. e4 e5; white plays a trap known for
## centuries (the "schoolboy's mate"). [from, to] per white move, and black's
## reply after each of the first two.
const MOVES := [["f1", "c4"], ["d1", "h5"], ["h5", "f7"]]
const REPLIES := [["b8", "c6"], ["g8", "f6"]]
## Where each movable white piece may be sent, by the square it stands on.
const OPTIONS := {
	"f1": ["c4", "d3", "e2", "b5"], "c4": ["b5", "d5", "e6", "f7"],
	"d1": ["h5", "g4", "f3", "e2"], "h5": ["f7", "h7", "g6", "e5"],
	"g1": ["f3", "h3", "e2"], "b1": ["c3", "a3"],
}
## Movable white pieces: node name -> [starting square, name].
const MOVABLE := {"WhiteBishop": ["f1", "bishop"], "WhiteQueen": ["d1", "queen"],
	"KingsKnight": ["g1", "knight"], "QueensKnight": ["b1", "knight"]}

var _pieces: Node3D
var _lion: MeshInstance3D
var _phase_t := 0.0


func _init() -> void:
	origin = Vector3(9000, 0, 0)


func _build() -> void:
	entries = {"default": {"jason": Vector3(-1, 1, 4), "julia": Vector3(1, 1, 4)}}
	add_environment(Color(0.55, 0.6, 0.7))
	add_box(Vector3(34, 0.5, 45), Vector3(-9, -0.25, -15.5), Color(0.45, 0.42, 0.4))

	_build_hall()
	_build_maze()
	_build_clock_room()
	_build_chess_room()
	_build_study()
	_build_finale()
	_build_rick()

	GameState.changed.connect(_on_state_changed)
	_on_state_changed("")


func _on_state_changed(_key: String) -> void:
	_draw_board()
	_lion.visible = not GameState.get_flag("lion.open", false)
	if multiplayer.is_server():
		_check_clock()


func _wall(size: Vector3, pos: Vector3, color := PLAIN) -> StaticBody3D:
	return add_box(size, pos, color)


# --- Entrance hall --------------------------------------------------------------

func _build_hall() -> void:
	_wall(Vector3(15, 4, 0.4), Vector3(0, 2, 6.2))
	_wall(Vector3(0.4, 4, 6), Vector3(-7.5, 2, 3))
	_wall(Vector3(0.4, 4, 6), Vector3(7.5, 2, 3))
	add_label("Welcome to my house.\nDon't trust your eyes. Trust each other.\n                P. D.", Vector3(0, 2.6, 5.9), 180).font_size = 36
	var out := LevelExit.new()
	out.level = KILMORE_COVE
	out.entry = "mirror_house"
	out.prompt = "Leave the House of Mirrors"
	out.requires = "!b3.phase=crew & !b3.phase=oblivia"
	out.on_used = func(_p: Node3D) -> void:
		if str(GameState.get_flag("b3.phase", "")) == "race":
			_escaped()
	place(out, "ExitToVillage", Vector3(0, 1, 5))


# --- The split-view maze (step 7) --------------------------------------------------

func cell_center(c: Vector2i) -> Vector3:
	return Vector3(-6 + 3 * c.x, 0, -13.5 + 3 * c.y)


## Every wall is drawn for Jason only, for Julia only, or for both. Walls on the
## true path are illusions (drawn for one twin, not solid); every other inner
## wall is solid, and two out of three are drawn for one twin only. So a wall
## both twins see is real; anything else they have to talk over, or test.
func _build_maze() -> void:
	# Outer walls, with the entrance (south) and exit (north) in column 2.
	for z in [0.0, -15.0]:
		_wall(Vector3(6, 4, 0.4), Vector3(-4.5, 2, z), MIRROR)
		_wall(Vector3(6, 4, 0.4), Vector3(4.5, 2, z), MIRROR)
	_wall(Vector3(0.4, 4, 15), Vector3(-7.5, 2, -7.5), MIRROR)
	_wall(Vector3(0.4, 4, 15), Vector3(7.5, 2, -7.5), MIRROR)

	var path_edges := {}
	for i in PATH.size() - 1:
		path_edges[_edge_key(PATH[i], PATH[i + 1])] = i
	for r in 5:
		for c in 5:
			var a := Vector2i(c, r)
			for b in [Vector2i(c + 1, r), Vector2i(c, r + 1)]:
				if b.x > 4 or b.y > 4:
					continue
				var key := _edge_key(a, b)
				var horizontal: bool = b.y != a.y
				var pos := (cell_center(a) + cell_center(b)) / 2.0 + Vector3(0, 2, 0)
				var size := Vector3(3, 4, 0.3) if horizontal else Vector3(0.3, 4, 3)
				if path_edges.has(key):
					_view_wall(size, pos, false, "jason" if path_edges[key] % 2 == 0 else "julia")
				else:
					_view_wall(size, pos, true, ["both", "jason", "julia"][(c * 7 + r * 3 + int(horizontal)) % 3])


func _edge_key(a: Vector2i, b: Vector2i) -> String:
	var lo := a if a.x + a.y * 10 < b.x + b.y * 10 else b
	var hi := b if lo == a else a
	return "%d,%d-%d,%d" % [lo.x, lo.y, hi.x, hi.y]


func _view_wall(size: Vector3, pos: Vector3, solid: bool, who: String) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := Vis.material(MIRROR)
	mat.metallic = 0.6
	mat.roughness = 0.2
	mesh.material_override = mat
	mesh.position = pos
	if who != "both":
		Vis.make_private(mesh, who)
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		body.add_child(shape)
		add_child(body)


# --- Owl clock and telephone (steps 8-9) ------------------------------------------

func _build_clock_room() -> void:
	_wall(Vector3(0.4, 4, 4), Vector3(-7.5, 2, -17))
	_wall(Vector3(0.4, 4, 4), Vector3(-7.5, 2, -23))
	_wall(Vector3(0.4, 8, 10), Vector3(7.5, 4, -20))
	_wall(Vector3(15, 8, 0.4), Vector3(0, 4, -25))

	# The owl clock, high on the north wall; Jason climbs the cabinet below it.
	add_climb_wall(Vector3(3, 5, 1.2), Vector3(0, 2.5, -24.2))
	var face := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.1
	face.mesh = cyl
	face.rotation_degrees.x = 90
	face.position = Vector3(0, 7, -24.7)
	face.material_override = Vis.material(Color(0.9, 0.85, 0.7))
	add_child(face)
	add_label("an owl-shaped clock", Vector3(0, 8.4, -24.6), 0).font_size = 28
	for i in 12:
		var mark := add_label(str(12 if i == 0 else i), Vector3(0, 7, -24.62) + Vector3(sin(TAU * i / 12.0), cos(TAU * i / 12.0), 0) * 0.82, 0)
		mark.font_size = 20
	var hour := Dial.new()
	hour.who = "jason"
	hour.flag = "clock.h"
	hour.steps = 12
	hour.length = 0.5
	hour.width = 0.1
	hour.prompt = "Turn the hour hand"
	hour.requires = "!clock.solved"
	place(hour, "HourHand", Vector3(0, 7, -24.6))
	var minute := Dial.new()
	minute.who = "jason"
	minute.flag = "clock.m"
	minute.steps = 4
	minute.length = 0.8
	minute.width = 0.05
	minute.prompt = "Turn the minute hand"
	minute.requires = "!clock.solved"
	minute.reach = 2.0
	place(minute, "MinuteHand", Vector3(0, 7, -24.58))

	# The black Bakelite telephone.
	_wall(Vector3(1.2, 1, 0.8), Vector3(5, 0.5, -19))
	var answer := JournalNote.new()
	answer.requires = "clock.solved"
	answer.entry_id = "dedalus_voice"
	answer.title = "A voice on the telephone"
	answer.body = "A crackly recording, an old man's voice:\n\"If you've set my owl right, you're in my house, and you're no fool. Now ring me at home, and I'll let you into the room where I play.\"\nAt home? This is his home. Unless he means the number in the guide."
	answer.prompt = "Pick up the ringing telephone"
	answer.size = Vector3(0.4, 0.2, 0.25)
	place(answer, "Telephone", Vector3(5, 1.1, -19))
	var dial := CodeEntry.new()
	dial.requires = "journal:dedalus_voice"
	dial.answer = PHONE_NUMBER
	dial.solved_flag = "phone.solved"
	dial.prompt = "Dial a number"
	dial.question = "Kilmore Cove ..."
	dial.wrong_text = "A click, then nothing. Wrong number."
	dial.size = Vector3(0.01, 0.01, 0.01)
	dial.on_used = func(_p: Node3D) -> void:
		Game.current.say("It rings... and somewhere in the house a lock clicks. The door to the west swings open.")
	place(dial, "Dial", Vector3(5, 1.0, -18.2))

	var chess_door := Door.new()
	chess_door.size = Vector3(2, 3, 0.3)
	chess_door.open_flag = "phone.solved"
	chess_door.color = Color(0.35, 0.25, 0.18)
	place(chess_door, "ChessDoor", Vector3(-7.5, 0, -20)).rotation_degrees.y = 90


func _check_clock() -> void:
	if GameState.get_flag("clock.solved", false):
		return
	if GameState.get_flag("clock.h", 0) == CLOCK_HOUR and GameState.get_flag("clock.m", 0) == CLOCK_QUARTER:
		GameState.set_flag("clock.solved")
		Game.current.say("The owl's eyes flash. Somewhere below, a telephone starts to ring.")


# --- The chess game across the centuries (step 10) --------------------------------

func square_pos(sq: String) -> Vector3:
	var file := sq.unicode_at(0) - "a".unicode_at(0)
	var rank := int(sq.substr(1)) - 1
	return Vector3(-22 + 0.75 + 1.5 * file, 0, -14 - 0.75 - 1.5 * rank)


## The board after `step` white moves (and black's replies): square -> piece,
## e.g. "wQ" or "bP".
func board_at(step: int) -> Dictionary:
	var board := {}
	var back := ["R", "N", "B", "Q", "K", "B", "N", "R"]
	for f in 8:
		var file := char("a".unicode_at(0) + f)
		board[file + "1"] = "w" + back[f]
		board[file + "2"] = "wP"
		board[file + "7"] = "bP"
		board[file + "8"] = "b" + back[f]
	_move(board, "e2", "e4")
	_move(board, "e7", "e5")
	for i in step:
		_move(board, MOVES[i][0], MOVES[i][1])
		if i < REPLIES.size():
			_move(board, REPLIES[i][0], REPLIES[i][1])
	return board


func _move(board: Dictionary, from: String, to: String) -> void:
	board[to] = board[from]
	board.erase(from)


## Where a white piece that started on `start` stands after `step` moves.
func piece_square(start: String, step: int) -> String:
	var sq := start
	for i in step:
		if MOVES[i][0] == sq:
			sq = MOVES[i][1]
	return sq


func _build_chess_room() -> void:
	_wall(Vector3(17.5, 4, 0.4), Vector3(-16.25, 2, -12))
	_wall(Vector3(0.4, 4, 16), Vector3(-25, 2, -20))
	_wall(Vector3(0.4, 4, 3), Vector3(-7.5, 2, -26.5))
	_wall(Vector3(8, 4, 0.4), Vector3(-21, 2, -28))
	_wall(Vector3(7.5, 4, 0.4), Vector3(-11.25, 2, -28))
	for f in 8:
		for r in 8:
			var sq := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(1.5, 0.05, 1.5)
			sq.mesh = b
			sq.material_override = Vis.material(Color(0.85, 0.8, 0.65) if (f + r) % 2 == 1 else Color(0.3, 0.22, 0.15))
			sq.position = square_pos(char(97 + f) + str(r + 1)) + Vector3(0, 0.025, 0)
			add_child(sq)
		add_label(char(97 + f), square_pos(char(97 + f) + "1") + Vector3(0, 0.06, 1.1), 0).rotation_degrees.x = -90
	for r in 8:
		add_label(str(r + 1), square_pos("a" + str(r + 1)) + Vector3(-1.1, 0.06, 0), 0).rotation_degrees.x = -90
	add_label("\"A game between centuries. White to play, and win.\"  P. D.", Vector3(-16, 3.2, -12.3), 180).font_size = 30

	# Julia's mirror shows the moves; on Jason's side it's just a mirror.
	var glass := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(4, 2.5, 0.1)
	glass.mesh = gb
	var shine := Vis.material(MIRROR)
	shine.metallic = 1.0
	shine.roughness = 0.05
	glass.material_override = shine
	glass.position = Vector3(-24.8, 2, -20)
	glass.rotation_degrees.y = 90
	add_child(glass)
	var moves := add_label("In the mirror, the game plays itself:\n1. Bishop to c4\n2. Queen to h5\n3. Queen takes on f7. Checkmate.", Vector3(-24.7, 2, -20), 90)
	moves.font_size = 32
	Vis.make_private(moves, "julia")

	_pieces = Node3D.new()
	_pieces.name = "Pieces"
	add_child(_pieces)

	for node_name in MOVABLE:
		var piece := ChoicePoint.new()
		piece.who = "jason"
		piece.prompt = "Move the brass %s" % MOVABLE[node_name][1]
		piece.question = "Move the %s to..." % MOVABLE[node_name][1]
		piece.requires = "phone.solved & !chess.solved"
		var start: String = MOVABLE[node_name][0]
		piece.options_for = func() -> Array:
			var at := piece_square(start, GameState.get_flag("chess.step", 0))
			return OPTIONS.get(at, []).map(func(sq: String) -> Array: return [sq, true])
		piece.on_choice = func(_p: Node3D, to: String) -> void: _play(start, to)
		place(piece, node_name, square_pos(start) + Vector3(0, 0.9, 0))


## Host: a white move. Right: black answers (or it's mate). Wrong: back to start.
func _play(start: String, to: String) -> void:
	var step: int = GameState.get_flag("chess.step", 0)
	var from := piece_square(start, step)
	if [from, to] != MOVES[step]:
		GameState.set_flag("chess.step", 0)
		Game.current.say("The board shudders, and every piece slides back to where it started.")
		return
	GameState.set_flag("chess.step", step + 1)
	if step + 1 == MOVES.size():
		GameState.set_flag("chess.solved")
		Game.current.say("Checkmate. With a long, slow groan, a door opens in the north wall.")
	else:
		Game.current.say("Click. A black piece slides across the board by itself: %s to %s." % REPLIES[step])


func _draw_board() -> void:
	for child in _pieces.get_children():
		child.queue_free()
	var step: int = GameState.get_flag("chess.step", 0)
	var board := board_at(step)
	for sq in board:
		var p: String = board[sq]
		var mesh := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.45, 0.5 if p[1] == "P" else 0.9, 0.45)
		mesh.mesh = b
		mesh.material_override = Vis.material(Color(0.9, 0.75, 0.4) if p[0] == "w" else Color(0.15, 0.15, 0.15))
		mesh.position = square_pos(sq) + Vector3(0, b.size.y / 2.0 + 0.05, 0)
		_pieces.add_child(mesh)
		var tag := Label3D.new()
		tag.text = p[1]
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size = 40
		tag.position = mesh.position + Vector3(0, b.size.y / 2.0 + 0.25, 0)
		_pieces.add_child(tag)
	for node_name in MOVABLE:
		var piece: Node3D = get_node_or_null(node_name)
		if piece:
			piece.position = square_pos(piece_square(MOVABLE[node_name][0], step)) + Vector3(0, 0.9, 0)


# --- Dedalus's study (step 11) --------------------------------------------------

func _build_study() -> void:
	_wall(Vector3(0.4, 4, 9), Vector3(-25, 2, -32.5))
	_wall(Vector3(0.4, 4, 9), Vector3(-7.5, 2, -32.5))
	_wall(Vector3(17.5, 4, 0.4), Vector3(-16.25, 2, -37))
	var door := Door.new()
	door.size = Vector3(2, 3, 0.3)
	door.open_flag = "chess.solved"
	door.color = Color(0.35, 0.25, 0.18)
	place(door, "StudyDoor", Vector3(-16, 0, -28))

	_wall(Vector3(3, 0.9, 1.4), Vector3(-12, 0.45, -33), Color(0.4, 0.28, 0.18))
	add_label("Dedalus's desk", Vector3(-12, 1.6, -32.2), 0).font_size = 26
	var doors := JournalNote.new()
	doors.requires = "chess.solved"
	doors.entry_id = "other_doors"
	doors.title = "Dedalus's notes: the Doors"
	doors.body = "Dedalus's notebooks, full of drawings of doors with animal-head keyholes: a cat, a lion, a horse, and more. \"Kilmore Cove has more than one Door,\" he writes. \"Each has its own key and leads to one place only.\"\nAnd, underlined three times: \"But there is one key that opens them all: the First Key. Three turtles.\"\nThree turtles, like the altar in Punt."
	doors.prompt = "Read Dedalus's notebooks"
	doors.size = Vector3(0.6, 0.1, 0.45)
	doors.on_used = func(_p: Node3D) -> void: _study_read()
	place(doors, "Notebooks", Vector3(-12.6, 1.0, -33))
	var photo := JournalNote.new()
	photo.requires = "chess.solved"
	photo.entry_id = "venice_photo"
	photo.title = "A photograph on the desk"
	photo.body = "An old photograph: Peter Dedalus and Penelope Moore, Ulysses's wife, laughing on a little bridge over a canal. On the back, in Dedalus's hand: \"Venice. One day I'll go back.\"\nIs that where he went?"
	photo.prompt = "Look at the photograph"
	photo.size = Vector3(0.25, 0.05, 0.2)
	photo.on_used = func(_p: Node3D) -> void: _study_read()
	place(photo, "Photograph", Vector3(-11.2, 1.0, -33))

	# The Lion Door, behind the tallest mirror (canon, MEDIUM).
	_lion = MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(0.15, 3.2, 2)
	_lion.mesh = lb
	var shine := Vis.material(MIRROR)
	shine.metallic = 1.0
	shine.roughness = 0.05
	_lion.material_override = shine
	_lion.position = Vector3(-24.8, 1.6, -32.5)
	add_child(_lion)
	add_box(Vector3(0.1, 3.2, 2), Vector3(-25.1, 1.6, -32.5), Color(0.05, 0.05, 0.08))
	add_label("a tall mirror framed with a carved lion's head", Vector3(-24.6, 3.6, -32.5), 90).font_size = 24


func _study_read() -> void:
	if GameState.has_journal("other_doors") and GameState.has_journal("venice_photo") and not GameState.get_flag("b3.study_done", false):
		GameState.set_flag("b3.study_done")
		GameState.give_item("dedalus_notebook", "Dedalus's notebook")
		GameState.set_flag("b3.phase", "crew")
		Game.current.say("Engines roar outside. Heavy machines, and voices coming up the path. Quick, hide!")


# --- Oblivia and the demolition race (steps 12-13) --------------------------------

func _build_finale() -> void:
	var desk := Switch.new()
	desk.who = "jason"
	desk.flag = "hide.jason"
	desk.prompt = "Duck under the desk"
	desk.requires = "b3.phase=crew"
	place(desk, "HideDesk", Vector3(-12, 1, -34))
	add_box(Vector3(0.2, 3, 2), Vector3(-8.2, 1.5, -35.5), Color(0.5, 0.15, 0.15))
	add_label("heavy curtain", Vector3(-8.4, 3.2, -35.5), -90).font_size = 24
	var curtain := Switch.new()
	curtain.who = "julia"
	curtain.flag = "hide.julia"
	curtain.prompt = "Hide behind the curtain"
	curtain.requires = "b3.phase=crew"
	place(curtain, "HideCurtain", Vector3(-9, 1, -35.5))

	var oblivia := Npc.new()
	oblivia.npc_name = "Oblivia Newton"
	oblivia.color = Color(0.6, 0.15, 0.3)
	oblivia.who = "nobody"
	oblivia.present = "b3.phase=oblivia & !lion.through"
	oblivia.walk_speed = 3.0
	oblivia.stations = [["", Vector3(-16, 1, -27)], ["b3.phase=oblivia", Vector3(-23.5, 1, -32.5)], ["lion.open", Vector3(-26, 1, -32.5)]]
	place(oblivia, "Oblivia", Vector3(-16, 1, -27))
	var manfred := Npc.new()
	manfred.npc_name = "Manfred"
	manfred.color = Color(0.25, 0.25, 0.3)
	manfred.who = "nobody"
	manfred.present = "b3.phase=oblivia"
	manfred.walk_speed = 3.0
	manfred.stations = [["", Vector3(-16, 1, -27)], ["b3.phase=oblivia", Vector3(-19, 1, -30)]]
	place(manfred, "Manfred", Vector3(-15, 1, -26.5))

	# Falling plaster in the chess room during the race.
	for i in 3:
		var plaster := Hazard.new()
		plaster.active = "b3.phase=race"
		plaster.size = Vector3(2.5, 1.0, 2.5)
		plaster.color = Color(0.85, 0.82, 0.75)
		plaster.label = "falling plaster"
		plaster.respawn = Vector3(-16, 1, -26.5)
		plaster.message = "Plaster crashes down in front of you! You stagger back."
		plaster.travel = Vector3(0, -3.5, 0)
		plaster.period = 3.0 + i * 0.7
		plaster.phase = i * 1.7
		place(plaster, "Plaster%d" % i, Vector3(-14 + i * 2.5, 4.0, -23 + i * 1.5))


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	var phase := str(GameState.get_flag("b3.phase", ""))
	_phase_t += delta
	match phase:
		"crew":
			if GameState.get_flag("hide.jason", false) and GameState.get_flag("hide.julia", false):
				_phase_t = 0.0
				GameState.set_flag("b3.phase", "oblivia")
				Game.current.say("Footsteps in the study. From your hiding places you see them: Oblivia Newton, and Manfred behind her.")
		"oblivia":
			if _phase_t > 4.0 and not GameState.get_flag("lion.open", false):
				GameState.set_flag("lion.open")
				Game.current.say("Oblivia runs a hand over the lion's head and turns a small golden key. The tall mirror swings open like a door. \"Venice, then. Let's see if dear Peter still remembers me.\"")
			elif _phase_t > 8.0 and not GameState.get_flag("lion.through", false):
				GameState.set_flag("lion.through")
				GameState.add_journal("lion_door", "The Lion Door",
					"We hid in Dedalus's study and saw it: Oblivia Newton opened the mirror with the lion's head using a small golden key, and stepped through. To Venice: she said so. She's going after Peter Dedalus.\nThe mirror closed behind her, and it won't open for us.")
				Game.current.say("She steps through the mirror, and it swings shut. Manfred grins at the ceiling: \"You heard the lady. Bring it down!\" He stamps out. The walls begin to shake.")
			elif _phase_t > 11.0:
				GameState.set_flag("lion.open", false)
				_start_race()
		"race":
			if _phase_t >= 1.0:
				_phase_t = 0.0
				var left: int = GameState.get_flag("race.left", RACE_SECONDS) - 1
				GameState.set_flag("race.left", left)
				if left > 0 and left % 30 == 0:
					Game.current.say("The walls shake! %d seconds!" % left)
				elif left <= 0:
					_race_lost()


func _start_race() -> void:
	_phase_t = 0.0
	GameState.set_flag("race.left", RACE_SECONDS)
	GameState.set_flag("b3.phase", "race")
	Game.current.say("The house is coming down! Get out, the way you came in! You have %d seconds." % RACE_SECONDS)


## Time's up: the twins wake in the study, and the crew starts again.
func _race_lost() -> void:
	for p in Game.current.get_players():
		p.teleport.rpc(to_global(STUDY + Vector3(-1 if p.role == "jason" else 1, 0, 0)), PI)
	GameState.set_flag("race.left", RACE_SECONDS)
	Game.current.say("A beam crashes down and everything goes dark... You come round in the study, coughing. The crew is backing up for another go. Run!")


## Host: both twins made it out (called by the hall exit).
func _escaped() -> void:
	GameState.set_flag("b3.phase", "escaped")
	GameState.set_flag("b3.escaped")
	Game.current.say("You burst out into the daylight just as half the house folds in behind you. Then Mr Minaxo and Calypso come striding up the road with half the village, and the crew decides to call it a day.")
	GameState.add_journal("book3_end", "What we know now",
		"Kilmore Cove isn't on any map. There are other Doors in it, and one key, the First Key, opens all of them.\nPeter Dedalus is in Venice, and Oblivia Newton has gone after him through the Lion Door. If he tells her where the First Key is...\nWe have to get to Venice before she finds him.")
	Game.current.say_later("End of book 3: The House of Mirrors. (Book 4, The Isle of Masks, comes next.)", 5.0)


func _build_rick() -> void:
	var rick := Npc.new()
	rick.npc_name = "Rick"
	rick.color = Color(0.85, 0.4, 0.2)
	rick.walk_speed = 5.0
	rick.stations = [
		["", Vector3(3, 1, 3.5)],
		["clock.solved", Vector3(3, 1, -17)],
		["phone.solved", Vector3(-9, 1, -13.5)],
		["chess.solved", Vector3(-9, 1, -30)],
		["b3.phase=race", Vector3(1, 1, 3)],
	]
	rick.lines = [
		["", "\"Don't trust your eyes. Trust each other.\" Tell each other what walls you see. If you both see it, it's real. If only one of you does... try walking through it."],
		["clock.solved", "A telephone ringing in an empty house. Answer it!"],
		["journal:dedalus_voice", "Ring him at home? Julia, the guide had a number for the House of Mirrors!"],
		["phone.solved", "A chessboard. Julia, can you see anything in that mirror? Jason, the pieces are brass: you'll have to move them."],
		["chess.solved", "His study! Look at everything."],
		["b3.study_done", "Other Doors... and a key that opens all of them. If Oblivia's got the map, she knows where they are."],
		["b3.phase=crew", "Someone's coming! Jason, under the desk! Julia, behind the curtain!"],
		["b3.phase=race", "Run! Back through the chess room, the clock room and the maze! Mind the plaster!"],
	]
	place(rick, "Rick", Vector3(3, 1, 3.5))
