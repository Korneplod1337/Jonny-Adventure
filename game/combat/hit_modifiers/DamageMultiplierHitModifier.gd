class_name DamageMultiplierHitModifier
extends HitModifier

@export var multiplier: float = 2.0


func apply(info: DamageInfo) -> void:
	info.damage *= multiplier
