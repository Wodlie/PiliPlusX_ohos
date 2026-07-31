# Task 28 QA Evidence — 恢复设置项 + 账号选择器昵称

**Date:** 2026-08-01
**Branch:** master (B = D:\coding\PiliPlusX_ohos)
**Reference:** A = D:\coding\PiliPlusX (dev)

## 目标
恢复 6 项设置 UI + 消费点激活 + 账号选择器昵称，参照 A 按需重写，不复制文件。

## 改动清单（4 文件）

### 1. lib/pages/setting/models/extra_settings.dart（+137）
新增 5 项设置 UI（港澳台代理 URL / AI 总结配置组已存在于 B，本任务只补缺失项）：
- **账号选择器显示昵称**（`SettingBoxKey.accountDisplayName`，默认 false）— 顶部桌面块后、空降助手前（A 同位置）
- **图片&截图 保存路径**（`getSaveImgPathModel`，`saveImgPath`/`saveScreenshotPath`，suffix 'bili'）— 门控 `Platform.isAndroid || OS.isHarmony`（OHOS 适配：A 仅 Platform.isAndroid，B 移动端需含鸿蒙）
- **默认申诉理由**（`Pref.defaultAppealReason` 编辑弹窗，保存写回）— 发评反诈后、哔哩发评反诈前
- **快速分享给指定用户**（`enableQuickShare`/`quickShareId`，mid 输入校验，无效关闭开关）— 快速收藏前
- **评论区AI翻译**（`SettingBoxKey.enableCommentTranslate`，默认 true）— 评论区搜索关键词后、启用AI总结前

消费点接线验证（T11/T13/T15/T22/T10 已提供底层）：
- `Pref.enableCommentTranslate` → `reply_item_grpc.dart:706`（T15）
- `Pref.defaultAppealReason` → `reply_utils.dart:131`（T15）
- `Pref.enableQuickShare`/`Pref.quickShareId` → `header_control.dart:2194/2210`、`ugc/view.dart:532/548`、`pgc/view.dart:450/467`（T22）
- `Pref.apiHKUrl`（设置港澳台代理）→ 拦截器（T11）；AI 总结组 8 项（T13）均在 B 已完整

### 2. lib/pages/setting/models/model.dart（+47）
- 新增 import `common/constants.dart`
- 新增 `getSaveImgPathModel({context, title, key1, key2, suffix, defaultValue = 'Pictures/${Constants.appName}'})` — 照 A verbatim（B 原缺此函数，09_report §6 确认）

### 3. lib/pages/login/controller.dart（+7）
- 新增 import `utils/storage_pref.dart`
- `switchAccountDialog` 增加 `useDisplayName = Pref.accountDisplayName`，options map 用 `Pref.getAccountDisplayName(v.mid)` 显示昵称（A 同款）

### 4. lib/pages/setting/view.dart（+9）
- 新增 import `utils/storage_pref.dart`
- `_logoutDialog` 增加 `useDisplayName`，多选列表 + 确认文案均用 `Pref.getAccountDisplayName(i.mid)` 显示昵称（A 同款，09_report §1 指出 B 登出框不生效）

## RED 测试检查
`test/storage_pref_test.dart` 引用 `enableCommentTranslate`/`enableQuickShare`/`quickShareId`/`accountDisplayName`/`defaultAppealReason` — 全部断言 `SettingBoxKey.*` 键存在，键在 `storage_key.dart` 均已定义，无新 RED 负担，无需转绿操作。

## analyze 结果
`dart analyze --no-fatal-warnings`（与 T24-T27 并行任务共存，计数有瞬时抖动，按文件隔离判定）：
- 改动 4 文件：**0 error / 0 warning**（仅 extra_settings.dart:743 一条 pre-existing info `unnecessary_lambdas`，A 同款）
- 总 error：27 → **26**（无新增，并行任务 T 系列继续压降；learnings 基线 31 已被 T18-T27 降低）
- 总 warning：39 持平
- 无新增 import 泄漏（grep `SelectableText` 消费点不变，`storage_pref` import 均被使用）

## 约束满足
- ✅ 不删 B 的设置页拆分架构（7 分类页保留）
- ✅ 不把 B 已改名的条目（屏蔽与过滤）改回 A 文案
- ✅ 保留 B 的 OHOS 设置项（enableHdsBar/showActualVolume/enableStatusBarTapToTop/allowRotateScreen）
- ✅ 保留 B 的 `OS.isHarmony`（saveImgPath 门控复用）/`SelectableText`
- ✅ 不编辑 `*.g.dart`、`*.pb*.dart`；不改 T11/T13/T15/T22 已完成逻辑（只补 UI）；不新增桌面分支
- ✅ 按需重写（Edit 落点），未复制 A 文件

## 待真机验证（runtime）
- 快速分享 mid 输入弹窗、AI 总结超时校验、图片保存路径选择、账号昵称显示均需真机走查；验收以 analyze 0-error + 符号接线为准。
