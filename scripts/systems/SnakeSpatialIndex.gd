class_name SnakeSpatialIndex
extends RefCounted
## Spatial hash of every live snake's head and beads, rebuilt once per frame after
## movement. Combat, AI perception and safe-spawn checks all query it.
##
## Handle encoding: slot * STRIDE + part, where part == HEAD for the head and the
## bead index otherwise.

const STRIDE: int = 1024
const HEAD: int = STRIDE - 1

var _hash: SpatialHash
var _by_slot: Dictionary = {}  # int -> SnakeActor
## Largest collision radius indexed this frame (queries pad by this).
var max_radius: float = 0.0


func _init(cell_size: float = 160.0) -> void:
	_hash = SpatialHash.new(cell_size)


## Re-indexes every live head and bead (once per frame, after movement).
func rebuild(snakes: Array[SnakeActor]) -> void:
	_hash.clear()
	_by_slot.clear()
	max_radius = 0.0
	for s: SnakeActor in snakes:
		if not s.is_alive:
			continue
		assert(s.body.count < HEAD, "render_segment_cap must stay below SnakeSpatialIndex.HEAD")
		_by_slot[s.slot] = s
		var base: int = s.slot * STRIDE
		_hash.insert(base + HEAD, s.head_position())
		max_radius = maxf(max_radius, s.head_radius())
		var positions: PackedVector2Array = s.body.positions
		for i: int in s.body.count:
			_hash.insert(base + i, positions[i])


## Appends handles near `center` (padded by the largest radius); caller does exact tests.
func query(center: Vector2, radius: float, out: PackedInt32Array) -> void:
	_hash.query(center, radius + max_radius, out)


## Snake owning `handle`, or null if the handle is stale. The index is rebuilt once
## per frame, but AI perception queries it mid-frame, after some snakes may have
## died or respawned with fewer beads; such handles are rejected here so every
## consumer is safe.
@warning_ignore("integer_division")
func actor_of(handle: int) -> SnakeActor:
	var actor: SnakeActor = _by_slot.get(handle / STRIDE)
	if actor == null or not actor.is_alive:
		return null
	var part: int = handle % STRIDE
	if part != HEAD and part >= actor.body.count:
		return null
	return actor


## Bead index of a handle, or HEAD.
static func part_of(handle: int) -> int:
	return handle % STRIDE


## True if the handle is a head.
static func is_head(handle: int) -> bool:
	return handle % STRIDE == HEAD


## Position and radius of an indexed part.
static func part_position(actor: SnakeActor, part: int) -> Vector2:
	return actor.head_position() if part == HEAD else actor.body.positions[part]


## Radius of an indexed part.
static func part_radius(actor: SnakeActor, part: int) -> float:
	return actor.head_radius() if part == HEAD else actor.body.radii[part]


## Distance from `p` to the nearest live snake part (excluding `ignore`), capped at `max_dist`.
func clearance(p: Vector2, max_dist: float, ignore: SnakeActor = null) -> float:
	var hits := PackedInt32Array()
	query(p, max_dist, hits)
	var best: float = max_dist
	for h: int in hits:
		var a: SnakeActor = actor_of(h)
		if a == null or a == ignore:
			continue
		var part: int = part_of(h)
		var d: float = p.distance_to(part_position(a, part)) - part_radius(a, part)
		best = minf(best, d)
	return maxf(best, 0.0)
