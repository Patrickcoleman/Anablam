@tool
extends Node2D
class_name Level

@export var display_name: String = ""

# Public Helpers


func get_spawn_positions() -> Array[Node]:
	return $SpawnPoints.get_children()


func get_arena_bounds() -> Rect2:
	var left: float = $Background/Borders/WallLeft.position.x
	var right: float = $Background/Borders/WallRight.position.x
	var top: float = $Background/Borders/WallTop.position.y
	var bottom: float = $Background/Borders/WallBottom.position.y
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))
