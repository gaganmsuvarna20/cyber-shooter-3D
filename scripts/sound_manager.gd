extends Node

var players: Array[AudioStreamPlayer] = []
var max_players: int = 12
var current_player_idx: int = 0

# Procedurally generated audio streams
var sound_rifle: AudioStreamWAV
var sound_shotgun: AudioStreamWAV
var sound_plasma: AudioStreamWAV
var sound_railgun: AudioStreamWAV
var sound_hitmarker: AudioStreamWAV
var sound_player_hurt: AudioStreamWAV
var sound_pickup: AudioStreamWAV
var sound_reload: AudioStreamWAV
var sound_jump: AudioStreamWAV
var sound_enemy_explode: AudioStreamWAV

func _ready() -> void:
	# Create pool of audio players
	for i in range(max_players):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		players.append(p)
	
	# Generate audio FX
	sound_rifle = _create_noise_sound(0.12, 0.9, 0.05)
	sound_shotgun = _create_noise_sound(0.25, 1.0, 0.02)
	sound_plasma = _create_sweep_sound(180.0, 60.0, 0.35)
	sound_railgun = _create_sweep_sound(1800.0, 120.0, 0.45)
	sound_hitmarker = _create_tone_sound(1200.0, 0.06, 0.4, false)
	sound_player_hurt = _create_tone_sound(180.0, 0.2, 0.6, true)
	sound_pickup = _create_chime_sound(0.15)
	sound_reload = _create_tone_sound(600.0, 0.1, 0.3, false)
	sound_jump = _create_sweep_sound(200.0, 450.0, 0.12)
	sound_enemy_explode = _create_noise_sound(0.35, 0.8, 0.01)

func play_sound(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	var player = players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_players
	
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_rifle_shot() -> void:
	play_sound(sound_rifle, -4.0, randf_range(0.95, 1.05))

func play_shotgun_shot() -> void:
	play_sound(sound_shotgun, 0.0, randf_range(0.85, 0.95))

func play_plasma_shot() -> void:
	play_sound(sound_plasma, 2.0, randf_range(0.95, 1.05))

func play_railgun_shot() -> void:
	play_sound(sound_railgun, 4.0, randf_range(0.98, 1.02))

func play_hitmarker() -> void:
	play_sound(sound_hitmarker, -6.0, randf_range(0.98, 1.02))

func play_player_hurt() -> void:
	play_sound(sound_player_hurt, -2.0, randf_range(0.9, 1.1))

func play_pickup() -> void:
	play_sound(sound_pickup, -3.0, 1.0)

func play_reload() -> void:
	play_sound(sound_reload, -5.0, 1.2)

func play_jump() -> void:
	play_sound(sound_jump, -8.0, 1.0)

func play_enemy_explode() -> void:
	play_sound(sound_enemy_explode, -2.0, randf_range(0.8, 1.1))

# Procedural Audio Generators (8-bit 44.1kHz mono WAV buffers)
func _create_noise_sound(duration: float, max_vol: float, decay_rate: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t = float(i) / num_samples
		var env = exp(-t / max(decay_rate, 0.001)) * max_vol
		var noise = (randf() * 2.0 - 1.0) * env
		var sample_val = int(clamp(noise * 127.0 + 128.0, 0.0, 255.0))
		data[i] = sample_val
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_tone_sound(freq: float, duration: float, vol: float, is_sawtooth: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		var env = (1.0 - progress) * vol
		var val = 0.0
		if is_sawtooth:
			val = (fmod(t * freq, 1.0) * 2.0 - 1.0) * env
		else:
			val = sin(TAU * freq * t) * env
		var sample_val = int(clamp(val * 127.0 + 128.0, 0.0, 255.0))
		data[i] = sample_val
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_chime_sound(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var t = float(i) / sample_rate
		var freq = lerp(523.25, 1046.5, progress) # C5 to C6
		var env = sin(progress * PI) * 0.5
		var val = sin(TAU * freq * t) * env
		var sample_val = int(clamp(val * 127.0 + 128.0, 0.0, 255.0))
		data[i] = sample_val
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_sweep_sound(start_freq: float, end_freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var progress = float(i) / num_samples
		var t = float(i) / sample_rate
		var freq = lerp(start_freq, end_freq, progress)
		var env = (1.0 - progress) * 0.4
		var val = sin(TAU * freq * t) * env
		var sample_val = int(clamp(val * 127.0 + 128.0, 0.0, 255.0))
		data[i] = sample_val
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav
