extends Node

const BATTLE_SCENE = preload("res://scenes/battle/BattleScene.tscn")
const VICTORY_SCENE = preload("res://scenes/ui/VictoryScreen.tscn")
const MAP_SCENE = preload("res://scenes/ui/MapScene.tscn")
const REST_SCENE = preload("res://scenes/ui/RestScene.tscn")
const EVENT_SCENE = preload("res://scenes/ui/EventScene.tscn")
const SHOP_SCENE = preload("res://scenes/ui/ShopScene.tscn")

const MapGenerator = preload("res://scripts/core/MapGenerator.gd")
const MapNodeData = preload("res://scripts/resources/MapNodeData.gd")

# 事件池
# 事件池
# 事件池
const OldBeggarEvent = preload("res://scripts/events/OldBeggarEvent.gd")  # 修正路径

var current_scene_node: Node = null

func _ready() -> void:
	# 为了简单，直接开始新游戏
	start_new_game()

func start_new_game() -> void:
	print("GameLoop: 开始新游戏")
	var starter_deck = CardFactory.create_starter_deck()
	if not RunManager:
		push_error("RunManager 单例未找到，请检查项目设置中是否已注册 RunManager 为自动加载。")
		return
	RunManager.start_new_run(starter_deck)
	
	# 生成新地图
	var map_data = MapGenerator.generate_map()
	RunManager.map_state.map_data = map_data
	
	show_map()

func show_map() -> void:
	print("GameLoop: 进入地图")
	_clear_current_scene()
	
	var map_scene = MAP_SCENE.instantiate()
	add_child(map_scene)
	current_scene_node = map_scene
	
	map_scene.setup_map(RunManager.map_state.map_data)
	map_scene.node_selected.connect(_on_map_node_selected)

func _on_map_node_selected(node: Resource) -> void:
	print("GameLoop: 选择了节点 %s" % MapNodeData.NodeType.keys()[node.type])
	
	# 更新进度
	RunManager.update_map_progress(node.position_grid)
	
	match node.type:
		MapNodeData.NodeType.ENEMY, MapNodeData.NodeType.ELITE, MapNodeData.NodeType.BOSS:
			start_battle(node)
		MapNodeData.NodeType.REST:
			show_rest_scene()
		MapNodeData.NodeType.EVENT:
			show_event_scene()
		MapNodeData.NodeType.SHOP:
			show_shop_scene()
		_:
			print("未实现的节点类型，跳过")
			show_map()

func show_rest_scene() -> void:
	print("GameLoop: 进入休息点")
	_clear_current_scene()
	
	var rest_scene = REST_SCENE.instantiate()
	add_child(rest_scene)
	current_scene_node = rest_scene
	
	rest_scene.rest_completed.connect(show_map)

func show_event_scene() -> void:
	print("GameLoop: 进入事件")
	_clear_current_scene()
	
	var event_scene = EVENT_SCENE.instantiate()
	add_child(event_scene)
	current_scene_node = event_scene
	
	# 简单随机：目前只有一个事件
	var event_def = OldBeggarEvent.new()
	event_scene.setup_event(event_def)
	
	event_scene.event_completed.connect(show_map)

func show_shop_scene() -> void:
	print("GameLoop: 进入商店")
	_clear_current_scene()
	
	var shop_scene = SHOP_SCENE.instantiate()
	add_child(shop_scene)
	current_scene_node = shop_scene
	
	shop_scene.shop_exited.connect(show_map)

func start_battle(node: Resource) -> void:
	print("GameLoop: 进入战斗")
	_clear_current_scene()
	
	var battle = BATTLE_SCENE.instantiate()
	battle.auto_start_battle = false # 禁用自动开始
	add_child(battle)
	current_scene_node = battle
	
	# 获取 BattleManager 信号
	var battle_manager = battle.get_node("BattleManager")
	battle_manager.battle_ended.connect(_on_battle_ended)
	
	# 根据节点类型创建敌人
	var enemy_data = CardFactory.create_test_enemy()
	
	# 难度调整
	var difficulty_factor = node.position_grid.x # 层数
	if node.type == MapNodeData.NodeType.ELITE:
		difficulty_factor += 5
		enemy_data.enemy_name = "精英守卫"
	elif node.type == MapNodeData.NodeType.BOSS:
		difficulty_factor += 10
		enemy_data.enemy_name = "武林盟主"
	else:
		enemy_data.enemy_name = "山贼 Lv.%d" % (difficulty_factor + 1)
		
	enemy_data.max_hp += difficulty_factor * 10
	
	battle.start_external_battle(enemy_data)

func _on_battle_ended(victory: bool) -> void:
	print("GameLoop: 战斗结束, 胜利: %s" % victory)
	await get_tree().create_timer(1.5).timeout
	
	if victory:
		_show_victory_screen()
	else:
		print("GameLoop: 游戏结束 (失败)")
		await get_tree().create_timer(2.0).timeout
		start_new_game()

func _show_victory_screen() -> void:
	_clear_current_scene()
	
	var victory_screen = VICTORY_SCENE.instantiate()
	add_child(victory_screen)
	current_scene_node = victory_screen
	
	victory_screen.continue_pressed.connect(_on_victory_continue)

func _on_victory_continue() -> void:
	print("GameLoop: 返回地图")
	show_map()

func _clear_current_scene() -> void:
	if current_scene_node:
		current_scene_node.queue_free()
		current_scene_node = null
