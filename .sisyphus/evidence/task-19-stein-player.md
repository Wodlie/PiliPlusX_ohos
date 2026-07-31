# Task 19 — Stein 互动视频播放器 UI

**状态**: 完成 | **日期**: 2026-08-01 | **基线**: 31 errors（T16 后）| **结果**: 31 errors（持平）

## 交付内容

### 1. `lib/plugin/pl_player/models/bottom_control_type.dart`
- 在 `episode` 与 `fit` 之间追加 `stein` 枚举值（与 A 顺序一致，index 5）

### 2. `lib/plugin/pl_player/view/view.dart`（+19 行，与 A 逐字对齐）
- `PLVideoPlayer` 构造器新增可选参数：`showStein`（VoidCallback?）+ `interactiveChild`（Widget?），字段声明同步
- `buildBottomControl` 新增 `BottomControlType.stein => ComBtn(...)` 分支（`Icons.history_rounded` + tooltip「进度回溯」+ `onTap: widget.showStein`），位于 viewPoints 与 episode 之间
- 在 `// 头部、底部控制条` 前插入 `if (widget.interactiveChild != null) widget.interactiveChild!,`（与 A 第 1661 行位置一致）
- 注意：A 的 `userSpecifyItemRight` 默认列表**不含** `.stein`（A 自身如此，switch case 存在但未挂进默认列表，主入口是 interactiveChild 的「进度回溯」按钮）——照 A 保持

### 3. `lib/plugin/pl_player/controller.dart`
- **无需改动**：T18 已在 `pages/video/controller.dart`（VideoDetailController）交付全部 stein 字段（steinEdgeInfo/showSteinEdgeInfo/steinResumeNode/steinHistory/recordCurrentSteinNode/getSteinEdgeInfo/goToSteinStoryNode）；PlPlayerController 无 stein 相关字段（A 同）

### 4. `lib/pages/video/view.dart`（+274 行）
- 新增 2 个模型 import：`video_play_info/interaction.dart`（HistoryNode）、`video_stein_edgeinfo/story_list.dart`（StoryList）
- `_steinResumeWorker` 字段 + `initState` 中 `ever(steinResumeNode, ...)` 接线（mounted + addPostFrameCallback → `_showSteinResumeDialog`）+ `dispose` 释放
- `_showSteinResumeDialog(HistoryNode)`：恢复互动视频进度弹框（从头开始 / 继续观看），点继续后按 `steinEdgeInfo.storyList` 匹配 `historyNode.cid`/`isCurrent==1`/last 找目标节点 → `goToSteinStoryNode`
- `_showSteinHistorySheet()`：进度回溯面板（当前节点高亮 play_circle / 历史节点 radio_button，点击 → `goToSteinStoryNode`）；空历史 toast「暂无互动历史记录」；全屏/半屏走 `PageUtils.showVideoBottomSheet`，否则 `childKey.showBottomSheet`
- `plPlayer` 中 `PLVideoPlayer` 接线：`showStein: _showSteinHistorySheet` + `interactiveChild: Obx(...)`（showSteinEdgeInfo 时渲染选项按钮 Wrap + 选项点击前 `recordCurrentSteinNode()` + `onChangeEpisode(item, isStein: true)` + `getSteinEdgeInfo(item.id)`；`steinHistory.length > 1` 时追加「进度回溯」TextButton）
- 保留 B 既有：`playerListener` onCompleted 的 stein 检查（B 已有）、`videoPlayer` 的 stein 选项 Obx（B 已有，A 同款无 recordCurrentSteinNode）

## 硬约束遵守情况

| 约束 | 状态 |
|------|------|
| 不复制 A 的 `_initPlayer`/`_createVideoController`/`SimpleVideo` | ✅ 未触碰；所有 stein 交互走 B 现有 `Player()`/`VideoController()`/`onChangeEpisode`/`goToSteinStoryNode`/`seekTo` |
| `interactiveChild` 为 Widget?、`showStein` 为回调 | ✅ 框架级参数，不触播放器内核 |
| 进度恢复弹框为 GetX UI | ✅ `ever(steinResumeNode,...)` + AlertDialog，不触内核 |
| 保留 B 播放器现有适配 | ✅ stall watchdog/PiP floating/OS.isHarmony/SelectableText 均未动 |
| 不编辑 `*.g.dart`/`*.pb*.dart` | ✅ 未触碰 |
| 不删 text_selection.dart | ✅ 未触碰 |
| 不新增桌面分支 | ✅ 无 |

## 验证

- `dart analyze --no-fatal-warnings`：**31 errors**（基线持平，无新增错误）
- 改动文件 lint 情况：
  - `pages/video/view.dart:288` `unnecessary_null_comparison`（warning）——**A verbatim**（A `view.dart:257` 同款，`?? storyList.last` 兜底使 RHS 非空）
  - `pages/video/view.dart:306` `use_decorated_box`（info）——**A verbatim**（A `view.dart:275` 同款）
- 非 `--no-fatal-warnings` gate 关注项（A 两仓库同款噪音）
- RED 测试检查：`test/` 无 `showStein`/`stein`/`interactiveChild` 引用 → 无转绿负担
- 其他 `PLVideoPlayer(` 消费点（live_room/view.dart）参数均可选，无破坏

## runtime-pending（仅设备可验证）
- 进度恢复弹框触发时机（checkResume）
- 回溯面板交互（点击节点跳转）
- 选项点击后选项条更新（getSteinEdgeInfo 重取）
