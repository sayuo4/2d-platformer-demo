class_name DashState
extends PlayerState

var start_pos: Vector2
var dash_dir: float

func _enter(previous_state: State) -> void:
	player.dash_allowed = false
	start_pos = player.global_position
	
	# If the player was wall sliding, dash into the opposite direction.
	if previous_state is WallSlideState:
		player.flip_h = !player.flip_h
	
	dash_dir = player.get_facing_dir()
	player.velocity = Vector2(player.dash_speed * dash_dir, 0.0)

func _exit(_next_state: State) -> void:
	player.velocity.x = player.after_dash_speed * dash_dir
	player.dash_cooldown_timer.start()
	player.after_dash_gravity_timer.start()
	
	start_pos = Vector2.ZERO

func _physics_update(_delta: float) -> void:
	player.apply_move_anim()
	
	player.move_and_slide()
	
	if (start_pos.distance_to(player.global_position) >= player.dash_distance
		or player.is_on_wall()
	):
		switch_to("AirEntryState")
