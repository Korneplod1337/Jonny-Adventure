extends CanvasLayer

@onready var _pages := $Pages.get_children()
@onready var _page_label: Label = $PageLabel
@onready var _btn_prev: Button = $BtnPrev
@onready var _btn_next: Button = $BtnNext

var _page := 0


func open() -> void:
	_page = 0
	_refresh()
	show()


func _process(_delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed("Escape"):
		_on_exit_pressed()
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("fire_left"):
		_on_btn_prev_pressed()
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("fire_right"):
		_on_btn_next_pressed()


func _on_exit_pressed() -> void:
	hide()
	get_parent().get_node("start_menu").show()


func _on_exit_mouse_entered() -> void:
	$exit/exit_select.show()


func _on_exit_mouse_exited() -> void:
	$exit/exit_select.hide()


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
	_page_label.text = "%d / %d" % [_page + 1, _pages.size()]
	_btn_prev.modulate.a = 0.35 if _page == 0 else 1.0
	_btn_next.modulate.a = 0.35 if _page == _pages.size() - 1 else 1.0
