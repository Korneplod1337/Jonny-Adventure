extends StaticBody2D

## Forwards weapon hits to the slot machine (Area2D shots use body_entered).
func hit(amount: float, clear := false) -> void:
	var machine := get_parent()
	if machine and machine.has_method("hit"):
		machine.hit(amount, clear)
