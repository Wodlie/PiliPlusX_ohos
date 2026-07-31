# lib/pages/ — UI Layer

**Overview:** All app pages. 115 page dirs, 453 Dart files. GetX controllers per page; shared base State classes.

## STRUCTURE

```
lib/pages/
├── main/                 # Root shell: MainApp, bottom nav hosting home/dynamics/mine tabs
├── home/                 # Home feed tab (inner TabBar of feed sections)
├── video/                # Video detail page (46 files — largest page) + sub-features
├── setting/              # Settings hub (40 files) + ~15 sub-pages
├── dynamics/             # Dynamics feed tab
├── fav/                  # Favorites hub (video/pgc/note/article children)
├── search_panel/         # Search results hub (all/video/live/user/article/pgc)
├── live/ + live_room/    # Live homepage; live room player
├── member/ + member_*    # User space home + 18 per-tab pages (video, article, coin, opus...)
├── common/               # Shared page bases + controllers (see CONVENTIONS)
├── msg_feed_top/         # Notifications (at_me/reply_me/like_me/sys_msg)
├── whisper/              # Private messages
├── download/             # Offline download manager
└── ...90+ more           # 1-5 files each: search, history, later, pgc, music, article, login, rank, hot...
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a page | `lib/pages/[name]/view.dart` + `controller.dart` | Then register route in `lib/router/app_pages.dart` |
| Comment/reply page | `lib/pages/common/dyn/common_dyn_page.dart` | `CommonDynPageState` + reply FAB, LoadingState list |
| Simple scroll page | `lib/pages/common/common_page.dart` | `CommonPageState<T>` — scroll-sync top/bottom bar hiding |
| Slide/gesture page | `lib/pages/common/slide/common_slide_page.dart` | `CommonSlidePageState` |
| Search result page | `lib/pages/common/search/common_search_page.dart` | `CommonSearchPage` |
| Video detail | `lib/pages/video/` | intro (local/ugc/pgc), reply, related, note, danmaku panel |
| Shared base controllers | `lib/pages/common/` | `CommonListController`, `CommonIntroController`, `ReplyController` |
| Tab/persistent controller | any `Get.putOrFind` call site | e.g. HomePage, MinePage, DynamicsPage |

## CONVENTIONS

- **Page = StatefulWidget**, State extends shared base: `CommonPageState<T>` (most), `CommonDynPageState<T>`/`CommonDynPageMultiState<T>` (comment/reply), `CommonSlidePageState`, `CommonSearchPage`, `CommonPublishPage`
- **Controller = `GetxController`**, bound in view's initState: `Get.put(Controller())` page-scoped (use `tag:`/`heroTag` for multi-instance, e.g. video page); `Get.putOrFind(Controller.new)` for tabs; cross-access via `Get.find<T>()`
- **No `GetView<T>`/`GetWidget<T>` anywhere** — pages use StatefulWidget + base State classes; no GetX `Bindings` classes exist
- **Per-page layout**: `view.dart` + `controller.dart`; nested features in `child/` subdirs or `child_view.dart` (fav/pgc, later, follow); widgets in `widgets/` subdir
- **Views are large** (video/view.dart = 2153 lines) — accepted pattern, don't split for style
- Route names in `lib/router/app_pages.dart` are camelCase (`/videoV`, `/favDetail`); sub-pages often pushed via `Get.to` without routes
- `GetView`-style typing is done via `Get.find<T>()` at use sites — keep explicit types

## ANTI-PATTERNS

- **Don't** wrap the early-return branch in `lib/pages/main/view.dart:67` in `Obx` (throws ObxError)
- **Don't** add pages outside `lib/pages/` — everything UI lives here
- **Don't** bypass GetX routing (`Get.to`/`Get.toNamed`) for page navigation
- **Don't** edit `lib/common/widgets/flutter/**` framework patches from page code (mark OHOS adaptation `// ↓↓↓ 适配flutter`)

## NOTES

- 25 `GetxController` classes across 24 files in pages/; `Get.put` 115×, `Get.putOrFind` 23×, `Get.find` 116×
- Main tabs defined by `NavigationBarType` enum in `lib/models/common/nav_bar_config.dart` (3 tabs: home/dynamics/mine)
- Bottom nav is 4-way switchable (FloatingNavigationBar / M3 NavigationBar / BottomNavigationBar / OHOS native HdsTabs)
- Player engine is NOT here — it's `lib/plugin/pl_player/`; pages/video only orchestrates it
