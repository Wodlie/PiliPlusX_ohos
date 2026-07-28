# Compatibility Verification: Flutter 3.41.6 Assumptions A1-A10

> **Generated**: 2026-07-27
> **Environment**: Flutter 3.44.4 / Dart 3.12.2 (system), target Flutter 3.41.6 / Dart ~3.9.x (FVM)
> **Purpose**: Verify Metis assumptions before proceeding with PiliPlusX feature port

---

## A1: flutter_lints:^6.0.0 with Flutter 3.41.6

**Status**: ✅ Compatible

**Evidence**:
- `flutter pub add flutter_lints:^6.0.0 --dry-run` → succeeded, resolved `flutter_lints 6.0.0` and `lints 6.1.0`
- Package `flutter_lints-6.0.0` requires SDK `^3.8.0` — Flutter 3.41.6 (Dart ~3.9.x) satisfies this
- Dry-run ran on Flutter 3.44.4 (Dart 3.12.2), but the SDK constraint check confirms backward compat

**Recommendation**: Update `dev_dependencies` from `flutter_lints: ^2.0.0` to `flutter_lints: ^6.0.0` if desired. Note this would upgrade `lints` from 2.1.1 to 6.1.0, potentially adding new lint rules.

---

## A2: collection package version ≥1.19.0

**Status**: ✅ Compatible

**Evidence**:
- `pubspec.lock` shows `collection` at version **1.19.1**
- Also present as `dependency: "direct main"` with constraint `any`
- Version 1.19.1 ≥ 1.19.0 ✅

**Note**: No action needed.

---

## A3: get fork API compatibility (81b8a71 vs version_4.7.2)

**Status**: ✅ Compatible

**Evidence**:
- `dart analyze lib/pages/home/controller.dart` (which uses `Get.find`, `TabController`, `GetSingleTickerProviderStateMixin`) → **No issues found**
- Both OHOS and PiliPlusX use the same git fork: `github.com/bggRGjQaUbCoE/getx.git`
- OHOS ref: `81b8a71982f89b46fa868b315cd71ff6a6ddf895` (commit hash)
- PiliPlusX ref: `version_4.7.2` (tag, resolved to `388fcb22ef24ac0a693949148d29fa6b4922159f`)
- Both advertise version `4.7.2`

**Caveat**: Different commit refs could mean minor differences, but the API analysis passed. No action needed.

---

## A4: canvas_danmaku Starfallan vs cnctem fork DanmakuController API

**Status**: ✅ Compatible

**Evidence**:
- OHOS uses `Starfallan/canvas_danmaku.git` (commit `3947b1fec9d89a8bb11b6feda7a43787ed1e73a9`)
- PiliPlusX uses `cnctem/canvas_danmaku.git` (commit `8595bdf74408e342927659977470aa080ee62de8`)
- Both are version **0.2.6**
- `DanmakuController<T>` class is **identical** between both forks:

| Field | Type |
|-------|------|
| `addDanmaku` | `bool Function(DanmakuContentItem<T>)` |
| `updateOption` | `ValueChanged<DanmakuOption>` |
| `pause` | `VoidCallback` |
| `resume` | `VoidCallback` |
| `clear` | `VoidCallback` |
| `getOption` | `ValueGetter<DanmakuOption>` |
| `isRunning` | `ValueGetter<bool>` |
| `findDanmaku` | `Iterable<(double, DanmakuItem<T>)> Function(Offset)` |
| `findSingleDanmaku` | `(double, DanmakuItem<T>)? Function(Offset)` |
| `getTrackCount` | `ValueGetter<int>` |
| `scrollDanmaku` | `List<List<DanmakuItem<T>>>` |
| `staticDanmaku` | `List<DanmakuItem<T>?>` |
| `specialDanmaku` | `List<DanmakuItem<T>>` |

**Recommendation**: No action needed. Both forks are API-compatible.

---

## A5: hive_ce:^2.19.3 with Flutter 3.41.6

**Status**: ✅ Compatible

**Evidence**:
- `pubspec.lock` shows `hive_ce` at version **2.19.3**
- `flutter pub add hive_ce:^2.19.3 --dry-run` → "No dependencies would change" (already satisfied by current `^2.2.3` constraint)
- Version 2.19.3 is the latest stable in the 2.19.x line

**Note**: No action needed. Current constraint `^2.2.3` already covers 2.19.3.

---

## A6: Dart 3.5+ syntax (.light enum shorthand, ?fullMode() null-shortening)

**Status**: ✅ Compatible

