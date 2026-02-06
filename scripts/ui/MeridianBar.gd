extends HBoxContainer
class_name MeridianBar

@export var slot_scene: PackedScene
@onready var slots: Array = []

func _ready() -> void:
	# 初始化3个槽位
	for i in range(3):
		var slot = slot_scene.instantiate()
		add_child(slot)
		slots.append(slot)
		slot.set_card(null)

func update_slots(meridians: Array[CardData]) -> void:
	for i in range(3):
		if i < meridians.size():
			slots[i].set_card(meridians[i])
		else:
			slots[i].set_card(null)
