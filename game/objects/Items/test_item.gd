extends Area2D
@onready var interactable: Area2D = $Interactable
@export var item_icon: Texture2D: set = _set_item_icon  # иконка для инвентаря
@export var item_tooltip: String = "this is test item luul" # текст для инвентаря

func _ready() -> void:
	interactable.interact = _on_interact
	
func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print('предмет не видит игрока')
	
	#Эффект
	StatManager.upgrade_stat(player, 'hp', 1) 
	
	#
	var hud = get_tree().get_first_node_in_group("HUD")
	hud.add_item(item_icon, item_tooltip)
	
	queue_free()

func _set_item_icon(new_icon: Texture2D):
	item_icon = new_icon
