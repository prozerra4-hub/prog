class_name FoodField
extends Node2D
## Food behaviour: ambient population, remains and severed-body drops, pickup with
## a short fly-into-the-mouth animation, and food queries for AI.
## Data lives in FoodStore (pooled, node-free); drawing is done by FoodRenderer.

signal food_collected(actor: SnakeActor, xp: int, at: Vector2, special: bool)

const REMAINS_LIFETIME: float = 30.0
const REMAINS_FADE: float = 2.0
## Cell size used to score food clusters for AI.
const CLUSTER_CELL: float = 160.0

var store := FoodStore.new()

var _table: FoodTable
var _arena: ArenaSystem
var _zone: ZoneSystem
var _rng: RandomNumberGenerator
var _absorbing := PackedInt32Array()
var _refill_budget: float = 0.0
var _scratch := PackedInt32Array()
var _renderer: FoodRenderer


func setup(table: FoodTable, arena: ArenaSystem, zone: ZoneSystem, rng: RandomNumberGenerator) -> void:
	_table = table
	_arena = arena
	_zone = zone
	_rng = rng
	_renderer = FoodRenderer.new()
	_renderer.name = "FoodRenderer"
	add_child(_renderer)
	_renderer.setup(store, table.spawn_pop_duration, REMAINS_LIFETIME, REMAINS_FADE)


## Initial population. Orbs get a staggered pop-in so the arena doesn't blink on.
func populate(index: SnakeSpatialIndex) -> void:
	for i: int in _table.target_count:
		var id: int = _spawn_ambient(index)
		if id >= 0:
			store.age[id] = -_rng.randf_range(0.0, 0.6)


## Per-frame food step: pickups, swallow animation, ageing, refill.
func update(delta: float, world: WorldContext) -> void:
	_pick_up(world)
	_advance_absorbing(delta, world)
	_age_items(delta)
	_refill(delta, world.index)


## Drops remains along a dead snake's body.
func spawn_remains(victim: SnakeActor, total_xp: int, max_orbs: int) -> void:
	_scatter_along(victim.body.positions, total_xp, max_orbs, victim, 0.25)


## Turns a cut-off part of a body into food along where it lay.
func spawn_severed(victim: SnakeActor, severed: PackedVector2Array, total_xp: int, max_orbs: int) -> void:
	_scatter_along(severed, total_xp, max_orbs, victim, 0.18)


## Ambient orbs alive (excludes remains).
func ambient_count() -> int:
	return store.ambient_alive


## All orbs alive (ambient + remains).
func active_count() -> int:
	return store.active_count()


## Best food target for an AI: the richest nearby CLUSTER inside the safe zone
## (value / distance, favouring what lies ahead). Returns the most valuable orb in
## that cluster, or Vector2.INF when nothing is in range.
func best_target(from: Vector2, heading: Vector2, radius: float) -> Vector2:
	_scratch.clear()
	store.hash.query(from, radius, _scratch)
	var cells: Dictionary = {}  # Vector2i -> [sum_xp, best_id]
	var r2: float = radius * radius
	for id: int in _scratch:
		if store.state[id] != FoodStore.State.IDLE or store.age[id] < 0.0:
			continue
		var p: Vector2 = store.pos[id]
		if from.distance_squared_to(p) > r2 or not _zone.contains(p, 30.0):
			continue
		var key := Vector2i(int(floor(p.x / CLUSTER_CELL)), int(floor(p.y / CLUSTER_CELL)))
		var entry: Array = cells.get(key, [0, id])
		entry[0] = int(entry[0]) + store.xp[id]
		if store.xp[id] > store.xp[int(entry[1])]:
			entry[1] = id
		cells[key] = entry
	var best: Vector2 = Vector2.INF
	var best_score: float = 0.0
	for key: Vector2i in cells.keys():
		var entry: Array = cells[key]
		var p: Vector2 = store.pos[int(entry[1])]
		var to: Vector2 = p - from
		var d: float = to.length()
		var facing: float = 1.0 + 0.6 * heading.dot(to / maxf(d, 0.001))
		var score: float = float(entry[0]) / (d + 120.0) * facing
		if score > best_score:
			best_score = score
			best = p
	return best


# --- Internals ---------------------------------------------------------------

