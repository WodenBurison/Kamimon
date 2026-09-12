extends Control
class_name BattleActionMenu
## Presents the player's battle choices and reports the result back through
## signals -- this never touches Combatant/BattleManager state directly, it
## only knows about moves/party-status handed to it via open().
##
## Menu shape: Battle / Items / Stats / Run at the top level. Battle opens
## Attack, Guard, and the acting monster's three out-of-battle-assigned
## moves. A move with target_all skips the target picker and hits every
## living enemy; a move with random_target skips it and hits one random
## living enemy; otherwise a target picker opens (auto-skipped when only
## one enemy is alive). Items and Stats are look-only for now -- Items has
## no item system to back it yet (stub), Stats is a read-only party status
## readout. Neither consumes a turn.
##
## Each of the 5 sub-menus lives inside its own ScrollContainer so a full
## button list scrolls instead of running off the screen.

signal attack_selected(target_index: int)
signal guard_selected
signal move_selected(move_index: int, target_index: int)
signal move_selected_random(move_index: int, target_index: int)
signal move_selected_targets(move_index: int, target_indices: Array[int])
signal move_selected_all_enemies(move_index: int)
signal run_selected

@onready var root_menu_scroll: ScrollContainer = %RootMenuScroll
@onready var root_menu: VBoxContainer = %RootMenu
@onready var battle_button: Button = %BattleButton
@onready var items_button: Button = %ItemsButton
@onready var stats_button: Button = %StatsButton
@onready var run_button: Button = %RunButton

@onready var battle_menu_scroll: ScrollContainer = %BattleMenuScroll
@onready var battle_menu: VBoxContainer = %BattleMenu
@onready var attack_button: Button = %AttackButton
@onready var guard_button: Button = %GuardButton
@onready var move1_button: Button = %Move1Button
@onready var move2_button: Button = %Move2Button
@onready var move3_button: Button = %Move3Button
@onready var battle_back_button: Button = %BattleBackButton

@onready var target_menu_scroll: ScrollContainer = %TargetMenuScroll
@onready var target_menu: VBoxContainer = %TargetMenu
@onready var target_back_button: Button = %TargetBackButton

@onready var items_menu_scroll: ScrollContainer = %ItemsMenuScroll
@onready var items_menu: VBoxContainer = %ItemsMenu
@onready var items_back_button: Button = %ItemsBackButton

@onready var stats_menu_scroll: ScrollContainer = %StatsMenuScroll
@onready var stats_menu: VBoxContainer = %StatsMenu
@onready var stats_back_button: Button = %StatsBackButton

var _actor_moves: Array[MoveData] = []
var _own_status: Array[Dictionary] = []
var _enemy_status: Array[Dictionary] = []

## "attack", "move", or "" when no target pick is pending.
var _pending_action := ""
var _pending_move_index := -1
var _pending_target_indices: Array[int] = []
var _pending_target_limit := 0

## Called from: Godot itself, automatically, when this node enters the
## scene tree.
## Purpose: wires every button's pressed signal to its handler.
func _ready() -> void:
	battle_button.pressed.connect(func(): _show_only(battle_menu_scroll))
	items_button.pressed.connect(func(): _show_only(items_menu_scroll))
	stats_button.pressed.connect(_on_stats_button_pressed)
	run_button.pressed.connect(_on_run_button_pressed)

	attack_button.pressed.connect(_on_attack_button_pressed)
	guard_button.pressed.connect(_on_guard_button_pressed)
	move1_button.pressed.connect(_on_move_button_pressed.bind(0))
	move2_button.pressed.connect(_on_move_button_pressed.bind(1))
	move3_button.pressed.connect(_on_move_button_pressed.bind(2))
	battle_back_button.pressed.connect(func(): _show_only(root_menu_scroll))

	target_back_button.pressed.connect(_on_target_back_pressed)
	items_back_button.pressed.connect(func(): _show_only(root_menu_scroll))
	stats_back_button.pressed.connect(func(): _show_only(root_menu_scroll))

	hide_all()

## Called from: battle_manager.gd, when a combatant's turn starts.
## Purpose: shows the root menu for the acting combatant, loaded with
## their 3 assigned moves and both parties' status.
func open(moves: Array[MoveData], own_status: Array[Dictionary], enemy_status: Array[Dictionary]) -> void:
	_actor_moves = moves
	_own_status = own_status
	_enemy_status = enemy_status
	_pending_action = ""
	_pending_move_index = -1
	_refresh_battle_menu_labels()
	_build_stats_menu()
	_show_only(root_menu_scroll)
	show()

