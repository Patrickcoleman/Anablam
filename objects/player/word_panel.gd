extends PanelContainer

@onready var lobby: Lobby = get_node("/root/Lobby")
@onready var sfx = get_node("/root/Lobby/SFX")
@onready var ui_word_prefab = preload("uid://d0ykplrahkjg4")
@onready var collected_letters: Collected_letters = $"../CollectedLetters"
@onready var collected_words: Collected_words = $"../Words/Margins/CollectedWords"
@onready var word_data: Dictionary = JSON.parse_string(
	FileAccess.open("res://assets/data/curated_word_frequency.json", FileAccess.READ).get_as_text()
)

@onready var syntax_highlighter = LetterColorHighlighter.new()
var letters_valid: bool = false


func _ready() -> void:
	$WordEntry.syntax_highlighter = syntax_highlighter
	collected_letters.letters_collected_changed.connect(collected_letters_changed)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_entry"):
		_try_toggle()


func _try_toggle() -> void:
	$WordEntry.text = ""
	if visible:
		visible = false
		release_focus()
	elif lobby.game_state == lobby.GameState.IN_GAME:
		visible = true
		$WordEntry.grab_focus()


func _on_word_entry_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			get_viewport().set_input_as_handled()
			_try_toggle()
		elif event.keycode == KEY_ENTER:
			get_viewport().set_input_as_handled()
			_submit_word()


func _submit_word():
	var submitted_text = $WordEntry.text
	if !check_letters_valid(submitted_text):
		print("invalid letters")
		play_wiggle_no(self)
	elif submitted_text not in word_data:
		sfx.play_sfx.rpc(sfx.SFX_TYPE.HUH, global_position)
		print("not word!")
	else:
		submit_valid_word(submitted_text, word_data[submitted_text])
		_try_toggle()


func submit_valid_word(word: String, rarity: float):
	print("word! rarity: %f" % (rarity))
	var new_letters: Array[Label] = await collected_words.create_new_word(word)
	collected_letters.send_letters_away(new_letters)
	#tell lobby about it
	return


func play_wiggle_no(panel: Control) -> void:
	var original_pos: Vector2 = panel.position
	var tween := create_tween()

	var offsets: Array[float] = [4, -3, 2, -1, 0]
	var step_duration: float = 0.04

	for offset in offsets:
		tween.tween_property(panel, "position:x", original_pos.x + offset, step_duration) \
				.set_trans(Tween.TRANS_SINE)


func collected_letters_changed():
	var collected_letter_dict: Dictionary = collected_letters.get_available_letters_dict()
	syntax_highlighter.letter_dict = collected_letter_dict


func check_letters_valid(input: String) -> bool:
	var collected_letter_dict = collected_letters.get_available_letters_dict()
	var result = true
	for character in input:
		if character in collected_letter_dict.keys():
			if collected_letter_dict[character] > 0:
				collected_letter_dict[character] -= 1
			else:
				result = false
		else:
			result = false
	return result
