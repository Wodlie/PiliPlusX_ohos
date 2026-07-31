# Batch 0 Hive Audit

> **任务**: port-a-features Task 2 — Hive schema/键命名空间审计 + 4→6 AccountType 迁移方案设计（纯侦察，零代码修改）
> **日期**: 2026-07-31
> **对比**: A = `D:\coding\PiliPlusX`（dev/Wodlie 增强） vs B = `D:\coding\PiliPlusX_ohos`（OHOS 移植，master）
> **方法**: 逐文件实读 A/B 双仓库（storage.dart / account*.dart / identity_core / storage_key / storage_pref / api_type / login_utils / grpc_headers）+ `git diff --no-index` 字节级核对 + hive_ce 2.19.3 源码核实解码时机
> **结论先行**: 4→6 迁移**全自动、零手动、零键冲突**。枚举按 index 序列化 + 尾部追加天然安全；真正的迁移工作是「每账号 BUVID/deviceProfile 回填」，由 `LoginAccount.restored` + `needsBuvidPersist` + `Accounts.refresh()` 自愈机制承担。

---

## 一、B 当前 Hive 体系（box/adapter/字段清单）

### 1.1 初始化流程（`lib/utils/storage.dart`）

- `Hive.init(path.join(appSupportDirPath, 'hive'))` — 与 A 完全一致（同一存储目录 `appSupportDirPath/hive`）。
- `GStorage.init()` 并行打开 7 个 box + `Accounts.init()`：
  | box | 泛型 | 备注 |
  |---|---|---|
  | `userInfo` | `Box<UserInfoData>` | compactionStrategy |
  | `localCache` | `Box<dynamic>` | 键：blackMids、danmakuFilterRules、guestBuvid、`buvid`(legacyBuvid)、accountUnameMap、mixinKey、timeStamp、historyPause |
  | `setting` | `Box<dynamic>` | 全部 `SettingBoxKey.*` 设置键 |
  | `historyWord` | `Box<dynamic>` | 搜索历史 |
  | `video` | `Box<dynamic>` | 播放器设置（`VideoBoxKey.*`） |
  | `watchProgress` | `Box<int>` | 自定义 `_intStrDescKeyComparator` |
  | `reply` | `Box<Uint8List>`? | 仅 `Pref.saveReply` 时打开 |
  | `account` | `Box<LoginAccount>` | **在 `Accounts.init()`（`lib/utils/accounts.dart:27`）中打开**，`Hive.openBox('account')`，无 typeId 冲突 |

### 1.2 adapter 注册列表（`GStorage.regAdapter()`，`storage.dart:99-109`）

| typeId | adapter | 类 | 状态 |
|---|---|---|---|
| 3 | OwnerAdapter | `models/model_owner.dart` | B+A |
| 4/5 | UserInfoDataAdapter / LevelInfoAdapter | `models/user/info.g.dart` | B+A |
| 8 | BiliCookieJarAdapter | `utils/accounts/cookie_jar_adapter.dart` | **B+A 逐字节相同** |
| 9 | LoginAccountAdapter | `utils/accounts/account_adapter.dart` | B=4 字段 / A=6 字段 |
| 10 | AccountTypeAdapter | `utils/accounts/account_type_adapter.dart` | **B+A 逐字节相同** |
| 11 | SetIntAdapter | `utils/set_int_adapter.dart` | B+A |
| 12 | RuleFilterAdapter | `models/user/danmaku_rule_adapter.dart` | B+A |
| 13 | AppDeviceProfileAdapter | `utils/accounts/app_device_profile.dart` | **仅 A 注册；B 未注册（B 中整文件是死代码，零引用）** |

> **关键**：B 仓库内已存在 `lib/utils/accounts/app_device_profile.dart`，与 A **逐字节相同**（含 `AppDeviceProfileAdapter` typeId=13、`AppDeviceProfiles` 6 条 curated 池、`defaultDeviceProfileForOwner`）。但 B 的 `storage.dart` 不 import、不注册，且整个 lib 树零消费（grep `AppDeviceProfile` 仅命中该文件自身）。typeId 13 在 B 的 box 中从未写记录 → **无历史数据、无迁移风险**，T6 只需补一行注册。

### 1.3 `LoginAccountAdapter`（B：4 字段）

