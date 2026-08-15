extends CharacterBody3D

enum EnemyType { CHASER, ENFORCER }

@export var enemy_type: EnemyType = EnemyType.CHASER
@export var max_health: float = 60.0
@export var speed: float = 4.5
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 1.0
@export var score_reward: int = 100

var health: float = 60.0
var attack_timer: float = 0.0
var player_node: Node3D = null
var walk_anim_time: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var pickup_scene: PackedScene = preload("res://scenes/pickup.tscn")
var default_material: StandardMaterial3D
var armor_material: StandardMaterial3D
var visor_material: StandardMaterial3D
var hit_material: StandardMaterial3D

# Humanoid Body Nodes for Animation
var body_model: Node3D
var head_node: Node3D
var left_arm_node: Node3D
var right_arm_node: Node3D
var left_leg_node: Node3D
var right_leg_node: Node3D
var humanoid_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("enemies")
	
	if enemy_type == EnemyType.ENFORCER:
		max_health = 160.0
		speed = 2.6
		attack_damage = 22.0
		attack_cooldown = 1.8
		score_reward = 250
		scale = Vector3(1.35, 1.35, 1.35)
		
	health = max_health
	
	# Setup Materials
	default_material = StandardMaterial3D.new()
	default_material.metallic = 0.7
	default_material.roughness = 0.3
	
	armor_material = StandardMaterial3D.new()
	armor_material.metallic = 0.85
	armor_material.roughness = 0.25
	armor_material.albedo_color = Color(0.1, 0.12, 0.16)

	visor_material = StandardMaterial3D.new()
	visor_material.emission_enabled = true
	
	if enemy_type == EnemyType.CHASER:
		default_material.albedo_color = Color(0.85, 0.15, 0.15)
		visor_material.albedo_color = Color(1.0, 0.1, 0.1)
		visor_material.emission = Color(1.0, 0.1, 0.1)
		visor_material.emission_energy_multiplier = 3.5
	else:
		default_material.albedo_color = Color(0.55, 0.1, 0.9)
		visor_material.albedo_color = Color(0.7, 0.1, 1.0)
		visor_material.emission = Color(0.7, 0.1, 1.0)
		visor_material.emission_energy_multiplier = 4.0

	hit_material = StandardMaterial3D.new()
	hit_material.albedo_color = Color(1.0, 1.0, 1.0)
	hit_material.emission_enabled = true
	hit_material.emission = Color(1.0, 1.0, 1.0)
	hit_material.emission_energy_multiplier = 4.0

	# Hide default box mesh if present
	if mesh_instance:
		mesh_instance.visible = false
		
	_build_humanoid_mesh()

