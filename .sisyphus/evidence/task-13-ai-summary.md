# Task 13 — AI 总结多服务（router + legacy/multimodal/subtitle adapters + 设置组）

**Date:** 2026-07-31
**Branch:** master (B = D:\coding\PiliPlusX_ohos，A = D:\coding\PiliPlusX)

## 交付物

1. **`lib/http/ai_summary_service_router.dart`（新建）** — 按 A verbatim：`abstract final class AiSummaryServiceRouter`，`summarizeUgcVideo` 按 `Pref.aiSummaryService`（`service ?? Pref.aiSummaryService`）switch 分发到 subtitle/multimodal/legacy 三路，无 fallback。
2. **`lib/http/bilibili_multimodal_summary_adapter.dart`（新建）** — 按 A verbatim：`VideoHttp.ugcSummaryMp4Url` → `OpenAiCompatibleMp4VideoInput.parse` 校验 → `OpenAiCompatibleSummaryProvider.summarizeMultimodal`，错误分类为 Unavailable/Misconfigured/ProviderError。
3. **`lib/http/bilibili_subtitle_summary_adapter.dart`（新建）** — 按 A verbatim：`VideoHttp.playInfo` 选字幕 → `VideoHttp.transcriptSubtitles` → `summarizeText`，JSON 解析（_parseSummaryResponse/_tryParseConclusionJson/_stripMarkdownCodeFence/_extractJsonObject）。
4. **`lib/http/video.dart`（修改）** — 恢复 `ugcSummaryMp4Url`（WbiSign + Api.ugcUrl + PlayUrlModel.durl.firstOrNull 取 http/https URL）+ `transcriptSubtitles` + `_processTranscriptList`。补 `import 'package:collection/collection.dart' show IterableExtension;`（B 的 video.dart 不 import material，firstOrNull 需显式引入）。
5. **`lib/pages/video/ai_conclusion/view.dart`（修改）** — 保留 B 现有 UI 结构（selectableText/SelectionArea），新增 A 的三个静态方法 `hasContent` / `messageForResult` / `showResultMessage`。
6. **`lib/pages/video/introduction/ugc/controller.dart`（修改）** — 数据获取改为 router：`enableAiSummaryBackground`、`aiConclusionResultService`、`_aiConclusionFuture`、`_handleAiConclusionResult`、`cachedAiConclusionSuccess`、`isAiConclusionInProgress`、`_requestAiConclusion`（→ `AiSummaryServiceRouter.summarizeUgcVideo`）、`aiConclusion()`（后台模式 / 加载框模式）。**保留** static `getAiConclusion`（`video_popup_menu.dart` 仍直连 legacy，A 同款遗留）。
7. **`lib/pages/video/introduction/ugc/view.dart`（修改）** — `_aiBtn` 接入新流程：cached → inProgress toast → 后台模式 → `AiSummaryServiceSuccess` + `hasContent` → `showAiBottomSheet`，否则 `showResultMessage`。
8. **`lib/pages/setting/models/extra_settings.dart`（修改）** — 设置组（`启用AI总结` 之后）：`后台进行AI总结` Switch、`视频总结服务` PopupModel<AiSummaryService>、`AI总结 Base URL`、`AI总结 API Key`、`文本总结模型`、`多模态总结模型`、`AI总结超时时间`；helper `_aiSummaryApiKeySubtitle` / `_normalizeAiSummaryBaseUrl` / `_showAiSummaryTextDialog` / `_showAiSummaryTimeoutDialog`（按 A verbatim）。

## 接线确认

