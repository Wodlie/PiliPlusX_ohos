# Task 7 — Accounts 生命周期状态机 + account_mgr `_resolveAccountSelection`

**Date:** 2026-07-31
**Repo:** D:\coding\PiliPlusX_ohos
**Baseline:** T6 后 236 errors → **226 errors**（-10，无新增）

## 改动文件

| 文件 | 改动 |
|------|------|
| `lib/utils/accounts.dart` | 重写为 A 状态机：`_AccountLifecycleState`（accounts+snapshots）、`_AccountLifecycleRegistry`（ListBase 固定长）、`_publish`、`canonicalize`、`snapshot`、`mainIdentity/videoIdentity/heartbeatIdentity`、`reply/blacklist` getter、`refresh` 回写 `needsBuvidPersist` + `Pref.deleteLegacyBuvid()`。与 A 逐字节相同（`git diff --no-index` 无输出）。 |
| `lib/utils/accounts/account_manager/account_mgr.dart` | `onRequest` 改用 `_resolveAccountSelection`（identity snapshot + canonicalize），心跳检查 `!identity.isLogin`；`_saveCookies` 加 `Accounts.canonicalize`；新增 `_resolveAccountSelection`。 |
| `lib/utils/accounts/account.dart` | 仅 `AnonymousAccount.delete()`：保留 B fawkes hack，加 `activated = false` + `Pref.deleteGuestBuvid()` + `cookieJar.deleteAll()` 合并 wait，`whenComplete(setBuvid3)` 重置 buvid3。 |

## 符号消费点 grep

- `Accounts.mainIdentity/videoIdentity/heartbeatIdentity` → `lib/utils/accounts.dart` 定义；`test/buvid_lifecycle_test.dart:204,223` 引用（T7 前 undefined，现已解析）。
- `Accounts.snapshot` → `account_mgr.dart:270`（`_resolveAccountSelection` 用）。
- `Accounts.canonicalize` → `account_mgr.dart:194`（`_saveCookies`）、`account_mgr.dart:245`（`_resolveAccountSelection`）。
- `Accounts.reply/blacklist` → `accounts.dart:36,44`（fallback 到 main）。
- `Accounts.accountMode` 消费方（login/controller.dart:629,630,647,755 + mine/controller.dart:233）——`ListBase` get/set 语义兼容，无需改 UI（与 A 同构）。

## OHOS 分支保留确认（account_mgr.dart）

- ✅ `import 'package:os_type/os_type.dart';` 保留
- ✅ `dioError` 的 `OS.isHarmony ? '' : ...` 分支保留（`account_mgr.dart:307`）
- ✅ connectivity 单值 `.desc`（非 A 的 `.first.desc`）保留（`account_mgr.dart:311`）
- ✅ `// TODO 鸿蒙待适配` 注释保留（`account_mgr.dart:305`）
- ✅ `AnonymousAccount.delete()` 的 `grpcHeaders['x-bili-fawkes-req-bin'] = GrpcHeaders.fawkes;` 保留（T1 决策 7 / fawkes hack）
- ✅ `test/buvid_lifecycle_test.dart` 与 A 逐字节相同（diff 无输出）

## analyze 对比

```
dart analyze --no-fatal-warnings
236 → 226 errors（-10）
```

- 改动 3 文件 0 错误。
- 剩余 226 全在已知基线：85 孤儿 part（reply/dyn/live_menu_helper + editable_text/vertical_slider vendored）+ test/ RED（T8/T9 符号）。

## RED 测试转绿情况

`test/buvid_lifecycle_test.dart`：**13 → 5 errors**

- 已解析（T7 提供）：`Accounts.mainIdentity`、`Accounts.snapshot`、`Accounts.refresh` 回写语义、`canonicalize`。
- 剩余 5 全为 T8 符号：`debugSetAppSupportDirPath`（1）、`LoginHttp.appHeaders`（3）、`LoginHttp.createLoginSessionIdentity`（1）——T8 落地后转绿。

`test/identity_migration_test.dart` 仍 3 errors（全 `request_identity_adapter`，T8 范围），未受影响。

## 风险说明

- `_AccountLifecycleState` 静态初始化会即时构造 guest snapshot（`OwnerScopedIdentitySnapshot.fromAccount` → `Pref.guestBuvid`），依赖 `GStorage.localCache` eager init——与 A 完全同构（storage_pref.dart 同字节结构），无新增风险。
- `http/init.dart setCookie` 内 `Accounts.refresh()` 为 fire-and-forget sync 调用——A 中 `refresh` 也是 async，兼容。
