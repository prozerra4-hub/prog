class_name HudFx
extends RefCounted
## Small, restrained HUD animations shared by HUD components.


## Quick scale punch around the control's centre.
static func pulse(c: Control, peak: float) -> void:
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2(peak, peak), 0.08)
	tw.tween_property(c, "scale", Vector2.ONE, 0.22)
