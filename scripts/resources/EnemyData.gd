extends Resource
class_name EnemyData

## 敌人意图类型
enum IntentType {
	ATTACK, ## 攻击
	DEFEND, ## 防御
	BUFF, ## 强化自身
	DEBUFF, ## 削弱玩家
	SPECIAL ## 特殊技能
}

## 单个行动模式
class MovePattern:
	var intent: IntentType
	var damage: int = 0
	var block: int = 0
	var status_effect: String = ""
	var status_stacks: int = 0
	var weight: int = 1 ## 权重，用于随机选择
	
	func _init(_intent: IntentType, _damage: int = 0, _block: int = 0):
		intent = _intent
		damage = _damage
		block = _block

## 基础属性
@export var enemy_name: String = ""
@export var max_hp: int = 50
@export var sprite: Texture2D

## 行动模式（在运行时构建，暂时用脚本定义）
var moveset: Array[MovePattern] = []

func add_move(intent: IntentType, damage: int = 0, block: int = 0, weight: int = 1) -> void:
	var move = MovePattern.new(intent, damage, block)
	move.weight = weight
	moveset.append(move)

## 随机选择一个行动
func get_random_move() -> MovePattern:
	if moveset.is_empty():
		push_warning("敌人 %s 没有定义行动模式！" % enemy_name)
		return MovePattern.new(IntentType.ATTACK, 5)
	
	var total_weight = 0
	for move in moveset:
		total_weight += move.weight
	
	var rand_value = randi() % total_weight
	var cumulative = 0
	
	for move in moveset:
		cumulative += move.weight
		if rand_value < cumulative:
			return move
	
	return moveset[0]
