extends WorldEnvironment

func _process(delta: float) -> void:
	environment.volumetric_fog_density = abs(cos(Time.get_ticks_msec() / 2000.0))
