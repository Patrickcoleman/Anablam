extends Node2D
class_name Letter

var letter: String = "":
	set(value):
		$LetterLabel.text = value
		letter = value


func _on_area_2d_body_entered(body: Node2D) -> void:
	if multiplayer.is_server():
		if body.local:
			body.collect_letter(letter, global_position)
		else:
			body.collect_letter.rpc_id(int(body.name), letter, global_position)
		queue_free()
