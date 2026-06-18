class_name BoomerangPath
extends RefCounted

## 1 — туда + обратно; 2 — туда + обратно + туда; N — N+1 отрезков, чередуя направление.
static func build_legs(power: int) -> Array:
	if power <= 0:
		return []

	var legs: Array = [{"forward": true}]
	var is_forward := false
	for _i in power:
		legs.append({"forward": is_forward})
		is_forward = not is_forward
	return legs
