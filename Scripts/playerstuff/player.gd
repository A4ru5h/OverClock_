class_name Player
extends CharacterBody3D

# --- movemnt settigs --- lowk not needed tho #
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8

# interact raycast
@export var interact_ray : RayCast3D

# HOVERING over animatronci
var _hovered_animatronic: Sleeper_Animatronic = null


# --- SIGNAL for shocks -- #
signal execute_shock
@onready var shock_timer: Timer = $ShockCooldown

# --- Mouse look settings --- #
@export var mouse_sensitivity: float = 0.15

## this is how much degrees left and right you can turn, if u want we can make it 360 
@export var max_yaw_degrees: float = 90.0

## this is how much degrees up and down you can turn, if u want we can make it 360 
@export var max_pitch_degrees: float = 45.0

# head (camera mount of camera3d)
@export var head : Node3D

# Current rotation offsets from the "center" facing direction, in radians.
var yaw_offset: float = 0.0
var pitch_offset: float = 0.0

# The center (starting) rotations, captured on ready, so limits are relative
# to wherever the player/camera was originally facing.
var center_yaw: float = 0.0
var center_pitch: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	center_yaw = rotation.y
	center_pitch = head.rotation.x

func _process(delta: float) -> void:
	check_for_shock()
	_update_hover_highlight()
	check_for_shock()


# THIS IS THE CAMERA MOVEMENT
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Toggle mouse capture with Esc, handy for testing.
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var max_yaw_rad: float = deg_to_rad(max_yaw_degrees)
		var max_pitch_rad: float = deg_to_rad(max_pitch_degrees)

		# Accumulate offsets, then clamp them to the allowed range.
		yaw_offset -= event.relative.x * mouse_sensitivity * 0.01
		yaw_offset = clamp(yaw_offset, -max_yaw_rad, max_yaw_rad)

		pitch_offset -= event.relative.y * mouse_sensitivity * 0.01
		pitch_offset = clamp(pitch_offset, -max_pitch_rad, max_pitch_rad)

		# Apply: body yaw rotates left/right, head pitch rotates up/down.
		rotation.y = center_yaw + yaw_offset
		head.rotation.x = center_pitch + pitch_offset


# APPLYING THE SHOCK
func _update_hover_highlight() -> void:
	var current := _get_animatronic_under_raycast()
	if current != _hovered_animatronic:
		if _hovered_animatronic:
			_hovered_animatronic.set_highlighted(false)
		if current:
			current.set_highlighted(true)
		_hovered_animatronic = current


func _get_animatronic_under_raycast() -> Sleeper_Animatronic:
	if not interact_ray.is_colliding():
		return null
	var collider := interact_ray.get_collider()
	if collider is Sleeper_Animatronic:
		return collider
	return null

func _is_looking_at_animatronic() -> bool:
	return _hovered_animatronic != null


func check_for_shock() -> void:
	if _is_looking_at_animatronic():
		if Input.is_action_just_pressed("Shock") and shock_timer.time_left == 0.0:
			shock_timer.start()
			execute_shock.emit()


# PHYSICS
func _physics_process(delta: float) -> void:
	pass
	# I'm commenting it out for now, but if you want player movement just uncomment
	#player_move(delta)
	

func player_move(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else move_speed

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
