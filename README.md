# 武侠卡牌肉鸽游戏 - 战斗系统开发总结

## 项目概述

基于 Godot 4.x 开发的类《杀戮尖塔》武侠风格卡牌肉鸽游戏战斗系统原型。

---

## 已完成功能

### 核心战斗系统
| 功能 | 状态 | 说明 |
|------|------|------|
| 回合制战斗流程 | ✅ | 玩家回合 → 敌人回合循环 |
| 真气（能量）系统 | ✅ | 每回合恢复，打牌消耗 |
| 卡牌抽取/弃置 | ✅ | 抽牌堆、弃牌堆、洗牌机制 |
| 伤害/护甲计算 | ✅ | 支持状态效果加成 |
| 胜负判定 | ✅ | HP归零触发胜利/失败 |

### UI 组件
| 组件 | 文件 | 功能 |
|------|------|------|
| 玩家面板 | `PlayerPanel.tscn` | 血条、护甲、状态效果 |
| 敌人面板 | `EnemyPanel.tscn` | 血条、意图、状态效果 |
| 卡牌UI | `CardBase.tscn` | 费用角标、类型边框、描述 |
| 伤害飞字 | `DamageNumber.tscn` | 伤害/治疗数字动画 |
| 能量球 | 内嵌于场景 | 真气显示 |
| 牌堆计数器 | 内嵌于场景 | 抽/弃牌堆数量 |

### 卡牌类型
- **招式（ATTACK）** - 红色边框，造成伤害
- **身法（SKILL）** - 绿色边框，提供护甲/辅助
- **内功（POWER）** - 紫色边框，持续性效果

---

## 项目结构

```
f:\game\
├── scenes/
│   ├── battle/
│   │   ├── BattleScene.tscn    # 战斗主场景
│   │   └── TestBattle.gd       # 战斗初始化脚本
│   ├── card/
│   │   └── CardBase.tscn       # 卡牌UI场景
│   ├── character/
│   │   ├── PlayerPanel.tscn    # 玩家信息面板
│   │   └── EnemyPanel.tscn     # 敌人信息面板
│   └── ui/
│       ├── DamageNumber.tscn   # 伤害飞字
│       ├── EnergyOrb.tscn      # 能量球
│       └── PileCounter.tscn    # 牌堆计数器
├── scripts/
│   ├── core/
│   │   ├── BattleManager.gd    # 战斗管理器
│   │   ├── CharacterBase.gd    # 角色基类
│   │   ├── CharacterPanel.gd   # 角色面板脚本
│   │   ├── CardUI.gd           # 卡牌UI控制
│   │   ├── HandManager.gd      # 手牌管理（弧形布局）
│   │   └── DamageNumber.gd     # 伤害飞字动画
│   ├── resources/
│   │   ├── CardData.gd         # 卡牌数据资源
│   │   └── EnemyData.gd        # 敌人数据资源
│   └── cards/
│       └── CardFactory.gd      # 卡牌/敌人工厂
└── GameRules.md                # 游戏规则设计文档
```

---

## 运行方式

1. 在 Godot 中打开项目
2. 运行 `scenes/battle/BattleScene.tscn`
3. 操作：
   - **拖拽卡牌向上** → 打出卡牌
   - **点击"结束回合"** → 进入敌人回合

---

## 已修复问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| CharacterPanel 节点引用失败 | 节点路径不匹配 | 添加 `VBoxContainer/` 前缀 |
| CardUI.update_display Nil 错误 | @onready 未初始化时调用 | 添加节点存在性检查 |
| 无法抽牌 | BattleManager 初始化时机问题 | 添加 `setup_battle_refs()` 方法 |
| DamageNumber 无动画 | 场景缺少脚本引用 | 添加脚本引用 |

---

## 后续开发建议

1. **地图系统** - 添加关卡选择和肉鸽地图生成
2. **更多卡牌** - 扩展卡牌种类和效果
3. **敌人AI** - 基于 EnemyData 的行动模式
4. **奖励系统** - 战斗胜利后的卡牌/遗物选择
5. **存档机制** - 游戏进度保存
