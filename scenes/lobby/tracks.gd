extends Node2D

var tracks: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tracks = preload("res://objects/scene/track.tscn")
	pass # Replace with function body.


func spawn_track(tank_position, tank_location) -> void:
	var track: Sprite2D = tracks.instantiate()
	track.global_position = tank_position
	track.rotation = tank_location
	add_child(track)
