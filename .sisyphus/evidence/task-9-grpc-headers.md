# Task 9 — GrpcHeaders 按账号快照构建（真实 device + mid/restriction/ticket）

**Date:** 2026-07-31
**Plan:** port-a-features
**Baseline:** 181 errors（T8 后）| **After:** 181 errors（无新增，持平）

## 1. 变更文件

### `lib/utils/accounts/grpc_headers.dart`（86 行静态版 → 208 行按账号版）

按 A 参照重写，消费 T6/T7/T8 已就绪依赖（`Accounts.snapshot`/`get`、`OwnerScopedIdentitySnapshot.fromAccount`、`LoginAccount.buvid/deviceProfile`、identity_core、`AppDeviceProfiles.resolve`），依赖面全部为 B 已有，**未引入新依赖**：

- **身份解析** `_resolveHeaderIdentity`：遍历 `AccountType.values`，用 buvid+accessKey 匹配 `Accounts.snapshot(type)`；命中登录快照 → 解析该账号的 buvid/deviceProfile/auroraEid/mid；未命中 → guest / `workflow('grpc:<buvid>')` 兜底（与 A 一致）
- **真实 Device proto**：`brand/model/osver` 来自按 owner 解析的 deviceProfile（不再硬编码 `android`/`15`）；`fpLocal/fpRemote/fp` = `IdentityDerivedProfile.fpLocal`（不再 `'1'*64`）；`guestId` = `derived.deviceId`；`buvid` = 账号 buvid
- **新增头**：`x-bili-mid`（`'${mid ?? 0}'`，登录为账号 mid、游客为 0）、`x-bili-restriction-bin: ''`、`x-bili-ticket: ''`、`x-bili-aurora-eid`（登录且 mid>0 时，`IdUtils.genAuroraEid`）
- **按账号派生**：`user-agent`/`x-bili-trace-id`/`x-bili-fawkes-req-bin`（derived.sessionId）/`x-bili-device-bin`/`x-bili-metadata-bin` 全部由匹配账号的 identity 派生，不再用全局静态值
- **签名** `newHeaders([String? accessKey, String? buvid, AppDeviceProfile? deviceProfile, int? mid])` —— A 的 4 参形式（原 B 仅 2 参）
- **新增 `currentImDeviceId()`**：`Accounts.snapshot(AccountType.main)` → 派生 deviceId，供 im.dart devId
- **fawkes 兼容**：保留无参 getter `GrpcHeaders.fawkes`（T7 `AnonymousAccount.delete` 的 fawkes hack 调用，`delete()` 未改），内部生成全新随机 sessionId；`newHeaders` 走 `_buildFawkes(derived.sessionId)`（Dart 不允许 getter 与同名函数共存，故用私有 helper 分流）
- **`_buvid => LoginUtils.buvid` 回退保留**：`_normalizeBuvid` 无参/无账号时返回 `Pref.guestBuvid`（B 中 `LoginUtils.buvid = Pref.buvid` 委托 `guestBuvid`，语义等价，且取实时值避免 static-final 冻结旧值）

### `lib/utils/accounts/account.dart`（最小改动，仅 grpcHeaders 2 处）

- `LoginAccount.grpcHeaders`：`late final = newHeaders(accessKey)` → **getter** `newHeaders(accessKey, buvid, deviceProfile, mid)`（A 对齐，每请求按账号解析）
- `AnonymousAccount.grpcHeaders`：`final = newHeaders()` → **getter** `newHeaders(null, buvid)`（A 对齐）
- `AnonymousAccount.delete()`（T7 fawkes hack）**未改动**——`grpcHeaders[...]=GrpcHeaders.fawkes` 仍编译（getter 返回新 map，赋值退化为无副作用；`GrpcHeaders.fawkes` 无参 getter 已保留）

### `lib/grpc/im.dart`（gRPC 层消费点接线）

- `sendMsg` devId：`const UuidV4().generate()` → `GrpcHeaders.currentImDeviceId()`（移除 `uuid/v4.dart` import）
- `syncFetchSessionMsgs` devId：`'1'` 占位 → `GrpcHeaders.currentImDeviceId()`（移除占位）
- **未新增** `buildSendMsgRequest`/`buildSyncFetchSessionMsgsRequest`（T17 范围，本任务不动）

