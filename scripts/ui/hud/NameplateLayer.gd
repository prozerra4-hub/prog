class_name NameplateLayer
extends Control
## Screen-space name + level tags above every visible snake head. Kept out of the
## world canvas so text stays a constant, readable size at any zoom.
## Level colour encodes the fight outcome relative to the player:
##   red = it can cut you, green = you can cut it, white = equal (bounce).
## Heads that can bite the player also get a thin ring (a shape cue, so the threat
## does not rely on colour alone). Tags sit on the side of the head away from the
## body so they never cover the snake itself.

const GAP_PX: float = 8.0
const RING_WIDTH: float = 2.0
## Hide tags of snakes whose head is smaller than this on screen.
const TINY_HEAD_PX: float = 6.0

var _session: GameSession
var _plates: Dictionary = {}  # SnakeActor -> {root, name, level, crown}
var _leader: SnakeActor
## Screen-space rings to draw this frame: [center, radius, alpha].
var _rings: Array = []


func bind(session: GameSession) -> void:
	_session = session
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	if _session == null:
		return
	_leader = _find_leader()
	var xf: Transform2D = get_viewport().get_canvas_transform()
	var zoom: float = xf.get_scale().x
	var view := Rect2(Vector2.ZERO, get_viewport_rect().size).grow(40.0)
	var player: SnakeActor = _session.player
	var placed: Array[Rect2] = []
	_rings.clear()
	for actor: SnakeActor in _priority_order():
		var plate: Dictionary = _plate_for(actor)
		var root: Control = plate["root"]
		var screen: Vector2 = xf * actor.head_position()
		if not actor.is_alive or not view.has_point(screen):
			root.visible = false
			continue
		# Snakes that look tiny next to you are fodder: no tag clutter for them.
		var tiny: bool = actor.head_radius() * zoom < TINY_HEAD_PX
		if tiny and actor != player and not actor.is_boss and (player == null or not _can_cut_player(actor, player)):
			root.visible = false
			continue
		root.visible = true
		var level_label: Label = plate["level"]
		level_label.text = UiFormat.level(actor.stats.level)
		level_label.add_theme_color_override(&"font_color", _level_color(actor, player))
		(plate["crown"] as Control).visible = actor == _leader
		root.reset_size()
		var head_px: float = actor.head_radius() * zoom
		var lift: float = head_px + GAP_PX
		# Above the head, unless the body trails upward on screen: then below it.
		var below: bool = _body_trails_upward(actor)
		var rect := Rect2(screen - Vector2(root.size.x * 0.5, lift + root.size.y), root.size)
		if below:
			rect.position.y = screen.y + lift
		# Declutter: higher-priority tags keep their spot, others step away.
		for i: int in 4:
			var hit: bool = false
			for other: Rect2 in placed:
				if rect.intersects(other):
					rect.position.y = (other.end.y + 2.0) if below else (other.position.y - rect.size.y - 2.0)
					hit = true
			if not hit:
				break
		if player != null and actor != player and _can_cut_player(actor, player):
			var dist: float = actor.head_position().distance_to(player.head_position())
			var near: float = clampf(1.0 - dist / 1500.0, 0.25, 1.0)
			_rings.append([screen, head_px + 5.0, near])
		# Keep tags fully on screen (a head near the edge must not clip its name).
		var screen_size: Vector2 = get_viewport_rect().size
		rect.position.x = clampf(rect.position.x, 4.0, maxf(4.0, screen_size.x - rect.size.x - 4.0))
		rect.position.y = clampf(rect.position.y, 4.0, maxf(4.0, screen_size.y - rect.size.y - 4.0))
		placed.append(rect)
		root.position = rect.position.round()
		root.modulate.a = 0.55 if actor.is_invulnerable() else 1.0
	queue_redraw()


func _draw() -> void:
	for ring: Array in _rings:
		var c: Color = UiTheme.DANGER
		c.a = 0.75 * float(ring[2])
		draw_arc(ring[0], ring[1], 0.0, TAU, 48, c, RING_WIDTH, true)


## True when the first stretch of body leaves the head upward on screen, i.e. a tag
## above the head would sit on top of the snake's own body.
func _body_trails_upward(actor: SnakeActor) -> bool:
	if actor.body.count == 0:
		return false
	var sample: Vector2 = actor.body.positions[mini(4, actor.body.count - 1)]
	var d: Vector2 = sample - actor.head_position()
	return d.y < 0.0 and -d.y > absf(d.x) * 0.5


func _can_cut_player(actor: SnakeActor, player: SnakeActor) -> bool:
	if not player.is_alive:
		return false
	var even: float = _session.balance.combat.even_match_ratio
	return float(actor.stats.level) > float(player.stats.level) * (1.0 + even)


## Player first, then boss, then everyone else: earlier entries win label space.
func _priority_order() -> Array[SnakeActor]:
	var out: Array[SnakeActor] = []
	if _session.player != null:
		out.append(_session.player)
	if _session.boss != null:
		out.append(_session.boss)
	for a: SnakeActor in _session.world.snakes:
		if a != _session.player and a != _session.boss:
			out.append(a)
	return out


## Highest-level contestant (the boss is not a contestant) wears the crown.
func _find_leader() -> SnakeActor:
	var best: SnakeActor = null
	for a: SnakeActor in _session.world.snakes:
		if a.is_boss or not a.is_alive:
			continue
		if best == null or a.stats.level > best.stats.level:
			best = a
	return best


func _level_color(actor: SnakeActor, player: SnakeActor) -> Color:
	if actor.is_player:
		return UiTheme.ACCENT.lightened(0.35)
	if player == null or not player.is_alive:
		return UiTheme.TEXT
	if _can_cut_player(actor, player):
		return UiTheme.DANGER
	if actor.stats.level < player.stats.level:
		return UiTheme.SUCCESS
	return UiTheme.TEXT


func _plate_for(actor: SnakeActor) -> Dictionary:
	if _plates.has(actor):
		return _plates[actor]
	var root := VBoxContainer.new()
	root.add_theme_constant_override(&"separation", -4)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_row := UiKit.hbox(4)
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var crown := UiKit.icon(AssetIds.ICON_CROWN, 16.0)
	crown.visible = false
	var name_label := _outlined(actor.display_name if not actor.is_player else "YOU", 13 if not actor.is_boss else 15, 600)
	name_label.add_theme_color_override(&"font_color", Color(1, 1, 1, 0.82) if not actor.is_boss else UiTheme.GOLD)
	name_row.add_child(crown)
	name_row.add_child(name_label)
	var level := _outlined("", 18 if (actor.is_player or actor.is_boss) else 16, 700)
	root.add_child(name_row)
	root.add_child(level)
	add_child(root)
	var plate := {"root": root, "name": name_label, "level": level, "crown": crown}
	_plates[actor] = plate
	return plate


static func _outlined(text: String, font_size: int, weight: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override(&"font", UiTheme.font(weight))
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_outline_color", Color(0.02, 0.04, 0.08, 0.85))
	l.add_theme_constant_override(&"outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
