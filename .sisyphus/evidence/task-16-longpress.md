# Task 16 — canSort + 评论长按菜单（拉黑/分享）+ 手动加载评论图 + 孤儿 part 删除

**Date:** 2026-08-01
**Repo:** B = D:\coding\PiliPlusX_ohos
**参照:** A = D:\coding\PiliPlusX

## 1. 孤儿 part 文件删除（T4 决策，先删）

`git rm` 删除 3 个 `part of` 死代码文件（宿主库无 `part` 声明，不参与编译，造成 B HEAD 85 个 analyze 错误）：

```
D  lib/common/widgets/context_menu/dyn_menu_helper.dart
D  lib/common/widgets/context_menu/live_menu_helper.dart
D  lib/common/widgets/context_menu/reply_menu_helper.dart
```

- 删除前 `git grep -l "menu_helper"` 全库 0 个 dart 消费方（仅 `.sisyphus/` 文档引用）。
- 删除后 `dart analyze --no-fatal-warnings` 从 **116 → 31 errors**（−85）。

## 2. canSort 排序可用性（switcherType 控制）

**`lib/pages/common/reply_controller.dart`**（对照 A）：
- 新增 `final RxBool canSort = true.obs;`（:25）
- `customHandleResponse` isRefresh 块：`canSort.value = data.subjectControl.switcherType == Int64(1);`（:69）
- `onRefresh`：`canSort.value = true;` 复位（:87）
- `queryBySort`：`if (isLoading || !canSort.value) return;`（:93）

**`lib/pages/main_reply/view.dart`**（对照 A）：
- 排序按钮 `onPressed: canSort.value ? queryBySort : null`
- 不可用时 icon/label 置灰 `colorScheme.outline`，label 显示「排序不可用」

验证：`switcherType` 在 B 生成 pb 为 `$fixnum.Int64`（v1.pb.dart:12270），`== Int64(1)` 类型正确。

## 3. 评论长按菜单（morePanel 扩展）

**`lib/pages/video/reply/widgets/reply_item_grpc.dart`**（对照 A §17.8）：

- **拉黑评论者**（举报项之后，`ownerMid != Int64.ZERO` 门控）：
  - 确认对话框（`AlertDialog`「拉黑评论者」）
  - `VideoHttp.relationMod(mid, act: 5, reSrc: 11)`（:1421-1424）
  - 成功后 `GlobalData().blackMids.add(mid)` + `Pref.setBlackMid(mid)` + `onDelete()` + toast「已拉黑该用户」
  - 失败 toast「拉黑失败」
- **分享**（复制全部之后）：
  - `switch (type)` 构造 `#reply` 链接：1=video（`IdUtils.av2bv`）、12=read/cv、11||17=opus、默认兜底
  - `ShareUtils.shareText(url)`（:1476）
- 保留 B 现有全部菜单项（删除/举报/置顶/复制全部/自由复制/保存评论/检查评论 + superchat 等）——未删任何既有项。

## 4. 手动加载评论图

**`lib/pages/video/reply/widgets/reply_item_grpc.dart`**（对照 A `_buildCommentImages`）：
- 状态字段 `bool _loadManualImages = false;`（:168）
- `_buildContent` 图片区改走 `_buildCommentImages`（:551）
- `Pref.manualLoadCommentImage` 为 false 或已手动加载 → 直接 `ImageGridView`；否则渲染「点击加载图片（共N张）」占位，`onTap: setState(() => _loadManualImages = true)`（:588-622）
- **T20 边界**：B 的 `ImageGridView` 无 `tempUnblockedUrls` 参数（OHOS 版），图片屏蔽 UI（屏蔽图片/恢复图片显示/举报 onBlockImages）留给 Task 20，本任务未引入。`ImageBlockService`/`Pref.enableImageBlock`/`imageBlockFlipEnabled` 等基础设施 B 已有。

## 5. relationMod fp 字段修正（T1 issues #11）

**`lib/http/video.dart`** `VideoHttp.relationMod`：
- 原：`'fp': BrowserUa.pc`（语义错误，风控隐患）
- 改：`final identity = RequestIdentityAdapter.fromAccount(account: Accounts.main, userAgent: BrowserUa.pc);` + `'fp': identity.fpLocal`（对照 A，A 为 `_accountTypeForRelationAct` + `identity.fpLocal`；B 无 `_accountTypeForRelationAct`，保持 B 的 `Accounts.main` 语义）
- `request_identity_adapter.dart` 已在 B video.dart 导入（:33），零新 import。

## 6. dart analyze 对比

| 阶段 | errors |
|------|--------|
| B HEAD 基线（T14/T15 后） | 116 |
| 删 3 孤儿 part 后 | **31**（−85） |
| T16 全部改动后 | **31**（保持） |

- 31 errors 全为已知基线：25 test/ RED（connectivity_utils 7 + android_helper 6 + platform_utils 4 + extension_test insertOrAdd 4 + selectable_region_ext_test 4）+ 6 vendored（editable_text 3 + vertical_slider 3）。
- 38 warnings 全 pre-existing；4 个改动文件 **0 error 0 warning**。
- 验收标准「116 应大幅下降至 ~31」达成。

## 7. 约束合规

- [x] 未恢复 SelectionText（长按菜单沿用 B 的 showModalBottomSheet + ListTile 模式；自由复制仍是既有 SelectableText）
- [x] T14/T15 逻辑保留（BlockedReplyBanner、`_expanded`、翻译横幅参数 `translatedText/isTranslating/onTranslate/forceShowOriginalContent` 全部未动）
- [x] 未新增桌面分支（`onSecondaryTap: PlatformUtils.isMobile ? null : showMore` 为 B 既有）
- [x] 未编辑 `*.g.dart`/`*.pb*.dart`
- [x] 未新增依赖（id_utils/share_utils 均为 B 已有 util）
- [x] 孤儿 part 不恢复

## 8. RED 测试检查

`test/` 仅 `storage_pref_test.dart:212` 引用 `SettingBoxKey.manualLoadCommentImage`（storage key 存在性测试，key 已在 B 存在，无需改动）。无 canSort/relationMod RED 引用——本任务无测试转绿负担。
