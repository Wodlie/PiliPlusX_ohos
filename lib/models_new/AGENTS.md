# lib/models_new/ — Active Data Models

**Overview:** Hand-written JSON data models mirroring Bilibili API responses. 41 subdirs, 493 Dart files. 100% hand-written — no codegen.

## STRUCTURE

```
lib/models_new/
├── space/             # 122 files — user space API surface (space/space/data.dart aggregates 20+)
├── live/              # 50 files — live streaming (live_room_play_info/, live_follow/, live_dm_block/)
├── pgc/               # 46 files — bangumi/PGC (pgc_info_model/ 25 files)
├── video/             # 44 files — video detail, play info (video_detail/ 16 files)
├── fav/               # 43 files — favorites (fav_pgc/ 22 files)
├── msg/               # 29 files — messages/notifications (msg_like/, msg_reply/, msg_at/)
├── article/ + dynamic/ + reply/   # 18 files each
├── bubble/ member/ media_list/ later/ match/ upower_rank/ history/
└── ...~28 more        # 1-7 files each (search, emote, download, follow, blacklist...)
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| New model for an API | `lib/models_new/[api_name]/` | One class per file; `data.dart` aggregates |
| Video detail models | `lib/models_new/video/video_detail/` | `VideoDetailData`, `Part`, `VideoStat` |
| User space models | `lib/models_new/space/space/` | `SpaceData` (composes 20+ sub-models) |
| Comment models | `lib/models_new/reply/` | `ReplyItemModel`, `ReplyMember` |
| Legacy base classes | `lib/models/` | `BaseOwner`, `BaseStat`, `BaseEpisodeItem` (don't add new code there) |
| Dynamic feed (main) | `lib/models/dynamics/` + `lib/utils/page_utils.dart` | type discriminators (`DYNAMIC_TYPE_AV`) — NOT in models_new |

## CONVENTIONS

- **Hand-written JSON**: plain Dart class + `factory Xxx.fromJson(Map<String, dynamic> json) =>` (arrow style, ~463 files). ~30 files use block-body named constructor + initializer list instead (e.g. `SpaceData`)
- **NO** `@JsonSerializable`, `@freezed`, `@JsonKey`, `Equatable`, `part '*.g.dart'` — zero in models_new
- **fromJson-only**: no `toJson` except `download/` models and a few `live/` (persistence needs)
- **One class per file**, lowercase_snake_case file per class; each subdir has a `data.dart` root aggregating siblings
- **Field mapping**: JSON snake_case → camelCase Dart field (`desc_v2` → `descV2`); explicit null checks on nested objects
- **Dual ID pattern**: Bilibili sends `int` + `String` IDs (`mid`/`midStr`, `rpid`/`rpidStr`) — keep both (JS int precision workaround)
- **Response envelope**: `code`/`message`/`ttl` modeled explicitly (`VideoDetailResponse`)
- Class naming is inconsistent (`ReplyItemModel`, `PgcInfoModel`, but plain `Part`, `Owner`) — match the surrounding subdir

## ANTI-PATTERNS

- **Don't** add `json_serializable`/`freezed` to new models — hand-write `fromJson` (project convention)
- **Don't** edit legacy `lib/models/` (frozen; only 3 `.g.dart` files live there)
- **Don't** move main dynamic-feed models here — they stay in `lib/models/dynamics/`
- **Don't** add `toJson` unless the model must be persisted
- **Don't** import with relative paths — `package:PiliPlus/models_new/...`

## NOTES

- 37 files import legacy types from `package:PiliPlus/models/` — models_new is NOT isolated (extends `BaseOwner`/`BaseEpisodeItem`/`HorizontalVideoModel`)
- Base classes defined locally: `BaseEpisodeItem` (video/video_detail/episode.dart), `SubItemModel` (sub/sub/list.dart)
- `stat_detail.dart` is the only `abstract class` in the tree
- Subdir name = Bilibili API surface name (video_detail, live_room_play_info, pgc_info_model)
