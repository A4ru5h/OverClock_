class_name RouletteWheel
extends Node3D
## Spins, and also racks up money the whole time it's active.


@export var spin_speed: float = 1.0        # radians per second
@export var spin_axis: Vector3 = Vector3.RIGHT

@export var money_per_second: float = 10.0
var money: float = 0.0


func _process(delta: float) -> void:
	rotate(spin_axis.normalized(), spin_speed * delta)
	$Control/RichTextLabel.text = "[wave] $" + str(round(money))
	money += money_per_second * delta
