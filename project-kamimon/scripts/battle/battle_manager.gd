extends Node2D
class_name BattleManager
## Orchestrates one Wait-mode ATB battle between two parties of up to four
## monsters each. Every non-downed combatant on both sides ticks
## simultaneously; the instant anyone becomes ready, ticking pauses so that
## turn can be resolved (Wait mode — nobody else's gauge fills while a menu
## is open), then resumes. Multiple combatants can become ready in the same
## frame; they queue up and take their turns one at a time.
##
## No mid-battle switching. A monster reduced to 0 HP goes downed and stays
## out for the rest of the fight (see Combatant.is_downed) instead of being
## swapped — nothing revives it yet, that's a later move type.
##
## References to the other pieces (HUD, action menu, sprite containers,
## message label) are wired in the Inspector via the exported NodePath
## slots below and resolved in _ready().

signal battle_won
signal battle_lost
signal battle_fled

@export var hud_path: NodePath
@export var action_menu_path: NodePath
@export var message_label_path: NodePath
@export var player_battler_container_path: NodePath
@export var enemy_battler_container_path: NodePath

## "Attack" is the universal baseline move every monster has regardless of
## its assigned loadout, same spirit as Guard — not one of the 3 assigned
## moves, so it isn't defined as a MoveData resource anywhere.
const BASIC_ATTACK_POWER := 10
const BASIC_ATTACK_ACCURACY := 1.0
const SPRITE_SPACING := 110.0
const SPRITE_SCALE := Vector2(1.5, 1.5)

## Combat damage formula constants (LOCKED shape 2026-08-30, these specific
## numbers are tunable balance dials, not locked — see Kamimon_Design_Notes/
## 050 Combat.md). GEAR_CAP in particular is flagged there as too soft
## (Woden wants gear to matter more); revisit once real gear content exists.
const LEVEL_CAP := 4.0
const LEVEL_STEEPNESS := 4.0
const STAT_CAP := 2.5
const GEAR_CAP := 1.5
const TYPE_SCALE := 1.0

## Background-stat (Accuracy/Evasion/Crit) constants (LOCKED shape
## 2026-08-31 per 050 Combat.md: baseline x smallCap^normalized-advantage,
## hard-clamped so nothing is ever guaranteed). The design doc only locked
## the shape, not these numbers — placeholders, same spirit as GEAR_CAP.
## ACC_EVA_CAP is deliberately tight (roughly a +/-20% swing on a move's own
## accuracy): the intent captured here is "stat gaps can't turn an already-
## risky move into a coinflip or a lock," not "no move can ever be
## reliable" — a move authored with accuracy 1.0 (e.g. the basic Attack)
## stays effectively guaranteed against equal-or-lower evasion, which is why
## the ceiling isn't clamped below 1.0. MIN_HIT_CHANCE is the actual "no
## guaranteed miss" floor. CRIT_STAT_REFERENCE stands in for an opposing
## "crit resist" stat, since the locked design doesn't define one — a
## monster with exactly the reference value crits at exactly
## BASE_CRIT_CHANCE, which is also every placeholder monster's default.
const ACC_EVA_CAP := 1.2
const MIN_HIT_CHANCE := 0.5
const BASE_CRIT_CHANCE := 0.05
const CRIT_CAP := 6.0
const CRIT_STAT_REFERENCE := 10.0
const MAX_CRIT_CHANCE := 0.5
const CRIT_DAMAGE_MULT := 1.5

var hud: BattleHUD
var action_menu: BattleActionMenu
var message_label: Label
var player_battler_container: Node2D
var enemy_battler_container: Node2D

enum State { TICKING, PLAYER_INPUT, RESOLVING, BATTLE_OVER }

var player_party: Array[Combatant] = []
var enemy_party: Array[Combatant] = []
var player_sprites: Array[Sprite2D] = []
var enemy_sprites: Array[Sprite2D] = []
var ready_queue: Array[Combatant] = []
var _current_actor: Combatant = null
var state: State = State.TICKING

func _ready() -> void:
	hud = get_node(hud_path)
	action_menu = get_node(action_menu_path)
	message_label = get_node(message_label_path)
	player_battler_container = get_node(player_battler_container_path)
	enemy_battler_container = get_node(enemy_battler_container_path)
	_build_parties()
	_build_sprites()
	action_menu.attack_selected.connect(_on_attack_selected)
	action_menu.guard_selected.connect(_on_guard_selected)
	action_menu.move_selected.connect(_on_move_selected)
	action_menu.move_selected_random.connect(_on_move_selected)
	action_menu.move_selected_all_enemies.connect(_on_move_selected_all_enemies)
	action_menu.run_selected.connect(_on_run_selected)
	hud.build(player_party, enemy_party)
	_refresh_hud()
	message_label.text = "A wild party appeared!"
	action_menu.hide_all()
	state = State.TICKING

