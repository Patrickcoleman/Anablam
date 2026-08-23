extends Node2D
var explosion_scene: PackedScene = preload("res://objects/bullets/explosions/Explosion.tscn")
var scorchmark_scene: PackedScene = preload("res://objects/scene/scorchmark.tscn")


@rpc("any_peer", "call_local", "unreliable")
func spawn_explosion(explosion_position: Vector2, explosion_scale: float) -> void:
	var explosion: Node2D = explosion_scene.instantiate()
	explosion.global_position = explosion_position
	explosion.scale = Vector2.ONE * explosion_scale
	add_child(explosion)


@rpc("any_peer", "call_local", "unreliable")
func spawn_scorchmark(scorchmark_position: Vector2, scorchmark_scale: float):
	var scorchmark: Node2D = scorchmark_scene.instantiate()
	scorchmark.position = scorchmark_position
	scorchmark.scale = Vector2.ONE * scorchmark_scale
	add_child(scorchmark)
