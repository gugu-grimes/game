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
@export var meridian_container: Control # 经脉槽UI

var current_state: BattleState = BattleState.INIT
var player_energy: int = 3
var max_energy: int = 10 # 修改最大真气为10
var energy_regen: int = 3 # 每回合回复3点
var player_momentum: int = 0
var turn_count: int = 0

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []
var exhaust_pile: Array[CardData] = []

signal state_changed(new_state: BattleState)
signal energy_changed(current: int, maximum: int)
signal momentum_changed(current: int)
signal turn_started(is_player: bool)
signal battle_ended(victory: bool)

func _ready() -> void:
	pass

## 初始化战斗引用（由 TestBattle 调用）
func setup_battle_refs() -> void:
	if player:
		if not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)
	if enemy:
		if not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)
	if end_turn_button:
		if not end_turn_button.pressed.is_connected(end_player_turn):
			end_turn_button.pressed.connect(end_player_turn)
	if hand_manager:
		if hand_container:
			hand_manager.hand_container = hand_container
		if not hand_manager.card_played.is_connected(_on_card_played):
			hand_manager.card_played.connect(_on_card_played)
		if not hand_manager.fusion_requested.is_connected(_on_fusion_requested):
			hand_manager.fusion_requested.connect(_on_fusion_requested)
		print("HandManager 配置完成，hand_container: ", hand_container)

func start_battle(starter_deck: Array[CardData], enemy_data: EnemyData) -> void:
	print("=== 战斗开始 ===")
	
	# 确保 hand_manager 已配置
	if hand_manager and hand_container and not hand_manager.hand_container:
		hand_manager.hand_container = hand_container
	
	# 集成 RunManager
	if RunManager.current_deck.size() > 0:
		print("从 RunManager 加载牌组")
		draw_pile = []
		for card in RunManager.current_deck:
			draw_pile.append(card.duplicate())
		
		player.max_hp = RunManager.max_hp
		player.current_hp = RunManager.current_hp
		max_energy = RunManager.max_energy # 这里可能需要 RunManager 也更新 max_energy
		# 临时覆盖为10，如果 RunManager 没更新
		max_energy = 10
		player_energy = 3 # 初始真气
	else:
		print("使用初始牌组（测试模式）")
		draw_pile = starter_deck.duplicate()
		RunManager.start_new_run(starter_deck)
		player_energy = 3
	
	draw_pile.shuffle()
	discard_pile.clear()
	hand.clear()
	exhaust_pile.clear()
	player_momentum = 0
	
	# 清空并初始化经脉（如果是新战斗）
	player.meridians.clear()
	if meridian_container and meridian_container.has_method("update_slots"):
		meridian_container.update_slots(player.meridians)
	
	if enemy and enemy_data:
		enemy.max_hp = enemy_data.max_hp
		enemy.current_hp = enemy_data.max_hp
		enemy.name = enemy_data.enemy_name
	
	change_state(BattleState.PLAYER_TURN)
	start_player_turn(true) # 标记为首回合

