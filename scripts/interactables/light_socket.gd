class_name LightSocket
extends Interactable
## A niche where a light can be placed (book 1: a ball of glowing clay). Once
## `lit_flag` is set, its light shines for both twins.

@export var lit_flag := ""
@export var light_color := Color(1.0, 0.85, 0.45)
@export var light_range := 7.0

var _ball: MeshInstance3D
var _light: OmniLight3D


func _init() -> void:
	prompt = "Place a glowing clay ball"
	reach = 1.6


func _available() -> bool:
	return not GameState.get_flag(lit_flag, false)


func _build() -> void:
	var niche := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.1, 0.5)
	niche.mesh = box
	niche.position.y = -0.2
	niche.material_override = Vis.material(Color(0.3, 0.28, 0.25))
	add_child(niche)
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	_ball.mesh = sphere
	var glow := Vis.material(light_color)
	glow.emission_enabled = true
	glow.emission = light_color
	glow.emission_energy_multiplier = 2.0
	_ball.material_override = glow
	add_child(_ball)
	_light = OmniLight3D.new()
	_light.light_color = light_color
	_light.omni_range = light_range
	_light.light_energy = 1.5
	_light.position.y = 0.3
	add_child(_light)


func refresh() -> void:
	var lit: bool = GameState.get_flag(lit_flag, false)
	_ball.visible = lit
	_light.visible = lit


func _host_interact(_player: Node3D) -> void:
	GameState.set_flag(lit_flag)
