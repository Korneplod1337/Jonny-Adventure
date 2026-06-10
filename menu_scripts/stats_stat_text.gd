extends GridContainer

@onready var stats_container = self


func _ready() -> void:
	StatsManager.load_statistic()
	update_stats_list()
	add_theme_constant_override("h_separation", 50)
	add_theme_constant_override("v_separation", 10)


func update_stats_list() -> void:
	for child in stats_container.get_children():
		child.queue_free()

	for key in StatsManager.get_menu_stat_keys():
		var stat = StatsManager.get_stat_display(key)
		var hbox = HBoxContainer.new()

		var label = Label.new()
		var font = load("res://Fonts/JonnyAdventureFont.ttf")
		label.add_theme_font_override("font", font)
		label.text = _format_stat_line(stat)
		label.add_theme_color_override("font_color", Color("MIDNIGHT_BLUE"))
		label.add_theme_font_size_override("font_size", 48)

		hbox.add_child(label)
		stats_container.add_child(hbox)


func _format_stat_line(stat: Dictionary) -> String:
	var desc: String = str(stat.get("desc", ""))
	match stat.get("custom_display", ""):
		"item_unlock_counts":
			return desc + " - " + ItemManager.get_item_unlock_counts()
		_:
			return desc + " - " + str(int(stat.get("value", 0)))
