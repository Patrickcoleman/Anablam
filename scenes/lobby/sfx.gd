extends Node2D

@export var bullet_explosion_sfx: SFXData
@export var tank_explosion_sfx: SFXData
@export var fire_sfx: SFXData
@export var huh_sfx: SFXData

@onready var sounds: Array[SFXData] = [bullet_explosion_sfx, tank_explosion_sfx, fire_sfx, huh_sfx]

enum SFX_TYPE {
	BULLET_EXPLOSION,
	TANK_EXPLOSION,
	FIRE,
	HUH,
}


@rpc("any_peer", "call_local", "unreliable")
func play_sfx(sound: SFX_TYPE, sfx_position: Vector2) -> void:
	var data: SFXData = sounds[sound]
	var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	player.stream = data.stream
	player.global_position = sfx_position
	player.volume_db = data.volume_db
	player.pitch_scale = data.pitch_scale + randf_range(
		-data.pitch_random_range,
		data.pitch_random_range,
	)
	player.bus = "SFX"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
