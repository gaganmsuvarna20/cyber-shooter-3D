extends CharacterBody3D

enum NpcState { WALKING, WORKING, TALKING, FLEEING }

@export var npc_name: String = "Civilian"
@export var walk_speed: float = 2.2
@export var job_type: String = "Pedestrian"

var current_state: NpcState = NpcState.WALKING
var state_timer: float = 0.0
var target_waypoint: Vector3 = Vector3.ZERO
var walk_anim_time: float = 0.0
var health: float = 40.0
var hit_material: StandardMaterial3D

# Humanoid Body Nodes
var body_model: Node3D
var head_node: Node3D
var left_arm_node: Node3D
var right_arm_node: Node3D
var left_leg_node: Node3D
var right_leg_node: Node3D
var npc_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("civilians")
	
	hit_material = StandardMaterial3D.new()
	hit_material.albedo_color = Color(1.0, 0.2, 0.2)
	hit_material.emission_enabled = true
	hit_material.emission = Color(1.0, 0.2, 0.2)
	
	_build_civilian_mesh()
	_pick_new_waypoint()

func _build_civilian_mesh() -> void:
	body_model = Node3D.new()
	body_model.name = "CivilianBody"
	add_child(body_model)

	# Randomize clothing colors
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var shirt_colors = [Color(0.2, 0.5, 0.8), Color(0.8, 0.3, 0.2), Color(0.2, 0.7, 0.4), Color(0.9, 0.7, 0.2), Color(0.5, 0.3, 0.7)]
	var pants_colors = [Color(0.15, 0.18, 0.25), Color(0.25, 0.22, 0.2), Color(0.1, 0.1, 0.12)]
	var skin_colors = [Color(0.9, 0.75, 0.65), Color(0.75, 0.55, 0.4), Color(0.5, 0.35, 0.25)]

	var shirt_mat = StandardMaterial3D.new()
	shirt_mat.albedo_color = shirt_colors.pick_random()

	var pants_mat = StandardMaterial3D.new()
	pants_mat.albedo_color = pants_colors.pick_random()

	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = skin_colors.pick_random()

	var hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.15, 0.1, 0.08)

	# 1. Torso / Shirt
	var torso = MeshInstance3D.new()
	var torso_box = BoxMesh.new()
	torso_box.size = Vector3(0.42, 0.52, 0.26)
	torso.mesh = torso_box
	torso.material_override = shirt_mat
	torso.position = Vector3(0, 1.05, 0)
	body_model.add_child(torso)
	npc_meshes.append(torso)

	# 2. Neck & Head
	var neck = MeshInstance3D.new()
	var neck_cyl = CylinderMesh.new()
	neck_cyl.top_radius = 0.06
	neck_cyl.bottom_radius = 0.06
	neck_cyl.height = 0.1
	neck.mesh = neck_cyl
	neck.material_override = skin_mat
	neck.position = Vector3(0, 1.36, 0)
	body_model.add_child(neck)
	npc_meshes.append(neck)

	head_node = Node3D.new()
	head_node.position = Vector3(0, 1.48, 0)
	body_model.add_child(head_node)

	var head_mesh = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 0.14
	h_sph.height = 0.28
	head_mesh.mesh = h_sph
	head_mesh.material_override = skin_mat
	head_node.add_child(head_mesh)
	npc_meshes.append(head_mesh)

	# Hair
	var hair = MeshInstance3D.new()
	var hair_box = BoxMesh.new()
	hair_box.size = Vector3(0.3, 0.1, 0.3)
	hair.mesh = hair_box
	hair.material_override = hair_mat
	hair.position = Vector3(0, 0.12, 0)
	head_node.add_child(hair)
	npc_meshes.append(hair)

	# 3. Arms
	left_arm_node = Node3D.new()
	left_arm_node.position = Vector3(-0.27, 1.28, 0)
	body_model.add_child(left_arm_node)

	var l_arm = MeshInstance3D.new()
	var arm_cyl = CylinderMesh.new()
	arm_cyl.top_radius = 0.05
	arm_cyl.bottom_radius = 0.045
	arm_cyl.height = 0.45
	l_arm.mesh = arm_cyl
	l_arm.material_override = shirt_mat
	l_arm.position = Vector3(0, -0.22, 0)
	left_arm_node.add_child(l_arm)
	npc_meshes.append(l_arm)

	right_arm_node = Node3D.new()
	right_arm_node.position = Vector3(0.27, 1.28, 0)
	body_model.add_child(right_arm_node)

	var r_arm = MeshInstance3D.new()
	r_arm.mesh = arm_cyl
	r_arm.material_override = shirt_mat
	r_arm.position = Vector3(0, -0.22, 0)
	right_arm_node.add_child(r_arm)
	npc_meshes.append(r_arm)

	# 4. Legs
	left_leg_node = Node3D.new()
	left_leg_node.position = Vector3(-0.13, 0.76, 0)
	body_model.add_child(left_leg_node)

	var l_leg = MeshInstance3D.new()
	var leg_cyl = CylinderMesh.new()
	leg_cyl.top_radius = 0.075
	leg_cyl.bottom_radius = 0.06
	leg_cyl.height = 0.62
	l_leg.mesh = leg_cyl
	l_leg.material_override = pants_mat
	l_leg.position = Vector3(0, -0.32, 0)
	left_leg_node.add_child(l_leg)
	npc_meshes.append(l_leg)

	right_leg_node = Node3D.new()
	right_leg_node.position = Vector3(0.13, 0.76, 0)
	body_model.add_child(right_leg_node)

	var r_leg = MeshInstance3D.new()
	r_leg.mesh = leg_cyl
	r_leg.material_override = pants_mat
	r_leg.position = Vector3(0, -0.32, 0)
	right_leg_node.add_child(r_leg)
	npc_meshes.append(r_leg)

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO, _hit_normal: Vector3 = Vector3.ZERO) -> void:
	if health <= 0:
		return
	health -= amount
	current_state = NpcState.FLEEING
	_pick_flee_waypoint()
	_trigger_hit_flash()

	if health <= 0:
		queue_free()

