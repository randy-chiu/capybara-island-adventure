# 卡皮巴拉海岛探险

这是项目唯一的正式游戏工程，使用 Godot 4.7 开发。仓库不再保留独立的 Swift/iOS 版本，所有关卡、玩法和后续迭代都统一在 `Game/` 中完成。

## 试玩

在 Finder 中双击根目录的 `试玩卡皮巴拉海岛.command`。

也可以在终端运行：

```bash
godot --path Game
```

使用 Godot 编辑器开发：

```bash
godot --editor --path Game
```

## 操作

- 方向键或 `WASD`：移动
- `空格` 或 `E`：互动
- 也可以点击右下角互动按钮
- 解题后按互动键亲自铺桥板、装水或在标记位置铺草垫
- 在各岛渡船码头往返已解锁岛屿，建设进度不会丢失

## 当前连续流程

1. 收集鱼饵并前往码头钓鱼
2. 找到断桥并解决与实际材料对应的修桥问题
3. 解题后由玩家操作 6 次逐块铺桥，过桥到达对岸
4. 打开宝箱并选择进入下一关
5. 在第二座岛收集 3 处水滴线索
6. 根据目标、已有水量和桶容量，亲自装满正好 3 桶水
7. 进入第三座岛，测量营地、火塘和草垫数据
8. 计算后走到 10 个铺设点逐块放置草垫，走进营地完成验收

## 唯一工程结构

```text
Game/
  project.godot       Godot 项目配置
  main.tscn           游戏主场景
  scripts/main.gd     关卡、世界、交互和 UI 流程
  scripts/capybara_controller.gd
试玩卡皮巴拉海岛.command
design/levels/        三关已批准的设计规格
```

## 流程验证

```bash
HOME=/tmp/capybara-godot-home godot --headless --path Game -- --qa-flow
```
