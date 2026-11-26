class_name MatchDirector
extends RefCounted
## Match clock and phases. REGULAR (growth & hunting) -> SHOWDOWN (final boss
## fight) -> OVER. Running out of regular time does NOT end the match; it starts
## the showdown. The match ends on boss defeat, elimination, or the showdown clock.

signal time_changed(seconds_left: int)
signal phase_changed(phase: Phase)
signal finished(outcome: MatchResult.Outcome)

enum Phase { REGULAR, SHOWDOWN, OVER }

var phase: Phase = Phase.REGULAR
var time_left: float = 0.0

var _showdown_sec: float
var _end_countdown: float = -1.0
var _pending: MatchResult.Outcome = MatchResult.Outcome.TIME_UP
var _last_whole: int = -1


func _init(regular_sec: float, showdown_sec: float) -> void:
	time_left = regular_sec
	_showdown_sec = showdown_sec


## Whole seconds left in the current phase.
func seconds_left() -> int:
	return int(ceil(maxf(time_left, 0.0)))


## True during the SHOWDOWN phase.
func is_showdown() -> bool:
	return phase == Phase.SHOWDOWN


## True once an end has been scheduled (clock frozen, result pending).
func is_ending() -> bool:
	return _end_countdown >= 0.0


## Requests the end of the match after `delay` (first request wins).
func end_match(outcome: MatchResult.Outcome, delay: float) -> void:
	if _end_countdown >= 0.0 or phase == Phase.OVER:
		return
	_pending = outcome
	_end_countdown = delay


func tick(delta: float) -> void:
	if phase == Phase.OVER:
		return
	if _end_countdown >= 0.0:
		_end_countdown -= delta
		if _end_countdown <= 0.0:
			phase = Phase.OVER
			finished.emit(_pending)
		return
	time_left = maxf(time_left - delta, 0.0)
	var whole: int = seconds_left()
	if whole != _last_whole:
		_last_whole = whole
		time_changed.emit(whole)
	if time_left > 0.0:
		return
	if phase == Phase.REGULAR:
		phase = Phase.SHOWDOWN
		time_left = _showdown_sec
		_last_whole = -1
		phase_changed.emit(phase)
	else:
		end_match(MatchResult.Outcome.TIME_UP, 0.0)
