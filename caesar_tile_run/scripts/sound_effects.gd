extends Node

var safe_stream: AudioStream
var crumble_stream: AudioStream
var victory_stream: AudioStream
var explosion_stream: AudioStream
var tick_stream: AudioStream
var crack_stream: AudioStream
var whack_stream: AudioStream
var footstep_stream: AudioStream
var landing_stream: AudioStream

func _ready() -> void:
	load_or_synthesize_sounds()

func load_or_synthesize_sounds() -> void:
	safe_stream = create_tone(880.0, 0.25, 0.8)
	crumble_stream = create_noise_crunch(0.4)
	victory_stream = create_fanfare(0.6)
	explosion_stream = create_explosion(0.65)
	tick_stream = create_click(1200.0, 0.04)
	crack_stream = create_click(650.0, 0.08)
	whack_stream = create_whack(0.28)
	footstep_stream = create_footstep(0.05)
	landing_stream = create_thud(0.16)

func play_safe() -> void:
	play_stream(safe_stream, -4.0)

func play_crumble() -> void:
	play_stream(crumble_stream, -2.0)

func play_victory() -> void:
	play_stream(victory_stream, 0.0)

func play_explosion() -> void:
	play_stream(explosion_stream, 2.0)

func play_tick() -> void:
	play_stream(tick_stream, -5.0)

func play_crack() -> void:
	play_stream(crack_stream, -3.0)

func play_whack() -> void:
	play_stream(whack_stream, 1.0)

func play_footstep() -> void:
	play_stream(footstep_stream, -14.0, randf_range(0.92, 1.08))

func play_landing() -> void:
	play_stream(landing_stream, -3.0)

func play_stream(stream: AudioStream, vol: float, pitch: float = 1.0) -> void:
	if stream:
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = stream
		p.volume_db = vol
		p.pitch_scale = pitch
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

func create_explosion(duration: float) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var sample_count = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / wav.mix_rate
		var envelope = exp(-t * 4.0)
		var low_rumble = sin(2.0 * PI * 65.0 * t * (1.0 - t * 0.5))
		var noise = (randf() * 2.0 - 1.0) * 0.7
		var val = (low_rumble * 0.6 + noise * 0.4) * envelope
		var int_val = clampi(int(val * 32767.0 * 0.95), -32768, 32767)
		data.encode_s16(i * 2, int_val)
	wav.data = data
	return wav

func create_click(freq: float, duration: float) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var sample_count = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / wav.mix_rate
		var envelope = exp(-t * 80.0)
		var val = sin(2.0 * PI * freq * t) * envelope
		var int_val = clampi(int(val * 32767.0 * 0.7), -32768, 32767)
		data.encode_s16(i * 2, int_val)
	wav.data = data
	return wav

func create_whack(duration: float) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var sample_count = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / wav.mix_rate
		var envelope = exp(-t * 15.0)
		var freq = lerpf(350.0, 90.0, t / duration)
		var val = (sin(2.0 * PI * freq * t) + (randf() * 0.4 - 0.2)) * envelope
		var int_val = clampi(int(val * 32767.0 * 0.9), -32768, 32767)
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
		var val = (sin(2.0 * PI * 523.25 * t) + sin(2.0 * PI * 659.25 * t) + sin(2.0 * PI * 783.99 * t)) / 3.0
		var envelope = min(1.0, t * 10.0) * exp(-t * 2.0)
		var int_val = clampi(int(val * envelope * 32767.0 * 0.8), -32768, 32767)
		data.encode_s16(i * 2, int_val)
	wav.data = data
	return wav

func create_footstep(duration: float) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var sample_count = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / wav.mix_rate
		var envelope = exp(-t * 55.0)
		var noise = (randf() * 2.0 - 1.0) * 0.7
		var low = sin(2.0 * PI * 180.0 * t) * 0.3
		var val = (noise + low) * envelope
		var int_val = clampi(int(val * 32767.0 * 0.5), -32768, 32767)
		data.encode_s16(i * 2, int_val)
	wav.data = data
	return wav

func create_thud(duration: float) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var sample_count = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / wav.mix_rate
		var envelope = exp(-t * 18.0)
		var bass = sin(2.0 * PI * 110.0 * (1.0 - t * 2.0) * t)
		var noise = (randf() * 2.0 - 1.0) * 0.25
		var val = (bass + noise) * envelope
		var int_val = clampi(int(val * 32767.0 * 0.85), -32768, 32767)
		data.encode_s16(i * 2, int_val)
	wav.data = data
	return wav