## Called from: battle_manager.gd, after every resolved action (attack,
## guard, move, run) to close the menu until the next turn.
## Purpose: hides the whole menu.
func hide_all() -> void:
	hide()

## Called from: internal only -- every "show this sub-menu, hide the
## rest" spot in this file (button handlers, open(), back buttons).
## Purpose: shows exactly one of the 5 sub-menus, hides the other 4.
func _show_only(menu: Control) -> void:
	root_menu_scroll.hide()
	battle_menu_scroll.hide()
	target_menu_scroll.hide()
	items_menu_scroll.hide()
	stats_menu_scroll.hide()
	menu.show()

## Called from: internal only -- open().
## Purpose: sets each of the 3 move buttons' label/disabled state to
## match the acting combatant's actual assigned moves.
func _refresh_battle_menu_labels() -> void:
	var slots := [move1_button, move2_button, move3_button]
	for i in slots.size():
		var button: Button = slots[i]
		if i < _actor_moves.size():
			button.text = _actor_moves[i].display_name
			button.disabled = false
		else:
			button.text = "--"
			button.disabled = true

## Called from: attack_button's pressed signal (wired in _ready()).
## Purpose: starts the Attack flow -- opens the target picker.
func _on_attack_button_pressed() -> void:
	_pending_action = "attack"
	_pending_move_index = -1
	_open_target_menu()

## Called from: guard_button's pressed signal (wired in _ready()).
## Purpose: Guard doesn't need a target, so this fires the signal and
## closes the menu immediately.
func _on_guard_button_pressed() -> void:
	guard_selected.emit()
	hide_all()

## Called from: move1/move2/move3_button's pressed signal, each bound
## with its index (wired in _ready()).
## Purpose: routes to the right targeting flow for the chosen move --
## every enemy, one random enemy, or the normal target picker.
func _on_move_button_pressed(move_index: int) -> void:
	if move_index >= _actor_moves.size():
		return
	_pending_action = "move"
	_pending_move_index = move_index
	_pending_target_indices.clear()
	_pending_target_limit = 0
	if _actor_moves[move_index].target_all:
		_confirm_all_enemies()
		return
	if _actor_moves[move_index].random_target == true:
		_confirm_random_target()
		return
	if _actor_moves[move_index].targets > 1:
		_open_multi_target_menu()
		return
	_open_target_menu()

## Called from: run_button's pressed signal (wired in _ready()).
## Purpose: Run doesn't need a target, fires the signal and closes.
func _on_run_button_pressed() -> void:
	run_selected.emit()
	hide_all()

## Called from: stats_button's pressed signal (wired in _ready()).
## Purpose: rebuilds the stats readout (HP can have changed since it was
## last shown) and switches to it.
func _on_stats_button_pressed() -> void:
	_build_stats_menu()
	_show_only(stats_menu_scroll)

## Called from: internal only -- _open_target_menu(),
## _confirm_random_target(), _confirm_all_enemies().
## Purpose: returns the indices into _enemy_status of every enemy that
## isn't downed.
func _living_enemy_indices() -> Array[int]:
	var out: Array[int] = []
	for i in _enemy_status.size():
		if not _enemy_status[i]["is_downed"]:
			out.append(i)
	return out

## Called from: internal only -- _on_attack_button_pressed(), and
## _on_move_button_pressed()'s fallback for a move that's neither
## target_all nor random_target.
## Purpose: opens the target picker, unless there are 0 living enemies
## (no-op) or exactly 1 (auto-picked, no menu needed).
func _open_target_menu() -> void:
	var living := _living_enemy_indices()
	if living.is_empty():
		_pending_action = ""
		return
	if living.size() == 1:
		_confirm_target(living[0])
		return
	_build_target_menu(living)
	_show_only(target_menu_scroll)

## Called from: internal only -- _on_move_button_pressed() when a move has
## targets > 1.
## Purpose: opens a target picker that keeps collecting enemy choices until
## the move's target count is reached.
func _open_multi_target_menu() -> void:
	var living := _living_enemy_indices()
	if living.is_empty():
		_pending_action = ""
		_pending_move_index = -1
		_pending_target_indices.clear()
		_pending_target_limit = 0
		return
	_pending_target_indices.clear()
	_pending_target_limit = min(_actor_moves[_pending_move_index].targets, living.size())
	if _pending_target_limit <= 1:
		_confirm_target(living[0])
		return
	_build_target_menu(living)
	_show_only(target_menu_scroll)

