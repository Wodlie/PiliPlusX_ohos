# Task 10 — BUVID 激活重试 + 登出清理 + 昵称缓存（QA Evidence）

**Task**: port-a-features Task 10
**Date**: 2026-07-31
**Repo**: B = `D:\coding\PiliPlusX_ohos`（参照 A = `D:\coding\PiliPlusX`）

## 变更清单（git diff 确认，仅 2 文件）

| 文件 | 变更 |
|------|------|
| `lib/http/init.dart` | `buvidActive` 重试语义 + `setCookie` async/await 对齐 |
| `lib/pages/mine/controller.dart` | `queryUserInfo` 补 `Pref.setAccountUname` 昵称缓存写入 |

## 1. BUVID 激活重试语义（A 移植，保留 B 的 Utils.random）

**改前（B，bug）**：`account.activated = true` 在请求**前**（`init.dart` 原 63-65 行），失败不重试；用 `Request().post`（把 DioException 包装成合成 Response，catch 永不触发）。

**改后（B，对齐 A）**：
```dart
static Future<void> buvidActive(Account account) async {
  if (account.activated) return;
  try {
    // ... Utils.random 生成 randPngEnd（保留 B 方式，A 的 generateSecureRandomBytes B 无此方法）
    await dio.post(          // 直接 dio.post：DioException 传播出 try → 保持 activated=false
      Api.activateBuvidApi, ...);
    account.activated = true; // 成功后才置 true
  } catch (_) { /* 失败保持 activated=false，下次可重试 */ }
}
```

**验证证据**：
- `lib/http/init.dart:102` `account.activated = true;` 位于 `await dio.post`（:93）之后 ✓
- 失败路径（catch）无 `activated` 赋值 ✓
- 保留 B 的 `Utils.random` 生成方式（:69, :78；A 的 `generateSecureRandomBytes` 在 B 全库 grep 0 命中，不可用）✓
- 注释保留 `// 这样线程不安全, 但仍按预期进行` 删除——该注释描述旧的前置 true 行为，随语义修复移除（非 OHOS 适配注释，A 版亦无）

## 2. setCookie 语义对齐（B sync → async + await）

- **为什么 B 是 sync**：`git log -- lib/http/init.dart` 显示 B 的 init.dart 仅含上游同步（`sync: 跟进至 2.1.0`）与上游 tweaks/fix；无任何 OHOS 专属"改 sync"提交。sync 是旧上游继承，非 OHOS 启动时序刻意选择 → **对齐 A**。
- **改后**：`static Future<void> setCookie() async` + `await Accounts.refresh();`（B 的 `Accounts.refresh()` T7 已是 `Future<void>`，此前未 await 属 fire-and-forget 竞态）。
- **约束检查**：唯一调用方 `main.dart:162` `Request.setCookie();` 不 await（A 同）；`analysis_options.yaml` 无 `unawaited_futures`/`discarded_futures` lint，不产生新 warning。✓

## 3. 登出身份清理（T7 已完成，本任务验证）

- `lib/utils/accounts/account.dart` 本任务**未改动**（git diff 确认）。
- T7 已实现 `AnonymousAccount.delete()`：`Future.wait([cookieJar.deleteAll(), Pref.deleteGuestBuvid()]).whenComplete(setBuvid3)` + fawkes hack（见 learnings T7）。无缺口。

## 4. 昵称缓存（写入方 + 读取方）

**写入方（2 处）**：
- `lib/utils/login_utils.dart:69`（`LoginUtils.onLoginMain`，T8 已补）✓
- `lib/pages/mine/controller.dart:107-109`（`queryUserInfo`，本任务补上，对齐 A 的 mine controller:107）✓

**读取方**：
- `lib/utils/storage_pref.dart:90` `accountUnameMap` getter + `:103` `getAccountDisplayName` 消费 ✓
- 存储键 `LocalCacheKey.accountUnameMap`（storage_key.dart:319）✓

## 5. OHOS 保留检查（全部原样）

- `init.dart:126` `// connectivity_plus 5.x 回调单值（鸿蒙适配版本）` ✓
- `init.dart:218` UA `'Dart/3.6 (dart:io)'`（未改回 A 的 `'grpc-go/1.61.1'`）✓
- `account_mgr.dart` 的 `OS.isHarmony`/`// TODO 鸿蒙待适配` 未触碰 ✓
- 无 `SelectionText(`、无桌面分支、无 `*.g.dart`/`*.pb*.dart` 改动 ✓

## 6. dart analyze --no-fatal-warnings

- **errors: 181**（基线 181，无新增）✓
- **warnings: 37**（全 pre-existing：vendored 引擎文件 / 孤儿 part / test/ RED unused_import / 已知 `buvid_lifecycle_test.dart:11` unused import）——**修改文件 0 warning 0 error** ✓
- RED 测试状态保持：`buvid_lifecycle_test.dart` / `identity_migration_test.dart` 无新增 error（test 仅 fixture 用 `..activated = true`，无激活顺序断言，不受影响）

## 7. 消费点证明（grep）

```
lib/utils/login_utils.dart:69        Pref.setAccountUname(response.mid!, response.uname!);
lib/pages/mine/controller.dart:108   Pref.setAccountUname(response.mid!, response.uname!);
lib/utils/storage_pref.dart:94       static void setAccountUname(int mid, String uname) {
lib/utils/storage_pref.dart:103      final uname = accountUnameMap[mid];
lib/http/init.dart:102               account.activated = true;   // 成功路径
```

## 结论

Task 10 全部验收标准满足：buvidActive 成功后才 activated=true（失败可重试）；delete() 无需再改（T7 已完成）；setAccountUname 双写入方 + accountUnameMap 读取方齐备；setCookie 对齐 A（async + await refresh）且保留 B 全部 OHOS 适配；analyze 181 errors 无新增。
