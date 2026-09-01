extends Resource
class_name MonsterData
## Static definition of a monster species/build goes here — the numbers that are
## the same for every instance of this monster. Per-battle state (current HP,
## ATB gauge) does not belong here; that lives on Combatant instead.
##
## PRAGMATIC NOTE (2026-08-31): `level` and `equipped_gear` are per-INDIVIDUAL
## state (they persist across battles, they're not shared by every monster of
## a species) and don't really belong on a "static species template" resource
## long-term — they're here now because there's no save/overworld/owned-
## monster-instance system yet to hold them properly, and every MonsterData
## in the prototype is already effectively instantiated per-individual (see
## PlaceholderBattleData). Revisit once a real per-individual/save layer
## exists — likely a new MonsterInstance-style wrapper around a shared
## MonsterData species template plus level/gear/matrix-progress.
##
## `assigned_moves` (renamed from `moves` 2026-09-01) is this monster's
## out-of-battle-assigned active loadout -- up to three moves used in
## battle, out of everything it actually knows. `move_pool` is the full
## learned set the player can swap those three from outside of battle --
## always empty for now (no move-matrix/learning system or swap UI exists
## yet, so there's nothing to populate it with; every placeholder monster's
## 3 assigned moves ARE its entire current movepool in practice, same as
## before this rename, just now with an explicit empty pool alongside them
## rather than conflating "assigned" and "known"). Attack and Guard are
## separate universal baseline actions every monster has regardless of
## either list, so they aren't included in it.
##
## `domains` is this monster's RANKED Domain list — Primary/Secondary/
## Tertiary/Last, matching the locked Combat.md rank percentages (40/30/20/
## 10%). Up to 4 slots; "" in a slot means unused. Combat's stab/weakness/
## resistance resolution (TypeResolution.derive_type_factors) walks this
## list from index 0 (Primary) downward and stops at the first slot that
## qualifies — so position matters, a Domain in slot 0 hits harder than the
## same Domain in slot 1. This replaces the old single `domain: String`
## placeholder field.
##
## `level` feeds the damage formula's levelFactor (level GAP between
## attacker/defender, not either monster's absolute level) — see
## BattleManager._compute_damage. Per the locked stat-system design, level
## does NOT directly grow Attack/Defense/etc. — those only change via the
## (not yet implemented) move matrix.
##
## `equipped_gear` is a placeholder for the locked 3-slot equipment system —
## each slot holds a flat "equip power" number (float) rather than a real
## gear item resource, since gear content/items haven't been designed yet
## (only the skeleton: 3 slots, gear stays its own separate damage-formula
## factor). equip_power() sums the slots; 0/0 on both sides of a fight
## (the current state, since no gear exists to assign) makes gearFactor
## resolve to a neutral 1.0x, so this is safe to wire in now without
## affecting any existing battle balance.
##
## `accuracy`/`evasion`/`crit_stat` are the three background stats from the
## locked Stat system design (050 Combat.md, 2026-08-31) — deliberately not
## on the visible stat menu, and not fed raw into hit/crit rolls (that broke
## at level extremes per the design doc). BattleManager instead uses them to
## nudge a move's own accuracy and a small baseline crit chance via the same
## bounded cap^ratio shape as the rest of the damage formula, both hard-
## clamped. Default 10.0 on all three matches the placeholder scale the
## other small-int stats already use, and — because BattleManager's crit
## formula compares against a matching reference constant — two default-
## stat monsters reproduce the exact pre-background-stat behavior (modifier
## == 1.0, crit chance == the flat baseline). Exact baseline rates/caps are
## still open per the design doc; see the constants at the top of
## battle_manager.gd for what's currently a placeholder pick vs. locked.

const DOMAIN_SLOTS := 4
const GEAR_SLOTS := 3

@export var display_name: String = ""
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 10
@export var speed: int = 10
@export var level: int = 5
@export var domains: Array[String] = ["", "", "", ""]
@export var equipped_gear: Array[float] = [0.0, 0.0, 0.0]
@export var accuracy: float = 10.0
@export var evasion: float = 10.0
@export var crit_stat: float = 10.0
@export var battler_sprite: Texture2D
@export var assigned_moves: Array[MoveData] = []
@export var move_pool: Array[MoveData] = []

func equip_power() -> float:
	var total := 0.0
	for g in equipped_gear:
		total += g
	return total
