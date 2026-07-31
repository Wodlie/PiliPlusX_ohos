# Task 25 — 播放器快捷操作（长按倍速/画面比例 + 独立快退时长 + HDR 提示）

## 交付物对照

| 期望项 | 状态 | 证据 |
|--------|------|------|
| `view.dart` speed/fit 控件 GestureDetector 长按切换（1.0x↔2.0x、contain↔cover）| ✅ | speed 分支 child 包 GestureDetector `onLongPress`/`onSecondaryTap`（view.dart:872-889）；fit 分支同样（view.dart:703-725），均 `feedBack()` + `SmartDialog.showToast` |
| `view.dart` qa 控件 HDR/杜比 提示弹窗 | ✅ | view.dart:938-957，选择 `VideoQuality.hdrVivid/dolbyVision/hdr` 时 `SmartDialog.show` AlertDialog「当前版本media_kit暂不支持HDR和杜比视界，将作SDR解析」（提示不阻断，仅提示后继续按 SDR 解析，符合 OHOS HDR 管线未知约束）|
| `controller.dart` `fastForBackwardDuration_` 独立字段 | ✅ | controller.dart:383-385，`Duration(seconds: Pref.fastForBackwardDuration_)`（B 的 storage_pref.dart:661 该 getter 原已存在，storage_key.dart:153 键已存在）|
| `view.dart` BackwardSeekIndicator 用 `fastForBackwardDuration_` | ✅ | view.dart:2130，双击快退指示器独立时长（ForwardSeekIndicator 保持 `fastForBackwardDuration` 不变）|

## 接线（未新增符号，全用 B 现有 API）

- `setPlaybackSpeed`（controller.dart:1227）与 `toggleVideoFit`（controller.dart:1403）**B 原本已存在**，长按直接复用，零新增方法。
- `feed_back.dart`（`feedBack()`）B 已存在且与 A 逐字节同构（`Pref.feedBackEnable` 门控 + `HapticFeedback.lightImpact`），仅给 view.dart 补 `import 'package:PiliPlus/utils/feed_back.dart'`。
- `SmartDialog`/`AlertDialog`/`TextButton`、`VideoQuality.hdrVivid/dolbyVision/hdr`（video_quality.dart:2,4,5）、`VideoFitType.contain/cover` 全在 B，无新依赖。

## 未复制 A 的播放器内核段（约束合规）

- **未**复制 A 的 `_initPlayer`/`_createVideoController`/`SimpleVideo`——B 保留 `Player()`/`VideoController()`/`maybeAsNativePlayer.setProperty`/`Video(controls: NoVideoControls)` 的 media_kit OHOS fork 接入（controller 全文未动这些段落）。
- **未**删 B 的 stall watchdog / PiP floating / OS.isHarmony 适配；controller.dart 中另有一处 hideStatusBar 恢复为并行任务写入，本任务未触碰。
- 未动 `text_selection.dart`、未新增桌面分支、未编辑 `*.g.dart`/`*.pb*.dart`。

## T19 协调（避开已占用区域）

- T19 占用构造器参数区、`buildBottomControl` stein case、`interactiveChild` 插入点（Positioned.fill 前）。
- T25 只改 `BottomControlType.fit/speed/qa` 三个 switch case 分支的 child 包裹与 onTap 内插段、BackwardSeekIndicator 的 duration 一行、import 一行——与 T19 区域零重叠。

## analyze 验证（`dart analyze --no-fatal-warnings`）

- 基线：31 errors（T16 后）
- 本任务后：**27 errors**（并行任务修复部分 test RED，比基线少 4，无新增）
- 改动文件：`lib/plugin/pl_player/controller.dart` 与 `view.dart` **0 error 0 warning**；仅 1 条 pre-existing info（controller.dart:748 `prefer_const_constructors`，setShader 区，非本任务引入）
- 其他 pl_player 文件无 error/warning。

## RED 测试检查

- grep `fastForBackwardDuration` in test/：`storage_key_test.dart:17`（`fastForBackwardDuration` 键）与 `storage_pref_test.dart:145-147`（`fastForBackwardDuration_` 键存在断言）——两个 SettingBoxKey 在 B 原本已存在（storage_key.dart:152-153），**无待转绿 RED**。controller 新字段 `fastForBackwardDuration_` 无测试直接引用。

## Runtime-pending（设备可验证）

- 长按倍速/画面比例切换、右键（onSecondaryTap）切换、HDR/杜比选择弹窗为 UI 层交互，需真机验证。
