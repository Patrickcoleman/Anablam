extends PanelContainer


# EnemyPanel.gd
@onready var kill_label: Label = $Margins/VBox/HBox/KillCount
@onready var name_label: Label = $Margins/VBox/DisplayName
@onready var player_sprite: TextureRect = $Margins/VBox/Sprite

func set_info(display_name: String, kill_count: int, sprite: CompressedTexture2D) -> void:
	name_label.text = display_name
	kill_label.text = str(kill_count)
	player_sprite.texture = sprite


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