`lib/utils/accounts/account_adapter.dart`（typeId 9）：
- `write`：`writeByte(4)` + 字段 0=cookieJar, 1=accessKey, 2=refresh, 3=type。
- `read`：按 `numOfFields` 读字段表 → `LoginAccount(fields[0], fields[1], fields[2], (fields[3] as List?)?.cast<AccountType>().toSet())`（**4 参构造**）。
- 无版本号、无 schema marker —— 版本靠字段计数自描述（`readByte()` 头部）。

### 1.4 `AccountTypeAdapter`（B+A 逐字节相同）

`lib/utils/accounts/account_type_adapter.dart`（typeId 10）：
- **序列化 = 枚举 index**：`write` → `writer.writeByte(obj.index)`；`read` → `AccountType.values.elementAtOrNull(reader.readByte()) ?? AccountType.main`。
- 自带越界兜底（`?? main`）。这是 4→6 尾部追加**安全**的核心依据：旧数据字节 0-3 在新枚举下映射不变；新值 4/5 永远不会出现在旧数据里。

### 1.5 `LoginAccount`（B：4 字段，BUVID 不落盘）

`lib/utils/accounts/account.dart`：
- `@HiveField(0..3)`：cookieJar / accessKey / refresh / `Set<AccountType> type`。
- `late final String buvid = _resolveBuvid()`：**现场推导**——cookie `buvid3` → cookie 旧 `buvid` → `cookieJar.setBuvid3()` 生成；**不写回 Hive**。
- 单构造器 `LoginAccount(cookieJar, accessKey, refresh, [type])`；无 `restored`、无 `deviceProfile`、无 `needsBuvidPersist`、无 `_persistedAccount`。
- `onChange()` → `_box.put(_midStr, this)`（直接回写自身）。
- `toJson()` 仅 4 键；`fromJson` 用 `AccountType.values[i]`（**下标索引**，与 adapter 序列化一致）。
- `AnonymousAccount.buvid => Pref.guestBuvid`（`localCache['guestBuvid']`，走 `OwnerScopedIdentityPersistence` stored→legacy→generated）；`delete()` 保留 B 的 fawkes hack、不清 guest BUVID。
- `grpcHeaders`：`GrpcHeaders.newHeaders(accessKey)`（全局静态，见下）。

### 1.6 B 已有的身份基础设施（重要发现）

B **已经拥有**（与 A 逐字节相同，仅 1 处注释差异）：
- `lib/utils/accounts/identity_core/`（5 文件：contracts/generators/owner/profile/snapshot）——完整算法（`generateBuvidForOwner`/`deriveBuvidFromSeed`/`validateBuvid`/`deriveProfile` 全在）。
- `lib/utils/accounts/identity_persistence.dart` —— `OwnerScopedIdentityPersistence.resolve`（stored→legacy→generated）逻辑逐字节一致（B 注释多列了 `session_id`）。
- `Pref.guestBuvid`（`storage_pref.dart:1136`）已消费 identity 解析（stored=`guestBuvid` 键 → legacy=`buvid` 键 → generated）。

**即 B 的「游客 BUVID」身份持久化已迁移完成；缺的是「每账号」一侧**（`LoginAccount.buvid` 持久化 + `deviceProfile` + `_resolveLoginAccountIdentity` + `needsBuvidPersist` + `_persistedAccount`）——这正是 Task 6 要补的。

### 1.7 B 的测试现状（决定性发现）

B 的 `test/` 已包含从 A 移植的**目标态测试**：
- `identity_migration_test.dart`、`buvid_lifecycle_test.dart`、`request_identity_adapters_test.dart`、`grpc_identity_test.dart`、`identity_test.dart`。
- 这些测试引用了 B 的 lib **当前不存在**的符号（grep 实锤零命中）：`LoginAccount.restored`、`needsBuvidPersist`、`deviceProfile`、`Accounts.mainIdentity`/`snapshot()`、`RequestIdentityAdapter`、`LoginHttp.createLoginSessionIdentity`/`appHeaders`。
- 结论：**这些测试目前是 RED（无法编译）**；`analysis_options.yaml` 未排除 `test/`。它们是 T5/6/7/8 的「验收契约」——实现落地后应转绿。AGENTS.md 的「CI 跑 dart analyze 零错误」与该现状矛盾，Batch 5 需复核。

---

## 二、A 的 Hive 体系（差异点）

### 2.1 `LoginAccountAdapter`（A：6 字段，typeId 9）

