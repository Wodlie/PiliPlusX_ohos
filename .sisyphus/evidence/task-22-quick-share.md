# Task 22 Evidence — 快速分享 + pmShare + enableQuickShare/quickShareId

**Timestamp:** 2026-08-01
**Repo:** D:\coding\PiliPlusX_ohos
**Reference (A):** D:\coding\PiliPlusX

## Summary

- B 的 `lib/utils/request_utils.dart:73 pmShare` 已存在（用 `Accounts.main`，且已用 `SelectableText`——OHOS 适配正确）。**无需修改**。
- A 的 pmShare 多一个 `avoidGetBack = false` 参数，但该参数在 A 函数体内**从未使用**（grep 仅命中声明行 77）——是死参数，B 调用方正确省略。
- 新增分享按钮 `onLongPress` 3 处（header_control / ugc / pgc），消费 `Pref.enableQuickShare` + `Pref.quickShareId`。
- `Pref.enableQuickShare`/`quickShareId` 消费点激活：`storage_pref.dart:845,1114` getter 存在，3 处 onLongPress 消费。

## Files Changed

| File | Change |
|------|--------|
| `lib/pages/video/widgets/header_control.dart` | +import request_utils; share ActionItem + onLongPress |
| `lib/pages/video/introduction/ugc/view.dart` | +import storage_pref; share ActionItem + onLongPress |
| `lib/pages/video/introduction/pgc/view.dart` | +import request_utils/storage_pref/flutter_smart_dialog; share ActionItem + onLongPress |
| `lib/utils/request_utils.dart` | **未修改**（B 已完整） |

## QA Scenarios

### Scenario 1: pmShare 接线（grep）
```
1. grep 'pmShare' lib/utils/request_utils.dart            → 命中 line 73（static Future<bool> pmShare）
2. grep 'onLongPress' lib/pages/video/widgets/header_control.dart → 命中 2193（分享按钮）
3. grep 'quickShareId' lib/pages/video/                    → 3 处消费命中
   - header_control.dart:2210
   - introduction/ugc/view.dart:548
   - introduction/pgc/view.dart:467
4. grep 'enableQuickShare' lib/pages/video/                → 3 处消费命中（同一批 onLongPress）
```
**Result: PASS**（全部命中）

### Scenario 2: 无 SelectionText 恢复
```
1. grep 'SelectionText(' lib/pages/video/                 → 0 命中
2. grep 'SelectionText|SelectableText' lib/utils/request_utils.dart → 仅 SelectableText（line 364, 581）
```
**Result: PASS**（B 保持 SelectableText；无 SelectionText 泄漏）

### Scenario 3: 保留 B 现有分享实现
```
B 的 onTap: () => introController.actionShareVideo(context) 保留（3 处）——Share.shareXFiles 不受影响
```
**Result: PASS**（onTap 未改，onLongPress 为新增并行手势）

### Scenario 4: dart analyze --no-fatal-warnings
```
error 计数: 31（= 基线，T16 后）
改动文件 error: 0
```
**Result: PASS**（无新增错误）

### Scenario 5: RED 测试检查
```
test/storage_pref_test.dart:171,175 → 仅断言 SettingBoxKey.enableQuickShare/'enableQuickShare'
与 SettingBoxKey.quickShareId/'quickShareId' 键存在（Pref getter 已使用这两个键，测试已绿）
```
**Result: PASS**（无待转绿的 RED 引用）

## Constraints Verification

- [x] 未重写 B 现有 pmShare（0 修改 request_utils.dart）
- [x] 未恢复 SelectionText（grep 0 命中）
- [x] 未删 B 现有分享实现（Share.shareXFiles / actionShareVideo 保留）
- [x] 未动 share_plus 版本（pubspec.yaml 未涉及）
- [x] 未新增桌面分支
- [x] 未编辑 `*.g.dart` / `*.pb*.dart`
- [x] 未动 text_selection.dart 注释代码

## Notes

- A 的 `avoidGetBack: true` 参数在 B 中省略：该参数 A 声明但函数体未引用，属死参数；B 的 pmShare 无此参数。
- 消费模式与 A 逐字对齐（除 avoidGetBack），保持 A/B 功能一致。