## Called from: internal only -- _open_target_menu().
## Purpose: builds one button per living enemy in the target menu.
func _build_target_menu(living: Array[int]) -> void:
	for child in target_menu.get_children():
		if child != target_back_button:
			child.queue_free()
	for i in living:
		var entry: Dictionary = _enemy_status[i]
		var button := Button.new()
		button.text = "%s (%d/%d HP)" % [entry["name"], entry["hp"], entry["max_hp"]]
		button.pressed.connect(_confirm_target.bind(i))
		target_menu.add_child(button)
	target_menu.move_child(target_back_button, target_menu.get_child_count() - 1)

## Called from: internal only -- each target-menu button's pressed
## signal (bound in _build_target_menu()), and directly by
## _open_target_menu() when there's exactly one living enemy.
## Purpose: closes the menu and fires attack_selected or move_selected
## with whichever target got picked.
func _confirm_target(target_index: int) -> void:
	var action := _pending_action
	var move_index := _pending_move_index
	if action == "move" and move_index >= 0 and move_index < _actor_moves.size() and _actor_moves[move_index].targets > 1:
		if not _pending_target_indices.has(target_index):
			_pending_target_indices.append(target_index)
		if _pending_target_indices.size() >= _pending_target_limit:
			var selected_targets := _pending_target_indices.duplicate()
			_pending_action = ""
			_pending_move_index = -1
			_pending_target_indices.clear()
			_pending_target_limit = 0
			hide_all()
			move_selected_targets.emit(move_index, selected_targets)
			return
		_show_only(target_menu_scroll)
		return

	_pending_action = ""
	_pending_move_index = -1
	_pending_target_indices.clear()
	_pending_target_limit = 0
	hide_all()
	if action == "attack":
		attack_selected.emit(target_index)
	elif action == "move":
		move_selected.emit(move_index, target_index)

## Called from: internal only -- _on_move_button_pressed(), for a move
## with random_target true.
## Purpose: closes the menu and fires move_selected_random against one
## randomly-chosen living enemy -- resolved here, not left to
## battle_manager.gd, so the target index is already final by the time
## the signal goes out.
func _confirm_random_target() -> void:
	var move_index := _pending_move_index
	_pending_action = ""
	_pending_move_index = -1
	hide_all()
	var enemy_choices: Array[int] = _living_enemy_indices()
	if enemy_choices.is_empty():
		return
	var enemy_chosen: int = enemy_choices.pick_random()
	move_selected_random.emit(move_index, enemy_chosen)


## Called from: internal only -- _on_move_button_pressed(), for a move
## with target_all true.
## Purpose: closes the menu and fires move_selected_all_enemies --
## nothing to pick, so there's no target_index in the signal.
func _confirm_all_enemies() -> void:
	var move_index := _pending_move_index
	_pending_action = ""
	_pending_move_index = -1
	hide_all()
	if _living_enemy_indices().is_empty():
		return
	move_selected_all_enemies.emit(move_index)

## Called from: target_back_button's pressed signal (wired in _ready()).
## Purpose: cancels the pending attack/move and returns to the Battle
## menu.
func _on_target_back_pressed() -> void:
	_pending_action = ""
	_pending_move_index = -1
	_show_only(battle_menu_scroll)

## Called from: open() and _on_stats_button_pressed().
## Purpose: rebuilds the Stats sub-menu's list of every combatant on
## both sides.
func _build_stats_menu() -> void:
	for child in stats_menu.get_children():
		if child != stats_back_button:
			child.queue_free()
	_add_stats_header("Your party:")
	for entry in _own_status:
		_add_stats_line(entry)
	_add_stats_header("Enemy party:")
	for entry in _enemy_status:
		_add_stats_line(entry)
	stats_menu.move_child(stats_back_button, stats_menu.get_child_count() - 1)

## Called from: internal only -- _build_stats_menu().
## Purpose: adds a section header label ("Your party:" / "Enemy
## party:").
func _add_stats_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	stats_menu.add_child(label)

## Called from: internal only -- _build_stats_menu().
## Purpose: adds one combatant's HP/downed-status line.
func _add_stats_line(entry: Dictionary) -> void:
	var label := Label.new()
	var tag := " (downed)" if entry["is_downed"] else ""
	label.text = "  %s — %d/%d HP%s" % [entry["name"], entry["hp"], entry["max_hp"], tag]
	stats_menu.add_child(label)
