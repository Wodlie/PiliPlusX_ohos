# Task 26 — 下载按 UP 主名过滤 + 保存评论图强制原文

**Date:** 2026-08-01
**Base:** dda954016 (T16 baseline, analyze 31 errors)

## Changes

### 1. UP 主名过滤 — `lib/pages/download/search/controller.dart`
`customGetData()` 的 `where` 条件增加 `ownerName` 匹配，与 A 逐字一致：

```dart
(e) =>
    e.title.toLowerCase().contains(text) ||
    e.showTitle.toLowerCase().contains(text) ||
    (e.ownerName?.toLowerCase().contains(text) ?? false),
```

- `BiliDownloadEntryInfo.ownerName`（`String?`）字段已在 B 模型（bili_download_entry_info.dart:38），无需补模型。
- null-safe：`ownerName == null` 时短路为 `false`。

### 2. 保存评论图强制原文 — `lib/pages/save_panel/view.dart`
SavePanel 渲染 `ReplyItemGrpc` 时传 `forceShowOriginalContent: true`（与 A save_panel/view.dart:378 一致）：

```dart
ReplyInfo reply => IgnorePointer(
  child: ReplyItemGrpc(
    replyItem: reply,
    replyLevel: 0,
    needDivider: false,
    upMid: widget.upMid,
    forceShowOriginalContent: true,
  ),
),
```

- 参数已由 T15 添加到 `reply_item_grpc.dart`（默认 `false`），本任务接线消费。
- `forceShowOriginalContent=true` 使保存图走 `child: (…!)` 渲染原图分支（reply_item_grpc.dart:178,207），不折叠为小图。

## Constraints honored
- 保留 B 下载多选分享：未触碰 `onRemove`/多选逻辑（controller 其余部分原样）。
- 未改 `download_manager`/`download_service`。
- 未删 `forceShowOriginalContent` 默认值分支（非保存场景仍 false）。
- 未新增桌面分支。

## Verification
`dart analyze --no-fatal-warnings` 结果：

```
Total errors: 31 (baseline, unchanged)
```

- 6 vendored (editable_text.dart ×3, vertical_slider.dart ×3) — 既有基线
- 25 test/ RED — 既有基线（android_helper ×6, connectivity_utils ×7, platform_utils ×4, extension ×4, selectable_region_ext ×4）
- **2 改动文件 0 error 0 warning**

无新增 error。A/B diff 已核对（见下）。

## A/B Parity
- `controller.dart` where 子句：A 行 36 与 B 修改后逐字相同。
- `save_panel/view.dart:378`：A `forceShowOriginalContent: true` 与 B 修改后逐字相同。
- 未复制的部分：无（两文件整体结构本已同构）。
