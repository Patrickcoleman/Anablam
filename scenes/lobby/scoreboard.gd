extends CanvasLayer

const PLAYER_DISPLAY: PackedScene = preload("res://common/ui/EnemyPanel.tscn")
const PLAYER_SPRITES: Array[Texture2D] = [
	preload("res://common/ui/player_icons/Green_Icon.png"),
	preload("res://common/ui/player_icons/Red_Icon.png"),
	preload("res://common/ui/player_icons/Black_Icon.png"),
	preload("res://common/ui/player_icons/Blue_Icon.png"),
	preload("res://common/ui/player_icons/Beige_Icon.png"),
	]
var player_scores: Dictionary = {
}
var kills_to_win: int = 3
var lobby: Lobby

func _ready() -> void:
	lobby = get_parent()

func reset_scores() -> void:
	if !multiplayer.is_server():
		return
	player_scores = {}
	share_scores.rpc(player_scores)

func update_scores(peer_id: int, display_name: String, kill_count: int, character: int) -> void:
	if !multiplayer.is_server():
		return
	if peer_id not in player_scores:
		player_scores[peer_id] = {
			"display_name" : display_name,
			"kill_count" : kill_count,
			"player_sprite_id" : character
		}
	else:
		player_scores[peer_id]["kill_count"] = kill_count
	
	share_scores.rpc(player_scores)
	
	if check_game_over():
		lobby.end_game()
	else:
		draw_scoreboard.rpc()

func remove_player(peer_id: int):
	player_scores.erase(peer_id)
	share_scores.rpc(player_scores)
	draw_scoreboard.rpc()

@rpc("authority", "call_local", "reliable")
func share_scores(new_player_scores : Dictionary) -> void:
	player_scores = new_player_scores

@rpc("authority", "call_local", "reliable")
func draw_scoreboard():
	draw_scores_in_element($PlayerBoxes)

func draw_game_over() -> void:
	draw_scores_in_element($GameOver/PlayerBoxes)
	
func draw_scores_in_element(parent: HBoxContainer) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	
	var player_ids: Array = player_scores.keys()
	player_ids.sort_custom(func(a, b): return player_scores[a]["kill_count"] < player_scores[b]["kill_count"])
	for player_id in player_ids:
		var player_dict = player_scores[player_id]
		var new_player_card = PLAYER_DISPLAY.instantiate()
		parent.add_child(new_player_card)
		new_player_card.set_info(player_dict["display_name"], player_dict["kill_count"], 
			PLAYER_SPRITES[player_dict["player_sprite_id"]])

func set_game_over_visible(visible_bool: bool) -> void:
	$GameOver.visible = visible_bool

func check_game_over() -> bool:
	for player in player_scores:
		if player_scores[player]["kill_count"] >= kills_to_win:
			return true
	return false
