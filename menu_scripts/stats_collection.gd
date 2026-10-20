extends ScrollContainer

## Set false to remove hover name popups without touching the rest of the page.
const ENABLE_HOVER_TOOLTIP := true

const ITEM_ICON_SIZE := 48
const EQUIP_ICON_SIZE := 96
const ITEM_COLUMNS := 16
const EQUIP_COLUMNS := 10
const TOOLTIP_FONT_SIZE := 32
const TOOLTIP_OFFSET := Vector2(32, 40)

@onready var _items_grid: GridContainer = $Content/ItemsGrid
@onready var _equip_grid: GridContainer = $Content/EquipGrid

var _tooltip: PanelContainer
var _tooltip_label: Label


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_setup_grid(_items_grid, ITEM_COLUMNS)
	_setup_grid(_equip_grid, EQUIP_COLUMNS)
	if ENABLE_HOVER_TOOLTIP:
		_setup_tooltip()


func _setup_grid(grid: GridContainer, columns: int) -> void:
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func rebuild() -> void:
	_clear_grid(_items_grid)
	_clear_grid(_equip_grid)

	var item_seen: Dictionary = {}
	for pool in ItemManager.POOLS.values():
		for item in pool:
			var id: String = item.id
			if item_seen.has(id):
				continue
			item_seen[id] = true
			_add_icon(_items_grid, {"id": id, "scene": item.scene, "kind": "item"}, ITEM_ICON_SIZE)

	var equip_seen: Dictionary = {}
	for equip in EquipManager.POOLS.get("all", []):
		var id: String = equip.id
		if equip_seen.has(id) or item_seen.has(id):
			continue
		equip_seen[id] = true
		_add_icon(_equip_grid, {"id": id, "scene": equip.scene, "kind": "equip"}, EQUIP_ICON_SIZE)


func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()


func _add_icon(grid: GridContainer, entry: Dictionary, icon_size: int) -> void:
	var visual: Dictionary = _extract_visual(entry)
	if visual.icon == null:
		return

	var rect := TextureRect.new()
	rect.texture = visual.icon
	rect.custom_minimum_size = Vector2(icon_size, icon_size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var discovered := _is_discovered(entry)
	if not discovered:
		rect.modulate = Color(0, 0, 0, 1)

	if ENABLE_HOVER_TOOLTIP and discovered:
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		rect.mouse_entered.connect(_on_icon_hover.bind(str(visual.name)))
		rect.mouse_exited.connect(_on_icon_unhover)
	else:
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	grid.add_child(rect)


func _is_discovered(entry: Dictionary) -> bool:
	var id: String = entry.id
	if entry.kind == "item":
		return ItemManager.is_discovered(id)
	return EquipManager.is_picked(id) or ItemManager.is_discovered(id)


func _extract_visual(entry: Dictionary) -> Dictionary:
	var inst: Node = entry.scene.instantiate()
	var icon: Texture2D = null
	var display_name: String = str(entry.id)

	if "item_icon" in inst and inst.item_icon != null:
		icon = inst.item_icon
	elif "equip_icon" in inst and inst.equip_icon != null:
		icon = inst.equip_icon

	if "item_name" in inst and str(inst.item_name) != "" and str(inst.item_name) != "-":
		display_name = str(inst.item_name)
	elif "interact_name" in inst and str(inst.interact_name) != "":
		display_name = str(inst.interact_name)

	inst.free()
	return {"icon": icon, "name": display_name}


# --- Hover tooltip (remove/disable via ENABLE_HOVER_TOOLTIP) ---

func _setup_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.top_level = true
	_tooltip.z_index = 100

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.101961, 0.101961, 0.180392, 0.92)
	style.set_content_margin_all(8)
	_tooltip.add_theme_stylebox_override("panel", style)

	_tooltip_label = Label.new()
	_tooltip_label.add_theme_font_override("font", load("res://Fonts/JonnyAdventureFont.ttf"))
	_tooltip_label.add_theme_font_size_override("font_size", TOOLTIP_FONT_SIZE)
	_tooltip_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9, 1))
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(_tooltip_label)
	add_child(_tooltip)


func _on_icon_hover(item_name: String) -> void:
	if not ENABLE_HOVER_TOOLTIP or _tooltip == null:
		return
	_tooltip_label.text = item_name
	_tooltip.visible = true
	_position_tooltip()


func _on_icon_unhover() -> void:
	if _tooltip:
		_tooltip.visible = false


func _process(_delta: float) -> void:
	if ENABLE_HOVER_TOOLTIP and _tooltip and _tooltip.visible:
		_position_tooltip()


func _position_tooltip() -> void:
	_tooltip.global_position = get_viewport().get_mouse_position() + TOOLTIP_OFFSET
