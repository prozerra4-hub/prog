class_name WorldContext
extends RefCounted
## Read-mostly view of the match that brains and systems receive. Decouples AI and
## combat from GameSession (they depend on this narrow API, not on the session).

var arena: ArenaSystem
var zone: ZoneSystem
var food: FoodField
var index: SnakeSpatialIndex
var snakes: Array[SnakeActor] = []
var player: SnakeActor
var boss: SnakeActor
var rng: RandomNumberGenerator
var rules: CombatRules


## Snake with the given slot id, or null.
func snake_by_slot(slot: int) -> SnakeActor:
	for s: SnakeActor in snakes:
		if s.slot == slot:
			return s
	return null
