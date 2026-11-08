extends Base_equip

const MODIFIER_ID := "White_Boots"
const DODGE_BONUS := 0.20
const EFFECT_SCRIPT := preload("res://game/objects/Equipment/boots/white_boots_effect.gd")


func effect_on() -> void:
	var player := get_player()
	if player == null:
		return
	player.dodge_chance += DODGE_BONUS
	if player.get_node_or_null(MODIFIER_ID):
		return
	var effect := EFFECT_SCRIPT.new()
	effect.name = MODIFIER_ID
	player.add_child(effect)


func effect_off() -> void:
	var player := get_player()
	if player == null:
		return
	player.dodge_chance = maxf(0.0, player.dodge_chance - DODGE_BONUS)
	var effect := player.get_node_or_null(MODIFIER_ID)
	if effect:
		effect.queue_free()
