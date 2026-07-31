# Task 24 QA Evidence — 动态/首页刷新 FAB + 剪贴板搜索

**Date:** 2026-08-01
**Branch:** master
**Plan:** port-a-features / Task 24

## Deliverables

| File | Change |
|------|--------|
| `lib/pages/common/fab_mixin.dart` | `BaseFabMixin` 增加 `fabAnimWrapper({required Widget child})` + `onNotification`（A 的封装，滚动方向 forward/reverse → showFab/hideFab） |
| `lib/pages/common/dyn/common_dyn_page.dart` | 删除本地位置参数 `fabAnimWrapper(Widget child)`，改为 `@override onNotification`（axisDirection==down 守卫 + super 委托）——与 A 完全同构 |
| `lib/pages/dynamics/controller.dart` | 增加 FAB 全套状态：`_isFabVisible`/`_fabAnimationCtr`/`_fabAnimation`/`fabAnimation` getter（200ms + Offset(0,2)→zero + easeInOut）/`showFab`/`hideFab` |
| `lib/pages/dynamics/view.dart` | `Scaffold.floatingActionButton`（`Pref.showDynamicsRefreshFab` 门控）+ body 用 `NotificationListener<UserScrollNotification>` 包裹（滚动方向显隐） |
| `lib/pages/home/controller.dart` | `GetSingleTickerProviderStateMixin` → `GetTickerProviderStateMixin` + FAB 全套状态（A 模式）；`dispose` 增加 `_fabAnimationCtr?.dispose()` |
| `lib/pages/home/view.dart` | `NotificationListener<UserScrollNotification>` + `Stack` + 首页 FAB（`Pref.showHomeRefreshFab`）+ 搜索栏剪贴板按钮（`Pref.showClipboardSearch`，读取剪贴板 → 写搜索历史 → 跳 `/searchResult`） |
| `lib/pages/article/view.dart` `dynamics_detail/view.dart` `match_info/view.dart` `music/view.dart` | 消费点 `fabAnimWrapper(child)` → `fabAnimWrapper(child: child)`（配合签名改为具名参数） |

## 1. Pref 激活验证（死键 → 消费点）

```
grep showDynamicsRefreshFab lib/pages/dynamics/ →
  view.dart:173 floatingActionButton: Pref.showDynamicsRefreshFab
  view.dart:223 if (!Pref.showDynamicsRefreshFab) return false;
grep showHomeRefreshFab lib/pages/home/ →
  view.dart:80  if (!Pref.showHomeRefreshFab) return false;
  view.dart:107 if (Pref.showHomeRefreshFab)
grep showClipboardSearch lib/pages/home/view.dart →
  view.dart:218 if (Pref.showClipboardSearch) ...[
```

storage_pref 键（pre-existing，已激活）：`showHomeRefreshFab`(:217)、`showDynamicsRefreshFab`(:220)、`recordSearchHistory`(:664)、`clipboardSearchIncognito`(:667)、`showClipboardSearch`(:670)。

## 2. 剪贴板搜索接线

- `Clipboard.getData(Clipboard.kTextPlain)` — flutter/services
- 无数据 → `SmartDialog.showToast('剪贴板无数据')`
- `Pref.recordSearchHistory && !Pref.clipboardSearchIncognito` → `GStorage.historyWord` 写 'cacheList'（去重置顶）
- `Get.toNamed('/searchResult', parameters: {'keyword': text})`（路由已在 app_pages.dart:111）

## 3. FAB 动画参数（对照 A verbatim）

- 时长 200ms，`Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset.zero)` + `CurveTween(Curves.easeInOut)`
- 初始 `..forward()`（可见）；`showFab()`=forward、`hideFab()`=reverse
- `heroTag: null` 防 Hero 冲突；`onPressed` = `feedBack()` + `onRefresh()`

## 4. `dart analyze --no-fatal-warnings`

- **改动文件：0 error / 0 warning**（单独 analyze 通过）
- 全项目：**23 errors / 0 warnings**（基线 31 → 23，不增）
- 23 = 6 vendored（editable_text×3 + vertical_slider×3，已知基线）+ 17 test RED（android_helper×6、connectivity_utils×6、platform_utils×5，其中 8 个被并行任务 T25-T29 清零）
- 残余 2 info（均非本任务引入）：
  - `common_dyn_page.dart:24` unnecessary_import（rendering 导入原本即冗余，改动前已存在）
  - `home/view.dart:238` cascade_invocations（A verbatim 同款代码，A 侧同 lint）

## 5. OHOS 保留检查

- dynamics controller `statusBarTap`（onInit/onClose）保留 ✓
- 无 `SelectionText(` 恢复、无桌面分支（`Platform.isWindows/TargetPlatform.windows/...`）在改动文件 0 命中 ✓
- `text_selection.dart` 未触碰（git diff 空）✓
- 未编辑 `*.g.dart` / `*.pb*.dart` / `bindings.g.dart` ✓
- B 的 home 现有结构（TabBar 内页、hideTopBar/barOffset、native bottom nav 经 main/view.dart）未破坏 ✓

## 6. 文件完整性

`git diff --name-only` 改动文件仅任务范围（6 文件）+ 4 个消费点；受保护文件 0 触碰。其余 M 文件为并行任务（T25-T29）产物。

## Runtime-Pending

- FAB 显隐动画、剪贴板搜索需真机验证（analyze + 符号接线为准）。