func _build_parties() -> void:
	for monster in PlaceholderBattleData.get_player_party():
		player_party.append(Combatant.new(monster))
	for monster in PlaceholderBattleData.get_enemy_party():
		enemy_party.append(Combatant.new(monster))

func _build_sprites() -> void:
	player_sprites = _build_sprite_row(player_battler_container, player_party, -1)
	enemy_sprites = _build_sprite_row(enemy_battler_container, enemy_party, 1)

## direction is -1 for the player's row (fans left of its anchor) and 1 for
## the enemy row (fans right), so both rows spread away from the middle.
func _build_sprite_row(container: Node2D, party: Array[Combatant], direction: int) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	for i in party.size():
		var sprite := Sprite2D.new()
		sprite.texture = party[i].data.battler_sprite
		sprite.scale = SPRITE_SCALE
		sprite.position = Vector2(direction * i * SPRITE_SPACING, 0)
		container.add_child(sprite)
		sprites.append(sprite)
	return sprites

func _process(delta: float) -> void:
	if state != State.TICKING:
		return
	_tick_all(delta)
	_refresh_hud()
	_collect_ready()
	if not ready_queue.is_empty():
		_start_turn(ready_queue.pop_front())

func _tick_all(delta: float) -> void:
	for c in player_party:
		c.tick(delta)
	for c in enemy_party:
		c.tick(delta)

func _collect_ready() -> void:
	for c in player_party:
		if c.is_ready() and not c.is_downed() and not (c in ready_queue):
			ready_queue.append(c)
	for c in enemy_party:
		if c.is_ready() and not c.is_downed() and not (c in ready_queue):
			ready_queue.append(c)

func _start_turn(actor: Combatant) -> void:
	if actor.is_downed():
		return
	actor.reset_gauge()
	actor.clear_guard()
	actor.tick_stat_modifiers()
	_current_actor = actor
	if actor in player_party:
		_start_player_turn(actor)
	else:
		_start_enemy_turn(actor)

func _start_player_turn(actor: Combatant) -> void:
	state = State.PLAYER_INPUT
	message_label.text = "%s is ready to act!" % actor.data.display_name
	action_menu.open(actor.data.assigned_moves, _party_status(player_party), _party_status(enemy_party))

func _party_status(party: Array[Combatant]) -> Array[Dictionary]:
	var status: Array[Dictionary] = []
	for c in party:
		status.append({
			"name": c.data.display_name,
			"hp": c.current_hp,
			"max_hp": c.data.max_hp,
			"is_downed": c.is_downed(),
		})
	return status

func _on_attack_selected(target_index: int) -> void:
	if state != State.PLAYER_INPUT:
		return
	_resolve_player_action(_basic_attack_move(), target_index)

func _on_move_selected(move_index: int, target_index: int) -> void:
	if state != State.PLAYER_INPUT:
		return
	var moves := _current_actor.data.assigned_moves
	if move_index < 0 or move_index >= moves.size():
		return
	_resolve_player_action(moves[move_index], target_index)
	

## Counterpart to _on_move_selected for a move BattleActionMenu identified
## as hitting every living enemy (MoveData.targets_all_enemies()) -- no
## target_index involved, there was nothing to pick between.
func _on_move_selected_all_enemies(move_index: int) -> void:
	if state != State.PLAYER_INPUT:
		return
	var moves := _current_actor.data.assigned_moves
	if move_index < 0 or move_index >= moves.size():
		return
	_resolve_player_aoe_action(moves[move_index])

func _on_guard_selected() -> void:
	if state != State.PLAYER_INPUT:
		return
	_current_actor.guard()
	message_label.text = "%s guards." % _current_actor.data.display_name
	action_menu.hide_all()
	_after_action()

## Flee is unconditional for the prototype — no escape-chance formula exists
## yet, so Run always succeeds and ends the battle immediately.
func _on_run_selected() -> void:
	if state != State.PLAYER_INPUT:
		return
	state = State.BATTLE_OVER
	message_label.text = "Got away safely!"
	action_menu.hide_all()
	battle_fled.emit()

func _resolve_player_action(move: MoveData, target_index: int) -> void:
	if target_index < 0 or target_index >= enemy_party.size() or enemy_party[target_index].is_downed():
		action_menu.hide_all()
		_after_action()
		return
	state = State.RESOLVING
	_resolve_attack(_current_actor, enemy_party[target_index], move)
	action_menu.hide_all()
	_after_action()

