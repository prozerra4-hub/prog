extends SceneTree
## Balance probe (QA tool, not a pass/fail test). Simulates full matches with an
## AI autopilot as the player and prints the level timeline.
##   godot --headless --path . -s tests/balance_probe.gd -- --matches=5


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var probe: Node = load("res://tests/integration/BalanceProbe.gd").new()
	root.add_child(probe)
	probe.call("run")
