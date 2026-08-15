extends Node3D

@export var spawn_points: Array[Node3D] = []
var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

var enemies_remaining_to_spawn: int = 0
var enforcers_remaining_to_spawn: int = 0
var spawn_timer: float = 0.0
var wave_intermission_timer: float = 0.0
var in_intermission: bool = false

func _ready() -> void:
	# Find spawn markers if not set manually
	if spawn_points.is_empty():
		for child in get_children():
			if child is Node3D:
				spawn_points.append(child)
				
	_start_wave(1)

func _process(delta: float) -> void:
	if Global.is_game_over or Global.is_paused:
		return

	if in_intermission:
		wave_intermission_timer -= delta
		if wave_intermission_timer <= 0:
			in_intermission = false
			Global.current_wave += 1
			Global.wave_changed.emit(Global.current_wave)
			_start_wave(Global.current_wave)
		return

	# Check if all wave enemies are dead
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	if active_enemies.is_empty() and enemies_remaining_to_spawn <= 0 and enforcers_remaining_to_spawn <= 0:
		in_intermission = true
		wave_intermission_timer = 3.5
		return

	# Handle enemy spawning queue
	if (enemies_remaining_to_spawn > 0 or enforcers_remaining_to_spawn > 0):
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer = randf_range(0.8, 1.4)
			_spawn_next_enemy()

func _start_wave(wave_num: int) -> void:
	enemies_remaining_to_spawn = 4 + wave_num * 3
	enforcers_remaining_to_spawn = max(0, wave_num - 1)
	spawn_timer = 1.0

func _spawn_next_enemy() -> void:
	if enemy_scene == null:
		return
		
	var spawn_pos = global_position
	var civilians = get_tree().get_nodes_in_group("civilians")

	# Prefer spawning near a civilian so enemies actively attack them
	if civilians.size() > 0 and randf() < 0.7:
		var target_civ = civilians.pick_random() as Node3D
		if target_civ and is_instance_valid(target_civ):
			spawn_pos = target_civ.global_position + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	else:
		if not spawn_points.is_empty():
			var sp_node = spawn_points.pick_random()
			if sp_node and sp_node.is_inside_tree():
				spawn_pos = sp_node.global_position

	var is_enforcer = false
	if enforcers_remaining_to_spawn > 0 and (enemies_remaining_to_spawn == 0 or randf() < 0.35):
		is_enforcer = true
		enforcers_remaining_to_spawn -= 1
	elif enemies_remaining_to_spawn > 0:
		enemies_remaining_to_spawn -= 1
	else:
		return

	var enemy = enemy_scene.instantiate()
	if is_enforcer:
		enemy.set("enemy_type", 1) # ENFORCER
	else:
		enemy.set("enemy_type", 0) # CHASER
		
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
