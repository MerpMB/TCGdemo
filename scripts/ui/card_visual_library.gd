class_name CardVisualLibrary
extends RefCounted
## Placeholder visual styles for card frames and backs.
## Future art/shaders can replace these lookups without changing CardScene.


enum CardBackType {
	DEFAULT,
	EVENT,
	BLACKJACK,
	DEVELOPER,
}


const FRAME_KEYS := {
	CardData.Rarity.COMMON: "common",
	CardData.Rarity.RARE: "rare",
	CardData.Rarity.EPIC: "epic",
	CardData.Rarity.LEGENDARY: "legendary",
}

const REVEAL_DURATIONS := {
	CardData.Rarity.COMMON: 0.28,
	CardData.Rarity.RARE: 0.34,
	CardData.Rarity.EPIC: 0.42,
	CardData.Rarity.LEGENDARY: 0.62,
}

const REVEAL_LIFT_OFFSETS := {
	CardData.Rarity.COMMON: -10.0,
	CardData.Rarity.RARE: -14.0,
	CardData.Rarity.EPIC: -18.0,
	CardData.Rarity.LEGENDARY: -26.0,
}

const REVEAL_GLOW_ALPHAS := {
	CardData.Rarity.COMMON: 0.0,
	CardData.Rarity.RARE: 0.18,
	CardData.Rarity.EPIC: 0.28,
	CardData.Rarity.LEGENDARY: 0.45,
}


static func get_frame_style(rarity: CardData.Rarity) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.bg_color = Color(0.1, 0.11, 0.15, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.shadow_color = Color(0, 0, 0, 0.35)

	match rarity:
		CardData.Rarity.COMMON:
			style.border_color = Color(0.18, 0.72, 0.32)
			style.shadow_color = Color(0.1, 0.4, 0.2, 0.35)
		CardData.Rarity.RARE:
			style.border_width_left = 4
			style.border_width_top = 4
			style.border_width_right = 4
			style.border_width_bottom = 4
			style.border_color = Color(0.22, 0.48, 0.95)
			style.shadow_color = Color(0.1, 0.25, 0.6, 0.4)
		CardData.Rarity.EPIC:
			style.border_width_left = 5
			style.border_width_top = 5
			style.border_width_right = 5
			style.border_width_bottom = 5
			style.border_color = Color(0.62, 0.28, 0.82)
			style.shadow_size = 8
			style.shadow_color = Color(0.35, 0.1, 0.5, 0.45)
		CardData.Rarity.LEGENDARY:
			style.border_width_left = 6
			style.border_width_top = 6
			style.border_width_right = 6
			style.border_width_bottom = 6
			style.border_color = Color(0.95, 0.78, 0.18)
			style.shadow_size = 12
			style.shadow_color = Color(0.55, 0.4, 0.05, 0.55)

	return style


static func get_card_back_style(back_type: CardBackType = CardBackType.DEFAULT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3

	match back_type:
		CardBackType.DEFAULT:
			style.bg_color = Color(0.12, 0.14, 0.22, 1.0)
			style.border_color = Color(0.35, 0.42, 0.62, 1.0)
		CardBackType.EVENT:
			style.bg_color = Color(0.2, 0.1, 0.18, 1.0)
			style.border_color = Color(0.85, 0.35, 0.55, 1.0)
		CardBackType.BLACKJACK:
			style.bg_color = Color(0.08, 0.1, 0.08, 1.0)
			style.border_color = Color(0.15, 0.55, 0.2, 1.0)
		CardBackType.DEVELOPER:
			style.bg_color = Color(0.15, 0.12, 0.08, 1.0)
			style.border_color = Color(0.95, 0.55, 0.2, 1.0)

	return style


static func get_reveal_duration(rarity: CardData.Rarity) -> float:
	return REVEAL_DURATIONS.get(rarity, 0.28)


static func get_reveal_lift(rarity: CardData.Rarity) -> float:
	return REVEAL_LIFT_OFFSETS.get(rarity, -10.0)


static func get_reveal_glow_alpha(rarity: CardData.Rarity) -> float:
	return REVEAL_GLOW_ALPHAS.get(rarity, 0.0)


static func parse_card_back(back_id: String) -> CardBackType:
	match back_id.to_lower():
		"event":
			return CardBackType.EVENT
		"blackjack":
			return CardBackType.BLACKJACK
		"developer":
			return CardBackType.DEVELOPER
		_:
			return CardBackType.DEFAULT
