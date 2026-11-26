extends TestCase
## Unit tests for node-free gameplay logic.


func test_level_curve_monotonic_and_invertible() -> void:
	var levels := LevelSystem.new(_curve())
	var prev: int = -1
	for lv: int in [1, 2, 3, 10, 57, 100, 999, 1000, 12345, 99998, 99999]:
		var total: int = levels.total_xp_for_level(lv)
		check(total > prev, "cumulative XP must increase at level %d" % lv)
		prev = total
		check_eq(levels.level_for_total_xp(total), lv, "inverse at exact threshold for level %d" % lv)
		if lv > 1:
			check_eq(levels.level_for_total_xp(total - 1), lv - 1, "one XP short of level %d" % lv)


func test_required_xp_matches_formula() -> void:
	var c := _curve()
	var levels := LevelSystem.new(c)
	for lv: int in [1, 5, 50, 500, 5000]:
		var expected: int = maxi(1, int(round(c.base_xp + pow(float(lv), c.growth_exponent) * c.growth_factor)))
		check_eq(levels.required_xp(lv), expected, "required_xp(%d)" % lv)


func test_max_level_clamp_and_no_overflow() -> void:
	var levels := LevelSystem.new(_curve())
	var stats := SnakeStats.new(levels)
	stats.add_xp(9223372036854775000)  # near int64 max
	check_eq(stats.level, 99999, "huge XP clamps to max level")
	check(stats.total_xp <= levels.max_total_xp(), "total XP clamped to table max")
	stats.add_xp(1000)
	check_eq(stats.level, 99999, "stays at max level")


func test_multi_level_gain_emits_once_with_full_jump() -> void:
	var levels := LevelSystem.new(_curve())
	var stats := SnakeStats.new(levels)
	var seen: Array = []
	stats.level_changed.connect(func(o: int, n: int) -> void: seen.append([o, n]))
	var gained: int = stats.add_xp(levels.total_xp_for_level(40))
	check_eq(gained, 39, "levels gained from one big pickup")
	check_eq(stats.level, 40, "level after big pickup")
	check_eq(seen.size(), 1, "one level_changed signal per XP grant")
	check_eq(seen[0], [1, 40], "signal carries old and new level")


func test_xp_penalty_keeps_ratio() -> void:
	var levels := LevelSystem.new(_curve())
	var stats := SnakeStats.new(levels)
	stats.set_level(500)
	var before: int = stats.total_xp
	stats.apply_xp_penalty(0.6)
	check_eq(stats.total_xp, int(float(before) * 0.6), "penalty keeps 60% XP")
	check(stats.level < 500 and stats.level >= 1, "level drops but stays valid")
	check_eq(stats.peak_level, 500, "peak level remembered")


func test_level_cap_clamps_growth() -> void:
	var levels := LevelSystem.new(_curve())
	var stats := SnakeStats.new(levels)
	stats.level_cap = 920
	stats.add_xp(levels.total_xp_for_level(5000))
	check_eq(stats.level, 920, "XP gain stops at the cap")
	stats.set_level(3000)
	check_eq(stats.level, 920, "set_level respects the cap too")


func test_path_extrapolates_instead_of_stacking() -> void:
	var path := SnakePathHistory.new()
	path.reset(Vector2.ZERO, Vector2.RIGHT, 40.0, 4.0)  # short history
	var out := PackedVector2Array()
	path.sample_evenly(10.0, 20, out)  # needs 200 px of body
	for i: int in range(1, 20):
		check_near(out[i - 1].distance_to(out[i]), 10.0, 0.05, "bead %d spacing kept past the recorded trail" % i)
	check_near(out[19].x, -200.0, 0.5, "tail extends straight back")


func test_food_xp_scales_with_level() -> void:
	var levels := LevelSystem.new(_curve())
	var small := SnakeStats.new(levels)
	var big := SnakeStats.new(levels)
	big.set_level(1000)
	var before_small: int = small.total_xp
	var before_big: int = big.total_xp
	small.add_food_xp(1)
	big.add_food_xp(1)
	var gain_small: float = float(small.total_xp - before_small) / float(levels.required_xp(1))
	var gain_big: float = float(big.total_xp - before_big) / float(levels.required_xp(1000))
	check(big.total_xp - before_big > small.total_xp - before_small, "big snakes get more XP per orb")
	check_near(gain_big, gain_small, 0.2, "an orb is worth about the same share of a level at any size")


