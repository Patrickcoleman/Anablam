extends Node2D
class_name Letters

@onready var lobby: Lobby = get_parent()
@onready var letter_timer: Timer = $LetterTimer
@onready var letter_scene: PackedScene = load(lobby.get_node("LetterSpawner").get_spawnable_scene(0))
@onready var letter_spawner: MultiplayerSpawner = lobby.get_node("LetterSpawner")
var arena_bounds: Rect2
var spawn_time_per_player: float = 4.0
var letter_radius: int = 17
var max_attempts: int = 30

var letter_weights: Dictionary = {
	"e": 12,
	"a": 9,
	"i": 9,
	"o": 8,
	"n": 6,
	"r": 6,
	"t": 6,
	"l": 4,
	"s": 4,
	"u": 4,
	"d": 4,
	"g": 3,
	"b": 2,
	"c": 2,
	"m": 2,
	"p": 2,
	"f": 2,
	"h": 2,
	"v": 2,
	"w": 2,
	"y": 2,
	"k": 1,
	"j": 1,
	"x": 1,
	"q": 1,
	"z": 1,
}

var weighted_letters: Array[String] = []


func _ready() -> void:
	_build_weighted_pool()
	letter_spawner.spawn_function = _create_letter


func _build_weighted_pool() -> void:
	weighted_letters.clear()
	for letter in letter_weights:
		for i in letter_weights[letter]:
			weighted_letters.append(letter)


func get_random_weighted_letter() -> String:
	return weighted_letters.pick_random()


func begin_spawning():
	if !multiplayer.is_server():
		return
	arena_bounds = lobby.level.get_arena_bounds()
	letter_timer.start()


func _on_letter_timer_timeout() -> void:
	letter_timer.wait_time = spawn_time_per_player / lobby.get_player_count()
	spawn_letter()


func spawn_letter():
	if lobby.get_node("Letters").get_child_count() < 100:
		var new_position: Vector2 = find_spawn_position()
		letter_spawner.spawn({ "position": new_position })


func _create_letter(data: Dictionary) -> Letter:
	var new_letter: Letter = letter_scene.instantiate()
	new_letter.letter = get_random_weighted_letter()
	new_letter.global_position = data["position"]
	return new_letter


func find_spawn_position() -> Vector2:
	var space_state := get_world_2d().direct_space_state

	for attempt in max_attempts:
		var candidate := Vector2(
			randf_range(arena_bounds.position.x, arena_bounds.end.x),
			randf_range(arena_bounds.position.y, arena_bounds.end.y),
		)

		var query := PhysicsShapeQueryParameters2D.new()
		var shape := CircleShape2D.new()
		shape.radius = letter_radius
		query.shape = shape
		query.transform = Transform2D(0, candidate)
		query.collide_with_bodies = true
		query.collide_with_areas = true

		var results := space_state.intersect_shape(query, 1)
		if results.is_empty():
			return candidate

	push_warning("find_spawn_position: no free spot found after %d attempts" % max_attempts)
	return arena_bounds.get_center()
