extends Node2D
## Вешается рядом с торговцем. Interactable → диалог. ! при активном ивенте.

@export var trader_id: String = "sherochka"
@export var focus_path: NodePath

@onready var interactable: Area2D = $Interactable
@onready var bang: Sprite2D = $Exclamation

var _focus_node: Node2D = null


func _ready() -> void:
	if focus_path != NodePath(""):
		_focus_node = get_node_or_null(focus_path) as Node2D
		if _focus_node == null and get_parent():
			_focus_node = get_parent().get_node_or_null(focus_path) as Node2D
	if _focus_node == null:
		_focus_node = get_parent() as Node2D
	if _focus_node == null:
		_focus_node = self

	interactable.interact_name = "Talk"
	interactable.interact = _on_talk
	interactable.is_interactable = true

	if not GameState.dialog_events_changed.is_connected(_refresh_bang):
		GameState.dialog_events_changed.connect(_refresh_bang)

	DialogDB.evaluate_triggers()
	_refresh_bang()


func _exit_tree() -> void:
	if GameState.dialog_events_changed.is_connected(_refresh_bang):
		GameState.dialog_events_changed.disconnect(_refresh_bang)


func _refresh_bang() -> void:
	if not is_instance_valid(bang):
		return
	bang.visible = DialogDB.has_pending_event_for(trader_id)


func _on_talk() -> void:
	if DialogDB.is_dialog_open:
		return
	DialogDB.start_dialog(trader_id, _focus_node)
