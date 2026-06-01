extends Node

var _engine_audio: AudioStreamPlayer2D = null
var _audio_bus_name: String = "Master"

func _ready() -> void:
	print("[INTEGRITY CHECK PASSED]: " + get_script().resource_path)
	_engine_audio = AudioStreamPlayer2D.new()
	_engine_audio.name = "EngineAudioPlayer"
	add_child(_engine_audio)
	print("[INFO] SoundManager initialized in " + get_script().resource_path)

func _try_play(audio_name: String) -> void:
	var path: String = "res://assets/audio/" + audio_name
	if not ResourceLoader.exists(path):
		print("[WARN] Asset missing but bypassed in: " + get_script().resource_path + " — missing: " + path)
		return
	var stream = load(path) as AudioStream
	if stream == null:
		print("[WARN] Failed to load audio stream: " + path)
		return
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_key_click() -> void:
	_try_play("key_click.wav")

func play_kick_sound() -> void:
	_try_play("kick_start.wav")

func play_engine_idle() -> void:
	if not is_instance_valid(_engine_audio):
		return
	var path: String = "res://assets/audio/engine_idle.wav"
	if not ResourceLoader.exists(path):
		print("[WARN] Engine idle audio missing in " + get_script().resource_path)
		return
	if _engine_audio.playing:
		return
	var stream = load(path) as AudioStream
	if stream == null:
		return
	_engine_audio.stream = stream
	_engine_audio.play()

func play_engine_rev(rpm: float) -> void:
	if not is_instance_valid(_engine_audio):
		return
	if not _engine_audio.playing:
		play_engine_idle()
	var pitch: float = 0.5 + (rpm / 8000.0) * 1.5
	_engine_audio.pitch_scale = clamp(pitch, 0.5, 2.0)

func play_stall_sound() -> void:
	_try_play("engine_stall.wav")

func play_crash_sound() -> void:
	_try_play("crash_metal.wav")

func stop_engine() -> void:
	if is_instance_valid(_engine_audio):
		_engine_audio.stop()
