extends WorldEnvironment


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var env = WorldEnvironment
	env.volumetric_fog_density =  abs(cos(Time.get_ticks_msec()))
	
	
	
	
