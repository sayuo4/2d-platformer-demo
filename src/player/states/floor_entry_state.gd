class_name FloorEntryState
extends PlayerState

func _enter(_previous_state: State) -> void:
	if player.velocity.x == 0:
		switch_to("IdleState")
	else:
		switch_to("RunState")
