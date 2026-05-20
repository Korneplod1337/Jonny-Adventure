extends InventorySlot
class_name InventorySlotAlt

func _ready():
	mouse_filter = MOUSE_FILTER_PASS
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_off_hover)
	if _pending_tooltip != "":
		set_tooltip(_pending_tooltip)
	if _pending_icon:
		icon.texture = _pending_icon
	
func _on_hover():
	tooltip_panel.visible = true
