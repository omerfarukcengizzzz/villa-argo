class_name Npc
extends Interactable
## A character the twins can talk to (gray-box: a capsule with a name tag).
## `lines` is a list of [condition, text]; talking says the last line whose
## GameState condition holds, so later story states override earlier ones.
## `present` is the condition for the character to be here at all, and
## `stations` ([condition, position] pairs, last match wins) moves them along
## as the story goes on; they walk there at `walk_speed` (0 = jump there).
## Story effects of talking go in `on_used` (runs after the line is chosen).

@export var npc_name := ""
@export var color := Color(0.5, 0.65, 0.4)
@export var present := ""
@export var walk_speed := 0.0

var lines: Array = []
var stations: Array = []

var _walk: Tween
var _target = null


func _init() -> void:
	prompt = "Talk"
	reach = 2.2


func _available() -> bool:
	return GameState.check(present)


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.8
	mesh.mesh = cm
	mesh.material_override = Vis.material(color)
	add_child(mesh)
	var tag := Label3D.new()
	tag.text = npc_name
	tag.position.y = 1.3
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 40
	add_child(tag)


func refresh() -> void:
	visible = GameState.check(present)
	var target = null
	for station in stations:
		if GameState.check(station[0]):
			target = station[1]
	if target == null or target == _target:
		return
	_target = target
	if _walk:
		_walk.kill()
	if walk_speed <= 0.0 or not is_node_ready():
		position = target
	else:
		var dir: Vector3 = target - position
		if Vector2(dir.x, dir.z).length() > 0.01:
			rotation.y = atan2(-dir.x, -dir.z)
		_walk = create_tween()
		_walk.tween_property(self, "position", target, position.distance_to(target) / walk_speed)


func current_line() -> String:
	var text := ""
	for line in lines:
		if GameState.check(line[0]):
			text = line[1]
	return text


func _host_interact(_player: Node3D) -> void:
	var text := current_line()
	if text != "":
		Game.current.say("%s: %s" % [npc_name, text])
