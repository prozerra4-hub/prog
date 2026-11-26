class_name VfxLayer
extends Node2D
## Short-lived sprite effects from a fixed pool (no node churn, bounded on-screen
## count). Every effect is one of the vetted static textures animated with scale,
## alpha and rotation curves — static art is never faked into frame animation.

enum Fx { LEVEL_UP, KILL_SPARK, DEATH_SMOKE, RESPAWN, BOSS_BURST, RARE_PICKUP, BOUNCE }

const POOL_SIZE: int = 36

## texture key, duration, start scale, end scale, start alpha, additive, spin (rad/s)
const DEFS: Dictionary = {
	Fx.LEVEL_UP: [AssetIds.VFX_LEVELUP_GOLD, 0.55, 0.7, 1.7, 0.85, true, 0.0],
	Fx.KILL_SPARK: [AssetIds.VFX_IMPACT_GOLD, 0.28, 0.35, 0.9, 0.9, true, 1.5],
	Fx.DEATH_SMOKE: [AssetIds.VFX_DEATH_SMOKE, 0.8, 0.8, 1.6, 0.7, false, 0.4],
	Fx.RESPAWN: [AssetIds.VFX_RESPAWN_PORTAL, 0.7, 0.3, 1.4, 0.9, true, 2.0],
	Fx.BOSS_BURST: [AssetIds.VFX_BOSS_BURST, 0.9, 0.5, 2.6, 0.95, true, 0.8],
	Fx.RARE_PICKUP: [AssetIds.VFX_SPARKLE_WHITE, 0.35, 0.5, 1.2, 1.0, true, 3.0],
	Fx.BOUNCE: [AssetIds.VFX_SPARKLE_CYAN, 0.25, 0.4, 0.9, 0.8, true, 0.0],
}

var _sprites: Array[Sprite2D] = []
## Optional position source per slot (effects that stay attached to a head).
var _follow: Array[Callable] = []
var _age := PackedFloat32Array()
var _fx := PackedInt32Array()
var _base_size := PackedFloat32Array()
var _next: int = 0
var _add_material := CanvasItemMaterial.new()


func _ready() -> void:
	_add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i: int in POOL_SIZE:
		var s := Sprite2D.new()
		s.visible = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(s)
		_sprites.append(s)
	_age.resize(POOL_SIZE)
	_fx.resize(POOL_SIZE)
	_base_size.resize(POOL_SIZE)
	_fx.fill(-1)
	_follow.resize(POOL_SIZE)


## Like play(), but the effect tracks `position_source` (returns a world Vector2)
## for its whole lifetime, e.g. a level-up ring that stays on the moving head.
func play_following(fx: Fx, position_source: Callable, size_px: float, tint: Color = Color.WHITE) -> void:
	var i: int = play(fx, position_source.call(), size_px, tint)
	if i >= 0:
		_follow[i] = position_source


## Plays `fx` centred at `at`, sized so the texture spans `size_px` world pixels.
## Returns the pool slot used (-1 if the texture is missing).
func play(fx: Fx, at: Vector2, size_px: float, tint: Color = Color.WHITE) -> int:
	var def: Array = DEFS[fx]
	var tex: Texture2D = Services.assets.texture(def[0])
	if tex == null:
		return -1
	var i: int = _next
	_next = (_next + 1) % POOL_SIZE  # oldest effect is recycled when the pool is full
	var s: Sprite2D = _sprites[i]
	s.texture = tex
	s.position = at
	s.rotation = randf() * TAU if float(def[6]) != 0.0 else 0.0
	s.material = _add_material if def[5] else null
	s.modulate = tint
	s.visible = true
	_age[i] = 0.0
	_fx[i] = fx
	_follow[i] = Callable()
	_base_size[i] = size_px / float(tex.get_width())
	_apply(i)
	return i


## Effects currently playing.
func active_count() -> int:
	var n: int = 0
	for f: int in _fx:
		if f >= 0:
			n += 1
	return n


func _process(delta: float) -> void:
	for i: int in POOL_SIZE:
		if _fx[i] < 0:
			continue
		_age[i] += delta
		var def: Array = DEFS[_fx[i]]
		if _age[i] >= float(def[1]):
			_fx[i] = -1
			_sprites[i].visible = false
			continue
		if _follow[i].is_valid():
			_sprites[i].position = _follow[i].call()
		_sprites[i].rotation += float(def[6]) * delta
		_apply(i)


func _apply(i: int) -> void:
	var def: Array = DEFS[_fx[i]]
	var t: float = clampf(_age[i] / float(def[1]), 0.0, 1.0)
	var e: float = 1.0 - pow(1.0 - t, 3.0)  # ease-out cubic
	var s: float = lerpf(float(def[2]), float(def[3]), e) * _base_size[i]
	_sprites[i].scale = Vector2(s, s)
	var c: Color = _sprites[i].modulate
	c.a = float(def[4]) * (1.0 - t * t)
	_sprites[i].modulate = c
