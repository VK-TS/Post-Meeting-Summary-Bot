class_name BulletTypes
extends RefCounted

const BASE_BULLETS := {
	"normal": {
		"name": "Round",
		"color": Color(1.0, 0.95, 0.55),
		"projectile_sprite": "res://sprites/round_projectile.png",
		"card_art": "res://cards/round_card.png",
		"shape": "circle",
		"damage": 1,
		"speed": 640.0,
		"radius": 5.0,
		"health": 1,
		"pierce": 0,
		"damage_type": "physical",
		"value": 1,
	},
	"heavy": {
		"name": "Slug",
		"color": Color(1.0, 0.38, 0.28),
		"projectile_sprite": "res://sprites/heavy_projectile.png",
		"card_art": "res://cards/heavy_card.png",
		"shape": "circle",
		"damage": 2,
		"speed": 500.0,
		"radius": 7.0,
		"health": 1,
		"pierce": 0,
		"damage_type": "physical",
		"value": 2,
	},
	"quick": {
		"name": "Needle",
		"color": Color(0.25, 0.85, 1.0),
		"projectile_sprite": "res://sprites/quick_projectile.png",
		"card_art": "res://cards/quick_card.png",
		"shape": "circle",
		"damage": 1,
		"speed": 860.0,
		"radius": 4.0,
		"health": 1,
		"pierce": 0,
		"damage_type": "physical",
		"value": 2,
	},
	"pierce": {
		"name": "Lance",
		"color": Color(0.7, 0.55, 1.0),
		"projectile_sprite": "res://sprites/pierce_projectile.png",
		"card_art": "res://cards/pierce_card.png",
		"shape": "circle",
		"damage": 1,
		"speed": 700.0,
		"radius": 5.0,
		"health": 2,
		"pierce": 1,
		"damage_type": "physical",
		"value": 3,
	},
}

