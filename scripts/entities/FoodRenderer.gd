class_name FoodRenderer
extends Node2D
## Draws every visible orb from a FoodStore in one pass (culled to the view).
## Orbs keep a minimum on-screen size so they stay readable when a huge snake's
## camera is zoomed far out.

const IDLE_PULSE_HZ: float = 0.45
const IDLE_PULSE_AMOUNT: float = 0.045
const AURA_SCALE: float = 2.6
## Smallest drawn orb radius in screen pixels.
const MIN_SCREEN_RADIUS_PX: float = 2.6

var _store: FoodStore
var _pop_duration: float = 0.28
var _remains_lifetime: float = 30.0
var _remains_fade: float = 2.0
var _aura: Texture2D
var _time: float = 0.0


func setup(store: FoodStore, pop_duration: float, remains_lifetime: float, remains_fade: float) -> void:
	_store = store
	_pop_duration = maxf(pop_duration, 0.01)
	_remains_lifetime = remains_lifetime
	_remains_fade = remains_fade
	_aura = Services.assets.texture(AssetIds.VFX_RARE_AURA)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _store == null:
		return
	var xf: Transform2D = get_canvas_transform()
	var zoom: float = maxf(xf.get_scale().x, 0.0001)
	var view: Rect2 = _visible_world_rect(xf).grow(64.0 / zoom)
	var min_r: float = MIN_SCREEN_RADIUS_PX / zoom
	var s: FoodStore = _store
	# Auras first so no orb is covered by another orb's glow.
	for id: int in s.size():
		if s.special[id] == 1 and s.state[id] == FoodStore.State.IDLE and view.has_point(s.pos[id]):
			var pulse: float = 0.5 + 0.5 * sin(_time * 2.2 + s.phase[id])
			var a: float = clampf(s.age[id] / _pop_duration, 0.0, 1.0) * (0.45 + 0.2 * pulse)
			var ar: float = maxf(s.radius[id], min_r) * AURA_SCALE
			draw_texture_rect(_aura, Rect2(s.pos[id] - Vector2(ar, ar), Vector2(ar, ar) * 2.0), false, Color(1, 1, 1, a))
	for id: int in s.size():
		var st: int = s.state[id]
		if st == FoodStore.State.FREE or not view.has_point(s.pos[id]):
			continue
		var age: float = s.age[id]
		if age < 0.0:
			continue
		var scale: float = _ease_out_back(clampf(age / _pop_duration, 0.0, 1.0))
		scale *= 1.0 + IDLE_PULSE_AMOUNT * sin(_time * TAU * IDLE_PULSE_HZ + s.phase[id])
		var alpha: float = 1.0
		if st == FoodStore.State.ABSORBING:
			var t: float = s.absorb_t[id]
			scale *= 1.0 - 0.65 * t * t
		elif s.ambient[id] == 0:
			alpha = clampf((_remains_lifetime - age) / _remains_fade, 0.0, 1.0)
		var tex: Texture2D = s.textures[s.tex_index[id]]
		var r: float = maxf(s.radius[id], min_r)
		var half: float = r / s.sprite_radius[id] * float(tex.get_width()) * 0.5 * scale
		draw_texture_rect(tex, Rect2(s.pos[id] - Vector2(half, half), Vector2(half, half) * 2.0), false, Color(1, 1, 1, alpha))


func _visible_world_rect(xf: Transform2D) -> Rect2:
	var vp: Viewport = get_viewport()
	if vp == null:
		return Rect2(-1e9, -1e9, 2e9, 2e9)
	var inv: Transform2D = xf.affine_inverse()
	var a: Vector2 = inv * Vector2.ZERO
	var b: Vector2 = inv * vp.get_visible_rect().size
	return Rect2(a, Vector2.ZERO).expand(b)


static func _ease_out_back(t: float) -> float:
	var c1: float = 1.20158
	var c3: float = c1 + 1.0
	var u: float = t - 1.0
	return 1.0 + c3 * u * u * u + c1 * u * u
