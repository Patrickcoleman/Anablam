extends Node2D
class_name Lobby

const MAX_PLAYERS: int = 5
const DEFAULT_PORT: int = 34777

var headless_mode: bool = (DisplayServer.get_name() == "headless")

const PLAYER_SCN: PackedScene = preload("res://objects/player/player.tscn")
var available_characters: Array[int] = []

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
	
	if (headless_mode):
		start_enet_server()

# Network

func _start_server_common() -> void:
	if (!headless_mode):
		load_level() # start the first level
		spawn_player(1) # server always has ID 1

func start_enet_server(port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	_start_server_common()

func start_enet_client(address: String, port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer

# Network Events

#This signal is emitted with the newly connected peer's ID on each other peer, 
# and on the new peer multiple times, once with each other peer's ID.
func _on_peer_connected(peer_id: int) -> void:
	# Handle player spawn if hosting
	if (!multiplayer.is_server()): return
	
	if (level == null):
		load_level()
		
	spawn_player(peer_id)

#This signal is emitted on every remaining peer when one disconnects.
func _on_peer_disconnected(peer_id: int) -> void:
	# Handle player removal if hosting
	if (!multiplayer.is_server()): return
	
	if (get_player_count() == 1):
		unload_level()
	
	remove_player(peer_id)

func _on_connected_to_server() -> void:
	pass

func _on_connection_failed() -> void:
	pass

func _on_server_disconnected() -> void:
	pass

var level: Level = null
var level_idx: int = -1

# ...

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
	if (level != null): level.queue_free()
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
	# Prepare new player
	var player: Player = PLAYER_SCN.instantiate()
	player.name = str(peer_id)
	player.character = available_characters.pop_front()
	
	# Add player to level and teleport to spawn position
	var best_spawn_location: Vector2 = get_furthest_spawn()
	$Players.add_child(player)
	player.teleport.rpc(best_spawn_location)

func get_furthest_spawn() -> Vector2:
	var potential_spawns: Array[Vector2] = level.get_spawn_positions()
	var players: Array[Node] = $Players.get_children()
	if players.is_empty():
		return potential_spawns.pick_random()
	else:
		var spawn_distances: Array[float] = []
		var player_locations: Array[Vector2] = []
		for player in players:
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

func remove_player(peer_id: int) -> void:
	# Find player node
	var player: Player = get_player(peer_id)
	if (player == null): return
	
	# Return character back to available list
	available_characters.append(player.character)
	
	# Free player
	player.queue_free()
