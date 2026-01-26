class_name Player
extends CharacterBody2D

signal wall_entered
signal wall_exited

@export var flip_h: bool: set = set_flip_h

@export_group("Horizontal Movement")
@export var max_speed: float
@export_range(1.0, 5.0) var max_h_velocity_ratio: float # Multiplied by max_speed

@export_subgroup("On Floor")
@export_range(0.0, 1.0) var running_acc_time: float
@export_range(0.0, 1.0) var running_dec_time: float

@export_subgroup("In Air")
@export_range(0.0, 1.0) var jumping_acc_time: float
@export_range(0.0, 1.0) var jumping_dec_time: float
@export_range(0.0, 1.0) var falling_acc_time: float
@export_range(0.0, 1.0) var falling_dec_time: float

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
@export var jump_peak_boost: float # Boost applied to horizontal velocity after reaching jump peak
@export_range(0.0, 1.0) var jump_peak_gravity_ratio: float
@export var corner_correction_distance: int
@export var oneway_platform_assist_distance: int

@export_group("On Wall")
@export_subgroup("Wall Slide")
@export var max_wall_slide_speed: float
@export_range(1.0, 2.0) var down_held_wall_slide_ratio: float
@export_range(0.0, 1.0) var wall_slide_acc_time: float # Downward acceleration

@export_subgroup("Wall Jump")
@export_range(0.0, 1.0) var wall_jump_v_velocity_ratio: float # Multiplied by jump_velocity
@export var wall_jump_h_velocity: float
# Horizontal acceleration/deceleration after wall jumping.
@export_range(0.0, 1.0) var wall_jumping_acc_time: float
@export_range(0.0, 1.0) var wall_jumping_dec_time: float
@export_range(0.0, 1.0) var wall_jumping_towards_wall_dec_time: float # While the player is moving towards the wall

@export_group("Dash")
@export var dash_speed: float
@export var dash_distance: float
@export var after_dash_speed: float
@export_range(0.0, 1.0) var after_dash_gravity_ratio: float

@export_group("Animation")
@export_range(-90.0, 90.0, 0.1, "degrees") var max_move_skew: float
@export_range(0.0, 1.0) var shape_rescale_weight: float

@export_subgroup("Squash")
@export_range(1.0, 2.0) var squash_width_scale_at_rest: float
@export_range(1.0, 2.0) var squash_width_scale_at_max_fall: float
@export_range(0.0, 1.0) var squash_height_scale_at_rest: float
@export_range(0.0, 1.0) var squash_height_scale_at_max_fall: float

@export_subgroup("Stretch")
@export_range(0.0, 1.0) var stretch_width_scale: float
@export_range(1.0, 2.0) var stretch_height_scale: float

var dash_allowed: bool = false
var _on_wall: bool = false: # This variable mustn't be edited manually
	set(value):
		if value != _on_wall:
			(wall_entered if value else wall_exited).emit()
		
		_on_wall = value

@onready var jump_velocity: float = -(2.0 * jump_height) / jump_time_to_peak
@onready var max_up_velocity: float = jump_velocity * max_up_velocity_ratio
@onready var max_h_velocity: float = max_speed * max_h_velocity_ratio
@onready var jumping_gravity: float = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var falling_gravity: float = (2.0 * jump_height) / (jump_time_to_land * jump_time_to_land)

@onready var shape: Node2D = $Shape as Node2D
@onready var state_machine: StateMachine = $StateMachine as StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D

@onready var jump_peak_gravity_timer: Timer = %JumpPeakGravity as Timer
@onready var jump_coyote_timer: Timer = %JumpCoyote as Timer
@onready var jump_buffer_timer: Timer = %JumpBuffer as Timer
@onready var wall_jump_coyote_timer: Timer = %WallJumpCoyote as Timer
@onready var wall_jump_buffer_timer: Timer = %WallJumpBuffer as Timer
@onready var dash_cooldown_timer: Timer = %DashCooldown as Timer
@onready var after_dash_gravity_timer: Timer = %AfterDashGravity as Timer

@onready var _default_shape_scale: Vector2 = shape.scale

func _physics_process(_delta: float) -> void:
	_on_wall = is_on_wall()

func get_facing_dir() -> float:
	return -1.0 if flip_h else 1.0

func set_flip_h(value: bool) -> void:
	if not is_node_ready():
		await ready
	
	flip_h = value
	shape.scale.x = absf(shape.scale.x) * get_facing_dir()

func update_flip_h() -> void:
	var h_input_dir: float = signf(get_input_vector().x)
	
	if h_input_dir:
		flip_h = h_input_dir != 1.0

func get_input_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

func apply_movement(delta: float, acc_time: float, dec_time: float) -> void:
	var speed_dir: float = max_speed * get_input_vector().x
	var h_velocity_dir: float = signf(velocity.x)
	var apply_acc: bool = (
			h_velocity_dir == 0.0
			or (velocity.x - speed_dir) * h_velocity_dir <= 0.0
	)
	
	var step: float = max_speed / (acc_time if apply_acc else dec_time)
	
	velocity.x = move_toward(velocity.x, speed_dir, step * delta)
	velocity.x = clampf(velocity.x, -max_h_velocity, max_h_velocity)

func apply_gravity(delta: float) -> void:
	velocity.y += calculate_gravity() * delta
	velocity.y = clampf(velocity.y, max_up_velocity, calculate_gravity_limit())

func get_default_gravity() -> float:
	return falling_gravity if velocity.y >= 0.0 else jumping_gravity

