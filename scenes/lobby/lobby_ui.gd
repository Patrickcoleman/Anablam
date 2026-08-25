extends CanvasLayer

var lobby: Lobby
const LOBBY_PLAYER: PackedScene = preload("uid://yktpdnchrv1n")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lobby = get_parent()
	lobby.player_data_changed.connect(_on_player_data_changed)
	redraw_players()
	redraw_votes()


func redraw_players():
	var player_data = lobby.player_data
	var player_ids = player_data.keys()
	var label_container: VBoxContainer = $Players/PlayerList
	for child in label_container.get_children():
		child.queue_free()
	for i in lobby.MAX_PLAYERS:
		var new_label = LOBBY_PLAYER.instantiate()
		label_container.add_child(new_label)
		if i < player_ids.size():
			var name_label: Label = new_label.get_node("NameLabel")
			name_label.text = player_data[player_ids[i]]["display_name"]
			var checkbox: CheckBox = new_label.get_node("CheckBox")
			checkbox.visible = true
			checkbox.button_pressed = player_data[player_ids[i]]["voted"]
			if player_data[player_ids[i]]["winner"]:
				new_label.get_node("Crown").visible = true


func vote_start():
	lobby.request_vote.rpc_id(1)


func redraw_votes():
	var player_data = lobby.player_data
	$Players/VBox/VotingOptions/Votes.text = "%d/%d votes" % [
		count_votes(player_data),
		max(player_data.size(), 2),
	]


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
