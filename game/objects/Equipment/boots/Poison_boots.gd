extends Base_equip

const MODIFIER_ID := "Poison_boots"
const TRAIL_SCRIPT := preload("res://game/objects/Equipment/boots/poison_boots_trail.gd")


func effect_on() -> void:
	var player := get_player()
	if player == null or player.get_node_or_null(MODIFIER_ID):
		return
	var trail := TRAIL_SCRIPT.new()
	trail.name = MODIFIER_ID
	player.add_child(trail)


func effect_off() -> void:
	var player := get_player()
	if player == null:
		return
	var trail := player.get_node_or_null(MODIFIER_ID)
	if trail:
		trail.queue_free()
