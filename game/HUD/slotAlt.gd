extends InventorySlot
class_name InventorySlotAlt

func _ready():
	count_label = get_node_or_null("CountLabel")
	mouse_filter = MOUSE_FILTER_PASS
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_off_hover)
	if _pending_tooltip != "":
		set_tooltip(_pending_tooltip)
	if _pending_icon:
		icon.texture = _pending_icon
	_apply_count(_pending_count)
func _on_hover():
	tooltip_panel.visible = true
