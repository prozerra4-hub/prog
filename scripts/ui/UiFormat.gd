class_name UiFormat
extends RefCounted
## Number/time formatting for UI text.


## 1234567 -> "1,234,567"
static func grouped(value: int) -> String:
	var negative: bool = value < 0
	var digits: String = str(absi(value))
	var out: String = ""
	var count: int = 0
	for i: int in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if negative else "") + out


## 125 -> "2:05"
static func clock(seconds: int) -> String:
	var s: int = maxi(seconds, 0)
	return "%d:%02d" % [s / 60, s % 60]


## "Lv 1,234"
static func level(value: int) -> String:
	return "Lv " + grouped(value)
