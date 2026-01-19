class_name FallState
extends PlayerState

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(player.falling_acc, player.falling_dec)
	player.update_flip_h()
	
	player.move_and_slide()
	
	if player.velocity.y < 0:
		switch_to("JumpState")
	elif player.is_on_floor():
		switch_to("FloorEntryState")