func test_bite_fraction_grows_with_gap() -> void:
	var rules := CombatRules.new()
	var c := CombatSystem.new(rules)
	check_near(c.bite_fraction(110, 100), rules.bite_base_fraction + rules.bite_fraction_per_ratio * 0.1, 0.0001, "small gap = small bite")
	check(c.bite_fraction(400, 100) < 1.0, "4x gap is still a bite")
	check_near(c.bite_fraction(700, 100), rules.head_bite_max_share, 0.0001, "a head bite is capped: it never swallows alone")
	check(c.body_cut_share(200, 100) > c.body_cut_share(110, 100), "bigger gap bites a bigger chunk")
	check_near(c.body_cut_share(5000, 100), rules.body_cut_max_share, 0.0001, "chunk size is capped")


func test_level_for_length_inverts_full_length() -> void:
	var t := SnakeTuning.new()
	for lv: int in [1, 7, 50, 333, 1000, 5000]:
		var length: float = t.full_length_for_level(lv)
		check_eq(t.level_for_length(length, 99999), lv, "length -> level round trip at Lv%d" % lv)
		if lv > 1:
			var between: float = (length + t.full_length_for_level(lv - 1)) * 0.5
			check_eq(t.level_for_length(between, 99999), lv - 1, "between two levels -> the lower one at Lv%d" % lv)


func test_size_gap_is_dramatic() -> void:
	var t := SnakeTuning.new()
	check(t.radius_for_level(1000) / t.radius_for_level(10) >= 3.0, "Lv1000 is at least 3x wider than Lv10")
	check(t.turn_rate_for_radius(t.radius_for_level(1000)) < t.turn_rate_for_radius(t.radius_for_level(10)) * 0.6, "giants turn much slower")


func test_path_samples_are_evenly_spaced_on_a_line() -> void:
	var path := SnakePathHistory.new()
	path.reset(Vector2.ZERO, Vector2.RIGHT, 200.0, 4.0)
	for i: int in 100:
		path.push_head(Vector2(float(i + 1) * 3.0, 0.0), 4.0)
	var out := PackedVector2Array()
	var placed: int = path.sample_evenly(10.0, 20, out)
	check_eq(placed, 20, "all samples placed")
	for i: int in 20:
		check_near(out[i].x, 300.0 - 10.0 * float(i + 1), 0.01, "bead %d x" % i)
		check_near(out[i].y, 0.0, 0.001, "bead %d y" % i)


func test_path_follows_a_corner() -> void:
	var path := SnakePathHistory.new()
	path.reset(Vector2.ZERO, Vector2.RIGHT, 50.0, 1.0)
	for i: int in 100:
		path.push_head(Vector2(float(i + 1), 0.0), 1.0)
	for i: int in 100:
		path.push_head(Vector2(100.0, float(i + 1)), 1.0)
	var out := PackedVector2Array()
	path.sample_evenly(50.0, 3, out)
	check_near(out[0].distance_to(Vector2(100, 50)), 0.0, 0.01, "50 behind is on the vertical leg")
	check_near(out[1].distance_to(Vector2(100, 0)), 0.0, 0.01, "100 behind is the corner")
	check_near(out[2].distance_to(Vector2(50, 0)), 0.0, 0.01, "150 behind is on the horizontal leg")


func test_path_memory_is_bounded() -> void:
	var path := SnakePathHistory.new()
	path.reset(Vector2.ZERO, Vector2.RIGHT, 300.0, 2.0)
	var p := Vector2.ZERO
	for i: int in 50000:
		p += Vector2.from_angle(float(i) * 0.01) * 3.0
		path.push_head(p, 2.0)
		path.trim(300.0)
	check(path.point_count() < 300, "point count bounded by length/step + batch (got %d)" % path.point_count())
	check(path.stored_length() >= 300.0, "trim never cuts into the needed length")


func test_body_count_capped_but_length_preserved() -> void:
	var tuning := SnakeTuning.new()
	var path := SnakePathHistory.new()
	var radius: float = tuning.radius_for_level(99999)
	var length: float = tuning.length_r_for_level(99999) * radius
	path.reset(Vector2.ZERO, Vector2.RIGHT, length + 100.0, 4.0)
	var body := SnakeBody.new()
	body.rebuild(path, radius, length, tuning)
	check(body.count <= tuning.render_segment_cap, "bead count capped (%d)" % body.count)
	check_near(body.spacing * float(body.count), length, 0.5, "rendered length equals logical length")
	check(body.spacing < radius * 2.0, "beads still overlap at max level (spacing %.1f vs diameter %.1f)" % [body.spacing, radius * 2.0])
	var tail: Vector2 = body.positions[body.count - 1]
	check_near(tail.distance_to(Vector2.ZERO), length, 1.0, "tail sits at the logical length")


