# Task 27 Evidence — selectable_region 替代 + insertOrAdd + viewPugv(progress:)

> port-a-features Task 27 · Batch 4 并行组（T24-T29）· 2026-08-01
> 方案按 Batch 0 更新（T4 结论）：不移植 A 原版 `selectable_region_ext.dart`，改 B 原生 SelectableText 菜单实现「打开」。

## 1. 背景（Batch 0 实证，必须遵守）

- A 原版 `selectable_region_ext.dart` 用 `(this as dynamic).selectable` / `.selectionDelegate` 访问私有字段，
  两 SDK（3.44.4 / 3.41.10-ohos）均无公共 getter → 运行时必 NoSuchMethodError，**A 自身也是坏的**。
- 替代方案：B 现行 SelectableText 菜单（`EditableTextState.textEditingValue` 公共可取选区）直接加「打开」按钮。
- superchat（SelectionArea）无公共选区文本 → 不实现（与 A 实际损坏行为一致）。
- 3 个孤儿 part 文件（dyn/reply/live_menu_helper）T16 已删，不恢复。

## 2. 改动清单

| 文件 | 改动 |
|---|---|
| `lib/utils/extension/iterable_ext.dart` | 恢复 `ListExt.insertOrAdd(int index, T element)`（length<=index 则 add，否则 insert），与 A 逐字一致 |
| `lib/utils/page_utils.dart` | `viewPugv` 恢复 `int? progress` 参数并透传给 `toVideoPage(progress:)`；`viewPgcFromUri` 的 pugv 分支补传 `progress: progress` |
| `lib/pages/dynamics/widgets/content_panel.dart` | `_contextMenuBuilder` 在选区非折叠且 trim 后非空时追加「打开」按钮 → `PageUtils.launchURL(选区文本)` |
| `lib/pages/video/reply/widgets/reply_item_grpc.dart` | `_filterMenuBuilder` 同上追加「打开」按钮 |
| `test/utils/selectable_region_ext_test.dart` | **删除**（见 §4 决策） |
| `test/utils/extension_test.dart` | 更新头部注释（移除对已删 selectable_region_ext_test 的引用） |

选区文本获取（全公共 API，无隐私越权）：
```dart
state.textEditingValue.selection.textInside(state.textEditingValue.text).trim()
```
守卫：`!selection.isCollapsed` + `selected.isNotEmpty`。

## 3. 未改动（约束遵守）

- ❌ 未创建 A 原版 `selectable_region_ext.dart`
- ❌ 未恢复 `text_selection.dart:2921,3044` 注释代码
- ❌ 未恢复 3 个孤儿 part 文件
- ✅ `lib/common/widgets/selectable_text.dart`（B 独有工具）未动
- ✅ superchat_card.dart 保持原生 `SelectionArea`（superchat_card.dart:240），无「打开」
- ✅ 未新增桌面分支；保留 B 的 OHOS 适配

## 4. selectable_region_ext_test 处理决策

**删除** `test/utils/selectable_region_ext_test.dart`。理由：

1. 该测试引用 `SelectableRegionStateExt`（`hideAndClear`/`selectedText`/`isUncollapsed`）——A 原版 API，
   T4 已实证其核心 `selectedText`/`isUncollapsed` 在 A 自身运行时即 NoSuchMethodError，且 B 不移植。
2. 替代实现是 B 原生 SelectableText 菜单内的内联接线（content_panel/reply_item_grpc 的私有 menu builder），
   非独立可单测单元；保留旧测试只会保留对不存在 API 的 4 个编译错误。
3. 删除后 analyze error 31 → 23（−8：extension_test 4 insertOrAdd 转绿 + selectable_region_ext_test 4 移除）。

## 5. 验证

### 5.1 dart analyze --no-fatal-warnings

- 基线（T16 后）：**31 errors**（T25/T26 并行任务写入时亦保持 31）
- 完成后：**23 errors**（−8）
- 改动文件 0 error / 0 warning；剩余 23 全为已知基线：
  - 6 vendored 引擎（editable_text ExtendSelectionByPageIntent ×3、vertical_slider TargetPlatform.ohos ×3）
  - 2 并行任务（common_dyn_page/fab_mixin ScrollDirection.down，T14 FAB 域）
  - 15 test/ RED（android_helper 6、connectivity_utils 6、platform_utils 3）
- 新引入 info 级：extension_test.dart 4× `cascade_invocations`（既有 insertOrAdd 测试固有，非本任务引入，info 不 gate）

### 5.2 flutter test test/utils/extension_test.dart

**24/24 PASS**，含 4 个 insertOrAdd 断言：
- inserts at index when within bounds
- inserts at index when index equals length
- appends when index exceeds length
- inserts at index 0 on empty list

⚠️ `flutter test` 会重写 pubspec.lock（pub 镜像 URL），验证后已 `git checkout -- pubspec.lock` 恢复。

### 5.3 符号接线

- `insertOrAdd`：定义于 iterable_ext.dart:72，被 extension_test.dart 消费（4 断言全绿）
- `viewPugv(progress:)`：签名含 `int? progress`（page_utils.dart:749），透传 toVideoPage（page_utils.dart:775）；viewPgcFromUri pugv 分支透传（page_utils.dart:620）
- 「打开」按钮：content_panel.dart:120-126 + reply_item_grpc.dart:1713-1720（均 `PageUtils.launchURL`）
- superchat：SelectionArea 无「打开」→ runtime-pending 无 UI 验证（与 A 行为一致）

## 6. Runtime-pending（仅设备可验证）

- 长按选中文本 → 菜单出现「打开」→ 外部分流打开的 UI 交互（需真机长按选择文本）
- 课程视频（pugv）按进度续播跳转（需真实课程数据）

## 7. 结论

- insertOrAdd ✅ 恢复（测试 4/4 转绿）
- viewPugv(progress:) ✅ 恢复（签名 + 双透传点）
- selectable_region 替代方案 ✅ 落地（B 原生 SelectableText 菜单「打开」按钮，2 处消费点）
- selectable_region_ext_test 删除决策 ✅ 记录（§4）
- analyze 31 → 23，无新增 error/warning，改动文件 0 error
