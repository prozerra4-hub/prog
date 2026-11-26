class_name TestCase
extends RefCounted
## Minimal assertion helper (no external test framework required).
## Test methods are any method whose name starts with "test_".

var failures: PackedStringArray = PackedStringArray()
var checks: int = 0
var _current: String = ""


func set_current(test_name: String) -> void:
	_current = test_name


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append("%s: %s" % [_current, message])


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func check_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	check(absf(actual - expected) <= tolerance, "%s (expected %.4f±%.4f, got %.4f)" % [message, expected, tolerance, actual])
