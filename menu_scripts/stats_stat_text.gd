extends GridContainer

@onready var stats_container = self

func _ready() -> void:
	StatsManager.load_statistic() 
	update_stats_list()
	add_theme_constant_override("h_separation", 50)  # Горизонтально между колонками
	add_theme_constant_override("v_separation", 10)
	

func update_stats_list():
	for child in stats_container.get_children():
		child.queue_free()


	for key in StatsManager.stats.keys():
		var stat = StatsManager.get_stat_display(key)
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		var font = load("res://Fonts/JonnyAdventureFont.ttf")
		label.add_theme_font_override('font', font)
		
		label.text = str(stat['disc']) + " - " + str(int(stat['value']))
		label.add_theme_color_override("font_color", Color("MIDNIGHT_BLUE"))
		label.add_theme_font_size_override('font_size', 60) 
		
		hbox.add_child(label)
		stats_container.add_child(hbox)
