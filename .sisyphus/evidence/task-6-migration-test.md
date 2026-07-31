# Task 6 QA Evidence — LoginAccount Hive 4→6 迁移

> **任务**: port-a-features Task 6（全计划最高优先级验收项）
> **日期**: 2026-07-31
> **分支**: master（B = `D:\coding\PiliPlusX_ohos`）

## 一、改动文件

| 文件 | 改动 |
|---|---|
| `lib/utils/accounts/account_adapter.dart` | 6 字段读写：`writeByte(6)` + field 4=buvid / 5=deviceProfile；`read` 走 `LoginAccount.restored(...)`（field4/5 可空） |
| `lib/utils/accounts/account.dart` | 新增 `@HiveField(4) buvid` / `@HiveField(5) deviceProfile`；`_resolveLoginAccountIdentity`（cookie DedeUserID → `OwnerScopedIdentityPersistence.resolve`）；`needsBuvidPersist`（`_needsBuvidPersist \|\| deviceProfile == null`）；`_persistedAccount`（保证 deviceProfile 落盘）；`restored` 工厂（`persistResolvedDeviceProfile: false`）；`seededMigrationCopy()`（cookie buvid3 seed + 确定性 deviceProfile，幂等）；**保留 B 的 `_resolveBuvid()` 作为 seed 来源**；保留 B 的 `grpcHeaders`/AnonymousAccount（fawkes hack）不动 |
| `lib/utils/accounts/account_migration.dart` | **新建**：`migrateAccountBoxV4ToV6(Box<LoginAccount>)` 幂等迁移（`needsBuvidPersist==false` 跳过；seed = cookie buvid3 → 旧 buvid → 现场生成） |
| `lib/utils/storage.dart` | 注册 `AppDeviceProfileAdapter()`（typeId 13）+ `import account_migration`；`GStorage.init()` 在 `Accounts.init()` 开 box 后调用 `await migrateAccountBoxV4ToV6(Accounts.account)`（触发钩子） |
| `test/hive_migration_test.dart` | **新建**：6 个用例（旧记录解码+迁移回填 / 幂等 / 空 box / 缺 buvid3 回退 / 已 6 字段跳过 / 重开值稳定） |

## 二、迁移测试结果

### 2.1 `dart analyze test/hive_migration_test.dart` → **No issues found**

### 2.2 `flutter test test/hive_migration_test.dart` → **编译期阻塞（环境，非测试逻辑）**

本地 Flutter 3.44.4 无法编译本包传递依赖图（B 钉 OHOS Flutter 3.41.9 / SDK 3.41.x）：

```
lib/common/widgets/flutter/text_field/editable_text.dart:5559:31: Error: Type 'ExtendSelectionByPageIntent' not found.
  （B vendored 3.32.4-ohos 引擎补丁引用的类仅在 OHOS 引擎存在）
font_awesome_flutter-10.9.0/lib/src/icon_data.dart:8:30: Error: The class 'IconData' can't be extended ... final class.
  （依赖版本与 3.44.4 框架不兼容；OHOS 3.41.x 下可编译）
flutter_audio_session / flutter_inappwebview（git fork）: Error: Member not found: 'ohos'.
  （fork 引用的 OHOS 平台扩展仅存在于 OHOS SDK）
```

触发链：`account.dart → accounts.dart → http/init.dart + pages/mine/controller.dart → font_awesome/material_design_icons/vendored`。
**任何 import `account.dart` 的 flutter_test 在本地 3.44.4 均无法编译**（`flutter test test/smoke_test.dart` 可跑证明 harness 本身正常）。该测试在 OHOS 3.41.9 CI 环境应可编译并通过。

### 2.3 纯 Dart 运行时验证（fallback，任务预案）→ **31/31 PASS**

因环境阻塞，按任务预案用纯 Dart 断言脚本验证迁移逻辑（hive_ce 2.19.3 本地可跑）。harness 位于
`%LOCALAPPDATA%\Temp\opencode\hive_migration_verify`，**真实复制** `account.dart`/`account_adapter.dart`/`account_migration.dart`/`app_device_profile.dart`/`identity_core/*`/`identity_persistence.dart`/`account_type*.dart`（import 重写至本地 stub），仅 stub 掉 5 个无关重依赖（Accounts/GrpcHeaders/Pref/IdUtils/Constants）。

`dart run bin/verify.dart` 输出（31 checks，逐字节同 flutter_test 用例逻辑）：