func calculate_gravity() -> float:
	return get_default_gravity() * (
			jump_peak_gravity_ratio if not jump_peak_gravity_timer.is_stopped()
			else after_dash_gravity_ratio if not after_dash_gravity_timer.is_stopped()
			else jump_not_held_gravity_ratio if not Input.is_action_pressed("jump")
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
	apply_stretch()

func try_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump()

func try_coyote_jump() -> void:
	if not jump_coyote_timer.is_stopped():
		try_jump()

func try_jump_buffer_timer() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

func try_buffer_jump() -> void:
	if not jump_buffer_timer.is_stopped():
		jump()

func stop_jump_timers() -> void:
	jump_coyote_timer.stop()
	jump_buffer_timer.stop()
	wall_jump_coyote_timer.stop()
	wall_jump_buffer_timer.stop()

func get_last_wall_dir() -> float:
	return -signf(get_wall_normal().x)

func apply_wall_slide(delta: float) -> void:
	var step: float = max_wall_slide_speed / wall_slide_acc_time
	velocity.y = move_toward(velocity.y, calculate_wall_slide_speed(), step * delta)

func can_wall_slide() -> bool:
	# Can wall slide if the player is touching the wall and moving towards it.
	return is_on_wall() and get_input_vector().x * get_last_wall_dir() > 0

func try_wall_slide() -> void:
	if can_wall_slide():
		state_machine.activate_state_by_name("WallSlideState")

func calculate_wall_slide_speed() -> float:
	return max_wall_slide_speed * (
			down_held_wall_slide_ratio if Input.is_action_pressed("down")
			else 1.0
	)

func wall_jump() -> void:
	var wall_jump_dir: float = -get_last_wall_dir()
	
	velocity.y = jump_velocity * wall_jump_v_velocity_ratio
	velocity.x = wall_jump_h_velocity * wall_jump_dir
	apply_stretch()
	
	state_machine.activate_state_by_name.call_deferred("WallJumpState")

func try_wall_jump(ignore_wall: bool = false) -> void:
	if Input.is_action_just_pressed("jump") and (is_on_wall() or ignore_wall):
		wall_jump()

func try_coyote_wall_jump() -> void:
	if not wall_jump_coyote_timer.is_stopped():
		try_wall_jump(true)

func try_wall_jump_buffer_timer() -> void:
	if Input.is_action_just_pressed("jump"):
		wall_jump_buffer_timer.start()

func _on_wall_entered() -> void:
	if not wall_jump_buffer_timer.is_stopped():
		wall_jump()

func _on_wall_exited() -> void:
	if velocity.y > 0:
		wall_jump_coyote_timer.start()

func calculate_wall_jumping_dec_time() -> float:
	var h_input_dir: float = signf(get_input_vector().x)
	
	return (
			wall_jumping_towards_wall_dec_time if h_input_dir == get_last_wall_dir()
			else wall_jumping_dec_time
	)

func can_dash() -> bool:
	return dash_allowed and dash_cooldown_timer.is_stopped()

func try_dash() -> void:
	if Input.is_action_just_pressed("dash") and can_dash():
		state_machine.activate_state_by_name.call_deferred("DashState")

func try_corner_correction(delta: float) -> void:
	var v_motion: Vector2 = Vector2(0.0, velocity.y * delta)
	
	if not test_move(global_transform, v_motion):
		return
	
	# Multiplied by 2 so each offset increments by 0.5 instead of 1.0.
	for offset_step: int in range(1, corner_correction_distance * 2 + 1):
		var offset: float = offset_step / 2.0
	
		for dir: float in [-1.0, 1.0]:
			var h_offset: Vector2 = Vector2(offset * dir, 0)
			var test_transform: Transform2D = global_transform.translated(h_offset)
			
			if not test_move(test_transform, v_motion):
				translate(h_offset)
				
				# Stop the player if they are moving opposite to the corner's direction.
				if velocity.x * dir < 0.0:
					velocity.x = 0.0
				
				return

func try_oneway_platform_assist() -> void:
	if test_move(global_transform, Vector2.DOWN):
		return
	
	# Multiplied by 2 so each offset increments by 0.5 instead of 1.0.
	for offset_step: int in range(oneway_platform_assist_distance * 2 + 1):
		var offset: float = offset_step / 2.0
		var v_offset: Vector2 = Vector2.UP * offset
		
		var test_transform: Transform2D = global_transform.translated(v_offset)
		
		if test_move(test_transform, Vector2.DOWN):
			# Make sure the player doesn't get stuck.
			if not test_move(test_transform, Vector2.UP):
				translate(v_offset)
			
			return

func apply_move_anim() -> void:
	var max_move_skew_rad: float = deg_to_rad(max_move_skew)
	
	shape.skew = remap(velocity.x, -max_speed, max_speed, -max_move_skew_rad, max_move_skew_rad)

func update_shape_scale(delta: float) -> void:
	var target: Vector2 = _default_shape_scale * shape.scale.sign()
	var frame_weight: float = 1.0 - pow(1.0 - shape_rescale_weight, 60.0 * delta)
	
	shape.scale = shape.scale.lerp(target, frame_weight)

func apply_squash() -> void:
	var max_fall_speed: float = calculate_gravity_limit()
	var vertical_speed: float = get_position_delta().y / get_physics_process_delta_time()
	
	shape.scale.x *= remap(vertical_speed, 0.0, max_fall_speed, squash_width_scale_at_rest, squash_width_scale_at_max_fall)
	shape.scale.y *= remap(vertical_speed, 0.0, max_fall_speed, squash_height_scale_at_max_fall, squash_height_scale_at_rest)

func apply_stretch() -> void:
	shape.scale *= Vector2(stretch_width_scale, stretch_height_scale)
