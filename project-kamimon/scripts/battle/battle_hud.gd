extends Control
class_name BattleHUD
## Displays HP and ATB gauges for every combatant on both sides — up to four
## per party. Rows are built once per battle (build()) and then just have
## their values refreshed each tick (update_party()), rather than being
## rebuilt from scratch, since party membership doesn't change mid-battle.

@onready var player_party_panel: VBoxContainer = %PlayerPartyPanel
@onready var enemy_party_panel: VBoxContainer = %EnemyPartyPanel

var _player_rows: Array[Dictionary] = []
var _enemy_rows: Array[Dictionary] = []

func build(player_party: Array[Combatant], enemy_party: Array[Combatant]) -> void:
	_player_rows = _build_rows(player_party_panel, player_party.size())
	_enemy_rows = _build_rows(enemy_party_panel, enemy_party.size())

func _build_rows(panel: VBoxContainer, count: int) -> Array[Dictionary]:
	for child in panel.get_children():
		child.queue_free()
	var rows: Array[Dictionary] = []
	for i in count:
		var row := VBoxContainer.new()
		var name_label := Label.new()
		var hp_bar := ProgressBar.new()
		hp_bar.custom_minimum_size = Vector2(220, 16)
		hp_bar.show_percentage = false
		var atb_bar := ProgressBar.new()
		atb_bar.custom_minimum_size = Vector2(220, 8)
		atb_bar.show_percentage = false
		row.add_child(name_label)
		row.add_child(hp_bar)
		row.add_child(atb_bar)
		panel.add_child(row)
		rows.append({"root": row, "name": name_label, "hp": hp_bar, "atb": atb_bar})
	return rows

func update_party(party: Array[Combatant], is_enemy: bool) -> void:
	var rows := _enemy_rows if is_enemy else _player_rows
	for i in party.size():
		var c := party[i]
		var row: Dictionary = rows[i]
		var name_label: Label = row["name"]
		var hp_bar: ProgressBar = row["hp"]
		var atb_bar: ProgressBar = row["atb"]
		var root: VBoxContainer = row["root"]
		var tag := " (downed)" if c.is_downed() else ""
		name_label.text = "%s%s" % [c.data.display_name, tag]
		hp_bar.max_value = c.data.max_hp
		hp_bar.value = c.current_hp
		atb_bar.value = c.atb_ratio() * 100.0
		root.modulate = Color(1, 1, 1, 0.4) if c.is_downed() else Color(1, 1, 1, 1)
