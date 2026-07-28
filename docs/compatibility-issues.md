# Compatibility Issues: Items Requiring Adaptation

> **Generated**: 2026-07-27
> **Referenced by**: Tasks T9-T43

---

## ❌ A8: NativePlayer.apiVersion not available in Predidit media_kit fork

### Severity: HIGH

**Description**: `NativePlayer.apiVersion` field does not exist in the Predidit media_kit fork (version 1.1.11, commit `df5a969`). The `NativePlayer` class and its base `PlatformPlayer` class have no `apiVersion` field.

**Adaptation Strategy**:
1. Search PiliPlusX codebase for all references to `NativePlayer.apiVersion` or `Player.apiVersion`
2. Where used, add conditional logic:
   ```dart
   // media_kit OHOS fork doesn't have apiVersion
   String get apiVersion => '';
   ```
3. If PiliPlusX code uses `apiVersion` for feature detection, implement a version constant in `harmony_adapt/` instead

**Impact**: Any PiliPlusX code calling `player.apiVersion` will fail to compile on OHOS.

---

## ⚠️ A10: OHOS-unique storage keys preserved during merge

### Severity: MEDIUM

**Description**: 4 OHOS-unique storage keys have no PiliPlusX equivalent. They must be preserved during the storage_key merge (Task T2).

**Keys to preserve**:
| Key | Purpose |
|-----|---------|
| `enableLGBar` | Enable liquid glass bar |
| `enableStatusBarTapToTop` | Tap status bar to scroll to top |
| `showActualVolume` | Show actual volume |
| `allowRotateScreen` | Allow screen rotation |

**Additional deprecated keys**:
- `defaultDecode` (marked `@Deprecated`, use `preferCodecs`)
- `secondDecode` (marked `@Deprecated`, use `preferCodecs`)

**Action**: Ensure these keys survive the storage_key merge in Task T2. Remove `@Deprecated` markers only after all references in OHOS code are cleaned up.

---

## ⚠️ A1: flutter_lints upgrade triggers linting changes

### Severity: LOW

**Description**: Upgrading `flutter_lints` from 2.0 to 6.0 (if done) would also upgrade `lints` from 2.1.1 to 6.1.0, introducing many new lint rules. This could cause hundreds of new lint warnings.

**Recommendation**: Only upgrade `flutter_lints` after all feature porting is complete (during T40: full project analyze). Or defer the upgrade entirely since it's not required for feature parity.

---

## ⚠️ A7: cached_network_image vs cached_network_image_ce import ambiguity

### Severity: LOW

**Description**: Both `cached_network_image` and `cached_network_image_ce` coexist in the OHOS project. Import resolution depends on which package is used in a given Dart file.

**Recommendation**: During file porting (Tasks T9-T43), ensure each file imports the correct package. PiliPlusX files that import `cached_network_image_ce` should continue to do so; OHOS files can use either.
