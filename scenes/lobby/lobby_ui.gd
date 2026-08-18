extends CanvasLayer

var lobby: Lobby

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lobby = get_parent()
	lobby.player_data_changed.connect(_on_player_data_changed)
	redraw_players()
	redraw_votes()

func redraw_players():
	var labels = $HBox/PlayerList.get_children()
	var player_data = lobby.player_data
	var player_ids = player_data.keys()
	for i in 5:
		if i < player_ids.size():
			labels[i].text = player_data[player_ids[i]]["display_name"]
		else:
			labels[i].text = "Empty"

func vote_start():
	lobby.request_vote.rpc_id(1)

func redraw_votes():
	var player_data = lobby.player_data
	$HBox/VBox/Label.text = "%d/%d votes" % [count_votes(player_data), max(player_data.size(), 2)]

func count_votes(player_data) -> int:
	var votes = 0
	for player in player_data:
		if player_data[player]["voted"]:
			votes += 1
	return votes

func _on_player_data_changed():
	redraw_players()
	redraw_votes()

func exit_to_menu():
	if multiplayer.is_server():
		lobby.close_server()
	else:
		lobby.leave_server()
