class_name RunState
extends PlayerState

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(player.running_acc, player.running_dec)
	player.try_jump()
	player.try_dash()
	player.update_flip_h()
	player.apply_move_anim()
	player.update_shape_scale()
	
	player.move_and_slide()
	
	if not player.is_on_floor():
		switch_to("AirEntryState")
	elif not player.velocity.x and not player.get_input_vector().x:
		switch_to("IdleState")
