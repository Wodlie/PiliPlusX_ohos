# lib/common/ — Shared Widgets & Constants

**Overview:** Reusable UI layer — 137 widgets + skeleton placeholders + constants. Pure presentation: **no state management, no networking, no settings** (those live in `lib/utils/`).

## STRUCTURE

```
lib/common/
├── constants.dart       # App keys, user-agents, headers (API base config)
├── assets.dart          # Static asset path constants
├── style.dart           # Design tokens: spacing, radii, aspect ratios (topBarHeight 52)
├── dial_prefix.dart     # Country dial codes (login)
├── skeleton/            # 11 loading placeholders (one per card type: video_card_h/v, dynamic_card, reply...)
├── utils/               # status_bar_tap.dart — StatusBarTapObserver (scroll-to-top)
└── widgets/             # 137 files — the widget library
```

## widgets/ MAP

| Dir | Files | Content |
|-----|-------|---------|
| *(root)* | 46 | standalone: `VideoPopupMenu`, `FloatingNavigationBar`, `MarqueeText`, `PendantAvatar`, `RadioWidget`, `ScaleApp`, `Pair`/`Triple`, `NetworkImgLayer`, `ExtraHitTestStack`... |
| `flutter/` | 38 | **Embedded Flutter framework patches** — RichTextField, CustomTabBarView, EditableText, SelectableText, PopupMenu, RefreshIndicator, VerticalTabBar, ChatListView (3.32.4-ohos adaptations) |
| `video_card/` | 2 | `VideoCardV` (vertical feed card) + `VideoCardH` (horizontal) |
| `image/` | 4 | `NetworkImgLayer`, `CachedNetworkSVGImage`, `ImageSave`, `BlockedImagePlaceholder` |
| `image_viewer/` | 6 | Fullscreen `Viewer`, `GalleryViewer`, Hero + `HeroDialogRoute` |
| `image_grid/` | 2 | `ImageGridBuilder` (custom RenderObject grid) |
| `sliver/` | 6 | Pinned/floating headers, `VideoHeader`, `TrendingHeader` |
| `progress_bar/` | 3 | `ProgressBar` (scrub), `SegmentProgressBar` (danmaku density), `VideoProgressIndicator` |
| `loading_widget/` | 4 | `LoadingWidget` (SmartDialog loader), `Morphs`, `HttpError` (error+retry) |
| `dialog/` + `context_menu/` + `button/` | 11 | Dialogs, per-context menus (dynamic/reply/live), buttons |
| `draggable_sheet/` + `dynamic_sliver_app_bar/` | 5 | Bottom sheets, collapsing app bars |
| `gesture/` | 6 | Custom recognizers, `MouseInteractiveViewer` (desktop zoom/pan) |
| `svg/` + `stat/` + `appbar/` | 4 | Painted icons, `StatWidget`, `MultiSelectAppBarWidget` |

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Reusable widget | `lib/common/widgets/` | Match existing subdir; add file there |
| Feed card | `lib/common/widgets/video_card/` | `VideoCardV`/`VideoCardH` |
| Loading state UI | `lib/common/widgets/loading_widget/` | `HttpError` + `LoadingWidget` |
| Framework-level patch | `lib/common/widgets/flutter/` | **Read NOTES first — OHOS engine constraints** |
| Skeleton loader | `lib/common/skeleton/` | One file per feed/card type |
| Design token | `lib/common/style.dart` | Radii, spacing, bar heights |

## CONVENTIONS

- Pure widgets + constants — **no controllers, no Hive, no dio** in this layer
- Network images go through `NetworkImgLayer`/`CachedNetworkSVGImage` (caching + placeholder handling)
- Keep widgets generic; page-specific logic belongs in `lib/pages/`
- `Style` class is the single source of spacing/radius tokens — don't hardcode

## ANTI-PATTERNS

- **Don't restore commented-out code** in `flutter/text_field/text_selection.dart:2921,3044` — unsupported by OHOS Flutter engine 3.32.4-ohos
- **Don't edit** `flutter/**` framework patches without marking `// ↓↓↓ 适配flutter 3.32.4-ohos-0.0.1` / `// ↑↑↑` paired markers
- **Don't** add state/logic to `lib/common/` — move to `lib/pages/` or `lib/utils/`
- **Don't** duplicate widgets that already exist here (search first — 137 files)

## NOTES

- `flutter/` subdir = embedded Flutter framework copies (RichTextField, tabs, text_field) with OHOS adaptations — upstream sync will overwrite, keep adaptation markers
- Global theming lives in `lib/utils/theme_utils.dart` + `lib/utils/bili_colors.dart`, NOT here
- Settings persistence (`Pref`, Hive) lives in `lib/utils/`, NOT here
