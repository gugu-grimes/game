extends Control
class_name CardUI

var card_data: CardData

@onready var card_bg: Panel = $CardBackground
@onready var border_color: ColorRect = $CardBackground/Border
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var desc_label: Label = $VBoxContainer/DescLabel
@onready var cost_label: Label = $CostCircle/CostLabel
@onready var icon_rect: TextureRect = $VBoxContainer/IconRect
@onready var icon_placeholder: ColorRect = $VBoxContainer/IconRect/IconPlaceholder

var is_hovered: bool = false
var is_dragging: bool = false
var original_position: Vector2

signal card_played(card: CardData)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# 确保在 ready 后更新显示
	if card_data:
		call_deferred("update_display")

func set_card_data(data: CardData) -> void:
	card_data = data
	# 如果节点还未准备好，等待 ready 后更新
	if is_inside_tree() and name_label:
		update_display()

func update_display() -> void:
	if not card_data:
		return
	
	# 检查节点是否存在
	if not name_label or not desc_label or not cost_label:
		push_warning("CardUI 节点未准备好，跳过更新")
		return
	
	name_label.text = card_data.card_name
	desc_label.text = card_data.description
	cost_label.text = str(card_data.cost)
	if card_data.icon:
		icon_rect.texture = card_data.icon
		if icon_placeholder:
			icon_placeholder.visible = false
	
	# 根据卡牌类型设置边框颜色
	var type_color: Color
	match card_data.type:
		CardData.CardType.ATTACK:
			type_color = Color(0.9, 0.2, 0.2) # 红色 - 招式
		CardData.CardType.SKILL:
			type_color = Color(0.2, 0.7, 0.3) # 绿色 - 身法
		CardData.CardType.POWER:
			type_color = Color(0.6, 0.2, 0.9) # 紫色 - 内功
		_:
			type_color = Color(0.5, 0.5, 0.5)
	
	if border_color:
		border_color.color = type_color
	if icon_placeholder:
		icon_placeholder.color = type_color.darkened(0.5)

func _on_mouse_entered() -> void:
	is_hovered = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)

func _on_mouse_exited() -> void:
	is_hovered = false
	if not is_dragging:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				original_position = global_position
			else:
				if is_dragging:
					is_dragging = false
					if global_position.y < original_position.y - 100:
						print("尝试打出卡牌: %s" % card_data.card_name)
						card_played.emit(card_data)
					else:
						global_position = original_position
					scale = Vector2(1.0, 1.0)
	elif event is InputEventMouseMotion and is_dragging:
		global_position += event.relative
