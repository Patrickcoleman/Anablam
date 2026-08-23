@tool
extends Node2D
class_name Level

@export var display_name: String = "Untitled Level"

# Public Helpers


func get_spawn_positions() -> Array[Vector2]:
	var spawn_positions: Array[Vector2] = []
	var spawns = $SpawnPoints.get_children()
	for child in spawns:
		spawn_positions.append(child.global_position)
	return spawn_positions
