extends Node2D

@onready var interact_label: Label = $InteractLabel
@onready var interact_range: Area2D = $InteractRange
var current_interactions := []
var can_interact := true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('button_E') and can_interact:
		_prune_stale_interactions()
		if current_interactions:
			can_interact = false
			interact_label.hide()
			
			await current_interactions[0].interact.call()
			
			can_interact = true

func _process(_delta: float) -> void:
	_prune_stale_interactions()
	if current_interactions and can_interact:
		current_interactions.sort_custom(_sort_by_nearest)
		if current_interactions[0].is_interactable:
			interact_label.text = current_interactions[0].interact_name
			interact_label.show()
	else:
		interact_label.hide()


func reset_interaction_state() -> void:
	current_interactions.clear()
	can_interact = true
	interact_label.hide()
	interact_range.monitoring = false
	interact_range.set_deferred("monitoring", true)


func _prune_stale_interactions() -> void:
	var valid: Array = []
	for area in current_interactions:
		if is_instance_valid(area) and area.is_inside_tree():
			valid.append(area)
	current_interactions = valid


func _sort_by_nearest(area1, area2):
	var area1_dist = global_position.distance_to(area1.global_position)
	var area2_dist = global_position.distance_to(area2.global_position)
	return area1_dist < area2_dist


func _on_interact_range_area_entered(area: Area2D) -> void:
	if area not in current_interactions:
		current_interactions.push_back(area)

func _on_interact_range_area_exited(area: Area2D) -> void:
	current_interactions.erase(area)
