extends PanelContainer
class_name MeridianSlot

@onready var icon_rect = $MarginContainer/IconRect
@onready var tooltip_label = $Tooltip/Label
@onready var tooltip_panel = $Tooltip

var card_data: CardData = null

func _ready() -> void:
	tooltip_panel.visible = false
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_card(card: CardData) -> void:
	card_data = card
	if card:
		# 这里假设 CardData 有 icon，如果没有则显示颜色块或文字
		if card.icon:
			icon_rect.texture = card.icon
			icon_rect.modulate = Color.WHITE
		else:
			# 简单的占位符颜色
			icon_rect.texture = null
			icon_rect.modulate = Color(0.6, 0.2, 0.9) # 紫色代表内功
		
		tooltip_label.text = "%s\n%s" % [card.card_name, card.description]
	else:
		icon_rect.texture = null
		icon_rect.modulate = Color.TRANSPARENT
		tooltip_label.text = "空经脉槽"

func _on_mouse_entered() -> void:
	if card_data:
		tooltip_panel.visible = true

func _on_mouse_exited() -> void:
	tooltip_panel.visible = false
