class_name JournalNote
extends Interactable
## A note, inscription or page. Reading it adds an entry to Ulysses' journal.
## With `who` = "julia" only Julia can read it, and with `entry_who` = "julia"
## only her journal shows the entry.

@export var entry_id := ""
@export var title := ""
@export_multiline var body := ""
@export var entry_who := "both"
@export var size := Vector3(0.6, 0.8, 0.05)


func _init() -> void:
	prompt = "Read"


func is_available() -> bool:
	return not GameState.has_journal(entry_id)


func _build() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = Vis.material(Color(0.92, 0.88, 0.75))
	add_child(mesh)


func _host_interact(_player: Node3D) -> void:
	GameState.add_journal(entry_id, title, body, entry_who)
