extends RefCounted
class_name Combatant
## Wraps a MonsterData definition with the mutable state it needs for one
## battle: current HP, ATB gauge fill, and whether it's currently guarding.
## MonsterData never changes during a fight; this does.

const ATB_MAX := 100.0

var data: MonsterData
var current_hp: int
var atb_gauge: float = 0.0
var is_defending: bool = false

func _init(monster_data: MonsterData) -> void:
	data = monster_data
	current_hp = data.max_hp

## A monster at 0 HP is downed for the rest of this battle — not swapped out
## (there's no mid-battle switching) and not removed from the party array.
## It stops ticking and is skipped for turns and as an attack target, and
## stays that way unless something explicitly revives it.
func is_downed() -> bool:
	return current_hp <= 0

func is_ready() -> bool:
	return atb_gauge >= ATB_MAX

## Gauge fill rate is just speed for now. A real formula (level, status
## effects, equipment, etc.) goes here later without touching anything that
## calls this.
func tick(delta: float) -> void:
	if is_downed():
		return
	atb_gauge = min(atb_gauge + data.speed * delta, ATB_MAX)

func reset_gauge() -> void:
	atb_gauge = 0.0

func apply_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)

## Guard/Defend is the universal baseline action every monster has. It halves
## incoming damage until this combatant's next turn (cleared in
## BattleManager._start_turn), not just against the next single hit.
func guard() -> void:
	is_defending = true

func clear_guard() -> void:
	is_defending = false

func atb_ratio() -> float:
	return atb_gauge / ATB_MAX

func hp_ratio() -> float:
	return float(current_hp) / float(data.max_hp)