const COMPONENTS := {
	"royal_tarts": {
		"name": "Royal Tarts",
		"description": "+size, -speed",
		"value": 2,
		"card_sticker": "res://stickers/royal_tarts.png",
		"projectile_overlay": "res://sprites/royal_tarts_overlay.png",
		"overlay_color": Color(1.0, 0.74, 0.38, 0.55),
		"radius_add": 3.0,
		"speed_mul": 0.82,
	},
	"sacrificial_oil": {
		"name": "Sacrificial Oil",
		"description": "Adds burn damage",
		"value": 3,
		"card_sticker": "res://stickers/sacrificial_oil.png",
		"projectile_overlay": "res://sprites/sacrificial_oil_overlay.png",
		"overlay_color": Color(1.0, 0.35, 0.1, 0.7),
		"trail_effect": "fire",
		"effect": "burn",
		"effect_damage": 5,
		"effect_lifespan": 3.0,
		"effect_tick_interval": 1.0,
		"damage_type": "fire",
		"color": Color(1.0, 0.35, 0.1),
	},
	"barbed_wire": {
		"name": "Barbed Wire",
		"description": "Adds bleed damage",
		"value": 2,
		"card_sticker": "res://stickers/barbed_wire.png",
		"projectile_overlay": "res://sprites/barbed_wire_overlay.png",
		"overlay_color": Color(0.8, 0.08, 0.08, 0.55),
		"effect": "bleed",
		"effect_damage": 3,
		"effect_lifespan": 4.0,
		"effect_tick_interval": 1.0,
		"damage_add": 1,
	},
	"frost_charm": {
		"name": "Frost Charm",
		"description": "Freezes briefly",
		"value": 3,
		"card_sticker": "res://stickers/frost_charm.png",
		"projectile_overlay": "res://sprites/frost_charm_overlay.png",
		"overlay_color": Color(0.55, 0.9, 1.0, 0.65),
		"trail_effect": "ice",
		"effect": "freeze",
		"effect_damage": 0,
		"effect_lifespan": 1.2,
		"effect_tick_interval": 1.0,
		"damage_type": "ice",
		"color": Color(0.55, 0.9, 1.0),
	},
	"one_eyes_boon": {
		"name": "One Eye's Boon",
		"description": "Adds poison damage",
		"value": 3,
		"card_sticker": "res://stickers/one_eyes_boon.png",
		"projectile_overlay": "res://sprites/one_eyes_boon_overlay.png",
		"overlay_color": Color(0.45, 1.0, 0.35, 0.65),
		"trail_effect": "poison",
		"effect": "poison",
		"effect_damage": 2,
		"effect_lifespan": 5.0,
		"effect_tick_interval": 1.0,
		"damage_type": "poison",
		"color": Color(0.45, 1.0, 0.35),
	},
	"vampiric_ink": {
		"name": "Vampiric Ink",
		"description": "Heals on damage over time",
		"value": 4,
		"card_sticker": "res://stickers/vampiric_ink.png",
		"projectile_overlay": "res://sprites/vampiric_ink_overlay.png",
		"overlay_color": Color(0.6, 0.05, 0.2, 0.58),
		"trail_effect": "hearts",
		"effect": "lifesteal",
		"effect_damage": 1,
		"effect_lifespan": 3.0,
		"effect_tick_interval": 1.0,
		"damage_type": "dark",
	},
	"swift_sigil": {
		"name": "Swift Sigil",
		"description": "+speed, -size",
		"value": 2,
		"card_sticker": "res://stickers/swift_sigil.png",
		"projectile_overlay": "res://sprites/swift_sigil_overlay.png",
		"overlay_color": Color(0.3, 0.8, 1.0, 0.45),
		"speed_mul": 1.25,
		"radius_add": -1.0,
	},
	"hunters_eye": {
		"name": "Hunter's Eye",
		"description": "Homes toward enemies",
		"value": 4,
		"card_sticker": "res://stickers/hunters_eye.png",
		"projectile_overlay": "res://sprites/hunters_eye_overlay.png",
		"overlay_color": Color(1.0, 0.95, 0.25, 0.6),
		"has_homing": true,
	},
	"split_charge": {
		"name": "Split Charge",
		"description": "+pierce, +bullet health",
		"value": 3,
		"card_sticker": "res://stickers/split_charge.png",
		"projectile_overlay": "res://sprites/split_charge_overlay.png",
		"overlay_color": Color(0.85, 0.75, 1.0, 0.55),
		"pierce_add": 1,
		"health_add": 1,
	},
	"lightning_coil": {
		"name": "Lightning Coil",
		"description": "Adds shock and sparkle overlay",
		"value": 4,
		"card_sticker": "res://stickers/lightning_coil.png",
		"projectile_overlay": "res://sprites/lightning_coil_overlay.png",
		"overlay_color": Color(0.7, 0.95, 1.0, 0.8),
		"trail_effect": "electric",
		"effect": "shock",
		"effect_damage": 2,
		"effect_lifespan": 2.0,
		"effect_tick_interval": 0.5,
		"damage_type": "electric",
	},
}

static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in BASE_BULLETS.keys():
		ids.append(str(id))
	return ids

static func all_component_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in COMPONENTS.keys():
		ids.append(str(id))
	return ids

static func random_id() -> String:
	return all_ids().pick_random()

static func random_component_id() -> String:
	return all_component_ids().pick_random()

static func data(id: String) -> Dictionary:
	return BASE_BULLETS.get(id, BASE_BULLETS["normal"])

static func component_data(id: String) -> Dictionary:
	return COMPONENTS.get(id, {})

static func create_card(base_id: String = "normal") -> Dictionary:
	return {
		"kind": "bullet",
		"base_id": base_id,
		"components": [],
	}

static func random_bullet_card() -> Dictionary:
	return create_card(random_id())

static func random_drop() -> Dictionary:
	if randf() < 0.45:
		return {
			"kind": "component",
			"component_id": random_component_id(),
		}

	return random_bullet_card()

static func add_component(card: Dictionary, component_id: String, position: Vector2) -> Dictionary:
	var next_card := card.duplicate(true)
	var components: Array = next_card.get("components", [])
	components.append({
		"id": component_id,
		"offset": position,
		"position": position,
		"rotation": 0.0,
		"scale": 1.0
	})
	next_card["components"] = components
	return next_card

static func component_entry_id(component_entry: Variant) -> String:
	if component_entry is Dictionary:
		var entry: Dictionary = component_entry
		if entry.has("id"):
			return str(entry.get("id", ""))
		if entry.has("component_id"):
			return str(entry.get("component_id", ""))
		return ""
	return str(component_entry)

