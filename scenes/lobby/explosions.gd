extends Node2D
var explosion_scene: PackedScene = preload("res://objects/bullets/explosions/Explosion.tscn")


@rpc("authority", "call_local", "unreliable")
func spawn_explosion(explosion_position: Vector2, explosion_scale: float) -> void:
	var explosion: Node2D = explosion_scene.instantiate()
	explosion.global_position = explosion_position
	explosion.scale = Vector2.ONE * explosion_scale
	add_child(explosion)
