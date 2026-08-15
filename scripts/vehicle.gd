extends CharacterBody3D

enum VehicleType { CAR, MOTORCYCLE }

@export var vehicle_type: VehicleType = VehicleType.CAR
@export var max_speed: float = 28.0
@export var acceleration: float = 22.0
@export var turn_speed: float = 2.6
@export var brake_force: float = 30.0

var is_occupied: bool = false
var driver_player: CharacterBody3D = null
var current_speed: float = 0.0

# Door Opening Animation state
var driver_door_node: Node3D = null
var is_door_open: bool = false
var door_target_rot_y: float = 0.0

@onready var camera: Camera3D = $VehicleCamera
@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
	add_to_group("vehicles")
	if camera:
		camera.current = false
	if prompt_label:
		prompt_label.text = "[E] Open Door & Drive " + ("Sports Car" if vehicle_type == VehicleType.CAR else "Motorcycle")

	_build_realistic_car_mesh()

func _build_realistic_car_mesh() -> void:
	# Materials
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.85, 0.12, 0.12) if vehicle_type == VehicleType.CAR else Color(0.12, 0.8, 0.3)
	body_mat.metallic = 0.95
	body_mat.roughness = 0.15

	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.1, 0.6, 0.85)
	glass_mat.metallic = 0.8
	glass_mat.roughness = 0.1
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.4, 0.6)

	var tire_mat = StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.1, 0.1, 0.12)
	tire_mat.roughness = 0.9

	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.8, 0.85, 0.9)
	rim_mat.metallic = 0.95
	rim_mat.roughness = 0.1

	var light_mat = StandardMaterial3D.new()
	light_mat.albedo_color = Color(1.0, 0.95, 0.8)
	light_mat.emission_enabled = true
	light_mat.emission = Color(1.0, 0.95, 0.8)
	light_mat.emission_energy_multiplier = 3.0

	var tail_light_mat = StandardMaterial3D.new()
	tail_light_mat.albedo_color = Color(1.0, 0.1, 0.1)
	tail_light_mat.emission_enabled = true
	tail_light_mat.emission = Color(1.0, 0.1, 0.1)
	tail_light_mat.emission_energy_multiplier = 2.5

	# Car Main Body Frame
	var chassis = CSGBox3D.new()
	chassis.size = Vector3(2.1, 0.75, 4.4)
	chassis.material = body_mat
	chassis.position = Vector3(0, 0.6, 0)
	add_child(chassis)

	# Curved Hood
	var hood = CSGBox3D.new()
	hood.size = Vector3(2.0, 0.35, 1.4)
	hood.material = body_mat
	hood.position = Vector3(0, 0.85, -1.2)
	add_child(hood)

	# Cabin Glass Roof
	var cabin = CSGBox3D.new()
	cabin.size = Vector3(1.85, 0.75, 2.2)
	cabin.material = glass_mat
	cabin.position = Vector3(0, 1.3, -0.1)
	add_child(cabin)

	# Driver Side Openable Door Pivot
	driver_door_node = Node3D.new()
	driver_door_node.name = "DriverDoorPivot"
	driver_door_node.position = Vector3(-1.02, 0.6, -0.8)
	add_child(driver_door_node)

	var door_mesh = CSGBox3D.new()
	door_mesh.size = Vector3(0.12, 0.85, 1.4)
	door_mesh.material = body_mat
	door_mesh.position = Vector3(0, 0.3, 0.7)
	driver_door_node.add_child(door_mesh)

	var door_window = CSGBox3D.new()
	door_window.size = Vector3(0.1, 0.6, 1.3)
	door_window.material = glass_mat
	door_window.position = Vector3(0, 0.9, 0.7)
	driver_door_node.add_child(door_window)

	# 4 Wheels with Rims & Tires
	for wx in [-1.05, 1.05]:
		for wz in [-1.35, 1.35]:
			var tire = CSGCylinder3D.new()
			tire.radius = 0.4
			tire.height = 0.28
			tire.rotation_degrees = Vector3(0, 0, 90)
			tire.position = Vector3(wx, 0.4, wz)
			tire.material = tire_mat
			add_child(tire)

			var rim = CSGCylinder3D.new()
			rim.radius = 0.24
			rim.height = 0.29
			rim.rotation_degrees = Vector3(0, 0, 90)
			rim.position = Vector3(wx, 0.4, wz)
			rim.material = rim_mat
			add_child(rim)

	# Headlights & Tail lights
	for hx in [-0.75, 0.75]:
		var hl = CSGBox3D.new()
		hl.size = Vector3(0.35, 0.2, 0.1)
		hl.material = light_mat
		hl.position = Vector3(hx, 0.75, -2.21)
		add_child(hl)

		var tl = CSGBox3D.new()
		tl.size = Vector3(0.35, 0.2, 0.1)
		tl.material = tail_light_mat
		tl.position = Vector3(hx, 0.75, 2.21)
		add_child(tl)

