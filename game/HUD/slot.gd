extends Control
class_name InventorySlot

@onready var icon: TextureRect = $Icon
@onready var tooltip_panel: Panel = $ToolTipPanel
@onready var tooltip_label: Label = $ToolTipPanel/Label
var count_label: Label
var _pending_tooltip: String = ""
var _pending_icon: Texture2D = null
var _pending_count: int = 1

func set_icon(tex: Texture2D):
	if icon:
		icon.texture = tex
	else:
		_pending_icon = tex

func set_count(count: int) -> void:
	_pending_count = count
	if count_label:
		_apply_count(count)

func _apply_count(count: int) -> void:
	if not count_label:
		return
	if count > 1:
		count_label.text = str(count)
		count_label.show()
	else:
		count_label.hide()

func _ready():
	count_label = get_node_or_null("CountLabel")
	tooltip_panel.top_level = true
	mouse_filter = MOUSE_FILTER_PASS
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_off_hover)
	if _pending_tooltip != "":
		set_tooltip(_pending_tooltip)
	if _pending_icon:
		icon.texture = _pending_icon
	_apply_count(_pending_count)

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
