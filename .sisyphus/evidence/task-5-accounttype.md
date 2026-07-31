# Task 5 Evidence — AccountType 4→6 values + api_type routing

**Date:** 2026-07-31

## 1. account_type.dart — 6 enum values + desc

`lib/models/common/account_type.dart` now matches A's declaration exactly:

| index | value | title | desc |
|-------|-------|-------|------|
| 0 | main | 主账号 | 登录、发表动态、投币、收藏、关注等操作 |
| 1 | heartbeat | 记录观看 | 获取视频/直播信息、上报观看历史与进度等 |
| 2 | recommend | 推荐 | 获取推荐列表、搜索结果、热门榜单等 |
| 3 | video | 视频取流 | 获取视频/直播流地址 |
| 4 | reply | 评论操作 | 发布、删除、点赞、点踩、举报评论，以及置顶、开关评论区等操作 |
| 5 | blacklist | 黑名单操作 | 获取黑名单、添加黑名单、移除黑名单等操作 |

- **Order hard-constraint satisfied:** existing 4 values (main/heartbeat/recommend/video, index 0-3) untouched and in A's order; reply=4, blacklist=5 appended at tail. Hive serializes by index (`AccountTypeAdapter.writeByte(obj.index)`, typeId 10) — index mapping identical to A, no data corruption.
- `const AccountType(this.title, this.desc)` — desc field added (A parity).

## 2. api_type.dart — reply/blacklist routing tables

- Added `AccountType.reply` table: `Api.replyAdd, Api.replyDel, Api.likeReply, Api.hateReply, Api.replyTop, Api.replyReport, Api.replySubjectModify` (all 7 verified present in `lib/http/api.dart`).
- Added `AccountType.blacklist` table: `Api.blackLst, Api.relationMod` (both verified present).
- **`Api.liveFeedback` NOT added** to recommend table — `grep liveFeedback lib/` in B returns 0 matches (constant removed vs A's `api.dart:1022`). Deferred to T21. Recommend table otherwise matches A minus that one entry.

## 3. Consumption-point compatibility (all 6-value safe)

| File | Pattern | Verdict |
|------|---------|---------|
| `lib/utils/accounts/account_type_adapter.dart` | `values.elementAtOrNull(i) ?? main` | Safe; no change needed |
| `lib/utils/accounts.dart` | `values.length` + index loops + `switch` w/ `default` | Safe; untouched (T7 scope) |
| `lib/utils/accounts/account.dart:141` | `values[i]` on saved JSON | Safe; indices 4/5 now valid (T6 scope) |
| `lib/utils/accounts/account_manager/account_mgr.dart:234` | `firstWhere(..., orElse: main)` | Safe; reply/blacklist paths now resolve |
| `lib/pages/login/controller.dart` (628/722/750) | generic `values` loops, `SingleChildScrollView` dialog | Safe; 6 groups scroll, no overflow |
| `lib/pages/setting/models/privacy_settings.dart` | `values` loop + `apiTypeSet[i]` null-skip | Updated to display `desc` (A parity) |
| `lib/http/*`, `lib/plugin/pl_player`, `lib/pages/{video,mine}` | fixed `AccountType.X` refs | Safe; no index arithmetic |

Only consumer file edited: `privacy_settings.dart` (now renders title + desc + URL list, matching A; includes `SelectionArea` wrapper).

## 4. dart analyze comparison

Command: `dart analyze --no-fatal-warnings`

- **Before (baseline):** 276 errors (orphan-part + test/ RED), 0 warnings
- **After:** **276 errors, 0 warnings** — no change
- Error files: 10 non-test files, all pre-existing orphan-part/known-RED files (`dyn_menu_helper.dart`, `live_menu_helper.dart`, `reply_menu_helper.dart`, `export_import.dart`, `editable_text.dart`, `vertical_slider.dart`, `extra_settings.dart`, `header_control.dart`, `image_utils.dart`, `storage_utils.dart`) + 166 in `test/`. **None of the modified files (account_type/api_type/privacy_settings) appear.**
- `git status`: only the 3 intended files modified (AGENTS.md/`lib/AGENTS.md`/`ohos/AGENTS.md` modifications pre-existing).

## 5. Out of scope (deferred)

- `Api.liveFeedback` recommend entry → T21
- `accounts.dart` snapshot()/reply+blacklist getters, `_accountTypeForRelationAct` in `http/video.dart` → T7/T9