func _build_humanoid_mesh() -> void:
	body_model = Node3D.new()
	body_model.name = "HumanoidBody"
	add_child(body_model)

	# 1. Torso / Upper Body & Tactical Vest
	var torso = MeshInstance3D.new()
	var torso_box = BoxMesh.new()
	torso_box.size = Vector3(0.46, 0.55, 0.28)
	torso.mesh = torso_box
	torso.material_override = default_material
	torso.position = Vector3(0, 1.1, 0)
	body_model.add_child(torso)
	humanoid_meshes.append(torso)

	# Tactical Chest Armor Vest
	var chest_plate = MeshInstance3D.new()
	var cp_box = BoxMesh.new()
	cp_box.size = Vector3(0.48, 0.38, 0.32)
	chest_plate.mesh = cp_box
	chest_plate.material_override = armor_material
	chest_plate.position = Vector3(0, 1.18, 0.01)
	body_model.add_child(chest_plate)
	humanoid_meshes.append(chest_plate)

	# Waist Belt & Buckle
	var belt = MeshInstance3D.new()
	var belt_box = BoxMesh.new()
	belt_box.size = Vector3(0.44, 0.08, 0.3)
	belt.mesh = belt_box
	belt.material_override = armor_material
	belt.position = Vector3(0, 0.82, 0)
	body_model.add_child(belt)
	humanoid_meshes.append(belt)

	# 2. Neck & Head
	var neck = MeshInstance3D.new()
	var neck_cyl = CylinderMesh.new()
	neck_cyl.top_radius = 0.07
	neck_cyl.bottom_radius = 0.08
	neck_cyl.height = 0.12
	neck.mesh = neck_cyl
	neck.material_override = armor_material
	neck.position = Vector3(0, 1.42, 0)
	body_model.add_child(neck)
	humanoid_meshes.append(neck)

	head_node = Node3D.new()
	head_node.position = Vector3(0, 1.56, 0)
	body_model.add_child(head_node)

	var head_mesh = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 0.15
	h_sph.height = 0.3
	head_mesh.mesh = h_sph
	head_mesh.material_override = armor_material
	head_node.add_child(head_mesh)
	humanoid_meshes.append(head_mesh)

	# Tactical Helmet Visor / Glowing Eyes
	var visor_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.24, 0.06, 0.12)
	visor_mesh.mesh = v_box
	visor_mesh.material_override = visor_material
	visor_mesh.position = Vector3(0, 0.02, -0.11)
	head_node.add_child(visor_mesh)
	humanoid_meshes.append(visor_mesh)

	# 3. Left Arm (Shoulder, Upper Arm, Forearm, Hand)
	left_arm_node = Node3D.new()
	left_arm_node.position = Vector3(-0.3, 1.32, 0)
	body_model.add_child(left_arm_node)

	var l_pauldron = MeshInstance3D.new()
	var pauldron_box = BoxMesh.new()
	pauldron_box.size = Vector3(0.16, 0.16, 0.18)
	l_pauldron.mesh = pauldron_box
	l_pauldron.material_override = armor_material
	l_pauldron.position = Vector3(-0.02, 0.02, 0)
	left_arm_node.add_child(l_pauldron)
	humanoid_meshes.append(l_pauldron)

	var l_arm = MeshInstance3D.new()
	var arm_cyl = CylinderMesh.new()
	arm_cyl.top_radius = 0.06
	arm_cyl.bottom_radius = 0.055
	arm_cyl.height = 0.48
	l_arm.mesh = arm_cyl
	l_arm.material_override = default_material
	l_arm.position = Vector3(0, -0.25, 0)
	left_arm_node.add_child(l_arm)
	humanoid_meshes.append(l_arm)

	# 4. Right Arm
	right_arm_node = Node3D.new()
	right_arm_node.position = Vector3(0.3, 1.32, 0)
	body_model.add_child(right_arm_node)

	var r_pauldron = MeshInstance3D.new()
	r_pauldron.mesh = pauldron_box
	r_pauldron.material_override = armor_material
	r_pauldron.position = Vector3(0.02, 0.02, 0)
	right_arm_node.add_child(r_pauldron)
	humanoid_meshes.append(r_pauldron)

	var r_arm = MeshInstance3D.new()
	r_arm.mesh = arm_cyl
	r_arm.material_override = default_material
	r_arm.position = Vector3(0, -0.25, 0)
	right_arm_node.add_child(r_arm)
	humanoid_meshes.append(r_arm)

	# 5. Left Leg (Thigh, Knee Cap, Shin, Boot)
	left_leg_node = Node3D.new()
	left_leg_node.position = Vector3(-0.14, 0.78, 0)
	body_model.add_child(left_leg_node)

	var l_leg = MeshInstance3D.new()
	var leg_cyl = CylinderMesh.new()
	leg_cyl.top_radius = 0.08
	leg_cyl.bottom_radius = 0.065
	leg_cyl.height = 0.65
	l_leg.mesh = leg_cyl
	l_leg.material_override = armor_material
	l_leg.position = Vector3(0, -0.35, 0)
	left_leg_node.add_child(l_leg)
	humanoid_meshes.append(l_leg)

	# Combat Boot
	var l_boot = MeshInstance3D.new()
	var boot_box = BoxMesh.new()
	boot_box.size = Vector3(0.15, 0.14, 0.25)
	l_boot.mesh = boot_box
	l_boot.material_override = armor_material
	l_boot.position = Vector3(0, -0.68, -0.04)
	left_leg_node.add_child(l_boot)
	humanoid_meshes.append(l_boot)

	# 6. Right Leg
	right_leg_node = Node3D.new()
	right_leg_node.position = Vector3(0.14, 0.78, 0)
	body_model.add_child(right_leg_node)

	var r_leg = MeshInstance3D.new()
	r_leg.mesh = leg_cyl
	r_leg.material_override = armor_material
	r_leg.position = Vector3(0, -0.35, 0)
	right_leg_node.add_child(r_leg)
	humanoid_meshes.append(r_leg)

	var r_boot = MeshInstance3D.new()
	r_boot.mesh = boot_box
	r_boot.material_override = armor_material
	r_boot.position = Vector3(0, -0.68, -0.04)
	right_leg_node.add_child(r_boot)
	humanoid_meshes.append(r_boot)

