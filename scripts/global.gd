extends Node

# Signals
signal health_changed(current: float, max_hp: float)
signal shield_changed(current: float, max_shield: float)
signal ammo_changed(in_clip: int, reserve: int)
signal score_changed(new_score: int)
signal wave_changed(wave_number: int)
signal player_damaged(damage_amount: float)
signal enemy_killed(score_value: int)
signal game_over_signal()
signal weapon_switched(weapon_name: String)

# State variables
var max_health: float = 100.0
var player_health: float = 100.0
var max_shield: float = 50.0
var player_shield: float = 50.0

var score: int = 0
var high_score: int = 0
var kills: int = 0
var current_wave: int = 1

var is_game_over: bool = false
var is_paused: bool = false
var mouse_sensitivity: float = 0.003

func _ready() -> void:
	reset_game()

func reset_game() -> void:
	player_health = max_health
	player_shield = max_shield
	score = 0
	kills = 0
	current_wave = 1
	is_game_over = false
	is_paused = false
	Engine.time_scale = 1.0

func add_score(amount: int) -> void:
	score += amount
	if score > high_score:
		high_score = score
	score_changed.emit(score)

func add_kill(score_val: int = 100) -> void:
	kills += 1
	add_score(score_val)

func damage_player(amount: float) -> void:
	if is_game_over:
		return
	
	var remaining_damage = amount
	if player_shield > 0:
		if player_shield >= remaining_damage:
			player_shield -= remaining_damage
			remaining_damage = 0
		else:
			remaining_damage -= player_shield
			player_shield = 0
		shield_changed.emit(player_shield, max_shield)
	
	if remaining_damage > 0:
		player_health -= remaining_damage
		if player_health <= 0:
			player_health = 0
			trigger_game_over()
		health_changed.emit(player_health, max_health)
	
	player_damaged.emit(amount)

func heal_player(amount: float) -> void:
	player_health = min(player_health + amount, max_health)
	health_changed.emit(player_health, max_health)

func add_ammo_bonus() -> void:
	# Signal receiver for ammo pickup
	pass

func trigger_game_over() -> void:
	is_game_over = true
	game_over_signal.emit()
