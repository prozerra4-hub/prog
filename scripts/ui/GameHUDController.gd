class_name GameHUDController
extends Control
## In-game HUD: lays out the HUD components and routes GameSession signals to them.
## Reads state only through signals and read-only getters; never changes gameplay.
##   top-left      HudStatusPanel (clock / showdown, revives), HudZonePanel, KillFeed
##   top-right     HudBossCard + HudLeaderboard
##   bottom-left   Minimap (arena, safe zone, next zone, snakes)
##   bottom-centre HudGrowthBar, ControlsHint (match start)
##   centre        HudToast
##   overlays      NameplateLayer, FloatingTextLayer (combat numbers),
##                 BossIndicator, HurtVignette

const CONTROLS_HINT_SEC: float = 6.0
## Repeated messages about the same thing are throttled to this interval.
const FLOAT_THROTTLE_MSEC: int = 600

var _session: GameSession
var _status: HudStatusPanel
var _boss_card: HudBossCard
var _board: HudLeaderboard
var _growth: HudGrowthBar
var _feed: KillFeed
var _toast: HudToast
var _vignette: HurtVignette
var _hint: ControlsHint
var _fps: Label
var _zone_panel: HudZonePanel
var _floats: FloatingTextLayer
var _last_float: Dictionary = {}  # key -> msec


func bind(session: GameSession) -> void:
	_session = session
	theme = UiTheme.shared()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	session.time_changed.connect(func(sec: int) -> void: _status.set_time(sec, session.is_showdown()))
	session.revives_changed.connect(_status.set_revives)
	session.leaderboard_updated.connect(_board.show_entries)
	session.level_up.connect(_on_level_up)
	session.combat_resolved.connect(_on_swallow)
	session.snake_struck.connect(_on_struck)
	session.snake_died.connect(_on_snake_died)
	session.boss_defeated.connect(_on_boss_defeated)
	session.player_respawn_scheduled.connect(func(delay: float) -> void: _toast.show_message("REVIVING", UiTheme.TEXT, delay))
	session.snake_respawned.connect(_on_snake_respawned)
	session.phase_changed.connect(_on_phase_changed)
	session.snake_eroded.connect(_on_snake_eroded)
	session.strike_blocked.connect(_on_strike_blocked)
	_status.set_time(session.seconds_left(), session.is_showdown())
	_status.set_revives(session.revives_left)
	_hint.show_for(CONTROLS_HINT_SEC)


func _process(_delta: float) -> void:
	if _session == null or _session.player == null:
		return
	_growth.refresh(_session.player.stats)
	_boss_card.refresh(_session.boss, _session.player, _session.balance.combat.even_match_ratio, _session.is_showdown())
	_zone_panel.refresh(_session.zone, _session.player, _session.balance.zone.erosion_per_sec)
	if _zone_panel.just_left_zone(_session.zone, _session.player):
		_toast.show_message("RETURN TO THE ZONE", UiTheme.DANGER, 1.4)
	_fps.visible = Services.settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()


# --- Layout ------------------------------------------------------------------

