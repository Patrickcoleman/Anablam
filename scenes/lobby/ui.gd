extends CanvasLayer

@onready var lobby: Lobby = get_parent()
var dedicated_server_ip = "62.238.5.106"
var localhost_ip = "127.0.0.1"
var default_port = 34777
var random_names: Array[String] = [
	"Monkey",
	"Walrus",
	"Chihuahua",
	"Bonobo",
	"Chameleon",
	"Bacterium",
	"Hippo",
	"Elk",
	"Goanna",
	"Koala",
	"Kangaroo",
	"Platypus",
	"Raven",
	"Eagle",
	"Moose",
	"Beaver",
	"Rat",
	"Donkey",
	"Caribou",
	"Springbok",
	"Mouse",
	"Capybara",
	"Tapir",
	"Sloth",
	"Raccoon",
	"Worm",
	"Mole",
	"Bat",
	"Bison",
	"Yak",
	"Buffalo",
	"Gnu",
]

# ENet


func _on_join_dedicated_pressed():
	lobby.display_name = check_name()
	lobby.start_enet_client(dedicated_server_ip, default_port)
	hide()


func _on_join_localhost_pressed():
	lobby.display_name = check_name()
	lobby.start_enet_client(localhost_ip, default_port)
	hide()


func _on_enet_host_pressed():
	lobby.display_name = check_name()
	lobby.start_enet_server(default_port)
	hide()


func check_name() -> String:
	var supplied_name = $Panel/MarginContainer/VBoxContainer/HBoxContainer/NameEntry.text
	var cleaned: String = ""
	for character in supplied_name:
		if (character >= "a" && character <= "z") \
				or (character >= "A" && character <= "Z") \
				or (character >= "0" && character <= "9"):
			cleaned += character

	cleaned = cleaned.substr(0, 15)

	if cleaned.length() < 2:
		return random_names.pick_random()
	return cleaned