- `AiSummaryServiceRouter.summarizeUgcVideo` ← `UgcIntroController._requestAiConclusion`（bvid/cid/title/upMid 全传，service 走 `Pref.aiSummaryService`）。
- `Pref.aiSummaryService` 默认 `bilibiliLegacyDeprecated` → 行为与改造前一致（直连 `BilibiliLegacySummaryAdapter` → `VideoHttp.aiConclusion`）。
- 设置组写键：`SettingBoxKey.enableAiSummaryBackground / aiSummaryService / aiSummaryBaseUrl / aiSummaryApiKey / aiSummaryTextModel / aiSummaryMultimodalModel / aiSummaryTimeoutSeconds`（storage_key.dart 与 storage_pref.dart 均已在 B 存在，**未修改**）。
- `lib/pages/video/view.dart:1951` `// TODO 鸿蒙待适配 ai总结模板无法拖拽关闭` 未动。

## 验证证据

### dart analyze（本任务起点基线 159 errors，见 T17 notepad：163 − 4 grpc_identity 全绿）

```
ERRORS: 146   （159 → 146，−13，恰为 RED 测试的 12×messageForResult + 1×hasContent undefined_method）
```

- 8 个改动/新建文件 analyze 0 error；5 个 video_summary 测试文件 `No issues found!`。
- 新增非 error 项（与 A 同款，不阻塞 gate）：
  - `ai_conclusion/view.dart:153 unreachable_switch_case`（A verbatim 的 `_ =>` 兜底，sealed 穷尽后不可达）
  - `extra_settings.dart:606 unnecessary_lambdas`（info，A 同款 `onSelected` 写法）
  - `ugc/controller.dart:808 unnecessary_async`（info，A 同款 `_requestAiConclusion` async）
- 其余 146 errors 全为 B 既有基线（context_menu 85 + test RED 68 + vendored 引擎 editable_text/vertical_slider 等）。

### RED → GREEN

| 测试文件 | 基线 | 现状 |
|---|---|---|
| `video_summary_failure_states_test.dart` | 12 error（messageForResult 未定义） | analyze 0 error |
| `video_summary_ugc_widget_test.dart` | 1 error（hasContent 未定义） | analyze 0 error |
| `video_summary_settings_test.dart` | 0 error（任务预期 1，实测基线已 0） | analyze 0 error |
| `video_summary_routing_test.dart` | — | analyze 0 error；`flutter test` **2/2 PASS** |
| `test/http/ai_summary_test.dart` | router/adapters/ugcSummaryMp4Url 未定义（大量） | analyze 0 error；`flutter test` 38/39 PASS，1 失败为**既有**契约 mismatch |

### flutter test 结果与既有环境限制

- `video_summary_routing_test.dart`（纯 source-contract，不拉 material）：**All tests passed (2/2)**。
- `test/http/ai_summary_test.dart`：38 PASS / 1 FAIL。唯一失败 `AiConclusionResult model contracts` 期望 model_result.dart 含 `List<Subtitle>? subtitle`——该模型两仓库逐字节 SAME 且本任务未动，字段本就不存在 → **既有测试契约 bug，与本次改动无关**（A 同样失败）。
- `video_summary_failure_states/ugc_widget/settings` 三个测试**无法编译**：`flutter test` 在 `lib/common/widgets/flutter/text_field/editable_text.dart:5559`（`ExtendSelectionByPageIntent` not found）编译失败。这是 B 既有基线错误（baseline analyze 就含该 error），与 flutter/material 无关的 widget 测试（`test/widgets/fractionally_sized_box_test.dart`）同样失败 → **环境性 pre-existing，非本任务引入**。可验证口径 = analyze 级 0 error（13 个 RED 错误已清零）。

## 合规检查（MUST NOT DO）

- ✅ 未编辑 `*.g.dart` / `*.pb*.dart`
- ✅ 未改 `openai_compatible_summary_provider.dart`、`ai_summary_service.dart`、`video_summary_provider.dart`、`bilibili_legacy_summary_adapter.dart`（与 A 逐字节 SAME，git status 无记录）
- ✅ 未动 `lib/pages/video/view.dart:1951` 鸿蒙待适配 TODO
- ✅ 未引入新依赖（multimodal/subtitle adapter 全部消费 B 既有 http/model）
- ✅ 未新增桌面分支
- ✅ `dart format --set-exit-if-changed` 8 文件 0 changed
