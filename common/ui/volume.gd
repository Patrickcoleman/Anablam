extends PanelContainer

const BUS_NAMES: Array[String] = ["Master", "Music", "SFX"]

@onready var sliders: Dictionary = {
	"Master": $Margins/VBox/Master/MasterScroll,
	"Music": $Margins/VBox/Music/MusicScroll,
	"SFX": $Margins/VBox/SFX/SFXScroll,
}


func _ready() -> void:
	for bus_name in BUS_NAMES:
		var bus_idx: int = AudioServer.get_bus_index(bus_name)
		if bus_idx == -1:
			push_warning("VolumeControls: no audio bus named '%s'" % bus_name)
			continue

		var slider: HScrollBar = sliders[bus_name]
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
		slider.value_changed.connect(_on_slider_changed.bind(bus_name))


func _on_slider_changed(value: float, bus_name: String) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