## Counterpart to _resolve_player_action for a move that hits every living
## enemy at once (see MoveData.targets_all_enemies()) -- resolves against
## the whole living enemy party via resolve_multi_target_attack() instead
## of a single picked target.
func _resolve_player_aoe_action(move: MoveData) -> void:
	var targets := _living(enemy_party)
	if targets.is_empty():
		action_menu.hide_all()
		_after_action()
		return
	state = State.RESOLVING
	resolve_multi_target_attack(_current_actor, targets, move)
	action_menu.hide_all()
	_after_action()

func _after_action() -> void:
	_current_actor = null
	if _check_battle_over():
		return
	state = State.TICKING

func _start_enemy_turn(actor: Combatant) -> void:
	state = State.RESOLVING
	var targets := _living(player_party)
	if not targets.is_empty():
		# Target and move are both rolled unconditionally, same as before
		# this branch existed, so seeded tests that assume this exact
		# draw order (target index, then move index) keep working even
		# though `target` goes unused on the all-enemies branch below.
		var target: Combatant = targets[randi() % targets.size()]
		var moves := actor.data.assigned_moves
		var move: MoveData = moves[randi() % moves.size()] if not moves.is_empty() else _basic_attack_move()
		if move.targets_all_enemies():
			resolve_multi_target_attack(actor, targets, move)
		else:
			_resolve_attack(actor, target, move)
	_after_action()

func _living(party: Array[Combatant]) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for c in party:
		if not c.is_downed():
			out.append(c)
	return out

func _basic_attack_move() -> MoveData:
	var move := MoveData.new()
	move.display_name = "Attack"
	move.power = BASIC_ATTACK_POWER
	move.accuracy = BASIC_ATTACK_ACCURACY
	return move

## The locked 5-factor damage formula (Kamimon_Design_Notes/050 Combat.md,
## LOCKED 2026-08-30): pow x levelFactor x statFactor x gearFactor x
## typeMult. Every factor besides pow and typeMult is a bounded
## cap^normalized-advantage ratio — diminishing returns approaching the cap,
## never exceeding it. Returns the rounded damage plus type_mult (for the
## super/not-very-effective message below); _resolve_attack still applies
## post-formula hit-variance and guard halving itself, same as before this
## migration.
func _compute_damage(attacker: Combatant, defender: Combatant, move: MoveData) -> Dictionary:
	var gap: float = attacker.data.level - defender.data.level
	var level_factor: float = pow(LEVEL_CAP, tanh(gap / LEVEL_STEEPNESS))

	var atk: float = attacker.effective_attack()
	var def: float = defender.effective_defense()
	var stat_factor: float = 1.0
	if atk + def > 0.0:
		stat_factor = pow(STAT_CAP, (atk - def) / (atk + def))

	var equip_a: float = attacker.data.equip_power()
	var equip_d: float = defender.data.equip_power()
	var gear_factor: float = pow(GEAR_CAP, (equip_a - equip_d) / (equip_a + equip_d + 2.0))

	var t := TypeResolution.derive_type_factors(move.domains, attacker.data.domains, defender.data.domains)
	var type_mult: float = 1.0 + TYPE_SCALE * (t.stab_pct + t.weak_pct - t.resist_pct)

	var raw_damage: float = move.power * level_factor * stat_factor * gear_factor * type_mult
	return {"damage": max(1, int(round(raw_damage))), "type_mult": type_mult}

## Background-stat hit-chance modifier (LOCKED shape 2026-08-31): nudges a
## move's own accuracy up or down by attacker Accuracy vs defender Evasion,
## same bounded cap^ratio shape as the rest of the formula, then floors it
## so no matchup can ever guarantee a miss. See the ACC_EVA_CAP doc comment
## above for why the ceiling isn't similarly restrictive.
func _compute_hit_chance(attacker: Combatant, defender: Combatant, move: MoveData) -> float:
	var acc: float = attacker.effective_accuracy()
	var eva: float = defender.effective_evasion()
	var ratio: float = 0.0
	if acc + eva > 0.0:
		ratio = (acc - eva) / (acc + eva)
	var modifier: float = pow(ACC_EVA_CAP, ratio)
	return clamp(move.accuracy * modifier, MIN_HIT_CHANCE, 1.0)

## Background-stat crit-chance (LOCKED shape 2026-08-31, same cap^ratio
## family). No opposing "crit resist" stat exists in the locked design, so
## the attacker's Crit stat is compared against CRIT_STAT_REFERENCE instead
## of a defender stat. Hard-clamped so a crit is never guaranteed.
func _compute_crit_chance(attacker: Combatant) -> float:
	var stat: float = attacker.effective_crit_stat()
	var ratio: float = 0.0
	if stat + CRIT_STAT_REFERENCE > 0.0:
		ratio = (stat - CRIT_STAT_REFERENCE) / (stat + CRIT_STAT_REFERENCE)
	var modifier: float = pow(CRIT_CAP, ratio)
	return clamp(BASE_CRIT_CHANCE * modifier, 0.0, MAX_CRIT_CHANCE)

