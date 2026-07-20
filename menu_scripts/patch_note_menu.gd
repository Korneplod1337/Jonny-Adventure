extends CanvasLayer

const PATCH_NOTES_PATH := "res://menu_scripts/patch_notes.txt"

@onready var notes_label: RichTextLabel = $ScrollContainer/PatchNotesText


func _ready() -> void:
	_load_patch_notes()


func open() -> void:
	_load_patch_notes()
	$ScrollContainer.scroll_vertical = 0
	show()


func _load_patch_notes() -> void:
	var text := FileAccess.get_file_as_string(PATCH_NOTES_PATH)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		notes_label.text = "Patch notes will appear here."
		return
	notes_label.text = text


func _process(_delta: float) -> void:
	if Input.is_action_pressed("Escape"):
		_on_exitpn_pressed()


func _on_exitpn_pressed() -> void:
	hide()
	get_parent().get_node("start_menu").show()


func _on_exitpn_mouse_entered() -> void:
	$exitpn/exit_select.show()


func _on_exitpn_mouse_exited() -> void:
	$exitpn/exit_select.hide()
