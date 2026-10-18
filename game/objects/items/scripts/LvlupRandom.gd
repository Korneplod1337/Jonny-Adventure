extends Item

var skip_base_price := false
var rand: int = 0


func _ready() -> void:
	randomize_stat()
	interactable.interact = _on_interact
	if not skip_base_price:
		cost += 3
	_base_cost = cost
	refresh_price_label()
	if not GameState.prices_changed.is_connected(refresh_price_label):
		GameState.prices_changed.connect(refresh_price_label)


func refresh_price_label() -> void:
	var shown: int = int(round((_base_cost + GS.cost_plus) * GS.cost_multiplier))
	if _base_cost < 1:
		interactable.interact_name = "lvlup"
	else:
		interactable.interact_name = "Take lvlup by %s coins" % shown


func _on_interact() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("предмет не видит игрока")
		return

	var price := _final_price()
	if GameState.coins >= price and player:
		GameState.add_coins(-price)
		apply_item_effect()
		match where:
			"shop":
				StatsManager.add_statistic_progress("shop_loyalty", 1)
				SoundManager.play_buy()
			"armory", "armor":
				StatsManager.add_statistic_progress("armory_loyalty", 1)
				SoundManager.play_buy()
		StatsManager.add_statistic_progress("items_equipped", 1)
		if AchivStatsRegistry.ITEM_PICKUP_STATS.has(item_id):
			StatsManager.add_statistic_progress(AchivStatsRegistry.ITEM_PICKUP_STATS[item_id], 1)
		ItemManager.mark_picked(item_id)
		queue_free()


func apply_item_effect() -> void:
	match rand:
		0:
			StatManager.upgrade_stat(player, "hp", 1)
		1:
			StatManager.upgrade_stat(player, "luck", 1)
		2:
			StatManager.upgrade_stat(player, "move_speed", 1)
		3:
			StatManager.upgrade_stat(player, "magic", 1)
		4:
			StatManager.upgrade_stat(player, "damage", 1)
		5:
			StatManager.upgrade_stat(player, "fire_rate", 1)
		6:
			StatManager.upgrade_stat(player, "spread", 1)
		7:
			StatManager.upgrade_stat(player, "range", 1)
		_:
			print("apply item effect error (lvlup)")


func randomize_stat() -> void:
	rand = randi() % 8
	$AnimatedSprite2D.frame = rand
