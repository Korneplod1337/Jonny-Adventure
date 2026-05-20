extends Control
class_name InventorySlot

@onready var icon: TextureRect = $Icon
@onready var tooltip_panel: Panel = $ToolTipPanel
@onready var tooltip_label: Label = $ToolTipPanel/Label
var _pending_tooltip: String = ""
var _pending_icon: Texture2D = null

func set_icon(tex: Texture2D):
	if icon:
		icon.texture = tex
	else:
		_pending_icon = tex

func _ready():
	tooltip_panel.top_level = true
	mouse_filter = MOUSE_FILTER_PASS
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_off_hover)
	if _pending_tooltip != "":
		set_tooltip(_pending_tooltip)
	if _pending_icon:
		icon.texture = _pending_icon

func set_tooltip(text: String):
	if tooltip_label:
		tooltip_label.text = text
		
		# Авто-размер панели под текст
		await get_tree().process_frame  # ждём update текста
		
		var label_size = tooltip_label.get_minimum_size() + Vector2(16, 16)  # padding
		tooltip_panel.size = Vector2(100, label_size.y)
		
	else:
		_pending_tooltip = text
		

func _on_hover():
	tooltip_panel.visible = true
	tooltip_panel.global_position = global_position + Vector2(-tooltip_panel.size.x * 2, 0)
	set_tooltip(_pending_tooltip)
	# await get_tree().process_frame

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size 
	var tooltip_bottom := tooltip_panel.global_position.y + tooltip_panel.size.y + 150
	var overflow := tooltip_bottom - viewport_size.y
	if overflow > 0:
		tooltip_panel.global_position.y -= overflow

func _off_hover():
	tooltip_panel.visible = false
