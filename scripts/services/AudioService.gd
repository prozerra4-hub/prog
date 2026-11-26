class_name AudioService
extends Node
## Sound effects. No audio files ship with the asset pack, so short, restrained
## tones are synthesised once at startup into AudioStreamWAV buffers. Playback
## uses a small voice pool and per-sound rate limits so rapid events never stack
## into noise.

enum Sfx { EAT, EAT_RARE, LEVEL_UP, KILL, DEATH, RESPAWN, BOSS_CHARGE, BOSS_DOWN, UI_CLICK, UI_HOVER, MATCH_END }

const MIX_RATE: int = 44100
const VOICES: int = 10
const SFX_BUS: StringName = &"SFX"

## Minimum seconds between two plays of the same effect.
const MIN_INTERVAL: Dictionary = {
	Sfx.EAT: 0.045, Sfx.EAT_RARE: 0.08, Sfx.LEVEL_UP: 0.25, Sfx.KILL: 0.08,
	Sfx.UI_HOVER: 0.05,
}
## Linear gain per effect.
const GAIN: Dictionary = {
	Sfx.EAT: 0.22, Sfx.EAT_RARE: 0.35, Sfx.LEVEL_UP: 0.35, Sfx.KILL: 0.5,
	Sfx.DEATH: 0.5, Sfx.RESPAWN: 0.35, Sfx.BOSS_CHARGE: 0.45, Sfx.BOSS_DOWN: 0.6,
	Sfx.UI_CLICK: 0.3, Sfx.UI_HOVER: 0.12, Sfx.MATCH_END: 0.45,
}

var _streams: Dictionary = {}  # Sfx -> AudioStreamWAV
var _last_played: Dictionary = {}  # Sfx -> msec
var _players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()
	for i: int in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_players.append(p)
	_build_streams()


func _exit_tree() -> void:
	# Release in-flight playbacks so quitting mid-sound leaves nothing behind.
	for p: AudioStreamPlayer in _players:
		p.stop()
		p.stream = null
	_streams.clear()


## Plays an effect (rate-limited per effect) with optional random pitch jitter.
func play(sfx: Sfx, pitch_jitter: float = 0.0) -> void:
	var now: int = Time.get_ticks_msec()
	var min_gap: float = float(MIN_INTERVAL.get(sfx, 0.0))
	if min_gap > 0.0 and now - int(_last_played.get(sfx, -100000)) < int(min_gap * 1000.0):
		return
	_last_played[sfx] = now
	var player: AudioStreamPlayer = _players[_next_voice]
	_next_voice = (_next_voice + 1) % _players.size()
	player.stream = _streams[sfx]
	player.volume_db = linear_to_db(float(GAIN.get(sfx, 0.4)))
	player.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	player.play()


## Sets master and SFX bus volumes (linear 0..1).
func apply_volumes(master: float, sfx: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master, 0.0001)))
	AudioServer.set_bus_mute(0, master <= 0.001)
	var idx: int = AudioServer.get_bus_index(SFX_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(sfx, 0.0001)))
		AudioServer.set_bus_mute(idx, sfx <= 0.001)


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(SFX_BUS) >= 0:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, SFX_BUS)
	AudioServer.set_bus_send(idx, &"Master")


# --- Synthesis ---------------------------------------------------------------

func _build_streams() -> void:
	_streams[Sfx.EAT] = _tone(0.055, 880.0, 1320.0, 0.0, 0.004, 0.05)
	_streams[Sfx.EAT_RARE] = _chord(0.22, [1046.5, 1568.0], 0.006, 0.2)
	_streams[Sfx.LEVEL_UP] = _arp(0.32, [523.25, 659.25, 783.99], 0.09)
	_streams[Sfx.KILL] = _tone(0.16, 180.0, 70.0, 0.35, 0.002, 0.15)
	_streams[Sfx.DEATH] = _tone(0.45, 420.0, 90.0, 0.15, 0.005, 0.42)
	_streams[Sfx.RESPAWN] = _tone(0.38, 300.0, 900.0, 0.0, 0.08, 0.28)
	_streams[Sfx.BOSS_CHARGE] = _tone(0.6, 70.0, 110.0, 0.25, 0.15, 0.4)
	_streams[Sfx.BOSS_DOWN] = _arp(0.9, [392.0, 523.25, 659.25, 1046.5], 0.14)
	_streams[Sfx.UI_CLICK] = _tone(0.03, 1800.0, 1500.0, 0.0, 0.001, 0.028)
	_streams[Sfx.UI_HOVER] = _tone(0.02, 2400.0, 2400.0, 0.0, 0.001, 0.018)
	_streams[Sfx.MATCH_END] = _arp(0.7, [659.25, 523.25, 783.99], 0.16)


## Pitch sweep with optional noise, simple attack/decay envelope.
func _tone(duration: float, f0: float, f1: float, noise: float, attack: float, decay: float) -> AudioStreamWAV:
	var n: int = int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase: float = 0.0
	for i: int in n:
		var t: float = float(i) / MIX_RATE
		var k: float = t / duration
		var f: float = lerpf(f0, f1, k)
		phase += TAU * f / MIX_RATE
		var s: float = sin(phase) * 0.8 + sin(phase * 2.0) * 0.12
		if noise > 0.0:
			s = s * (1.0 - noise) + _rng.randf_range(-1.0, 1.0) * noise
		s *= _envelope(t, duration, attack, decay)
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32000.0))
	return _wav(data)


func _chord(duration: float, freqs: Array, attack: float, decay: float) -> AudioStreamWAV:
	var n: int = int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i: int in n:
		var t: float = float(i) / MIX_RATE
		var s: float = 0.0
		for f: float in freqs:
			s += sin(TAU * f * t)
		s = s / float(freqs.size()) * _envelope(t, duration, attack, decay)
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 30000.0))
	return _wav(data)


## Notes played in sequence, each with its own short envelope.
func _arp(duration: float, freqs: Array, step: float) -> AudioStreamWAV:
	var n: int = int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i: int in n:
		var t: float = float(i) / MIX_RATE
		var s: float = 0.0
		for j: int in freqs.size():
			var start: float = step * float(j)
			if t >= start:
				var lt: float = t - start
				var f: float = freqs[j]
				var env: float = minf(lt / 0.006, 1.0) * exp(-lt * 7.0)
				s += (sin(TAU * f * lt) * 0.75 + sin(TAU * f * 2.0 * lt) * 0.15) * env
		s *= 0.55 * clampf((duration - t) / 0.05, 0.0, 1.0)
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 30000.0))
	return _wav(data)


func _envelope(t: float, duration: float, attack: float, decay: float) -> float:
	var a: float = minf(t / maxf(attack, 0.0005), 1.0)
	var tail: float = clampf((duration - t) / maxf(decay, 0.0005), 0.0, 1.0)
	return a * tail * tail


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