## Top-level single-target entry point (2026-09-01 refactor): resolves the
## move's normal single-hit resolution against `defender` once per
## MultiHitEffect.hit_count() (1 for every move without one -- see
## MoveEffect's doc comment), stopping early if `defender` goes down
## partway through since there's nothing left to hit. For a move whose
## effects include a MultiTargetEffect, this only ever resolves against the
## one `defender` passed in -- resolve_multi_target_attack() below is the
## "hit everyone" case, and both the player action menu
## (_on_move_selected_all_enemies) and enemy-turn AI (_start_enemy_turn)
## route a MoveData.targets_all_enemies() move there automatically as of
## 2026-09-02, see MultiTargetEffect's doc comment.
func _resolve_attack(attacker: Combatant, defender: Combatant, move: MoveData) -> void:
	var hits := _hit_count(move)
	for i in hits:
		if defender.is_downed():
			break
		_resolve_single_hit(attacker, defender, move)

## _hit_count resolves per defender
func _hit_count(move: MoveData) -> int:
	return move.attempts
	

## Resolves `move` against every living entry in `targets` in turn (each
## target gets the full _resolve_attack treatment, multi-hit included, on
## its own -- one target going down doesn't affect the others). Called
## automatically for a MoveData.targets_all_enemies() move by both
## _on_move_selected_all_enemies (player) and _start_enemy_turn (AI) as of
## 2026-09-02 -- see MultiTargetEffect's doc comment.
func resolve_multi_target_attack(attacker: Combatant, targets: Array[Combatant], move: MoveData) -> void:
	for target in targets:
		if target.is_downed():
			continue
		_resolve_attack(attacker, target, move)

## One full resolution of `move` against `defender`: hit-chance roll,
## damage roll, crit roll, guard halving, HP applied, message written, then
## every one of the move's effects gets its apply() hook called (a no-op
## for anything that isn't a per-hit secondary effect, e.g. MultiHitEffect/
## MultiTargetEffect -- their hooks are consulted elsewhere, not here).
## Body is unchanged from the pre-refactor _resolve_attack, just renamed
## and wrapped by the hit-count loop above -- RNG draw order per hit is
## identical to before, so every existing seeded test still holds.
func _resolve_single_hit(attacker: Combatant, defender: Combatant, move: MoveData) -> void:
	var hit_chance := _compute_hit_chance(attacker, defender, move)
	if randf() > hit_chance:
		message_label.text = "%s used %s, but it missed!" % [attacker.data.display_name, move.display_name]
		return
	var result := _compute_damage(attacker, defender, move)
	var is_crit := randf() <= _compute_crit_chance(attacker)
	var damage: int = max(1, int(result.damage * randf_range(0.9, 1.1)))
	if is_crit:
		damage = max(1, int(damage * CRIT_DAMAGE_MULT))
	if defender.is_defending:
		damage = max(1, int(damage * 0.5))
	defender.apply_damage(damage)
	message_label.text = "%s used %s! It dealt %d damage to %s." % [
		attacker.data.display_name, move.display_name, damage, defender.data.display_name
	]
	if is_crit:
		message_label.text += " Critical hit!"
	var type_mult: float = result.type_mult
	if type_mult > 1.0:
		message_label.text += " It's super effective!"
	elif type_mult < 1.0:
		message_label.text += " It's not very effective..."
	if defender.is_downed():
		message_label.text += " %s is downed!" % defender.data.display_name
	for effect in move.effects:
		effect.apply(attacker, defender, self)
	_refresh_hud()

func _check_battle_over() -> bool:
	if _all_downed(enemy_party):
		state = State.BATTLE_OVER
		message_label.text = "The enemy party is downed! You won!"
		battle_won.emit()
		return true
	if _all_downed(player_party):
		state = State.BATTLE_OVER
		message_label.text = "Your whole party is downed! You lost."
		battle_lost.emit()
		return true
	return false

func _all_downed(party: Array[Combatant]) -> bool:
	for c in party:
		if not c.is_downed():
			return false
	return true

func _refresh_hud() -> void:
	hud.update_party(player_party, false)
	hud.update_party(enemy_party, true)
	_refresh_sprite_visibility()

func _refresh_sprite_visibility() -> void:
	for i in player_sprites.size():
		player_sprites[i].modulate = Color(1, 1, 1, 0.35) if player_party[i].is_downed() else Color(1, 1, 1, 1)
	for i in enemy_sprites.size():
		enemy_sprites[i].modulate = Color(1, 1, 1, 0.35) if enemy_party[i].is_downed() else Color(1, 1, 1, 1)
