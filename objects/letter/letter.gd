extends Node2D
class_name Letter

var letters: Array[String] = [
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
]

var letter: String = "":
	set(value):
		$LetterLabel.text = value
		letter = value


func randomise():
	letter = letters.pick_random()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if multiplayer.is_server():
		if body.local:
			body.collect_letter(letter, global_position)
		else:
			body.collect_letter.rpc_id(int(body.name), letter, global_position)
		queue_free()
