extends PanelContainer
class_name StatusIcon

@onready var icon_rect = $MarginContainer/IconRect
@onready var stack_label = $StackLabel

func setup(status_name: String, stacks: int) -> void:
	stack_label.text = str(stacks)
	tooltip_text = _get_status_tooltip(status_name, stacks)
	
	# 设置颜色和图标
	var color = _get_status_color(status_name)
	icon_rect.modulate = color
	
	# 这里使用一个简单的白色圆形或方形作为基础图标，通过颜色区分
	# 实际项目中应使用 specific icons
	if not icon_rect.texture:
		var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		icon_rect.texture = ImageTexture.create_from_image(image)

func _get_status_color(status_name: String) -> Color:
	match status_name:
		"vulnerable": return Color(0.9, 0.2, 0.2) # 红色
		"weak": return Color(0.7, 0.2, 0.9) # 紫色
		"breach": return Color(0.5, 0.0, 0.0) # 暗红
		"strength": return Color(0.9, 0.5, 0.1) # 橙色
		"retain_block": return Color(0.2, 0.6, 0.9) # 蓝色
		_: return Color(0.5, 0.5, 0.5) # 灰色

func _get_status_tooltip(status_name: String, stacks: int) -> String:
	match status_name:
		"vulnerable": return "内伤: 受到伤害增加 50%"
		"weak": return "虚弱: 造成伤害减少 25%"
		"breach": return "破绽: 每层受到伤害增加 10%"
		"strength": return "力量: 攻击伤害增加 %d" % stacks
		"retain_block": return "固守: 回合结束时不失去护体"
		_: return "%s: %d 层" % [status_name, stacks]
