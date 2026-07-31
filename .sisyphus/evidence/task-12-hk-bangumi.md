# Task 12 QA Evidence — 港澳台番剧（hk_bangumi + media_hk_bangumi + pgc 代理）

**Date:** 2026-07-31
**Plan:** port-a-features
**Branch:** master

## 1. 改动文件清单（7 个）

| File | Change |
|------|--------|
| `lib/models/common/home_tab_type.dart` | 追加 `hk_bangumi('港澳台番剧')`（bangumi 之后、cinema 之前）；`ctr`/`page` 两个 `switch (this)` 表达式均补齐 `hk_bangumi` 分支（Dart 穷尽性） |
| `lib/models/common/search/search_type.dart` | 追加 `media_hk_bangumi('港澳台番剧')`（media_bangumi 之后） |
| `lib/pages/pgc/controller.dart` | `showPgcTimeline` 含 hk_bangumi；`queryPgcTimeline` apiUrl 走 `Pref.apiHKUrl + Api.pgcTimeline`；`queryPgcFollow` type 1 含 hk_bangumi；`customGetData` 加 hk 分支（代理为空 → Error 提示；否则 apiUrl=代理+Api.pgcIndexResult）；补 `http/api.dart` import |
| `lib/pages/pgc/view.dart` | `_buildRcmdTitle` 索引入口加 `\|\| tabType == HomeTabType.hk_bangumi` |
| `lib/pages/search_result/view.dart` | `switch (item)` 的 SearchPgcPanel case 加 `SearchType.media_hk_bangumi` |
| `lib/http/pgc.dart` | `pgcIndex`/`pgcTimeline` 恢复 `required String apiUrl` 参数（替代硬编码 Api 常量） |
| `lib/http/search.dart` | `searchByType` 加 hk 分支：代理为空 → Error；否则 `search_type` 改写为 media_bangumi、api 前缀代理、referer 用改写后 type；switch case 加 media_hk_bangumi；补 `storage_pref.dart` import |

## 2. 枚举 + switch 穷尽性

- `HomeTabType` 现 7 值（live/rcmd/hot/rank/bangumi/hk_bangumi/cinema）。
  - `ctr` switch：`bangumi || hk_bangumi || cinema => Get.find<PgcController>(tag: name)` — 穷尽。
  - `page` switch：`hk_bangumi => const PgcPage(tabType: HomeTabType.hk_bangumi)` — 穷尽。
- `SearchType` 现 7 值（video/media_bangumi/media_hk_bangumi/media_ft/live_room/bili_user/article）。
  - `search_result/view.dart` switch 穷尽：`media_bangumi || media_hk_bangumi || media_ft => SearchPgcPanel`。
  - `http/search.dart` switch 穷尽：case 加 `media_hk_bangumi` → SearchPgcData。
- 其他 `switch (searchType)`（live_search / member_search）均为各自独立枚举（LiveSearchType/MemberSearchType），不受影响。

## 3. 代理默认关闭（T11 就绪）

- `Pref.apiHKUrl` 默认空：`lib/utils/storage_pref.dart:691` → `defaultValue: ''`。
- `HkApiRetryInterceptor` 已在 `lib/http/init.dart:246` 注册。
- hk_bangumi 分支均先判空：`Pref.apiHKUrl.isEmpty → return const Error('请在 设置-其他设置-港澳台代理 中设置代理服务器')`（pgc/controller.dart:152-154、http/search.dart:86-88）。未设置代理时不发起代理请求、tab 显示错误提示。

## 4. 消费点接线

- 首页 tab：`lib/pages/home/controller.dart:72` 默认 `this.tabs = HomeTabType.values` → 自动出现「港澳台番剧」tab（无 tabBarSort 自定义时），与 A 一致。
- 设置「首页标签页」`defaultBars`（style_settings.dart:351）同样自动含新值。
- 无 tabBarSort 迁移需求：与 A 相同，hk_bangumi 追加在 bangumi 后、cinema 前（cinema index 5→6），顺序与 A 完全一致。

## 5. RED 测试

- grep `hk_bangumi|media_hk_bangumi|apiHKUrl|港澳台` test/：仅 `test/storage_pref_test.dart:159-160` 断言 `SettingBoxKey.apiHKUrl == 'apiHKUrl'`（T11 已转绿，本任务无需新增）。
- 无其他 hk 相关 RED 测试。

## 6. dart analyze --no-fatal-warnings

- 基线（T11 后）：**163 errors** / 37 warnings
- 本次：**159 errors** / 37 warnings（`--no-fatal-warnings`）
- 7 个改动文件自身：0 error、0 warning。
- 剩余 159 errors 全为已知基线：85 context_menu 孤儿 part + 6 vendored flutter + 68 test/ RED。
- 唯一新 lint 为 info 级 `constant_identifier_names`（home_tab_type.dart:22 `hk_bangumi`），与 A 完全一致（A 同文件同 lint），不阻塞 gate。

**结论：无新增错误，达标。**
