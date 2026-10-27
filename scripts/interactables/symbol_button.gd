class_name SymbolButton
extends Interactable
## One shape button of a symbol puzzle. GameState holds "<puzzle>.target" (the
## shape index the host picked) and "<puzzle>.solved". Pressing the matching
## shape solves the puzzle; a wrong one flashes red.

@export var puzzle := "symbol_puzzle"
@export var index := 0

var _mesh: MeshInstance3D


func _init() -> void:
	prompt = "Press"
	reach = 1.3


func _available() -> bool:
	return GameState.get_flag(puzzle + ".target", -1) >= 0 and not GameState.get_flag(puzzle + ".solved", false)


func _build() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.mesh = Shapes.mesh(index, 0.5)
	_mesh.rotation_degrees = Shapes.rotation(index)
	_mesh.material_override = Vis.material(Color.WHITE)
	add_child(_mesh)


func refresh() -> void:
	if GameState.get_flag(puzzle + ".solved", false) and index == GameState.get_flag(puzzle + ".target", -1):
		(_mesh.material_override as StandardMaterial3D).albedo_color = Color(0.2, 0.9, 0.3)


func _host_interact(_player: Node3D) -> void:
	if index == GameState.get_flag(puzzle + ".target", -1):
		GameState.set_flag(puzzle + ".solved")
		Game.current.say("The door rumbles open!")
	else:
		_flash_wrong.rpc()
		Game.current.say("Nothing happens...")


@rpc("authority", "call_local", "reliable")
func _flash_wrong() -> void:
	var mat := _mesh.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.9, 0.2, 0.2)
	await get_tree().create_timer(0.6).timeout
	mat.albedo_color = Color.WHITE