func test_spatial_hash_query_and_remove() -> void:
	var h := SpatialHash.new(50.0)
	h.insert(1, Vector2(10, 10))
	h.insert(2, Vector2(400, 400))
	h.insert(3, Vector2(-60, 20))
	var out := PackedInt32Array()
	h.query(Vector2.ZERO, 80.0, out)
	check(out.has(1) and out.has(3) and not out.has(2), "query finds near handles only")
	h.remove(1, Vector2(10, 10))
	out.clear()
	h.query(Vector2.ZERO, 80.0, out)
	check(not out.has(1), "removed handle gone")


func test_score_formula() -> void:
	var w := ScoreWeights.new()
	var s := ScoreSystem.new(w)
	var r := MatchResult.new()
	r.final_level = 100
	r.kills = 3
	r.food_eaten = 50
	r.survival_sec = 61.7
	r.final_rank = 2
	r.boss_defeated = true
	var expected: int = 100 * w.per_level + 3 * w.per_kill + 50 * w.per_food + 61 * w.per_second_alive + w.rank_bonus[1] + w.boss_defeated_bonus
	check_eq(s.compute(r), expected, "score matches weights")
	r.final_rank = 9
	r.boss_defeated = false
	check_eq(s.compute(r), expected - w.rank_bonus[1] - w.boss_defeated_bonus, "no rank bonus outside table")


func test_game_state_machine_guards() -> void:
	var m := GameStateMachine.new()
	check(not m.transition(GameStateMachine.State.ENDED), "cannot end before playing")
	check(m.transition(GameStateMachine.State.PLAYING), "setup -> playing")
	check(m.transition(GameStateMachine.State.PAUSED), "playing -> paused")
	check(m.transition(GameStateMachine.State.PLAYING), "paused -> playing")
	check(m.transition(GameStateMachine.State.ENDED), "playing -> ended")
	check(not m.transition(GameStateMachine.State.PLAYING), "ended is final")


func test_save_roundtrip_and_versioning() -> void:
	var path := "user://test_save_roundtrip.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var a := SaveService.new(path)
	a.load_data()
	check_eq(a.best_level, 0, "fresh save starts empty")
	var r := MatchResult.new()
	r.final_level = 321
	r.score = 9999
	r.final_rank = 3
	r.kills = 4
	check(a.record_match(r), "first match sets records")
	a.unlock_skin(&"teal")
	a.selected_skin = &"teal"
	a.settings = {"master_volume": 0.5}
	check_eq(a.save_data(), OK, "save succeeds")
	var b := SaveService.new(path)
	b.load_data()
	check_eq(b.best_level, 321, "best level persisted")
	check_eq(b.best_score, 9999, "best score persisted")
	check_eq(b.best_rank, 3, "best rank persisted")
	check_eq(b.total_kills, 4, "kills persisted")
	check(b.unlocked_skins.has("teal"), "unlocked skins persisted")
	check_eq(b.selected_skin, &"teal", "selected skin persisted")
	check_near(float(b.settings.get("master_volume", 0.0)), 0.5, 0.0001, "settings persisted")
	var cfg := ConfigFile.new()
	cfg.load(path)
	check_eq(int(cfg.get_value("meta", "version", 0)), SaveService.SCHEMA_VERSION, "schema version written")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_arena_clamp_slides() -> void:
	var cfg := ArenaConfig.new()
	cfg.radius = 1000.0
	var arena := ArenaSystem.new(cfg)
	var m := SnakeMovement.new()
	m.reset(Vector2(1200, 0), 0.0, 100.0)
	var n: Vector2 = arena.clamp_inside(m, 20.0)
	check_near(m.position.length(), 980.0, 0.01, "clamped inside radius minus head radius")
	check_near(n.x, 1.0, 0.001, "outward normal returned")
	m.slide_along(n)
	check(m.heading().dot(n) <= 0.001, "heading no longer points out of the arena")


func _curve() -> LevelCurve:
	return load("res://resources/balance/GameBalance.tres").level_curve
