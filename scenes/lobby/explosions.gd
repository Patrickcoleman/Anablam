extends Node2D
var explosion_scene: PackedScene = preload("res://objects/bullets/explosions/Explosion.tscn")
var scorchmark_scene: PackedScene = preload("res://objects/scene/scorchmark.tscn")

@onready var lobby: Lobby = get_node("/root/Lobby")

enum EFFECT_TYPE {
	EXPLOSION,
	SCORCHMARK,
}


@rpc("any_peer", "call_local", "unreliable")
func spawn_effect(effect_type: EFFECT_TYPE, effect_position: Vector2, effect_scale: float) -> void:
	if lobby.game_state != lobby.GameState.IN_GAME:
		return

	var scene: PackedScene
	match effect_type:
		EFFECT_TYPE.EXPLOSION:
			scene = explosion_scene
		EFFECT_TYPE.SCORCHMARK:
			scene = scorchmark_scene

	var effect: Node2D = scene.instantiate()
	effect.global_position = effect_position
	effect.scale = Vector2.ONE * effect_scale
	add_child(effect)