`write`：`writeByte(6)` + 0=cookieJar, 1=accessKey, 2=refresh, 3=type, 4=buvid, 5=deviceProfile。
`read`：`LoginAccount.restored(fields[0], fields[1], fields[2], fields[3], fields[4] as String?, fields[5] as AppDeviceProfile?)`。

### 2.2 `LoginAccount`（A：6 字段）

- 新增 `@HiveField(4) final String buvid`、`@HiveField(5) final AppDeviceProfile? deviceProfile`；私有 `_needsBuvidPersist`（不落盘）。
- `bool get needsBuvidPersist => _needsBuvidPersist || deviceProfile == null;`
- 两个工厂：
  - `LoginAccount(...)`（新建/登录）→ `persistResolvedDeviceProfile: true` → 无 deviceProfile 时立刻分配 `AppDeviceProfiles.defaultDeviceProfileForOwner('account:$mid')`。
  - `LoginAccount.restored(...)`（Hive 读回）→ `persistResolvedDeviceProfile: false` → deviceProfile 保持 null，靠 `_persistedAccount` + refresh 自愈。
- 统一走 `_resolveLoginAccountIdentity(cookieJar, storedBuvid)` → `OwnerScopedIdentityPersistence.resolve(owner: IdentityOwnerKey.account(mid), storedBuvid)`，`source ∈ {stored, legacy, generated}`；`generated/legacy` ⇒ `_needsBuvidPersist=true`。
- `onChange()` → `_box.put(_midStr, _persistedAccount)`；`_persistedAccount` 在 deviceProfile==null 时构造带 `defaultDeviceProfileForOwner('account:$mid')` 的副本回写（**保证设备档案落盘**）。
- `Accounts.refresh()`（A，`accounts.dart:82-110`）：迭代 box → 对 `needsBuvidPersist` 账号 `onChange()` 回写 → 清理旧全局 `'buvid'` 键（`Pref.deleteLegacyBuvid()`）。
- `grpcHeaders` → `GrpcHeaders.newHeaders(accessKey, buvid, deviceProfile, mid)`（按账号快照）。

### 2.3 A 的 storage.dart

`regAdapter()` 比 B 多一行：`..registerAdapter(AppDeviceProfileAdapter())`（typeId 13）。

### 2.4 A 的枚举与路由

- `account_type.dart`：6 值 + `desc`（`reply`/`blacklist` 在 index 4/5，**顺序**：main, heartbeat, recommend, video, reply, blacklist）。
- `api_type.dart`：新增 `AccountType.reply`（7 端点）、`AccountType.blacklist`（2 端点）路由表 + recommend 增补 `Api.liveFeedback`。
- A 独有 `request_identity_adapter.dart`、`LoginHttp.createLoginSessionIdentity`/`appHeaders`（Task 8 范围）。

### 2.5 hive_ce 解码时机（迁移边界的事实依据）

核实 `hive_ce 2.19.3` 源码 `storage_backend_vm.dart`：
- `initialize(lazy: false)`（默认 `Hive.openBox`）→ `framesFromFile(...)` → **openBox 时全部记录同步解码**（eager）。
- `initialize(lazy: true)` → `keysFromFile(...)` 存 lazy frame，首访问才解码。
- 含义：**结构损坏的记录在 `Accounts.init()`/`GStorage.init()` 即抛错崩溃**（A/B 一致，非 B 回归）；旧 4 字段记录不是损坏——新 adapter 解码正常（4/5 为 null）。**迁移函数只能解决「结构合法但 schema 旧」这一真实升级路径**。

---

## 三、键命名空间冲突表

**核心结论（实测，非推测）**：
- 用正则提取 A/B 两仓库 `storage_key.dart` 全部键名常量 + 全 lib 树 `.get/.put/.delete` 裸字面量，做集合差：
  - **A 有而 B 没有的键：0 个**。
  - B 有而 A 没有的键：8 个（全部 OHOS 专属或已废弃，见下）。
- 任务简报提到的「A 新增键」（accountUnameMap、quickShareId、defaultAppealReason、apiHKUrl、saveImgPath/imageSavePath、enableImageBlock*）**在 B 中全部已存在**，语义一致。它们只是**消费方缺失的死键**（Task 1 死代码残留审计范畴）。
- 无任何 `SharedPreferences` 使用（两仓库均零命中）；无 `account_type` 存储键（AccountType 只作为 account box 记录的 field 3 序列化）；无 `api_host` 存储键（`http/api_hosts.dart` 的 `apiHostEntries` 是代码常量，`/apiHostSetting` 路由 B 已注册）。

