extends Node

# 全局游戏状态管理器 (RunManager)
# 负责在场景切换间保持数据持久化

signal run_updated

# 玩家数据
var current_deck: Array[CardData] = []
var max_hp: int = 80
var current_hp: int = 80
var gold: int = 0
var max_energy: int = 3

# 进度数据
var current_floor: int = 0
var map_seed: int = 0
var map_state: Dictionary = {
	"current_node_pos": Vector2i(-1, -1),
	"map_data": [] # Array[Array[MapNodeData]]
}

# 临时数据（用于调试或初始测试）
var _starter_deck_ref: Array[CardData] = []

func _ready() -> void:
	print("RunManager loaded")

# 初始化一局新游戏
func start_new_run(starter_deck: Array[CardData]) -> void:
	current_deck = []
	# 深度复制牌组，防止修改原资源
	for card in starter_deck:
		current_deck.append(card.duplicate())
	
	max_hp = 80
	current_hp = max_hp
	gold = 100
	max_energy = 3
	current_floor = 1
	
	# 初始化地图状态
	map_state = {
		"current_node_pos": Vector2i(-1, -1),
		"map_data": []
	}
	
	print("新游戏开始！Deck: %d cards, HP: %d" % [current_deck.size(), current_hp])
	run_updated.emit()

# 获取一张新卡
func add_card_to_deck(card: CardData) -> void:
	current_deck.append(card.duplicate())
	print("获得新卡: %s" % card.card_name)
	run_updated.emit()

# 移除一张卡
func remove_card_from_deck(card_id: String) -> void:
	for i in range(current_deck.size()):
		if current_deck[i].id == card_id: # 假设 CardData 有唯一 id 或通过实例比较
			current_deck.remove_at(i)
			break
	run_updated.emit()

# 更新玩家状态（通常在战斗结束时调用）
func update_player_state(hp: int) -> void:
	current_hp = hp
	print("玩家状态更新 - HP: %d/%d" % [current_hp, max_hp])
	if current_hp <= 0:
		_handle_game_over()

func update_map_progress(node_pos: Vector2i) -> void:
	map_state.current_node_pos = node_pos
	# 标记已访问
	var floor_idx = node_pos.x
	var node_idx = node_pos.y
	if map_state.map_data.size() > floor_idx:
		var node = map_state.map_data[floor_idx][node_idx]
		node.visited = true
	run_updated.emit()

func _handle_game_over() -> void:
	print("游戏结束！")
	# 这里后续可以发送信号通知 UI 显示失败界面