func change_state(new_state: BattleState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	print("状态切换: %s" % BattleState.keys()[new_state])

func start_player_turn(is_first_turn: bool = false) -> void:
	turn_count += 1
	print("\n--- 玩家回合 %d ---" % turn_count)
	
	# 回合开始时清除护体（除非有固守状态）
	player.clear_block()
	
	# 真气回复（累积制）
	if not is_first_turn:
		player_energy = min(player_energy + energy_regen, max_energy)
	
	energy_changed.emit(player_energy, max_energy)
	player_momentum = 0
	momentum_changed.emit(player_momentum)
	update_energy_ui()
	
	# 抽牌逻辑
	var draw_count = 5 if is_first_turn else 2
	draw_cards(draw_count)
	
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
	
	# 内功牌进入经脉槽，不进入弃牌堆/消耗堆（除非有特殊逻辑）
	if card.type == CardData.CardType.POWER:
		pass 
	elif card.is_exhaust:
		exhaust_pile.append(card)
		print("%s 被移出战斗" % card.card_name)
	else:
		_discard_card(card)
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
				var momentum_gain = 1 + card.momentum_gain
				add_momentum(momentum_gain)
				if card.breach_apply > 0:
					actual_target.add_breach(card.breach_apply)
				actual_target.take_damage(damage)
				show_damage_number(actual_target, damage, "damage")
				if card.keywords.size() > 0:
					var stacks = card.secondary_value if card.secondary_value > 0 else 1
					for keyword in card.keywords:
						actual_target.add_status(keyword, stacks)
		CardData.CardType.SKILL:
			if card.base_value > 0:
				player.add_block(card.base_value)
				show_damage_number(player, card.base_value, "block")
			if card.secondary_value > 0:
				draw_cards(card.secondary_value)
			if card.keywords.size() > 0:
				var stacks = card.secondary_value if card.secondary_value > 0 else 1
				for keyword in card.keywords:
					if keyword in ["weak", "vulnerable", "stun", "bleed"]:
						if enemy:
							enemy.add_status(keyword, stacks)
					else:
						player.add_status(keyword, stacks)
		CardData.CardType.POWER:
			# 内功现在装备到经脉
			player.equip_meridian(card)
			if meridian_container and meridian_container.has_method("update_slots"):
				meridian_container.update_slots(player.meridians)
	
	if card.type != CardData.CardType.ATTACK and card.momentum_gain != 0:
		add_momentum(card.momentum_gain)

func trigger_player_meridians() -> void:
	print("触发经脉效果...")
	for card in player.meridians:
		_apply_meridian_effect(card)

func _apply_meridian_effect(card: CardData) -> void:
	# 简单的被动效果逻辑
	if card.keywords.has("retain_block"):
		player.add_block(card.base_value)
		show_damage_number(player, card.base_value, "block")
	elif card.keywords.has("strength"):
		# 力量可能需要是永久的，这里简单处理为每回合加力量? 
		# 或者内功本身就是"力量+X"，这里每回合都加会太强。
		# 假设内功是"回合开始时获得X力量"
		player.add_status("strength", card.base_value)
	else:
		# 默认：如果base_value > 0且是Power，视为获得护体（如果没有特定keywords）
		if card.base_value > 0:
			player.add_block(card.base_value)
			show_damage_number(player, card.base_value, "block")

func end_player_turn() -> void:
	print("\n玩家结束回合")
	
	# 触发经脉效果
	trigger_player_meridians()
	
	# 弃牌逻辑：如果手牌超过8张，丢弃多余的（最左侧/最早抽到的）
	while hand.size() > 8:
		var card_to_discard = hand.pop_front()
		print("手牌上限溢出，丢弃: %s" % card_to_discard.card_name)
		_discard_card(card_to_discard)
		if hand_manager:
			hand_manager.remove_card(card_to_discard)
	
	# 注意：不再清空所有手牌，保留剩余手牌
	
	# 护体保留到敌人回合，不在此处清除
	# player.clear_block()
	
	change_state(BattleState.ENEMY_TURN)
	await get_tree().create_timer(0.5).timeout
	start_enemy_turn()

func start_enemy_turn() -> void:
	print("\n--- 敌人回合 ---")
	
	# 敌人回合开始时清除敌人的护体
	enemy.clear_block()
	
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
	# enemy.clear_block() # 移到回合开始
	enemy.clear_breach()
	change_state(BattleState.PLAYER_TURN)
	start_player_turn()

func _on_player_died() -> void:
	change_state(BattleState.DEFEAT)
	print("\n=== 战斗失败 ===")
	battle_ended.emit(false)

func _on_enemy_died() -> void:
	change_state(BattleState.VICTORY)
	print("\n=== 战斗胜利 ===")
	RunManager.update_player_state(player.current_hp)
	battle_ended.emit(true)

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

func _on_fusion_requested(card_a: CardData, card_b: CardData) -> void:
	if not hand.has(card_a) or not hand.has(card_b):
		return
	if hand_manager:
		hand_manager.remove_card(card_a)
		hand_manager.remove_card(card_b)
	hand.erase(card_a)
	hand.erase(card_b)
	var fused = _create_fused_card(card_a, card_b)
	hand.append(fused)
	if hand_manager:
		hand_manager.add_card(fused)

func _create_fused_card(card_a: CardData, card_b: CardData) -> CardData:
	var fused = CardData.new()
	var same_name = card_a.card_name == card_b.card_name
	var base_name = card_a.card_name if same_name else "%s+%s" % [card_a.card_name, card_b.card_name]
	fused.id = "fused_%s_%s" % [card_a.id, card_b.id]
	if base_name == "长拳":
		fused.card_name = "连环长拳"
	else:
		fused.card_name = "%s·合" % base_name
	fused.type = card_a.type
	fused.cost = card_a.cost + card_b.cost
	fused.base_value = card_a.base_value + card_b.base_value
	fused.secondary_value = card_a.secondary_value + card_b.secondary_value
	fused.momentum_gain = card_a.momentum_gain + card_b.momentum_gain
	fused.breach_apply = card_a.breach_apply + card_b.breach_apply
	fused.is_exhaust = card_a.is_exhaust or card_b.is_exhaust
	fused.is_ethereal = card_a.is_ethereal or card_b.is_ethereal
	fused.fused_from_cards = [card_a, card_b]
	match fused.type:
		CardData.CardType.ATTACK:
			fused.description = "融合技：造成 %d 点伤害" % fused.base_value
		CardData.CardType.SKILL:
			fused.description = "融合技：获得 %d 护体" % fused.base_value
		CardData.CardType.POWER:
			fused.description = "融合技：强化效果"
	return fused

func _discard_card(card: CardData) -> void:
	if card.fused_from_cards.size() > 0:
		for base_card in card.fused_from_cards:
			discard_pile.append(base_card)
	else:
		discard_pile.append(card)

func add_momentum(amount: int) -> void:
	if amount <= 0:
		return
	player_momentum += amount
	momentum_changed.emit(player_momentum)
