extends SceneTree
## Test runner. Usage (from the project root):
##   godot --headless --path . -s tests/run_tests.gd
## Exit code 0 = all passed. Runs unit tests, then integration tests that need the
## scene tree (GameWorld simulation).

const SUITES: Array[String] = [
	"res://tests/unit/CoreLogicTests.gd",
	"res://tests/integration/MatchIntegrationTests.gd",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var total_checks: int = 0
	var failures := PackedStringArray()
	for path: String in SUITES:
		if not ResourceLoader.exists(path):
			failures.append("missing suite %s" % path)
			continue
		var suite: TestCase = load(path).new()
		for m: Dictionary in suite.get_method_list():
			var method: String = m["name"]
			if not method.begins_with("test_"):
				continue
			suite.set_current(method)
			var t0: int = Time.get_ticks_msec()
			var before: int = suite.failures.size()
			# `await` on a plain call returns immediately; coroutine tests are awaited.
			if _takes_tree(m):
				await suite.call(method, self)
			else:
				await suite.call(method)
			var status: String = "ok" if suite.failures.size() == before else "FAIL"
			print("  [%s] %s (%d ms)" % [status, method, Time.get_ticks_msec() - t0])
		total_checks += suite.checks
		failures.append_array(suite.failures)
	# Let queued frees from the last suite run before exiting (no leak noise).
	await process_frame
	await process_frame
	print("")
	if failures.is_empty():
		print("ALL TESTS PASSED (%d checks)" % total_checks)
		quit(0)
	else:
		for f: String in failures:
			printerr("FAIL: " + f)
		print("%d FAILURE(S) out of %d checks" % [failures.size(), total_checks])
		quit(1)


func _takes_tree(m: Dictionary) -> bool:
	return (m["args"] as Array).size() == 1
