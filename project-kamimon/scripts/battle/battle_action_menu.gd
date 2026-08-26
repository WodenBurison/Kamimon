extends Control
class_name BattleActionMenu
## Presents the player's battle choices and reports the result back through
## signals — this never touches Combatant/BattleManager state directly, it
## only knows about moves-to-show and party-status-to-show.

signal attack_selected(move_index: int)
signal switch_selected(party_index: int)

@onready var root_menu: VBoxContainer = %RootMenu
@onready var attack_button: Button = %AttackButton
@onready var switch_button: Button = %SwitchButton
@onready var move_menu: VBoxContainer = %MoveMenu
@onready var switch_menu: VBoxContainer = %SwitchMenu

var _current_moves: Array[MoveData] = []
var _switch_only := false

func _ready() -> void:
	attack_button.pressed.connect(_on_attack_button_pressed)
	switch_button.pressed.connect(_on_switch_button_pressed)
	hide_all()

## Normal turn: both Attack and Switch are choices.
func open(moves: Array[MoveData], party_status: Array[Dictionary]) -> void:
	_switch_only = false
	_current_moves = moves
	_build_switch_menu(party_status)
	root_menu.show()
	move_menu.hide()
	switch_menu.hide()
	show()

## Forced switch after a faint: only Switch is offered, no Back option.
func open_switch_only(party_status: Array[Dictionary]) -> void:
	_switch_only = true
	_build_switch_menu(party_status)
	root_menu.hide()
	move_menu.hide()
	switch_menu.show()
	show()

func hide_all() -> void:
	hide()

func _on_attack_button_pressed() -> void:
	root_menu.hide()
	_build_move_menu()
	move_menu.show()

func _on_switch_button_pressed() -> void:
	root_menu.hide()
	switch_menu.show()

func _build_move_menu() -> void:
	for child in move_menu.get_children():
		child.queue_free()
	for i in _current_moves.size():
		var move := _current_moves[i]
		var button := Button.new()
		button.text = move.display_name
		button.pressed.connect(_on_move_button_pressed.bind(i))
		move_menu.add_child(button)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(_on_move_back_pressed)
	move_menu.add_child(back)

func _build_switch_menu(party_status: Array[Dictionary]) -> void:
	for child in switch_menu.get_children():
		child.queue_free()
	for i in party_status.size():
		var entry: Dictionary = party_status[i]
		var button := Button.new()
		var label: String = entry["name"]
		if entry["is_active"]:
			label += " (active)"
		if entry["is_fainted"]:
			label += " (fainted)"
		button.text = label
		button.disabled = entry["is_fainted"] or entry["is_active"]
		button.pressed.connect(_on_switch_button_item_pressed.bind(i))
		switch_menu.add_child(button)
	if not _switch_only:
		var back := Button.new()
		back.text = "Back"
		back.pressed.connect(_on_switch_back_pressed)
		switch_menu.add_child(back)

func _on_move_button_pressed(move_index: int) -> void:
	attack_selected.emit(move_index)

func _on_switch_button_item_pressed(party_index: int) -> void:
	switch_selected.emit(party_index)

func _on_move_back_pressed() -> void:
	move_menu.hide()
	root_menu.show()

func _on_switch_back_pressed() -> void:
	switch_menu.hide()
	root_menu.show()
