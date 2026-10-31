class_name ExecuteLowHpHitModifier
extends HitModifier

@export var hp_threshold: float = 0.12


func is_per_target() -> bool:
	return true


func apply(info: DamageInfo) -> void:
	if info.target == null:
		return
	if info.target is Boss:
		return
	var hp_v = info.target.get("current_hp")
	var max_v = info.target.get("base_hp")
	if hp_v == null or max_v == null:
		return
	var hp: int = int(hp_v)
	var max_hp: int = int(max_v)
	if max_hp <= 0:
		return
	if float(hp) / float(max_hp) >= hp_threshold:
		return
	info.damage = maxf(info.damage, float(hp))
