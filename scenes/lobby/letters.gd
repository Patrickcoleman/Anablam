extends Node2D

@onready var lobby: Lobby = get_parent()
@onready var letter_timer: Timer = $LetterTimer
@onready var letter_scene: PackedScene = load(lobby.get_node("LetterSpawner").get_spawnable_scene(0))
@onready var letter_spawner: MultiplayerSpawner = lobby.get_node("LetterSpawner")
var arena_bounds: Rect2
var spawn_time: float = 1.0
var letter_radius: int = 17
var max_attempts: int = 30


func _ready() -> void:
	letter_spawner.spawn_function = _create_letter


func begin_spawning():
	if !multiplayer.is_server():
		return
	arena_bounds = lobby.level.get_arena_bounds()
	letter_timer.start()


func _on_letter_timer_timeout() -> void:
	spawn_letter()


func spawn_letter():
	if letter_spawner.get_child_count() < 100:
		var new_position: Vector2 = find_spawn_position()
		letter_spawner.spawn({ "position": new_position })


func _create_letter(data: Dictionary) -> Letter:
	var letter: Letter = letter_scene.instantiate()
	letter.randomise()
	letter.global_position = data["position"]
	return letter


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
