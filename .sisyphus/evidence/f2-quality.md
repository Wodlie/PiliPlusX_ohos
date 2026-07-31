# F2 — Code Quality Review Report (Final Verification Wave)

**Date:** 2026-08-01
**Task:** port-a-features Final Verification Wave #2 — Code Quality Review
**Repo:** D:\coding\PiliPlusX_ohos
**Range:** `886b57dd9..HEAD` (`5971e081`) — 17 commits, 131 changed files (95 lib/ + 3 test/ + 33 evidence/notepad/docs)

---

## Summary Line

**Build [PASS] | Lint [PASS] | Files [91 lib clean / 0 issues] | VERDICT: APPROVE**

---

## 1. Build — `dart analyze --no-fatal-warnings`

Command run at HEAD `5971e081` (global Dart 3.12.2 / Flutter 3.44.4 on PATH).

**Result: 18 errors / 34 warnings / 197 info = 249 issues. ALL errors are known baseline. ZERO errors in ported files.**

| Count | File | Category | Note |
|------:|------|----------|------|
| 1 | `lib/utils/platform_shortcuts.dart:21` | vendored (init 遗留) | `switch(defaultTargetPlatform)` 缺 `.ohos` 分支 — 运行时 `OS.isHarmony` 提前返回不触达，非移植引入 |
| 7 | `test/connectivity_utils_test.dart` | test/ RED (已知) | 未移植 API 断言 |
| 6 | `test/android_helper_test.dart` | test/ RED (已知) | `AndroidHelper` 未定义 |
| 4 | `test/platform_utils_test.dart` | test/ RED (已知) | `isDarwin`/`isHarmony` 未定义 |

**错误构成归因（重要）**: Batch5 报告 23 错误（6 vendored engine + 17 test）；本次 18 错误（1 vendored + 17 test）。差异是**环境**，不是回归 — package_config 重新生成后解析 OHOS SDK，`ExtendSelectionByPageIntent`/`TargetPlatform.ohos` 那 6 个 vendored 假象错误消失，platform_shortcuts.dart 的 non_exhaustive_switch 现出 1 个。17 个 test RED 逐项不变。**判断基线看错误构成，不是总数**（learnings.md 已有此归因）。

**34 warnings 分布（全部已知）**：
- **2 个在移植文件中**（见 §2，均 A-verbatim）：
  - `lib/pages/video/ai_conclusion/view.dart:153` `unreachable_switch_case`（`_ =>` 兜底）→ A:153 完全相同
  - `lib/pages/video/view.dart:288` `unnecessary_null_comparison`（`targetNode != null`）→ A:257 完全相同
- 其余 32 个全部在**非移植文件**：vendored engine（text_field.dart、identity_generators.dart ×5）、既有 lib（theme_utils ×4、block_filter_settings ×2、storage_pref、shortcut_keys_dialog、dynamics_mention、live_room、member_profile ×2）、test/ RED（14）。

**结论：无移植引入的 error；仅 2 个 A-verbatim warning 在移植文件，计划允许（"A 逐字一致"）。**

## 2. Code Quality Scan (91 changed lib .dart files)

### 2.1 Empty catches — PASS
- 新增 diff 中唯一真正空 catch：`lib/http/bilibili_subtitle_summary_adapter.dart:162` `catch (_) {}` → **A:162 逐字相同**（JSON 多候选 try 循环，跳过非法候选属有意）。
- `lib/http/init.dart:105` `catch (_) {}` → **A:107-110 逐字相同**，T10 buvidActive 重试语义，注释说明（"失败保持 activated=false，下次可重试"）— 计划明示不算。
- 其余全部新增 `catch` 有真实处理体：
  - `video.dart:317/369/664` → `return Error('$e\n\n$s')`
  - `controller.dart:1178` → `kDebugMode` debugPrint
  - `pgc/view.dart:471`、`ugc/view.dart:552`、`header_control.dart:735` → `SmartDialog.showToast`
  - `video/view.dart:432/1606` → `kDebugMode` debugPrint / 返回空 widget
  - `hk_api_retry_interceptor.dart:38` → toast + `handler.next`
  - `multimodal_summary_adapter.dart:31` → `on FormatException` 返回结构化错误

### 2.2 Release prints — PASS
- 新增 diff 中所有 print 均为 `debugPrint` 或 `kDebugMode` 守卫：`_checkSteinResume`、`goToSteinStoryNode`、`build stein edges`、`getSteinEdgeInfo`、`SponsorBlock vote`、`WBI sign error`。无裸 `print(`。`avoid_print` lint 0 命中。

