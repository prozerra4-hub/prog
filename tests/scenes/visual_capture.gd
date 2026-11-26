extends SceneTree
## Visual QA capture bootstrap (not shipped).
##   godot --path . -s tests/scenes/visual_capture.gd -- --out=<dir> [--only=a,b]
## Scripts passed with -s compile before autoloads are registered, so all game
## types live in CaptureDirector.gd, which is loaded here at runtime.


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var director: Node = load("res://tests/scenes/CaptureDirector.gd").new()
	root.add_child(director)
	director.call("begin")
