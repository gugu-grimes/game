extends Resource
class_name CardData

## 卡牌类型枚举
enum CardType {
	ATTACK, ## 招式 - 造成伤害
	SKILL, ## 身法 - 提供护体、辅助效果
	POWER ## 内功 - 持续性被动效果
}

## 基础属性
@export var id: String = ""
@export var card_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 1
@export var type: CardType = CardType.ATTACK
@export var icon: Texture2D

## 效果数值（根据卡牌类型解释不同）
@export var base_value: int = 0 ## 攻击伤害、护体值、或内功层数
@export var secondary_value: int = 0 ## 如：额外抽牌数、附加状态层数

## 关键词标记
@export var is_exhaust: bool = false ## 打出后移出战斗
@export var is_ethereal: bool = false ## 回合结束时消失
@export var keywords: PackedStringArray = [] ## 如 ["连招", "闪避"]

## 卡牌效果脚本引用（可选，用于复杂效果）
@export var effect_script_path: String = ""

func _to_string() -> String:
	return "[%s] %s (Cost: %d)" % [CardType.keys()[type], card_name, cost]
