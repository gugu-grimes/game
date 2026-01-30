extends Node2D
class_name CharacterBase

## 信号
signal hp_changed(new_hp: int, max_hp: int)
signal block_changed(new_block: int)
signal died()

## 属性
@export var max_hp: int = 100
var current_hp: int = 100
var block: int = 0

## 状态效果（Buff/Debuff）
var status_effects: Dictionary = {} # {status_name: stacks}

func _ready() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)

## 受到伤害
func take_damage(amount: int) -> void:
	# 先扣除护体
	var actual_damage = amount
	if block > 0:
		if block >= amount:
			block -= amount
			actual_damage = 0
		else:
			actual_damage -= block
			block = 0
		block_changed.emit(block)
	
	# 检查"内伤"状态（Vulnerable，受伤增加50%）
	if status_effects.has("vulnerable"):
		actual_damage = int(actual_damage * 1.5)
	
	# 扣血
	if actual_damage > 0:
		current_hp = max(0, current_hp - actual_damage)
		hp_changed.emit(current_hp, max_hp)
		print("%s 受到 %d 点伤害！剩余血量: %d/%d" % [name, actual_damage, current_hp, max_hp])
		
		if current_hp <= 0:
			die()

## 增加护体
func add_block(amount: int) -> void:
	block += amount
	block_changed.emit(block)
	print("%s 获得 %d 点护体，当前: %d" % [name, amount, block])

## 治疗
func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)
	print("%s 恢复 %d 点生命，当前: %d/%d" % [name, amount, current_hp, max_hp])

## 添加状态效果
func add_status(status_name: String, stacks: int) -> void:
	if status_effects.has(status_name):
		status_effects[status_name] += stacks
	else:
		status_effects[status_name] = stacks
	print("%s 获得 %d 层 %s" % [name, stacks, status_name])

## 清除护体（回合结束调用，除非有特殊能力）
func clear_block() -> void:
	if not status_effects.has("retain_block"):
		block = 0
		block_changed.emit(block)

## 死亡
func die() -> void:
	print("%s 已死亡" % name)
	died.emit()