```
PASS: A1: accessKey 保留                    PASS: A2: type 0-3 映射正确
PASS: A3: 旧记录 field5 为 null             PASS: A4: 旧记录 needsBuvidPersist==true
PASS: A5: type 集合(多值)映射正确            PASS: A6: 第二账号也标记待回填
PASS: A7: 迁移条数 == 2                     PASS: A8: field4 与 cookie buvid3 逐字节一致
PASS: A9: field5 = 确定性默认设备档案        PASS: A10: 设备档案非通用占位
PASS: A11: 迁移后 needsBuvidPersist==false  PASS: A12: type 迁移后保留
PASS: A13: 第二账号 seed 一致               PASS: A14: 第二账号 deviceProfile 落盘
PASS: B1: 首次迁移 1 条                     PASS: B2: 二次迁移 0 条（幂等）
PASS: C1: 空 box 返回 0                     PASS: C2: 空 box 无副作用
PASS: D1: 缺 buvid3 记录标记待回填          PASS: D2: 迁移完成不崩溃
PASS: D3: field4 落盘为现场生成 buvid3      PASS: D4: 生成值符合 buvid3 格式
PASS: D5: deviceProfile 回填                PASS: D6: 迁移后不需要再持久化
PASS: E1: 重开后 needsBuvidPersist==false   PASS: E2: 已存 buvid 读回一致
PASS: E3: 已 6 字段跳过                     PASS: E4: 迁移不覆盖已有 buvid
PASS: E5: deviceProfile 保留
PASS: F1: 首次迁移                          PASS: F2: 重开+再迁移后 field4 仍为同一 cookie buvid3（值稳定）
ALL PASS (31 checks)
```

关键断言：
- **A8**：迁移后 field4 **逐字节 == cookie buvid3**（方案 A，升级前后线上 `buvid:` 头不漂移）
- **A9**：field5 == `AppDeviceProfiles.defaultDeviceProfileForOwner('account:<mid>')` 确定性
- **B2**：二次迁移 0 条（幂等）
- **E3/E4**：已 6 字段记录跳过且不被覆盖
- **F2**：重开后再迁移，field4 仍回填同一 cookie buvid3（跨启动值稳定；`restored` 对 `...infoc` 格式的瞬时再生成会被 GStorage.init 的迁移钩子立即纠正）

## 三、adapter 6 字段确认

`account_adapter.dart`（typeId 9 不变）：

```dart
// write
..writeByte(6) ..writeByte(0) ..write(obj.cookieJar)      // field0
..writeByte(1) ..write(obj.accessKey)                     // field1
..writeByte(2) ..write(obj.refresh)                       // field2
..writeByte(3) ..write(obj.type.toList())                 // field3
..writeByte(4) ..write(obj.buvid)                         // field4
..writeByte(5) ..write(obj.deviceProfile);                // field5
// read
return LoginAccount.restored(fields[0]..., fields[1]..., fields[2]...,
  (fields[3] as List?)?.cast<AccountType>().toSet(),
  fields[4] as String?, fields[5] as AppDeviceProfile?);
```

旧 4 字段记录（`numOfFields=4`）由新 adapter 解码 → field4/5 为 null → `restored` 置 `needsBuvidPersist=true` → 迁移回填。**与 A 逐字节一致**（除 `seededMigrationCopy` 为 B 方案 A 特有）。

## 四、analyze 对比

| 指标 | 基线（T6 前） | T6 后 | 说明 |
|---|---|---|---|
| `dart analyze --no-fatal-warnings` error 总数 | 276 | **236**（-40） | 无新增错误（新增测试文件 0 错误） |
| 改动文件（4 lib + 1 test） | — | 0 error | 各自 `dart analyze` 通过 |

-40 来源：T5 已落地 + 本任务让部分 RED 契约测试（引用 `restored`/`needsBuvidPersist`/`deviceProfile`/`buvid` 字段的符号）开始可解析。

## 五、RED 契约测试转绿进度（本任务范围）

| 测试文件 | T6 前 | T6 后 | 剩余错误 → 归属 |
|---|---|---|---|
| `identity_migration_test.dart` | 21 errors | **3 errors** | `request_identity_adapter.dart` 文件（T8）、`RequestIdentityAdapter`（T8）、`debugSetAppSupportDirPath`（A 的 path_utils，T8） |
| `buvid_lifecycle_test.dart` | — | 13 errors | `Accounts.mainIdentity`/`snapshot`（T7）、`LoginHttp.appHeaders`/`createLoginSessionIdentity`（T8）、`debugSetAppSupportDirPath`（T8） |
| `grpc_identity_test.dart` | — | 11 errors | T9（GrpcHeaders 按账号快照）+ T8 |
| `request_identity_adapters_test.dart` | — | 16 errors | 全 T8 |

`identity_migration_test.dart` 中 T6 相关的 `restored`/`needsBuvidPersist`/`deviceProfile`/`toJson()['deviceProfile']`/`fromJson`/`onChange` 持久化契约符号已全部提供 → **T8 落地后该文件应 0 错误**。

## 六、环境/仓库备注

- **`.gitignore:152 test*` 过宽**：新 `test/hive_migration_test.dart` 被忽略（目录 `test/` 命中 `test*`；既有测试文件为规则添加前已跟踪故不受影响）。提交时需 `git add -f test/hive_migration_test.dart`。
- 本地无 fvm / 无 OHOS Flutter SDK；OHOS CI（oh-3.41.9-release）是唯一可运行 `flutter test` 的环境。
- 迁移触发钩子：`GStorage.init()` 末尾 `await migrateAccountBoxV4ToV6(Accounts.account)`（`storage.dart:84`），在 `Accounts.init()` 开 box 之后执行；`http/init.dart:42` 的 `Accounts.refresh()` 未 await 属 T7 范围，未在本任务改动。
- 迁移函数无 try/catch：eager 解码在 openBox 已校验结构；DedeUserID 缺失记录 openBox 即抛错，与 A 行为一致（非迁移可救，审计 4.3 已定案）。
