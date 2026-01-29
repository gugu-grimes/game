# Godot 游戏架构与主菜单界面

## 当前项目状态

- Godot 4.6 项目，名称为 "we"
- 使用 Forward Plus 渲染、Jolt Physics 3D 物理引擎

## 游戏架构文件夹结构

```
we/
├── scenes/                 # 场景文件
│   ├── ui/                # UI 场景
│   │   └── main_menu.tscn # 主菜单场景
│   ├── levels/            # 关卡场景
│   └── characters/        # 角色场景
├── scripts/               # 脚本文件
│   ├── autoload/          # 自动加载的全局脚本
│   │   └── game_manager.gd
│   ├── ui/               # UI 脚本
│   │   └── main_menu.gd
│   └── utils/            # 工具脚本
├── assets/               # 资源文件
│   ├── textures/         # 纹理/图片
│   ├── audio/            # 音频
│   ├── fonts/            # 字体
│   └── models/           # 3D 模型
└── resources/            # 资源配置 (.tres)
```

## 主菜单界面实现

### 场景结构 (`scenes/ui/main_menu.tscn`)

```
MainMenu (Control)
└── CenterContainer
    └── VBoxContainer
        ├── Label (游戏标题)
        └── Button (开始游戏按钮)
```

### 脚本功能 (`scripts/ui/main_menu.gd`)

- 处理"开始游戏"按钮的点击事件
- 预留切换场景的逻辑

### 项目配置更新 (`project.godot`)

- 设置主菜单为游戏的启动场景
- 注册 GameManager 为自动加载

## 关键代码示例

**主菜单脚本 (GDScript 4.x):**

```gdscript
extends Control

func _ready():
    $CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)

func _on_start_pressed():
    # TODO: 切换到游戏场景
    print("开始游戏!")
```

**GameManager 全局脚本:**

```gdscript
extends Node

func change_scene(scene_path: String):
    get_tree().change_scene_to_file(scene_path)
```
