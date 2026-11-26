class_name SpatialHash
extends RefCounted
## Uniform-grid spatial hash storing integer handles. Rebuilt or updated by its
## owner; supports circle queries. Used for snake beads and food.

var cell_size: float

var _cells: Dictionary = {}  # Vector2i -> PackedInt32Array


func _init(size: float) -> void:
	cell_size = maxf(size, 1.0)


## Removes everything.
func clear() -> void:
	_cells.clear()


## Grid cell containing `p`.
func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / cell_size)), int(floor(p.y / cell_size)))


## Adds `handle` at `p`.
func insert(handle: int, p: Vector2) -> void:
	var key: Vector2i = cell_of(p)
	var bucket: PackedInt32Array = _cells.get(key, PackedInt32Array())
	bucket.append(handle)
	_cells[key] = bucket


## Removes `handle` from the cell at `p` (no-op if absent).
func remove(handle: int, p: Vector2) -> void:
	var key: Vector2i = cell_of(p)
	if not _cells.has(key):
		return
	var bucket: PackedInt32Array = _cells[key]
	var i: int = bucket.find(handle)
	if i >= 0:
		bucket.remove_at(i)
		if bucket.is_empty():
			_cells.erase(key)
		else:
			_cells[key] = bucket


## Appends every handle whose cell overlaps the circle's bounding box.
## Callers do the exact distance test.
func query(center: Vector2, radius: float, out: PackedInt32Array) -> void:
	var lo: Vector2i = cell_of(center - Vector2(radius, radius))
	var hi: Vector2i = cell_of(center + Vector2(radius, radius))
	for cy: int in range(lo.y, hi.y + 1):
		for cx: int in range(lo.x, hi.x + 1):
			var key := Vector2i(cx, cy)
			if _cells.has(key):
				out.append_array(_cells[key])
