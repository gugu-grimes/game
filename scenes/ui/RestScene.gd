extends Control

signal rest_completed

@onready var rest_button = $VBoxContainer/RestButton
@onready var upgrade_button = $VBoxContainer/UpgradeButton
@onready var message_label = $VBoxContainer/MessageLabel

func _ready() -> void:
	rest_button.pressed.connect(_on_rest_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	message_label.text = "你来到一处安静的营地..."

func _on_rest_pressed() -> void:
	var heal_amount = int(RunManager.max_hp * 0.3)
	RunManager.update_player_state(min(RunManager.current_hp + heal_amount, RunManager.max_hp))
	message_label.text = "你休息了一会儿，恢复了 %d 点生命。" % heal_amount
	
	_disable_buttons()
	await get_tree().create_timer(1.5).timeout
	rest_completed.emit()

func _on_upgrade_pressed() -> void:
	# TODO: 实现卡牌升级界面
	message_label.text = "正在修炼武功... (暂未实现)"
	
	_disable_buttons()
	await get_tree().create_timer(1.0).timeout
	rest_completed.emit()

func _disable_buttons() -> void:
	rest_button.disabled = true
	upgrade_button.disabled = true
