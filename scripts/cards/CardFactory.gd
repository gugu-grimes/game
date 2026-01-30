extends Node

## 创建初始卡组的工厂脚本
class_name CardFactory

static func create_starter_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# 1. 长拳 x4 - 基础攻击
	for i in range(4):
		var card = CardData.new()
		card.id = "strike_%d" % i
		card.card_name = "长拳"
		card.description = "造成 6 点伤害"
		card.cost = 1
		card.type = CardData.CardType.ATTACK
		card.base_value = 6
		deck.append(card)
	
	# 2. 格挡 x4 - 基础防御
	for i in range(4):
		var card = CardData.new()
		card.id = "defend_%d" % i
		card.card_name = "格挡"
		card.description = "获得 5 点护体"
		card.cost = 1
		card.type = CardData.CardType.SKILL
		card.base_value = 5
		deck.append(card)
	
	# 3. 气沉丹田 x1 - 抽牌+能量
	var qi_card = CardData.new()
	qi_card.id = "qi_focus"
	qi_card.card_name = "气沉丹田"
	qi_card.description = "抽 2 张牌"
	qi_card.cost = 1
	qi_card.type = CardData.CardType.SKILL
	qi_card.base_value = 0
	qi_card.secondary_value = 2 # 抽牌数
	deck.append(qi_card)
	
	# 4. 突刺 x1 - 强力攻击
	var thrust = CardData.new()
	thrust.id = "thrust"
	thrust.card_name = "突刺"
	thrust.description = "造成 9 点伤害，施加 1 层内伤"
	thrust.cost = 2
	thrust.type = CardData.CardType.ATTACK
	thrust.base_value = 9
	thrust.keywords = PackedStringArray(["vulnerable"])
	deck.append(thrust)
	
	return deck

## 创建测试敌人
static func create_test_enemy() -> EnemyData:
	var enemy = EnemyData.new()
	enemy.enemy_name = "山贼头目"
	enemy.max_hp = 50
	
	# 定义行动模式
	enemy.add_move(EnemyData.IntentType.ATTACK, 8, 0, 3) # 70%攻击
	enemy.add_move(EnemyData.IntentType.DEFEND, 0, 6, 2) # 30%防御
	
	return enemy
