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
	#var tween = create_tween()
	#tween.tween_property(tooltip_panel, "modulate:a", 1.0, 1.2)

func _off_hover():
	tooltip_panel.visible = false
	#var tween = create_tween()
	#tween.tween_property(tooltip_panel, "modulate:a", 0.0, 1.2)
	#tween.tween_callback(func(): tooltip_panel.visible = false)
