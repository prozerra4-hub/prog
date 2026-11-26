class_name ZoneConfig
extends Resource
## Battle-royale style safe zone. The regular match runs through `phases` in
## order; the showdown then plays `final_phase`. Outside the zone a snake erodes
## from the tail (its level drops with its length) until it re-enters or dies.

@export var phases: Array[ZonePhase] = []
## Played when the showdown starts (no wait, the circle closes on the boss fight).
@export var final_phase: ZonePhase
## Share of body length lost per second outside the zone.
@export_range(0.0, 1.0) var erosion_per_sec: float = 0.05
## Erosion is applied in ticks of this length.
@export var erosion_tick_sec: float = 0.5
## The boss is immune (it is the showdown's centrepiece, never a zone casualty).
@export var boss_immune: bool = true
