extends CanvasLayer

var ui_letter_scene = preload("uid://c8rmqaulnjc1w")

var collect_tween_duration: float = 0.7


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func add_letter(letter: String, world_location: Vector2) -> void:
	var spawn_location = convert_world_to_container_location(world_location, $CollectedLetters)
	var new_location: Vector2 = get_random_point_in_container($CollectedLetters)
	var new_letter: Control = ui_letter_scene.instantiate()
	$CollectedLetters.add_child(new_letter)
	new_letter.position = spawn_location

	var label: Label = new_letter.get_node("LetterLabel")
	label.text = letter

	var tween := create_tween()
	tween.tween_property(new_letter, "position", new_location, collect_tween_duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.finished.connect(on_letter_arrived.bind(new_letter))


func on_letter_arrived(new_letter: Control):
	$CollectedLetters.add_letter(new_letter)


func convert_world_to_container_location(world_location: Vector2, container: Control) -> Vector2:
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * world_location
	var local_pos: Vector2 = container.get_global_transform_with_canvas().affine_inverse() * screen_pos
	return local_pos


func get_random_point_in_container(container: Control) -> Vector2:
	return Vector2(randf_range(0.0, container.size.x), randf_range(0.0, container.size.y))
