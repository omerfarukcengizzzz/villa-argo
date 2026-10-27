class_name Vis
## Per-twin private visuals. Meshes on a twin's private render layer are drawn
## only by that twin's camera (see player.gd), and cast no shadows so they can't
## leak to the other twin.

const JULIA_ONLY_LAYER := 2
const JASON_ONLY_LAYER := 3


static func make_private(g: GeometryInstance3D, role: String) -> void:
	g.layers = 1 << ((JULIA_ONLY_LAYER if role == "julia" else JASON_ONLY_LAYER) - 1)
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## The layer that `role`'s camera must not draw.
static func hidden_layer_for(role: String) -> int:
	return JULIA_ONLY_LAYER if role == "jason" else JASON_ONLY_LAYER


static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m
