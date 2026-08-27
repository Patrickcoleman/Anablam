extends CanvasLayer

@onready var lobby = get_node("/root/Lobby")


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_escape"):
		_try_toggle()


func _try_toggle() -> void:
	if visible:
		visible = false
	elif lobby.game_state == lobby.GameState.IN_GAME:
		visible = true
