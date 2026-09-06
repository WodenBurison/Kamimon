extends Resource
class_name MoveEffect
## Base type for anything a move can do beyond its own power/accuracy/
## domains. A move holds zero or more of these in MoveData.effects. To add
## a new effect kind, write one subclass overriding whichever hook below
## it needs.
##
## hit_count() and target_mode() are currently unused -- see their own
## comments below. apply() is the only hook actually driving live
## behavior.

## Called from: nowhere in live code -- MoveData.attempts (read directly
## by battle_manager.gd's _hit_count()) replaced this.
## Purpose: was meant to let a subclass say how many times a move repeats
## against its target.
func hit_count() -> int:
	return 1

## Called from: battle_smoke_test.gd only, as a direct unit test of
## MultiTargetEffect -- no real game code calls this.
## Purpose: was meant to let a subclass say a move hits every living enemy
## instead of one picked target. MoveData.target_all replaced it --
## battle_action_menu.gd and battle_manager.gd both read that field
## directly.
func target_mode() -> String:
	return "single"

## Called from: battle_manager.gd, _resolve_single_hit() -- once per hit,
## after damage/crit/type/guard are resolved.
## Purpose: lets a subclass do something extra after a hit lands, e.g.
## StatModifierEffect rolling its chance to apply a stat debuff.
func apply(_attacker: Combatant, _defender: Combatant, _battle: BattleManager) -> void:
	pass
