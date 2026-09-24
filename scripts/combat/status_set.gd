class_name StatusSet extends RefCounted
# Refresh-duration stacking: Burn caps at 4, Chill at 3; hard control refreshes.
var active: Dictionary = {}
var stagger: float = 0.0
var resistance: float = 3.0
var control_resistance: float = 1.0
var burn_tick: float = 0.0

func apply(id: String, duration: float, source: Node2D, strength: float = 0.0) -> void:
	if id.is_empty():
		return
	if id == "stagger":
		stagger += 1.0 + strength
		if stagger >= resistance:
			stagger = 0.0
			apply("stunned", 0.9, source)
		return
	var stacks: int = mini(int(active.get(id, {}).get("stacks", 0)) + 1, 4 if id == "burn" else 3)
	active[id] = {"time": duration * (control_resistance if ["freeze", "root", "stunned", "airborne"].has(id) else 1.0), "stacks": stacks, "source": weakref(source) if source != null else null, "strength": strength}
	if id == "chill" and stacks >= 3:
		active.erase("chill")
		apply("freeze", 1.5, source)

func update(delta: float) -> Array[DamageEvent]:
	var events: Array[DamageEvent] = []
	stagger = maxf(0.0, stagger - delta * 0.12)
	burn_tick -= delta
	if active.has("burn") and burn_tick <= 0.0:
		burn_tick = 0.65
		var event: DamageEvent = DamageEvent.new()
		event.amount = 3.0 * float(active.burn.stacks)
		event.element = "Fire"
		event.tags = ["dot"]
		if active.burn.source != null:
			event.instigator = active.burn.source.get_ref()
		events.append(event)
	for id: String in active.keys():
		active[id].time -= delta
		if float(active[id].time) <= 0.0:
			active.erase(id)
	return events

func rooted() -> bool:
	return active.has("freeze") or active.has("root") or active.has("stunned") or active.has("airborne")

func movement_factor() -> float:
	if rooted():
		return 0.0
	if active.has("chill"):
		return maxf(0.25, 1.0 - float(active.chill.stacks) * 0.19 - float(active.chill.strength))
	return 1.0

func clear() -> void:
	active.clear()
	stagger = 0.0