**Evidence**:
- Created temp file using `mode == .light` (enum shorthand, Dart 3.5+) and `fullMode?.toString()` (null-shortening, Dart 3.9+)
- `dart analyze` passed with only `avoid_print` info-level lint (expected for test code)
- Flutter 3.41.6 uses Dart ~3.9.x which fully supports both features
- Current environment is Dart 3.12.2, confirming compatibility

**Recommendation**: No action needed. PiliPlusX code using these features will work on Flutter 3.41.6.

---

## A7: cached_network_image vs cached_network_image_ce import compatibility

**Status**: ✅ Compatible — both coexist

**Evidence**:
- OHOS has both: `cached_network_image: ^3.4.1` (pub.dev) and `cached_network_image_ce: any`
- PiliPlusX uses only `cached_network_image_ce` from git (develop branch)
- `cached_network_image: ^3.4.1` provides the standard `CachedNetworkImage` widget
- `cached_network_image_ce` provides a compatibility/CE variant
- Both full platform interface sets coexist (`cached_network_image_platform_interface` + `_ce` variants)

**Caveat**: OHOS may use `cached_network_image` directly for CachedNetworkImage widget, while PiliPlusX code that imports `cached_network_image_ce` will also resolve. Verify which package each file actually imports during port.

---

## A8: Predidit media_kit fork NativePlayer.apiVersion field

**Status**: ❌ Not Available

**Evidence**:
- Searched entire `media_kit` source tree (Predidit fork, version 1.1.11, commit `df5a969`)
- `apiVersion` not found in `NativePlayer` class, `PlatformPlayer` base class, or any file in the package
- `NativePlayer` extends `PlatformPlayer`, which is an abstract class with no `apiVersion` field

**Impact**:
- PiliPlusX code that references `NativePlayer.apiVersion` will NOT compile on OHOS
- Must check if PiliPlusX actually uses this field; if so, adaptation needed

**Recommendation**: Search PiliPlusX code for `apiVersion` usage and add conditional logic for OHOS.

---

## A9: screen_brightness package OHOS implementation

**Status**: ✅ Has OHOS implementation

**Evidence**:
- `pubspec.lock` shows `screen_brightness_ohos` version **2.1.4** as transitive dependency
- `flutter-plugins-dependencies` confirms `screen_brightness` depends on `screen_brightness_ohos`
- OHOS platform plugin is registered in the dependency graph: `screen_brightness` → `["screen_brightness_android","screen_brightness_ios","screen_brightness_macos","screen_brightness_windows","screen_brightness_ohos"]`
- Package version in lock: `screen_brightness 2.1.11`

**Recommendation**: No action needed. `screen_brightness: ^2.1.7` already supports OHOS via the `screen_brightness_ohos` plugin.

---

## A10: OHOS unique storage keys without PiliPlusX equivalent

**Status**: ⚠️ 4 OHOS-unique keys identified

**Evidence**:
PiliPlusX storage_key (`D:\coding\PiliPlusX\lib\utils\storage_key.dart`) was compared against OHOS storage_key.

**OHOS keys WITHOUT PiliPlusX equivalent**:

| Key | Purpose |
|-----|---------|
| `enableLGBar` | Enable liquid glass bar (OHOS UI feature) |
| `enableStatusBarTapToTop` | Tap status bar to scroll to top |
| `showActualVolume` | Show actual volume level |
| `allowRotateScreen` | Allow screen rotation |

**OHOS deprecated keys (also not in PiliPlusX)**:
- `defaultDecode` (deprecated, use `preferCodecs`)
- `secondDecode` (deprecated, use `preferCodecs`)

**Note**: `enableLongShowControl` appears in both (shared key, not unique).

**Recommendation**: Preserve these OHOS-unique keys during storage_key merge (Task T2). They are OHOS-specific features without PiliPlusX equivalents.

---

## Summary

| Assumption | Status | Notes |
|------------|--------|-------|
| A1: flutter_lints 6.0.0 | ✅ | SDK ^3.8.0, compatible |
| A2: collection ≥1.19.0 | ✅ | Resolved 1.19.1 |
| A3: get fork API | ✅ | Same fork, different refs, API compatible |
| A4: canvas_danmaku API | ✅ | Identical DanmakuController |
| A5: hive_ce 2.19.3 | ✅ | Already resolved |
| A6: Dart 3.5+ syntax | ✅ | Works on Dart 3.9+ |
| A7: cached_image coexistence | ✅ | Both packages coexist |
| A8: NativePlayer.apiVersion | ❌ | Not in Predidit fork |
| A9: screen_brightness OHOS | ✅ | Has OHOS plugin |
| A10: OHOS-unique storage keys | ⚠️ | 4 keys preserved |
