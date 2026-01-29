extends Control
## 主菜单界面脚本

func _ready() -> void:
	# 连接开始游戏按钮的点击信号
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed() -> void:
	# TODO: 切换到游戏场景
	print("开始游戏!")
	# 示例：GameManager.change_scene("res://scenes/levels/level_1.tscn")
