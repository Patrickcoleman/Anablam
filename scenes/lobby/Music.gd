extends AudioStreamPlayer

@export var menu: AudioStream
@export var lobby: AudioStream
@export var battle: AudioStream

enum MUSIC_TRACK {
	MENU,
	LOBBY,
	BATTLE,
}


func play_track(track: MUSIC_TRACK) -> void:
	var new_stream: AudioStream
	match track:
		MUSIC_TRACK.MENU:
			new_stream = menu
		MUSIC_TRACK.LOBBY:
			new_stream = lobby
		MUSIC_TRACK.BATTLE:
			new_stream = battle

	if stream == new_stream and playing:
		return

	stream = new_stream
	play()


func stop_music() -> void:
	stop()
