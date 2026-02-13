extends Area2D
@onready var interactable: Area2D = $Interactable
@export var item_icon: Texture2D: set = _set_item_icon  # иконка для инвентаря
var item_tooltip: String = "this is test item luul coins" # текст для инвентаря
var item_id: String = 'hpup'
@export var cost: int = 1

func _ready() -> void:
	interactable.interact = _on_interact
	cost = cost * GameState.cost_multiplier
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
		
		#
		var hud = get_tree().get_first_node_in_group("HUD")
		hud.add_item(item_icon, item_tooltip)
		ItemManager.mark_picked(item_id)
		queue_free()

func _set_item_icon(new_icon: Texture2D) -> void:
	item_icon = new_icon
