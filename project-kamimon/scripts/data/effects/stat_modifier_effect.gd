extends MoveEffect
class_name StatModifierEffect
## Rolls a chance to nudge one of the target's stats by a stage delta for a
## number of turns -- see Combatant.apply_stat_modifier()/effective_*() for
## the actual stage math (clamped to +/-3 stages, +/-15%% each -- Claude's
## placeholder numbers, not yet Woden-reviewed).
##
## A standalone, independently Inspector-editable resource -- multiple moves
## can share one StatModifierEffect.tres the same way moves already share
## MoveData.tres files, if that's ever useful.

@export var stat: String = ""              # "Attack"/"Defense"/"Speed"/"Accuracy"/"Evasion"/"CritStat"
@export var stages: int = -1
@export var chance: float = 1.0
@export var duration: int = 3
@export var target: String = "defender"    # "defender" or "self"

## Called from: battle_manager.gd's _resolve_single_hit(), once per hit, for
## each effect in the move's effects array. Also called directly by
## battle_smoke_test.gd.
## Purpose: rolls this effect's chance, and if it hits, applies its stat
## stage delta to the attacker or defender (per `target`) and posts a
## message about it.
func apply(attacker: Combatant, defender: Combatant, battle: BattleManager) -> void:
	if stat == "":
		return
	if randf() > chance:
		return
	var t: Combatant = attacker if target == "self" else defender
	t.apply_stat_modifier(stat, stages, duration)
	var verb: String = "rose" if stages > 0 else "fell"
	battle.message_label.text += " %s's %s %s!" % [t.data.display_name, stat, verb]