func _scatter_along(positions: PackedVector2Array, total_xp: int, max_orbs: int,
		victim: SnakeActor, stagger: float) -> void:
	if positions.is_empty() or total_xp <= 0:
		return
	var kind: FoodKind = _table.remains_kind
	var n: int = clampi(positions.size() / 3, 2, max_orbs)
	var xp_each: int = maxi(1, total_xp / n)
	var size_k: float = clampf(sqrt(victim.radius / 13.0) * 1.15, 1.0, 4.0)
	var r: float = kind.radius * size_k
	var step: float = float(positions.size()) / float(n)
	for i: int in n:
		var p: Vector2 = positions[mini(int(float(i) * step), positions.size() - 1)]
		p += Vector2.from_angle(_rng.randf() * TAU) * victim.radius * _rng.randf_range(0.1, 0.7)
		if not _arena.contains(p, r):
			continue
		var id: int = store.add(p, xp_each, r, kind.sprite_radius_px, victim.skin.remains_texture_key, false, false, _rng)
		store.age[id] = -float(i) / float(n) * stagger


func _pick_up(world: WorldContext) -> void:
	for s: SnakeActor in world.snakes:
		if not s.is_alive:
			continue
		var head: Vector2 = s.head_position()
		var reach: float = s.head_radius() * (1.0 + _table.magnet_reach_r)
		_scratch.clear()
		store.hash.query(head, reach + 40.0, _scratch)
		for id: int in _scratch:
			if store.state[id] != FoodStore.State.IDLE or store.age[id] < 0.0:
				continue
			var limit: float = reach + store.radius[id]
			if head.distance_squared_to(store.pos[id]) <= limit * limit:
				store.begin_absorb(id, s.slot)
				_absorbing.append(id)


func _advance_absorbing(delta: float, world: WorldContext) -> void:
	if _absorbing.is_empty():
		return
	var still := PackedInt32Array()
	var step: float = delta / maxf(_table.absorb_duration, 0.001)
	for id: int in _absorbing:
		var s: SnakeActor = world.snake_by_slot(store.absorber[id])
		if s == null or not s.is_alive:
			store.drop(id)  # eater died mid-swallow: the orb falls where it is
			continue
		store.absorb_t[id] = minf(store.absorb_t[id] + step, 1.0)
		var t: float = store.absorb_t[id]
		store.pos[id] = store.absorb_from[id].lerp(s.head_position(), t * t)
		if t >= 1.0:
			var special: bool = store.special[id] == 1
			var ambient: bool = store.ambient[id] == 1
			var base_xp: int = maxi(1, roundi(float(store.xp[id]) * _table.ambient_xp_multiplier)) if ambient else store.xp[id]
			var before: int = s.stats.total_xp
			s.on_food_eaten(base_xp, ambient)
			food_collected.emit(s, s.stats.total_xp - before, store.pos[id], special)
			store.release(id)
		else:
			still.append(id)
	_absorbing = still


func _age_items(delta: float) -> void:
	for id: int in store.size():
		if store.state[id] == FoodStore.State.FREE:
			continue
		store.age[id] += delta
		var outside: bool = not _arena.contains(store.pos[id])
		var expired: bool = store.ambient[id] == 0 and store.age[id] > REMAINS_LIFETIME
		if store.state[id] == FoodStore.State.IDLE and (expired or outside):
			store.release(id)


func _refill(delta: float, index: SnakeSpatialIndex) -> void:
	var target: int = _ambient_target()
	if store.ambient_alive >= target:
		_refill_budget = 0.0
		return
	_refill_budget += _table.refill_per_sec * delta
	while _refill_budget >= 1.0 and store.ambient_alive < target:
		_refill_budget -= 1.0
		_spawn_ambient(index)


## Ambient count scales with the safe zone's area.
func _ambient_target() -> int:
	var share: float = pow(_zone.radius / maxf(_arena.radius, 1.0), 2.0)
	return int(float(_table.target_count) * clampf(share, 0.15, 1.0))


func _spawn_ambient(index: SnakeSpatialIndex) -> int:
	var kind: FoodKind = _pick_kind()
	if kind == null:
		return -1
	var p: Vector2 = Vector2.ZERO
	var ok: bool = false
	for attempt: int in 6:
		p = _zone.random_point(_rng, 0.97)
		if index == null or index.clearance(p, _table.spawn_clearance) >= _table.spawn_clearance:
			ok = true
			break
	if not ok:
		return -1
	var key: StringName = kind.texture_keys[_rng.randi() % kind.texture_keys.size()]
	return store.add(p, kind.xp, kind.radius, kind.sprite_radius_px, key, true, kind.has_aura, _rng)


func _pick_kind() -> FoodKind:
	var total: float = 0.0
	for k: FoodKind in _table.kinds:
		total += k.spawn_weight
	if total <= 0.0:
		return null
	var roll: float = _rng.randf() * total
	for k: FoodKind in _table.kinds:
		roll -= k.spawn_weight
		if roll <= 0.0:
			return k
	return _table.kinds.back()
