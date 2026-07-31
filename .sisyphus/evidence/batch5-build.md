# Batch 5 — Build Verification Report (Task 30)

**Date:** 2026-08-01
**Task:** port-a-features Task 30 — full `dart analyze` + `flutter build hap` attempt after Batch 1–4 ports
**Repo:** D:\coding\PiliPlusX_ohos
**HEAD:** `2b06e01d1 verify(batch5): wiring 19/19, guardrails clean, smoke passed`
**Method:** read-only verification; no source files modified (only `pubspec.lock` churn from ohos `pub get`, restored)

---

## 1. dart analyze — 23 errors (baseline, no new)

Command: `dart analyze --no-fatal-warnings` (global Dart 3.12.2 / Flutter 3.44.4)

**Result: 23 errors — EXACTLY matches the known baseline (6 vendored engine patches + 17 test/ RED). ZERO new errors.**

Error distribution:

| Count | File | Category | Detail |
|------:|------|----------|--------|
| 3 | `lib/common/widgets/flutter/text_field/editable_text.dart` | vendored engine patch (3.32.4-ohos) | `ExtendSelectionByPageIntent` undefined — compiles only under OHOS engine |
| 3 | `lib/common/widgets/flutter/vertical_slider.dart` | vendored engine patch | `TargetPlatform.ohos` undefined on standard SDK |
| 7 | `test/connectivity_utils_test.dart` | test/ RED (known baseline) | `checkConnectivity`/`isNone`/`isWifi`/`isMobile`/`onConnectivityChanged` not ported |
| 6 | `test/android_helper_test.dart` | test/ RED (known baseline) | `AndroidHelper` undefined |
| 4 | `test/platform_utils_test.dart` | test/ RED (known baseline) | `isDarwin`/`isHarmony` undefined |

**All 23 errors are in the 2 vendored engine-patch files + 3 known test/ files. No errors in ANY ported `lib/` file → no port-caused compile bugs.**

Other totals: 39 warnings (all pre-existing categories — vendored `unreachable_switch_case`/`undefined_hidden_name`, A-verbatim `unreachable_switch_case` in ai_conclusion, orphan-part `unused_import`, test RED `unused_import`, `identity_generators` unused_field) + 209 info. Total 271 issues.

**Warning distribution (39, all known):**
- vendored engine copies: `selectable_region.dart` (2), `text_field.dart` (2), `adaptive_text_selection_toolbar.dart` (1), `editable_text.dart` (1)
- A-verbatim: `video/ai_conclusion/view.dart` (1), `video/view.dart` (1), `member_profile/view.dart` (2)
- pre-existing lib: `identity_generators.dart` (5), `theme_utils.dart` (4), `block_filter_settings.dart` (2), `storage_pref.dart` (1), `shortcut_keys_dialog.dart` (1), `dynamics_mention/view.dart` (1), `live_room/view.dart` (1)
- test/ RED files (8 files, 14 warnings)

**No new warnings introduced by Batch 1–4 ports.**

---

## 2. flutter build hap — FAILED: ENVIRONMENT (no HOS SDK), NOT code

### 2.1 Environment check summary

