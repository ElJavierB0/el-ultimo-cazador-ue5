extends Node
## Audio: reproduce la música y los efectos. Los sonidos se generan con tools/generate_audio.gd.

const MUSIC_PATH := "res://assets/audio/music/%s.wav"
const SFX_PATH := "res://assets/audio/sfx/%s.wav"
const VOICES := 8

var muted := false
var current := ""
var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.volume_db = -11.0
	add_child(_music)
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -6.0
		add_child(voice)
		_voices.append(voice)


func sfx(sound: String) -> void:
	var path := SFX_PATH % sound
	if not ResourceLoader.exists(path):
		push_warning("No existe el efecto: " + sound)
		return
	var voice := _voices[_next]
	_next = (_next + 1) % VOICES
	voice.stream = load(path)
	voice.play()


func music(track: String) -> void:
	if current == track and _music.playing:
		return
	var path := MUSIC_PATH % track
	if not ResourceLoader.exists(path):
		push_warning("No existe la pista: " + track)
		return
	current = track
	var stream := load(path) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	current = ""
	_music.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
		Events.message.emit("Sonido apagado" if muted else "Sonido encendido")
