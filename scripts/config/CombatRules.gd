class_name CombatRules
extends Resource
## Rules used by CombatSystem. One predictable rule, matching what you see:
##   "When the FRONT HALF of a head touches any part of a LOWER-level snake, it
##    strikes. Every time."
##   * strike on a BODY -> bites a CHUNK out where the mouth landed (bigger gap,
##     bigger chunk); the chunk drops as food and the body gets that much shorter
##   * strike on a HEAD -> bite sized by the level gap
##   * strike on the NECK (front part of the body) -> swallowed whole
##   * the struck snake's level drops to match its remaining length
##   Your own head never hurts you: higher-level bodies are walls you slide along,
##   equal-level heads bounce. A struck/respawned snake shows a shield bubble
##   while it is protected; that is the ONLY time a touch does nothing.

@export_group("Hit shapes")
## Striking circle = drawn head radius * mouth_scale.
@export var mouth_scale: float = 0.95
## Contact must lie within this half-angle of the heading (90 = front half).
@export_range(10.0, 180.0) var mouth_half_angle_deg: float = 90.0
## Head (as a target) circle = drawn head radius * head_target_scale.
@export var head_target_scale: float = 0.9
## Body hit circle = drawn bead radius * body_hit_scale.
@export var body_hit_scale: float = 0.9

@export_group("Strength")
## Levels within this ratio are an even match: heads bounce, nobody strikes.
## 0 = only identical levels are even (the higher level always wins).
@export_range(0.0, 0.5) var even_match_ratio: float = 0.0
@export var bounce_invulnerable_sec: float = 0.35

@export_group("Head bite")
## Share of the victim lost to a bite on the head:
##   fraction = bite_base_fraction + bite_fraction_per_ratio * (level_ratio - 1)
## Capped at head_bite_max_share: a head bite never swallows in one hit.
@export var bite_base_fraction: float = 0.2
@export var bite_fraction_per_ratio: float = 0.15
@export_range(0.1, 1.0) var head_bite_max_share: float = 0.8

@export_group("Body cut")
## Share of the body a body strike bites off:
##   share = body_cut_base_share + body_cut_per_ratio * (level_ratio - 1), capped.
@export var body_cut_base_share: float = 0.15
@export var body_cut_per_ratio: float = 0.1
@export_range(0.05, 0.95) var body_cut_max_share: float = 0.6
## Strikes on this front share of the body (the neck) swallow the victim.
@export_range(0.0, 0.9) var neck_cut_ratio: float = 0.15
## A victim left at or below this level is swallowed.
@export var swallow_floor_level: int = 1
## Of the XP bitten off, this share goes straight to the striker...
@export_range(0.0, 1.0) var cut_gain_ratio: float = 0.35
## ...and this share drops as food where the chunk was.
@export_range(0.0, 1.0) var cut_spill_ratio: float = 0.65
@export var severed_max_orbs: int = 30

@export_group("Timing")
## Striker cannot strike again for this long.
@export var strike_cooldown_sec: float = 0.25
## A struck snake is knocked away and protected for this long...
@export var struck_invulnerable_sec: float = 1.5
## ...and gets an escape burst: speed multiplier for burst_sec.
@export var escape_burst_speed: float = 1.5
@export var escape_burst_sec: float = 1.2
## Speed kept after sliding off a body.
@export_range(0.0, 1.0) var slide_speed_keep: float = 0.85

@export_group("Swallow rewards")
## Swallower gains victim_total_xp * kill_xp_ratio + kill_flat_xp.
@export var kill_xp_ratio: float = 0.8
@export var kill_flat_xp: int = 20
## Share of the victim's XP dropped as food along its body.
@export var remains_xp_ratio: float = 0.3
@export var remains_max_orbs: int = 24

@export_group("Death & respawn")
@export var respawn_invulnerable_sec: float = 3.0
## Player keeps this share of total XP after dying...
@export_range(0.0, 1.0) var respawn_xp_keep_ratio: float = 0.75
## ...but never less than this share of the best XP reached this match.
@export_range(0.0, 1.0) var respawn_peak_floor_ratio: float = 0.4
