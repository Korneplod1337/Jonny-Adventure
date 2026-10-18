extends CanvasLayer

@onready var _pages := $Pages.get_children()
@onready var _page_label: Label = $PageLabel
@onready var _btn_prev: Button = $BtnPrev
@onready var _btn_next: Button = $BtnNext
@onready var _stats_grid = $Pages/PageStats/GridContainer
@onready var _collection = $Pages/PageCollection/ScrollContainer
@onready var _stats_bg: Sprite2D = $stats_bg
@onready var _stats_bg2: Sprite2D = $stats_bg2

var _page := 0


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_page = 0
		_stats_grid.update_stats_list()
		_collection.rebuild()
		_refresh()


func _process(_delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed("Escape"):
		_on_exit_button_pressed()
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("fire_left"):
		_on_btn_prev_pressed()
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("fire_right"):
		_on_btn_next_pressed()


func _on_exit_button_pressed() -> void:
	self.hide()
	get_parent().get_node("start_menu").show()


func _on_exit_button_mouse_entered() -> void:
	$exit_button/exit_button_sprite.show()


func _on_exit_button_mouse_exited() -> void:
	$exit_button/exit_button_sprite.hide()


func _on_btn_prev_pressed() -> void:
	if _page <= 0:
		return
	_page -= 1
	_refresh()


func _on_btn_next_pressed() -> void:
	if _page >= _pages.size() - 1:
		return
	_page += 1
	_refresh()


func _refresh() -> void:
	for i in _pages.size():
		_pages[i].visible = i == _page
	_stats_bg.visible = _page == 0
	_stats_bg2.visible = _page == 1
	_page_label.text = "%d / %d" % [_page + 1, _pages.size()]
	_btn_prev.modulate.a = 0.35 if _page == 0 else 1.0
	_btn_next.modulate.a = 0.35 if _page == _pages.size() - 1 else 1.0

