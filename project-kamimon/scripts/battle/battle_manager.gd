extends Node2D
class_name BattleManager
## Orchestrates one ATB battle: gauge ticking, player input, attack
## resolution, switching, and win/loss detection.
##
## References to the other pieces (HUD, action menu, sprites, message label)
## are wired in the Inspector via the exported NodePath slots below and
## resolved in _ready() — the scene that owns this node decides what's
## plugged into it, this script never hardcodes a path to go find them on
## its own.

signal battle_won
signal battle_lost

@export var hud_path: NodePath
@export var action_menu_path: NodePath
@export var message_label_path: NodePath
@export var player_battler_sprite_path: NodePath
@export var enemy_battler_sprite_path: NodePath

var hud: BattleHUD
var action_menu: BattleActionMenu
var message_label: Label
var player_battler_sprite: Sprite2D
var enemy_battler_sprite: Sprite2D

enum State { TICKING, PLAYER_INPUT, FORCED_SWITCH, RESOLVING, BATTLE_OVER }

var player_party: Array[Combatant] = []
var enemy_party: Array[Combatant] = []
var player_active_index: int = 0
var enemy_active_index: int = 0
var state: State = State.TICKING

func _ready() -> void:
	hud = get_node(hud_path)
	action_menu = get_node(action_menu_path)
	message_label = get_node(message_label_path)
	player_battler_sprite = get_node(player_battler_sprite_path)
	enemy_battler_sprite = get_node(enemy_battler_sprite_path)
	_build_parties()
	action_menu.attack_selected.connect(_on_attack_selected)
	action_menu.switch_selected.connect(_on_switch_selected)
	_refresh_sprites()
	_refresh_hud()
	message_label.text = "A wild %s appeared!" % _enemy_active().data.display_name
	action_menu.hide_all()
	state = State.TICKING

func _build_parties() -> void:
	for monster in PlaceholderBattleData.get_player_party():
		player_party.append(Combatant.new(monster))
	for monster in PlaceholderBattleData.get_enemy_party():
		enemy_party.append(Combatant.new(monster))

func _player_active() -> Combatant:
	return player_party[player_active_index]

func _enemy_active() -> Combatant:
	return enemy_party[enemy_active_index]

## Only the two active combatants tick — bench monsters do not charge while
## waiting. That is a simplification, not a rule from the design doc; swap
## it out if the party-wide ATB feel is wanted instead.
func _process(delta: float) -> void:
	if state != State.TICKING:
		return
	_player_active().tick(delta)
	_enemy_active().tick(delta)
	_refresh_hud()
	if _player_active().is_ready():
		_start_player_turn()
	elif _enemy_active().is_ready():
		_run_enemy_turn()

func _start_player_turn() -> void:
	state = State.PLAYER_INPUT
	action_menu.open(_player_active().data.moves, _player_party_status())
	message_label.text = "%s is ready to act!" % _player_active().data.display_name

func _player_party_status() -> Array[Dictionary]:
	var status: Array[Dictionary] = []
	for i in player_party.size():
		var c := player_party[i]
		status.append({
			"name": c.data.display_name,
			"is_fainted": c.is_fainted(),
			"is_active": i == player_active_index,
		})
	return status

func _on_attack_selected(move_index: int) -> void:
	if state != State.PLAYER_INPUT:
		return
	var actor := _player_active()
	var move := actor.data.moves[move_index]
	_resolve_attack(actor, _enemy_active(), move)
	actor.reset_gauge()
	action_menu.hide_all()
	_after_player_action()

func _on_switch_selected(party_index: int) -> void:
	if state != State.PLAYER_INPUT and state != State.FORCED_SWITCH:
		return
	var was_forced := state == State.FORCED_SWITCH
	player_active_index = party_index
	message_label.text = "Go, %s!" % _player_active().data.display_name
	_refresh_sprites()
	_refresh_hud()
	action_menu.hide_all()
	if was_forced:
		state = State.TICKING
	else:
		_after_player_action()

func _after_player_action() -> void:
	if _check_battle_over():
		return
	state = State.TICKING

func _run_enemy_turn() -> void:
	state = State.RESOLVING
	var actor := _enemy_active()
	var moves := actor.data.moves
	var move: MoveData = moves[randi() % moves.size()]
	_resolve_attack(actor, _player_active(), move)
	actor.reset_gauge()
	if _check_battle_over():
		return
	if _player_active().is_fainted():
		_prompt_forced_switch()
	else:
		state = State.TICKING

func _prompt_forced_switch() -> void:
	state = State.FORCED_SWITCH
	message_label.text = "%s fainted! Choose your next monster." % _player_active().data.display_name
	action_menu.open_switch_only(_player_party_status())

func _resolve_attack(attacker: Combatant, defender: Combatant, move: MoveData) -> void:
	if randf() > move.accuracy:
		message_label.text = "%s used %s, but it missed!" % [attacker.data.display_name, move.display_name]
		return
	# Flat power vs. defense goes here until the type chart exists.
	var raw: int = attacker.data.attack + move.power - defender.data.defense
	var damage := int(max(1, raw) * randf_range(0.9, 1.1))
	defender.apply_damage(damage)
	message_label.text = "%s used %s! It dealt %d damage." % [attacker.data.display_name, move.display_name, damage]
	_refresh_hud()

func _check_battle_over() -> bool:
	if _all_fainted(enemy_party):
		state = State.BATTLE_OVER
		message_label.text = "%s fainted! You won!" % _enemy_active().data.display_name
		battle_won.emit()
		return true
	if _all_fainted(player_party):
		state = State.BATTLE_OVER
		message_label.text = "Your whole party fainted! You lost."
		battle_lost.emit()
		return true
	return false

func _all_fainted(party: Array[Combatant]) -> bool:
	for c in party:
		if not c.is_fainted():
			return false
	return true

func _refresh_sprites() -> void:
	player_battler_sprite.texture = _player_active().data.battler_sprite
	enemy_battler_sprite.texture = _enemy_active().data.battler_sprite

func _refresh_hud() -> void:
	hud.update_player(_player_active())
	hud.update_enemy(_enemy_active())
