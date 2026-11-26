class_name Minimap
extends Control
## Bottom-left overview: arena wall, the safe zone (lit), the next circle (dashed),
## the boss (red), rivals (grey; red if they can cut you) and you (accent).
## Answers "where is the zone going and how far is it" at a glance.

const SIZE_PX: float = 156.0
const DASHES: int = 40

var _session: GameSession


func bind(session: GameSession) -> void:
	_session = session
	custom_minimum_size = Vector2(SIZE_PX, SIZE_PX)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _session == null:
		return
	var half: float = SIZE_PX * 0.5
	var c := Vector2(half, half)
	var arena_r: float = _session.balance.arena.radius
	var k: float = (half - 3.0) / arena_r  # world px -> map px
	var zone: ZoneSystem = _session.zone
	# Arena disc and wall.
	draw_circle(c, half - 2.0, Color(0.03, 0.05, 0.10, 0.86), true, -1.0, true)
	# Safe zone (lit) and its edge.
	draw_circle(c + zone.center * k, zone.radius * k, Color(0.12, 0.2, 0.36, 0.9), true, -1.0, true)
	draw_arc(c + zone.center * k, zone.radius * k, 0.0, TAU, 64, ZoneRenderer.EDGE, 1.5, true)
	if zone.state != ZoneSystem.State.DONE and zone.next_radius < zone.radius - 1.0:
		var step: float = TAU / float(DASHES)
		for i: int in range(0, DASHES, 2):
			draw_arc(c + zone.next_center * k, zone.next_radius * k, step * i, step * (i + 1), 3, Color(1, 1, 1, 0.8), 1.0, true)
	draw_arc(c, half - 2.0, 0.0, TAU, 64, UiTheme.PANEL_BORDER.lightened(0.2), 1.5, true)
	# Snakes.
	var player: SnakeActor = _session.player
	for s: SnakeActor in _session.world.snakes:
		if not s.is_alive or s == player:
			continue
		var p: Vector2 = c + s.head_position() * k
		if s.is_boss:
			draw_circle(p, 4.5, UiTheme.DANGER, true, -1.0, true)
			draw_arc(p, 6.5, 0.0, TAU, 16, Color(UiTheme.DANGER, 0.6), 1.0, true)
		else:
			var threat: bool = player != null and s.stats.level > player.stats.level
			draw_circle(p, 2.2, Color(UiTheme.DANGER, 0.8) if threat else Color(0.7, 0.76, 0.86, 0.6), true, -1.0, true)
	if player != null and player.is_alive:
		var pp: Vector2 = c + player.head_position() * k
		var dir: Vector2 = player.heading()
		var tri := PackedVector2Array([pp + dir * 6.0, pp + dir.rotated(2.5) * 4.5, pp + dir.rotated(-2.5) * 4.5])
		draw_colored_polygon(tri, UiTheme.ACCENT.lightened(0.3))
