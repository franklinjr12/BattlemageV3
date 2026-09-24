extends Node2D
var clock: float = 0.0
func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
func _draw() -> void:
	ArenaArt.draw_arena(self, Vector2(365, 425), 244, clock)
	draw_rect(Rect2(670, 0, 610, 800), Color(0.035, 0.06, 0.10, 0.96))
	draw_line(Vector2(685, 95), Vector2(685, 705), Color("514b3e"), 1)
