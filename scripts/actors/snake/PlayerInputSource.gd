class_name PlayerInputSource
extends RefCounted
## Reads raw device input and turns it into a world-space steering direction.
## Priority rule: while any direction key is held, the keyboard steers; otherwise
## the mouse steers (direction from the head on screen to the cursor). A cursor
## very close to the head keeps the current heading so the snake never jitters.
## A touch implementation can replace this class without touching the snake.

## Cursor dead-zone around the head, in screen pixels.
const MOUSE_DEADZONE_PX: float = 26.0

## Last device that produced input: true = keyboard.
var keyboard_active: bool = false
var _last_mouse: Vector2 = Vector2.INF


## World-space steering direction from keys (priority) or the mouse; zero = keep heading.
func read_direction(viewport: Viewport, head_world: Vector2) -> Vector2:
	var keys := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if keys.length_squared() > 0.01:
		keyboard_active = true
		return keys.normalized()
	if viewport == null:
		return Vector2.ZERO
	var mouse: Vector2 = viewport.get_mouse_position()
	if keyboard_active:
		# Hand control back to the mouse only once it actually moves.
		if _last_mouse == Vector2.INF or mouse.distance_to(_last_mouse) < 4.0:
			_last_mouse = mouse
			return Vector2.ZERO
		keyboard_active = false
	_last_mouse = mouse
	var head_screen: Vector2 = viewport.get_canvas_transform() * head_world
	var to_mouse: Vector2 = mouse - head_screen
	if to_mouse.length() < MOUSE_DEADZONE_PX:
		return Vector2.ZERO
	return to_mouse.normalized()
