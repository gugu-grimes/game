extends Node
class_name MapGenerator

const FLOORS = 15
const NODES_PER_FLOOR_MIN = 3
const NODES_PER_FLOOR_MAX = 5
const PATH_CONNECTIVITY = 0.4 # 路径分叉概率

const MapNodeData = preload("res://scripts/resources/MapNodeData.gd")

# 生成地图数据：返回一个二维数组，每层包含若干 MapNodeData
static func generate_map() -> Array: # Array[Array[MapNodeData]]
	var map_grid: Array = []
	
	# 1. 生成第一层（起始点）
	var first_layer = []
	var start_nodes_count = randi_range(NODES_PER_FLOOR_MIN, NODES_PER_FLOOR_MAX)
	for i in range(start_nodes_count):
		var node = MapNodeData.new(MapNodeData.NodeType.ENEMY, Vector2i(0, i))
		node.available = true # 第一层默认可选
		first_layer.append(node)
	map_grid.append(first_layer)
	
	# 2. 生成中间层
	for floor_idx in range(1, FLOORS - 1):
		var layer = []
		var nodes_count = randi_range(NODES_PER_FLOOR_MIN, NODES_PER_FLOOR_MAX)
		
		for i in range(nodes_count):
			# 随机确定类型
			var type = _get_random_node_type(floor_idx)
			var node = MapNodeData.new(type, Vector2i(floor_idx, i))
			layer.append(node)
		
		map_grid.append(layer)
	
	# 3. 生成最后一层（BOSS）
	var boss_node = MapNodeData.new(MapNodeData.NodeType.BOSS, Vector2i(FLOORS - 1, 0))
	map_grid.append([boss_node])
	
	# 4. 生成连接（核心逻辑：保证每层每个节点至少有一个父节点和一个子节点，除了首尾）
	_generate_connections(map_grid)
	
	return map_grid

static func _get_random_node_type(floor: int) -> int: # MapNodeData.NodeType
	# 简单权重配置
	var roll = randf()
	if floor == 0: return MapNodeData.NodeType.ENEMY
	if floor % 5 == 0: return MapNodeData.NodeType.ELITE # 暂时简单处理
	if floor == FLOORS - 2: return MapNodeData.NodeType.REST # BOSS前休息
	
	if roll < 0.45: return MapNodeData.NodeType.ENEMY
	if roll < 0.65: return MapNodeData.NodeType.EVENT
	if roll < 0.80: return MapNodeData.NodeType.REST
	if roll < 0.90: return MapNodeData.NodeType.SHOP
	return MapNodeData.NodeType.ELITE

static func _generate_connections(map: Array) -> void:
	for floor_idx in range(map.size() - 1):
		var current_layer = map[floor_idx]
		var next_layer = map[floor_idx + 1]
		
		# 确保下一层每个节点至少被连接一次
		var next_layer_connected_indices = {}
		
		# 遍历当前层，尝试向前连接
		for i in range(current_layer.size()):
			var node = current_layer[i]
			
			# 尝试连接到下一层的相邻节点（直走、左斜、右斜）
			# 为了简化视觉，假设下一层节点索引范围类似
			# 实际算法可能需要归一化坐标，这里采用简化版：连接到 index 相似的节点
			
			var center_target = float(i) / current_layer.size() * next_layer.size()
			var target_start = floor(center_target)
			var target_end = target_start + 1
			
			# 至少连接一个
			var primary_target = int(target_start) if randf() < 0.5 else int(target_end)
			primary_target = clamp(primary_target, 0, next_layer.size() - 1)
			
			_connect_nodes(node, next_layer[primary_target])
			next_layer_connected_indices[primary_target] = true
			
			# 随机额外连接
			if randf() < PATH_CONNECTIVITY:
				var extra_target = primary_target + (1 if randf() < 0.5 else -1)
				if extra_target >= 0 and extra_target < next_layer.size():
					_connect_nodes(node, next_layer[extra_target])
					next_layer_connected_indices[extra_target] = true
		
		# 修正：确保下一层所有节点都被连接（如果有孤儿节点，强制从上一层最近的节点连过来）
		for j in range(next_layer.size()):
			if not next_layer_connected_indices.has(j):
				# 找上一层最“近”的节点连过来
				var best_parent_idx = int(float(j) / next_layer.size() * current_layer.size())
				best_parent_idx = clamp(best_parent_idx, 0, current_layer.size() - 1)
				_connect_nodes(current_layer[best_parent_idx], next_layer[j])

static func _connect_nodes(from_node: Resource, to_node: Resource) -> void:
	if not from_node.connections.has(to_node.position_grid):
		from_node.connections.append(to_node.position_grid)
