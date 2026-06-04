class_name PenetrationHitModifier
extends HitModifier

@export var bonus: int = 1


func apply(info: DamageInfo) -> void:
	info.penetration += bonus
