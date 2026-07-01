extends Item


func apply_item_effect() -> void:
	ItemManager.apply_last_item_effect(player)
