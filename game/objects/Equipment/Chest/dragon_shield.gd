extends Base_equip

const MODIFIER_ID := "Dragon_Shield"
const EFFECT_SCRIPT := preload("res://game/objects/Equipment/Chest/dragon_shield_effect.gd")


func effect_on() -> void:
	var player := get_player()
	if player == null:
		return
	if int(player.hp_list.get("black", 0)) < 1 and player.has_method("heal"):
		player.heal(0, 0, 0, 1)
	if player.get_node_or_null(MODIFIER_ID):
		return
	var effect := EFFECT_SCRIPT.new()
	effect.name = MODIFIER_ID
	player.add_child(effect)


func effect_off() -> void:
	var player := get_player()
	if player == null:
		return
	var effect := player.get_node_or_null(MODIFIER_ID)
	if effect:
		effect.queue_free()
