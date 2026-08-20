extends Area2D
class_name Bullet

var speed: float = 400.0
var owner_peer_id: int = -1
var bounces_remaining: int = 1

const SPRITES: Array[Texture2D] = [
	preload("res://objects/bullets/bulletGreenSilver_outline.png"),
	preload("res://objects/bullets/bulletRedSilver_outline.png"),
	preload("res://objects/bullets/bulletSilverSilver_outline.png"),
	preload("res://objects/bullets/bulletBlueSilver_outline.png"),
	preload("res://objects/bullets/bulletBeigeSilver_outline.png"),
]


func _ready() -> void:
	if multiplayer.is_server():
		#I need to await 2 here until the other bodies are registered
		await get_tree().physics_frame
		await get_tree().physics_frame
		for body in get_overlapping_bodies():
			if body is Player:
				continue
			queue_free()
			return


func _physics_process(delta: float) -> void:
	var ray_right: RayCast2D = $RayCastRight
	var ray_left: RayCast2D = $RayCastRight
	var colliding_ray: RayCast2D

	if ray_right.is_colliding():
		colliding_ray = ray_right
	elif ray_left.is_colliding():
		colliding_ray = ray_left

	if colliding_ray:
		if bounces_remaining > 0:
			var normal: Vector2 = colliding_ray.get_collision_normal()
			var direction: Vector2 = Vector2.DOWN.rotated(rotation)
			var bounced: Vector2 = direction.bounce(normal)
			rotation = bounced.angle() - PI / 2
			bounces_remaining -= 1
			global_position = colliding_ray.get_collision_point() + bounced.normalized() * 8.0
		else:
			if multiplayer.is_server():
				queue_free()
			return

	position += Vector2.DOWN.rotated(rotation) * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if !multiplayer.is_server():
		return
	if body is Player:
		if body.peer_id == owner_peer_id and bounces_remaining == 1:
			return
		if body.peer_id != owner_peer_id:
			get_node("/root/Lobby").add_kill(owner_peer_id)
		body.kill.rpc()
		queue_free()
