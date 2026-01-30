extends Node
class_name BattleManager

enum BattleState {INIT, PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT}

@export var player: CharacterBase
@export var enemy: CharacterBase
@export var hand_manager: HandManager
@export var energy_label: Label
@export var end_turn_button: Button
@export var hand_container: Control # 改为Control支持弧形布局
@export var damage_number_scene: PackedScene

var current_state: BattleState = BattleState.INIT
var player_energy: int = 3
var max_energy: int = 3
var turn_count: int = 0

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []
var exhaust_pile: Array[CardData] = []

signal state_changed(new_state: BattleState)
signal energy_changed(current: int, maximum: int)
signal turn_started(is_player: bool)

func _ready() -> void:
	# 注意：player/enemy/hand_manager 等引用可能在 TestBattle._ready() 中设置
	# 所以这里只进行基本的信号连接
	pass

## 初始化战斗引用（由 TestBattle 调用）
func setup_battle_refs() -> void:
	if player:
		player.died.connect(_on_player_died)
	if enemy:
		enemy.died.connect(_on_enemy_died)
	if end_turn_button:
		end_turn_button.pressed.connect(end_player_turn)
	if hand_manager:
		if hand_container:
			hand_manager.hand_container = hand_container
		hand_manager.card_played.connect(_on_card_played)
		print("HandManager 配置完成，hand_container: ", hand_container)

func start_battle(starter_deck: Array[CardData], enemy_data: EnemyData) -> void:
	print("=== 战斗开始 ===")
	
	# 确保 hand_manager 已配置
	if hand_manager and hand_container and not hand_manager.hand_container:
		hand_manager.hand_container = hand_container
	
	draw_pile = starter_deck.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()
	hand.clear()
	exhaust_pile.clear()
	if enemy and enemy_data:
		enemy.max_hp = enemy_data.max_hp
		enemy.current_hp = enemy_data.max_hp
		enemy.name = enemy_data.enemy_name
	change_state(BattleState.PLAYER_TURN)
	start_player_turn()

func change_state(new_state: BattleState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	print("状态切换: %s" % BattleState.keys()[new_state])

func start_player_turn() -> void:
	turn_count += 1
	print("\n--- 玩家回合 %d ---" % turn_count)
	player_energy = max_energy
	energy_changed.emit(player_energy, max_energy)
	update_energy_ui()
	draw_cards(5)
	turn_started.emit(true)

func draw_cards(count: int) -> void:
	for i in range(count):
		if draw_pile.is_empty():
			shuffle_discard_into_draw()
			if draw_pile.is_empty():
				print("没有更多卡牌可抽！")
				break
		var card = draw_pile.pop_front()
		hand.append(card)
		print("抽到: %s" % card.card_name)
		if hand_manager:
			hand_manager.add_card(card)

func shuffle_discard_into_draw() -> void:
	if discard_pile.is_empty():
		return
	print("重新洗牌...")
	draw_pile.append_array(discard_pile)
	draw_pile.shuffle()
	discard_pile.clear()

func play_card(card: CardData, target: CharacterBase = null) -> bool:
	if player_energy < card.cost:
		print("真气不足！需要 %d，当前 %d" % [card.cost, player_energy])
		return false
	player_energy -= card.cost
	energy_changed.emit(player_energy, max_energy)
	hand.erase(card)
	execute_card_effect(card, target)
	if card.is_exhaust:
		exhaust_pile.append(card)
		print("%s 被移出战斗" % card.card_name)
	else:
		discard_pile.append(card)
	return true

func execute_card_effect(card: CardData, target: CharacterBase) -> void:
	print("打出: %s" % card.card_name)
	match card.type:
		CardData.CardType.ATTACK:
			var damage = card.base_value
			if player.status_effects.has("weak"):
				damage = int(damage * 0.75)
			var actual_target = target if target else enemy
			if actual_target:
				actual_target.take_damage(damage)
				show_damage_number(actual_target, damage, "damage")
		CardData.CardType.SKILL:
			if card.base_value > 0:
				player.add_block(card.base_value)
				show_damage_number(player, card.base_value, "block")
			if card.secondary_value > 0:
				draw_cards(card.secondary_value)
		CardData.CardType.POWER:
			if card.keywords.size() > 0:
				player.add_status(card.keywords[0], card.base_value)

func end_player_turn() -> void:
	print("\n玩家结束回合")
	discard_pile.append_array(hand)
	hand.clear()
	if hand_manager:
		hand_manager.clear_hand()
	player.clear_block()
	change_state(BattleState.ENEMY_TURN)
	await get_tree().create_timer(0.5).timeout
	start_enemy_turn()

func start_enemy_turn() -> void:
	print("\n--- 敌人回合 ---")
	turn_started.emit(false)
	var action = randi() % 100
	if action < 70:
		var damage = randi_range(5, 10)
		print("%s 攻击，造成 %d 点伤害" % [enemy.name, damage])
		player.take_damage(damage)
		show_damage_number(player, damage, "damage")
	else:
		var block_amount = randi_range(3, 8)
		print("%s 进入防御姿态，获得 %d 点护体" % [enemy.name, block_amount])
		enemy.add_block(block_amount)
		show_damage_number(enemy, block_amount, "block")
	await get_tree().create_timer(1.0).timeout
	enemy.clear_block()
	change_state(BattleState.PLAYER_TURN)
	start_player_turn()

func _on_player_died() -> void:
	change_state(BattleState.DEFEAT)
	print("\n=== 战斗失败 ===")

func _on_enemy_died() -> void:
	change_state(BattleState.VICTORY)
	print("\n=== 战斗胜利 ===")

func update_energy_ui() -> void:
	if energy_label:
		energy_label.text = "%d/%d" % [player_energy, max_energy]

## 显示伤害飞字
func show_damage_number(target: Node, value: int, damage_type: String = "damage") -> void:
	if not damage_number_scene:
		return
	
	var dmg_num = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(dmg_num)
	
	# 尝试获取目标位置
	var target_pos = Vector2(400, 300)
	if target is Node2D:
		target_pos = target.global_position
	elif target is Control:
		target_pos = target.global_position + target.size / 2
	
	dmg_num.global_position = target_pos + Vector2(randf_range(-20, 20), -30)
	
	if dmg_num.has_method("setup"):
		dmg_num.setup(value, damage_type)
	else:
		# 如果没有setup方法，直接设置Label
		var label = dmg_num.get_node_or_null("Label")
		if label:
			label.text = "-%d" % value if damage_type == "damage" else "+%d" % value

func _on_card_played(card: CardData) -> void:
	if play_card(card):
		if hand_manager:
			hand_manager.remove_card(card)
		update_energy_ui()