func _trigger_hit_flash() -> void:
	for m in npc_meshes:
		if is_instance_valid(m):
			m.material_override = hit_material
	get_tree().create_timer(0.12).timeout.connect(func():
		for m in npc_meshes:
			if is_instance_valid(m):
				m.material_override = null
	)

func _physics_process(delta: float) -> void:
	if Global.is_game_over or Global.is_paused:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= 16.0 * delta

	state_timer -= delta

	match current_state:
		NpcState.WALKING:
			_process_walking(delta)
		NpcState.WORKING:
			_process_working(delta)
		NpcState.TALKING:
			_process_talking(delta)
		NpcState.FLEEING:
			_process_fleeing(delta)

	move_and_slide()

func _process_walking(delta: float) -> void:
	var dir = (target_waypoint - global_position)
	dir.y = 0
	var dist = dir.length()

	if dist > 0.8:
		dir = dir.normalized()
		velocity.x = dir.x * walk_speed
		velocity.z = dir.z * walk_speed

		look_at(Vector3(target_waypoint.x, global_position.y, target_waypoint.z), Vector3.UP)

		# Walking Limb Animation
		walk_anim_time += delta * walk_speed * 3.0
		left_arm_node.rotation.x = sin(walk_anim_time) * 0.4
		right_arm_node.rotation.x = -sin(walk_anim_time) * 0.4
		left_leg_node.rotation.x = -sin(walk_anim_time) * 0.5
		right_leg_node.rotation.x = sin(walk_anim_time) * 0.5
		body_model.position.y = sin(walk_anim_time * 2.0) * 0.02
	else:
		velocity.x = 0
		velocity.z = 0
		if state_timer <= 0:
			if randf() < 0.5:
				current_state = NpcState.WORKING
				state_timer = randf_range(4.0, 9.0)
			else:
				_pick_new_waypoint()

func _process_working(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0

	# Working / Activity animation (sweeping/inspecting)
	walk_anim_time += delta * 4.0
	right_arm_node.rotation.x = -0.6 + sin(walk_anim_time) * 0.25
	left_arm_node.rotation.x = -0.3 + cos(walk_anim_time) * 0.2
	left_leg_node.rotation.x = 0
	right_leg_node.rotation.x = 0
	head_node.rotation.y = sin(walk_anim_time * 0.5) * 0.3

	if state_timer <= 0:
		current_state = NpcState.WALKING
		_pick_new_waypoint()

func _process_talking(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	walk_anim_time += delta * 2.0
	head_node.rotation.y = sin(walk_anim_time) * 0.2
	right_arm_node.rotation.x = sin(walk_anim_time * 2.0) * 0.15

	if state_timer <= 0:
		current_state = NpcState.WALKING
		_pick_new_waypoint()

func _pick_new_waypoint() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rx = rng.randf_range(-38.0, 38.0)
	var rz = rng.randf_range(-38.0, 38.0)
	target_waypoint = Vector3(rx, 0, rz)
	state_timer = 15.0

func _pick_flee_waypoint() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rx = clamp(global_position.x + rng.randf_range(-15.0, 15.0), -45.0, 45.0)
	var rz = clamp(global_position.z + rng.randf_range(-15.0, 15.0), -45.0, 45.0)
	target_waypoint = Vector3(rx, 0, rz)
	state_timer = 8.0

func _process_fleeing(delta: float) -> void:
	var dir = (target_waypoint - global_position)
	dir.y = 0
	var dist = dir.length()

	if dist > 0.8:
		dir = dir.normalized()
		velocity.x = dir.x * (walk_speed * 2.2)
		velocity.z = dir.z * (walk_speed * 2.2)

		look_at(Vector3(target_waypoint.x, global_position.y, target_waypoint.z), Vector3.UP)

		# Panic Sprint Animation
		walk_anim_time += delta * walk_speed * 5.0
		left_arm_node.rotation.x = sin(walk_anim_time) * 0.7
		right_arm_node.rotation.x = -sin(walk_anim_time) * 0.7
		left_leg_node.rotation.x = -sin(walk_anim_time) * 0.8
		right_leg_node.rotation.x = sin(walk_anim_time) * 0.8
	else:
		velocity.x = 0
		velocity.z = 0
		if state_timer <= 0:
			current_state = NpcState.WALKING
			_pick_new_waypoint()
