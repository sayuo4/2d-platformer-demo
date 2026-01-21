class_name WallJumpState
extends PlayerState

func _enter(_previous_state: State) -> void:
	player.stop_jump_timers()

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(player.wall_jumping_acc, player.calculate_wall_jumping_dec())
	player.try_wall_jump()
	player.try_dash()
	player.try_corner_correction(delta)
	player.update_flip_h()
	player.apply_move_anim()
	player.update_shape_scale()
	
	player.move_and_slide()
	
	if player.velocity.y >= 0:
		switch_to("FallState")
	if player.get_slide_collision_count() > 0:
		switch_to("JumpState")
