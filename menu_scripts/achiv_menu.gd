extends Control

const TOOLTIP_FONT_SIZE := 32
const TOOLTIP_OFFSET := Vector2(32, 40)

@onready var achievements_container = self

var _tooltip: PanelContainer
var _tooltip_label: Label


func _ready():
	_setup_tooltip()
	update_achievement_list()
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(_popup_path: String) -> void:
	update_achievement_list()

func update_achievement_list():
	for child in achievements_container.get_children():
		child.queue_free()

	var sorted_keys = AchievementManager.achievements.keys()
	sorted_keys.sort_custom(func(a: String, b: String) -> bool:
		var ach_a = AchievementManager.achievements[a]
		var ach_b = AchievementManager.achievements[b]
		if ach_a["unlocked"] != ach_b["unlocked"]:
			return ach_a["unlocked"]
		return ach_a["name"].nocasecmp_to(ach_b["name"]) < 0
	)

	for key in sorted_keys:
		var achievement = AchievementManager.achievements[key]
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		
		var icon = TextureRect.new()
		var icon_path: String = achievement["unlocked_icon"] if achievement["unlocked"] \
			else "res://image/achievements/menu_achiv/lock_achiv.png"
		if icon_path == "" or icon_path == "-":
			icon_path = "res://image/achievements/menu_achiv/lock_achiv.png"
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(96, 96)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var reward_text := _get_unlock_reward_text(key) if achievement["unlocked"] else ""
		if reward_text != "":
			icon.mouse_filter = Control.MOUSE_FILTER_STOP
			icon.mouse_entered.connect(_on_icon_hover.bind(reward_text))
			icon.mouse_exited.connect(_on_icon_unhover)
		else:
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var label = Label.new()
		var font = load("res://Fonts/JonnyAdventureFont2.ttf")
		label.add_theme_font_override('font', font)
		label.text = (achievement["name"]) if achievement["unlocked"] else (achievement["name"] + " - " + achievement["desc"])
		label.add_theme_color_override("font_color", Color(0, 0, 0))
		label.add_theme_font_size_override('font_size', 48)
		
		
		hbox.add_child(icon)
		hbox.add_child(label)
		achievements_container.add_child(hbox)


func _get_unlock_reward_text(ach_id: String) -> String:
	var names: Array[String] = []
	var seen: Dictionary = {}

	if AchivStatsRegistry.CHARACTER_UNLOCKS.has(ach_id):
		for char_id in AchivStatsRegistry.CHARACTER_UNLOCKS[ach_id]:
			_append_unique(names, seen, str(char_id))

	if AchivStatsRegistry.ITEM_UNLOCKS.has(ach_id):
		for item_id in AchivStatsRegistry.ITEM_UNLOCKS[ach_id]:
			_append_unique(names, seen, _resolve_item_name(str(item_id)))

	if AchivStatsRegistry.EQUIP_UNLOCKS.has(ach_id):
		for rule in AchivStatsRegistry.EQUIP_UNLOCKS[ach_id]:
			_append_unique(names, seen, _resolve_equip_name(str(rule["equipment_id"])))

	if AchivStatsRegistry.LOCATION_UNLOCKS.has(ach_id):
		var loc: int = int(AchivStatsRegistry.LOCATION_UNLOCKS[ach_id])
		_append_unique(names, seen, "Location %d" % loc)

	return "\n".join(names)


func _append_unique(names: Array[String], seen: Dictionary, display_name: String) -> void:
	if display_name == "" or seen.has(display_name):
		return
	seen[display_name] = true
	names.append(display_name)


func _resolve_item_name(item_id: String) -> String:
	for pool in ItemManager.POOLS.values():
		for item in pool:
			if item.id == item_id:
				return _name_from_scene(item.scene, item_id)
	return item_id


func _resolve_equip_name(equip_id: String) -> String:
	for pool in EquipManager.POOLS.values():
		for equip in pool:
			if equip.id == equip_id:
				return _name_from_scene(equip.scene, equip_id)
	return equip_id


func _name_from_scene(scene: PackedScene, fallback: String) -> String:
	var inst: Node = scene.instantiate()
	var display_name := fallback
	if "item_name" in inst and str(inst.item_name) != "" and str(inst.item_name) != "-":
		display_name = str(inst.item_name)
	elif "interact_name" in inst and str(inst.interact_name) != "":
		display_name = str(inst.interact_name)
	inst.free()
	return display_name


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
	# Parent to ScrollContainer so the tooltip does not occupy a grid cell.
	get_parent().add_child.call_deferred(_tooltip)


func _on_icon_hover(reward_text: String) -> void:
	if _tooltip == null:
		return
	_tooltip_label.text = reward_text
	_tooltip.visible = true
	_position_tooltip()


func _on_icon_unhover() -> void:
	if _tooltip:
		_tooltip.visible = false


func _process(_delta: float) -> void:
	if _tooltip and _tooltip.visible:
		_position_tooltip()


func _position_tooltip() -> void:
	_tooltip.global_position = get_viewport().get_mouse_position() + TOOLTIP_OFFSET
