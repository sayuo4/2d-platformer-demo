class_name WallSlideState
extends PlayerState

func _physics_update(_delta: float) -> void:
	player.apply_wall_slide()
	player.try_wall_jump()
	player.try_dash()
	player.apply_move_anim()
	player.update_shape_scale()
	
	player.move_and_slide()
	
	var h_input_dir: float = signf(player.get_input_vector().x)
	
	if not player.is_on_wall() or h_input_dir != player.get_last_wall_dir():
		switch_to("AirEntryState")
	if player.is_on_floor():
		switch_to("FloorEntryState")