### 2.3 Commented-code restoration — PASS
- `lib/common/widgets/flutter/text_field/text_selection.dart` **0 行 diff** — 2921/3044 注释完好（`// // TODO 直接注释掉的代码 3.32.4-ohos-0.0.1不支持`）。
- 全 lib 无 `SelectionText(` 使用（仅有 `selection_text.dart` 自身定义文件 + gRPC 生成的 `selectionText` 字段，均非恢复）。
- `grpc/reply.dart:60-68` 注释掉的 `replyInfo` 块 → A:61-68 逐字相同。

### 2.4 Unused imports — PASS
- 全部 `unused_import` warning（block_filter_settings ×2、shortcut_keys_dialog、storage_pref、bubble_test 等）都在**非移植文件**。91 个移植文件中 0 unused_import。

### 2.5 AI slop — PASS
- **新文件与 A 逐字节一致**（Compare-Object diff=0）：`bilibili_multimodal_summary_adapter.dart`、`bilibili_subtitle_summary_adapter.dart`、`ai_summary_service_router.dart`、`hk_api_retry_interceptor.dart`、`image_grid_view.dart`、全部 4 个 stein edgeinfo 模型、`iterable_ext.dart`。
- **比 A 更干净**：`custom_host_interceptor.dart`（94→65 行，删掉 29 行 reverse-engineering 调查注释，A 有 B 无 → 反 slop）。
- **B 自研**：`account_migration.dart`（21 行，33% doc 注释但都是迁移语义说明，合理）、`request_identity_adapter.dart`（211 行，0 注释行，结构清晰）。
- 无过度注释（新文件注释密度 0-20%）、无过度抽象（无多余泛型/工厂）、无通用命名（`localId`/`fpLocal`/`ownerKey` 等均为领域术语）、无重复代码块。

### 2.6 `as dynamic` / `dynamic` 等价物 — PASS
- T27 已**整体删除** `selectable_region_ext.dart`（A 版含 `(this as dynamic).selectable` 坏代码，B 无残留），`extension_test.dart` 注释说明原因。
- 新增 diff 中仅 `Map<String, dynamic>`（JSON 解析，项目标准写法）。无 `as dynamic`、无 `(x as dynamic).foo` 访问。

## 3. Guardrail / Protected-file audit — PASS

| Guardrail | Status |
|-----------|--------|
| `text_selection.dart:2921,3044` 未恢复 | ✅ 0 diff |
| 无 `SelectionText(` 恢复 | ✅ |
| 无新增桌面平台分支 | ✅ `Platform.isWindows/Linux/MacOS` diff 0 新增 |
| 4 个「鸿蒙待适配」TODO | ✅ 计数仍 4 |
| 受保护文件（`.g.dart`/`GeneratedPluginRegistrant.ets`/`*.pb*.dart`） | ✅ 0 触碰 |
| ohos/android/ios/macos/windows/linux 目录 | ✅ 0 触碰 |
| pubspec 仅加 `visibility_detector` | ✅ 且被使用（image_grid_view.dart:41，与 A 一致），非死依赖 |
| 删除 3 个 context_menu orphan helper | ✅ 0 残留引用 |

## 4. Deep-read files (10/10)

`account_migration.dart` ✅ · `request_identity_adapter.dart` ✅ · `grpc_headers.dart` ✅（B 干净版，裁掉 A 的长 reverse-eng 注释）· `grpc/reply.dart` ✅（5 策略 A-verbatim）· `ai_summary_service_router.dart` ✅ · stein models ✅ · `image_grid_view.dart` ✅ · `reply_item_grpc.dart` ✅（BlockedReplyBanner 结构清晰）· `pl_player/view.dart` ✅（stein 追加干净，其余为既有 OHOS 适配）· `extra_settings.dart` ✅（catch 模式与 A 一致）。

## 5. Issues found

**0 blocking issues.** 2 informational notes (non-blocking, A-verbatim):
1. `ai_conclusion/view.dart:153` — `_ =>` 兜底分支 unreachable（A 原样，保留作防御性默认）。
2. `video/view.dart:288` — `targetNode != null` 恒真检查（A 原样，无害）。

---

**VERDICT: APPROVE**
- Build: 18 errors 全为已知基线（1 vendored + 17 test RED），0 移植 error
- Lint: 0 空 catch（除 A-verbatim 有意项）、0 release print、0 注释恢复、0 unused import、0 AI slop、0 as-dynamic 残留
- Guardrails: 全部通过
- 91 移植文件 clean
