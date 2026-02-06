extends Resource
class_name EventDefinition

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var image: Texture2D

# 选项配置: Array[Dictionary]
# { "text": "描述", "tooltip": "后果提示 (可选)", "condition": "check_func_name (可选)" }
@export var options: Array[Dictionary] = []

# 虚函数：执行选项效果
# 返回值：是否关闭事件窗口 (true=离开, false=更新文本继续)
func execute_option(option_idx: int) -> bool:
	return true

# 虚函数：获取选项是否可用 (可选)
func is_option_available(option_idx: int) -> bool:
	return true
