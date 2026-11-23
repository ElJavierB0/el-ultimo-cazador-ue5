extends SceneTree
## Genera la música y los efectos del juego por síntesis (composición propia, sin muestras de terceros).
## Uso: godot --headless --path juego -s tools/generate_audio.gd
##
## Partituras: "A4" nota · "." silencio · "-" sostener la nota anterior. Cada paso es una corchea.

const RATE := 22050
const NOTES := {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}

const TRACKS := {
	"forest": {"bpm": 104, "wave": "square",
		"lead": "A4 . C5 . E5 . D5 C5  B4 . G4 . A4 - - .  A4 . C5 . E5 . G5 F5  E5 . D5 . E5 - - .  F5 . E5 . D5 . C5 .  B4 . C5 . D5 - - .  C5 . B4 . A4 . G#4 .  A4 - - . . . . .",
		"bass": "A2 . . . A3 . . .  G2 . . . G3 . . .  F2 . . . F3 . . .  E2 . . . E3 . . .  D2 . . . D3 . . .  G2 . . . G3 . . .  E2 . . . E3 . . .  A2 . . . A3 . . ."},
	"battle": {"bpm": 150, "wave": "square",
		"lead": "E5 E5 D5 E5 . B4 C5 D5  E5 . G5 F5 E5 D5 C5 B4  A4 A4 G4 A4 . E4 F4 G4  A4 . C5 B4 A4 G#4 A4 .",
		"bass": "A2 A3 A2 A3 A2 A3 A2 A3  G2 G3 G2 G3 G2 G3 G2 G3  F2 F3 F2 F3 F2 F3 F2 F3  E2 E3 E2 E3 E2 E3 E2 E3"},
	"boss": {"bpm": 168, "wave": "saw",
		"lead": "D5 D5 C5 D5 . A4 A#4 C5  D5 . F5 E5 D5 C5 A#4 A4  G4 G4 F4 G4 . D4 E4 F4  G4 . A#4 A4 G4 F#4 G4 .",
		"bass": "D2 D3 D2 D3 D2 D3 D2 D3  C2 C3 C2 C3 C2 C3 C2 C3  A#1 A#2 A#1 A#2 A#1 A#2 A#1 A#2  A1 A2 A1 A2 A1 A2 A1 A2"},
	"title": {"bpm": 72, "wave": "triangle",
		"lead": "A4 - - . E5 - - .  D5 - C5 - B4 - - .  C5 - - . A4 - - .  B4 - G#4 - A4 - - .",
		"bass": "A2 - - - - - - -  F2 - - - - - - -  C2 - - - - - - -  E2 - - - - - - -"},
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/music")
	DirAccess.make_dir_recursive_absolute("res://assets/audio/sfx")
	for track: String in TRACKS:
		_save("music/" + track, _render_track(TRACKS[track]))
	_render_sfx()
	print("Audio generado.")
	quit()


## ---------- Síntesis ----------

func _freq(note: String) -> float:
	var octave := int(note.right(1))
	var midi: int = NOTES[note.left(note.length() - 1)] + (octave + 1) * 12
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


func _buffer(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Suma un tono al buffer. "slide" es la frecuencia final si el tono se desliza.
func _tone(b: PackedFloat32Array, at: float, f: float, dur: float, vol: float, wave := "square", slide := 0.0) -> void:
	var start := int(at * RATE)
	var count := mini(int(dur * RATE), b.size() - start)
	var phase := 0.0
	for i in count:
		var k := float(i) / (dur * RATE)
		var fr := f if slide <= 0.0 else f * pow(slide / f, k)
		phase = fposmod(phase + fr / RATE, 1.0)
		var s := 0.0
		match wave:
			"square": s = 0.6 if phase < 0.5 else -0.6
			"saw": s = (phase * 2.0 - 1.0) * 0.6
			"triangle": s = 4.0 * absf(phase - 0.5) - 1.0
			"sine": s = sin(phase * TAU)
		var attack := minf(1.0, i / (0.004 * RATE))
		b[start + i] += s * vol * attack * pow(0.004, k)


## Suma ruido filtrado (golpes, fuego). "cutoff" es el filtro pasa bajas en Hz.
func _noise(b: PackedFloat32Array, at: float, dur: float, vol: float, cutoff: float) -> void:
	var start := int(at * RATE)
	var count := mini(int(dur * RATE), b.size() - start)
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	var last := 0.0
	for i in count:
		last += a * (randf_range(-1.0, 1.0) - last)
		b[start + i] += last * vol * 1.8 * pow(0.004, float(i) / (dur * RATE))


func _arp(notes: Array, step: float, vol: float, wave := "square") -> PackedFloat32Array:
	var b := _buffer(notes.size() * step + step)
	for i in notes.size():
		if notes[i] != "-":
			_tone(b, i * step, _freq(notes[i]), step * 1.6, vol, wave)
	return b


func _render_track(t: Dictionary) -> PackedFloat32Array:
	var step := 60.0 / float(t.bpm) / 2.0
	var lead := (t.lead as String).split(" ", false)
	var bass := (t.bass as String).split(" ", false)
	var b := _buffer(maxi(lead.size(), bass.size()) * step)
	_render_line(b, lead, step, t.wave, 0.22)
	_render_line(b, bass, step, "triangle", 0.42)
	return b


func _render_line(b: PackedFloat32Array, line: PackedStringArray, step: float, wave: String, vol: float) -> void:
	for i in line.size():
		if line[i] == "." or line[i] == "-":
			continue
		var length := 1
		while i + length < line.size() and line[i + length] == "-":
			length += 1
		_tone(b, i * step, _freq(line[i]), step * length * 1.15, vol, wave)


func _render_sfx() -> void:
	var b := _buffer(0.18)
	_tone(b, 0, 220, 0.16, 0.4, "square", 520)
	_save("sfx/jump", b)
	_save("sfx/coin", _arp(["B5", "E6"], 0.07, 0.35))
	_save("sfx/potion", _arp(["C5", "E5", "G5", "C6"], 0.06, 0.45, "triangle"))
	_save("sfx/select", _arp(["A5", "E6"], 0.05, 0.3))
	_save("sfx/buy", _arp(["E5", "B5", "E6", "G6"], 0.06, 0.35, "triangle"))
	b = _buffer(0.06)
	_tone(b, 0, 660, 0.05, 0.25)
	_save("sfx/move", b)
	b = _buffer(0.12)
	_tone(b, 0, 330, 0.1, 0.3, "square", 220)
	_save("sfx/back", b)
	b = _buffer(0.2)
	_noise(b, 0, 0.14, 0.7, 4000)
	_tone(b, 0, 900, 0.1, 0.2, "saw", 300)
	_save("sfx/slash", b)
	b = _buffer(0.25)
	_noise(b, 0, 0.1, 0.5, 7000)
	_tone(b, 0.02, 1318, 0.2, 0.25, "triangle")
	_tone(b, 0.06, 1975, 0.18, 0.22, "triangle")
	_save("sfx/silver", b)
	b = _buffer(0.25)
	_noise(b, 0, 0.2, 1.0, 900)
	_tone(b, 0, 140, 0.18, 0.5, "square", 60)
	_save("sfx/hit", b)
	b = _buffer(0.35)
	_noise(b, 0, 0.28, 1.0, 1500)
	_tone(b, 0, 200, 0.3, 0.5, "saw", 50)
	_save("sfx/crit", b)
	b = _buffer(0.6)
	_noise(b, 0, 0.55, 1.0, 700)
	_tone(b, 0, 120, 0.5, 0.3, "saw", 400)
	_save("sfx/fire", b)
	_save("sfx/shield", _arp(["G4", "D5", "G5"], 0.07, 0.4, "triangle"))
	_save("sfx/heal", _arp(["C5", "E5", "G5", "E5", "G5", "C6"], 0.06, 0.4, "triangle"))
	b = _buffer(0.25)
	_tone(b, 0, 500, 0.2, 0.3, "triangle", 250)
	_save("sfx/miss", b)
	b = _buffer(0.2)
	_noise(b, 0, 0.16, 0.8, 600)
	_tone(b, 0, 180, 0.14, 0.4, "saw", 90)
	_save("sfx/enemy_attack", b)
	_save("sfx/battle_start", _arp(["A4", "C5", "E5", "A5", "E5", "A5", "C6"], 0.06, 0.35))
	_save("sfx/victory", _arp(["C5", "E5", "G5", "C6", "-", "G5", "C6"], 0.1, 0.38))
	_save("sfx/level_up", _arp(["C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6"], 0.06, 0.4, "triangle"))
	_save("sfx/defeat", _arp(["E4", "D#4", "D4", "C#4"], 0.2, 0.45, "triangle"))
	b = _buffer(0.65)
	_tone(b, 0, 400, 0.6, 0.45, "square", 60)
	_save("sfx/death", b)
	_save("sfx/checkpoint", _arp(["D5", "A5", "D6"], 0.09, 0.4, "triangle"))
	_save("sfx/clear", _arp(["G4", "C5", "E5", "G5", "E5", "G5", "C6", "-", "C6"], 0.1, 0.38))
	b = _buffer(0.3)
	_tone(b, 0, 110, 0.25, 0.4, "saw")
	_save("sfx/locked", b)
	b = _buffer(0.08)
	_tone(b, 0, 1200, 0.06, 0.18, "sine")
	_save("sfx/medallion", b)


func _save(path: String, samples: PackedFloat32Array) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	wav.save_to_wav("res://assets/audio/%s.wav" % path)
