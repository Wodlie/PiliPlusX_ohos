# Batch 5 — Guardrails Integrity Report (Task 32)

**Date:** 2026-08-01
**Baseline commit:** `886b57dd9` (batch0 recon)
**Port commit range:** `50039f462..8723476f9` (T5–T29, 16 commits)
**Repo:** D:\coding\PiliPlusX_ohos
**Method:** pure inspection — zero file modifications

---

## 1. OHOS Preservation Assertions

| # | Assertion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | `SelectionText(` 0 hits in **ported** lib files | ✅ PASS | Recursive grep for `SelectionText(` in all lib/ files found only: (a) widget *definition* at `lib/common/widgets/selection_text.dart:4` — pre-existing (init commit `5a4dd671f`), **untouched** in port range; (b) `getSelectionText(` method names in pre-existing Flutter framework copies `text_field/controller.dart:1036`, `editable_text.dart:2506,2552`; (c) generated protobuf `v1.pb.dart:2425-2429` (excluded from analysis). Zero `SelectionText(` in any file touched by port commits. |
| 2 | No NEW `TargetPlatform.macOS/windows/linux` in lib/ | ✅ PASS | `git diff 886b57dd9..HEAD --unified=0 -- lib` filtered for added lines `^\+.*TargetPlatform\.(macOS|windows|linux)` = **EMPTY**. All current hits live in pre-existing `lib/common/widgets/flutter/**` copies, pre-existing `platform_shortcuts.dart` (untouched), and `dynamics_detail/view.dart:37-39` (confirmed byte-identical to baseline; only change in that file = `fabAnimWrapper(child: child)` at line 510). `Platform.isWindows/Linux/MacOS` added lines = EMPTY. |
| 3 | `text_selection.dart:2921,3044` commented code intact | ✅ PASS | Line 2921: `// //  TODO 直接注释掉的代码 3.32.4-ohos-0.0.1不支持` + commented `_isDraggingStartHandle`/`DragStartDetails` block. Line 3044: identical comment block for `_isDraggingEndHandle`. File byte-untouched in port range (`git diff --name-only` = empty). |
| 4 | `@Deprecated` defaultDecode/secondDecode preserved | ✅ PASS | `storage_pref.dart` byte-untouched in port range (1001 lines before == 1001 after, region identical). Getters at lines 306/312 carry `/// Deprecated: use [preferCodecs] instead. Kept for OHOS compatibility.` doc comments identical to baseline. `@Deprecated(` on `buvid` getter (line 1161) identical. Nothing removed/changed. |
| 5 | 4 「鸿蒙待适配」TODOs unchanged | ✅ PASS | Baseline 4 .dart occurrences == current 4, same files & text (line numbers shifted by added code): `main.dart:219` 异常捕获, `video/view.dart` (1951→2225) ai总结拖拽, `pl_player/controller.dart` (444→447) strokeStyle, `account_mgr.dart` (259→305) Connectivity. `lib/AGENTS.md` 5th hit is doc text, not code. |

**All 5 OHOS preservation assertions PASS.**

---

## 2. Protected Files — 0 Touched

Command: `git log 886b57dd9..HEAD --name-only` filtered for protected patterns.

| Protected pattern | Result | Evidence |
|-------------------|--------|----------|
| `*.g.dart` (legacy models ×3) | ✅ UNTOUCHED | `model_owner.g.dart`, `user/info.g.dart`, `user/stat.g.dart` — no commit in range touches them |
| `lib/grpc/bilibili/**/*.pb*.dart` | ✅ UNTOUCHED | Zero commits touch `lib/grpc/bilibili/**` |
| `ohos/entry/src/main/ets/plugins/GeneratedPluginRegistrant.ets` | ✅ UNTOUCHED | Zero commits touch `ohos/**` at all |
| `lib/utils/android/bindings.g.dart` | ✅ UNTOUCHED | No commit in range |
| `ohos/entry/build-profile.json5` abiFilters | ✅ UNTOUCHED | `abiFilters: ["arm64-v8a"]` + x86 excludes intact; file untouched |
| `ohos/build-profile.json5` (gitignored signing) | ✅ UNTOUCHED | Not in any port commit |
| `pubspec.lock` | ✅ UNTOUCHED | No commit in range |

**All protected files: 0 touches.**

---

## 3. Dependency Override Integrity

| Assertion | Result | Evidence |
|-----------|--------|----------|
| pubspec.yaml change set minimal | ✅ PASS | `git diff 886b57dd9..HEAD -- pubspec.yaml` = **single addition**: `+ visibility_detector: ^0.4.0` (plan-approved, Task 20). Nothing removed/rewritten. |
| gitcode overrides preserved | ✅ PASS | `gitcode.com` count current == baseline == **13**. dependency_overrides has 24 entries (17 git-sourced), all intact. |
| No upstream media_kit/audio_service/video_player/url_launcher mixed in | ✅ PASS | `audio_service` → gitcode `fluttertpc_audio_service.git` (OHOS fork); `# audio_service: ^0.18.15` upstream line commented out. `media_kit*` overrides → `github.com/cnoim/media-kit` `feat-ohos` fork + `github.com/My-Responsitories/media-kit` `version_1.2.5` (pre-existing upstream-specified). `video_player`/`url_launcher` → gitcode `openharmony-tpc/flutter_packages.git` (OHOS forks). No plain pub.dev version present for any of the 4 in overrides. |
| SDK constraint not raised | ✅ PASS | Baseline `sdk: ">=3.11.1"` + `flutter: ">=3.41.9"` == current, identical. |

**Dependency overrides: all intact, no upstream contamination, SDK pinned at 3.41.9.**

---

## 4. Non-Protected Working-Tree Changes (pre-existing, out of scope)

Uncommitted changes present in working tree **before** this task (no port commit involvement; none touch protected files):
- `AGENTS.md`, `ohos/AGENTS.md` — knowledge-base refresh (2026-07-31), pre-existing
- `test/utils/extension_test.dart` (edit), `test/utils/selectable_region_ext_test.dart` (deleted) — Task 27 selectable_region_ext removal, pre-existing
- `.sisyphus/notepads/*`, `.sisyphus/boulder.json` — orchestrator state

---

## 5. Verdict

**ALL ASSERTIONS PASS.** No guardrail violations detected across OHOS preservation (5/5), protected files (0 touched), and dependency overrides (~37 git overrides intact, no upstream mix, SDK unraised).

Remaining verification tasks: T30 (analyze/hap) and T31 (symbol wiring) are separate deliverables.
