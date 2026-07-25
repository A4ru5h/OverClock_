extends Node

@export var shocks : int = 6
@onready var shocks_available_text: RichTextLabel = $"../../Control/ShocksAvailableText"

func _process(delta: float) -> void:
	shocks_available_text.text = "[wave] Available Shocks: " + str(shocks)
	
func decrement_shocks() -> void:
	shocks -= 1
	

func increment_shocks() -> void:
	shocks += 1

func shocks_available() -> bool:
	return shocks >= 1
	

func _on_player_execute_shock() -> void:
	
	decrement_shocks() # Replace with function body.
