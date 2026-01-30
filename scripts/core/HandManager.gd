extends Node
class_name HandManager

## 配置
@export var hand_container: Control # 手牌容器（改用Control以支持自定义布局）
@export var card_ui_scene: PackedScene

## 弧形布局参数
@export var arc_height: float = 30.0 # 弧形高度
@export var arc_width: float = 800.0 # 弧形宽度
@export var card_rotation_max: float = 15.0 # 最大旋转角度
@export var hover_lift: float = 50.0 # 悬停时上移距离

## 手牌数据
var hand_cards: Array[CardUI] = []
var hovered_card: CardUI = null

signal card_played(card: CardData)

func _ready() -> void:
	pass

## 添加卡牌到手牌
func add_card(card_data: CardData) -> void:
	if not card_ui_scene or not hand_container:
		push_error("HandManager 未正确配置！")
		return
	
	# 实例化卡牌UI
	var card_ui: CardUI = card_ui_scene.instantiate()
	card_ui.set_card_data(card_data)
	card_ui.card_played.connect(_on_card_played)
	
	# 连接悬停信号
	card_ui.mouse_entered.connect(_on_card_hover_enter.bind(card_ui))
	card_ui.mouse_exited.connect(_on_card_hover_exit.bind(card_ui))
	
	hand_container.add_child(card_ui)
	hand_cards.append(card_ui)
	
	# 更新手牌布局
	update_hand_layout()

## 清空手牌
func clear_hand() -> void:
	for card in hand_cards:
		if is_instance_valid(card):
			card.queue_free()
	hand_cards.clear()
	hovered_card = null

## 移除指定卡牌
func remove_card(card_data: CardData) -> void:
	for card_ui in hand_cards:
		if is_instance_valid(card_ui) and card_ui.card_data == card_data:
			hand_cards.erase(card_ui)
			card_ui.queue_free()
			break
	
	# 更新布局
	update_hand_layout()

## 更新手牌弧形布局
func update_hand_layout() -> void:
	var card_count = hand_cards.size()
	if card_count == 0:
		return
	
	var container_width = hand_container.size.x if hand_container else arc_width
	var container_height = hand_container.size.y if hand_container else 200.0
	var center_x = container_width / 2.0
	var center_y = container_height / 2.0
	
	# 计算卡牌间距
	var total_width = min(card_count * 160, container_width - 100)
	var card_spacing = total_width / max(card_count, 1)
	var start_x = center_x - total_width / 2.0
	
	for i in range(card_count):
		var card = hand_cards[i]
		if not is_instance_valid(card):
			continue
		
		# 计算卡牌位置
		var t = float(i) / max(card_count - 1, 1) if card_count > 1 else 0.5
		var x = start_x + i * card_spacing
		
		# 弧形 Y 偏移（中间高两边低）
		var arc_offset = - arc_height * (1.0 - pow(2.0 * t - 1.0, 2))
		var y = center_y + arc_offset
		
		# 旋转角度（中间直立两边倾斜）
		var rotation_deg = card_rotation_max * (2.0 * t - 1.0)
		
		# 如果是悬停的卡牌，不改变它的位置
		if card == hovered_card:
			continue
		
		# 应用位置和旋转
		var tween = card.create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "position", Vector2(x, y), 0.15)
		tween.tween_property(card, "rotation_degrees", rotation_deg, 0.15)
		
		# 设置绘制顺序
		card.z_index = i

func _on_card_hover_enter(card: CardUI) -> void:
	hovered_card = card
	
	# 悬停时上移并放大
	var tween = card.create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position:y", card.position.y - hover_lift, 0.1)
	tween.tween_property(card, "rotation_degrees", 0.0, 0.1)
	tween.tween_property(card, "scale", Vector2(1.2, 1.2), 0.1)
	
	# 提升到最前
	card.z_index = 100

func _on_card_hover_exit(card: CardUI) -> void:
	if hovered_card == card:
		hovered_card = null
	
	# 恢复原位
	if not card.is_dragging:
		var tween = card.create_tween()
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
		update_hand_layout()

func _on_card_played(card: CardData) -> void:
	card_played.emit(card)
