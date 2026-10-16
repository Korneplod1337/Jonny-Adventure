extends Area2D

@export var effect_power: float = 5.0

var _picked := false


func _ready() -> void:
	var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim:
		anim.play()
	PickupIdleFloat.begin(self)


func _on_body_entered(body: Node) -> void:
	if _picked or not body.is_in_group("player"):
		return
	_picked = true

	var amount := int(effect_power)
	body.hp_bonus += amount
	body.speed_bonus += amount
	body.luck_bonus += amount
	body.magic_bonus += amount
	body.damage_bonus += amount
	body.accuracy_bonus += amount
	body.range_bonus += amount
	body.fire_rate_bonus += amount

	body.max_hp = int(StatManager.get_stat(body, "hp"))
	body.move_speed = StatManager.get_stat(body, "move_speed")
	body.luck = StatManager.get_stat(body, "luck")
	body.magic = StatManager.get_stat(body, "magic")
	body.damage = StatManager.get_stat(body, "damage")
	body.spread = StatManager.get_stat(body, "spread")
	body.atk_range = StatManager.get_stat(body, "range")
	body.fire_rate = StatManager.get_stat(body, "fire_rate")
	body._emit_stats_changed()
	if body.has_method("_emit_bonuses_changed"):
		body._emit_bonuses_changed()
	if body.has_method("_emit_hp_visual_changed"):
		body._emit_hp_visual_changed()

	queue_free()
