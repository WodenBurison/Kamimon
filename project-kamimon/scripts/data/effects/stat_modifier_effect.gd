extends MoveEffect
class_name StatModifierEffect
## Rolls a chance to nudge one of the target's stats by a stage delta for a
## number of turns -- see Combatant.apply_stat_modifier()/effective_*() for
## the actual stage math (clamped to +/-3 stages, +/-15%% each -- Claude's
## placeholder numbers, not yet Woden-reviewed).
##
## Replaces MoveData's old flat effect_stat/effect_stages/effect_chance/
## effect_duration/effect_target fields (2026-09-01, superseded same day
## once the general MoveEffect system landed) with a standalone,
## independently Inspector-editable resource -- multiple moves can now
## share one StatModifierEffect.tres the same way moves already share
## MoveData.tres files, if that's ever useful.

@export var stat: String = ""              # "Attack"/"Defense"/"Speed"/"Accuracy"/"Evasion"/"CritStat"
@export var stages: int = -1
@export var chance: float = 1.0
@export var duration: int = 3
@export var target: String = "defender"    # "defender" or "self"

func apply(attacker: Combatant, defender: Combatant, battle: BattleManager) -> void:
	if stat == "":
		return
	if randf() > chance:
		return
	var t: Combatant = attacker if target == "self" else defender
	t.apply_stat_modifier(stat, stages, duration)
	var verb: String = "rose" if stages > 0 else "fell"
	battle.message_label.text += " %s's %s %s!" % [t.data.display_name, stat, verb]
