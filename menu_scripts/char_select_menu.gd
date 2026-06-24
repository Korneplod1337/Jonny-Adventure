extends CanvasLayer

@export var characters: Array[CharacterSelectEntry] = []
@export var lock_portrait: Texture2D = preload("res://image/main_menu/char_select_lock.png")
@export var lock_portrait_selected: Texture2D = preload("res://image/main_menu/char_select_lock_select.png")

@export_group("Layout")
@export var center_scale := Vector2(1.75, 1.75)
@export var side_scale := Vector2(1.25, 1.25)
@export var side_modulate := Color(0.75, 0.75, 0.75, 0.85)
@export var locked_modulate := Color(0.55, 0.55, 0.55, 0.75)

const MEDAL_EMPTY_SMALL := preload("res://image/main_menu/locations_mark1.png")
const MEDAL_FILLED_SMALL := [
	preload("res://image/main_menu/locations_mark2.png"),
	preload("res://image/main_menu/locations_mark3.png"),
	preload("res://image/main_menu/locations_mark4.png"),
	preload("res://image/main_menu/locations_mark5.png"),
	preload("res://image/main_menu/locations_mark6.png"),
	preload("res://image/main_menu/locations_mark7.png"),
]
const MEDAL_EMPTY_BIG := preload("res://image/main_menu/locations_mark8.png")
const MEDAL_FILLED_BIG := preload("res://image/main_menu/locations_mark9.png")

@onready var _slot_prev2: Control = $Carousel/SlotPrev2
@onready var _slot_prev: Control = $Carousel/SlotPrev
@onready var _slot_center: Button = $Carousel/SlotCenter
@onready var _slot_next: Control = $Carousel/SlotNext
@onready var _slot_next2: Control = $Carousel/SlotNext2
const MEDAL_TEXTURE_SIZE := 48
const MEDAL_SMALL_SCALE := 4  ## 192×192 (×2 от 96)
const MEDAL_BIG_SCALE := 4    ## 192×192 — тот же контейнер, круг в текстуре крупнее
const MEDAL_SMALL_SIZE := Vector2(MEDAL_TEXTURE_SIZE * MEDAL_SMALL_SCALE, MEDAL_TEXTURE_SIZE * MEDAL_SMALL_SCALE)
const MEDAL_BIG_SIZE := Vector2(MEDAL_TEXTURE_SIZE * MEDAL_BIG_SCALE, MEDAL_TEXTURE_SIZE * MEDAL_BIG_SCALE)
const MEDAL_SMALL_SEPARATION := -80  ## перекрываем прозрачные поля 48×48 текстур
const MEDAL_BIG_SEPARATION := -40

@onready var _medals_panel: HBoxContainer = $MedalsPanel
@onready var _small_medals_row: HBoxContainer = $MedalsPanel/SmallMedals

@onready var _medal_slots: Array[TextureRect] = [
	$MedalsPanel/SmallMedals/Medal1,
	$MedalsPanel/SmallMedals/Medal2,
	$MedalsPanel/SmallMedals/Medal3,
	$MedalsPanel/SmallMedals/Medal4,
	$MedalsPanel/SmallMedals/Medal5,
	$MedalsPanel/SmallMedals/Medal6,
]
@onready var _medal_big: TextureRect = $MedalsPanel/MedalBig

var _current_index := 0
var _carousel_slots: Array[Control] = []


func _ready() -> void:
	_carousel_slots = [_slot_prev2, _slot_prev, _slot_center, _slot_next, _slot_next2]
	_setup_medal_sizes()
	visibility_changed.connect(_on_visibility_changed)
	_connect_carousel()
	_refresh_carousel()


func _setup_medal_sizes() -> void:
	_small_medals_row.add_theme_constant_override("separation", MEDAL_SMALL_SEPARATION)
	_medals_panel.add_theme_constant_override("separation", MEDAL_BIG_SEPARATION)
	for slot in _medal_slots:
		slot.custom_minimum_size = MEDAL_SMALL_SIZE
		slot.size = MEDAL_SMALL_SIZE
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_SCALE
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_medal_big.custom_minimum_size = MEDAL_BIG_SIZE
	_medal_big.size = MEDAL_BIG_SIZE
	_medal_big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_medal_big.stretch_mode = TextureRect.STRETCH_SCALE
	_medal_big.size_flags_vertical = Control.SIZE_SHRINK_CENTER


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
	for slot in _carousel_slots:
		if slot != _slot_center:
			slot.pressed.connect(_on_side_slot_pressed.bind(slot))


func _on_side_slot_pressed(slot: Control) -> void:
	var slot_index := _carousel_slots.find(slot)
	if slot_index < 0:
		return
	var offset := slot_index - 2
	if offset == 0:
		return
	_current_index = _wrap_index(_current_index + offset)
	_refresh_carousel()


func _on_visibility_changed() -> void:
	if visible:
		CharacterMedalsManager.load_medals()
		CharacterMedalsManager.ensure_all_characters()
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
	var offsets := [-2, -1, 0, 1, 2]
	for i in offsets.size():
		var is_center = offsets[i] == 0
		_apply_slot(_carousel_slots[i], _get_character_at(offsets[i]), is_center)
	_slot_center.disabled = not _get_character_at(0).unlocked
	_refresh_medals(_get_character_at(0))
	_position_medals_panel.call_deferred()


func _position_medals_panel() -> void:
	var panel: HBoxContainer = $MedalsPanel
	panel.reset_size()
	var panel_size := panel.get_combined_minimum_size()
	panel.size = panel_size
	var slot_rect := _slot_center.get_global_rect()
	panel.global_position = Vector2(
		slot_rect.position.x + slot_rect.size.x * 0.5 - panel_size.x * 0.5,
		slot_rect.position.y - panel_size.y - 28.0
	)


func _refresh_medals(entry: CharacterSelectEntry) -> void:
	if entry == null:
		$MedalsPanel.hide()
		return
	$MedalsPanel.show()
	var medals := CharacterMedalsManager.get_medals(entry.id)
	for i in _medal_slots.size():
		_medal_slots[i].texture = (
			MEDAL_FILLED_SMALL[i] if medals[i] else MEDAL_EMPTY_SMALL
		)
	_medal_big.texture = MEDAL_FILLED_BIG if medals[6] else MEDAL_EMPTY_BIG


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
