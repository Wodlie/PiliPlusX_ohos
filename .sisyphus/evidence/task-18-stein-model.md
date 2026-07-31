# Task 18 — Stein 互动视频数据模型 + 进度恢复

**Date:** 2026-08-01
**Branch:** master (D:\coding\PiliPlusX_ohos)
**Reference:** A = D:\coding\PiliPlusX (Wodlie fork 完整版)

## 结论

Stein 互动视频数据模型（4 个 DIFF 文件）已恢复为 A 的 fork 完整版；video controller 已补齐进度恢复逻辑（`steinResumeNode`/`goToSteinStoryNode`/本地历史栈/进度回溯数据）。播放器内核未改动，`dart analyze` 错误数维持基线 31。

## 1. 模型字段对齐（A fork 完整版 vs B 精简版 → 已恢复）

| 文件 | B 精简版（原） | A fork 完整版（恢复后） | 验证 |
|---|---|---|---|
| `choice.dart` | 仅 `id/cid/option` | + `platformAction`/`nativeAction`/`condition`/`isDefault` | 归一化后与 A 逐字节一致 |
| `data.dart` | 仅 `edges` | + `title`/`edgeId`/`storyList`/`buvid`/`preload`/`isLeaf` | 归一化后与 A 逐字节一致 |
| `edges.dart` | 仅 `questions` | + `dimension`/`skin` | 归一化后与 A 逐字节一致 |
| `question.dart` | 仅 `choices` | + `id`/`type`/`startTimeR`/`duration`/`pauseVideo`/`title` | 归一化后与 A 逐字节一致 |

SHA 校验：4 文件换行归一化（CRLF→LF）后与 A 对应文件**完全一致**（`normalized-equal=True` ×4）。

依赖文件核对（A/B 均为 SAME，未改，供 T19/后续引用）：
- `preload.dart`、`skin.dart`、`story_list.dart`、`video.dart`、`video_detail/dimension.dart`、`video_play_info/interaction.dart`（`HistoryNode`）——SHA-256 全部 SAME。

## 2. video controller 进度恢复逻辑（`lib/pages/video/controller.dart`）

按 A 补齐（新增 157 行，逐段与 A 归一化比对一致）：

- 新增 import：`video_play_info/interaction.dart`（`HistoryNode`）、`video_stein_edgeinfo/story_list.dart`（`StoryList`）
- 新增状态：
  - `HistoryNode? _steinHistoryNode`（服务器返回的上次观看节点）
  - `List<StoryList> _localSteinHistory`（本地选择历史栈）
  - `StoryList? _currentSteinNode`（当前节点，nodeId/edgeId 优先标识）
  - `late final Rx<HistoryNode?> steinResumeNode`（进度恢复信号，驱动 T19 的对话框）
- 新增方法：
  - `_isSameSteinNode()` / `_findCurrentSteinNode()`（含 edgeId 顶层兜底构造）
  - `recordCurrentSteinNode()`（选择选项前调用，供 T19 view 接线）
  - `steinHistory` getter（合并历史栈 + 当前节点）
  - `_checkSteinResume()`（恢复判定：起点不恢复/同 cid 不恢复/发出信号）
  - `goToSteinStoryNode()`（截断历史 + `onChangeEpisode(isStein: true)` + `getSteinEdgeInfo(edgeId)` + cursor/startPos seek）
- 修改 `getSteinEdgeInfo`：签名 `[int? edgeId, bool checkResume = false]`；成功时记录 `_currentSteinNode`、`checkResume` 时触发 `_checkSteinResume()`（A 对齐；B 原为无 checkResume）
- 修改 `_queryPlayInfo`：读取 `response.interaction?.historyNode`，`cid != 当前` 时存 `_steinHistoryNode` 并 `getSteinEdgeInfo(null, true)`
- 修改 `onReset`：`!isStein` 时重置 `_steinHistoryNode`/`steinResumeNode`/`_localSteinHistory`/`_currentSteinNode`

**约束遵守**：
- 未复制 A 的 `_initPlayer`/`_createVideoController`/`SimpleVideo` 段落；`goToSteinStoryNode` 只用 B 现有 `ugcIntroCtr.onChangeEpisode(Part(cid:...), isStein: true)`（B 已支持 `isStein` 参数）+ `plPlayerController.seekTo`（B 已有 `seekTo(Duration)`）。
- 未改动 B 现有播放器初始化（`plPlayerController = PlPlayerController.getInstance()` 等原样保留）。
- 保留 B 的 OS.isHarmony/SelectableText 模式（本任务不涉及）。

## 3. 进度恢复对话框归属（T18/T19 协调）

A 中进度恢复对话框 UI（`_showSteinResumeDialog(HistoryNode)`）、历史回溯面板（`_showSteinHistorySheet()`）、`_steinResumeWorker = ever(steinResumeNode, ...)`、`interactiveChild`/`showStein` 均位于 `pages/video/view.dart` + `plugin/pl_player/**`——按 06_video_report §22.4/§22.8 属 **T19（Stein 播放器 UI）范围**。

T18 已交付控制器侧全部机制：
- `steinResumeNode`（Rx 信号，T19 view 用 `ever()` 监听弹出对话框）
- `goToSteinStoryNode`（T19 对话框"继续观看"回调目标）
- `steinHistory` / `recordCurrentSteinNode` / `steinEdgeInfo.storyList`（T19 回溯面板 + 选项点击接线）
- `_checkSteinResume`（首次加载自动判定是否发信号）

**留给 T19 的协调**：view.dart 需恢复 `_steinResumeWorker = ever(videoDetailController.steinResumeNode, ...)` → `_showSteinResumeDialog(historyNode)`（参照 A view.dart:173-182,225-262），并在选择选项时先调 `recordCurrentSteinNode()`（参照 A view.dart:1481）。

## 4. dart analyze 验证

```bash
dart analyze --no-fatal-warnings
```
- **总 error：31**（基线 31，无新增）——分布 25 test RED + 6 vendored（editable_text/vertical_slider 等既有）
- 改动文件（`lib/models_new/video/video_stein_edgeinfo/*` + `lib/pages/video/controller.dart`）单独 analyze：**0 error 0 warning**
- 唯一 info 级 lint（`controller.dart:1194 curly_braces_in_flow_control_structures`）与 A controller.dart:1180 相同——A verbatim 固有，info 级不 gate

## 5. 测试 RED 检查

`grep -r stein/Stein/SteinEdgeInfo/HistoryNode test/`：**0 命中**——test/ 无 stein 引用，无 RED→GREEN 负担。

## 6. 文件清单（本任务改动）

- `lib/models_new/video/video_stein_edgeinfo/choice.dart`（M）
- `lib/models_new/video/video_stein_edgeinfo/data.dart`（M）
- `lib/models_new/video/video_stein_edgeinfo/edges.dart`（M）
- `lib/models_new/video/video_stein_edgeinfo/question.dart`（M）
- `lib/pages/video/controller.dart`（M，+157 行）

未触碰：`*.g.dart`、`*.pb*.dart`、`plugin/pl_player/**`、`pages/video/view.dart`、`common/widgets/flutter/text_selection.dart`。
