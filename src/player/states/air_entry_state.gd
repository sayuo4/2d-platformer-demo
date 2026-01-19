class_name AirEntryState
extends PlayerState

func _enter(_previous_state: State) -> void:
	if player.velocity.y >= 0:
		switch_to("FallState")
	else:
		switch_to("JumpState")
