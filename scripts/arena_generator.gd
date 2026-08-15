extends Node3D

var door_script = preload("res://scripts/interactive_door.gd")
var vehicle_script = preload("res://scripts/vehicle.gd")
var civilian_script = preload("res://scripts/civilian_npc.gd")

func _ready() -> void:
	_generate_interactive_city_world()

func _generate_interactive_city_world() -> void:
	var arena_node = get_node_or_null("Arena")
	if arena_node == null:
		arena_node = Node3D.new()
		arena_node.name = "Arena"
		add_child(arena_node)

	# 1. Materials Design System
	var asphalt_mat = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.12, 0.13, 0.15)
	asphalt_mat.roughness = 0.85

	var sidewalk_mat = StandardMaterial3D.new()
	sidewalk_mat.albedo_color = Color(0.55, 0.58, 0.62)

	var road_yellow = StandardMaterial3D.new()
	road_yellow.albedo_color = Color(0.95, 0.82, 0.15)

	var house_wall_mat = StandardMaterial3D.new()
	house_wall_mat.albedo_color = Color(0.8, 0.76, 0.72)

	var house_floor_mat = StandardMaterial3D.new()
	house_floor_mat.albedo_color = Color(0.4, 0.25, 0.15) # Wood floor

	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.45, 0.15, 0.12)

	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.35, 0.2, 0.1)

	var building_mat = StandardMaterial3D.new()
	building_mat.albedo_color = Color(0.22, 0.25, 0.3)
	building_mat.metallic = 0.6

	var window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color(0.2, 0.75, 0.95)
	window_mat.emission_enabled = true
	window_mat.emission = Color(0.15, 0.65, 0.85)

	var car_red_mat = StandardMaterial3D.new()
	car_red_mat.albedo_color = Color(0.9, 0.1, 0.1)
	car_red_mat.metallic = 0.9
	car_red_mat.roughness = 0.2

	var car_blue_mat = StandardMaterial3D.new()
	car_blue_mat.albedo_color = Color(0.1, 0.4, 0.95)
	car_blue_mat.metallic = 0.9

	var bike_mat = StandardMaterial3D.new()
	bike_mat.albedo_color = Color(0.1, 0.85, 0.3)
	bike_mat.metallic = 0.85

	var mountain_mat = StandardMaterial3D.new()
	mountain_mat.albedo_color = Color(0.2, 0.23, 0.26)

	var snow_mat = StandardMaterial3D.new()
	snow_mat.albedo_color = Color(0.9, 0.92, 0.96)

	# 2. Main Floor
	var floor_node = arena_node.get_node_or_null("Floor") as CSGBox3D
	if floor_node:
		floor_node.size = Vector3(140, 1, 140)
		floor_node.material = asphalt_mat

	# Remove legacy boundary walls
	for wall_name in ["WallNorth", "WallSouth", "WallEast", "WallWest"]:
		var w = arena_node.get_node_or_null(wall_name)
		if w: w.queue_free()

	var city_root = Node3D.new()
	city_root.name = "InteractiveCity"
	arena_node.add_child(city_root)

	# 3. Roads & Sidewalks
	var road_ns = CSGBox3D.new()
	road_ns.position = Vector3(0, 0.02, 0)
	road_ns.size = Vector3(16.0, 0.05, 140.0)
	road_ns.material = asphalt_mat
	city_root.add_child(road_ns)

	var line_ns = CSGBox3D.new()
	line_ns.position = Vector3(0, 0.05, 0)
	line_ns.size = Vector3(0.4, 0.06, 140.0)
	line_ns.material = road_yellow
	city_root.add_child(line_ns)

	var road_ew = CSGBox3D.new()
	road_ew.position = Vector3(0, 0.02, 0)
	road_ew.size = Vector3(140.0, 0.05, 16.0)
	road_ew.material = asphalt_mat
	city_root.add_child(road_ew)

	for side_x in [-10.0, 10.0]:
		var sw = CSGBox3D.new()
		sw.use_collision = true
		sw.position = Vector3(side_x, 0.1, 0)
		sw.size = Vector3(4.0, 0.2, 140.0)
		sw.material = sidewalk_mat
		city_root.add_child(sw)

	# 4. Interactive Houses with Furnished Interiors & Openable Doors
	var house_configs = [
		Vector3(-24, 0, -12), Vector3(-36, 0, -12),
		Vector3(24, 0, -12), Vector3(36, 0, -12),
		Vector3(-24, 0, 12), Vector3(24, 0, 12)
	]

	for h_pos in house_configs:
		var house = Node3D.new()
		house.position = h_pos
		city_root.add_child(house)

		# Wood Interior Floor
		var h_floor = CSGBox3D.new()
		h_floor.use_collision = true
		h_floor.position = Vector3(0, 0.1, 0)
		h_floor.size = Vector3(7.8, 0.2, 7.8)
		h_floor.material = house_floor_mat
		house.add_child(h_floor)

		# Outer Walls with Front Doorway Opening
		# Back Wall
		var w_back = CSGBox3D.new()
		w_back.use_collision = true
		w_back.position = Vector3(0, 2.5, -3.9)
		w_back.size = Vector3(8.0, 5.0, 0.2)
		w_back.material = house_wall_mat
		house.add_child(w_back)

		# Left & Right Walls
		var w_left = CSGBox3D.new()
		w_left.use_collision = true
		w_left.position = Vector3(-3.9, 2.5, 0)
		w_left.size = Vector3(0.2, 5.0, 8.0)
		w_left.material = house_wall_mat
		house.add_child(w_left)

		var w_right = CSGBox3D.new()
		w_right.use_collision = true
		w_right.position = Vector3(3.9, 2.5, 0)
		w_right.size = Vector3(0.2, 5.0, 8.0)
		w_right.material = house_wall_mat
		house.add_child(w_right)

		# Front Wall Parts (leaving door doorway)
		var w_front_l = CSGBox3D.new()
		w_front_l.use_collision = true
		w_front_l.position = Vector3(-2.5, 2.5, 3.9)
		w_front_l.size = Vector3(3.0, 5.0, 0.2)
		w_front_l.material = house_wall_mat
		house.add_child(w_front_l)

		var w_front_r = CSGBox3D.new()
		w_front_r.use_collision = true
		w_front_r.position = Vector3(2.5, 2.5, 3.9)
		w_front_r.size = Vector3(3.0, 5.0, 0.2)
		w_front_r.material = house_wall_mat
		house.add_child(w_front_r)

		# Openable Front Door Pivot
		var door_pivot = Node3D.new()
		door_pivot.position = Vector3(-1.0, 0.2, 3.9)
		door_pivot.script = door_script
		house.add_child(door_pivot)

		var door_mesh = CSGBox3D.new()
		door_mesh.use_collision = true
		door_mesh.position = Vector3(1.0, 1.4, 0)
		door_mesh.size = Vector3(2.0, 2.8, 0.12)
		door_mesh.material = door_mat
		door_pivot.add_child(door_mesh)

		# Interior Ceiling Light & Furniture
		var light = OmniLight3D.new()
		light.position = Vector3(0, 4.2, 0)
		light.light_color = Color(1.0, 0.9, 0.75)
		light.light_energy = 2.5
		light.omni_range = 8.0
		house.add_child(light)

		# Table & Chairs Furniture inside
		var table = CSGBox3D.new()
		table.use_collision = true
		table.position = Vector3(0, 0.75, 0)
		table.size = Vector3(1.8, 1.2, 1.2)
		table.material = door_mat
		house.add_child(table)

	# 5. Multi-Story Buildings with Internal & External Walkable Stairs
	var bldg_positions = [
		Vector3(-28, 0, -28), Vector3(28, 0, -28),
		Vector3(-28, 0, 28), Vector3(28, 0, 28)
	]

	for b_pos in bldg_positions:
		var bldg = Node3D.new()
		bldg.position = b_pos
		city_root.add_child(bldg)

		# 3-Story Building Shell (Hollow with floors)
		for floor_idx in range(3):
			var fy = floor_idx * 4.5
			var flr = CSGBox3D.new()
			flr.use_collision = true
			flr.position = Vector3(0, fy + 0.1, 0)
			flr.size = Vector3(12.0, 0.2, 12.0)
			flr.material = building_mat
			bldg.add_child(flr)

			# Floor Walls with Window cutouts
			for wall_angle in [0, 90, 180, 270]:
				var w = CSGBox3D.new()
				w.use_collision = true
				w.rotation_degrees = Vector3(0, wall_angle, 0)
				w.position = Vector3(0, fy + 2.25, -6.0)
				w.size = Vector3(12.0, 4.3, 0.3)
				w.material = building_mat
				bldg.add_child(w)

			# Walkable Stairs to next level
			for step_i in range(10):
				var step = CSGBox3D.new()
				step.use_collision = true
				step.position = Vector3(-4.0 + step_i * 0.4, fy + step_i * 0.45, -3.5)
				step.size = Vector3(0.6, 0.45, 2.2)
				step.material = sidewalk_mat
				bldg.add_child(step)

		# Roof Helipad & Lookout Railing
		var roof_rail = CSGBox3D.new()
		roof_rail.use_collision = true
		roof_rail.position = Vector3(0, 14.1, 0)
		roof_rail.size = Vector3(12.4, 0.8, 12.4)
		roof_rail.material = window_mat
		bldg.add_child(roof_rail)

	# 6. Drivable Sports Cars & Motorcycles
	var car_spawn_configs = [
		{"pos": Vector3(-6.0, 0.4, -18.0), "type": 0, "mat": car_red_mat},
		{"pos": Vector3(6.0, 0.4, 18.0), "type": 0, "mat": car_blue_mat},
		{"pos": Vector3(-6.0, 0.3, 24.0), "type": 1, "mat": bike_mat}
	]

	for v_cfg in car_spawn_configs:
		var v_body = CharacterBody3D.new()
		v_body.position = v_cfg["pos"]
		v_body.script = vehicle_script
		v_body.set("vehicle_type", v_cfg["type"])
		city_root.add_child(v_body)

		# Collision Shape
		var col = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2.2, 1.4, 4.2) if v_cfg["type"] == 0 else Vector3(1.0, 1.2, 2.2)
		col.shape = box_shape
		col.position = Vector3(0, 0.7, 0)
		v_body.add_child(col)

		# Vehicle Chassis Mesh
		var chassis = CSGBox3D.new()
		chassis.size = Vector3(2.2, 1.1, 4.2) if v_cfg["type"] == 0 else Vector3(0.8, 0.9, 2.2)
		chassis.material = v_cfg["mat"]
		chassis.position = Vector3(0, 0.65, 0)
		v_body.add_child(chassis)

		# Cabin Glass
		var cabin = CSGBox3D.new()
		cabin.size = Vector3(1.8, 0.7, 2.0) if v_cfg["type"] == 0 else Vector3(0.6, 0.5, 0.8)
		cabin.material = window_mat
		cabin.position = Vector3(0, 1.35, -0.2)
		v_body.add_child(cabin)

		# 4 Wheels
		for wx in [-1.0, 1.0]:
			for wz in [-1.3, 1.3]:
				var wheel = CSGCylinder3D.new()
				wheel.radius = 0.38
				wheel.height = 0.25
				wheel.rotation_degrees = Vector3(0, 0, 90)
				wheel.position = Vector3(wx, 0.38, wz)
				wheel.material = asphalt_mat
				v_body.add_child(wheel)

		# Headlights
		for hx in [-0.7, 0.7]:
			var headlight = OmniLight3D.new()
			headlight.position = Vector3(hx, 0.7, -2.2)
			headlight.light_color = Color(1.0, 0.95, 0.8)
			headlight.light_energy = 4.0
			headlight.omni_range = 18.0
			v_body.add_child(headlight)

		# Camera Attachment node for Vehicle driving mode
		var v_cam = Camera3D.new()
		v_cam.name = "VehicleCamera"
		v_cam.position = Vector3(0, 3.2, 6.5)
		v_cam.rotation_degrees = Vector3(-18, 0, 0)
		v_body.add_child(v_cam)

		# Interaction 3D Prompt Label
		var lbl = Label3D.new()
		lbl.name = "PromptLabel"
		lbl.position = Vector3(0, 2.2, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.font_size = 28
		lbl.outline_size = 8
		v_body.add_child(lbl)

	# 7. Moving Civilian NPCs Doing Activities
	for i in range(12):
		var npc = CharacterBody3D.new()
		npc.script = civilian_script
		npc.position = Vector3(randf_range(-38, 38), 0.9, randf_range(-38, 38))
		city_root.add_child(npc)

		# Collision Shape
		var col = CollisionShape3D.new()
		var cap = CapsuleShape3D.new()
		cap.radius = 0.4
		cap.height = 1.8
		col.shape = cap
		col.position = Vector3(0, 0.9, 0)
		npc.add_child(col)

	# 8. Mountains Backdrop
	var mtn_root = Node3D.new()
	mtn_root.name = "MountainRanges"
	arena_node.add_child(mtn_root)

	var mtn_specs = [
		Vector3(0, 0, -80), Vector3(-55, 0, -75), Vector3(55, 0, -75),
		Vector3(0, 0, 80), Vector3(-55, 0, 75), Vector3(55, 0, 75),
		Vector3(-80, 0, 0), Vector3(80, 0, 0)
	]

	for m_pos in mtn_specs:
		var mtx = CSGPolygon3D.new()
		mtx.use_collision = true
		mtx.position = m_pos + Vector3(-20, 0, -15)
		mtx.polygon = PackedVector2Array([Vector2(0, 0), Vector2(20, 48), Vector2(40, 0)])
		mtx.depth = 30.0
		mtx.material = mountain_mat
		mtn_root.add_child(mtx)

		var snow = CSGPolygon3D.new()
		snow.position = m_pos + Vector3(-8, 34, -10)
		snow.polygon = PackedVector2Array([Vector2(0, 0), Vector2(8, 14), Vector2(16, 0)])
		snow.depth = 20.0
		snow.material = snow_mat
		mtn_root.add_child(snow)
