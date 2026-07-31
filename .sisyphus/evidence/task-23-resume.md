# Task 23 QA Evidence — 历史续播 + SponsorBlock 无痕抑制

**Date:** 2026-08-01
**Branch:** master
**Baseline:** dart analyze = 31 errors (T16 后基线，25 test RED + 6 vendored)

## 1. 历史续播（progress 传入 pgc/ugc 播放页）

### 改动：`lib/pages/history/widgets/item.dart`
- 新增 `resumeProgress`（item.progress 秒 → 毫秒，`progress > 0` 才有效，`-1`/`0` 返回 null）：
  ```dart
  final resumeProgress = switch (item.progress) {
    final int progress when progress > 0 => progress * 1000,
    _ => null,
  };
  ```
- **pgc 分支**：`PageUtils.viewPgc(epId: item.history.epid, progress: resumeProgress)` — viewPgc 已支持 progress（B page_utils.dart:644）
- **cheese 分支**：`PageUtils.viewPgcFromUri(..., progress: resumeProgress)` — viewPgcFromUri 已支持 progress（B page_utils.dart:597）
- **ugc 分支**：`PageUtils.toVideoPage(..., progress: resumeProgress)` — toVideoPage 已支持 progress（B page_utils.dart:560）

### 签名确认（`lib/utils/page_utils.dart`，无改动）
- `viewPgc({seasonId, epId, progress, off})` — **已含** progress ✓
- `toVideoPage(..., progress, ...)` — **已含** progress ✓（UGC 续播入口）
- `viewPugv` 的 progress 参数属 **Task 27** 域（plan 明示），本任务不动
- 保留 B 的 `enterPip` floating 插件 OHOS 适配、`ContextExtensions` 等既有实现

### 消费链验证
- `toVideoPage` → `/videoV` arguments 含 `'progress': ?progress` → 播放页续播
- `viewPgc` → `toVideoPage(progress: progress)`（pgc 与 viewSection 两处均透传）
- 未删任何 `viewPgc`/`viewUgc` 现有调用方

## 2. SponsorBlock 无痕/游客抑制

### 改动：`lib/pages/sponsor_block/block_mixin.dart`
- 新增 import：`package:PiliPlus/pages/mine/controller.dart`（`MineController.anonymity` 已存在于 B）
- foundation import 补 `debugPrint`：`show debugPrint, kDebugMode`
- **不拉取**：`querySponsorBlock` 开头新增：
  ```dart
  if (Pref.suppressSponsorBlockIncognito && MineController.anonymity.value) {
    return;
  }
  ```
  `Pref.suppressSponsorBlockIncognito` 已存在于 B（storage_pref.dart:906 + SettingBoxKey:214）
- **不上报**：`_skipToast` 的 `viewedVideoSponsorTime` 条件追加
  `!(Pref.suppressSponsorBlockIncognito && MineController.anonymity.value)`
- **catchError**：`_doVote` 的 `.then(...)` 链追加
  ```dart
  .catchError((e) {
    debugPrint('SponsorBlock vote error: $e');
  });
  ```

## 3. RED 测试检查
- grep `suppressSponsorBlockIncognito` in `test/`：仅 `storage_pref_test.dart:242` 断言 `SettingBoxKey` key 存在（已在），**无 mixin 行为引用** → 无转绿负担
- grep `resumeProgress`/`viewPugv` in `test/`：无引用

## 4. 验证命令
- `dart analyze --no-fatal-warnings` → **31 errors**（= 基线 31，无新增）
- 改动文件 0 error 0 warning（analyze 输出与 lsp_diagnostics 双确认）
- 未改 `sponsor_block_api.dart`（SAME）、未动 `*.g.dart`/`*.pb*.dart`、未新增桌面分支

## 5. 改动文件清单
| 文件 | 状态 | 说明 |
|------|------|------|
| `lib/pages/history/widgets/item.dart` | 修改 | resumeProgress + pgc/cheese/ugc 透传 |
| `lib/pages/sponsor_block/block_mixin.dart` | 修改 | 无痕抑制 + catchError + 2 import |
| `lib/utils/page_utils.dart` | 未改（验证） | viewPgc/toVideoPage 已含 progress |
