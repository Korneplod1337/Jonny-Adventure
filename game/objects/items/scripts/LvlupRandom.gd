extends Item

var rand : int

func _ready() -> void:
	randomize_stat()
	cost += 3
	interactable.interact = _on_interact
	cost = cost * GameState.cost_multiplier
	if cost < 1:
		interactable.interact_name = 'lvlup'
	else:
		interactable.interact_name = 'Take lvlup by %s coins' %cost

func _on_interact():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print('предмет не видит игрока')
		return
	
	if GameState.coins >= cost and player:
		GameState.add_coins(-cost)
		
		apply_item_effect()
		
		match where:
			'shop':
				StatsManager.add_statistic_progress('sher_loyalty', 1)
			'armor':
				StatsManager.add_statistic_progress('armory_loyalty', 1)
		
		StatsManager.add_statistic_progress('items_equipped', 1)
		ItemManager.mark_picked(item_id)
		queue_free()


func apply_item_effect() -> void:
	print(rand, player)
	match rand:
		0: StatManager.upgrade_stat(player, 'hp', 1) 
		1: StatManager.upgrade_stat(player, 'luck', 1)  
		2: StatManager.upgrade_stat(player, 'move_speed', 1) 
		3: StatManager.upgrade_stat(player, 'magic', 1) 
		4: StatManager.upgrade_stat(player, 'damage', 1) 
		5: StatManager.upgrade_stat(player, 'fire_rate', 1) 
		6: StatManager.upgrade_stat(player, 'spread', 1) 
		7: StatManager.upgrade_stat(player, 'range', 1) 
		_: print('apply item effect error (lvlup)')
	
func randomize_stat() -> void:
	if where == 'shop':		rand = randi() % 4
	elif where == 'armory':	rand = randi() % 4 + 4
	else:					rand = randi() % 8
	$AnimatedSprite2D.frame = rand
	