var current_target: Node3D = null

func _physics_process(delta: float) -> void:
	if Global.is_game_over or Global.is_paused:
		return
		
	if attack_timer > 0:
		attack_timer -= delta

	if player_node == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0] as Node3D

	# 1. Target Selection Logic: Prioritize Civilians unless Player is close or attacked
	if current_target == null or not is_instance_valid(current_target):
		_find_target()

	# Check if player is super close (player intervention)
	if player_node and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) <= 6.5:
			current_target = player_node

	if current_target and is_instance_valid(current_target):
		var target_pos = current_target.global_position
		var dir = (target_pos - global_position)
		dir.y = 0 # keep horizontal
		var dist = dir.length()
		dir = dir.normalized()
		
		# Look towards target
		if dir.length() > 0.01:
			look_at(Vector3(target_pos.x, global_position.y, target_pos.z), Vector3.UP)
			
		# Gravity
		if not is_on_floor():
			velocity.y -= 16.0 * delta
			
		# Movement
		var is_moving = false
		if dist > 1.8:
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			is_moving = true
		else:
			velocity.x = move_toward(velocity.x, 0, speed * delta * 5.0)
			velocity.z = move_toward(velocity.z, 0, speed * delta * 5.0)

		move_and_slide()

		# Realistic Humanoid Movement Gait
		if is_moving:
			walk_anim_time += delta * speed * 2.8
			var arm_swing = sin(walk_anim_time) * 0.45
			var leg_swing = sin(walk_anim_time) * 0.55
			
			left_arm_node.rotation.x = arm_swing
			right_arm_node.rotation.x = -arm_swing
			left_leg_node.rotation.x = -leg_swing
			right_leg_node.rotation.x = leg_swing
			
			body_model.position.y = sin(walk_anim_time * 2.0) * 0.03 # Natural torso bobbing
		else:
			left_arm_node.rotation.x = lerp(left_arm_node.rotation.x, 0.0, delta * 8.0)
			right_arm_node.rotation.x = lerp(right_arm_node.rotation.x, 0.0, delta * 8.0)
			left_leg_node.rotation.x = lerp(left_leg_node.rotation.x, 0.0, delta * 8.0)
			right_leg_node.rotation.x = lerp(right_leg_node.rotation.x, 0.0, delta * 8.0)
			body_model.position.y = lerp(body_model.position.y, 0.0, delta * 8.0)
		
		# Attack Target Logic
		if dist <= 2.2 and attack_timer <= 0:
			_perform_attack()

func _find_target() -> void:
	# Search for closest civilian to attack
	var civilians = get_tree().get_nodes_in_group("civilians")
	var closest_civ: Node3D = null
	var closest_dist: float = 35.0

	for c in civilians:
		if c and is_instance_valid(c):
			var d = global_position.distance_to(c.global_position)
			if d < closest_dist:
				closest_dist = d
				closest_civ = c

	if closest_civ:
		current_target = closest_civ
	elif player_node and is_instance_valid(player_node):
		current_target = player_node

func _perform_attack() -> void:
	attack_timer = attack_cooldown
	if current_target and is_instance_valid(current_target):
		if current_target.is_in_group("player"):
			Global.damage_player(attack_damage)
			SoundManager.play_player_hurt()
		elif current_target.has_method("take_damage"):
			current_target.call("take_damage", attack_damage, global_position, Vector3.UP)

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO, _hit_normal: Vector3 = Vector3.ZERO) -> void:
	if health <= 0:
		return
		
	health -= amount
	_trigger_hit_flash()

	# If shot by player, target player!
	if player_node and is_instance_valid(player_node):
		current_target = player_node
	
	if health <= 0:
		die()

func _trigger_hit_flash() -> void:
	for m in humanoid_meshes:
		if is_instance_valid(m):
			m.material_override = hit_material
			
	get_tree().create_timer(0.08).timeout.connect(func():
		for m in humanoid_meshes:
			if is_instance_valid(m):
				m.material_override = null # revert to default
	)

func die() -> void:
	Global.add_kill(score_reward)
	SoundManager.play_enemy_explode()
	
	# Chance to spawn pickup
	if randf() < 0.45 and pickup_scene:
		var p = pickup_scene.instantiate()
		p.position = global_position + Vector3(0, 0.5, 0)
		p.call("set", "pickup_type", 0 if randf() < 0.6 else 1)
		get_parent().add_child(p)
		
	queue_free()
