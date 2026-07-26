class_name Player
extends CharacterBody3D

# --- STATE MACHINE --- #
enum State { NORMAL, DEATH_BY_SLEEPER, ADVERTISEMENT }
var _state = State.NORMAL

# --- SLEEPER ANIMATRONIC -- #
@export var sleeper_animatronic : Sleeper_Animatronic

# interact raycast
@export var interact_ray : RayCast3D


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
	if _state == State.NORMAL:
		check_for_shock()


# THIS IS THE CAMERA MOVEMENT
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Toggle mouse capture with Esc, handy for testing.
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if _state == State.DEATH_BY_SLEEPER:
		look_at(Vector3(sleeper_animatronic.global_position.x,sleeper_animatronic.global_position.y, sleeper_animatronic.global_position.z  ))

	
	if _state == State.NORMAL:
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





# ------------------- #
# STATE MACHINE STUFF
# -------------------- #












# APPLYING THE SHOCK

func check_for_shock() -> void:
	var coll = interact_ray.get_collider()
	if interact_ray.is_colliding():
		if coll is RouletteWheel:
			$Control/defaultcrosshair.hide()
			$Control/aimedcrosshair.show()
			if Input.is_action_just_pressed("Shock"):
				get_tree().change_scene_to_file("res://Scenes/endscrene.tscn")

			
		if coll is Sleeper_Animatronic:
			$Control/defaultcrosshair.hide()
			$Control/aimedcrosshair.show()
			if Input.is_action_just_pressed("Shock") and shock_timer.time_left == 0.0:
				shock_timer.start()
				execute_shock.emit()
		else:
			$Control/defaultcrosshair.show()
			$Control/aimedcrosshair.hide()
	else:
		$Control/defaultcrosshair.show()
		$Control/aimedcrosshair.hide()


# END THE GAME AFTER BEING KILLED
func _on_sleeper_animatronic_sleeper_kills_player() -> void:
	end_game()
	
func end_game() -> void:
	_state = State.DEATH_BY_SLEEPER
