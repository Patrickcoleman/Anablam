extends Area2D
class_name Bullet

var speed: float = 600.0
#var owner_peer_id: int = -1

const SPRITES: Array[CompressedTexture2D] = [
	preload("res://objects/bullets/bulletGreenSilver_outline.png"),
	preload("res://objects/bullets/bulletRedSilver_outline.png"),
	preload("res://objects/bullets/bulletSilverSilver_outline.png"),
	preload("res://objects/bullets/bulletBlueSilver_outline.png"),
	preload("res://objects/bullets/bulletBeigeSilver_outline.png"),
]

func _physics_process(delta: float) -> void:
	position += Vector2.DOWN.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if !multiplayer.is_server(): return
	#if body is Player && body.peer_id == owner_peer_id:
		#return
	
	queue_free()
