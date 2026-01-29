extends Node
## 游戏全局管理器
## 用于管理游戏状态和场景切换

## 切换场景
func change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

## 退出游戏
func quit_game() -> void:
	get_tree().quit()
