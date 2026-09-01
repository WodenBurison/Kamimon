extends Resource
class_name MoveEffect
## Base type for everything a move can do beyond its own base
## power/accuracy/domains. A move holds zero or more of these in
## MoveData.effects. To add a brand-new effect kind, write ONE new small
## subclass overriding whichever hook(s) below it needs -- MoveData and
## BattleManager's resolution code never need to change again for it,
## only for a genuinely new *kind* of hook (see the note on each one).
##
## Three hooks, because a move's effects can act at three different points
## in resolution, not just "after the hit lands":
## - hit_count(): how many times the move's normal single-hit resolution
##   repeats against its target (default 1). Structural -- see
##   MultiHitEffect.
## - target_mode(): whether this move resolves against the one picked
##   target ("single", the default) or every living target on the
##   defending side ("all_enemies"). Structural -- see MultiTargetEffect.
##   NOT YET auto-detected by the player action menu; see that class's doc
##   comment.
## - apply(): runs once after a single hit has already been fully resolved
##   (damage applied, crit/type/guard messaging already written). This is
##   the "secondary effect" hook -- see StatModifierEffect.
##
## A move with multiple effects can mix hooks freely (e.g. multi-hit AND a
## stat-modifier effect that rolls separately on each individual hit).
## Base implementations are all safe no-ops, so a move with effects = []
## behaves exactly like one with no MoveEffect system at all.

func hit_count() -> int:
	return 1

func target_mode() -> String:
	return "single"

func apply(_attacker: Combatant, _defender: Combatant, _battle: BattleManager) -> void:
	pass
