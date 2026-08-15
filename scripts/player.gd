extends CharacterBody3D

@export var speed: float = 6.5
@export var sprint_speed: float = 10.5
@export var jump_velocity: float = 5.5
@export var gravity: float = 16.0
@export var mouse_sensitivity: float = 0.003

# Node references
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var rifle_mesh: Node3D = $Head/Camera3D/WeaponHolder/RifleMesh
@onready var shotgun_mesh: Node3D = $Head/Camera3D/WeaponHolder/ShotgunMesh
@onready var plasma_mesh: Node3D = $Head/Camera3D/WeaponHolder/PlasmaMesh
@onready var railgun_mesh: Node3D = $Head/Camera3D/WeaponHolder/RailgunMesh
@onready var muzzle_flash_light: OmniLight3D = $Head/Camera3D/WeaponHolder/MuzzleFlashLight

# Bullet Tracer PackedScene
var tracer_scene: PackedScene = preload("res://scenes/bullet_tracer.tscn")

# Weapon Data Structure
class Weapon:
	var name: String
	var is_auto: bool
	var damage: float
	var fire_rate: float
	var clip_size: int
	var in_clip: int
	var reserve_ammo: int
	var max_reserve: int
	var spread: float
	var recoil: float
	var pellets: int

	func _init(p_name: String, p_auto: bool, p_dmg: float, p_rate: float, p_clip: int, p_reserve: int, p_spread: float, p_recoil: float, p_pellets: int = 1):
		name = p_name
		is_auto = p_auto
		damage = p_dmg
		fire_rate = p_rate
		clip_size = p_clip
		in_clip = p_clip
		reserve_ammo = p_reserve
		max_reserve = p_reserve
		spread = p_spread
		recoil = p_recoil
		pellets = p_pellets

var weapons: Array[Weapon] = []
var current_weapon_idx: int = 0
var fire_timer: float = 0.0
var reload_timer: float = 0.0
var is_reloading: bool = false

# Recoil & Sway
var camera_recoil_pitch: float = 0.0
var initial_weapon_pos: Vector3 = Vector3(0.25, -0.22, -0.45)
var target_weapon_pos: Vector3 = Vector3(0.25, -0.22, -0.45)

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Setup 4 High-Power Weapons
	weapons.append(Weapon.new("Assault Rifle", true, 25.0, 0.1, 30, 180, 0.02, 0.03, 1))
	weapons.append(Weapon.new("Shotgun", false, 16.0, 0.65, 8, 48, 0.07, 0.1, 8))
	weapons.append(Weapon.new("Plasma Cannon", false, 140.0, 0.45, 10, 40, 0.01, 0.14, 1))
	weapons.append(Weapon.new("Hyper Railgun", false, 350.0, 1.0, 5, 20, 0.0, 0.25, 1))
	
	_update_weapon_visibility()
	_update_hud_ammo()

func _input(event: InputEvent) -> void:
	if Global.is_game_over or Global.is_paused:
		return

	# Re-capture mouse if window is clicked
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Handle Mouse Aim / Looking around
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens = Global.mouse_sensitivity if Global.mouse_sensitivity > 0 else mouse_sensitivity
		var rot_y = -event.relative.x * sens
		var rot_x = -event.relative.y * sens
		
		rotate_y(rot_y)
		head.rotation.x = clamp(head.rotation.x + rot_x, deg_to_rad(-85), deg_to_rad(85))

func _physics_process(delta: float) -> void:
	if Global.is_game_over:
		return
		
	# Handle Pause Toggle
	if Input.is_action_just_pressed("pause"):
		Global.is_paused = not Global.is_paused
		if Global.is_paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if Global.is_paused:
		return

	# Timers
	if fire_timer > 0:
		fire_timer -= delta
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			_finish_reload()

	# Gravity & Jump
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			SoundManager.play_jump()

	# Sprint & Movement
	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else speed
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0, current_speed * delta * 8.0)

	move_and_slide()

	# Weapon Switching
	if Input.is_action_just_pressed("switch_rifle") and current_weapon_idx != 0:
		_switch_weapon(0)
	elif Input.is_action_just_pressed("switch_shotgun") and current_weapon_idx != 1:
		_switch_weapon(1)
	elif Input.is_action_just_pressed("switch_plasma") and current_weapon_idx != 2:
		_switch_weapon(2)
	elif Input.is_action_just_pressed("switch_railgun") and current_weapon_idx != 3:
		_switch_weapon(3)
	elif Input.is_action_just_pressed("next_weapon"):
		_switch_weapon((current_weapon_idx + 1) % weapons.size())
	elif Input.is_action_just_pressed("prev_weapon"):
		_switch_weapon((current_weapon_idx - 1 + weapons.size()) % weapons.size())

	# Reloading
	if Input.is_action_just_pressed("reload") and not is_reloading:
		_start_reload()

	# Shooting
	var w = weapons[current_weapon_idx]
	var can_shoot = (Input.is_action_pressed("shoot") if w.is_auto else Input.is_action_just_pressed("shoot"))
	if can_shoot and fire_timer <= 0 and not is_reloading:
		if w.in_clip > 0:
			_shoot_weapon()
		else:
			_start_reload()

	# Camera & Weapon Recoil Recovery
	if camera_recoil_pitch > 0.0001:
		camera_recoil_pitch = lerp(camera_recoil_pitch, 0.0, delta * 12.0)
		head.rotation.x = clamp(head.rotation.x + camera_recoil_pitch * delta * 2.0, deg_to_rad(-85), deg_to_rad(85))
		if camera_recoil_pitch < 0.001:
			camera_recoil_pitch = 0.0

	weapon_holder.position = weapon_holder.position.lerp(target_weapon_pos, delta * 15.0)

