class_name State
extends Node

# These variables are managed by the state machine and mustn't be modified manually.
var target_node: Node
var _is_active_callable: Callable
var _deactivate_state_callable: Callable
var _switch_state_callable: Callable

func is_active() -> bool:
	return _is_active_callable.call()

func force_switch_to(state_name: StringName, pass_as_previous: State = null) -> void:
	_switch_state_callable.call(state_name, pass_as_previous)

## Switches to the given state at the end of the current frame if this state is active.
func switch_to(state_name: StringName, pass_as_previous: State = null) -> void:
	if is_active():
		force_switch_to.call_deferred(state_name, pass_as_previous)

func force_deactivate() -> void:
	_deactivate_state_callable.call()

## Deactivates this state at the end of the current frame.
func deactivate() -> void:
	if is_active():
		force_deactivate.call_deferred()

## Called when the state machine managing this node is ready. This method is meant to be overriden.
func _state_machine_ready() -> void:
	pass

## Called when the state becomes active. This method is meant to be overriden.
func _enter(_previous_state: State) -> void:
	pass

## Called when the state becomes inactive. This method is meant to be overriden.
func _exit(_current_state: State) -> void:
	pass

## Called every process frame while the state is active. This method is meant to be overriden.
func _update(_delta: float) -> void:
	pass

## Called every physics frame while the state is active. This method is meant to be overriden.
func _physics_update(_delta: float) -> void:
	pass
