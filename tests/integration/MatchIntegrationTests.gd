extends TestCase
## Integration tests on a real GameWorld. The session is stepped manually with a
## fixed delta so results are deterministic and per-step cost can be measured.

const WORLD: PackedScene = preload("res://scenes/game/GameWorld.tscn")
const STEP: float = 1.0 / 60.0


func test_match_simulates_without_errors(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var states_seen: Dictionary = {}
	var t0: int = Time.get_ticks_usec()
	for i: int in 900:  # 15 s of play
		s._process(STEP)
		for a: SnakeActor in s.world.snakes:
			if a.brain is SnakeAIController and a.is_alive:
				states_seen[(a.brain as SnakeAIController).state_id()] = true
	var avg_ms: float = float(Time.get_ticks_usec() - t0) / 900.0 / 1000.0
	print("    avg simulation step: %.2f ms (11 AI/boss + player, %d food)" % [avg_ms, s.food.active_count()])
	check_eq(s.world.snakes.size(), 12, "player + 10 AI + boss")
	check(s.food.ambient_count() > int(s.balance.food.target_count * 0.9), "ambient food maintained (%d)" % s.food.ambient_count())
	check(states_seen.size() >= 3, "AI used several states: %s" % str(states_seen.keys()))
	check(avg_ms < 8.0, "simulation step under 8 ms (got %.2f)" % avg_ms)
	check_near(s.time_left, s.balance.match_duration_sec - 15.0, 0.1, "timer counts down")
	_free(s)


func test_high_level_stress_stays_bounded(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	s.player.stats.set_level(99999)
	for a: SnakeActor in s.world.snakes:
		if not a.is_player and not a.is_boss:
			a.stats.set_level(800)
	var t0: int = Time.get_ticks_usec()
	for i: int in 600:
		s._process(STEP)
	var avg_ms: float = float(Time.get_ticks_usec() - t0) / 600.0 / 1000.0
	var cap: int = s.balance.snake.render_segment_cap
	var p: SnakeActor = s.player
	print("    Lv99999 player: radius %.1f, length %.0f px, beads %d, path points %d, step %.2f ms"
			% [p.radius, p.body.length, p.body.count, p.path.point_count(), avg_ms])
	for a: SnakeActor in s.world.snakes:
		check(a.body.count <= cap, "%s bead count within cap" % a.display_name)
		check(a.path.point_count() < 4000, "%s path memory bounded (%d)" % [a.display_name, a.path.point_count()])
	check_eq(p.stats.level, 99999, "max level kept")
	check(avg_ms < 12.0, "high-level step under 12 ms (got %.2f)" % avg_ms)
	_free(s)


func test_small_head_into_big_body_slides_off(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var p: SnakeActor = s.player
	var ai: SnakeActor = _first_ai(s)
	p.spawn(Vector2(-400, 0), 0.0, 50, 0.0)
	var bead: Vector2 = p.body.positions[p.body.count / 2]
	ai.spawn(bead + Vector2(0, -5), PI / 2.0, 10, 0.0)  # weak head rammed into a big body
	_isolate(s, [p, ai])
	s.world.index.rebuild(s.world.snakes)
	var xp_before: int = ai.stats.total_xp
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.kills.size() + r.strikes.size(), 0, "bumping a body never hurts the bumper")
	check(ai.is_alive, "weaker snake survives the bump")
	check_eq(ai.stats.total_xp, xp_before, "no XP lost on a bump")
	var reach: float = ai.head_radius() * s.balance.combat.head_target_scale + p.body.radii[p.body.count / 2] * s.balance.combat.body_hit_scale
	check(ai.head_position().distance_to(bead) >= reach - 0.5, "head pushed out of the body (slide)")
	_free(s)


func test_bigger_mouth_bites_a_chunk_that_becomes_food(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var p: SnakeActor = s.player
	var ai: SnakeActor = _first_ai(s)
	ai.spawn(Vector2(-400, 0), 0.0, 50, 0.0)
	var count_before: int = ai.body.count
	var cut_bead: int = count_before / 2
	var full_before: float = s.balance.snake.full_length_for_level(ai.stats.level)
	var bead: Vector2 = ai.body.positions[cut_bead]
	p.spawn(bead + Vector2(0, -5), PI / 2.0, 60, 0.0)  # mouth pointing into the AI body
	_isolate(s, [p, ai])
	s.world.index.rebuild(s.world.snakes)
	var ai_xp: int = ai.stats.total_xp
	var p_xp: int = p.stats.total_xp
	var food_before: int = s.food.active_count()
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.kills.size(), 0, "a mid-body cut is not a swallow")
	check_eq(r.strikes.size(), 1, "one strike")
	if r.strikes.size() == 1:
		var st: StrikeRecord = r.strikes[0]
		check_eq(st.kind, StrikeRecord.Kind.BODY_CUT, "body contact is a cut")
		check(st.striker == p and st.victim == ai, "player cut the AI")
		check(not st.severed.is_empty(), "bitten-off beads reported")
		check(st.severed[0].distance_to(bead) < ai.radius * 2.0, "the chunk comes from where the mouth landed")
		check(ai.stats.total_xp < ai_xp, "victim lost XP")
		check(ai.body.count < count_before, "victim body is shorter right away")
		# Size is strength: the new level is exactly the one that fits the remaining body.
		var keep_share: float = 1.0 - s.combat.body_cut_share(60, 50)
		var expected: int = s.balance.snake.level_for_length(full_before * keep_share, ai.stats.level_cap)
		check_eq(ai.stats.level, expected, "level drops to match the remaining length")
		check(p.stats.total_xp > p_xp, "striker gained XP")
		check(ai.is_alive and ai.is_invulnerable(), "victim survives, knocked away and protected")
		s.consequences.apply(r)
		check(s.food.active_count() > food_before, "severed part turned into food")
	var again: CombatResult = s.combat.resolve(s.world)
	check_eq(again.strikes.size() + again.kills.size(), 0, "no chain strike in the same contact")
	_free(s)


func test_mouth_only_strikes_in_front(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var p: SnakeActor = s.player
	var ai: SnakeActor = _first_ai(s)
	ai.spawn(Vector2(-400, 0), 0.0, 50, 0.0)
	var bead: Vector2 = ai.body.positions[ai.body.count / 2]
	# Big head touching the body with the BACK of its head (facing away).
	p.spawn(bead + Vector2(0, -p.radius * 1.2), -PI / 2.0, 60, 0.0)
	_isolate(s, [p, ai])
	s.world.index.rebuild(s.world.snakes)
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.strikes.size() + r.kills.size(), 0, "no strike from the back of the head")
	_free(s)


func test_strike_cooldown_makes_lower_body_a_wall(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var p: SnakeActor = s.player
	var ai: SnakeActor = _first_ai(s)
	ai.spawn(Vector2(-400, 0), 0.0, 50, 0.0)
	var mid: int = ai.body.count / 2
	var bead: Vector2 = ai.body.positions[mid]
	p.spawn(bead + Vector2(0, -5), PI / 2.0, 60, 0.0)  # mouth into a lower body...
	p.start_strike_cooldown(1.0)                       # ...right after another strike
	_isolate(s, [p, ai])
	s.world.index.rebuild(s.world.snakes)
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.strikes.size() + r.kills.size(), 0, "no strike while on cooldown")
	var reach: float = p.head_radius() * s.balance.combat.head_target_scale + ai.body.radii[mid] * s.balance.combat.body_hit_scale
	check(p.head_position().distance_to(bead) >= reach - 0.5, "the lower body is a wall, not passed through")
	_free(s)


func test_calm_boss_notice_level(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var brain := s.boss.brain as BossController
	var p: SnakeActor = s.player
	var notice: int = brain.notice_level()
	check_eq(notice, ceili(float(s.balance.boss.level) * s.balance.boss.min_target_level_ratio), "notice level from the boss definition")
	p.spawn(Vector2(-2500, 0), 0.0, notice - 1, 0.0)
	check(not brain.will_strike(p), "calm boss ignores a snake just below its notice level")
	p.spawn(Vector2(-2500, 0), 0.0, notice, 0.0)
	check(brain.will_strike(p), "calm boss strikes at its notice level")
	brain.set_enraged(true, 1.0)
	p.spawn(Vector2(-2500, 0), 0.0, 1, 0.0)
	check(brain.will_strike(p), "enraged boss strikes anything")
	_free(s)


func test_head_bite_scales_with_gap(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var p: SnakeActor = s.player
	var ai: SnakeActor = _first_ai(s)
	p.spawn(Vector2(0, 0), 0.0, 60, 0.0)
	# AI head right in front of the player's mouth, facing it (its body trails away).
	ai.spawn(Vector2(p.head_radius() * 1.1, 0), PI, 50, 0.0)
	_isolate(s, [p, ai])
	s.world.index.rebuild(s.world.snakes)
	var ai_xp: int = ai.stats.total_xp
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.strikes.size(), 1, "head contact is a bite")
	if r.strikes.size() == 1:
		check_eq(r.strikes[0].kind, StrikeRecord.Kind.HEAD_BITE, "kind = head bite")
		var lost: float = float(ai_xp - ai.stats.total_xp) / float(ai_xp)
		check(lost > 0.1 and lost < 0.6, "a 1.2x bite takes a moderate share (%.2f)" % lost)
	_free(s)


func test_neck_strike_swallows(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var p: SnakeActor = s.player
	var ai: SnakeActor = _first_ai(s)
	ai.spawn(Vector2(-400, 0), 0.0, 40, 0.0)
	var neck: Vector2 = ai.body.positions[1]
	p.spawn(neck + Vector2(0, -5), PI / 2.0, 60, 0.0)
	_isolate(s, [p, ai])
	s.world.index.rebuild(s.world.snakes)
	var ai_xp: int = ai.stats.total_xp
	var xp_before: int = p.stats.total_xp
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.kills.size(), 1, "a strike at the neck swallows")
	if r.kills.size() == 1:
		check(r.kills[0].victim == ai and r.kills[0].killer == p, "player swallowed the AI")
		s.consequences.apply_kill(r.kills[0])
		check(not ai.is_alive, "AI dead")
		check(p.stats.total_xp >= xp_before + s.combat.kill_reward_for_xp(ai_xp), "swallow rewarded")
		check_eq(p.stats.kills, 1, "kill counted")
	_free(s)


func test_equal_levels_bounce(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var p: SnakeActor = s.player
	var ai: SnakeActor = _first_ai(s)
	p.spawn(Vector2(0, 0), 0.0, 30, 0.0)
	ai.spawn(Vector2(p.head_radius() * 1.2, 0), PI, 30, 0.0)
	_isolate(s, [p, ai])
	s.world.index.rebuild(s.world.snakes)
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.kills.size() + r.strikes.size(), 0, "even head-on: no damage")
	check(p.is_invulnerable() and ai.is_invulnerable(), "both bounce with brief protection")
	_free(s)


func test_cut_short_snake_is_really_weaker(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var a: SnakeActor = _first_ai(s)
	var p: SnakeActor = s.player
	_isolate(s, [p, a])
	a.spawn(Vector2(-600, 0), 0.0, 400, 0.0)
	a.cut_at(a.body.count / 3)  # lose two thirds of the body
	check(a.stats.level < 100, "a snake cut to a third is far below its old level (now Lv%d)" % a.stats.level)
	# Now a Lv150 player can cut what used to be a Lv400 snake.
	var bead: Vector2 = a.body.positions[a.body.count / 2]
	a._invulnerable_left = 0.0
	p.spawn(bead + Vector2(0, -5), PI / 2.0, 150, 0.0)
	s.world.index.rebuild(s.world.snakes)
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.strikes.size() + r.kills.size(), 1, "the smaller-but-intact snake wins")
	_free(s)


func test_shielded_target_reports_block(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var p: SnakeActor = s.player
	var ai: SnakeActor = _first_ai(s)
	_isolate(s, [p, ai])
	ai.spawn(Vector2(-400, 0), 0.0, 20, 5.0)  # shielded
	var bead: Vector2 = ai.body.positions[ai.body.count / 2]
	p.spawn(bead + Vector2(0, -5), PI / 2.0, 60, 0.0)
	var blocked: Array = []
	s.combat.blocked.connect(func(st: SnakeActor, t: SnakeActor, _at: Vector2) -> void: blocked.append([st, t]))
	s.world.index.rebuild(s.world.snakes)
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.strikes.size() + r.kills.size(), 0, "shielded snake is not cut")
	check_eq(blocked.size(), 1, "the block is reported (UI shows SHIELD)")
	_free(s)


func test_zone_phases_shrink_inside_each_other(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var z: ZoneSystem = s.zone
	var full: float = s.balance.arena.radius
	check_eq(z.state, ZoneSystem.State.WAITING, "the match starts with the first zone wait")
	check(z.next_radius < full, "next circle announced from the start")
	check(z.next_center.distance_to(z.center) + z.next_radius <= z.radius + 0.5, "next circle lies inside the current one")
	_isolate(s, [s.player])
	s.player.grant_invulnerability(999.0)
	var p1: ZonePhase = s.balance.zone.phases[0]
	for i: int in int((p1.wait_sec + p1.shrink_sec + 0.5) * 60.0):
		s._process(STEP)
	check_near(z.radius, full * p1.radius_ratio, 1.0, "phase 1 shrinks to its target radius")
	check_eq(z.phase_index, 1, "phase 2 announced")
	_free(s)


func test_zone_erosion_burns_snakes_outside(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var ai: SnakeActor = _first_ai(s)
	_isolate(s, [ai, s.player])
	s.player.grant_invulnerability(999.0)
	s.zone.radius = 300.0  # force a tiny zone
	s.zone.center = Vector2.ZERO
	ai.spawn(Vector2(2500, 0), 0.0, 200, 0.0)
	ai.brain = SnakeBrain.new()  # stand still-ish: keep heading, no AI steering back
	var level_before: int = ai.stats.level
	var length_before: float = ai.body.length
	for i: int in 60:
		s._process(STEP)
	check(ai.stats.level < level_before, "level burns down outside the zone")
	check(ai.body.length < length_before, "body burns from the tail")
	for i: int in 60 * 30:
		s._process(STEP)
		if not ai.is_alive:
			break
	check(not ai.is_alive, "a snake left outside burns to death")
	_free(s)


func test_spawns_land_inside_the_next_zone(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	for i: int in 20:
		var p: Vector2 = s.spawner.find_safe_point(s.world.index)
		check(p.distance_to(s.zone.next_center) <= s.zone.next_radius + 1.0, "spawn %d inside the next circle" % i)
	_free(s)


func test_player_revives_then_eliminated(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var results: Array[MatchResult] = []
	s.game_over.connect(func(r: MatchResult) -> void: results.append(r))
	var revives_start: int = s.revives_left
	for death: int in revives_start + 1:
		s.consequences.apply_kill(KillRecord.new(s.player, null, s.player.head_position()))
		for i: int in 200:  # let the death finish and the respawn happen
			s._process(STEP)
		if death < revives_start:
			check(s.player.is_alive, "respawned after death %d" % (death + 1))
			check_eq(s.revives_left, revives_start - death - 1, "revive consumed")
	check_eq(results.size(), 1, "game over emitted once")
	if results.size() == 1:
		check_eq(results[0].outcome, MatchResult.Outcome.ELIMINATED, "eliminated outcome")
	_free(s)


func test_boss_kill_is_victory(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var results: Array[MatchResult] = []
	s.game_over.connect(func(res: MatchResult) -> void: results.append(res))
	var boss: SnakeActor = s.boss
	_isolate(s, [s.player, boss])
	var neck: Vector2 = boss.body.positions[1]
	s.player.spawn(neck + Vector2(0, -6), PI / 2.0, boss.stats.level * 2, 0.0)
	s.world.index.rebuild(s.world.snakes)
	s.consequences.apply(s.combat.resolve(s.world))
	for i: int in 120:
		s._process(STEP)
	check(not boss.is_alive, "boss swallowed by a neck strike")
	check_eq(results.size(), 1, "match ended")
	if results.size() == 1:
		check_eq(results[0].outcome, MatchResult.Outcome.VICTORY, "victory outcome")
		check(results[0].boss_defeated, "result records boss kill")
		check(results[0].score > 0, "score computed")
	_free(s)


func test_boss_fight_takes_several_strikes(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var boss: SnakeActor = s.boss
	var p: SnakeActor = s.player
	_isolate(s, [p, boss])
	var strikes: int = 0
	for attempt: int in 20:
		if not boss.is_alive:
			break
		var bead: Vector2 = boss.body.positions[boss.body.count / 2]
		p.spawn(bead + Vector2(0, -6), PI / 2.0, maxi(p.stats.level, 1300), 0.0)
		boss._invulnerable_left = 0.0  # skip the post-strike protection window
		s.world.index.rebuild(s.world.snakes)
		var r: CombatResult = s.combat.resolve(s.world)
		strikes += r.strikes.size()
		s.consequences.apply(r)
	check(strikes >= 2, "boss survives at least two cuts first (got %d)" % strikes)
	check(not boss.is_alive, "repeated cuts finish the boss")
	_free(s)


func test_boss_body_is_safe_but_its_jaws_are_not(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var boss: SnakeActor = s.boss
	var p: SnakeActor = s.player
	_isolate(s, [p, boss])
	var bead: Vector2 = boss.body.positions[boss.body.count / 2]
	p.spawn(bead + Vector2(0, -6), PI / 2.0, 10, 0.0)
	s.world.index.rebuild(s.world.snakes)
	var r: CombatResult = s.combat.resolve(s.world)
	check(r.kills.is_empty() and p.is_alive, "bumping the boss body is survivable")
	# Outside the showdown the boss ignores small fry even on contact...
	p.spawn(Vector2(-2500, 0), 0.0, 10, 0.0)
	var neck0: Vector2 = p.body.positions[1]
	boss.spawn(neck0 + Vector2(0, -8), PI / 2.0, s.balance.boss.level, 0.0)
	s.world.index.rebuild(s.world.snakes)
	r = s.combat.resolve(s.world)
	check(r.kills.is_empty() and r.strikes.is_empty(), "the calm boss ignores a tiny snake")
	# ...but enraged (showdown) its mouth swallows a small player.
	(boss.brain as BossController).set_enraged(true, 1.0)
	p.spawn(Vector2(-2500, 0), 0.0, 10, 0.0)
	var neck: Vector2 = p.body.positions[1]
	boss.spawn(neck + Vector2(0, -8), PI / 2.0, s.balance.boss.level, 0.0)
	s.world.index.rebuild(s.world.snakes)
	r = s.combat.resolve(s.world)
	check(r.kills.size() == 1 and r.kills[0].victim == p, "the boss swallows a small player")
	_free(s)


func test_boss_weak_spot_only_in_showdown(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var boss: SnakeActor = s.boss
	var p: SnakeActor = s.player
	_isolate(s, [p, boss])
	var weak: int = -1
	for i: int in range(boss.body.count - 1, -1, -1):
		if boss.is_weak_spot(i):
			weak = i
			break
	check(weak >= 0, "boss has weak-spot bands on its rear half")
	var bead: Vector2 = boss.body.positions[weak]
	p.spawn(bead + Vector2(0, -6), PI / 2.0, 50, 0.0)  # far weaker than the boss
	s.world.index.rebuild(s.world.snakes)
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.strikes.size(), 0, "before the showdown a weak player cannot cut the boss")
	(boss.brain as BossController).set_enraged(true, 1.0)
	p.spawn(bead + Vector2(0, -6), PI / 2.0, 50, 0.0)
	s.world.index.rebuild(s.world.snakes)
	var level_before: int = boss.stats.level
	r = s.combat.resolve(s.world)
	check_eq(r.strikes.size(), 1, "in the showdown the gold tail can be cut at any level")
	check(boss.stats.level < level_before, "the boss shrinks and its level drops (Lv%d)" % boss.stats.level)
	_free(s)


func test_rivals_cannot_bite_the_boss(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var boss: SnakeActor = s.boss
	var ai: SnakeActor = _first_ai(s)
	_isolate(s, [ai, boss])
	boss.stats.set_level(300)  # weakened boss
	var bead: Vector2 = boss.body.positions[boss.body.count / 2]
	ai.spawn(bead + Vector2(0, -6), PI / 2.0, s.spawner.ai_level_cap(), 0.0)
	s.world.index.rebuild(s.world.snakes)
	var r: CombatResult = s.combat.resolve(s.world)
	check_eq(r.strikes.size() + r.kills.size(), 0, "a rival only slides off the boss")
	_free(s)


func test_boss_stays_apex(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var results: Array[MatchResult] = []
	s.game_over.connect(func(r: MatchResult) -> void: results.append(r))
	var cap: int = s.spawner.ai_level_cap()
	var ai: SnakeActor = _first_ai(s)
	ai.stats.add_xp(9999999)
	check_eq(ai.stats.level, cap, "AI growth stops below the boss")
	s.boss.on_kill_reward(9999999)
	check_eq(s.boss.stats.level, s.balance.boss.level, "boss level is fixed")
	# Even if an AI somehow lands the kill, the match must not end as a victory.
	s.consequences.apply_kill(KillRecord.new(s.boss, ai, s.boss.head_position()))
	for i: int in 120:
		s._process(STEP)
	check_eq(results.size(), 0, "boss killed by an AI does not end the match")
	_free(s)


func test_time_up_starts_showdown_not_game_over(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var results: Array[MatchResult] = []
	s.game_over.connect(func(res: MatchResult) -> void: results.append(res))
	var full_radius: float = s.zone.radius
	s.time_left = 0.2
	for i: int in 30:
		s._process(STEP)
	check(s.is_showdown(), "regular time out -> SHOWDOWN")
	check_eq(results.size(), 0, "the match did not end at 0:00")
	var rivals_alive: int = 0
	for a: SnakeActor in s.world.snakes:
		if not a.is_player and not a.is_boss and a.is_alive:
			rivals_alive += 1
	check_eq(rivals_alive, 0, "rivals dissolved into food")
	check((s.boss.brain as BossController).enraged, "boss enraged")
	for i: int in 300:
		s._process(STEP)
	check(s.zone.radius < full_radius * 0.9, "the final zone is closing in (%.0f)" % s.zone.radius)
	_free(s)


func test_showdown_timeout_ends_match(tree: SceneTree) -> void:
	var s: GameSession = await _new_session(tree)
	var results: Array[MatchResult] = []
	s.game_over.connect(func(res: MatchResult) -> void: results.append(res))
	s.time_left = 0.05
	for i: int in 5:
		s._process(STEP)
	check(s.is_showdown(), "in showdown")
	s.player.grant_invulnerability(999.0)
	s.time_left = 0.2
	for i: int in 40:
		s._process(STEP)
	check_eq(results.size(), 1, "showdown clock out ends the match")
	if results.size() == 1:
		check_eq(results[0].outcome, MatchResult.Outcome.TIME_UP, "boss still standing -> TIME_UP (tyrant endures)")
	_free(s)


func test_screen_flow_menu_game_restart_menu(tree: SceneTree) -> void:
	var main: Main = load("res://scenes/main/Main.tscn").instantiate()
	tree.root.add_child(main)
	await tree.create_timer(0.5).timeout
	check(main.get_child(0) is MainMenuController, "boots into the main menu")
	for round_i: int in 3:  # start -> restart -> restart
		main.start_game()
		await tree.create_timer(0.7).timeout
		check(main.get_child(0) is GameScreenController, "game screen active (round %d)" % round_i)
		var screen := main.get_child(0) as GameScreenController
		if screen != null:
			check(screen.session().is_running(), "match running after transition (round %d)" % round_i)
	(main.get_child(0) as GameScreenController).session().pause()
	check(tree.paused, "pause freezes the tree")
	main.show_menu()
	await tree.create_timer(0.7).timeout
	check(not tree.paused, "returning to menu unpauses")
	check(main.get_child(0) is MainMenuController, "back at the main menu")
	var screens: int = 0
	for c: Node in main.get_children():
		if c is GameScreenController or c is MainMenuController:
			screens += 1
	check_eq(screens, 1, "old screens freed (no stacking)")
	main.queue_free()
	await tree.process_frame


# --- helpers -----------------------------------------------------------------

func _new_session(tree: SceneTree) -> GameSession:
	var s: GameSession = WORLD.instantiate()
	s.process_mode = Node.PROCESS_MODE_DISABLED  # stepped manually
	tree.root.add_child(s)
	await tree.process_frame
	var skin: SnakeSkin = load("res://resources/skins/azure.tres")
	s.start(skin)
	return s


func _first_ai(s: GameSession) -> SnakeActor:
	for a: SnakeActor in s.world.snakes:
		if not a.is_player and not a.is_boss:
			return a
	return null


## Takes every other snake out of play so a staged contact is the only one.
func _isolate(s: GameSession, keep: Array) -> void:
	for a: SnakeActor in s.world.snakes:
		if not keep.has(a):
			a.is_alive = false
			a.visible = false


func _free(s: GameSession) -> void:
	s.get_tree().paused = false
	s.queue_free()
