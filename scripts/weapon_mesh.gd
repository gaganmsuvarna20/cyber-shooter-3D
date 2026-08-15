extends Node3D

enum WeaponType { RIFLE, SHOTGUN, PLASMA_CANNON, HYPER_RAILGUN }

@export var weapon_type: WeaponType = WeaponType.RIFLE

func _ready() -> void:
	build_weapon_mesh()

func build_weapon_mesh() -> void:
	# Clear existing children
	for c in get_children():
		c.queue_free()
		
	match weapon_type:
		WeaponType.RIFLE:
			_build_rifle()
		WeaponType.SHOTGUN:
			_build_shotgun()
		WeaponType.PLASMA_CANNON:
			_build_plasma_cannon()
		WeaponType.HYPER_RAILGUN:
			_build_railgun()

func _build_rifle() -> void:
	# Main Gun Body
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.12, 0.14, 0.18)
	body_mat.metallic = 0.8
	body_mat.roughness = 0.3
	
	var neon_mat = StandardMaterial3D.new()
	neon_mat.albedo_color = Color(0.1, 0.8, 1.0)
	neon_mat.emission_enabled = true
	neon_mat.emission = Color(0.1, 0.8, 1.0)
	neon_mat.emission_energy_multiplier = 3.0

	# Receiver / Body
	var receiver = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.12, 0.45)
	receiver.mesh = box
	receiver.material_override = body_mat
	receiver.position = Vector3(0, 0, 0)
	add_child(receiver)

	# Barrel
	var barrel = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.02
	cyl.height = 0.35
	barrel.mesh = cyl
	barrel.material_override = body_mat
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.02, -0.35)
	add_child(barrel)

	# Magazine
	var mag = MeshInstance3D.new()
	var mag_box = BoxMesh.new()
	mag_box.size = Vector3(0.05, 0.18, 0.08)
	mag.mesh = mag_box
	mag.material_override = body_mat
	mag.rotation_degrees = Vector3(15, 0, 0)
	mag.position = Vector3(0, -0.12, -0.05)
	add_child(mag)

	# Glowing Strip
	var strip = MeshInstance3D.new()
	var strip_box = BoxMesh.new()
	strip_box.size = Vector3(0.086, 0.02, 0.40)
	strip.mesh = strip_box
	strip.material_override = neon_mat
	strip.position = Vector3(0, 0.04, -0.02)
	add_child(strip)
	
	# Muzzle marker node at tip of barrel
	var muzzle_node = Node3D.new()
	muzzle_node.name = "MuzzleMarker"
	muzzle_node.position = Vector3(0, 0.02, -0.55)
	add_child(muzzle_node)

func _build_shotgun() -> void:
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.18, 0.16, 0.15)
	body_mat.metallic = 0.6
	body_mat.roughness = 0.4

	var neon_mat = StandardMaterial3D.new()
	neon_mat.albedo_color = Color(1.0, 0.4, 0.1)
	neon_mat.emission_enabled = true
	neon_mat.emission = Color(1.0, 0.4, 0.1)
	neon_mat.emission_energy_multiplier = 3.0

	# Double Barrel
	for offset_x in [-0.025, 0.025]:
		var barrel = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.025
		cyl.bottom_radius = 0.025
		cyl.height = 0.45
		barrel.mesh = cyl
		barrel.material_override = body_mat
		barrel.rotation_degrees = Vector3(90, 0, 0)
		barrel.position = Vector3(offset_x, 0.02, -0.3)
		add_child(barrel)

	# Stock & Frame
	var frame = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.1, 0.14, 0.35)
	frame.mesh = box
	frame.material_override = body_mat
	frame.position = Vector3(0, -0.02, 0.05)
	add_child(frame)

	# Pump grip
	var pump = MeshInstance3D.new()
	var pump_box = BoxMesh.new()
	pump_box.size = Vector3(0.11, 0.08, 0.15)
	pump.mesh = pump_box
	pump.material_override = neon_mat
	pump.position = Vector3(0, -0.02, -0.25)
	add_child(pump)

	var muzzle_node = Node3D.new()
	muzzle_node.name = "MuzzleMarker"
	muzzle_node.position = Vector3(0, 0.02, -0.55)
	add_child(muzzle_node)

func _build_plasma_cannon() -> void:
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.08, 0.12, 0.15)
	body_mat.metallic = 0.9
	body_mat.roughness = 0.25

	var cyan_mat = StandardMaterial3D.new()
	cyan_mat.albedo_color = Color(0.0, 0.95, 1.0)
	cyan_mat.emission_enabled = true
	cyan_mat.emission = Color(0.0, 0.95, 1.0)
	cyan_mat.emission_energy_multiplier = 4.0

	# Heavy Frame
	var frame = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.14, 0.16, 0.5)
	frame.mesh = box
	frame.material_override = body_mat
	frame.position = Vector3(0, 0, 0)
	add_child(frame)

	# Plasma Energy Core Cylinder
	var core = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = 0.28
	core.mesh = cyl
	core.material_override = cyan_mat
	core.rotation_degrees = Vector3(90, 0, 0)
	core.position = Vector3(0, 0.02, -0.2)
	add_child(core)

	# Front Heavy Ring
	var ring = MeshInstance3D.new()
	var ring_mesh = CylinderMesh.new()
	ring_mesh.top_radius = 0.07
	ring_mesh.bottom_radius = 0.07
	ring_mesh.height = 0.08
	ring.mesh = ring_mesh
	ring.material_override = body_mat
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, 0.02, -0.45)
	add_child(ring)

	var muzzle_node = Node3D.new()
	muzzle_node.name = "MuzzleMarker"
	muzzle_node.position = Vector3(0, 0.02, -0.6)
	add_child(muzzle_node)

func _build_railgun() -> void:
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.08, 0.18)
	body_mat.metallic = 0.95
	body_mat.roughness = 0.2

	var mag_mat = StandardMaterial3D.new()
	mag_mat.albedo_color = Color(0.9, 0.1, 1.0)
	mag_mat.emission_enabled = true
	mag_mat.emission = Color(0.9, 0.1, 1.0)
	mag_mat.emission_energy_multiplier = 4.5

	# Sleek Main Stock
	var stock = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.09, 0.13, 0.6)
	stock.mesh = box
	stock.material_override = body_mat
	stock.position = Vector3(0, 0, 0.05)
	add_child(stock)

	# Twin Magnetic Rails
	for offset_x in [-0.035, 0.035]:
		var rail = MeshInstance3D.new()
		var rail_box = BoxMesh.new()
		rail_box.size = Vector3(0.015, 0.03, 0.55)
		rail.mesh = rail_box
		rail.material_override = body_mat
		rail.position = Vector3(offset_x, 0.02, -0.45)
		add_child(rail)

	# Glowing Railgun Accelerator Channel
	var channel = MeshInstance3D.new()
	var ch_box = BoxMesh.new()
	ch_box.size = Vector3(0.04, 0.015, 0.5)
	channel.mesh = ch_box
	channel.material_override = mag_mat
	channel.position = Vector3(0, 0.02, -0.42)
	add_child(channel)

	# Holographic Scope
	var scope = MeshInstance3D.new()
	var scope_box = BoxMesh.new()
	scope_box.size = Vector3(0.05, 0.05, 0.12)
	scope.mesh = scope_box
	scope.material_override = mag_mat
	scope.position = Vector3(0, 0.09, -0.1)
	add_child(scope)

	var muzzle_node = Node3D.new()
	muzzle_node.name = "MuzzleMarker"
	muzzle_node.position = Vector3(0, 0.02, -0.75)
	add_child(muzzle_node)
