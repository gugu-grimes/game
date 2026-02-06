extends Control

var map_data: Array = []
var node_buttons: Dictionary = {}

func setup(data: Array, btns: Dictionary) -> void:
	map_data = data
	node_buttons = btns
	queue_redraw()

func _draw() -> void:
	if map_data.is_empty():
		return
		
	for floor_idx in range(map_data.size() - 1):
		var layer = map_data[floor_idx]
		for node in layer:
			var start_btn = node_buttons.get(node.position_grid)
			if not start_btn: continue
			
			var start_pos = start_btn.position + start_btn.size / 2
			
			for next_pos_grid in node.connections:
				var end_btn = node_buttons.get(next_pos_grid)
				if not end_btn: continue
				
				var end_pos = end_btn.position + end_btn.size / 2
				
				draw_line(start_pos, end_pos, Color(0.8, 0.8, 0.8, 0.5), 2.0)
