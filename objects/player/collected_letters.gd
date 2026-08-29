extends Panel

var tween_duration: float = 0.1
var tween_repeats: int = 9
var tween_repeats_remaining: int = 9
var letters: Array[Control] = []
@export var max_push_distance: float = 100
@export var max_push_strength: float = 20.0
@export var force: float = 1
var active_tweens: Array[Tween] = []
@onready var bounds: Rect2 = Rect2(Vector2.ZERO, size)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TweenTimer.wait_time = tween_duration


func add_letter(new_letter: Control) -> void:
	letters.append(new_letter)
	trigger_repeating_tweens()


func remove_letter(letter: Control) -> void:
	letters.erase(letter)
	trigger_repeating_tweens()


func trigger_repeating_tweens():
	tween_repeats_remaining = tween_repeats
	start_tweens()
	$TweenTimer.start()


func start_tweens():
	var destinations := get_destinations()
	for i in letters.size():
		var tween := create_tween()
		tween.tween_property(letters[i], "position", destinations[i], tween_duration) \
				.set_trans(Tween.TRANS_CUBIC)
		active_tweens.append(tween)


func _cancel_active_tweens() -> void:
	for tween in active_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	active_tweens.clear()


func get_push_from_neighbour(pushed: Vector2, pusher: Vector2) -> Vector2:
	var diff: Vector2 = pushed - pusher
	if diff.length_squared() < 0.0001:
		diff = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	var dist: float = diff.length()
	var push_force: float = clamp(max_push_distance / sqrt(dist) - 10, 0, max_push_strength)
	var push: Vector2 = diff.normalized() * push_force * force
	return push


func get_destinations() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for l in letters:
		points.append(l.position)

	var letter_count: int = letters.size()
	var destinations: Array[Vector2] = points.duplicate()
	var current_bounds := get_bounds()

	for i in letter_count:
		for j in letter_count:
			if i == j:
				continue
			destinations[i] += get_push_from_neighbour(points[i], points[j])

	for i in letter_count:
		destinations[i] += get_push_from_neighbour(
			points[i],
			Vector2(current_bounds.position.x, points[i].y),
		)
		destinations[i] += get_push_from_neighbour(
			points[i],
			Vector2(current_bounds.end.x, points[i].y),
		)
		destinations[i] += get_push_from_neighbour(
			points[i],
			Vector2(points[i].x, current_bounds.position.y),
		)
		destinations[i] += get_push_from_neighbour(
			points[i],
			Vector2(points[i].x, current_bounds.end.y),
		)

		destinations[i].x = clamp(destinations[i].x, bounds.position.x, bounds.end.x)
		destinations[i].y = clamp(destinations[i].y, bounds.position.y, bounds.end.y)

	return destinations


func _on_tween_timer_timeout() -> void:
	if tween_repeats_remaining > 0:
		start_tweens()
		tween_repeats_remaining -= 1
		$TweenTimer.start()


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, size)
