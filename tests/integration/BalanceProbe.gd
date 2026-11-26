extends Node
## Runs full matches with a hunter autopilot as the player and reports growth.

const STEP: float = 1.0 / 60.0
const CHECKPOINTS: Array[int] = [30, 60, 90, 120]


func run() -> void:
	var matches: int = 5
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--matches="):
			matches = int(arg.substr(10))
	var world_scene: PackedScene = load("res://scenes/game/GameWorld.tscn")
	# A "reasonable human" profile: hunts actively but respects bigger snakes.
	var hunter: AIPersonality = (load("res://resources/ai/hunter.tres") as AIPersonality).duplicate()
	hunter.hunts_boss = true
	hunter.caution_margin = 0.1
	hunter.aggression = 0.6
	hunter.xp_multiplier = 1.0
	hunter.speed_multiplier = 1.0
	var wins: int = 0
	for m: int in matches:
		var s: GameSession = world_scene.instantiate()
		s.process_mode = Node.PROCESS_MODE_DISABLED
		get_tree().root.add_child(s)
		await get_tree().process_frame
		s.start(load("res://resources/skins/azure.tres"))
		var brain := SnakeAIController.new(hunter, 1000 + m)
		s.player.brain = brain
		brain.on_spawned(s.player)
		var ended: Array = []
		s.game_over.connect(func(res: MatchResult) -> void: ended.append(res))
		var causes: PackedStringArray = PackedStringArray()
		var loss: Dictionary = {"strike": 0, "zone": 0, "strikes": 0, "zone_ticks": 0}
		s.snake_struck.connect(func(_st: SnakeActor, v: SnakeActor, _k: StrikeRecord.Kind, xp: int, _at: Vector2) -> void:
			if v.is_player:
				loss["strike"] += xp
				loss["strikes"] += 1)
		s.snake_eroded.connect(func(a: SnakeActor, xp: int) -> void:
			if a.is_player:
				loss["zone"] += xp
				loss["zone_ticks"] += 1)
		s.snake_died.connect(func(victim: SnakeActor, killer: SnakeActor) -> void:
			if victim.is_player:
				var who: String = "self/none" if killer == null else ("BOSS" if killer.is_boss else killer.display_name)
				var state: String = String(brain.state_id())
				var kl: int = killer.stats.level if killer != null else 0
				var head_on: String = ""
				if killer != null:
					head_on = " head-on" if victim.head_position().distance_to(killer.head_position()) < (victim.head_radius() + killer.head_radius()) * 1.1 else " hit-body"
				causes.append("%s(Lv%d vs Lv%d,%s%s)" % [who, victim.stats.level, kl, state, head_on]))
		var line: String = "match %d:" % (m + 1)
		var step: int = 0
		var next_cp: int = 0
		var t0: int = Time.get_ticks_usec()
		while ended.is_empty() and step < 60 * 160:
			s._process(STEP)
			step += 1
			if next_cp < CHECKPOINTS.size() and step == CHECKPOINTS[next_cp] * 60:
				line += "  %ds Lv%d" % [CHECKPOINTS[next_cp], s.player.stats.level]
				next_cp += 1
		var r: MatchResult = ended[0] if not ended.is_empty() else null
		if r != null:
			if r.outcome == MatchResult.Outcome.VICTORY:
				wins += 1
			line += "  | %s at %.0fs%s, peak Lv%d, kills %d, deaths %d, rank #%d, boss Lv%d" % [
				r.outcome_title(), s.elapsed, " (showdown)" if s.is_showdown() else "", r.peak_level, r.kills,
				s.player.stats.deaths, r.final_rank, s.boss.stats.level if s.boss.is_alive else 0]
		line += "  (%.1f ms/step)" % (float(Time.get_ticks_usec() - t0) / float(step) / 1000.0)
		print(line)
		print("    deaths: ", ", ".join(causes))
		print("    xp lost: strikes %d (x%d), zone %d (x%d ticks)" % [loss["strike"], loss["strikes"], loss["zone"], loss["zone_ticks"]])
		s.queue_free()
		await get_tree().process_frame
	print("boss victories: %d / %d" % [wins, matches])
	get_tree().quit(0)
