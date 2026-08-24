extends SpinBox


func _ready() -> void:
	value_changed.connect(_on_value_changed)


func _on_value_changed(new_value: float) -> void:
	if not multiplayer.is_server():
		return
	_sync_value.rpc(new_value)


@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: float) -> void:
	set_value_no_signal(new_value)
