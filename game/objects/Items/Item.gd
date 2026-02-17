extends Area2D
@onready var interactable: Area2D = $Interactable
@export var item_icon: Texture2D: set = _set_item_icon  # иконка для инвентаря
var item_tooltip: String = "this is test item" # текст для инвентаря
var item_tooltip2: String = "item test is this secret text" # текст для инвентаря продвинутый
var item_id: String = 'hpup'
var cost: int = 1
var where := 'nowhere'
func _ready() -> void:
	interactable.interact = _on_interact
	cost = cost * GameState.cost_multiplier
	if cost < 1:
		interactable.interact_name = 'Take item FOR FREE yey'
	else:
		interactable.interact_name = 'Take item by %s coins' %cost
	
func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print('предмет не видит игрока')
		return
	
	if GameState.coins >= cost and player:
		GameState.add_coins(-cost)
		
		#Эффект
		StatManager.upgrade_stat(player, 'hp', 1) 
		
		
		#stat
		match where:
			'shop':
				StatsManager.add_statistic_progress('sher_loyalty', 1)
			'armor':
				StatsManager.add_statistic_progress('armory_loyalty', 1)
		StatsManager.add_statistic_progress('items_equipped', 1)
		
		# hud
		var hud = get_tree().get_first_node_in_group("HUD")
		hud.add_item(item_icon, item_tooltip, item_tooltip2)
		ItemManager.mark_picked(item_id)
		queue_free()

func _set_item_icon(new_icon: Texture2D) -> void:
	item_icon = new_icon
