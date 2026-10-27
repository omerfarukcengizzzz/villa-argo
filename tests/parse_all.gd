extends SceneTree
# Loads every script under res://scripts and res://tests and reports parse
# errors (an --import run does not). Usage: --headless -s tests/parse_all.gd


func _initialize() -> void:
	var bad := 0
	for dir in ["res://scripts", "res://tests"]:
		bad += _check_dir(dir)
	print("PARSE %s (%d bad)" % ["OK" if bad == 0 else "FAILED", bad])
	quit(1 if bad else 0)


func _check_dir(path: String) -> int:
	var bad := 0
	for f in DirAccess.get_files_at(path):
		if f.ends_with(".gd"):
			var script: GDScript = load(path + "/" + f)
			if script == null or not script.can_instantiate():
				print("BAD " + path + "/" + f)
				bad += 1
	for d in DirAccess.get_directories_at(path):
		bad += _check_dir(path + "/" + d)
	return bad
