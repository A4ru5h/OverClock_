class_name Sleeper_Animatronic
extends CharacterBody3D

## Golden-Freddy-style "sleeper" animatronic.
##
## Behavior:
##   SLEEPING - idle, motionless. Wakes up on its own after sleep_duration.
##   WAKING   - gradually getting up (multi-stage). No movement yet.
##   CHASING  - moves toward the player in random bursts (see
##              move_duration_min/max and pause_duration_min/max).
##   SHOCKED  - triggered by shock(): freezes in place, waits shock_delay
##              seconds, then resets straight back to SLEEPING to restart
##              the whole cycle.

enum State { SLEEPING, WAKING, CHASING, SHOCKED, GOING_FOR_KILL }
@export var player : Player

# --- Animation ---
@export var anim_player: AnimationPlayer
@export var gpu_particles : GPUParticles3D
@onready var timer: Timer = $Timer
@export var player_kill_point : Node3D 

signal sleeper_kills_player


# --- Phase timing ---
@export var start_state: State = State.SLEEPING # what it's doing when the level loads
@export var timer_min : float = 2.0   
@export var timer_max : float = 6.0
@export var timer_min_chase : float = 8.0
@export var timer_max_chase : float = 12.0

@export var rotation_speed : float = 0.5
var _state: State


func _ready() -> void:

	_enter_state(start_state)


func _physics_process(delta: float) -> void:
	match _state:
		State.SLEEPING:
			pass  # no movement, just waiting on _stage_timer
		State.WAKING:
			pass
		State.CHASING:
			pass
		State.SHOCKED:
			pass  # frozen, just waiting on _stage_timer

	move_and_slide()


# ---------------------------------------------------------------------------
# STATE MACHINE
# ---------------------------------------------------------------------------

func _enter_state(new_state: State) -> void:
	_state = new_state
	velocity = Vector3.ZERO

	match new_state:
		State.SLEEPING:
			var _a = randf_range(timer_min,timer_max)
			timer.start(_a)
			anim_player.play("Crouched")

		State.WAKING:
			var _a = randf_range(timer_min,timer_max)
			timer.start(_a)
			anim_player.play("Crouched")

		State.CHASING:
			var _a = randf_range(timer_min_chase,timer_max_chase)
			timer.start(_a)
			anim_player.play("Crouched_2")

		State.SHOCKED:
			anim_player.play("Shocked")
			if gpu_particles:
				gpu_particles.restart()  # restart() resets + emits, works even if it fired recently
		
		State.GOING_FOR_KILL:
			_get_direction_to(player)
			anim_player.play("Attack")



func _on_sleep_finished() -> void:
	_enter_state(State.WAKING)


func _on_wake_finished() -> void:
	_enter_state(State.CHASING)


func _on_shock_finished() -> void:
	_enter_state(State.SLEEPING)


# ---------------------------------------------------------------------------
# SHARED HELPERS
# ---------------------------------------------------------------------------

func _get_direction_to(node: Node3D) -> Vector3:
	if not node:
		return Vector3.ZERO
	var to_target: Vector3 = node.global_position - global_position
	to_target.y = 0.0
	if to_target.length() < 0.1:
		return Vector3.ZERO
	return to_target.normalized()


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir == Vector3.ZERO:
		return
	var target_angle: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Call this from your UI (e.g. a "Shock" button). Only does anything while
## it's actively CHASING — freezes it in place, then after shock_delay
## seconds it resets all the way back to SLEEPING and starts the whole
## cycle over again.
func shock() -> void:
	_enter_state(State.SHOCKED)


## Hook this up to whatever signal your UI's shock button emits.
func _on_player_execute_shock() -> void:
	shock()


func _on_timer_timeout() -> void:
	
	if _state == State.SLEEPING:
		_enter_state(State.WAKING)
	elif _state == State.WAKING:
		_enter_state(State.CHASING)
	elif _state == State.CHASING:
		# END THE GAME GO FOR KILL
		end_game()
	elif _state == State.SHOCKED:
		pass

# end the game with jump scare
func end_game() -> void:
	global_position = player_kill_point.global_position
	
	sleeper_kills_player.emit()
	_enter_state(State.GOING_FOR_KILL)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Shocked":
		_enter_state(State.SLEEPING)
