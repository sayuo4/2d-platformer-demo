class_name AirEntryState
extends PlayerState

func _enter(previous_state: State) -> void:
	if player.velocity.y >= 0:
		switch_to("FallState", previous_state)
	else:
		switch_to("JumpState", previous_state)
	
	player.stop_jump_timers()
