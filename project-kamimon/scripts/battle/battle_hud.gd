extends Control
class_name BattleHUD
## Displays HP and ATB gauges for the active player and enemy monster.
##
## Child references use scene-unique names (%Name) instead of get_node paths
## — the nodes are owned by this component's own scene, so a % lookup stays
## valid even if this subtree gets moved around inside a bigger scene later.

@onready var player_name_label: Label = %PlayerNameLabel
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_atb_bar: ProgressBar = %PlayerATBBar
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_atb_bar: ProgressBar = %EnemyATBBar

func update_player(combatant: Combatant) -> void:
	player_name_label.text = combatant.data.display_name
	player_hp_bar.max_value = combatant.data.max_hp
	player_hp_bar.value = combatant.current_hp
	player_atb_bar.value = combatant.atb_ratio() * 100.0

func update_enemy(combatant: Combatant) -> void:
	enemy_name_label.text = combatant.data.display_name
	enemy_hp_bar.max_value = combatant.data.max_hp
	enemy_hp_bar.value = combatant.current_hp
	enemy_atb_bar.value = combatant.atb_ratio() * 100.0
