extends Control
class_name InventorySlot

const ENCHANT_FRAMES := preload("res://game/objects/Equipment/_enchantments/enchant_shader_frames.tres")

@onready var icon: TextureRect = $Icon
@onready var tooltip_panel: Panel = $ToolTipPanel
@onready var tooltip_label: Label = $ToolTipPanel/Label
var count_label: Label
var _hover_overlay: ColorRect
var _hover_tween: Tween
var _cd_overlay: ColorRect
var _enchant_mask: Sprite2D
var _enchant_sprite: AnimatedSprite2D
var _pending_enchant_anim: String = ""

var HOVER_OVERLAY_COLOR := Color(0, 0, 0, 0.5)
var COOLDOWN_OVERLAY_COLOR := Color(0, 0, 0, 0.5)
var _pending_tooltip: String = ""
var _pending_icon: Texture2D = null
var _pending_count: int = 1
var _pending_cooldown: float = 0.0

func set_icon(tex: Texture2D):
	if icon:
		icon.texture = tex
	else:
		_pending_icon = tex
	if _enchant_mask and _enchant_mask.visible:
		_sync_enchant_mask_texture()


func set_enchantment(enchantment: EnchantmentResource) -> void:
	if enchantment == null:
		clear_enchantment()
		return
	var anim_name := enchantment.get_visual_animation()
	if not ENCHANT_FRAMES.has_animation(anim_name):
		clear_enchantment()
		return
	if not icon:
		_pending_enchant_anim = anim_name
		return
	_ensure_enchant_sprite()
	_sync_enchant_mask_texture()
	icon.visible = false
	_enchant_mask.visible = true
	_enchant_sprite.visible = true
	_enchant_sprite.play(anim_name)


func clear_enchantment() -> void:
	_pending_enchant_anim = ""
	if icon:
		icon.visible = true
	if _enchant_sprite:
		_enchant_sprite.visible = false
		_enchant_sprite.stop()
	if _enchant_mask:
		_enchant_mask.visible = false


func _sync_enchant_mask_texture() -> void:
	if _enchant_mask == null or icon == null or icon.texture == null:
		return
	_enchant_mask.texture = icon.texture
	_enchant_mask.position = icon.position
	var tex_size := icon.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	# Fit native texture into the Icon's 24×24 box, then apply Icon.scale.
	var fit := Vector2(icon.size) / tex_size
	if icon.size == Vector2.ZERO:
		fit = Vector2(24, 24) / tex_size
	_enchant_mask.scale = fit * icon.scale
	_enchant_sprite.position = tex_size * 0.5


func _ensure_enchant_sprite() -> void:
	if _enchant_mask:
		return
	# Sprite2D + CLIP_CHILDREN_AND_DRAW masks by icon alpha (same as world pickups).
	# TextureRect.clip_contents only clips a rectangle, so transparent pixels leaked.
	_enchant_mask = Sprite2D.new()
	_enchant_mask.name = "EnchantMask"
	_enchant_mask.centered = false
	_enchant_mask.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_enchant_mask.visible = false
	add_child(_enchant_mask)
	move_child(_enchant_mask, icon.get_index() + 1)

	_enchant_sprite = AnimatedSprite2D.new()
	_enchant_sprite.sprite_frames = ENCHANT_FRAMES
	_enchant_sprite.centered = true
	_enchant_sprite.rotation = 0.5235988
	_enchant_sprite.scale = Vector2(1.5, 1.5)
	_enchant_sprite.visible = false
	_enchant_mask.add_child(_enchant_sprite)

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

func _ensure_hover_overlay() -> void:
	if _hover_overlay:
		return
	_hover_overlay = ColorRect.new()
	_hover_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hover_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	_hover_overlay.color = Color(0, 0, 0, 0)
	add_child(_hover_overlay)
	move_child(_hover_overlay, 0)


func _ensure_cooldown_overlay() -> void:
	if _cd_overlay:
		return
	_cd_overlay = ColorRect.new()
	_cd_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	_cd_overlay.color = COOLDOWN_OVERLAY_COLOR
	_cd_overlay.visible = false
	add_child(_cd_overlay)
	move_child(_cd_overlay, get_child_count() - 1)


func _cooldown_cover_size() -> Vector2:
	var slot_size := size
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		slot_size = custom_minimum_size
	# Icon uses scale (e.g. ×3); cover the visual footprint, not just Control.size.
	if icon:
		var icon_visual := icon.size * icon.scale
		slot_size.x = maxf(slot_size.x, icon_visual.x)
		slot_size.y = maxf(slot_size.y, icon_visual.y)
	# Ceil so float→pixel rounding never leaves a 1px gap at the edge.
	return Vector2(ceili(slot_size.x), ceili(slot_size.y))


## ratio 1.0 = full cooldown lock, 0.0 = ready. Dark bar shrinks from top.
func set_cooldown_progress(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	_pending_cooldown = ratio
	if not is_inside_tree():
		return
	_ensure_cooldown_overlay()
	if ratio <= 0.001:
		_cd_overlay.visible = false
		return
	var cover := _cooldown_cover_size()
	_cd_overlay.visible = true
	_cd_overlay.position = Vector2.ZERO
	_cd_overlay.size = Vector2(cover.x, ceili(cover.y * ratio))


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
	if _pending_enchant_anim != "":
		var anim := _pending_enchant_anim
		_pending_enchant_anim = ""
		_ensure_enchant_sprite()
		_sync_enchant_mask_texture()
		icon.visible = false
		_enchant_mask.visible = true
		_enchant_sprite.visible = true
		_enchant_sprite.play(anim)
	_apply_count(_pending_count)
	if _pending_cooldown > 0.0:
		set_cooldown_progress(_pending_cooldown)

func set_tooltip(text: String):
	if tooltip_label:
		tooltip_label.text = text
		
		# Авто-размер панели под текст
		await get_tree().process_frame  # ждём update текста
		
		var label_size = tooltip_label.get_minimum_size() + Vector2(16, 16)  # padding
		tooltip_panel.size = Vector2(100, label_size.y)
		
	else:
		_pending_tooltip = text
		

func _set_hover_visual(active: bool) -> void:
	_ensure_hover_overlay()
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	var target_color := HOVER_OVERLAY_COLOR if active else Color(0, 0, 0, 0)
	_hover_tween.tween_property(_hover_overlay, "color", target_color, 0.1)

func _on_hover():
	_set_hover_visual(true)
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
	_set_hover_visual(false)
	tooltip_panel.visible = false
