class_name Sleeper_Animatronic
extends CharacterBody3D
## Basic animatronic controller (lowk js golden freddy lol ).
##
## Behavior:
##   CHASING    - moves toward the player (target_node_path), but only in
##                random bursts (see move_interval_min/max below) instead
##                of continuously and yea
##   RETREATING - triggered by shock(): rushes back to its spawn point
##                ("old spot") at retreat_speed.
##   SPINNING   - once home, spins a full 360 in place, then resumes chasing.

# state machine
enum State { CHASING, RETREATING, SPINNING }


# --- Movement settings ---
@export_group("Basic Stuff")
@export var move_speed: float = 0.2
@export var retreat_speed: float = 8.0            # fast run back to spawn when shocked
@export var arrival_distance: float = 0.3          # how close to home counts as "arrived"
@export var rotation_speed: float = 6.0            # how fast it turns to face its move direction (rad/sec)
@export var spin_speed: float = 10.0               # rad/sec while doing the 360 spin
@export var target_node_path: NodePath  # e.g. the Player, to stalk/approach.


# --- Random movement intervals (only affects CHASING) ---
@export_group("Chasing Variables")
@export var move_duration_min: float = 1.0          # shortest time it moves before pausing
@export var move_duration_max: float = 3.0          # longest time it moves before pausing
@export var pause_duration_min: float = 1.0         # shortest time it pauses before moving again
@export var pause_duration_max: float = 3.0         # longest time it pauses before moving again


# this is the time randomized between each interval
@export_group("Intervals Between Random Moves")
@export var move_interval_min := 1.5
@export var move_interval_max := 7.0


# -- highlighting sprite
@export var sprite_path: NodePath = "AnimatedSprite3D"
@export var highlight_color: Color = Color(1.6, 1.6, 0.6)  # warm/bright tint, tweak to taste

var _sprite: AnimatedSprite3D
var _base_modulate: Color



var _target: Node3D
var _home_position: Vector3
var _state: State = State.CHASING
var _spin_progress: float = 0.0                    # radians turned so far during SPINNING

var _decision_timer: Timer
var _is_moving_allowed: bool = true                 # flips randomly while CHASING

func _ready() -> void:
	# HIGHLIGHTING WHEN PLAYER LOOKING AT ANIMATRONIC
	if target_node_path != NodePath():
		_target = get_node_or_null(target_node_path)
	_home_position = global_position

	_sprite = get_node_or_null(sprite_path)
	if _sprite:
		_base_modulate = _sprite.modulate

	# DECISION TIMER STUFF
	if target_node_path != NodePath():
		_target = get_node_or_null(target_node_path)
	_home_position = global_position

	_decision_timer = Timer.new()
	_decision_timer.one_shot = true
	add_child(_decision_timer)
	_decision_timer.timeout.connect(_on_decision_timer_timeout)
	_start_decision_timer()


func _start_decision_timer() -> void:
	_decision_timer.wait_time = randf_range(move_interval_min, move_interval_max)
	_decision_timer.start()


func _on_decision_timer_timeout() -> void:
	_is_moving_allowed = not _is_moving_allowed
	_start_decision_timer()


func _physics_process(delta: float) -> void:
	pass
	match _state:
		State.CHASING:
			_process_chasing(delta)
		State.RETREATING:
			_process_retreating(delta)
		State.SPINNING:
			_process_spinning(delta)
	move_and_slide()
func _process_chasing(delta: float) -> void:
	var dir: Vector3 = _get_direction_to(_target)

	if _is_moving_allowed:
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	_face_direction(dir, delta)
func _process_retreating(delta: float) -> void:
	var to_home: Vector3 = _home_position - global_position
	to_home.y = 0.0
	if to_home.length() <= arrival_distance:
		velocity.x = 0.0
		velocity.z = 0.0
		_state = State.SPINNING
		_spin_progress = 0.0
		return
	var dir: Vector3 = to_home.normalized()
	velocity.x = dir.x * retreat_speed
	velocity.z = dir.z * retreat_speed
	_face_direction(dir, delta)
func _process_spinning(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	var step: float = spin_speed * delta
	rotate_y(step)
	_spin_progress += step
	if _spin_progress >= TAU:
		_state = State.CHASING
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
## Call this from your UI (e.g. a "Shock" button). Interrupts chasing,
## sends the animatronic running back to its spawn point, then it does
## a full 360 spin before resuming the chase.
func shock() -> void:
	if _state == State.RETREATING or _state == State.SPINNING:
		return  # already shocked / mid-sequence, ignore repeat presses
	_state = State.RETREATING
	
	
	
## Hook this up to whatever signal your UI's shock button emits.
func _on_player_execute_shock() -> void:
	shock()
	
func set_highlighted(is_highlighted: bool) -> void:
	if not _sprite:
		return
	_sprite.modulate = highlight_color if is_highlighted else _base_modulate
