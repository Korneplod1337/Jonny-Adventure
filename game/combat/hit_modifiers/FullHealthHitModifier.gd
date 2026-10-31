class_name FullHealthHitModifier
extends HitModifier

@export var multiplier: float = 1.30


func is_per_target() -> bool:
	return true


func apply(info: DamageInfo) -> void:
	if info.target == null:
		return
	var hp_v = info.target.get("current_hp")
	var max_v = info.target.get("base_hp")
	if hp_v == null or max_v == null:
		return
	var hp: int = int(hp_v)
	var max_hp: int = int(max_v)
	if max_hp <= 0 or hp < max_hp:
		return
	info.damage *= multiplier
