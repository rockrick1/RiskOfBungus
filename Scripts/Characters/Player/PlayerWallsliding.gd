extends PlayerMovementState

@export var fall_gravity_multiplier := .3
@export var walljump_force_multiplier := 1.0
@export var jump_start_air_control := 1
@export var jump_end_air_control := 5
@export var jump_air_control_transition_time := .5
@export var break_force := 5.0

var move_direction : Vector3
var wall_normal : Vector3

func enter(params: Dictionary):
	if params.is_wall_on_left:
		animator.set("parameters/ground_air_transition/transition_request", "wallslideflip")
	else:
		animator.set("parameters/ground_air_transition/transition_request", "wallslide")
	move_direction = params.move_direction
	wall_normal = player.get_wall_normal()

func physics_process(delta):
	if player.is_on_floor():
		transitioned.emit(self, "idle")
		super.physics_process(delta)
		return
	
	var wants_jump := Input.is_action_just_pressed("jump")
	var is_on_wall := player.is_on_wall_only()
	if wants_jump or not is_on_wall:
		var params := PlayerAirborneState.Params.new()
		if wants_jump:
			wall_normal.y = 1
			params.jump_force = wall_normal * cc.base_jump_strength * walljump_force_multiplier
			params.override_current_velocity = true
			params.start_air_control = jump_start_air_control
			params.end_air_control = jump_end_air_control
			params.air_control_transition_time = jump_air_control_transition_time
		transitioned.emit(self, "airborne", { airborne_params = params })
		super.physics_process(delta)
		return
	
	player.velocity.y -= player.gravity * delta * fall_gravity_multiplier
	
	move_direction = move_direction.lerp(Vector3.ZERO, delta * break_force)
	
	var h_speed := cc.run_speed
	player.velocity.x = move_direction.x * h_speed
	player.velocity.z = move_direction.z * h_speed
	
	if move_direction:
		player.mesh.rotation.y = lerp_angle(player.mesh.rotation.y, atan2(player.velocity.x, player.velocity.z), player.LERP_VALUE)
	
	animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 1.0, delta * player.ANIMATION_BLEND))
	super.physics_process(delta)