### 冲突表（A 语义 | B 语义 | 风险）

| 键 | A 语义 | B 语义 | 风险 |
|---|---|---|---|
| `buvid`（`LocalCacheKey.legacyBuvid`） | 遗留全局 BUVID；`Accounts.refresh()` 主动删除 | 同键遗留；B 的 refresh **不删**（仅 guest 解析时读） | **低**。同语义，B 只是留赃不清理 |
| `guestBuvid` | 游客 BUVID，identity 解析 + **内存缓存** `_cachedGuestBuvid` | 同键同解析，**无内存缓存**（每次重新 resolve，值已持久化故稳定） | **低**。行为等价 |
| `preInitPlayer`（默认值） | `false` | `OS.isHarmony`（OHOS 上 true） | **低**。B 有意 OHOS 化 |
| `springDescription`（默认值） | `[1.0, 438.65, 41.89]` | `[0.5, 100.0, 2.2*sqrt(50)]` | **低**。默认值漂移，不影响已存值 |
| `horizontalSeasonPanel` / `horizontalMemberPage`（默认值） | `horizontalScreen` | `PlatformUtils.isDesktop` | **低**。漂移 |
| `dynamicsWaterfallFlow`（默认值） | `horizontalScreen` | `true` | **低**。漂移 |
| `autoPlayEnable`（默认值） | `true` | `false` | **低**。漂移 |
| `enableQuickDouble`（默认值） | `false` | `true` | **低**。漂移 |
| `touchSlopH`（默认值） | `deviceTouchSlop + 6.0` | `12.0` | **低**。漂移 |
| `fullScreenSCWidth`（默认值） | `kFullScreenSCWidth` | `255.0` | **低**。漂移 |
| `apiHKUrl` / `quickShareId` / `defaultAppealReason` / `saveImgPath` / `custom*BaseUrl` / `enableImageBlock*` 等 | 有消费方的功能设置 | **键存在、消费方缺失（死键）** | **中**。移植功能时必须消费既有键，**禁止改名**，否则双端 WebDAV 设置备份不互通 |
| `allowRotateScreen` / `enableHdsBar` / `enableLGBar` / `enableStatusBarTapToTop` / `expandBuffer` / `showActualVolume` | 不存在 | B 独有（OHOS 适配） | 无 |
| `defaultDecode` / `secondDecode` | 不存在（A 已移除） | B 独有（`@Deprecated`，`preferCodecs` 迁移残留，AGENTS.md A10 要求保留） | 无 |

**同名不同语义的真冲突：0 个。** 唯一需要留意的是 `'buvid'` 键——A/B 语义一致（遗留），但 A 主动清理、B 不清；T6 移植 A 的 `refresh` 后 B 也会清理。

---

## 四、4→6 迁移方案

### 4.1 为什么尾部追加天然安全（实测确认）

- `AccountTypeAdapter` 按 `obj.index` 序列化（typeId 10），读侧 `elementAtOrNull(byte) ?? main` 自带越界兜底。
- 枚举追加 `reply`(index 4)、`blacklist`(index 5) **必须与 A 顺序一致**（main, heartbeat, recommend, video, reply, blacklist）。旧数据只有字节 0-3 → 映射不变。
- `LoginAccount.type`（Set<AccountType>）经 adapter 写入的是一串 index 字节，无枚举名字符串 → 追加不破坏。
- **无需 remap 任何存储值**。所谓「4→6 迁移」实为「schema 追加字段 + 回填」，不是枚举值映射。

### 4.2 迁移函数签名（T6 落地建议）

```dart
// lib/utils/accounts/account_migration.dart（T6 新建）
/// 4→6 schema 迁移：把 B 旧 4 字段 LoginAccount 记录回填为 6 字段。
/// - field4 buvid：优先取账号 cookie 的 buvid3（保持 B 当前线上请求值不漂移）；
///   否则走 OwnerScopedIdentityPersistence 生成稳定值。
/// - field5 deviceProfile：AppDeviceProfiles.defaultDeviceProfileForOwner('account:$mid')。
/// 幂等：已 6 字段（needsBuvidPersist==false）的记录跳过。
/// 返回迁移条数。
Future<int> migrateAccountBoxV4ToV6(Box<LoginAccount> box) async {
  var migrated = 0;
  for (final key in box.keys) {
    final record = box.get(key);
    if (record == null) continue;
    if (!record.needsBuvidPersist) continue;   // 已是 6 字段，跳过
    final seeded = _seedAccountIdentity(record); // cookie buvid3 → field4；default profile → field5
    await box.put(key, seeded);
    migrated++;
  }
  return migrated;
}
```

