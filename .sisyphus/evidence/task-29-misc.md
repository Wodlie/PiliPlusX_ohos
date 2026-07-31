# Task 29 — 视频换源跳转 videoPush + 隐藏状态栏 + 无痕空降（QA 证据）

**日期:** 2026-08-01
**基线:** dart analyze errors = 31（T16 后基线）

## 改动文件（3 个）

### 1. `lib/http/video.dart` — 换源跳转弹窗
- **前置检查**: B 的 `lib/utils/app_scheme.dart` **已有** `PiliScheme.videoPush`（line 881，签名 `videoPush(int? aid, String? bvid, {bool showDialog = true, bool off = false, int? progress, String? part})`）与 A 完全一致 → 无需补 app_scheme。
- **改动**: `videoUrl()` 在 `res.data['code'] != 0` 且 bvid 符合 `IdUtils.bvRegexExact` 时，弹出 `SmartDialog`「视频可能换源，是否跳转到新地址？」，确认后 `PiliScheme.videoPush(null, bvid, showDialog: false)`（照 A verbatim，B 之前直接返回错误）。
- **新增 import**: `flutter/material.dart`（AlertDialog/Text/TextButton/Theme）、`flutter_smart_dialog`、`utils/app_scheme.dart`。
- **A 参照**: `D:\coding\PiliPlusX\lib\http\video.dart:295-323`。

### 2. `lib/plugin/pl_player/controller.dart` — 隐藏状态栏
- **前置检查**: B 的 `utils/plugin/pl_player/utils/fullscreen.dart` 已有 `hideSystemBar()/showSystemBar()` 且带 `StatusBar.i`（OHOS 原生状态栏适配）→ 保留 B 机制，不采用 A 的纯 SystemChrome 写法。
- **改动**: `triggerFullScreen` 退出全屏分支 `if (!removeSafeArea)` 内，按 `Pref.hideStatusBar` 判定：false → `showSystemBar()`，true → `hideSystemBar()`（照 A `controller.dart:1434-1440`；B 之前无条件 showSystemBar）。
- `Pref.hideStatusBar`（storage_pref.dart:828）已存在。

### 3. `lib/pages/setting/models/extra_settings.dart` — 无痕空降设置项
- **前置检查**: T23 已在 `block_mixin.dart` 消费 `Pref.suppressSponsorBlockIncognito && MineController.anonymity.value`（querySponsorBlock line 68 + viewedVideoSponsorTime line 256）——无痕下不发空降助手查询 **消费点已接线**。
- **改动**: 补 A 有而 B 缺的「无痕模式不发送查询」`SwitchModel`（`setKey: SettingBoxKey.suppressSponsorBlockIncognito`），使该设置可在 UI 中开启。

## 验收 grep

| 断言 | 结果 |
|------|------|
| `videoPush` in `lib/http/video.dart` | PASS（弹窗 + PiliScheme.videoPush 调用） |
| `Pref.hideStatusBar` 消费 in `lib/plugin/pl_player/view/` (controller) | PASS（triggerFullScreen） |
| `incognito`/`suppressSponsorBlockIncognito` 空降助手调用点 | PASS（block_mixin.dart:68,256 消费 + extra_settings 设置项） |
| B 的 app_scheme videoPush 保留 | PASS（未删 B 现有方法，仅确认存在） |

## 约束检查

- 未编辑 `*.g.dart`、`*.pb*.dart`、`text_selection.dart`（2921,3044 注释完好）
- 未删 B 的 app_scheme 现有方法
- 未动 4 个「鸿蒙待适配」TODO
- 未新增桌面分支；保留 B 的 `StatusBar.i`/`OS.isHarmony`
- 保留 B 的 SelectableText 机制（本任务未涉及）

## dart analyze

```
dart analyze --no-fatal-warnings
ERRORS: 27（基线 31 → 27，-4：并行任务已修部分 test RED）
WARNINGS: 39（全 pre-existing，本任务 3 文件 0 error 0 warning）
```

错误分布：6 vendored（editable_text/vertical_slider）+ 21 test RED，均不在本任务改动文件内。

## runtime-pending

- 换源弹窗：需真机触发 -404（视频被删/换源）验证
- 隐藏状态栏：需真机全屏/退出全屏验证状态栏显隐
- 无痕空降：需真机登录账号 + 开启无痕 + 开启「无痕模式不发送查询」验证不查 SponsorBlock 服务器

## 结论

**PASS** — 3/3 功能落地，analyze 无新增 error/warning（27 < 31 基线）。
