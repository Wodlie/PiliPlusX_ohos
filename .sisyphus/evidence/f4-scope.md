# F4 — Scope Fidelity Check (Final Verification Wave Review #4)

**Date:** 2026-08-01
**Reviewer:** deep (F4 scope audit)
**Range:** `886b57dd9..HEAD` (17 commits: 50039f46 → 5971e081, T5–T29 + batch5 verify)
**Method:** `git log --stat` / `git show <commit> -- <file>` per-file diff inspection vs plan per-task "What to do" (`.sisyphus/plans/port-a-features.md`). Zero file modifications.

---

## 1. Task-by-Task Compliance (What to do ↔ git diff)

| Task | Commit(s) | Spec'd files touched | Out-of-list files (justified) | Status |
|------|-----------|----------------------|-------------------------------|--------|
| T5 | 50039f46 | account_type.dart, api_type.dart, privacy_settings.dart | — | ✅ |
| T6 | 8b2cde09 | account.dart, account_adapter.dart, account_migration.dart(new), storage.dart, test/hive_migration_test.dart(new) | — | ✅ |
| T7 | b4689fd7 | accounts.dart, account_mgr.dart, account.dart | — | ✅ |
| T8 | e8a4a532 | request_identity_adapter.dart(new), dynamics/follow/live/login/member/search/video.dart, login_utils.dart, wbi_sign.dart, path_utils.dart | — | ✅ |
| T9 | b552c998 | grpc_headers.dart, grpc_req.dart, im.dart, account.dart | — | ✅ |
| T10 | f9ea51b1 | init.dart (buvidActive retry + setCookie await), mine/controller.dart (setAccountUname) | — | ✅ |
| T11 | 20cda5c4 | custom_host_interceptor.dart(new), hk_api_retry_interceptor.dart(new), init.dart, grpc_req.dart, extra_settings.dart (HK URL + API host entry via `/apiHostSetting`) | — | ✅ |
| T12 | ae03902b | home_tab_type.dart, search_type.dart, pgc/controller+view, search_result/view, pgc.dart, search.dart | — | ✅ |
| T13 | ae03902b | router + 2 adapters(new), video.dart, ai_conclusion/view.dart, ugc/controller+view, extra_settings.dart (AI group) | — | ✅ |
| T14 | 01392350 | grpc/reply.dart, reply_item_grpc.dart (banner) | — | ✅ |
| T15 | eeee83b7 | reply/controller.dart, reply_item_grpc.dart, http/reply.dart, api.dart, reply_utils.dart, extra_settings.dart (appeal reason) | — | ✅ |
| T16 | 446d24c0 + f66a1719 | reply_controller.dart (canSort), main_reply/view.dart, reply_item_grpc.dart, video.dart (relationMod identity), 3 orphan part files deleted (plan-updated guardrail) | — | ✅ |
| T17 | ae03902b | grpc/im.dart (sessionDetail), grpc/url.dart, whisper/widgets/item.dart | — | ✅ |
| T18 | 7d3d522e | video_stein_edgeinfo 4 models, video/controller.dart | — | ✅ |
| T19 | d8ac5b0b | bottom_control_type.dart, pl_player/controller.dart, pl_player/view/view.dart, video/view.dart (stein resume dialog + showStein) | — | ✅ |
| T20 | 7d3d522e | blocked_image_placeholder.dart, image_grid_view.dart, gallery_viewer.dart, report.dart, reply_item_grpc.dart, pubspec.yaml (visibility_detector) | — | ✅ |
| T21 | 7d3d522e | api.dart (liveFeedback), live.dart, live_item_app.dart, card_data_list_item.dart, api_type.dart | — | ✅ |
| T22 | 7d3d522e | header_control.dart, ugc/view.dart, pgc/view.dart, extra_settings.dart (enableQuickShare/quickShareId). request_utils.dart **untouched** — pmShare pre-existed at baseline (T3 audit confirmed); only onLongPress wiring was needed | — | ✅ |
| T23 | 7d3d522e | history/widgets/item.dart, page_utils.dart (viewPgc progress), block_mixin.dart, extra_settings.dart (suppressSponsorBlockIncognito) | — | ✅ |
| T24 | 8723476f9 | fab_mixin.dart, dynamics/controller+view, home/controller+view, common_dyn_page.dart | article/match_info/music/dynamics_detail view.dart — `fabAnimWrapper(child:)` signature adaptation (FAB refactor collateral, A mixin uses named param) | ✅ |
| T25 | 8723476f9 | pl_player/controller.dart (fastForBackwardDuration_), pl_player/view/view.dart (long-press/HDR) | — | ✅ |
| T26 | 8723476f9 | download/search/controller.dart (UP filter), save_panel/view.dart (forceShowOriginalContent) | — | ✅ |
| T27 | 8723476f9 + 2b06e01d | iterable_ext.dart (insertOrAdd), page_utils.dart (viewPugv progress), content_panel.dart + reply_item_grpc.dart ("打开" native menu), test/utils/selectable_region_ext_test.dart deleted, extension_test.dart comment sync | — (plan T27 explicitly mandates NOT porting A's original ext; Batch 0 decision) | ✅ |
| T28 | 8723476f9 | extra_settings.dart (AI/translate/appeal/image-path/quick-share/HK), model.dart (getSaveImgPathModel), setting/view.dart, login/controller.dart (accountDisplayName switcher) | — | ✅ |
| T29 | 8723476f9 | video.dart (videoPush redirect), pl_player/controller.dart + view/view.dart (hideStatusBar), login nickname via T10 login_utils/mine setAccountUname + T28 switcher display | — | ✅ |

**Tasks [25/25 compliant]** — every spec'd file implemented; every changed lib file maps to ≥1 task's What to do.

---

## 2. Out-of-Scope Exclusions — 0 Additions (user-excluded items NOT ported)

Verified via `git diff 886b57dd9..HEAD -S <pattern> --stat` (empty = no additions):

| Excluded category | Pattern(s) | Additions |
|-------------------|------------|-----------|
| Darwin bounce physics | `BouncingScrollPhysicsExt`, `RefreshScrollPhysicsIOS` | **0** ✅ |
| Desktop keyboard selection | `_deletedRange` | **0** ✅ |
| Desktop window management / platform shortcuts | `window_manager` delta, `platform_shortcuts.dart` delta, ShortcutManager/KeyboardListener/LogicalKeyboardKey | **0** ✅ (files untouched) |
| log port | `ProductionFilter`, `PrettyLogPrinter`, services/logger.dart delta | **0** ✅ |
| catch/reporting port | `catcher_2`, `CatcherOptions` | **0** ✅ |
| logs page | logs.dart delta | **0** ✅ (preserved) |
| SelectionText restore | `SelectionText(` in ported lib files | **0** ✅ (only pre-existing vendored engine copies + .pb.dart + `selection_text.dart` widget, all untouched) |
| Desktop platform branches | added `TargetPlatform.macOS/windows/linux`, `Platform.isWindows/Linux/MacOS` | **0** ✅ (only added mobile guard `Platform.isAndroid \|\| OS.isHarmony` in extra_settings.dart T28 image-path — existing OHOS pattern) |

Guardrails (plan Must NOT Have) independently re-verified:
- `text_selection.dart:2921,3044` — file byte-untouched ✅
- 4 「鸿蒙待适配」TODO — all 4 present unchanged ✅
- Protected files (`*.g.dart`, `*.pb*.dart`, GeneratedPluginRegistrant.ets, bindings.g.dart, ohos/build-profile*.json5, pubspec.lock) — 0 touched ✅
- pubspec: only `visibility_detector: ^0.4.0` added (T20-documented; promoted from transitive 0.4.0+2 in lock — no new package in graph; approved in task-20 evidence) ✅

---

## 3. Cross-Task Contamination Check (shared-file serial coordination)

| File | Tasks | Conflict assessment |
|------|-------|---------------------|
| reply_item_grpc.dart | T14 banner / T15 translate+appeal / T16 long-press / T20 comment image block / T27 "打开" menu | **CLEAN** — independent regions (banner flag, translate params, long-press menu, image-block menu, context-menu builder); no logic overwrite |
| pl_player/controller.dart + view/view.dart | T19 stein / T25 shortcuts+fastForBackwardDuration_ / T29 hideStatusBar | **CLEAN** — additive fields/params/GestureDetectors; B media_kit integration untouched |
| init.dart | T10 buvidActive/setCookie / T11 interceptors | **CLEAN** — different methods/regions |
| video.dart | T8 identity / T13 ai-summary / T16 relationMod fp / T29 videoPush | **CLEAN** — separate functions |
| extra_settings.dart | T11 HK/API-host / T13 AI / T15 appeal / T22 quick-share / T23 incognito / T28 umbrella | **CLEAN** — additive list entries, all Pref keys already existed (dead keys reactivated, not renamed) |
| page_utils.dart | T23 viewPgc progress / T27 viewPugv progress | **CLEAN** — two different methods |
| api_type.dart | T5 reply/blacklist routes / T21 liveFeedback | **CLEAN** — additive |
| ugc/view.dart + pgc/view.dart | T13 AI / T22 quick-share long-press | **CLEAN** — additive |

Cross-task note: T16 commit included `relationMod` identity wiring in video.dart (`fp: identity.fpLocal` replacing `BrowserUa.pc`). This is **in-scope for T16** — the long-press blacklist feature uses `relationMod`, and issues.md documented the pre-existing `fp` semantic bug (风控隐患) as a fix-to-do during T16. Not contamination.

**Contamination [CLEAN]** — 0 conflicts.

---

## 4. Unaccounted Changes

| File(s) | Classification |
|---------|----------------|
| lib/AGENTS.md, lib/common/AGENTS.md, lib/models_new/AGENTS.md, lib/pages/AGENTS.md (4 files, in batch4 commit) | **Knowledge-base refresh, documentation only** (0 dart code added). Not in any task's What-to-do; consistent with project doc-KB convention. Benign. |
| .sisyphus/plans/port-a-features.md, .sisyphus/notepads/*.md | Orchestrator process artifacts (checkbox completion, guardrail updates T16/T27, task logs). Expected. |

**Unaccounted [4 files — doc-only AGENTS.md refresh, benign]** — every *code* file in the range maps to a task.

---

## 5. VERDICT

**Tasks [25/25 compliant] | Contamination [CLEAN] | Unaccounted [4 files (doc-only, benign)] | VERDICT: APPROVE**

- All 25 implementation tasks (T5–T29) implemented 1:1 against plan "What to do"; no spec'd file missing, no spec'd feature skipped.
- Zero user-excluded content ported (no desktop branches, no bounce physics, no keyboard-selection, no window/shortcut management, no log, no catcher_2; logs page preserved).
- Shared files show only planned serial coordination — no logic conflicts.
- Only unrecorded deltas are 4 lib AGENTS.md documentation refreshes (no code) + process artifacts.
- Guardrails independently re-confirmed (text_selection untouched, 4 TODO intact, protected files 0, overrides intact).
