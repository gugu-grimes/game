extends EventDefinition
class_name OldBeggarEvent

var stage: int = 0

func _init():
	id = "old_beggar"
	title = "老乞丐"
	description = "你在路边遇到一个衣衫褴褛的老乞丐，他向你伸出脏兮兮的手，嘴里念叨着什么绝世武功。"
	options = [
		{ "text": "施舍金钱 (50金)", "tooltip": "失去50金，获得一张随机稀有卡" },
		{ "text": "帮忙疗伤 (失去10HP)", "tooltip": "失去10点生命，移除一张卡牌" },
		{ "text": "无视离开", "tooltip": "什么也不发生" }
	]

func is_option_available(idx: int) -> bool:
	if stage == 0:
		if idx == 0:
			return RunManager.gold >= 50
		if idx == 1:
			return RunManager.current_hp > 10
	return true

func execute_option(idx: int) -> bool:
	if stage == 0:
		match idx:
			0:
				RunManager.gold -= 50
				var card = CardFactory.create_random_reward_card() # 简单给张卡
				RunManager.add_card_to_deck(card)
				description = "老乞丐嘿嘿一笑，从怀里掏出一本破书塞给你：“好人有好报！”"
				options = [{ "text": "离开" }]
				stage = 1
				return false # 不关闭，刷新文本
			1:
				RunManager.current_hp -= 10
				RunManager.update_player_state(RunManager.current_hp)
				# 这里应该打开移除卡牌界面，为了简化，随机移除一张打击或防御
				_remove_basic_card()
				description = "你运功帮老乞丐疏通经脉。他感激地指点了几句，让你豁然开朗，忘却了一些繁杂招式。"
				options = [{ "text": "离开" }]
				stage = 1
				return false
			2:
				return true # 离开
	else:
		# 阶段1：任意选项都是离开
		return true
	
	return true

func _remove_basic_card() -> void:
	for i in range(RunManager.current_deck.size() - 1, -1, -1):
		var card = RunManager.current_deck[i]
		if card.card_name == "长拳" or card.card_name == "格挡":
			RunManager.remove_card_from_deck(card.id)
			print("移除了卡牌: " + card.card_name)
			break
