class_name ExecuteLowHpHitModifier
extends HitModifier

## Порог HP для инстакилла (Efir Blade +0.12 за стак). Без капа 1.0 —
## иначе full HP (ratio == 1) никогда не проходит проверку «< threshold».
var hp_threshold: float = 0.0


func is_per_target() -> bool:
	return true


func apply(info: DamageInfo) -> void:
	if info.target == null or hp_threshold <= 0.0:
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
	# «меньше порога»: при threshold > 1.0 казнит и с полного HP.
	if float(hp) / float(max_hp) >= hp_threshold:
		return
	info.damage = maxf(info.damage, float(hp))
	# Иначе effect_protection в hit() уменьшит урон и враг выживет.
	info.is_clear = true
