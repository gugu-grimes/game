extends Control

signal continue_pressed

@onready var card_container = $VBoxContainer/HBoxContainer
@onready var continue_button = $VBoxContainer/ContinueButton

func _ready() -> void:
	generate_rewards()
	continue_button.disabled = true
	continue_button.pressed.connect(_on_continue_pressed)

func generate_rewards() -> void:
	for child in card_container.get_children():
		child.queue_free()
	
	for i in range(3):
		var card_data = CardFactory.create_random_reward_card()
		var btn = Button.new()
		btn.text = "%s\n\n%s" % [card_data.card_name, card_data.description]
		btn.custom_minimum_size = Vector2(150, 200)
		btn.pressed.connect(_on_card_selected.bind(card_data, btn))
		card_container.add_child(btn)

func _on_card_selected(card: CardData, btn: Button) -> void:
	print("选择了卡牌: %s" % card.card_name)
	RunManager.add_card_to_deck(card)
	
	# 禁用所有按钮，高亮选中的
	for child in card_container.get_children():
		child.disabled = true
		child.modulate = Color.GRAY
	
	btn.modulate = Color.GREEN
	btn.disabled = true # 既然已经选中，也不能再点了，或者可以允许取消？这里简化为不可撤销
	
	continue_button.disabled = false

func _on_continue_pressed() -> void:
	continue_pressed.emit()
