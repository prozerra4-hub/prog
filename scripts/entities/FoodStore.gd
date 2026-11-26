class_name FoodStore
extends RefCounted
## Pooled orb data (structure of packed arrays) + spatial hash of idle orbs.
## FoodField owns the behaviour, FoodRenderer reads these arrays to draw.
## Treat the arrays as read-only outside FoodField.

enum State { FREE, IDLE, ABSORBING }

var pos := PackedVector2Array()
var state := PackedByteArray()
var xp := PackedInt32Array()
var radius := PackedFloat32Array()
var sprite_radius := PackedFloat32Array()
var tex_index := PackedInt32Array()
var age := PackedFloat32Array()
var phase := PackedFloat32Array()
var ambient := PackedByteArray()
var special := PackedByteArray()
var absorber := PackedInt32Array()  # snake slot
var absorb_from := PackedVector2Array()
var absorb_t := PackedFloat32Array()

var textures: Array[Texture2D] = []
var hash := SpatialHash.new(96.0)
var ambient_alive: int = 0

var _free := PackedInt32Array()
var _texture_ids: Dictionary = {}  # StringName -> index


## Pool size (live + free slots).
func size() -> int:
	return pos.size()


## Live orbs in the pool.
func active_count() -> int:
	return pos.size() - _free.size()


## Adds an orb (reusing a free slot) and returns its id.
func add(p: Vector2, value: int, r: float, sprite_r: float, texture_key: StringName,
		is_ambient: bool, is_special: bool, rng: RandomNumberGenerator) -> int:
	var id: int = _alloc()
	pos[id] = p
	state[id] = State.IDLE
	xp[id] = value
	radius[id] = r
	sprite_radius[id] = sprite_r
	tex_index[id] = texture_index(texture_key)
	age[id] = 0.0
	phase[id] = rng.randf() * TAU
	ambient[id] = 1 if is_ambient else 0
	special[id] = 1 if is_special else 0
	absorber[id] = -1
	hash.insert(id, p)
	if is_ambient:
		ambient_alive += 1
	return id


## Frees an orb slot (and removes it from the hash if it was idle).
func release(id: int) -> void:
	if state[id] == State.IDLE:
		hash.remove(id, pos[id])
	if ambient[id] == 1:
		ambient_alive -= 1
	state[id] = State.FREE
	_free.append(id)


## Starts the fly-into-mouth animation toward snake `slot`.
func begin_absorb(id: int, slot: int) -> void:
	hash.remove(id, pos[id])
	state[id] = State.ABSORBING
	absorber[id] = slot
	absorb_from[id] = pos[id]
	absorb_t[id] = 0.0


## Puts an absorbing orb back on the ground (its eater died mid-swallow).
func drop(id: int) -> void:
	state[id] = State.IDLE
	hash.insert(id, pos[id])


## Index of the texture for `key` (loaded once, cached).
func texture_index(key: StringName) -> int:
	if _texture_ids.has(key):
		return _texture_ids[key]
	var tex: Texture2D = Services.assets.texture(key)
	if tex == null:
		tex = Services.assets.texture(AssetIds.FOOD_SMALL_GOLD)
	textures.append(tex)
	_texture_ids[key] = textures.size() - 1
	return textures.size() - 1


func _alloc() -> int:
	if not _free.is_empty():
		var id: int = _free[_free.size() - 1]
		_free.remove_at(_free.size() - 1)
		return id
	var id: int = pos.size()
	pos.append(Vector2.ZERO)
	state.append(State.FREE)
	xp.append(0)
	radius.append(0.0)
	sprite_radius.append(1.0)
	tex_index.append(0)
	age.append(0.0)
	phase.append(0.0)
	ambient.append(0)
	special.append(0)
	absorber.append(-1)
	absorb_from.append(Vector2.ZERO)
	absorb_t.append(0.0)
	return id
