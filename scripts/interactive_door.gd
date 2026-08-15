extends Node3D

@export var open_angle: float = 90.0
@export var speed: float = 6.0

var is_open: bool = false
var target_rot_y: float = 0.0
var initial_rot_y: float = 0.0

@onready var door_pivot: Node3D = self

func _ready() -> void:
	initial_rot_y = rotation_degrees.y
	target_rot_y = initial_rot_y

func _process(delta: float) -> void:
	rotation_degrees.y = lerp(rotation_degrees.y, target_rot_y, delta * speed)

	# Check player proximity to open door on interact key E
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0] as CharacterBody3D
		if p and is_instance_valid(p):
			var dist = global_position.distance_to(p.global_position)
			if dist <= 3.2 and Input.is_action_just_pressed("interact"):
				toggle_door()

func toggle_door() -> void:
	is_open = not is_open
	if is_open:
		target_rot_y = initial_rot_y + open_angle
	else:
		target_rot_y = initial_rot_y

func interact() -> void:
	toggle_door()