**触发点（推荐）**：并入 `GStorage.init()` —— `Accounts.init()`（开 box）之后调用；同时移植 A 的 `Accounts.refresh()` 自愈语义（迭代 `needsBuvidPersist` 账号 `onChange()` 回写 + `Pref.deleteLegacyBuvid()`），两者互为冗余保障。

**回填策略二选一**（T6 必须显式决策）：
- **方案 A（推荐，连续性优先）**：field4 种子 = 该账号 cookie 的 `buvid3`（等价 B 当前 `_resolveBuvid()` 返回值）→ 升级前后 REST `'buvid':` 头**逐字节不变**，bilibili 风控侧视为同一设备。deviceProfile 用 `defaultDeviceProfileForOwner` 确定性分配。
- 方案 B（A 忠实）**：不取 cookie，直接 `OwnerScopedIdentityPersistence.resolve(owner: account(mid), storedBuvid: null)` → generated 一个全新稳定 buvid。缺点：升级后首个请求的 buvid 会变化（风控指纹漂移一次）。

### 4.3 边界情况

| 场景 | 行为 |
|---|---|
| **无账号**（box 空/从未登录） | 0 条迭代，no-op，无副作用 |
| **游客** | 不在 account box（游客 BUVID 在 `localCache['guestBuvid']`，已由现有 identity 解析+持久化覆盖），迁移不触碰 |
| **旧 4 字段记录**（真实升级路径） | 新 6 字段 adapter 解码正常（field4/5=null）→ `restored` 置 `needsBuvidPersist=true` → 迁移回填 |
| **损坏数据（结构损坏）** | hive_ce eager 解码在 `openBox` 抛错崩溃——**与 A 行为一致，非迁移可救**；不扩大范围 |
| **cookie 缺 DedeUserID**（半登录残迹） | `restored` → `_resolveLoginAccountIdentity` 的 `!['DedeUserID']!` 抛错 → openBox 崩溃；**与 A 行为一致**（A 的 adapter 同样不防御）。真实 B 数据不会出现（写入前提是登录成功含 DedeUserID） |
| **type 集合含越界 index** | adapter 层 `elementAtOrNull ?? main` 已兜底，无需迁移干预 |
| **重复/遗留键** | account box 键为 mid 字符串，无重复命名空间问题 |

### 4.4 回滚策略

- 迁移为**追加/回填、幂等**：重复执行是 no-op；新 adapter 读旧记录无损（null 兜底）。
- 降级（装回旧 B）：旧 4 字段 adapter 读 6 字段记录时按 `numOfFields` 只消费 0-3，**不崩溃**；但旧版一旦写回会丢掉 field4/5（buvid/deviceProfile 数据降级丢失）。**降级不可逆地丢设备档案，但不丢 cookie/登录态**——文档标注即可。
- Hive 无 schema 版本号机制；建议在 `migrateAccountBoxV4ToV6` 完成后不做额外备份（cookie 是主数据，迁移不动 cookie）。如需极致保险，可在首次迁移前 `box.toMap()` 快照到日志（侦察阶段不实施）。

### 4.5 自动 or 手动

**100% 自动，无需手动步骤、无需 UI 提示。**
- 现有 B 用户升级后：首次启动 `GStorage.init()` → 新 adapter 解码旧记录（不崩）→ 迁移回填 field4/5 → `Accounts.refresh()` 持久化 + 清旧键。
- B 现有 `http/init.dart:42` 的 `Accounts.refresh()` **未 await**（A 在 `http/init.dart:44` await）——T6/T7 建议对齐为 await，保证回填在首批请求前完成（否则首个请求可能带未回填的临时值，但 cookie buvid3 仍在，无实质破坏）。

---

## 五、对 T6 的执行建议

