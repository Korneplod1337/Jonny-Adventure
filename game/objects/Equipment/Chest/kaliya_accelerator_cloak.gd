extends Base_equip

const MODIFIER_ID := "Accelerator_Cloak"
const EFFECT_SCRIPT := preload("res://game/objects/Equipment/Chest/accelerator_cloak_effect.gd")


func effect_on() -> void:
	var player := get_player()
	if player == null or player.get_node_or_null(MODIFIER_ID):
		return
	var effect := EFFECT_SCRIPT.new()
	effect.name = MODIFIER_ID
	player.add_child(effect)
	player.speed_bonus += 1


func effect_off() -> void:
	var player := get_player()
	if player == null:
		return
	var effect := player.get_node_or_null(MODIFIER_ID)
	if effect:
		effect.queue_free()
	player.EquipFireRateBoost = 1.0
	player.speed_bonus -= 1
