extends Node

# Generates procedural retro sound effects so the game has audio out of the box,
# and allows Karen or the team to easily replace with custom .wav / .ogg files in assets/audio/

var safe_stream: AudioStream
var crumble_stream: AudioStream
var victory_stream: AudioStream

var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Check if custom audio files exist, else synthesize
	load_or_synthesize_sounds()

func load_or_synthesize_sounds() -> void:
	if ResourceLoader.exists("res://assets/audio/safe_chime.wav"):
		safe_stream = load("res://assets/audio/safe_chime.wav")
	else:
		safe_stream = create_tone(880.0, 0.25, 0.8) # High A chime
		
	if ResourceLoader.exists("res://assets/audio/crumble.wav"):
		crumble_stream = load("res://assets/audio/crumble.wav")
	else:
		crumble_stream = create_noise_crunch(0.4)
		
	if ResourceLoader.exists("res://assets/audio/victory.wav"):
		victory_stream = load("res://assets/audio/victory.wav")
	else:
		victory_stream = create_fanfare(0.6)

func play_safe() -> void:
	if safe_stream:
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = safe_stream
		p.volume_db = -4.0
		p.finished.connect(p.queue_free)
		p.play()

func play_crumble() -> void:
	if crumble_stream:
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = crumble_stream
		p.volume_db = -2.0
		p.finished.connect(p.queue_free)
		p.play()

func play_victory() -> void:
	if victory_stream:
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = victory_stream
		p.volume_db = 0.0
		p.finished.connect(p.queue_free)
		p.play()

func create_tone(freq: float, duration: float, decay: float = 0.5) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var sample_count = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / wav.mix_rate
		var envelope = exp(-t * (1.0 / decay) * 8.0)
		var val = sin(2.0 * PI * freq * t) * envelope * 0.7
		var int_val = clampi(int(val * 32767.0), -32768, 32767)
		
		data.encode_s16(i * 2, int_val)
		
	wav.data = data
	return wav

func create_noise_crunch(duration: float) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var sample_count = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / wav.mix_rate
		var envelope = exp(-t * 6.0)
		var val = (randf() * 2.0 - 1.0) * envelope * 0.8
		var int_val = clampi(int(val * 32767.0), -32768, 32767)
		
		data.encode_s16(i * 2, int_val)
		
	wav.data = data
	return wav

func create_fanfare(duration: float) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var sample_count = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / wav.mix_rate
		# Major chord blend (523Hz C5, 659Hz E5, 784Hz G5)
		var val = (sin(2.0 * PI * 523.25 * t) + sin(2.0 * PI * 659.25 * t) + sin(2.0 * PI * 783.99 * t)) / 3.0
		var envelope = min(1.0, t * 10.0) * exp(-t * 2.0)
		var int_val = clampi(int(val * envelope * 32767.0 * 0.8), -32768, 32767)
		data.encode_s16(i * 2, int_val)
		
	wav.data = data
	return wav
