# Task 21 — 恢复直播"不感兴趣"反馈

**Date:** 2026-08-01
**Status:** Done

## Objective
Restore live feed "不感兴趣" (dislike) feedback: `Api.liveFeedback` + `LiveHttp.liveFeedback` + card feedback button, porting from A (PiliPlusX) into B (PiliPlusX_ohos). No file copying — rewritten as needed.

## Changes

| File | Change |
|------|--------|
| `lib/http/api.dart` | Added `liveFeedback` const: `${HttpString.liveBaseUrl}/xlive/app-interface/v2/index/feedback` |
| `lib/http/live.dart` | Added `LiveHttp.liveFeedback(roomId, id, type, {page})` — app-signed GET to `Api.liveFeedback`, returns `LoadingState<void>` |
| `lib/models_new/live/live_feed_index/card_data_list_item.dart` | Added `List<Feedback>? feedback` field + fromJson parse (model file `feedback.dart` already existed in B) |
| `lib/pages/live/widgets/live_item_app.dart` | Wrapped Card in Stack; added `more_vert` feedback IconButton (bottom-right) showing SimpleDialog of feedback reasons; on tap submits via `LiveHttp.liveFeedback` with SmartDialog loading/toast |
| `lib/utils/accounts/api_type.dart` | Added `Api.liveFeedback` to `AccountType.recommend` route table (after `Api.liveSearch`) — T5 had NOT added it because the const didn't exist yet |

## Constraints honored
- B's live.dart existing implementations (`liveMedalWall`, `sendLiveMsg`, OHOS adaptations) untouched — method appended at end of class
- B's card structure preserved (AspectRatio + LayoutBuilder + AnimatedOpacity videoStat) — only outer Stack + Positioned button added, matching A's placement
- No new dependencies (`flutter_smart_dialog`, `get`, `SearchText`, `iterable_ext` already present in B)
- No desktop branch added
- No `*.g.dart` / `*.pb*.dart` edited

## Verification
```
dart analyze --no-fatal-warnings  →  31 errors (baseline preserved)
```
- Zero errors in touched files (`api.dart`, `live.dart`, `live_item_app.dart`, `api_type.dart`, `card_data_list_item.dart`)

## Evidence
- A refs: `lib/http/live.dart:773-808`, `lib/http/api.dart:1022-1023`, `lib/pages/live/widgets/live_item_app.dart:71-152`, `lib/utils/accounts/api_type.dart:91`
- B pre-state: `liveFeedback` grep → 0 matches (fully removed)
- `feedback.dart` model already present in B (unused) — field re-wired only
