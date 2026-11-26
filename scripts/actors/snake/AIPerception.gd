class_name AIPerception
extends RefCounted
## What an AI snake currently knows, refreshed on its think interval.
##   threats    bigger mouths near my head or body (predicted a moment ahead)
##   obstacles  bodies that would block me (walls to steer around)
##   prey       the best strike opportunity: a weaker snake's part, scored by how
##              much a strike there would take (cuts near the neck take most)
##   food_point the richest nearby food cluster

const MAX_OBSTACLES: int = 48
## Prey score multiplier for the player (AI rivals mostly fight each other).
const PLAYER_PREY_WEIGHT: float = 0.6
## Seconds ahead used to predict where a threat's mouth will be.
const THREAT_LOOKAHEAD: float = 0.35

## Predicted mouth positions of threats and their danger reach.
var threat_points := PackedVector2Array()
var threat_reach := PackedFloat32Array()
## Strongest threat head (null if none) and its distance.
var threat: SnakeActor
var threat_distance: float = INF
## Weighted "away from danger" direction (zero when calm).
var avoidance: Vector2 = Vector2.ZERO
## 0..1 how urgent escaping is.
var danger: float = 0.0
## Blocking body beads (positions + radii) for obstacle probing.
var obstacle_points := PackedVector2Array()
var obstacle_radii := PackedFloat32Array()

var prey: SnakeActor
## Part of the prey to strike (SnakeSpatialIndex.HEAD or a bead index).
var prey_part: int = -1
var prey_point: Vector2 = Vector2.INF
var prey_distance: float = INF
var prey_value: float = 0.0
var food_point: Vector2 = Vector2.INF
## Distance to the safe-zone edge (negative = outside the zone).
var edge_distance: float = INF
var sight: float = 500.0

var _hits := PackedInt32Array()


func refresh(me: SnakeActor, world: WorldContext, p: AIPersonality, rules: CombatRules) -> void:
	_clear()
	var head: Vector2 = me.head_position()
	var my_r: float = me.head_radius()
	var my_level: float = float(me.stats.level)
	sight = maxf(my_r * p.sight_r, p.sight_min_px)
	edge_distance = world.zone.distance_to_edge(head)
	var threat_floor: float = my_level * (1.0 + rules.even_match_ratio - p.caution_margin)
	var prey_ceiling: float = my_level * p.prey_ratio
	var my_body_samples: PackedVector2Array = _body_samples(me)

	_hits.clear()
	world.index.query(head, sight, _hits)
	var seen_threat: Dictionary = {}
	for h: int in _hits:
		var other: SnakeActor = world.index.actor_of(h)
		if other == null or other == me or not other.is_alive:
			continue
		var part: int = SnakeSpatialIndex.part_of(h)
		var is_head: bool = part == SnakeSpatialIndex.HEAD
		var pos: Vector2 = SnakeSpatialIndex.part_position(other, part)
		var d: float = head.distance_to(pos)
		if d > sight:
			continue
		var lvl: float = float(other.stats.level)
		if lvl > threat_floor and not me.is_invulnerable():
			if is_head and not seen_threat.has(other):
				seen_threat[other] = true
				_add_threat(other, head, my_r, my_body_samples)
			elif not is_head:
				_add_obstacle(pos, SnakeSpatialIndex.part_radius(other, part), d, my_r)
		elif lvl >= my_level * 0.5 and not is_head:
			_add_obstacle(pos, SnakeSpatialIndex.part_radius(other, part), d, my_r)
		var weak_spot: bool = p.hunts_boss and other.is_boss and other.is_weak_spot(part) 				and (other.brain as BossController).enraged
		if (lvl <= prey_ceiling or weak_spot) and not other.is_invulnerable() and (not other.is_boss or p.hunts_boss):
			_consider_prey(other, part, pos, d, rules)

	food_point = world.food.best_target(head, me.heading(), minf(sight, 700.0 + my_r * 8.0))


func _clear() -> void:
	threat_points.clear()
	threat_reach.clear()
	threat = null
	threat_distance = INF
	avoidance = Vector2.ZERO
	danger = 0.0
	obstacle_points.clear()
	obstacle_radii.clear()
	prey = null
	prey_part = -1
	prey_point = Vector2.INF
	prey_distance = INF
	prey_value = 0.0


## A bigger mouth: dangerous to my head and (less) to my body.
func _add_threat(other: SnakeActor, head: Vector2, my_r: float,
		body_samples: PackedVector2Array) -> void:
	var mouth: Vector2 = other.head_position() + other.heading() * other.current_speed() * THREAT_LOOKAHEAD
	var reach: float = my_r * 8.0 + other.head_radius() * 5.0
	var to_head: Vector2 = mouth - head
	var d: float = to_head.length()
	# Exposure of my body: a mouth near my body can cut it.
	var body_d: float = INF
	for b: Vector2 in body_samples:
		body_d = minf(body_d, b.distance_to(mouth))
	var effective: float = minf(d, body_d * 1.4)
	if effective > reach:
		return
	var coming: float = clampf(other.heading().dot(-to_head / maxf(d, 0.001)), 0.0, 1.0)
	var w: float = pow(1.0 - effective / reach, 2.0) * (2.0 + 2.0 * coming) * (1.4 if other.is_boss else 1.0)
	avoidance -= (to_head / maxf(d, 0.001)) * w
	danger = maxf(danger, (1.0 - effective / reach) * (0.6 + 0.4 * coming))
	threat_points.append(mouth)
	threat_reach.append(reach)
	if d < threat_distance:
		threat = other
		threat_distance = d


func _add_obstacle(pos: Vector2, r: float, d: float, my_r: float) -> void:
	if d > my_r * 10.0 + r or obstacle_points.size() >= MAX_OBSTACLES:
		return
	obstacle_points.append(pos)
	obstacle_radii.append(r)


## Scores a strike on `part` of a weaker snake: XP it would take / distance.
func _consider_prey(other: SnakeActor, part: int, pos: Vector2, d: float, rules: CombatRules) -> void:
	var share: float
	if part == SnakeSpatialIndex.HEAD:
		share = 0.35
	else:
		var n: int = maxi(other.body.count, 1)
		share = float(n - part) / float(n)
		if float(part) / float(n) < rules.neck_cut_ratio:
			share = 1.2  # a neck strike swallows: best possible outcome
	# Rivals prefer each other; the player is a lower-priority mark for them.
	var bias: float = 3.0 if other.is_boss else (PLAYER_PREY_WEIGHT if other.is_player else 1.0)
	var value: float = float(maxi(other.stats.total_xp, 10)) * share * bias
	var score: float = value / (d + 80.0)
	if score > prey_value:
		prey_value = score
		prey = other
		prey_part = part
		prey_point = pos
		prey_distance = d


func _body_samples(me: SnakeActor) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n: int = me.body.count
	var step: int = maxi(int(float(n) / 6.0), 1)
	for i: int in range(0, n, step):
		out.append(me.body.positions[i])
	return out
