class_name CombatConsequences
extends RefCounted
## Applies what CombatSystem decided: food from cuts and remains, swallow rewards,
## revives / respawn scheduling, and the match-ending boss kill. Announces each
## event through the owning GameSession's signals.

const END_DELAY_SEC: float = 1.4

var _session: GameSession
var _balance: GameBalance


func _init(session: GameSession) -> void:
	_session = session
	_balance = session.balance


## Applies one frame of combat results (strikes first, then swallows).
func apply(result: CombatResult) -> void:
	for s: StrikeRecord in result.strikes:
		apply_strike(s)
	for k: KillRecord in result.kills:
		apply_kill(k)


## Drops the bitten-off chunk as food and announces the strike.
func apply_strike(s: StrikeRecord) -> void:
	_session.food.spawn_severed(s.victim, s.severed, s.xp_spilled, _balance.combat.severed_max_orbs)
	_session.snake_struck.emit(s.striker, s.victim, s.kind, s.xp_taken, s.at)


## Rewards the killer, drops remains, kills the victim and schedules what comes next.
func apply_kill(k: KillRecord) -> void:
	var victim: SnakeActor = k.victim
	var killer: SnakeActor = k.killer
	# Rewards and remains use the victim's XP *before* any penalty.
	if killer != null:
		var reward: int = int(float(victim.stats.total_xp) * _balance.boss.reward_xp_ratio) if victim.is_boss else _session.combat.kill_reward(victim)
		killer.on_kill_reward(reward)
	_session.food.spawn_remains(victim, _session.combat.remains_xp(victim), _balance.combat.remains_max_orbs)
	victim.kill(killer)
	if killer != null:
		_session.combat_resolved.emit(killer, victim)
	_session.snake_died.emit(victim, killer)

	if victim.is_player:
		_on_player_down(victim)
	elif victim.is_boss:
		_on_boss_down(victim, killer)
	elif _session.showdown.allows_rival_respawn():
		_session.respawns.schedule(victim, _balance.ai_respawn_delay_sec)


## Turns a rival straight into food (showdown start). No killer, no respawn.
func dissolve(rival: SnakeActor) -> void:
	_session.food.spawn_remains(rival, rival.stats.total_xp, _balance.combat.remains_max_orbs)
	rival.kill(null)
	_session.snake_died.emit(rival, null)


func _on_player_down(player: SnakeActor) -> void:
	if _session.revives_left > 0:
		_session.revives_left -= 1
		_session.revives_changed.emit(_session.revives_left)
		_session.respawns.schedule(player, _balance.player_respawn_delay_sec)
		_session.player_respawn_scheduled.emit(_balance.player_respawn_delay_sec)
	else:
		_session.director.end_match(MatchResult.Outcome.ELIMINATED, END_DELAY_SEC)


func _on_boss_down(boss: SnakeActor, killer: SnakeActor) -> void:
	if killer != null and killer.is_player and not _session.attract_mode:
		_session.mark_boss_defeated()
		_session.boss_defeated.emit(killer)
		_session.director.end_match(MatchResult.Outcome.VICTORY, END_DELAY_SEC)
	else:
		# Only the player's kill ends the match; otherwise the tyrant returns.
		_session.respawns.schedule(boss, _balance.ai_respawn_delay_sec * 3.0)
