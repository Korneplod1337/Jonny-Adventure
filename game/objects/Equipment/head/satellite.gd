extends Base_equip

const BUFF_ITEM_ID := "satellitebuff"
const BUFF_WEIGHT_BONUS := 5.0


func effect_on() -> void:
	GameState.SatelliteOrbit = true
	ItemManager.add_runtime_weight(BUFF_ITEM_ID, BUFF_WEIGHT_BONUS)
	var player := get_player()
	if player and player.get_node_or_null("SatelliteOrbit") == null:
		var ctrl := SatelliteOrbitController.new()
		ctrl.name = "SatelliteOrbit"
		player.add_child(ctrl)


func effect_off() -> void:
	GameState.SatelliteOrbit = false
	ItemManager.add_runtime_weight(BUFF_ITEM_ID, -BUFF_WEIGHT_BONUS)
	var player := get_player()
	if player:
		var ctrl := player.get_node_or_null("SatelliteOrbit")
		if ctrl and ctrl.has_method("clear_all"):
			ctrl.clear_all()
		if ctrl:
			ctrl.queue_free()
	# Solaris сам переключит режим по GameState в следующем тике.
