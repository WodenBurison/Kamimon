extends RefCounted
class_name Combatant
## Wraps a MonsterData definition with the mutable state it needs for one
## battle: current HP, ATB gauge fill, whether it's currently guarding, and
## (new 2026-09-01) temporary in-battle stat "stage" modifiers from move
## effects (see MoveData's effect_* fields doc comment). MonsterData never
## changes during a fight; this does.

const ATB_MAX := 100.0

## Speed-to-gauge-fill diminishing-returns constant (2026-09-03), same
## tanh-bounded shape as battle_manager.gd's LEVEL_CAP/LEVEL_STEEPNESS
## (`cap * tanh(x / steepness)`, not the multiplicative `cap ^ tanh(x)`
## form used there -- this isn't a ratio between two combatants, it's a
## single stat being turned into a bounded fill rate). SPEED_REFERENCE
## does double duty as both the steepness and the asymptotic cap: for
## speed well under this value the curve is close to linear (matches
## today's roster, speed 6-20, within about 8% of the old uncapped
## behavior), and gains taper off hard as speed climbs toward and past
## it, so a very high Speed stat (once real high-end content exists)
## can't buy unbounded turn frequency the way flat `speed * delta` did.
## Placeholder value, not yet reviewed by Woden -- same status as
## GEAR_CAP/ACC_EVA_CAP/CRIT_STAT_REFERENCE.
const SPEED_REFERENCE := 40.0

## Stage step/cap for the new stat-modifier mechanic -- deliberately small
## and hard-clamped to stay "mellow" in the spirit of the rest of the
## combat formula, but these exact numbers are Claude's placeholder pick
## (not yet reviewed by Woden), same status as battle_manager.gd's
## GEAR_CAP/ACC_EVA_CAP. +/-3 stages at 15%% each caps the swing at
## roughly 0.55x-1.45x.
const STAGE_STEP := 0.15
const MAX_STAGE := 3

var data: MonsterData
var current_hp: int
var atb_gauge: float = 0.0
var is_defending: bool = false

## Keyed by stat name ("Attack"/"Defense"/"Speed"/"Accuracy"/"Evasion"/
## "CritStat"), value {"stages": int, "turns_left": int}. Absent key means
## no active modifier on that stat -- the common case, and a fresh
## Combatant always starts with this empty, so effective_*() is an exact
## no-op until something actually applies a modifier.
var stat_modifiers: Dictionary = {}

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

## Gauge fill rate is speed, now stat-modifier-aware (2026-09-01) -- a
## Speed debuff genuinely slows turn frequency, not just damage math. A
## fuller formula (level, equipment, etc.) can still layer on top of this
## later without touching anything that calls this.
func tick(delta: float) -> void:
	if is_downed():
		return
	atb_gauge = min(atb_gauge + effective_speed() * delta, ATB_MAX)

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

## Adds `stages` to whatever's already active on `stat_name` (clamped to
## +/-MAX_STAGE, so repeated debuffs can't stack without bound), refreshes
## the duration to `duration` turns. A move applying, say, -1 Defense onto
## an already -2'd target lands at -3 (the clamp), not -6 -- deliberately
## not additive-unbounded, matching the "mellow curve" philosophy
## elsewhere in this combat system.
func apply_stat_modifier(stat_name: String, stages: int, duration: int) -> void:
	var current_stages: int = 0
	if stat_modifiers.has(stat_name):
		current_stages = stat_modifiers[stat_name]["stages"]
	var new_stages: int = clamp(current_stages + stages, -MAX_STAGE, MAX_STAGE)
	stat_modifiers[stat_name] = {"stages": new_stages, "turns_left": duration}

func _stage_multiplier(stat_name: String) -> float:
	if not stat_modifiers.has(stat_name):
		return 1.0
	return 1.0 + STAGE_STEP * stat_modifiers[stat_name]["stages"]

func effective_attack() -> float:
	return data.attack * _stage_multiplier("Attack")

func effective_defense() -> float:
	return data.defense * _stage_multiplier("Defense")

## Diminishing-returns curve applied to the raw stat first (see
## SPEED_REFERENCE above), THEN the stage multiplier on top -- a
## temporary Speed buff/debuff from a move effect still swings turn
## frequency by its full linear percentage, it's only the underlying
## stat investment that gets bent toward a cap.
func effective_speed() -> float:
	var curved_speed: float = SPEED_REFERENCE * tanh(data.speed / SPEED_REFERENCE)
	return curved_speed * _stage_multiplier("Speed")

func effective_accuracy() -> float:
	return data.accuracy * _stage_multiplier("Accuracy")

func effective_evasion() -> float:
	return data.evasion * _stage_multiplier("Evasion")

func effective_crit_stat() -> float:
	return data.crit_stat * _stage_multiplier("CritStat")

## Called from BattleManager._start_turn, the same hook that already clears
## Guard -- decays every active modifier by one of THIS combatant's own
## turns, dropping it once it hits zero.
func tick_stat_modifiers() -> void:
	for stat_name in stat_modifiers.keys().duplicate():
		var entry: Dictionary = stat_modifiers[stat_name]
		entry["turns_left"] -= 1
		if entry["turns_left"] <= 0:
			stat_modifiers.erase(stat_name)
		else:
			stat_modifiers[stat_name] = entry
