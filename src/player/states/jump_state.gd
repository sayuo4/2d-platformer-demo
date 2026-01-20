class_name JumpState
extends PlayerState

func _enter(_previous_state: State) -> void:
	player.stop_jump_timers()

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(player.jumping_acc, player.jumping_dec)
	player.try_wall_jump()
	player.try_coyote_wall_jump()
	player.try_wall_jump_buffer_timer()
	player.try_dash()
	player.update_flip_h()
	
	player.move_and_slide()
	
	if player.velocity.y >= 0:
		switch_to("FallState")
