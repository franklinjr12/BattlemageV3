class_name Vitality extends RefCounted
signal health_changed(current: float, maximum: float)
signal damage_taken(amount: float)
signal died
var maximum: float = 100.0
var current: float = 100.0
var invulnerable: bool = false
var dead: bool = false

func reset(value: float) -> void:
	maximum = maxf(1.0, value)
	current = maximum
	dead = false
	invulnerable = false
	health_changed.emit(current, maximum)

func hurt(amount: float) -> float:
	if invulnerable or dead or amount <= 0.0:
		return 0.0
	var actual: float = minf(current, amount)
	current -= actual
	damage_taken.emit(actual)
	health_changed.emit(current, maximum)
	if current <= 0.0:
		dead = true
		died.emit()
	return actual

func heal(amount: float) -> void:
	if not dead:
		current = clampf(current + maxf(0.0, amount), 0.0, maximum)
		health_changed.emit(current, maximum)