func _shoot_weapon() -> void:
	var w = weapons[current_weapon_idx]
	w.in_clip -= 1
	fire_timer = w.fire_rate
	_update_hud_ammo()
	
	# Muzzle light flash
	muzzle_flash_light.visible = true
	get_tree().create_timer(0.04).timeout.connect(func(): muzzle_flash_light.visible = false)
	
	# Sound
	match current_weapon_idx:
		0: SoundManager.play_rifle_shot()
		1: SoundManager.play_shotgun_shot()
		2: SoundManager.play_plasma_shot()
		3: SoundManager.play_railgun_shot()
		
	# Recoil kickback
	camera_recoil_pitch = w.recoil
	weapon_holder.position += Vector3(0, 0.04, 0.08)

	# Get Muzzle world position
	var active_mesh: Node3D = rifle_mesh
	match current_weapon_idx:
		0: active_mesh = rifle_mesh
		1: active_mesh = shotgun_mesh
		2: active_mesh = plasma_mesh
		3: active_mesh = railgun_mesh
		
	var muzzle_node = active_mesh.get_node_or_null("MuzzleMarker") as Node3D
	var muzzle_pos = muzzle_node.global_position if muzzle_node else camera.global_position

	# Fire Pellets / Raycasts
	var hit_any_enemy = false
	for i in range(w.pellets):
		# Calculate raycast direction with spread
		var ray_origin = camera.global_position
		var spread_offset = Vector3(
			randf_range(-w.spread, w.spread),
			randf_range(-w.spread, w.spread),
			0
		)
		var ray_dir = (-camera.global_transform.basis.z + camera.global_transform.basis * spread_offset).normalized()
		var ray_end = ray_origin + ray_dir * 90.0
		
		# Physics Direct Space State Raycast
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.exclude = [self.get_rid()]
		var result = space_state.intersect_ray(query)
		
		var actual_end = ray_end
		if result:
			actual_end = result.position
			var collider = result.collider
			if collider and collider.has_method("take_damage"):
				collider.call("take_damage", w.damage, result.position, result.normal)
				hit_any_enemy = true
			
			# Plasma Explosive Splash Damage
			if current_weapon_idx == 2: # Plasma Cannon
				var enemies = get_tree().get_nodes_in_group("enemies")
				for enemy in enemies:
					if enemy and is_instance_valid(enemy) and enemy.has_method("take_damage"):
						var dist = enemy.global_position.distance_to(result.position)
						if dist <= 5.5:
							var splash_dmg = w.damage * (1.0 - (dist / 5.5) * 0.5)
							enemy.call("take_damage", splash_dmg, enemy.global_position, Vector3.UP)
							hit_any_enemy = true

		# Spawn Tracer
		if tracer_scene:
			var tracer = tracer_scene.instantiate()
			get_parent().add_child(tracer)
			tracer.call("setup", muzzle_pos, actual_end, current_weapon_idx == 1 or current_weapon_idx == 2)

	if hit_any_enemy:
		SoundManager.play_hitmarker()

func _start_reload() -> void:
	var w = weapons[current_weapon_idx]
	if w.in_clip < w.clip_size and w.reserve_ammo > 0:
		is_reloading = true
		reload_timer = 1.2
		SoundManager.play_reload()

func _finish_reload() -> void:
	var w = weapons[current_weapon_idx]
	var needed = w.clip_size - w.in_clip
	var to_load = min(needed, w.reserve_ammo)
	w.in_clip += to_load
	w.reserve_ammo -= to_load
	is_reloading = false
	_update_hud_ammo()

func _switch_weapon(new_idx: int) -> void:
	current_weapon_idx = new_idx
	is_reloading = false
	_update_weapon_visibility()
	_update_hud_ammo()
	Global.weapon_switched.emit(weapons[current_weapon_idx].name)

func _update_weapon_visibility() -> void:
	rifle_mesh.visible = (current_weapon_idx == 0)
	shotgun_mesh.visible = (current_weapon_idx == 1)
	plasma_mesh.visible = (current_weapon_idx == 2)
	railgun_mesh.visible = (current_weapon_idx == 3)

func _update_hud_ammo() -> void:
	var w = weapons[current_weapon_idx]
	Global.ammo_changed.emit(w.in_clip, w.reserve_ammo)

func add_reserve_ammo(rifle_amt: int, shotgun_amt: int) -> void:
	weapons[0].reserve_ammo = min(weapons[0].reserve_ammo + rifle_amt, weapons[0].max_reserve)
	weapons[1].reserve_ammo = min(weapons[1].reserve_ammo + shotgun_amt, weapons[1].max_reserve)
	weapons[2].reserve_ammo = min(weapons[2].reserve_ammo + 10, weapons[2].max_reserve)
	weapons[3].reserve_ammo = min(weapons[3].reserve_ammo + 5, weapons[3].max_reserve)
	_update_hud_ammo()
