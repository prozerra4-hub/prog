class_name GameStateMachine
extends RefCounted
## Match lifecycle. Guards illegal transitions so systems can't, for example,
## end a match twice or pause a finished one.

signal changed(old_state: State, new_state: State)

enum State { SETUP, PLAYING, PAUSED, ENDED }

const ALLOWED: Dictionary = {
	State.SETUP: [State.PLAYING],
	State.PLAYING: [State.PAUSED, State.ENDED],
	State.PAUSED: [State.PLAYING, State.ENDED],
	State.ENDED: [],
}

var state: State = State.SETUP


## True if `next` is a legal transition from the current state.
func can_enter(next: State) -> bool:
	return (ALLOWED[state] as Array).has(next)


## Moves to `next` if legal; returns false (and does nothing) otherwise.
func transition(next: State) -> bool:
	if not can_enter(next):
		return false
	var old: State = state
	state = next
	changed.emit(old, next)
	return true


## True in the PLAYING state.
func is_playing() -> bool:
	return state == State.PLAYING
