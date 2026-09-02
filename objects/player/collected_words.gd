extends VBoxContainer
class_name Collected_words

var word_h_box_prefab: PackedScene = preload("uid://bvdfuyrx1pcah")
var word_letter_label_prefab: PackedScene = preload("uid://d0ykplrahkjg4")
@onready var container: Control = get_parent().get_parent()


func create_new_word(letters: String) -> Array[Label]:
	container.show()
	var new_row: HBoxContainer = word_h_box_prefab.instantiate()
	add_child(new_row)
	var new_letters: Array[Label] = []
	for letter in letters:
		var new_letter: Label = word_letter_label_prefab.instantiate()
		new_letter.text = letter
		new_letter.modulate.a = 0.0
		new_row.add_child(new_letter)
		new_letters.append(new_letter)

	await get_tree().process_frame

	return new_letters
