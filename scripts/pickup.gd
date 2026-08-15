extends Area3D

enum PickupType { HEALTH, AMMO }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var float_speed: float = 3.0
@export var rotate_speed: float = 2.0
@export var magnet_range: float = 5.0
@export var magnet_speed: float = 8.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

var initial_y: float = 0.0
var time_passed: float = 0.0
var player_node: Node3D = null

func _ready() -> void:
	initial_y = global_position.y
	time_passed = randf() * 10.0
	
	# Set up material & color according to type
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.emission_enabled = true
	
	if pickup_type == PickupType.HEALTH:
		mat.albedo_color = Color(0.2, 0.9, 0.3)
		mat.emission = Color(0.2, 1.0, 0.4)
		mat.emission_energy_multiplier = 2.0
		if light: light.light_color = Color(0.2, 1.0, 0.4)
	else:
		mat.albedo_color = Color(1.0, 0.8, 0.1)
		mat.emission = Color(1.0, 0.8, 0.2)
		mat.emission_energy_multiplier = 2.0
		if light: light.light_color = Color(1.0, 0.8, 0.2)
		
	if mesh_instance:
		mesh_instance.material_override = mat
		
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_passed += delta * float_speed
	rotate_y(rotate_speed * delta)
	
	if player_node == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0] as Node3D
			
	if player_node and is_instance_valid(player_node):
		var dist = global_position.distance_to(player_node.global_position)
		if dist < magnet_range:
			global_position = global_position.move_toward(player_node.global_position + Vector3(0, 1.0, 0), magnet_speed * delta)
		else:
			global_position.y = initial_y + sin(time_passed) * 0.25
	else:
		global_position.y = initial_y + sin(time_passed) * 0.25

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if pickup_type == PickupType.HEALTH:
			Global.heal_player(30.0)
			SoundManager.play_pickup()
			queue_free()
		elif pickup_type == PickupType.AMMO:
			if body.has_method("add_reserve_ammo"):
				body.call("add_reserve_ammo", 60, 16)
			SoundManager.play_pickup()
			queue_free()