| Item | Status | Detail |
|------|--------|--------|
| `ohos/build-profile.json5` | ✅ present | committed template copied; signingConfigs `[]` (unsigned), SDK 5.0.3(15), arm64-v8a |
| `.vscode/env.json` | ✅ present | 206 bytes (build_env.dart output) |
| Global Flutter | ❌ standard 3.44.4 | `flutter build --help` lists only `apk` — **no `hap` target** |
| `D:\Program\Flutter\flutter-ohos` | ✅ present | **Flutter 3.41.10-ohos-0.0.2-beta** — supports `hap` target (matches B's declared environment family) |
| HOS SDK (`HOS_SDK_HOME`) | ❌ **absent** | env var unset; no DevEco Studio, no `hdc`, no `command-line-tools` SDK anywhere on machine |

### 2.2 Actual build attempt (with OHOS Flutter SDK)

Command:
```
D:\Program\Flutter\flutter-ohos\bin\flutter.bat build hap --release --dart-define-from-file=.vscode/env.json
```

**Stage 1 — pub get: ✅ SUCCESS.** All 231 dependencies resolved; all 34 git overrides (media_kit forks, audio_service, video_player, url_launcher, inappwebview, etc.) fetched correctly.

**Stage 2 — SDK discovery: ❌ FAILED (environment, before any Dart compilation).**
```
[!] No Hmos SDK found. Try setting the HOS_SDK_HOME environment variable.
```

The build terminated at OHOS SDK discovery — it never reached Dart kernel compile or hvigor. This is a **pure environment gap** (missing HarmonyOS SDK/DevEco Studio on this machine), **not a code error**.

### 2.3 Code-vs-environment distinction

- **Environment cause, confirmed:** failure message is `No Hmos SDK found` — toolchain discovery, not compilation.
- **No code-caused compile errors:** the only compile-equivalent signal available on this machine (`dart analyze`, §1) shows **0 errors in any ported lib/ file**; the 23 errors are all the known baseline (vendored engine patches + test RED). The global standard-SDK run confirms the ported code is analyzable; the OHOS fork couldn't run analyze because it also gates on HOS SDK.
- **CI is authoritative** for the actual .hap artifact (GitHub Actions runs with `oh-3.41.9-release` + HarmonyOS SDK). This machine's build limitation must NOT be read as a port failure.

### 2.4 Housekeeping

- `pubspec.lock` was rewritten by the ohos `flutter pub get` (280+/264- churn, mirror URL + resolution noise) → **restored via `git checkout -- pubspec.lock`** (T14/T27 gotcha). Working tree clean w.r.t. source.

---

## 3. Guardrails — quick re-check (T32 detailed, this task re-verifies key items)

| Guardrail | Result | Evidence |
|-----------|--------|----------|
| `SelectionText(` no leak in ported lib | ✅ PASS | Recursive grep: only (a) widget *definition* `lib/common/widgets/selection_text.dart:4` (pre-existing, init commit), (b) generated `v1.pb.dart` (excluded), (c) framework copies. **0 hits in files touched by port commits.** |
| `text_selection.dart:2921,3044` comments intact | ✅ PASS | Line 2921: `// //  TODO 直接注释掉的代码 3.32.4-ohos-0.0.1不支持`; Line 3044: identical. Both commented handle-drag blocks present. |
| Protected files untouched | ✅ PASS | `git log --name-only` for last 10 commits: **0 matches** for `*.g.dart`, `*.pb*.dart`, `*.pbjson.dart`, `GeneratedPluginRegistrant.ets`, `bindings.g.dart`. |
| git overrides preserved | ✅ PASS | 34 `git:`-sourced overrides present (17 in `dependencies:`, 17 in `dependency_overrides:`); only pubspec change in port range = `+ visibility_detector: ^0.4.0` (T20, plan-approved). |
| SDK constraint unraised | ✅ PASS | `sdk: ">=3.11.1"` + `flutter: ">=3.41.9"` unchanged. |

---

## 4. Verdict

- **analyze:** 23 errors = baseline exactly (6 vendored + 17 test RED). **No new errors, no port bugs** requiring code fixes.
- **hap build:** blocked by **environment** (no HOS SDK on this machine; global Flutter is standard 3.44.4). The OHOS fork `3.41.10-ohos-0.0.2-beta` supports `hap` but requires `HOS_SDK_HOME`. Pub resolution succeeded (231 deps), proving dependency graph is intact. No code-caused compile failure — CI (oh-3.41.9-release + HOS SDK) remains authoritative for the .hap artifact.
- **Guardrails:** all re-checked items PASS.
- **No code fixes required** — no non-baseline errors surfaced.
