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
## `moves` is this monster's out-of-battle-assigned active loadout — up to
## three moves the player picks outside of battle. It is not the monster's
## full learned movepool (no move-matrix/learning system exists yet, so for
## now the assigned loadout and the learned set are the same thing). Attack
## and Guard are separate universal baseline actions every monster has
## regardless of this list, so they aren't included here.
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
@export var battler_sprite: Texture2D
@export var moves: Array[MoveData] = []

func equip_power() -> float:
	var total := 0.0
	for g in equipped_gear:
		total += g
	return total
