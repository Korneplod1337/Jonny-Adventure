extends Area2D
class_name Item
var GS = GameState

@onready var interactable: Area2D = $Interactable
@export var item_icon: Texture2D: set = _set_item_icon  # иконка для инвентаря
var where := 'nowhere'
var player : CharacterBody2D

@export var item_tooltip: String = 	"this is test item" 				# текст для инвентаря
@export var item_tooltip2: String = 	"item test is this secret text" 	# текст для инвентаря продвинутый
@export var item_id: String = 'hpup'
@export var cost: int = 0

@export var effect_power: float = 1

func _ready() -> void:
	interactable.interact = _on_interact
	cost = cost * GameState.cost_multiplier
	if cost < 1:
		interactable.interact_name = item_tooltip
	else:
		interactable.interact_name = "%s by %s coins" % [item_tooltip, (cost + GS.cost_plus) * GS.cost_multiplier]

func _on_interact():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print('предмет не видит игрока')
		return
	
	if GameState.coins >= ((cost + GS.cost_plus) * GS.cost_multiplier) and player:
		GameState.add_coins((-cost - GS.cost_plus) * GS.cost_multiplier)
		
		apply_item_effect()
		
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


func apply_item_effect() -> void:
	StatManager.upgrade_stat(player, 'hp', 1) 
	player.heal(1)