## 2. 传输架构保留确认

- **dio_http2_adapter 未动**：`http/init.dart`（`Request._internal`/`Http2Adapter`/fallbackAdapter/`_resetAdaptersForNetworkChange`/OHOS connectivity 分支）0 变更
- **`GrpcReq` 未动**：`grpc_req.dart` 0 变更；gRPC-over-HTTP framing（`compressProtobuf`/`Grpc-Status`/`Status.fromBuffer`）保持
- **头注入链路不变**：`account_mgr.dart:66` `options.headers.addAll(account.grpcHeaders)` 仍在 `isApp && ResponseType.bytes`（gRPC 请求）路径生效；`account.grpcHeaders` 由 `late final`/`final` 改为 getter 后**每请求**重新构建，正是按账号快照所需
- 改动仅 3 个文件（grpc_headers/account/im），无 OHOS 专属分支被触碰

## 3. analyze 结果

```
基线 181 errors（T8 后）
T9 后 181 errors（0 新增 / 0 减少），WARNINGS 与基线一致
修改的 3 个 lib 文件：0 error / 0 warning
```

按文件明细：
- `grpc_identity_test`：仍 4 error = `ImGrpc.buildSendMsgRequest`/`buildSyncFetchSessionMsgsRequest`（**T17 范围**，T8 证据误标为 T9；本任务按 brief 不新增这两个方法）
- 其余 177 = 85 孤儿 part + 6 vendored + 86 其他非 T9 测试 RED，均为已知基线

## 4. grpc_identity_test 转绿情况（grpc_headers 相关部分）

测试文件整体被 T17 的 4 个 `undefined_method` 编译阻塞，无法本地运行。已用**纯 Dart harness**（T6 模式）对 grpc_headers 真实逻辑逐条断言，**56/56 PASS**（见下节），覆盖测试中所有非 ImGrpc 断言：

- 登录（mid=2101）：`user-agent=androidHd.userAgent`、`authorization=identify_v1 ACCESS_KEY_2101`、`buvid=账号buvid`、`x-bili-aurora-zone=sh001`、`x-bili-mid=2101`、`x-bili-aurora-eid=genAuroraEid(2101)`、`x-bili-restriction-bin`/`x-bili-ticket` 存在、metadata.buvid/accessKey、device.brand/model/osver=grpcProfile、fpLocal/fpRemote/fp/guestId=derived、**brand≠android 占位**、`currentImDeviceId()==derived.deviceId`
- 游客：无 authorization/aurora-eid、`x-bili-mid=0`、device=guest profile、fp 字段=derived、brand≠android
- 兜底：无参 `newHeaders()` → `Pref.guestBuvid`；`newHeaders('SOME_ACCESS')` → workflow buvid 合法格式
- T7 fawkes getter：`GrpcHeaders.fawkes` 仍可解码为合法 FawkesReq

## 5. 验证 harness（运行时行为证据）

`C:\Users\dashan\AppData\Local\Temp\opencode\t9_harness\`（临时目录，不入库）
- **真实复制**：新 `grpc_headers.dart`、identity_core 5 文件、app_device_profile、account_type、constants、metadata/device/fawkes/locale/network `.pb.dart`
- **Stub 仅 4 个重依赖壳**：`Accounts`（snapshot/get 表）、`account.dart`（Account/LoginAccount/AnonymousAccount/NoAccount 骨架）、`Pref.guestBuvid`、`IdUtils.genAuroraEid`（真实算法内联）
- 依赖：protobuf 6.0.0 / fixnum / crypto / cookie_jar 4.0.9 / hive_ce / collection
- 运行：`dart run bin/verify.dart` → **`PASS: 56  FAIL: 0`**

## 6. 遗留（非本任务范围）

- `grpc_identity_test` 4 error → **T17** 补 `ImGrpc.buildSendMsgRequest`/`buildSyncFetchSessionMsgsRequest`（devId 已接 `currentImDeviceId`，T17 直接复用）
- `sendMsg`/`syncFetchSessionMsgs` devId 已替换占位；T17 提取 build 方法时保持 `GrpcHeaders.currentImDeviceId()` 来源即可
