class_name LetterColorHighlighter
extends SyntaxHighlighter

var letter_dict: Dictionary = { }


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var result := { }
	var letter_dict_copy: Dictionary = letter_dict.duplicate()
	var line_text: String = get_text_edit().get_line(line)
	for col in line_text.length():
		var character: String = line_text[col]
		var present: bool = false
		if character in letter_dict_copy.keys():
			if letter_dict_copy[character] > 0:
				present = true
				letter_dict_copy[character] -= 1
		var color: Color = Color.WHITE if present else Color.RED
		result[col] = { "color": color }
	return result