func _build() -> void:
	_vignette = HurtVignette.new()
	_vignette.build()
	add_child(_vignette)
	var plates := NameplateLayer.new()
	add_child(plates)
	plates.bind(_session)
	_floats = FloatingTextLayer.new()
	add_child(_floats)
	_floats.build()
	var tracker := BossIndicator.new()
	add_child(tracker)
	tracker.bind(_session)

	var frame := MarginContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, 16)
	add_child(frame)
	var area := Control.new()
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(area)

	var left := UiKit.vbox(8)
	_status = HudStatusPanel.new()
	_status.build()
	_status.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_zone_panel = HudZonePanel.new()
	_zone_panel.build()
	_zone_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_feed = KillFeed.new()
	_feed.build()
	left.add_child(_status)
	left.add_child(_zone_panel)
	left.add_child(_feed)
	area.add_child(left)
	left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)

	var minimap := Minimap.new()
	minimap.bind(_session)
	area.add_child(minimap)
	minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	minimap.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var right := UiKit.vbox(10)
	_boss_card = HudBossCard.new()
	_boss_card.build(_session.balance.boss.display_name)
	right.add_child(_boss_card)
	_board = HudLeaderboard.new()
	_board.build(_session.balance.leaderboard_size)
	right.add_child(_board)
	area.add_child(right)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	var bottom := UiKit.vbox(14)
	bottom.alignment = BoxContainer.ALIGNMENT_END
	_hint = ControlsHint.new()
	_hint.build()
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_growth = HudGrowthBar.new()
	_growth.build()
	_growth.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom.add_child(_hint)
	bottom.add_child(_growth)
	area.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var corner := UiKit.vbox(4)
	_fps = UiKit.label("", &"CaptionLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	corner.add_child(_fps)
	var pause_hint := UiKit.hbox(6)
	pause_hint.alignment = BoxContainer.ALIGNMENT_END
	pause_hint.add_child(UiKit.key_cap("ESC"))
	pause_hint.add_child(UiKit.label("PAUSE", &"CaptionLabel"))
	corner.add_child(pause_hint)
	area.add_child(corner)
	corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	corner.grow_vertical = Control.GROW_DIRECTION_BEGIN

	_toast = HudToast.new()
	_toast.build()
	area.add_child(_toast)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = 110


# --- Signal handlers -------------------------------------------------------------

func _on_level_up(actor: SnakeActor, old_level: int, new_level: int) -> void:
	if actor.is_player and new_level > old_level and actor.is_alive:
		_growth.punch()


func _on_swallow(winner: SnakeActor, loser: SnakeActor) -> void:
	if loser.is_boss:
		return  # the boss gets its own toast
	if winner.is_player:
		_feed.push("You swallowed %s" % loser.display_name, UiTheme.ACCENT.lightened(0.3))
		_floats.spawn(loser.head_position(), "SWALLOWED!", UiTheme.GOLD, true)
	elif loser.is_player:
		_feed.push("%s swallowed you" % winner.display_name, UiTheme.DANGER)
	else:
		_feed.push("%s swallowed %s" % [winner.display_name, loser.display_name], UiTheme.TEXT_DIM)


## Strikes involving the player: a feed line plus a number AT the hit point.
func _on_struck(striker: SnakeActor, victim: SnakeActor, kind: StrikeRecord.Kind, xp_taken: int, at: Vector2) -> void:
	var share: int = int(round(100.0 * float(xp_taken) / float(maxi(victim.stats.total_xp + xp_taken, 1))))
	var verb: String = "cut" if kind == StrikeRecord.Kind.BODY_CUT else "bit"
	if victim.is_player:
		_feed.push("%s %s you  -%d%%" % [striker.display_name, verb, share], UiTheme.DANGER)
		_floats.spawn(at, "-%d%%" % share, UiTheme.DANGER, true)
		_vignette.flash()
	elif striker.is_player:
		var target: String = "the boss" if victim.is_boss else victim.display_name
		_feed.push("You %s %s  -%d%%" % [verb, target, share], UiTheme.ACCENT.lightened(0.3))
		_floats.spawn(at, "%s -%d%%" % [verb.to_upper(), share], UiTheme.GOLD, true)


## Contact that did nothing because the target was shielded: say so.
func _on_strike_blocked(striker: SnakeActor, target: SnakeActor, at: Vector2) -> void:
	if (striker.is_player or target.is_player) and _throttle("shield_%d" % target.slot):
		_floats.spawn(at, "SHIELD", Color(0.62, 0.86, 1.0))


func _on_snake_eroded(actor: SnakeActor, xp_lost: int) -> void:
	if not actor.is_player:
		return
	var share: int = int(round(100.0 * float(xp_lost) / float(maxi(actor.stats.total_xp + xp_lost, 1))))
	_floats.spawn(actor.head_position(), "ZONE -%d%%" % share, ZoneRenderer.EDGE)
	_vignette.flash()


func _throttle(key: String) -> bool:
	var now: int = Time.get_ticks_msec()
	if now - int(_last_float.get(key, -100000)) < FLOAT_THROTTLE_MSEC:
		return false
	_last_float[key] = now
	return true


func _on_snake_died(victim: SnakeActor, _killer: SnakeActor) -> void:
	if victim.is_player and _session.revives_left <= 0 and not _session.attract_mode:
		_toast.show_message("OUT OF REVIVES", UiTheme.DANGER, 2.0)


func _on_boss_defeated(by: SnakeActor) -> void:
	_boss_card.mark_defeated()
	if by != null and by.is_player:
		_toast.show_message("BOSS DEFEATED", UiTheme.GOLD, 2.2)


func _on_snake_respawned(actor: SnakeActor) -> void:
	if actor.is_player:
		_toast.show_message("PROTECTED", UiTheme.ACCENT.lightened(0.3), 1.2)


func _on_phase_changed(phase: MatchDirector.Phase) -> void:
	if phase == MatchDirector.Phase.SHOWDOWN:
		_toast.show_message("SHOWDOWN", UiTheme.DANGER, 3.0, "The arena closes in. Defeat the Crimson Tyrant.")
		_status.set_time(_session.seconds_left(), true)
