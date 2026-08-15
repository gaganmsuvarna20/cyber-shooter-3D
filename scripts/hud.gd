extends CanvasLayer

# Node references
@onready var health_bar: ProgressBar = $Control/BottomLeft/HealthBar
@onready var shield_bar: ProgressBar = $Control/BottomLeft/ShieldBar
@onready var health_text: Label = $Control/BottomLeft/HealthText
@onready var shield_text: Label = $Control/BottomLeft/ShieldText

@onready var ammo_text: Label = $Control/BottomRight/AmmoText
@onready var weapon_text: Label = $Control/BottomRight/WeaponText

@onready var score_text: Label = $Control/TopLeft/ScoreText
@onready var wave_text: Label = $Control/TopLeft/WaveText

@onready var wave_banner: Label = $Control/CenterContainer/WaveBanner
@onready var damage_vignette: ColorRect = $Control/DamageVignette

@onready var pause_menu: Control = $Control/PauseMenu
@onready var game_over_menu: Control = $Control/GameOverMenu
@onready var final_score_label: Label = $Control/GameOverMenu/VBoxContainer/FinalScoreLabel
@onready var retry_button: Button = $Control/GameOverMenu/VBoxContainer/RetryButton
@onready var resume_button: Button = $Control/PauseMenu/VBoxContainer/ResumeButton
@onready var sens_slider: HSlider = $Control/PauseMenu/VBoxContainer/SensContainer/SensSlider

@onready var crosshair_top: ColorRect = $Control/Crosshair/Top
@onready var crosshair_bottom: ColorRect = $Control/Crosshair/Bottom
@onready var crosshair_left: ColorRect = $Control/Crosshair/Left
@onready var crosshair_right: ColorRect = $Control/Crosshair/Right

var crosshair_gap: float = 6.0
var target_gap: float = 6.0

func _ready() -> void:
	# Connect Global signals
	Global.health_changed.connect(_on_health_changed)
	Global.shield_changed.connect(_on_shield_changed)
	Global.ammo_changed.connect(_on_ammo_changed)
	Global.score_changed.connect(_on_score_changed)
	Global.wave_changed.connect(_on_wave_changed)
	Global.player_damaged.connect(_on_player_damaged)
	Global.weapon_switched.connect(_on_weapon_switched)
	Global.game_over_signal.connect(_on_game_over)

	# Setup buttons
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if sens_slider:
		sens_slider.value_changed.connect(_on_sens_changed)

	pause_menu.visible = false
	game_over_menu.visible = false
	damage_vignette.color.a = 0.0
	wave_banner.visible = false
	
	_update_all()

func _process(delta: float) -> void:
	# Fade damage vignette
	if damage_vignette.color.a > 0:
		damage_vignette.color.a = lerp(damage_vignette.color.a, 0.0, delta * 5.0)

	# Crosshair expansion
	crosshair_gap = lerp(crosshair_gap, target_gap, delta * 15.0)
	crosshair_top.position.y = -10 - crosshair_gap
	crosshair_bottom.position.y = 2 + crosshair_gap
	crosshair_left.position.x = -10 - crosshair_gap
	crosshair_right.position.x = 2 + crosshair_gap
	
	# Update pause menu visibility
	if not Global.is_game_over:
		pause_menu.visible = Global.is_paused

func _update_all() -> void:
	_on_health_changed(Global.player_health, Global.max_health)
	_on_shield_changed(Global.player_shield, Global.max_shield)
	_on_score_changed(Global.score)
	_on_wave_changed(Global.current_wave)

func _on_health_changed(current: float, max_val: float) -> void:
	if health_bar: health_bar.value = (current / max_val) * 100.0
	if health_text: health_text.text = "HP %d / %d" % [int(current), int(max_val)]

func _on_shield_changed(current: float, max_val: float) -> void:
	if shield_bar: shield_bar.value = (current / max_val) * 100.0
	if shield_text: shield_text.text = "SHIELD %d" % int(current)

func _on_ammo_changed(in_clip: int, reserve: int) -> void:
	if ammo_text: ammo_text.text = "%d / %d" % [in_clip, reserve]

func _on_score_changed(score: int) -> void:
	if score_text: score_text.text = "SCORE: %d" % score

func _on_wave_changed(wave_num: int) -> void:
	if wave_text: wave_text.text = "WAVE %d" % wave_num
	if wave_banner:
		wave_banner.text = "WAVE %d START" % wave_num
		wave_banner.visible = true
		get_tree().create_timer(2.2).timeout.connect(func(): wave_banner.visible = false)

func _on_weapon_switched(w_name: String) -> void:
	if weapon_text: weapon_text.text = w_name.to_upper()

func _on_player_damaged(_amt: float) -> void:
	if damage_vignette: damage_vignette.color.a = 0.5
	target_gap = 14.0
	get_tree().create_timer(0.15).timeout.connect(func(): target_gap = 6.0)

func _on_game_over() -> void:
	game_over_menu.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if final_score_label:
		final_score_label.text = "FINAL SCORE: %d\nKILLS: %d  |  WAVE SURVIVED: %d" % [Global.score, Global.kills, Global.current_wave]

func _on_retry_pressed() -> void:
	Global.reset_game()
	get_tree().reload_current_scene()

func _on_resume_pressed() -> void:
	Global.is_paused = false
	pause_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_sens_changed(val: float) -> void:
	Global.mouse_sensitivity = val
