class_name AIPersonality
extends Resource
## Behaviour profile for SnakeAIController. Different numbers, same state machine.

enum Archetype { COLLECTOR, BALANCED, HUNTER }

@export var archetype: Archetype = Archetype.BALANCED
@export var display_name: String = "Balanced"
## Seconds between decisions (randomised ±25% per snake).
@export var think_interval: float = 0.18
## Food scoring multiplier vs. hunting.
@export var food_bias: float = 1.0
## Chance per decision to start chasing visible prey.
@export_range(0.0, 1.0) var aggression: float = 0.4
## Treat a snake as a threat when its level >= mine * (1 - caution_margin).
@export_range(0.0, 0.5) var caution_margin: float = 0.05
## Perception radius in own head radii (min clamp in px applies).
@export var sight_r: float = 26.0
@export var sight_min_px: float = 520.0
## Only hunt snakes whose level <= mine * prey_ratio.
@export_range(0.1, 1.0) var prey_ratio: float = 0.85
@export var chase_timeout: float = 4.0
@export var speed_multiplier: float = 1.0
## Personal XP gain multiplier (growth speed).
@export var xp_multiplier: float = 1.0
## Treat the boss as prey once out-levelled. Off for rivals (the boss is the
## player's trophy); used by the QA autopilot.
@export var hunts_boss: bool = false
