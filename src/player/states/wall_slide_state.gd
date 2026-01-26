class_name WallSlideState
extends PlayerState

func _enter(_previous_state: State) -> void:
	player.dash_allowed = true

func _physics_update(delta: float) -> void:
	player.apply_wall_slide(delta)
	player.try_wall_jump()
	player.try_dash()
	player.apply_move_anim()
	player.update_shape_scale(delta)
	
	player.move_and_slide()
	
	var h_input_dir: float = signf(player.get_input_vector().x)
	
	if not player.is_on_wall() or h_input_dir != player.get_last_wall_dir():
		switch_to("AirEntryState")
	if player.is_on_floor():
		switch_to("FloorEntryState")
