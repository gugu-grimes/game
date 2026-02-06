extends Resource
class_name MapNodeData

enum NodeType {
	ENEMY,
	ELITE,
	REST,
	EVENT,
	SHOP,
	BOSS
}

@export var type: NodeType = NodeType.ENEMY
@export var position_grid: Vector2i = Vector2i.ZERO # 在地图网格中的位置
@export var connections: Array[Vector2i] = [] # 连接到的下一个层级的节点坐标
@export var visited: bool = false
@export var available: bool = false

func _init(p_type: NodeType = NodeType.ENEMY, p_pos: Vector2i = Vector2i.ZERO):
	type = p_type
	position_grid = p_pos
