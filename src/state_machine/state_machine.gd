class_name StateMachine
extends Node

signal state_transitioned(previous_state, current_state)

@export var target_node: Node
@export var default_state: State

## States managed by the state machine. This value is determined once on ready by the node's children and their child nodes.
var states: Dictionary[StringName, State]

@onready var active_state: State # This variable should only be edited using activate_state

func _ready() -> void:
	if target_node:
		await target_node.ready
	
	add_child_states(self)
	
	states.make_read_only()
	
	if default_state:
		if default_state not in states.values():
			push_error("Default state '%s' is missing in state machine '%s'." % [default_state.get_path(), get_path()])
		else:
			activate_state(default_state)

func _process(delta: float) -> void:
	if should_update():
		active_state._update(delta)

func _physics_process(delta: float) -> void:
	if should_update():
		active_state._physics_update(delta)

func add_child_states(node: Node):
	for child in node.get_children():
		var state: State = child as State
		
		if state:
			states[state.name] = state
			
			state.target_node = target_node
			state._is_active_callable = _is_state_active.bind(state)
			state._switch_state_callable = activate_state_by_name
			state._deactivate_state_callable = activate_state.bind(null)
			
			state._state_machine_ready()
		
		add_child_states(child)

func should_update() -> bool:
	return active_state and target_node

func _is_state_active(state: State) -> bool:
	return state == active_state

func activate_state(state: State, pass_as_previous: State = null) -> void:
	var next_state: State = state
	var previous_state: State = pass_as_previous if pass_as_previous else active_state
	
	if next_state == previous_state:
		return

	if next_state and next_state not in states.values():
		next_state = null
		push_error("Attempted to activate missing state '%s' in state machine '%s'." % [next_state.get_path(), get_path()])
	
	active_state = next_state
	
	if next_state:
		next_state._enter(previous_state)
	if previous_state:
		previous_state._exit(next_state)
	
	state_transitioned.emit(previous_state, next_state)

func activate_state_by_name(state_name: StringName, pass_as_previous: State = null) -> void:
	var state: State = states.get(state_name)
	
	if not state:
		push_error("Attempted to activate missing state '%s' by name in state machine '%s'." % [state_name, get_path()])
		return
	
	activate_state(state, pass_as_previous)