1. **adapter 6 字段**（`account_adapter.dart`）：按 A 重写 `writeByte(6)` + `LoginAccount.restored(...)`（field4/5 可空）；typeId 保持 9。**不要引入版本号字段**（与 A 不一致，且旧记录无该字段）。
2. **注册 AppDeviceProfileAdapter**（`storage.dart:100`）：文件已在 B 且逐字节同 A，只加 `import` + `..registerAdapter(AppDeviceProfileAdapter())`（typeId 13 无历史冲突）。
3. **account.dart**：按 A 补 `buvid`(field4)/`deviceProfile`(field5)/`_needsBuvidPersist`/`needsBuvidPersist`/`_persistedAccount`/`restored` 工厂/`onChange` 写 `_persistedAccount`；`_resolveLoginAccountIdentity` 用 B 已有的 `OwnerScopedIdentityPersistence.resolve`。保留 B 的 `_resolveBuvid()` 作为迁移回填种子来源。
4. **Accounts.refresh()**：按 A 移植（回填持久化 + `Pref.deleteLegacyBuvid()`）。注意 B 当前 refresh 迭代 `account.values`，adapter 变更后旧记录可正常解码。
5. **迁移测试**（`test/hive_migration_test.dart`，全计划最高优先级验收）：
   - **必须模拟真旧格式**：注册一个「旧 4 字段 fixture adapter」（复制当前 B adapter，typeId 9），写临时 Hive 目录（`debugSetAppSupportDirPath` 模式已在 B 测试中使用）→ 关闭 → 用新 6 字段 adapter 重开 → 断言：解码无崩溃、`needsBuvidPersist=true`、type 0-3 映射正确 → 跑 `migrateAccountBoxV4ToV6` → 断言 6 字段落盘、buvid 与 seed（cookie buvid3）一致、deviceProfile 非空且确定性。
   - 覆盖：空 box / 仅 buvid3 cookie / `type={main,recommend,heartbeat,video}` / 缺 DedeUserID（文档化抛错行为）。
   - 复用 B 已移植的 `test/identity_migration_test.dart` + `buvid_lifecycle_test.dart`——**它们正是 A 语义的验收契约（当前 RED）**，T6/7/8 落地后应转绿，一并纳入验证。
6. **依赖顺序**：T5（枚举→6 + api_type reply/blacklist 路由表）必须与 T6 同波完成；消费点已核实全部安全（`privacy_settings.dart:49` 有 `if (url == null) continue` 兜底；login controller 的 `selectAccount = List.of(accountMode)` 长度自适应；`for i < values.length` 循环自适应）。
7. **注意**：B 当前 `dart analyze` 可能因 RED 移植测试（缺失符号）报错；Batch 5 复核。`analysis_options.yaml` 未排除 `test/`。
8. **不改** box 打开为 lazy（保持 eager，与 A 一致）；**不改** `identity_owner.dart`（逐字节相同）；**不编辑** `*.g.dart`。

---

## 附：证据清单（本审计实读/实测项）

- B/A `lib/utils/storage.dart`：box 清单、adapter 注册差异（AppDeviceProfileAdapter 仅 A）
- B/A `lib/utils/accounts/account_adapter.dart`：4 vs 6 字段
- B/A `lib/utils/accounts/account.dart`：`_resolveBuvid` vs `_resolveLoginAccountIdentity`/`_persistedAccount`
- B/A `lib/utils/accounts/account_type_adapter.dart` + `cookie_jar_adapter.dart`：`git diff --no-index` 逐字节相同
- B/A `lib/utils/storage_key.dart` + 全 lib 裸键字面量集合差：A 无独有键，B 多 8 键
- B/A `lib/utils/accounts/identity_core/`、`identity_persistence.dart`：相同（1 注释差异）
- B/A `lib/utils/accounts/app_device_profile.dart`：`git diff --no-index` 逐字节相同；B 零引用
- B `test/identity_migration_test.dart` / `buvid_lifecycle_test.dart`：引用 lib 缺失符号（RED 契约）
- hive_ce 2.19.3 源码 `storage_backend_vm.dart`：eager decode 于 openBox
- B/A `lib/utils/accounts/api_type.dart`：B 缺 reply/blacklist 路由 + recommend 缺 `liveFeedback`
- B/A `lib/models/common/account_type.dart`：4 vs 6 值 + desc
- B/A `lib/utils/accounts/grpc_headers.dart`：静态全局 vs 按账号快照
- B/A `lib/http/init.dart`：`Accounts.refresh()` 未 await vs await
