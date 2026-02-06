extends Control
class_name MapScene

@onready var scroll_container = $ScrollContainer
@onready var map_container = $ScrollContainer/MapContainer

const NODE_SPACING_X = 100
const NODE_SPACING_Y = 150

const MapNodeData = preload("res://scripts/resources/MapNodeData.gd")
const MapGenerator = preload("res://scripts/core/MapGenerator.gd")

var map_data: Array = [] # Array[Array[MapNodeData]]
var node_buttons: Dictionary = {} # {Vector2i: Button}

signal node_selected(node: Resource)

func _ready() -> void:
	pass

func setup_map(data: Array) -> void:
	map_data = data
	_draw_map()
	_update_node_states()

func _draw_map() -> void:
	# 清理旧节点
	for child in map_container.get_children():
		child.queue_free()
	node_buttons.clear()
	
	# 设置容器最小尺寸
	var max_width = MapGenerator.NODES_PER_FLOOR_MAX * NODE_SPACING_X
	var total_height = map_data.size() * NODE_SPACING_Y
	map_container.custom_minimum_size = Vector2(max_width, total_height)
	
	# 绘制节点
	for floor_idx in range(map_data.size()):
		var layer = map_data[floor_idx]
		var layer_y = total_height - (floor_idx * NODE_SPACING_Y) - 100 # 从下往上画
		
		var layer_width = layer.size() * NODE_SPACING_X
		var start_x = (map_container.size.x - layer_width) / 2.0
		
		for i in range(layer.size()):
			var node_data = layer[i]
			var btn = Button.new()
			btn.text = _get_node_icon(node_data.type)
			btn.custom_minimum_size = Vector2(50, 50)
			btn.position = Vector2(start_x + i * NODE_SPACING_X, layer_y)
			
			btn.pressed.connect(_on_node_pressed.bind(node_data))
			
			map_container.add_child(btn)
			node_buttons[node_data.position_grid] = btn
			
			# 绘制连线（简单实现，用 Line2D 或者 draw_line）
			# 这里因为 Button 是 Control，最好用独立的 Control 层来画线
			# 暂时略过连线绘制，先做功能
	
	# 简单的连线绘制（作为背景子节点）
	var lines_layer = Control.new()
	lines_layer.name = "Lines"
	lines_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_container.add_child(lines_layer)
	map_container.move_child(lines_layer, 0) # 放到最底层
	
	lines_layer.script = preload("res://scripts/ui/MapLines.gd") # 需要创建一个画线脚本
	lines_layer.call("setup", map_data, node_buttons)

func _get_node_icon(type: int) -> String: # MapNodeData.NodeType
	match type:
		MapNodeData.NodeType.ENEMY: return "⚔️"
		MapNodeData.NodeType.ELITE: return "💀"
		MapNodeData.NodeType.REST: return "🔥"
		MapNodeData.NodeType.EVENT: return "❓"
		MapNodeData.NodeType.SHOP: return "💰"
		MapNodeData.NodeType.BOSS: return "👹"
	return "O"

func _update_node_states() -> void:
	var current_pos = RunManager.map_state.current_node_pos if RunManager.map_state else Vector2i(-1, -1)
	
	for floor_idx in range(map_data.size()):
		var layer = map_data[floor_idx]
		for node in layer:
			var btn = node_buttons.get(node.position_grid)
			if not btn: continue
			
			# 状态判断逻辑
			if node.visited:
				btn.modulate = Color(0.5, 0.5, 0.5) # 已访问变灰
				btn.disabled = true
			elif _is_node_reachable(node, current_pos):
				btn.modulate = Color(1, 1, 1) # 可访问高亮
				btn.disabled = false
				
				# 简单的呼吸动画效果
				var tween = create_tween().set_loops()
				tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.5)
				tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.5)
			else:
				btn.modulate = Color(1, 1, 1, 0.3) # 不可访问半透明
				btn.disabled = true

func _is_node_reachable(target_node: Resource, current_pos: Vector2i) -> bool:
	# 如果还没有开始（current_pos 为 -1,-1），第一层所有节点都可达
	if current_pos == Vector2i(-1, -1):
		return target_node.position_grid.x == 0
	
	# 检查当前位置是否连接到目标节点
	# 注意：RunManager 需要保存当前节点信息
	# 这里简化：我们需要遍历上一层，找到 current_pos 对应的节点，看它的 connections 是否包含 target
	if target_node.position_grid.x != current_pos.x + 1:
		return false
	
	# 获取上一层的当前节点
	var prev_layer = map_data[current_pos.x]
	# 找到对应的节点对象（这里假设索引对应，实际上可能需要遍历）
	var current_node_data = null
	for n in prev_layer:
		if n.position_grid == current_pos:
			current_node_data = n
			break
	
	if current_node_data:
		return current_node_data.connections.has(target_node.position_grid)
	
	return false

func _on_node_pressed(node: Resource) -> void:
	node_selected.emit(node)
