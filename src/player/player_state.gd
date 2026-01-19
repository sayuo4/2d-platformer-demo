class_name PlayerState
extends State

var player: Player

func _state_machine_ready() -> void:
	if target_node is not Player:
		push_error("Player state '%s' target node isn't a player." % get_path())
		return
	
	player = target_node as Player
