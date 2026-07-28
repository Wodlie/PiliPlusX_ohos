# OHOS Known Gaps

Tracked gaps where Android-specific APIs are not available on OpenHarmony.
Methods should be guarded with `if (!OS.isHarmony && Platform.isAndroid)`.

## AndroidHelper (lib/utils/android/android_helper.dart)

| Method | Status | Notes |
|--------|--------|-------|
| `biliSendCommAntifraud()` | ⛔ Stub | Anti-fraud metadata for comment/reply posting. No OHOS equivalent. Stub throws `UnsupportedError`. |
| `back()` | ⛔ Stub | Android system back gesture. Not available on OHOS (use Navigator directly). Stub throws `UnsupportedError`. |
| `openLinkVerifySettings()` | ⛔ Stub | Android link verification settings. Not available on OHOS (links handled by system browser). Stub throws `UnsupportedError`. |

## Methods not yet stubbed (will be added per-task)

Additional `AndroidHelper` / `PiliAndroidHelper` methods from upstream that need stubs
when their call sites are ported:

- `isFoldable` — foldable device detection
- `isPipAvailable` — PiP availability check
- `isPipMode` — PiP mode state
- `sdkInt()` — Android SDK version
- `enterPip(...)` — Picture-in-Picture mode
- `disableAutoEnterPip()` — Disable automatic PiP
- `updatePipActions(...)` — Update PiP action buttons
- `maxScreenSize()` — Get max screen dimensions
- `openMusic(...)` — Open system music player
- `createShortcut(...)` — Create home screen shortcut

## Non-AndroidHelper Gaps

| Gap | Location | Notes |
|-----|----------|-------|
| (reserved for future gaps) | | |
