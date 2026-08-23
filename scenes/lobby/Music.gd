extends AudioStreamPlayer

@export var menu: MusicData
@export var lobby: MusicData
@export var battle: MusicData

enum MUSIC_TRACK {
	MENU,
	LOBBY,
	BATTLE,
}


func play_track(track: MUSIC_TRACK) -> void:
	var new_stream: AudioStream
	match track:
		MUSIC_TRACK.MENU:
			new_stream = menu.stream
			volume_db = menu.volume_db
		MUSIC_TRACK.LOBBY:
			new_stream = lobby.stream
			volume_db = lobby.volume_db
		MUSIC_TRACK.BATTLE:
			new_stream = battle.stream
			volume_db = battle.volume_db
	if stream == new_stream and playing:
		return

	stream = new_stream
	play()


func stop_music() -> void:
	stop()
