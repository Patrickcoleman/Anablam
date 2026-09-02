extends Panel
class_name Collected_letters

@onready var letters: Letters = get_node("/root/Lobby/Letters")

var tween_duration: float = 0.1
var tween_repeats: int = 9
var tween_repeats_remaining: int = 9
var ui_letters: Array[Control] = []
var letters_collected: Array[String] = []
@export var max_push_distance: float = 100
@export var max_push_strength: float = 20.0
@export var force: float = 1
var active_tweens: Array[Tween] = []
@onready var bounds: Rect2 = Rect2(Vector2.ZERO, size)

signal letters_collected_changed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TweenTimer.wait_time = tween_duration


func add_letter(new_letter: Control) -> void:
	ui_letters.append(new_letter)
	letters_collected.append(new_letter.get_child(0).text)
	trigger_repeating_tweens()
	letters_collected_changed.emit()


func remove_letter(old_letter: Control) -> void:
	ui_letters.erase(old_letter)
	letters_collected.erase(old_letter.get_node("LetterLabel").text)
	trigger_repeating_tweens()
	letters_collected_changed.emit()


func send_letters_away(new_letters: Array[Label]):
	var sent_letters: Array[Control] = []
	for letter in new_letters:
		var found = false
		for ui_letter in ui_letters:
			if ui_letter in sent_letters:
				continue
			if ui_letter.get_node("LetterLabel").text == letter.text:
				found = true
				var tween := create_tween()
				tween.tween_property(ui_letter, "global_position", letter.global_position
				+ letter.size / 2.0, 1) \
						.set_trans(Tween.TRANS_CUBIC)
				tween.finished.connect(make_element_visisble_and_disappear.bind(letter, ui_letter))
				sent_letters.append(ui_letter)
				break
		if not found:
			push_error("sent letter not matched with collected letters!")
	for ui_letter in sent_letters:
		remove_letter(ui_letter)

	return


func make_element_visisble_and_disappear(element: Label, moving_letter: Control):
	element.modulate.a = 1.0
	moving_letter.queue_free()


func remove_letter_from_characters(old_characters: String):
	for character in old_characters:
		remove_letter_from_character(character)


func remove_letter_from_character(old_character: String):
	var found: bool = false
	for ui_letter: Control in ui_letters:
		if ui_letter.get_node("LetterLabel").text == old_character:
			remove_letter(ui_letter)
			found = true
			break
	if not found:
		push_error("Tried to remove a letter I didn't have! letter: '%s'" % old_character)


func trigger_repeating_tweens():
	tween_repeats_remaining = tween_repeats
	start_tweens()
	$TweenTimer.start()


func start_tweens():
	var destinations := get_destinations()
	for i in ui_letters.size():
		var tween := create_tween()
		tween.tween_property(ui_letters[i], "position", destinations[i], tween_duration) \
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
	for l in ui_letters:
		points.append(l.position)

	var letter_count: int = ui_letters.size()
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


func get_available_letters_dict() -> Dictionary:
	var letter_dict: Dictionary = { }
	for letter in letters.letter_weights:
		letter_dict[letter] = 0
	for letter in letters_collected:
		letter_dict[letter] += 1
	return letter_dict
