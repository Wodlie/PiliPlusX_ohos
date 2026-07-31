# Task 20 — 图片屏蔽 pHash UI 接入 (QA Evidence)

**Date:** 2026-08-01
**Branch:** master (B = D:\coding\PiliPlusX_ohos)
**Baseline:** 31 errors (post-T16: 6 vendored + 25 test RED)

## Changes

| File | Change |
|------|--------|
| `lib/common/widgets/image/blocked_image_placeholder.dart` | New version: "图片已屏蔽 / 长按查看" + parameterized (`width`/`height`/`borderRadius`/`onLongPress`), `Style.mdRadius`, `surfaceContainerHighest` |
| `lib/common/widgets/image_grid/image_grid_view.dart` | StatelessWidget → StatefulWidget: `_enableBlock` (Pref.enableImageBlock), `_imageBlockStatus` map, `_evaluateImageBlock`/`_evaluateAllImages`, `_tempUnblockedSrcs` + `tempUnblockedUrls` param, `_showUnblockMenu` bottom sheet, blocked-guard in `_onTap`/`_showMenu`, "屏蔽图片" menu item, `VisibilityDetector` wrap |
| `lib/common/widgets/image_viewer/gallery_viewer.dart` | `_onLongPress` gains "屏蔽图片" DialogOption (`ImageBlockService.blockImage` + Pref dedup + invalidateResultCache). **media_kit untouched** (B's `Video()`/`Player()` preserved) |
| `lib/common/widgets/dialog/report.dart` | `autoWrapReportDialog` gains `showImageBlock`/`imageUrls`/`onBlockImages` params + "同时屏蔽图片" CheckBoxText (default selected) + post-success `await onBlockImages(imageUrls)` |
| `lib/pages/video/reply/widgets/reply_item_grpc.dart` | Consumer wiring (T16 deferred to T20): `_tempUnblockImageUrls` + `_blockImageVersion` state, `tempUnblockedUrls` + `key` on ImageGridView, `hasBlockedImages`/`hasUnblockedImages` detection, "屏蔽图片" (multi-select dialog for >1 pics) + "恢复图片显示" menu items, report call passes `showImageBlock`/`imageUrls`/`onBlockImages` |
| `pubspec.yaml` | `visibility_detector: ^0.4.0` promoted from transitive (0.4.0+2 in lock, same as A's direct dep) to direct — no new package in graph |

## QA Scenarios

### Scenario 1: 图片屏蔽接线 (plan QA)
```
grep 'ImageBlockService' lib/common/widgets/image_grid/image_grid_view.dart → 123,163,309,386 ✓
grep 'tempUnblockedUrls' → 75,86,104 ✓
grep 'onBlockImages' lib/common/widgets/dialog/report.dart → 17,135,137 ✓
grep 'VisibilityDetector' → 450,453 ✓
grep '屏蔽图片|ImageBlockService' gallery_viewer.dart → 602,609,611,615 ✓
```
All hit.

### Scenario 2: Pref 消费激活
- `Pref.enableImageBlock` read in `image_grid_view.dart` initState (gates entire blocking UI) — activated.
- `Pref.imageBlockHashList` read/written via `ImageBlockService` (addBlockedImage/blockImage/unblockImages) — activated via menu + report + gallery.
- `image_block.dart` settings page (pre-existing) already writes both.

### Scenario 3: RED 测试转绿 (analyze level)
- `test/widgets/image_grid_view_test.dart` (5 image-block widget tests + 1 skipped) — **no errors** (was referencing blocking behavior; now compiles clean, referencing implemented ImageGridView/BlockedImagePlaceholder).
- `test/image_block_service_test.dart` (normalizeUrl / thumbnailUrlForHash / LRU / worker / isBlocked / getCachedBlockResult / unblockImages / addBlockedImage) — **no errors** (service pre-existed as SAME).
- `test/phash_cross_resolution_test.dart` — **no errors**.

### Scenario 4: analyze gate
```
dart analyze --no-fatal-warnings → 31 errors (run 3× stable)
Baseline 31 → 31 (0 new)
Distribution: 6 vendored (editable_text×3 + vertical_slider×3) + 25 test RED (android_helper×6, connectivity×7, platform×4, extension×4, selectable_region×4)
```
Changed files: 0 errors, 0 warnings.

### Scenario 5: OHOS 保留 / 受保护文件
- `gallery_viewer.dart` media_kit: B's `Player()`/`VideoController()`/`Video()` untouched (only `_onLongPress` menu extended).
- `text_selection.dart`, `*.g.dart`, `*.pb*.dart`, `image_block_service.dart`, `GeneratedPluginRegistrant.ets` — untouched.
- `dart:io show Platform` + `PlatformUtils.isMobile/isDesktop` branches preserved (existing OHOS pattern).
- `reply_item_grpc.dart` `SelectableText` + `_filterMenuBuilder` (B's OHOS text-selection adaptation) preserved.

## Runtime note
pHash 屏蔽评估 / 长按查看 / 举报联动按画像属于**runtime-pending**（无真机），以 analyze 0-error + 符号接线为验收。`ImageBlockService` 为两仓库 SAME 文件，isBlocked 内部已含 `Pref.enableImageBlock` 守卫。
