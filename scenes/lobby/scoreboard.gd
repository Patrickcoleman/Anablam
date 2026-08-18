extends CanvasLayer

const PLAYER_DISPLAY: PackedScene = preload("res://common/ui/EnemyPanel.tscn")
const PLAYER_SPRITES: Array[Texture2D] = [
	preload("res://common/ui/player_icons/Green_Icon.png"),
	preload("res://common/ui/player_icons/Red_Icon.png"),
	preload("res://common/ui/player_icons/Black_Icon.png"),
	preload("res://common/ui/player_icons/Blue_Icon.png"),
	preload("res://common/ui/player_icons/Beige_Icon.png"),
]

var lobby: Lobby


func _ready() -> void:
	lobby = get_parent()
	lobby.player_data_changed.connect(_on_player_data_changed)


func _on_player_data_changed():
	draw_scoreboard()


func draw_scoreboard():
	draw_scores_in_element($PlayerBoxes)


func draw_game_over() -> void:
	draw_scores_in_element($GameOver/PlayerBoxes)


func draw_scores_in_element(parent: HBoxContainer) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

	var player_data = lobby.player_data
	var player_ids: Array = player_data.keys()

	player_ids.sort_custom(
		func(a, b):
			return player_data[a]["kills"] < player_data[b]["kills"],
	)
	for player_id in player_ids:
		var player_dict = player_data[player_id]
		if player_dict["kills"] == 0:
			continue
		var new_player_card = PLAYER_DISPLAY.instantiate()
		parent.add_child(new_player_card)
		new_player_card.set_info(
			player_dict["display_name"],
			player_dict["kills"],
			PLAYER_SPRITES[player_dict["sprite_id"]],
		)
