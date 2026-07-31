# Task 8 — RequestIdentityAdapter + http 层身份接入 + wbi 风控字段

**Date:** 2026-07-31
**Plan:** port-a-features
**Baseline:** 226 errors（T7 后）| **After:** 181 errors（-45）

## 1. 新文件

- `lib/utils/accounts/request_identity_adapter.dart`（6285 字节）——按 A 参照重建，逐段对齐：
  - `fromAccount({Account, userAgent})`：消费 T6/T7 已就绪的 `OwnerScopedIdentitySnapshot.fromAccount` + `IdentityCoreGenerators.deriveProfile` + `LoginAccount.deviceProfile` + `AppDeviceProfiles.resolve`
  - `fromBuvid({buvid, userAgent, scope})`：workflow owner，供 login 会话
  - 产出：`loginPayloadFields` / `restPayloadFields` / `appHeaders` / `appIdentityHeaders` / `webDeviceQueryFields` / `webDmImageQueryFields` / `preserveGaiaFields` / `gaiaCookieHeaders`
  - 依赖面全部为 B 已有：`Constants.baseHeaders`（x-bili-aurora-zone=sh001）、`IdUtils.genAuroraEid`、identity_core、app_device_profile。**未引入新依赖。**

## 2. wbi 签名风控字段

- `lib/utils/wbi_sign.dart`
  - `encWbi` 首行追加 `appendRiskFingerprintParams(params)`
  - 新增 `appendRiskFingerprintParams`：`dm_img_list='[]'`、`dm_img_str`、`dm_cover_img_str`（web GL 指纹）、`dm_img_inter={"ds":[],"wh":[0,0,0],"of":[0,0,0]}`，均 `??=`（不覆盖调用方自定义）
  - `getWbiKeys` else 分支补 `.catchError((e) { debugPrint('WBI sign error: $e'); return ''; })`
  - 新增 `import 'package:flutter/foundation.dart' show debugPrint;`

## 3. path_utils / login_utils

- `lib/utils/path_utils.dart`：补 `@visibleForTesting debugSetAppSupportDirPath(String)`（11 个测试文件引用，缺失根因）
- `lib/utils/login_utils.dart`：
  - `generateBuvid()` → `IdentityCoreGenerators.generateBuvid()`（确定性，接 identity）
  - `onLoginMain` 补 `Pref.setAccountUname(response.mid!, response.uname!)`（多账号昵称缓存，与 A 对齐）
  - **保留** `genDeviceId()`（http/login 使用）与 `buvid`（grpc_headers.dart 使用）

## 4. http 层接入（仅补身份字段接入点，保留 B 的 OHOS 适配，不整体重写）

| 文件 | 变更 |
|------|------|
| `http/login.dart` | 新增 `createLoginSessionIdentity({scope})` + `appHeaders({buvid, appKey, userAgent, contentType, account, identity})`（A 对齐）；**保留** `deviceId`/`buvid`/`headers` 全局单例（OHOS 适配） |
| `http/video.dart` | 新增 `_recommendProfile=androidHd` + `@visibleForTesting recommendAppQueryParameters` + `recommendAppIdentityHeaders`；`rcmdVideoListApp` 改用二者（**替换**全局 buvid + fp `'1'*64` + session `'11111111'` 占位头） |
| `http/live.dart` | 新增 `_appProfile=androidApp` + `@visibleForTesting liveFeedIndexQueryParameters` + `appIdentityHeaders`；`liveFeedIndex`/`liveSecondList` 改用二者（替换占位头 + device_name 'android'→真实型号） |
| `http/member.dart` | `memberInfo`/`searchArchive`/`memberDynamic` 用 `identity.webDmImageQueryFields`（确定性，替换 `Utils.base64EncodeRandomString` 随机段）；`memberDynamic` + 4 个关注分组 CRUD 用 `webDeviceQueryFields` |
| `http/search.dart` | gaia 字段改走 `RequestIdentityAdapter.preserveGaiaFields` + `gaiaCookieHeaders`（行为等价，接 identity 抽象） |
| `http/follow.dart` | `sortFollowTag` 用 `identity.webDeviceQueryFields(spmid:'333.1387')` |
| `http/dynamics.dart` | `createDynamic`（**补上缺失的 spmid 333.999**）/`dynamicDetail`/`editDyn`/`bubble` 用 `identity.webDeviceQueryFields` |

保留未动（遵循 MUST-NOT）：`account.dart`、`grpc_headers.dart`（T9 范围）、`init.dart` 的 OS.isHarmony/connectivity 单值/buvidActive、`AnonymousAccount.delete` fawkes hack、`relationMod` 的 fp 字段（T16 修）。

## 5. analyze 结果

```
基线 226 errors（T7 后）
T8 后 181 errors（-45），WARNINGS 与基线一致（2 条 pre-existing 未改文件）
```

按文件明细（T8 相关全部归零）：
- `request_identity_adapters_test`：16 → **0**
- `web_gaia_identity_test`：10 → **0**
- `identity_migration_test`：3 → **0**
- `buvid_lifecycle_test`：5 → **0**
- `grpc_identity_test`：11 → 4（剩余 4 = `ImGrpc.buildSendMsgRequest`/`buildSyncFetchSessionMsgsRequest`，**T9 gRPC 头范围**）
- `debugSetAppSupportDirPath` 相关 11 个测试文件：全部归零（block_reason 23→22、blocked_reply_filter 6→5 等）
- 剩余 181 = 85 孤儿 part（reply_menu_helper 40/dyn_menu_helper 37/live_menu_helper 8）+ 6 vendored（editable_text 3/vertical_slider 3）+ 90 非 T8 测试 RED（init_test 18、block_reason 22、video_summary_failure_states 12、T9 grpc 4 等），全为已知基线
- 修改的 lib 文件：**0 error / 0 warning**

## 6. 测试转绿说明

本机 Flutter 3.44.4 无法编译 B 的传递依赖图（T6 实证：vendored 3.32.4-ohos 补丁/font_awesome/git fork 平台成员），`flutter test` 需 OHOS 3.41.9 SDK（CI）。转绿验收以 `dart analyze` 对 RED 测试文件的 error 归零为准（测试引用符号已全部提供）。剩余的 grpc_identity 4 个 error 属 T9 的 `ImGrpc` 构建方法，不在 T8 范围。

## 7. 消费点接线证据

- `LoginHttp.appHeaders` → `RequestIdentityAdapter.fromAccount/fromBuvid` → `appHeaders`（含 buvid/env/app-key/user-agent/x-bili-trace-id/x-bili-aurora-zone[/eid]/cronet）
- `VideoHttp.recommendAppIdentityHeaders`/`LiveHttp.appIdentityHeaders` = `appHeaders` + `appIdentityHeaders`（fp_local/fp_remote/session_id）
- `member/dynamics/follow` = `webDeviceQueryFields`（x-bili-device-req-json，含 spmid）
- `memberInfo/searchArchive/memberDynamic` = `webDmImageQueryFields`（dm_img_* 确定性指纹）
- `search` = `preserveGaiaFields` + `gaiaCookieHeaders`
