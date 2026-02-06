extends Control
class_name ShopScene

signal shop_exited

@onready var gold_label = $TopBar/GoldLabel
@onready var cards_container = $ScrollContainer/HBoxContainer/CardsContainer
@onready var services_container = $ScrollContainer/HBoxContainer/ServicesContainer
@onready var exit_button = $TopBar/ExitButton

var items_for_sale: Array = [] # { "type": "card/service", "data": ..., "price": int, "btn": Button }

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	update_gold_ui()
	generate_shop_items()

func update_gold_ui() -> void:
	gold_label.text = "金钱: %d" % RunManager.gold

func generate_shop_items() -> void:
	# 清空旧内容
	for child in cards_container.get_children():
		child.queue_free()
	for child in services_container.get_children():
		child.queue_free()
	items_for_sale.clear()
	
	# 生成卡牌商品 (3-5张)
	for i in range(4):
		var card = CardFactory.create_random_reward_card()
		var price = randi_range(40, 80)
		_add_card_item(card, price)
	
	# 生成服务 (移除卡牌)
	_add_service_item("移除卡牌", "选择一张卡牌移除", 75, "remove_card")

func _add_card_item(card: CardData, price: int) -> void:
	var btn = Button.new()
	btn.text = "%s\n%s\n\n价格: %d" % [card.card_name, card.description, price]
	btn.custom_minimum_size = Vector2(150, 220)
	btn.pressed.connect(_on_buy_card.bind(card, price, btn))
	cards_container.add_child(btn)
	
	items_for_sale.append({
		"type": "card",
		"data": card,
		"price": price,
		"btn": btn
	})

func _add_service_item(title: String, desc: String, price: int, service_id: String) -> void:
	var btn = Button.new()
	btn.text = "%s\n%s\n\n价格: %d" % [title, desc, price]
	btn.custom_minimum_size = Vector2(150, 220)
	btn.pressed.connect(_on_buy_service.bind(service_id, price, btn))
	services_container.add_child(btn)

func _on_buy_card(card: CardData, price: int, btn: Button) -> void:
	if RunManager.gold >= price:
		RunManager.gold -= price
		RunManager.add_card_to_deck(card)
		update_gold_ui()
		btn.disabled = true
		btn.text = "已购买"
	else:
		# 简单的反馈，实际可以用Toast
		var old_text = btn.text
		btn.text = "金钱不足!"
		await get_tree().create_timer(1.0).timeout
		btn.text = old_text

func _on_buy_service(service_id: String, price: int, btn: Button) -> void:
	if RunManager.gold >= price:
		if service_id == "remove_card":
			# 这里应该打开牌组界面选择，简化为随机移除一张打击/格挡
			if _try_remove_basic_card():
				RunManager.gold -= price
				update_gold_ui()
				btn.disabled = true
				btn.text = "已购买"
			else:
				btn.text = "无牌可删!"
				await get_tree().create_timer(1.0).timeout
				btn.text = "%s\n选择一张卡牌移除\n\n价格: %d" % ["移除卡牌", price]
	else:
		var old_text = btn.text
		btn.text = "金钱不足!"
		await get_tree().create_timer(1.0).timeout
		btn.text = old_text

func _try_remove_basic_card() -> bool:
	# 临时逻辑：随机移除基础牌
	for i in range(RunManager.current_deck.size() - 1, -1, -1):
		var card = RunManager.current_deck[i]
		if card.card_name == "长拳" or card.card_name == "格挡":
			RunManager.remove_card_from_deck(card.id)
			return true
	return false

func _on_exit_pressed() -> void:
	shop_exited.emit()
