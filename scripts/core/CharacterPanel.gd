extends Control
class_name CharacterPanel

## 通用角色面板脚本 - 用于玩家和敌人

@export var is_player: bool = true

## UI 节点引用 - 路径匹配场景结构
@onready var portrait_rect: TextureRect = $VBoxContainer/Portrait
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var hp_label: Label = $VBoxContainer/HPBar/HPLabel
@onready var block_container: HBoxContainer = $VBoxContainer/BlockContainer
@onready var block_label: Label = $VBoxContainer/BlockContainer/BlockLabel
@onready var status_container: HBoxContainer = $VBoxContainer/StatusContainer
@onready var intent_container: VBoxContainer = $VBoxContainer/IntentContainer # 仅敌人使用

var character: CharacterBase

func _ready() -> void:
	if intent_container:
		intent_container.visible = not is_player

## 绑定角色
func bind_character(chara: CharacterBase) -> void:
	character = chara
	if character:
		character.hp_changed.connect(_on_hp_changed)
		character.block_changed.connect(_on_block_changed)
		update_display()

## 更新显示
func update_display() -> void:
	if not character:
		return
	
	name_label.text = character.name
	_on_hp_changed(character.current_hp, character.max_hp)
	_on_block_changed(character.block)

## HP 变化回调
func _on_hp_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "%d/%d" % [current, maximum]
	
	# 血条颜色变化
	var hp_ratio = float(current) / float(maximum)
	if hp_ratio > 0.5:
		hp_bar.modulate = Color(0.2, 0.8, 0.2) # 绿色
	elif hp_ratio > 0.25:
		hp_bar.modulate = Color(0.9, 0.7, 0.1) # 黄色
	else:
		hp_bar.modulate = Color(0.9, 0.2, 0.2) # 红色

## 护甲变化回调
func _on_block_changed(block: int) -> void:
	block_container.visible = block > 0
	block_label.text = str(block)

## 设置意图（仅敌人）
func set_intent(intent_type: String, value: int = 0) -> void:
	if not intent_container or is_player:
		return
	
	# 清除旧意图
	for child in intent_container.get_children():
		if child.name != "IntentIcon":
			child.queue_free()
	
	var intent_label = Label.new()
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	match intent_type:
		"attack":
			intent_label.text = "⚔️ %d" % value
			intent_label.modulate = Color(1, 0.3, 0.3)
		"defend":
			intent_label.text = "🛡️ %d" % value
			intent_label.modulate = Color(0.3, 0.7, 1)
		"buff":
			intent_label.text = "⬆️ 强化"
			intent_label.modulate = Color(0.3, 1, 0.3)
		"debuff":
			intent_label.text = "⬇️ 削弱"
			intent_label.modulate = Color(0.8, 0.3, 0.8)
		_:
			intent_label.text = "❓"
	
	intent_container.add_child(intent_label)

## 添加状态效果图标
func add_status_icon(status_name: String, stacks: int) -> void:
	var status_label = Label.new()
	status_label.name = status_name
	
	match status_name:
		"vulnerable":
			status_label.text = "💔%d" % stacks
			status_label.tooltip_text = "内伤: 受到伤害+50%"
		"weak":
			status_label.text = "💪%d" % stacks
			status_label.tooltip_text = "破绽: 造成伤害-25%"
		"strength":
			status_label.text = "⚡%d" % stacks
			status_label.tooltip_text = "力量: 攻击+%d" % stacks
		_:
			status_label.text = "%s:%d" % [status_name, stacks]
	
	status_container.add_child(status_label)

## 清除状态图标
func clear_status_icons() -> void:
	for child in status_container.get_children():
		child.queue_free()
