extends Control

@onready var achievements_container = self

func _ready():
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
		
		var label = Label.new()
		var font = load("res://Fonts/JonnyAdventureFont2.ttf")
		label.add_theme_font_override('font', font)
		label.text = (achievement["name"]) if achievement["unlocked"] else (achievement["name"] + " - " + achievement["desc"])
		label.add_theme_color_override("font_color", Color(0, 0, 0))
		label.add_theme_font_size_override('font_size', 48)
		
		
		hbox.add_child(icon)
		hbox.add_child(label)
		achievements_container.add_child(hbox)
