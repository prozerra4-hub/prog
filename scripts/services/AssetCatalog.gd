class_name AssetCatalog
extends RefCounted
## Central texture registry. Every texture is loaded at most once and cached;
## a missing key or file is reported loudly instead of failing silently.
##
## Only assets that passed the visual audit are listed (docs/ASSET_CATALOG.md).

const ROOT: String = "res://assets/serpent_arena/"

const MANIFEST: Dictionary = {
	AssetIds.SNAKE_BEAD: "snakes/body_segment_blue.png",

	AssetIds.FOOD_SMALL_GOLD: "food/food_small_gold.png",
	AssetIds.FOOD_MEDIUM_GOLD: "food/food_medium_gold.png",
	AssetIds.FOOD_LARGE_GOLD: "food/food_large_gold.png",
	AssetIds.FOOD_RED: "food/food_red.png",
	AssetIds.FOOD_PURPLE: "food/food_purple.png",
	AssetIds.FOOD_CYAN: "food/food_cyan.png",
	AssetIds.FOOD_GREEN: "food/food_green.png",
	AssetIds.FOOD_RARE: "food/food_rare_orange.png",
	AssetIds.GEM_BLUE: "food/gem_blue.png",
	AssetIds.GEM_PURPLE: "food/gem_purple.png",
	AssetIds.GEM_GREEN: "food/gem_green.png",

	AssetIds.VFX_LEVELUP_GOLD: "vfx/levelup_ring_gold.png",
	AssetIds.VFX_IMPACT_GOLD: "vfx/impact_burst_gold.png",
	AssetIds.VFX_SPARKLE_WHITE: "vfx/sparkle_white.png",
	AssetIds.VFX_SPARKLE_CYAN: "vfx/sparkle_cyan.png",
	AssetIds.VFX_DEATH_SMOKE: "vfx/death_smoke.png",
	AssetIds.VFX_RESPAWN_PORTAL: "vfx/respawn_portal.png",
	AssetIds.VFX_BOSS_BURST: "vfx/boss_burst_red.png",
	AssetIds.VFX_RARE_AURA: "vfx/rare_food_aura.png",

	AssetIds.ARENA_FLOOR: "arena_tiles/arena_01_dots.png",
	AssetIds.ARENA_FLOOR_HEX: "arena_tiles/arena_02_hex.png",

	AssetIds.ICON_CLOCK: "ui_icons/clock.png",
	AssetIds.ICON_HEART: "ui_icons/heart.png",
	AssetIds.ICON_CROWN: "ui_icons/crown.png",
	AssetIds.ICON_SKULL: "ui_icons/skull.png",
}

var _cache: Dictionary = {}  # StringName -> Texture2D


## Texture for `key`, loaded once and cached; logs an error and returns null if missing.
func texture(key: StringName) -> Texture2D:
	var cached: Texture2D = _cache.get(key)
	if cached != null:
		return cached
	if not MANIFEST.has(key):
		push_error("AssetCatalog: unknown asset key '%s'" % key)
		return null
	var path: String = ROOT + String(MANIFEST[key])
	if not ResourceLoader.exists(path):
		push_error("AssetCatalog: file missing for '%s' -> %s" % [key, path])
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		push_error("AssetCatalog: failed to load '%s' -> %s" % [key, path])
		return null
	_cache[key] = tex
	return tex


## Loads everything up front (avoids hitches on first use). Returns missing keys.
func preload_all() -> PackedStringArray:
	var missing := PackedStringArray()
	for key: StringName in MANIFEST.keys():
		if texture(key) == null:
			missing.append(String(key))
	return missing
