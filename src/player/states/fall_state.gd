class_name FallState
extends PlayerState

func _enter(previous_state: State) -> void:
	if previous_state is RunState:
		player.jump_coyote_timer.start()
	
	if previous_state is JumpState or previous_state is WallJumpState:
		player.velocity.x += player.jump_peak_boost * signf(player.velocity.x)
		player.jump_peak_gravity_timer.start()
		player.try_oneway_platform_assist()

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(player.falling_acc, player.falling_dec)
	player.try_coyote_jump()
	player.try_jump_buffer_timer()
	player.try_wall_slide()
	player.try_wall_jump()
	player.try_coyote_wall_jump()
	player.try_wall_jump_buffer_timer()
	player.try_dash()
	player.update_flip_h()
	player.apply_move_anim()
	player.try_squash(delta)
	player.update_shape_scale()
	
	player.move_and_slide()
	
	if player.velocity.y < 0:
		switch_to("JumpState")
	elif player.is_on_floor():
		switch_to("FloorEntryState")
