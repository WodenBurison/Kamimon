extends RefCounted
class_name Combatant
## Wraps a MonsterData definition with the mutable state it needs for one
## battle: current HP and ATB gauge fill. MonsterData never changes during a
## fight; this does.

const ATB_MAX := 100.0

var data: MonsterData
var current_hp: int
var atb_gauge: float = 0.0

func _init(monster_data: MonsterData) -> void:
	data = monster_data
	current_hp = data.max_hp

func is_fainted() -> bool:
	return current_hp <= 0

func is_ready() -> bool:
	return atb_gauge >= ATB_MAX

## Gauge fill rate is just speed goes here for now. A real formula (level,
## status effects, held-item-equivalent, etc.) goes here later without
## touching anything that calls this.
func tick(delta: float) -> void:
	if is_fainted():
		return
	atb_gauge = min(atb_gauge + data.speed * delta, ATB_MAX)

func reset_gauge() -> void:
	atb_gauge = 0.0

func apply_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)

func atb_ratio() -> float:
	return atb_gauge / ATB_MAX

func hp_ratio() -> float:
	return float(current_hp) / float(data.max_hp)
