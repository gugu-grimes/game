extends Control
class_name DamageNumber

@onready var label: Label = $Label

func _ready() -> void:
	# 播放飞字动画
	play_animation()

func setup(value: int, damage_type: String = "damage") -> void:
	match damage_type:
		"damage":
			label.text = "-%d" % value
			label.modulate = Color(1, 0.3, 0.3) # 红色
		"heal":
			label.text = "+%d" % value
			label.modulate = Color(0.3, 1, 0.3) # 绿色
		"block":
			label.text = "+%d" % value
			label.modulate = Color(0.4, 0.7, 1) # 蓝色

func play_animation() -> void:
	# 向上飘动并淡出
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 80, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
