extends CanvasLayer

const PLAYER_DISPLAY: PackedScene = preload("res://common/ui/EnemyPanel.tscn")
const PLAYER_SPRITES: Array[Texture2D] = [
	preload("res://common/ui/player_icons/Green_Icon.png"),
	preload("res://common/ui/player_icons/Red_Icon.png"),
	preload("res://common/ui/player_icons/Black_Icon.png"),
	preload("res://common/ui/player_icons/Blue_Icon.png"),
	preload("res://common/ui/player_icons/Beige_Icon.png"),
	]
var players: Dictionary = {}

@rpc("authority", "call_local", "reliable")
func update_row(peer_id: int, display_name: String, kill_count: int, character: int) -> void:
	var display: PanelContainer = players.get(peer_id)
	if display == null:
		display = PLAYER_DISPLAY.instantiate()
		$PlayerBoxes.add_child(display)
		players[peer_id] = display
	display.set_info(display_name, kill_count, PLAYER_SPRITES[character])
	

func remove_row(peer_id: int) -> void:
	if players.has(peer_id):
		players[peer_id].queue_free()
		players.erase(peer_id)
