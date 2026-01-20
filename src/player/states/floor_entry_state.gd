class_name FloorEntryState
extends PlayerState

func _enter(previous_state: State) -> void:
	if player.velocity.x == 0:
		switch_to("IdleState", previous_state)
	else:
		switch_to("RunState", previous_state)
	
	player.try_buffer_jump()
	player.stop_jump_timers()
	player.dash_allowed = true
