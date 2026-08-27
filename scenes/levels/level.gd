@tool
extends Node2D
class_name Level

@export var display_name: String = ""

# Public Helpers


func get_spawn_positions() -> Array[Node]:
	return $SpawnPoints.get_children()
