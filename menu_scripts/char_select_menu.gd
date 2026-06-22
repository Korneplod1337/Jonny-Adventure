extends CanvasLayer

@export var characters: Array[CharacterSelectEntry] = []
@export var lock_portrait: Texture2D = preload("res://image/main_menu/char_select_lock.png")
@export var lock_portrait_selected: Texture2D = preload("res://image/main_menu/char_select_lock_select.png")

@export_group("Layout")
@export var center_scale := Vector2(2.0, 2.0)
@export var side_scale := Vector2(1.5, 1.5)
@export var side_modulate := Color(0.75, 0.75, 0.75, 0.85)
@export var locked_modulate := Color(0.55, 0.55, 0.55, 0.75)

@onready var _slot_prev: Control = $Carousel/SlotPrev
@onready var _slot_center: Button = $Carousel/SlotCenter
@onready var _slot_next: Control = $Carousel/SlotNext

var _current_index := 0


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_connect_carousel()
	_refresh_carousel()



func _make_entry(
	id: String, display_name: String,
	portrait: Texture2D, portrait_selected: Texture2D,
	name_texture: Texture2D, unlocked: bool
) -> CharacterSelectEntry:
	var entry := CharacterSelectEntry.new()
	entry.id = id
	entry.display_name = display_name
	entry.portrait = portrait
	entry.portrait_selected = portrait_selected
	entry.name_texture = name_texture
	entry.unlocked = unlocked
	return entry


func _connect_carousel() -> void:
	_slot_center.pressed.connect(_on_center_pressed)
	$BtnLeft.pressed.connect(_on_prev_pressed)
	$BtnRight.pressed.connect(_on_next_pressed)
	_slot_prev.pressed.connect(_on_prev_pressed)
	_slot_next.pressed.connect(_on_next_pressed)


func _on_visibility_changed() -> void:
	if visible:
		_refresh_carousel()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_left"):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_center_pressed()
		get_viewport().set_input_as_handled()


func _wrap_index(index: int) -> int:
	var count := characters.size()
	if count == 0:
		return 0
	return ((index % count) + count) % count


func _on_prev_pressed() -> void:
	if characters.is_empty():
		return
	_current_index = _wrap_index(_current_index - 1)
	_refresh_carousel()


func _on_next_pressed() -> void:
	if characters.is_empty():
		return
	_current_index = _wrap_index(_current_index + 1)
	_refresh_carousel()


func _get_character_at(offset: int) -> CharacterSelectEntry:
	if characters.is_empty():
		return null
	return characters[_wrap_index(_current_index + offset)]


func _refresh_carousel() -> void:
	if characters.is_empty():
		return
	_apply_slot(_slot_prev, _get_character_at(-1), false)
	_apply_slot(_slot_center, _get_character_at(0), true)
	_apply_slot(_slot_next, _get_character_at(1), false)
	_slot_center.disabled = not _get_character_at(0).unlocked


func _apply_slot(slot: Control, entry: CharacterSelectEntry, is_center: bool) -> void:
	if entry == null:
		slot.hide()
		return

	slot.show()
	slot.scale = center_scale if is_center else side_scale

	var portrait: TextureRect = slot.get_node("Portrait")
	var name_label: Label = slot.get_node_or_null("Name")
	var name_sprite: TextureRect = slot.get_node_or_null("NameSprite")
	var select_overlay: CanvasItem = slot.get_node_or_null("SelectOverlay")

	var texture := entry.portrait
	if not entry.unlocked:
		texture = entry.portrait_locked if entry.portrait_locked else (
			lock_portrait_selected if is_center else lock_portrait
		)
		slot.modulate = locked_modulate
	elif is_center:
		slot.modulate = Color.WHITE
	else:
		slot.modulate = side_modulate

	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = texture
	if entry.unlocked and is_center:
		portrait.texture = entry.portrait_selected if entry.portrait_selected else entry.portrait

	if select_overlay:
		select_overlay.visible = false
		select_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if name_sprite and entry.name_texture:
		name_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		name_sprite.texture = entry.name_texture
		name_sprite.show()
		if name_label:
			name_label.hide()
	elif name_label:
		name_label.text = entry.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.clip_text = false
		name_label.show()
		if name_sprite:
			name_sprite.hide()


func _on_center_pressed() -> void:
	var entry := _get_character_at(0)
	if entry == null or not entry.unlocked:
		return
	DungeonManager.selected_character = entry.id
	hide()
	get_parent().get_node("Diff_select_menu").show()


func _on_exit_pressed() -> void:
	hide()
	get_parent().get_node("start_menu").show()


func _on_exit_mouse_entered() -> void:
	$exit/exit_select.show()


func _on_exit_mouse_exited() -> void:
	$exit/exit_select.hide()
