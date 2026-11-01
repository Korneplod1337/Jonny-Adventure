extends Item

const MODIFIER_ID := "efirblade"
const THRESHOLD_PER_STACK := 0.12


func apply_item_effect() -> void:
	var existing: HitModifier = DamageDealer.get_modifier_by_id(MODIFIER_ID)
	if existing is ExecuteLowHpHitModifier:
		(existing as ExecuteLowHpHitModifier).hp_threshold += THRESHOLD_PER_STACK
		return
	var modifier := ExecuteLowHpHitModifier.new()
	modifier.hp_threshold = THRESHOLD_PER_STACK
	DamageDealer.add_modifier(modifier, MODIFIER_ID)
