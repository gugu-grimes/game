extends Node2D

## 战斗场景控制器
## 既可以独立运行（自动开始测试战斗），也可以被 GameLoop 调用

@export var auto_start_battle: bool = true

@onready var battle_manager = $BattleManager
@onready var player = $Player
@onready var enemy = $Enemy
@onready var hand_manager = $UI/HandManager
@onready var energy_label = $UI/TopBar/EnergyOrb/EnergyLabel
@onready var end_turn_button = $UI/TopBar/EndTurnButton
@onready var hand_container = $UI/HandArea/HandContainer
@onready var player_panel = $UI/CharacterArea/PlayerPanel
@onready var enemy_panel = $UI/CharacterArea/EnemyPanel
@onready var draw_pile_label = $UI/TopBar/DrawPileCounter/CountLabel
@onready var discard_pile_label = $UI/TopBar/DiscardPileCounter/CountLabel
@onready var turn_indicator = $UI/TurnIndicator

const MERIDIAN_BAR_SCENE = preload("res://scenes/ui/MeridianBar.tscn")

func _ready() -> void:
	print("初始化战斗场景...")
	
	# 调整UI布局：将真气球移动到手牌区域上方
	_reparent_energy_orb()
	
	# 创建并添加经脉槽UI
	var meridian_bar = MERIDIAN_BAR_SCENE.instantiate()
	$UI/CharacterArea.add_child(meridian_bar)
	# 手动调整位置（假设PlayerPanel在左侧）
	meridian_bar.position = Vector2(20, 320) # 在角色面板下方
	
	# 设置 BattleManager 的引用
	battle_manager.player = player
	battle_manager.enemy = enemy
	battle_manager.hand_manager = hand_manager
	battle_manager.energy_label = energy_label
	battle_manager.end_turn_button = end_turn_button
	battle_manager.hand_container = hand_container
	battle_manager.meridian_container = meridian_bar
	
	# 初始化战斗引用（连接信号等）
	battle_manager.setup_battle_refs()
	
	# 绑定角色面板
	if player_panel and player_panel.has_method("bind_character"):
		player_panel.bind_character(player)
		player_panel.get_node("VBoxContainer/Portrait/PortraitPlaceholder").color = Color(0.2, 0.5, 0.8)
	
	if enemy_panel and enemy_panel.has_method("bind_character"):
		enemy_panel.bind_character(enemy)
		enemy_panel.get_node("VBoxContainer/Portrait/PortraitPlaceholder").color = Color(0.8, 0.3, 0.3)
	
	# 连接信号更新UI
	battle_manager.energy_changed.connect(_on_energy_changed)
	battle_manager.state_changed.connect(_on_state_changed)
	
	if auto_start_battle:
		print("自动启动测试战斗...")
		start_test_battle()

func _reparent_energy_orb() -> void:
	var energy_orb = $UI/TopBar/EnergyOrb
	var hand_area = $UI/HandArea
	
	if energy_orb and hand_area:
		# 记录当前位置的相对关系并不重要，因为我们要重新定位
		energy_orb.reparent(hand_area)
		
		# 设置锚点为顶部中间
		energy_orb.set_anchors_preset(Control.PRESET_CENTER_TOP)
		# 微调位置，向上偏移一点，使其位于手牌区域边界
		energy_orb.position.y = -40
		energy_orb.position.x = hand_area.size.x / 2 - energy_orb.size.x / 2
		
		print("真气球已移动到手牌区域")

func start_test_battle() -> void:
	# 创建初始卡组和敌人
	var starter_deck = CardFactory.create_starter_deck()
	var test_enemy = CardFactory.create_test_enemy()
	
	# 设置敌人名称
	enemy.name = test_enemy.enemy_name
	
	# 延迟启动战斗
	await get_tree().create_timer(0.5).timeout
	battle_manager.start_battle(starter_deck, test_enemy)
	
	# 更新牌堆显示
	_update_pile_counts()
	
	# 设置敌人意图
	_update_enemy_intent()
	
	print("战斗已启动！")

# 供外部调用的启动方法
func start_external_battle(enemy_data: EnemyData) -> void:
	# 设置敌人名称
	enemy.name = enemy_data.enemy_name
	
	# 启动战斗（传入空 deck，因为 BattleManager 会从 RunManager 读取）
	var empty_deck: Array[CardData] = []
	battle_manager.start_battle(empty_deck, enemy_data)
	
	_update_pile_counts()
	_update_enemy_intent()

func _on_energy_changed(current: int, maximum: int) -> void:
	if energy_label:
		energy_label.text = "%d/%d" % [current, maximum]

func _on_state_changed(new_state) -> void:
	match new_state:
		0: # INIT
			turn_indicator.text = "准备中..."
		1: # PLAYER_TURN
			turn_indicator.text = "玩家回合"
			turn_indicator.modulate = Color(0.3, 0.8, 0.3)
			_update_enemy_intent()
		2: # ENEMY_TURN
			turn_indicator.text = "敌人回合"
			turn_indicator.modulate = Color(0.8, 0.3, 0.3)
		3: # VICTORY
			turn_indicator.text = "胜利！"
			turn_indicator.modulate = Color(1, 0.8, 0.2)
		4: # DEFEAT
			turn_indicator.text = "失败..."
			turn_indicator.modulate = Color(0.5, 0.5, 0.5)
	
	_update_pile_counts()

func _update_pile_counts() -> void:
	if draw_pile_label:
		draw_pile_label.text = str(battle_manager.draw_pile.size())
	if discard_pile_label:
		discard_pile_label.text = str(battle_manager.discard_pile.size())

func _update_enemy_intent() -> void:
	if not enemy_panel:
		return
	
	# 简单随机意图，实际应从 BattleManager 或 EnemyData 获取
	# TODO: 集成真正的意图系统
	var intent_type = "attack" if randf() < 0.7 else "defend"
	var value = randi_range(5, 12) if intent_type == "attack" else randi_range(4, 8)
	
	if enemy_panel.has_method("set_intent"):
		enemy_panel.set_intent(intent_type, value)
