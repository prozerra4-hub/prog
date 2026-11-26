extends Node
## Visual QA capture director, loaded at runtime by visual_capture.gd.
## Stages scenarios in the real game and saves screenshots. Not shipped.
## The player is driven by an AI autopilot so frames show natural movement.

var MAIN: PackedScene
var SCREEN: PackedScene
var _out: String = "user://captures"
var _only: PackedStringArray = PackedStringArray()
var tree: SceneTree


func begin() -> void:
	tree = get_tree()
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--only="):
			_only = arg.substr(7).split(",")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	MAIN = load("res://scenes/main/Main.tscn")
	SCREEN = load("res://scenes/game/GameScreen.tscn")
	await _menu()
	await _gameplay()
	print("CAPTURE DONE -> ", _out)
	tree.quit(0)


func _wants(key: String) -> bool:
	return _only.is_empty() or _only.has(key)


func _menu() -> void:
	if not (_wants("menu") or _wants("skins") or _wants("settings")):
		return
	var main: Main = MAIN.instantiate()
	tree.root.add_child(main)
	await _wait(2.5)
	await _shot("01_main_menu")
	var menu := main.get_child(0) as MainMenuController
	if menu != null:
		menu._show_view(menu._skins_view)
		await _wait(0.6)
		await _shot("09_menu_skins")
		menu._show_view(menu._settings_view)
		await _wait(0.6)
		await _shot("10_menu_settings")
		menu._show_view(menu._how_to_view)
		await _wait(0.6)
		await _shot("10b_menu_how_to_play")
	main.queue_free()
	await _wait(0.2)


func _gameplay() -> void:
	var screen: GameScreenController = SCREEN.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	var s: GameSession = screen.session()
	await _wait(1.0)
	await _shot("02a_match_start_controls")
	_autopilot(s)
	await _wait(4.0)
	await _shot("02_play_normal")

	# Close-up: inspect head/body/food rendering at high magnification.
	if _wants("closeup"):
		s.camera.zoom = Vector2(2.6, 2.6)
		s.balance.camera.max_zoom = 2.6
		s.balance.camera.base_zoom = 2.6
		await _wait(0.5)
		await _shot("03_closeup")
		s.balance.camera.base_zoom = 1.15
		s.balance.camera.max_zoom = 1.4

	# Crowd: pull rivals around the player.
	if _wants("crowd"):
		var p: SnakeActor = s.player
		var i: int = 0
		for a: SnakeActor in s.world.snakes:
			if a.is_player or a.is_boss:
				continue
			var ang: float = TAU * float(i) / 10.0
			var at: Vector2 = p.head_position() + Vector2.from_angle(ang) * 380.0
			a.spawn(at, ang + PI * 0.6, maxi(1, p.stats.level + (i % 5) * 3 - 6), 0.0)
			i += 1
		p.grant_invulnerability(3.0)
		await _wait(1.2)
		await _shot("04_crowd")

	# Level-up ring + growth.
	if _wants("levelup"):
		s.player.grant_invulnerability(2.0)
		s.player.stats.add_xp(400)
		await _wait(0.12)
		await _shot("05_levelup")

	# Bitten: a 2x bigger rival's mouth lands on the player's body.
	if _wants("bitten"):
		var p: SnakeActor = s.player
		p._invulnerable_left = 0.0
		var biter: SnakeActor = null
		for a: SnakeActor in s.world.snakes:
			if not a.is_player and not a.is_boss:
				biter = a
				break
		var bead: Vector2 = p.body.positions[p.body.count >> 2]
		var side: Vector2 = (bead - p.head_position()).orthogonal().normalized()
		biter.spawn(bead + side * p.radius * 0.8, (-side).angle(), p.stats.level * 2, 0.0)
		await _wait(0.1)
		await _shot("05b_bitten")
		await _wait(1.2)

	# High level: long body, zoomed out.
	if _wants("highlevel"):
		s.player.stats.set_level(850)
		s.player.grant_invulnerability(6.0)
		await _wait(4.0)
		await _shot("06_high_level")

	# Boss close: put the player near the boss.
	if _wants("boss"):
		var b: SnakeActor = s.boss
		s.player.stats.set_level(400)
		s.player.spawn(b.head_position() + b.heading() * 700.0, (b.head_position() - (b.head_position() + b.heading() * 700.0)).angle(), 400, 8.0)
		await _wait(1.8)
		await _shot("07_boss")

	# Death + respawn.
	if _wants("death"):
		s.player.grant_invulnerability(0.0)
		s.consequences.apply_kill(KillRecord.new(s.player, s.boss, s.player.head_position()))
		await _wait(0.25)
		await _shot("08_death")
		await _wait(1.9)
		await _shot("08b_respawn")

	if _wants("zone"):
		# Let the first wait run out so the zone is mid-shrink, player outside it.
		var z: ZoneSystem = s.zone
		s.player.spawn(z.center + Vector2(z.radius + 250.0, 0), PI, s.player.stats.level, 0.0)
		await _wait(1.2)
		await _shot("05c_outside_zone")

	if _wants("showdown"):
		s.player.grant_invulnerability(4.0)
		s.time_left = 0.05
		await _wait(4.5)
		await _shot("13_showdown")

	if _wants("pause"):
		s.pause()
		await _wait(0.5)
		await _shot("11_pause")
		s.resume()
		await _wait(0.2)

	if _wants("result"):
		s.time_left = 0.05
		await _wait(1.2)
		await _shot("12_result")
	screen.queue_free()
	await _wait(0.2)


## Replaces the player's input brain with an AI brain (balanced personality).
func _autopilot(s: GameSession) -> void:
	var p: SnakeActor = s.player
	var personality: AIPersonality = load("res://resources/ai/balanced.tres")
	var brain := SnakeAIController.new(personality, 1234)
	p.brain = brain
	brain.on_spawned(p)


func _wait(sec: float) -> void:
	await tree.create_timer(sec, true, false, true).timeout


func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = tree.root.get_texture().get_image()
	var path: String = _out.path_join(file_name + ".png")
	img.save_png(path)
	print("  saved %s  (%d FPS, %d active food)" % [path.get_file(), Engine.get_frames_per_second(), _food_count()])


func _food_count() -> int:
	for n: Node in tree.root.find_children("*", "FoodField", true, false):
		return (n as FoodField).active_count()
	return 0
