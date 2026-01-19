class_name JumpState
extends PlayerState

func _physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(player.jumping_acc, player.jumping_dec)
	player.update_flip_h()
	
	player.move_and_slide()
	
	if player.velocity.y >= 0:
		switch_to("FallState")
