extends Node3D
## Symbol puzzle. Julia sees a big shape on the west wall (render layer 2, which
## Jason's camera culls). Jason climbs the stairs on the east side and presses the
## matching shape; the host validates the press and opens the door for everyone.
## Only the host (Jason) can press, so no press RPC is needed: the host decides and
## broadcasts results.

const CLUE_LAYER := 2 # bit 1; see player.gd camera cull mask
const BUTTON_Z := [-8.4, -7.6, -6.8, -6.0]
const BUTTON_POS_X := 9.6
const BUTTON_Y := 3.9
const REACH := 1.3
const DOOR_CLOSED_Y := 2.0
const DOOR_OPEN_Y := -2.1

var target := -1
var solved := false

var _buttons: Array[MeshInstance3D] = []
var _clue: MeshInstance3D
var _door: StaticBody3D
var _prompt: Label
var _message: Label


func _ready() -> void:
	_build_door()
	for i in 4:
		var b := MeshInstance3D.new()
		b.mesh = _shape_mesh(i, 0.5)
		b.rotation_degrees = _shape_rotation(i)
		b.position = Vector3(BUTTON_POS_X, BUTTON_Y, BUTTON_Z[i])
		b.material_override = _material(Color.WHITE)
		add_child(b)
		_buttons.append(b)

	var layer := CanvasLayer.new()
	_prompt = Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position.y -= 80
	_prompt.visible = false
	layer.add_child(_prompt)
	_message = Label.new()
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_message.position.y += 40
	layer.add_child(_message)
	add_child(layer)


## Host picks the target once and (re)broadcasts it, e.g. when Julia (re)joins.
func host_start() -> void:
	if target < 0:
		target = randi() % 4
	start.rpc(target, solved)


@rpc("authority", "call_local", "reliable")
func start(new_target: int, is_solved: bool) -> void:
	target = new_target
	solved = is_solved
	if _clue:
		_clue.queue_free()
	_clue = MeshInstance3D.new()
	_clue.mesh = _shape_mesh(target, 1.6)
	_clue.rotation_degrees = _shape_rotation(target)
	_clue.position = Vector3(-9.3, 2.5, 0)
	_clue.material_override = _material(Color(0.4, 0.9, 1.0))
	_clue.layers = CLUE_LAYER
	_clue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_clue)
	_door.position.y = DOOR_OPEN_Y if solved else DOOR_CLOSED_Y


func _process(_delta: float) -> void:
	_prompt.visible = false
	if solved or target < 0 or not multiplayer.is_server():
		return
	var me := get_node_or_null("../Players/1") as Node3D
	if me == null:
		return
	var nearest := -1
	var best := REACH
	for i in _buttons.size():
		var d := me.global_position.distance_to(_buttons[i].global_position)
		if d < best:
			best = d
			nearest = i
	if nearest < 0:
		return
	_prompt.text = "[E] / (X) Press"
	_prompt.visible = true
	if Input.is_action_just_pressed("interact"):
		_press(nearest)


func _press(index: int) -> void:
	var ok := index == target
	feedback.rpc(index, ok)
	if ok:
		solved = true
		open_door.rpc()


@rpc("authority", "call_local", "reliable")
func feedback(index: int, ok: bool) -> void:
	var mat := _buttons[index].material_override as StandardMaterial3D
	mat.albedo_color = Color(0.2, 0.9, 0.3) if ok else Color(0.9, 0.2, 0.2)
	_message.text = "The door rumbles open!" if ok else "Nothing happens..."
	await get_tree().create_timer(0.6).timeout
	if not ok:
		mat.albedo_color = Color.WHITE


@rpc("authority", "call_local", "reliable")
func open_door() -> void:
	solved = true
	var tween := create_tween()
	tween.tween_property(_door, "position:y", DOOR_OPEN_Y, 1.5)


func _build_door() -> void:
	_door = StaticBody3D.new()
	_door.position = Vector3(0, DOOR_CLOSED_Y, -10)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3, 4, 0.5)
	mesh.mesh = box
	mesh.material_override = _material(Color(0.45, 0.3, 0.15))
	_door.add_child(mesh)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box.size
	shape.shape = bs
	_door.add_child(shape)
	add_child(_door)


func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


## 0 sphere, 1 cube, 2 triangular prism, 3 cylinder.
func _shape_mesh(index: int, size: float) -> Mesh:
	match index:
		0:
			var s := SphereMesh.new()
			s.radius = size / 2.0
			s.height = size
			return s
		1:
			var b := BoxMesh.new()
			b.size = Vector3.ONE * size
			return b
		2:
			var p := PrismMesh.new()
			p.size = Vector3(size, size, size)
			return p
		_:
			var c := CylinderMesh.new()
			c.top_radius = size / 2.0
			c.bottom_radius = size / 2.0
			c.height = size
			return c


## Orient shapes so their profile faces the east/west walls (normal along x).
func _shape_rotation(index: int) -> Vector3:
	match index:
		2:
			return Vector3(0, 90, 0)
		3:
			return Vector3(0, 0, 90)
		_:
			return Vector3.ZERO
