class_name DamageEvent extends RefCounted
var source: Node2D
var instigator: Node2D
var amount: float = 0.0
var element: String = ""
var spell_id: String = ""
var tags: PackedStringArray = []
var critical: bool = false
var knockback: Vector2 = Vector2.ZERO
var status: String = ""
var status_duration: float = 0.0
var status_power: float = 0.0
