extends Item

var skip_base_price := false
var rand: int = 0


func _ready() -> void:
	randomize_stat()
	interactable.interact = _on_interact
	if not skip_base_price:
		cost += 3
	cost = int(cost * GameState.cost_multiplier)
	if cost < 1:
		interactable.interact_name = "def lvlup"
	else:
		interactable.interact_name = "Take def lvlup by %s coins" % cost


func _on_interact() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("предмет не видит игрока")
		return

	if GameState.coins >= cost and player:
		GameState.add_coins(-cost)
		apply_item_effect()
		match where:
			"shop":
				StatsManager.add_statistic_progress("shop_loyalty", 1)
			"armor":
				StatsManager.add_statistic_progress("armory_loyalty", 1)
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
		_:
			print("apply item effect error (lvlup_def)")


func randomize_stat() -> void:
	rand = randi() % 4
	$AnimatedSprite2D.frame = rand
