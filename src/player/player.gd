class_name Player
extends CharacterBody2D

@export var flip_h: bool: set = set_flip_h

@export_group("Horizontal Movement")
@export var max_speed: float
@export_range(1.0, 5.0) var max_h_velocity_ratio: float # Multiplied by max_speed

@export_subgroup("On Floor")
@export var running_acc: float
@export var running_dec: float

@export_subgroup("In Air")
@export var jumping_acc: float
@export var jumping_dec: float
@export var falling_acc: float
@export var falling_dec: float

@export_group("Vertical Movement")
@export_subgroup("Gravity")
@export_range(1.0, 2.0) var jump_not_held_gravity_ratio: float
@export_range(1.0, 2.0) var down_held_gravity_ratio: float
@export var gravity_limit: float
@export_range(1.0, 2.0) var down_held_gravity_limit_ratio: float

@export_subgroup("Jump")
@export var jump_height: float
@export_range(0.0, 1.0) var jump_time_to_peak: float
@export_range(0.0, 1.0) var jump_time_to_land: float
@export_range(1.0, 5.0) var max_up_velocity_ratio: float # Multiplied by jump_velocity

@onready var jump_velocity: float = -(2.0 * jump_height) / jump_time_to_peak
@onready var max_up_velocity: float = jump_velocity * max_up_velocity_ratio
@onready var max_h_velocity: float = max_speed * max_h_velocity_ratio
@onready var jumping_gravity: float = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var falling_gravity: float = (2.0 * jump_height) / (jump_time_to_land * jump_time_to_land)

@onready var shape: Node2D = $Shape

func set_flip_h(value: bool) -> void:
	if not is_node_ready():
		await ready
	
	flip_h = value
	
	shape.scale.x = absf(shape.scale.x) * (-1.0 if flip_h else 1.0)

func update_flip_h() -> void:
	var h_input_dir: float = signf(get_input_vector().x)
	
	if h_input_dir:
		flip_h = h_input_dir != 1

func get_input_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

func apply_movement(acc: float, dec: float) -> void:
	var speed: float = max_speed * get_input_vector().x
	var h_velocity_dir: float = signf(velocity.x)
	var apply_acc: bool = (
			h_velocity_dir == 0.0
			or (velocity.x - speed) * h_velocity_dir <= 0.0
	)
	
	var step: float = acc if apply_acc else dec
	
	velocity.x = move_toward(velocity.x, speed, step)
	velocity.x = clampf(velocity.x, -max_h_velocity, max_h_velocity)

func apply_gravity(delta: float) -> void:
	velocity.y += calculate_gravity() * delta
	velocity.y = clampf(velocity.y, max_up_velocity, calculate_gravity_limit())

func get_default_gravity() -> float:
	return falling_gravity if velocity.y >= 0.0 else jumping_gravity

func calculate_gravity() -> float:
	return get_default_gravity() * (
			jump_not_held_gravity_ratio if not Input.is_action_pressed("jump")
			else down_held_gravity_ratio if Input.is_action_pressed("down") and velocity.y > 0
			else 1.0
	)

func calculate_gravity_limit() -> float:
	return gravity_limit * (
			down_held_gravity_ratio if Input.is_action_pressed("down") and velocity.y > 0
			else 1.0
	)

func jump() -> void:
	velocity.y = jump_velocity

func try_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump()
