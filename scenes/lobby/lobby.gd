extends Node2D
class_name Lobby

const MAX_PLAYERS: int = 5
const DEFAULT_PORT: int = 34777

var headless_mode: bool = (DisplayServer.get_name() == "headless")

const PLAYER_SCN: PackedScene = preload("res://objects/player/player.tscn")
var available_characters: Array[int] = []
var display_name: String = "Player"
var player_data: Dictionary = { }
signal player_data_changed

var kills_to_win: int = 5

# Lifecycle


func _ready() -> void:
	# Listen to multiplayer signals
	# The following emit on both clients and servers
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	# The rest only emit for clients
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Prepare available character indices
	for idx: int in Player.CHARACTERS.size():
		available_characters.append(idx)

	update_game_state(GameState.MAIN_MENU)

	if (headless_mode):
		start_enet_server()

# Network


func start_enet_server(port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	if !headless_mode:
		player_data[1] = make_default_player_entry()
		player_data[1]["display_name"] = display_name
	share_player_info.rpc(player_data)
	open_lobby()


func start_enet_client(address: String, port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer

# Network Events


#This signal is emitted with the newly connected peer's ID on each other peer,
# and on the new peer multiple times, once with each other peer's ID.
func _on_peer_connected(peer_id: int) -> void:
	# Handle player spawn if hosting
	if (!multiplayer.is_server()):
		return

	player_data[peer_id] = make_default_player_entry()

	if (game_state == GameState.IN_GAME):
		spawn_player(peer_id)

	share_player_info.rpc(player_data)


func make_default_player_entry() -> Dictionary:
	return { "display_name": "Loading...", "voted": false, "sprite_id": 0, "kills": 0 }


@rpc("authority", "call_local", "reliable")
func share_player_info(new_player_data):
	player_data = new_player_data
	player_data_changed.emit()


#This signal is emitted on every remaining peer when one disconnects.
func _on_peer_disconnected(peer_id: int) -> void:
	if (!multiplayer.is_server()):
		return

	remove_player(peer_id)
	player_data.erase(peer_id)
	share_player_info.rpc(player_data)

	if (get_player_count() == 0):
		unload_level()


func _on_connected_to_server() -> void:
	submit_display_name.rpc_id(1, display_name)
	pass


func _on_connection_failed() -> void:
	pass


func _on_server_disconnected() -> void:
	pass


func leave_server() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	game_state = GameState.MAIN_MENU


@rpc("authority", "call_local", "reliable")
func notify_server_closing() -> void:
	if !multiplayer.is_server():
		leave_server()


func close_server() -> void:
	if !multiplayer.is_server():
		return
	notify_server_closing.rpc()
	leave_server()


var level: Level = null
var level_idx: int = -1

# Game State Management

enum GameState {
	MAIN_MENU,
	LOBBY,
	IN_GAME,
	GAME_OVER,
}

var game_state: GameState = GameState.MAIN_MENU:
	set(value):
		game_state = value
		_on_game_state_changed(value)


func _on_game_state_changed(new_state: GameState) -> void:
	$UI.hide()
	$LobbyUI.hide()
	$Scoreboard.hide()
	$Scoreboard/PlayerBoxes.hide()
	$Scoreboard/GameOver.hide()

	match new_state:
		GameState.MAIN_MENU:
			$UI.show()
		GameState.LOBBY:
			$LobbyUI.show()
		GameState.IN_GAME:
			$Scoreboard.draw_scoreboard()
			$Scoreboard.show()
			$Scoreboard/PlayerBoxes.show()
		GameState.GAME_OVER:
			$Scoreboard.show()
			$Scoreboard/GameOver.show()
			$Scoreboard.draw_game_over()


func update_game_state(new_state: GameState) -> void:
	game_state = new_state
	return


func open_lobby():
	reset_votes()
	update_game_state(GameState.LOBBY)


func start_new_game() -> void:
	if !multiplayer.is_server():
		return
	load_level() # start the first level
	spawn_all_players()
	reset_kills()
	update_game_state(GameState.IN_GAME)
	return


func end_game() -> void:
	if !multiplayer.is_server():
		return
	unload_level()
	update_game_state(GameState.GAME_OVER)
	remove_all_players()
	$GameOverTimer.start()
	return


func gameover_screen_timeout() -> void:
	if !multiplayer.is_server():
		return
	open_lobby()

# player_data updaters


@rpc("any_peer", "call_remote", "reliable")
func submit_display_name(name_value: String) -> void:
	if multiplayer.is_server():
		player_data[multiplayer.get_remote_sender_id()]["display_name"] = name_value
		share_player_info.rpc(player_data)


func add_kill(player_id: int):
	if multiplayer.is_server():
		player_data[player_id]["kills"] += 1
		share_player_info.rpc(player_data)
		if is_game_over():
			end_game()


func is_game_over() -> bool:
	for player in player_data:
		if player_data[player]["kills"] >= kills_to_win:
			return true
	return false


func reset_kills():
	for player in player_data:
		player_data[player]["kills"] = 0
	share_player_info.rpc(player_data)


@rpc("any_peer", "call_local", "reliable")
func request_vote():
	if multiplayer.is_server():
		player_data[multiplayer.get_remote_sender_id()]["voted"] = true
		share_player_info.rpc(player_data)
		if all_players_voted():
			start_new_game()


func reset_votes():
	for player in player_data:
		player_data[player]["voted"] = false
	share_player_info.rpc(player_data)


#returns true if all players have voted
func all_players_voted() -> bool:
	if player_data.size() <= 1:
		return false
	for player in player_data:
		if !player_data[player]["voted"]:
			return false
	return true

# Level Management


func load_level() -> void:
	# Get level path
	var level_spawner: MultiplayerSpawner = $LevelSpawner
	var level_path: String = level_spawner.get_spawnable_scene(0)

	# Load new level
	var level_scn: PackedScene = load(level_path)
	level = level_scn.instantiate()
	$Level.add_child.call_deferred(level, true)


func unload_level() -> void:
	if (level != null):
		level.queue_free()
	level = null


func get_player(peer_id: int) -> Player:
	for child: Node in $Players.get_children():
		if (child is Player && child.peer_id == peer_id):
			return child
	return null


func get_players() -> Array[Player]:
	var players: Array[Player] = []
	for child: Node in $Players.get_children():
		if (child is Player):
			players.append(child)
	return players


func get_player_count() -> int:
	var count: int = 0
	for child: Node in $Players.get_children():
		if (child is Player):
			count += 1
	return count


func spawn_player(peer_id: int) -> void:
	var player: Player = PLAYER_SCN.instantiate()
	player.name = str(peer_id)

	var random_index: int = randi_range(0, available_characters.size() - 1)
	player_data[peer_id]["sprite_id"] = available_characters[random_index]
	available_characters.remove_at(random_index)
	share_player_info.rpc(player_data)

	$Players.add_child(player)

	player.teleport.rpc(get_furthest_spawn(player))


func remove_player(peer_id: int) -> void:
	var player: Player = get_player(peer_id)
	if (player == null):
		return
	if player_data.has(peer_id):
		var sprite_id = player_data[peer_id]["sprite_id"]
		if sprite_id != null:
			available_characters.append(sprite_id)

	player.queue_free()


func spawn_all_players() -> void:
	if !multiplayer.is_server():
		return
	for player in player_data:
		spawn_player(player)


func remove_all_players() -> void:
	if !multiplayer.is_server():
		return
	for player: Player in get_players():
		player.prepare_for_despawn.rpc()
		player.set_hidden.rpc(true)
	await get_tree().create_timer(0.5).timeout

	for player: Player in get_players():
		remove_player(player.peer_id)


func respawn_player(peer_id: int) -> void:
	var player: Player = get_player(peer_id)
	if player == null:
		return
	var spawn_pos: Vector2 = get_furthest_spawn(player)
	player.revive.rpc(spawn_pos)


func get_furthest_spawn(excluded_player: Player) -> Vector2:
	var potential_spawns: Array[Vector2] = level.get_spawn_positions()
	var players: Array[Node] = $Players.get_children()
	if players.is_empty():
		return potential_spawns.pick_random()
	else:
		var spawn_distances: Array[float] = []
		var player_locations: Array[Vector2] = []
		for player in players:
			if player != excluded_player:
				player_locations.append(player.global_position)
		for spawn in potential_spawns:
			var nearest = INF
			for location in player_locations:
				var distance: float = spawn.distance_to(location)
				nearest = min(distance, nearest)
			spawn_distances.append(nearest)

		var best_spawn_index: int = 0
		var best_spawn_distance: float = spawn_distances[0]

		for i in spawn_distances.size():
			if spawn_distances[i] > best_spawn_distance:
				best_spawn_distance = spawn_distances[i]
				best_spawn_index = i

		var best_spawn: Vector2 = potential_spawns[best_spawn_index]
		return best_spawn
