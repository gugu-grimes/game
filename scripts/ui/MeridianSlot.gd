extends PanelContainer
class_name MeridianSlot

@onready var icon_rect = $MarginContainer/IconRect
@onready var tooltip_label = $Tooltip/Label
@onready var tooltip_panel = $Tooltip

var card_data: CardData = null
var placeholder_texture: ImageTexture

func _ready() -> void:
	tooltip_panel.visible = false
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 创建一个 1x1 的白色纹理用于显示色块
	var image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	placeholder_texture = ImageTexture.create_from_image(image)

func set_card(card: CardData) -> void:
	card_data = card
	if card:
		# 使用色块代替图标
		icon_rect.texture = placeholder_texture
		icon_rect.modulate = _get_meridian_color(card)
		
		tooltip_label.text = "%s\n%s" % [card.card_name, card.description]
	else:
		icon_rect.texture = null
		icon_rect.modulate = Color.TRANSPARENT
		tooltip_label.text = "空经脉槽"

func _get_meridian_color(card: CardData) -> Color:
	# 根据关键词决定颜色
	if card.keywords.has("strength") or card.keywords.has("damage"):
		return Color(0.9, 0.3, 0.3) # 红色 - 攻击型
	elif card.keywords.has("retain_block") or card.keywords.has("block"):
		return Color(0.3, 0.6, 0.9) # 蓝色 - 防御型
	else:
		return Color(0.6, 0.3, 0.9) # 紫色 - 辅助型

func _on_mouse_entered() -> void:
	if card_data:
		tooltip_panel.visible = true

func _on_mouse_exited() -> void:
	tooltip_panel.visible = false
