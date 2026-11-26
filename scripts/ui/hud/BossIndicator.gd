class_name BossIndicator
extends Control
## When the boss is off-screen, a small chevron sits on the screen edge pointing
## at it (with distance), so the main threat and goal is always locatable.

const EDGE_INSET: float = 34.0
## Extra top inset so the marker never sits on the top HUD panels.
const TOP_INSET: float = 150.0
const SIZE: float = 13.0

var _session: GameSession
var _icon: Texture2D
var _font: Font


func bind(session: GameSession) -> void:
	_session = session
	_icon = Services.assets.texture(AssetIds.ICON_SKULL)
	_font = UiTheme.font(600)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _session == null or _session.boss == null or not _session.boss.is_alive:
		return
	var player: SnakeActor = _session.player
	if player == null or not player.is_alive:
		return
	if size.x <= EDGE_INSET * 3.0 or size.y <= TOP_INSET + EDGE_INSET * 2.0:
		return  # not laid out yet
	var xf: Transform2D = get_viewport().get_canvas_transform()
	var boss_screen: Vector2 = xf * _session.boss.head_position()
	var inner := _marker_rect()
	if inner.has_point(boss_screen):
		return
	var center: Vector2 = inner.get_center()
	var dir: Vector2 = (boss_screen - center).normalized()
	# Intersect the ray from the marker area's centre with its edge.
	var tx: float = (inner.size.x * 0.5) / maxf(absf(dir.x), 0.0001)
	var ty: float = (inner.size.y * 0.5) / maxf(absf(dir.y), 0.0001)
	var p: Vector2 = center + dir * minf(tx, ty)
	var stronger: bool = _session.boss.stats.level >= player.stats.level
	var col: Color = UiTheme.DANGER if stronger else UiTheme.GOLD
	var tip: Vector2 = p + dir * SIZE
	var side: Vector2 = dir.orthogonal() * SIZE * 0.75
	draw_colored_polygon(PackedVector2Array([tip, p - dir * SIZE * 0.3 + side, p - dir * SIZE * 0.3 - side]), col)
	var icon_center: Vector2 = p - dir * SIZE * 1.9
	draw_texture_rect(_icon, Rect2(icon_center - Vector2(11, 11), Vector2(22, 22)), false)
	var dist_m: int = int(_session.boss.head_position().distance_to(player.head_position()) / 10.0)
	var text: String = "%dm" % dist_m
	var tsize: Vector2 = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string_outline(_font, icon_center + Vector2(-tsize.x * 0.5, 26), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0.02, 0.04, 0.08, 0.9))
	draw_string(_font, icon_center + Vector2(-tsize.x * 0.5, 26), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)


## Area the marker travels along: inset from the edges, clear of the top HUD panels.
func _marker_rect() -> Rect2:
	return Rect2(Vector2(EDGE_INSET, TOP_INSET), size - Vector2(EDGE_INSET * 2.0, TOP_INSET + EDGE_INSET))