static func component_entry_offset(component_entry: Variant, default_offset: Vector2 = Vector2.ZERO) -> Vector2:
	if component_entry is Dictionary:
		var entry: Dictionary = component_entry
		if entry.has("offset"):
			return entry.get("offset", default_offset)
		if entry.has("position"):
			return entry.get("position", default_offset)
	return default_offset

static func card_name(card: Dictionary) -> String:
	var base := data(str(card.get("base_id", "normal")))
	var components: Array = card.get("components", [])
	if components.is_empty():
		return str(base["name"])
	return "%s +%d" % [str(base["name"]), components.size()]

static func component_name(component_id: String) -> String:
	var component := component_data(component_id)
	if component.is_empty():
		return "Unknown"
	return str(component["name"])

static func component_description(component_id: String) -> String:
	var component := component_data(component_id)
	if component.is_empty():
		return ""
	return str(component["description"])

static func card_value(card: Dictionary) -> int:
	return int(card_stats(card)["value"])

static func card_stats(card: Dictionary) -> Dictionary:
	var base := data(str(card.get("base_id", "normal")))
	var stats := {
		"name": str(base["name"]),
		"color": base["color"],
		"projectile_sprite": str(base.get("projectile_sprite", "")),
		"card_art": str(base.get("card_art", "")),
		"shape": str(base.get("shape", "circle")),
		"damage": int(base["damage"]),
		"speed": float(base["speed"]),
		"radius": float(base["radius"]),
		"health": int(base["health"]),
		"pierce": int(base["pierce"]),
		"damage_type": str(base.get("damage_type", "physical")),
		"value": int(base["value"]),
		"effects": [],
		"death_effects": [],
		"trail": {},
		"visual_layers": [],
		"card_layers": [],
		"has_homing": false,
	}

	var components: Array = card.get("components", [])
	for component_entry in components:
		var component_id := component_entry_id(component_entry)
		if component_id.is_empty():
			continue
		var component := component_data(component_id)
		if component.is_empty():
			continue

		stats["value"] = int(stats["value"]) + int(component.get("value", 0))
		stats["damage"] = int(stats["damage"]) + int(component.get("damage_add", 0))
		stats["speed"] = float(stats["speed"]) * float(component.get("speed_mul", 1.0))
		stats["radius"] = max(2.0, float(stats["radius"]) + float(component.get("radius_add", 0.0)))
		stats["health"] = int(stats["health"]) + int(component.get("health_add", 0))
		stats["pierce"] = int(stats["pierce"]) + int(component.get("pierce_add", 0))
		stats["has_homing"] = bool(stats["has_homing"]) or bool(component.get("has_homing", false))

		if component.has("color"):
			stats["color"] = component["color"]
		if component.has("damage_type"):
			stats["damage_type"] = str(component["damage_type"])
		if component.has("shape"):
			stats["shape"] = str(component["shape"])
		if component.has("projectile_sprite"):
			stats["projectile_sprite"] = str(component["projectile_sprite"])
		if component.has("card_art"):
			stats["card_art"] = str(component["card_art"])

		var visual_layers: Array = stats.get("visual_layers", [])
		visual_layers.append({
			"id": str(component_id),
			"sprite": str(component.get("projectile_overlay", "")),
			"color": component.get("overlay_color", Color(1.0, 1.0, 1.0, 0.45)),
			"trail_effect": str(component.get("trail_effect", "")),
		})
		stats["visual_layers"] = visual_layers

		var card_layers: Array = stats.get("card_layers", [])
		card_layers.append({
			"id": str(component_id),
			"sprite": str(component.get("card_sticker", "")),
			"color": component.get("overlay_color", Color(1.0, 1.0, 1.0, 0.45)),
			"name": str(component.get("name", component_id)),
		})
		stats["card_layers"] = card_layers

		if component.has("effect"):
			var effects: Array = stats.get("effects", [])
			effects.append({
				"id": str(component["effect"]),
				"damage": int(component.get("effect_damage", 0)),
				"lifespan": float(component.get("effect_lifespan", 0.0)),
				"tick_interval": float(component.get("effect_tick_interval", 1.0)),
			})
			stats["effects"] = effects

	return stats

static func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null

	# Prefer ResourceLoader if available
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex

	# Only try raw image load if the file actually exists.
	if not FileAccess.file_exists(path):
		return null

	var img := Image.new()
	var err := img.load(path)
	if err == OK:
		var it := ImageTexture.create_from_image(img)
		return it

	return null
