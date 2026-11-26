class_name MatchResult
extends RefCounted
## Immutable-by-convention summary of a finished match, handed to UI and save.

## TIME_UP = the showdown clock ran out with the boss still standing.
enum Outcome { VICTORY, TIME_UP, ELIMINATED }

var outcome: Outcome = Outcome.TIME_UP
var final_level: int = 1
var peak_level: int = 1
var final_rank: int = 1
var participants: int = 1
var kills: int = 0
var food_eaten: int = 0
var survival_sec: float = 0.0
var boss_defeated: bool = false
var score: int = 0
var new_record: bool = false


## Headline for the result screen.
func outcome_title() -> String:
	match outcome:
		Outcome.VICTORY:
			return "VICTORY"
		Outcome.ELIMINATED:
			return "ELIMINATED"
		_:
			return "THE TYRANT ENDURES"
