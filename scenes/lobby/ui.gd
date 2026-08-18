extends CanvasLayer

@onready var lobby: Lobby = get_parent()
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


func _on_enet_join_pressed():
	lobby.display_name = check_name()
	var address: String = $Start/ENet/Join/VBox/Options/Address.text
	var port: int = $Start/ENet/Join/VBox/Options/Port.value
	lobby.start_enet_client(address, port)
	hide()


func _on_enet_host_pressed():
	lobby.display_name = check_name()
	var port: int = $Start/ENet/Host/VBox/Options/Port.value
	lobby.start_enet_server(port)
	hide()


func check_name() -> String:
	var supplied_name = $Start/ENet/Name/VBox/Name.text
	supplied_name.strip_edges()
	if supplied_name.length() < 2:
		return random_names.pick_random()
	else:
		return supplied_name
