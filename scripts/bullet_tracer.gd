extends MeshInstance3D

var lifetime: float = 0.08
var timer: float = 0.0

func setup(start_pos: Vector3, end_pos: Vector3, is_shotgun: bool = false) -> void:
	var im = ImmediateMesh.new()
	mesh = im
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.4, 0.1, 0.9) if is_shotgun else Color(0.2, 0.9, 1.0, 0.9)
	mat.use_particle_trails = false
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = mat
	
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(start_pos)
	im.surface_add_vertex(end_pos)
	im.surface_end()

func _process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
	else:
		if material_override is StandardMaterial3D:
			var mat = material_override as StandardMaterial3D
			var alpha = 1.0 - (timer / lifetime)
			mat.albedo_color.a = alpha
