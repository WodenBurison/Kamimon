extends Control
class_name BattleActionMenu
## Presents the player's battle choices and reports the result back through
## signals — this never touches Combatant/BattleManager state directly, it
## only knows about moves/party-status handed to it via open().
##
## Menu shape: Battle / Items / Stats / Run at the top level. Battle opens
## Attack, Guard, and the acting monster's three out-of-battle-assigned
## moves. Attack/moves that have more than one living enemy target prompt a
## target picker; a single living target is auto-selected. A move whose
## effects mark it as hitting every enemy (MoveData.targets_all_enemies(),
## added 2026-09-02) skips the picker entirely — it emits
## move_selected_all_enemies instead of move_selected, no target_index
## involved. Items and Stats are look-only for now — Items has no item
## system to back it yet (stub), and Stats is a read-only party status
## readout. Neither consumes a turn.
##
## Each of the 5 sub-menus lives inside its own ScrollContainer (RootMenu is
## the only one that's always a fixed 4 buttons; the rest can grow — Battle
## always has 6, Target scales with living enemies up to 4, Stats lists
## every combatant on both sides). That's a deliberate safety net: rather
## than hand-tuning ActionMenu's pixel size to whatever happens to fit
## today's button count, anything that doesn't fit just scrolls instead of
## silently running off the bottom of the screen.

signal attack_selected(target_index: int)
signal guard_selected
signal move_selected(move_index: int, target_index: int)
signal move_selected_random(move_index: int, target_index: int)
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

## Opens the top-level menu for whichever combatant's turn it is. moves is
## that combatant's assigned loadout (expected up to 3 — fewer shows
## disabled "--" slots). own_status/enemy_status are plain Dictionaries
## ({name, hp, max_hp, is_downed}) for the acting side and the opposing
## side, used to build the target picker and the Stats readout.
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

func hide_all() -> void:
	hide()

func _show_only(menu: Control) -> void:
	root_menu_scroll.hide()
	battle_menu_scroll.hide()
	target_menu_scroll.hide()
	items_menu_scroll.hide()
	stats_menu_scroll.hide()
	menu.show()

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

func _on_attack_button_pressed() -> void:
	_pending_action = "attack"
	_pending_move_index = -1
	_open_target_menu()

func _on_guard_button_pressed() -> void:
	guard_selected.emit()
	hide_all()

func _on_move_button_pressed(move_index: int) -> void:
	if move_index >= _actor_moves.size():
		return
	_pending_action = "move"
	_pending_move_index = move_index
	if _actor_moves[move_index].targets_all_enemies():
		_confirm_all_enemies()
		return
	if _actor_moves[move_index].random_target == true:
		_confirm_random_target()
		return
	_open_target_menu()

func _on_run_button_pressed() -> void:
	run_selected.emit()
	hide_all()

func _on_stats_button_pressed() -> void:
	_build_stats_menu()
	_show_only(stats_menu_scroll)

func _living_enemy_indices() -> Array[int]:
	var out: Array[int] = []
	for i in _enemy_status.size():
		if not _enemy_status[i]["is_downed"]:
			out.append(i)
	return out

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

func _confirm_target(target_index: int) -> void:
	var action := _pending_action
	var move_index := _pending_move_index
	_pending_action = ""
	_pending_move_index = -1
	hide_all()
	if action == "attack":
		attack_selected.emit(target_index)
	elif action == "move":
		move_selected.emit(move_index, target_index)

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
	

## Skips the target picker entirely for a move that hits every living enemy
## (see MoveData.targets_all_enemies()) -- there's nothing to pick between.
## Still respects the same "no living enemies, no-op" guard the normal
## target menu enforces via _open_target_menu's own living-list check.
func _confirm_all_enemies() -> void:
	var move_index := _pending_move_index
	_pending_action = ""
	_pending_move_index = -1
	hide_all()
	if _living_enemy_indices().is_empty():
		return
	move_selected_all_enemies.emit(move_index)

func _on_target_back_pressed() -> void:
	_pending_action = ""
	_pending_move_index = -1
	_show_only(battle_menu_scroll)

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

func _add_stats_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	stats_menu.add_child(label)

func _add_stats_line(entry: Dictionary) -> void:
	var label := Label.new()
	var tag := " (downed)" if entry["is_downed"] else ""
	label.text = "  %s — %d/%d HP%s" % [entry["name"], entry["hp"], entry["max_hp"], tag]
	stats_menu.add_child(label)
