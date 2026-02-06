extends Control
class_name EventScene

signal event_completed

@onready var title_label = $VBoxContainer/TitleLabel
@onready var image_rect = $VBoxContainer/ImageRect
@onready var desc_label = $VBoxContainer/DescLabel
@onready var options_container = $VBoxContainer/OptionsContainer

var current_event

func _ready() -> void:
	pass

func setup_event(event: EventDefinition) -> void:
	current_event = event.duplicate() # 复制一份以免修改资源
	_update_ui()

func _update_ui() -> void:
	if not current_event: return
	
	title_label.text = current_event.title
	desc_label.text = current_event.description
	
	if current_event.image:
		image_rect.texture = current_event.image
		image_rect.visible = true
	else:
		image_rect.visible = false
	
	# 生成选项按钮
	for child in options_container.get_children():
		child.queue_free()
	
	for i in range(current_event.options.size()):
		var opt = current_event.options[i]
		var btn = Button.new()
		btn.text = opt.text
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# 检查可用性
		if current_event.has_method("is_option_available"):
			if not current_event.is_option_available(i):
				btn.disabled = true
				btn.text += " (不可用)"
		
		if opt.has("tooltip"):
			btn.tooltip_text = opt.tooltip
		
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(btn)

func _on_option_pressed(idx: int) -> void:
	if current_event.execute_option(idx):
		# 如果返回 true，说明事件结束
		event_completed.emit()
	else:
		# 如果返回 false，说明需要刷新 UI (例如进入多阶段事件)
		_update_ui()
