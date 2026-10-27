class_name LevelExit
extends Interactable
## Takes both twins to another level. Both must be close by, so nobody gets
## dragged along from across the map.

@export_file("*.tscn") var level := ""
## Which entry point of the target level to arrive at.
@export var entry := "default"
@export var gather_radius := 5.0


func _init() -> void:
	prompt = "Go through"
	reach = 2.0


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.5, 0.05, 2.5)
	mesh.mesh = box
	mesh.material_override = Vis.material(Color(0.3, 0.8, 0.9, 0.5))
	mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.position.y = -0.9
	add_child(mesh)


func _host_interact(player: Node3D) -> void:
	var players := Game.current.get_players()
	var together := players.size() == 2 and players.all(
		func(p: Node3D) -> bool: return p.global_position.distance_to(global_position) <= gather_radius)
	if together:
		Game.current.change_level(level, entry)
	else:
		Game.current.say("Both twins need to be here.", player.role)
