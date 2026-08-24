extends Node2D

@onready var cooldown_circle: TextureProgressBar = $CooldownCircle

var cooldown_time: float = 4.0
var cooldown_remaining: float = 0.0


func _ready() -> void:
	pass


func start_cooldown() -> void:
	cooldown_remaining = cooldown_time


func _process(delta: float) -> void:
	position = get_global_mouse_position()
	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta
		cooldown_circle.value = 100 - 100 * cooldown_remaining / cooldown_time
