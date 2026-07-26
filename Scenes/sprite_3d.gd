extends Sprite3D

@onready var player_camera = get_viewport().get_camera_3d()

@export var death_screen: CanvasLayer

@export var min_distance := 1
@export var max_distance := 2

@export var teleport_interval := 2.0

@export var kill_time := 1.0
@export var view_angle := 8.0

@export var stare_fill_speed := 0.8
@export var stare_decay_speed := 0.5
@export var kill_threshold := 1.0

var stare_meter := 0.0

@export_multiline var death_message := "IT'S RUDE TO STARE."

@export var grace_period := 10.0

var time_alive := 0.0

var look_timer := 0.0
var dead := false


func _ready():

	teleport_in_front_of_player()

	var timer = Timer.new()
	timer.wait_time = teleport_interval
	timer.autostart = true
	timer.timeout.connect(try_teleport)

	add_child(timer)


func _process(delta):

	if dead:
		return

	if player_camera != null:
		look_at_player()

	time_alive += delta

	if time_alive < grace_period:
		return


	if player_is_looking():

		stare_meter += stare_fill_speed * delta

	else:

		stare_meter -= stare_decay_speed * delta


	stare_meter = clamp(
		stare_meter,
		0.0,
		kill_threshold
	)


	if stare_meter >= kill_threshold:
		kill_player()


func look_at_player():

	look_at(
		player_camera.global_position,
		Vector3.UP
	)

	# Sprite3D textures usually face backwards
	rotate_y(deg_to_rad(180))



func try_teleport():

	# Only move when the player is not looking
	if !player_is_looking():
		teleport_in_front_of_player()



func teleport_in_front_of_player():

	# Biases teleport distance toward closer positions
	var distance = lerp(
		min_distance,
		max_distance,
		randf() * randf()
	)


	var direction = -player_camera.global_transform.basis.z


	var target_position = (
		player_camera.global_position
		+ direction * distance
	)


	# Small randomness while keeping it near the viewing angle
	var offset = Vector3(
		randf_range(-0.75, 0.75),
		randf_range(-0.5, 1.0),
		randf_range(-0.75, 0.75)
	)


	global_position = target_position + offset



func player_is_looking() -> bool:

	var direction = (
		global_position - player_camera.global_position
	).normalized()


	var camera_direction = (
		-player_camera.global_transform.basis.z
	)


	var angle = rad_to_deg(
		acos(
			clamp(
				camera_direction.dot(direction),
				-1.0,
				1.0
			)
		)
	)


	return angle <= view_angle



func kill_player():

	print("dead")

	dead = true


	var black = death_screen.get_node("Control/ColorRect")
	var label = death_screen.get_node("Control/Label")


	label.text = death_message


	var tween = create_tween()


	tween.tween_property(
		black,
		"modulate:a",
		1.0,
		1.0
	)


	tween.parallel().tween_property(
		label,
		"modulate:a",
		1.0,
		1.0
	)


	await tween.finished


	get_tree().paused = true