func _process(delta: float) -> void:
	# Smoothly animate openable driver door
	if driver_door_node:
		driver_door_node.rotation_degrees.y = lerp(driver_door_node.rotation_degrees.y, door_target_rot_y, delta * 8.0)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= 16.0 * delta

	if is_occupied and driver_player:
		# Vehicle Steering & Acceleration Controls
		var steer_input = Input.get_axis("move_right", "move_left") # A/D steering
		var accel_input = Input.get_axis("move_backward", "move_forward") # W/S throttle

		if accel_input != 0:
			current_speed = move_toward(current_speed, accel_input * max_speed, acceleration * delta)
		else:
			current_speed = move_toward(current_speed, 0.0, brake_force * delta * 0.5)

		# Handbrake
		if Input.is_action_pressed("jump"):
			current_speed = move_toward(current_speed, 0.0, brake_force * delta * 2.0)

		# Steer rotation
		if abs(current_speed) > 0.5:
			var dir_mult = 1.0 if current_speed >= 0 else -1.0
			rotate_y(steer_input * turn_speed * delta * dir_mult)

		# Forward Velocity Vector
		var fwd_dir = -transform.basis.z
		velocity.x = fwd_dir.x * current_speed
		velocity.z = fwd_dir.z * current_speed

		move_and_slide()

		# Vehicle Collision Damage - Hit Enemies & Civilians
		_handle_vehicle_collisions()

		# Exit Vehicle
		if Input.is_action_just_pressed("interact"):
			exit_vehicle()
	else:
		# Slow down when unoccupied
		current_speed = move_toward(current_speed, 0.0, brake_force * delta)
		velocity.x = move_toward(velocity.x, 0, brake_force * delta)
		velocity.z = move_toward(velocity.z, 0, brake_force * delta)
		move_and_slide()

		# Check player proximity to show prompt and allow entry
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0] as CharacterBody3D
			if p and is_instance_valid(p):
				var dist = global_position.distance_to(p.global_position)
				if prompt_label:
					prompt_label.visible = (dist <= 3.8)

				if dist <= 3.8 and Input.is_action_just_pressed("interact"):
					enter_vehicle(p)

func _handle_vehicle_collisions() -> void:
	if abs(current_speed) < 3.0:
		return

	var num_collisions = get_slide_collision_count()
	for i in range(num_collisions):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and is_instance_valid(collider):
			# Calculate impact damage based on car velocity
			var impact_damage = abs(current_speed) * 6.5
			if collider.has_method("take_damage"):
				collider.call("take_damage", impact_damage, col.get_position(), col.get_normal())
				SoundManager.play_hitmarker()

			# Apply knockback force if CharacterBody3D (Enemy or Civilian)
			if collider is CharacterBody3D:
				var push_dir = (-transform.basis.z + Vector3(0, 0.3, 0)).normalized()
				collider.velocity += push_dir * abs(current_speed) * 1.5

func enter_vehicle(p: CharacterBody3D) -> void:
	# Open car door first!
	door_target_rot_y = -65.0
	is_occupied = true
	driver_player = p
	if prompt_label:
		prompt_label.visible = false

	# Hide player after brief door open
	get_tree().create_timer(0.2).timeout.connect(func():
		if is_instance_valid(p):
			p.visible = false
			p.set_physics_process(false)
			p.set_process_input(false)
			p.global_position = global_position
		door_target_rot_y = 0.0 # Shut door
	)

	# Switch to vehicle camera
	if camera:
		camera.make_current()

func exit_vehicle() -> void:
	# Open car door to step out
	door_target_rot_y = -65.0
	
	if driver_player and is_instance_valid(driver_player):
		driver_player.visible = true
		driver_player.set_physics_process(true)
		driver_player.set_process_input(true)
		
		# Spawn player next to driver door
		var exit_pos = global_position + (transform.basis.x * 2.4)
		exit_pos.y += 0.5
		driver_player.global_position = exit_pos

		# Switch back to player camera
		var p_cam = driver_player.get_node_or_null("Head/Camera3D") as Camera3D
		if p_cam:
			p_cam.make_current()

	is_occupied = false
	driver_player = null

	# Shut door after exit
	get_tree().create_timer(0.4).timeout.connect(func():
		door_target_rot_y = 0.0
	)
