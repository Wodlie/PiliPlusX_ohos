# learnings.md

## [2026-07-31] Task: T1 — 337-diff 三分类 + 残留审计

### 关键复用资产与结论
- 15 份对比报告的 `.txt` 清单（328 DIFF / 18 ONLY_A）比权威全量（337/27）少 9+9 个文件——缺 `lib/pages/common/*`、`lib/pages/mine/*`、`lib/scripts/*`、`lib/tcp/`、`lib/pages/AGENTS.md`。全量核对必须自己跑 SHA-256 递归 diff（`authoritative_lib.txt` 已存 cmp_reports/）。
- B 的 git 历史是"近 3 提交可追溯 + 单次 init 快照"：`5a4dd671f init` → `b11857c1e restore fork features` → `dda954016 minimize block filter`。判定 B 残留来源时，**只信 B 最近 2-3 个提交 + A 提交链**，B 再往前不可信。
- 三分类判据：**a/A 功能**（需移植）、**b/B OHOS 适配**（必须保留）、**c/双方漂移**（重构/同步/风格，不移植）。约 40% 是 c（纯构造器写法/点简写），移植时不要误碰。
- 大文件里 a+b 混存（grpc/im、http/init、video.dart、reply_item_grpc、pl_player/controller、video/controller、header_control）——移植需"只加不改"，用 B 现有分支做基底。
- 残留判定高频证据源：`git log -- <file>` 双侧、全库 grep 引用、SHA-256 对比 A/B。

### 可复用操作（后续 Task 直接采用）
1. 全量 diff：`Get-FileHash` 递归比较 lib/，输出 `status\tpath` 清单，与 cmp_reports txt 对照补缺。
2. 残留引用检查：`Get-ChildItem lib -Recurse | Select-String "<symbol>"` 找消费方；零引用即孤儿。
3. A/B 同文件比对：`git diff --no-index`（Windows 可用）+ SHA-256 判字节一致。



## [2026-07-31] Task: T2 (Hive 审计)
- Hive adapter 无版本号，靠 writeByte(numOfFields) 自描述；Hive box 记录可跨字段数读（多余字段忽略，缺字段 null）。
- AccountType 枚举序列化 = index（account_type_adapter 逐字节同 A）；追加枚举必须与 A 顺序一致（reply=4, blacklist=5）。
- A/B 键命名空间完全同构（A 0 独有 / B 8 独有）；默认值漂移集中在 8 个设置键（preInitPlayer/springDescription/horizontal* 等）。
- B 的 identity_core + OwnerScopedIdentityPersistence 是 guest-only 消费；account 侧（restored/needsBuvidPersist/_persistedAccount）缺失。
- B test/ 的移植测试是 RED 验收契约（引用 lib 缺失符号），是 T6/7/8 的可执行规格。
- 判断 adapter/文件是否同构：`git diff --no-index`（忽略行尾差异需用 --stat 判断）。

## [2026-07-31] Task: T3 (API 审计)
- media_kit fork 源码定位：读 `pubspec.lock` source 列 + `.dart_tool/package_config.json` 的 rootUri → `%LOCALAPPDATA%\Pub\Cache\git\<repo>-<sha>\`。B 用 cnoim `media-kit-9de37e13...`（1.2.3），A 用 My-Responsitories `media-kit-deac6b62...`（1.1.11）。
- fork API 面差异是"结构性的"：A fork 的 `Player.create`/`setMediaHeader`/`SimpleVideo` 不存在于 B fork——判断移植代码能否编译，**必须查实际 lock 解析的 fork，不能看上游版本号**。
- A fork 特性：`NativePlayer.create({PlayerConfiguration})`（real.dart:56）、`setMediaHeader({userAgent,referer,headers})`（real.dart:1906）、`screenshot→Future<ui.Image?>`、`video/simple_video_texture.dart`。B fork 特性：`maybeAsNativePlayer` 扩展在 B 的 `lib/media_kit_adapt/media_kit_adapt.dart:128`。
- B fork 的 `VideoController(Player, {configuration})` 构造内部分平台走 `Native/Android/Ohos/WebVideoController.create`（OHOS 有 `ohos_video_controller/real.dart`）。
- B fork `NoVideoControls = const null`（`media_kit_video_controls/src/controls/no.dart`）——`controls: NoVideoControls` 即禁用内置控件。
- 版本漂移项只存在于 vendored `lib/common/widgets/flutter/**`（3.32.4-ohos 引擎拷贝）；功能代码 grep 0 命中。判断方法：`Get-ChildItem lib -Recurse | Where FullName -notmatch 'common[\\/]widgets[\\/]flutter[\\/]' | Select-String <api>`。
- `part of` 文件在宿主无 `part` 声明时是孤儿（不编译、不报错）——排查"为何 B 里引用不存在的扩展方法还能编译"的方法论。
- B 现有 `selectableText()`/`selectableRichText()`（`common/widgets/selectable_text.dart`）是 OHOS 移动端 SelectableText 禁滚的官方替代；`selection_text.dart`（SAME）在 B 是死文件可复用。
- 本机工具链是 Flutter 3.44.4/Dart 3.12.2（全局），fvm 未装 3.41.9——"B 钉 3.41.9"是声明目标，本机验证环境实际更新。

## [2026-07-31] Task: T5 (AccountType 6 值 + api_type 路由表)
- 追加枚举安全：B 的 4 值（main/heartbeat/recommend/video, index 0-3）与 A 完全一致，reply/blacklist 直接追加尾部；Hive 按 index 序列化（account_type_adapter typeId 10），顺序与 A 一致即无数据错乱。
- `Api.liveFeedback` 在 B 全库 0 命中（A 的 api.dart:1022 有）——recommend 路由表不补该键，留 T21。
- reply/blacklist 表所需 9 个 API 常量在 B 的 api.dart 全部存在（replyAdd/replyDel/likeReply/hateReply/replyTop/replyReport/replySubjectModify/blackLst/relationMod）——路由表可直接移植。
- 消费点全部 index-generic（`values.length` 循环、`values[i]`、`firstWhere orElse: main`），6 值天然兼容；唯一需要改 UI 的是 privacy_settings.dart（A 版显示 title+desc+URL 列表并包 SelectionArea）。
- A 的 `http/video.dart:108 _accountTypeForRelationAct`（5||6→blacklist）在 B 不存在——属 T9 范围，T5 不补。
- `dart analyze` 总数（含 info）≠ error 数；基线 276 errors / 0 warnings，验收按 error 数对比。错误全部集中在 10 个孤儿 part/已知 RED 文件 + test/，改动文件 0 错误即达标。

## [2026-07-31] Task: T6（4→6 Hive 迁移 + 迁移测试）
- **本地 flutter test 编译阻塞确认（实证）**：任何 `import 'package:PiliPlus/utils/accounts/account.dart'` 的测试在本机 Flutter 3.44.4 都编译不过——传递链 `account.dart → accounts.dart → http/init.dart + pages/mine/controller.dart` 拉到 (1) B vendored 3.32.4-ohos 框架补丁（editable_text.dart 引用 `ExtendSelectionByPageIntent`，仅 OHOS 引擎有）(2) font_awesome_flutter-10.9.0（3.44.4 的 IconData 是 final class，扩展报错）(3) flutter_audio_session/flutter_inappwebview git fork 引用 `ohos` 平台成员。`flutter test test/smoke_test.dart` 可跑（只 import flutter_test）证明是依赖图问题不是 harness 问题。**只有 OHOS 3.41.9 SDK 环境（CI）能跑**。
- **纯 Dart 验证 harness 模式（可复用）**：在 temp 目录建独立 pubspec（hive_ce 2.19.3 + cookie_jar 4.0.9 + crypto 3.0.7），**真实复制**待验证文件 + 用 import 重写指向本地 stub，仅 stub 无关重依赖（Accounts/GrpcHeaders/Pref/IdUtils/Constants 5 个）。`dart run bin/verify.dart` 31 checks 全 PASS。这验证了真实 account.dart/account_adapter/account_migration 逻辑（仅 import 路径不同）。
- **PowerShell 陷阱**：`Re` 函数里 `@(@("a","b"),@("c","d"))` 嵌套数组被展平为字符串数组，`$p[0]`/`$p[1]` 变成字符下标 → 全局 `Replace('p','a')` 把 import 全弄坏。**修法**：用 `@{from=...; to=...}` hashtable 数组 + `[System.IO.File]::ReadAllText/WriteAllText`（UTF8 无 BOM），再跑一遍正常。
- **方案 A seed 语义（重要设计确认）**：cookie buvid3（`[0-9A-F]{32}\d{5}infoc`）**不通过** `validateBuvid`（要求 `X[A-Z][0-9A-F]{35}`）——所以 `restored` 每次读它都会"再生成"（source=generated，needsBuvidPersist=true），disk 值只有靠 **每次启动都跑的 GStorage.init 迁移钩子** 保持为 cookie buvid3。F2 测试证明值稳定（重开+再迁移仍回填同一 buvid3）。这是有意为之：方案 A 优先线上头不漂移，代价是每次 boot 有瞬时再生成。若未来要跨启动真幂等，得把 seed 改成 `deriveBuvidFromSeed(cookieBuvid3)`（validator 合法），但那会让线上 buvid 从 buvid3 变为派生值。
- **`restored` 工厂读回缺 buvid3 记录**：`LoginAccount._` 私有构造器体内 `cookieJar.setBuvid3()` 会把缺 buvid3 的 jar 补上 fresh buvid3 → `_resolveBuvid` 的 legacy-buvid 回退分支在正常流程不可达（decoded 对象 jar 必有 buvid3）。测试按实际行为断言（现场生成 seed）。
- **`.gitignore:152 test*` 过宽**：目录 `test/` 命中 `test*`，新测试文件被忽略；既有测试为规则前已跟踪。提交需 `git add -f test/hive_migration_test.dart`。
- **RED 契约进度**：identity_migration_test 21→3 errors（剩 request_identity_adapter/RequestIdentityAdapter/debugSetAppSupportDirPath，全 T8）；buvid_lifecycle 剩 13（T7 的 Accounts.mainIdentity/snapshot + T8 的 LoginHttp.appHeaders/createLoginSessionIdentity）；T6 符号全已提供。
- **`const AppDeviceProfile(...)` 不存在**：公共构造器是 factory，测试里要用普通构造。

## [2026-07-31] Task: T7（Accounts 状态机 + _resolveAccountSelection）
- **accounts.dart 状态机可整体按 A 重写**：该文件无 OHOS 专属分支（B 仅简单数组 vs A 状态机），`git diff --no-index` 后与 A 逐字节相同。`_AccountLifecycleRegistry extends ListBase<Account>` 让外部 `accountMode[i]` get/set + `List.of(...)` 全部兼容，login/controller + mine/controller 消费方零改动。
- **`_state` 静态初始化即构造 guest snapshot**：`OwnerScopedIdentitySnapshot.fromAccount(anonymous)` → `Pref.guestBuvid` → `GStorage.localCache`（static final eager init）——A/B storage_pref 同字节结构，无新增静态初始化风险。
- **account_mgr 的移植边界**：只加 `_resolveAccountSelection` + `onRequest` 解构 + `_saveCookies` canonicalize + identity_snapshot import；`toast`/dioError 的 OHOS 分支（`OS.isHarmony`、connectivity 单值 `.desc`、`// TODO 鸿蒙待适配`）原样保留。B 缺 A 的 `.transformTimeout` case 是既有漂移，不动。
- **`AnonymousAccount.delete()` 合并语义**：`Future.wait([cookieJar.deleteAll(), Pref.deleteGuestBuvid()]).whenComplete(setBuvid3)` + fawkes hack 前置——删除后 `Pref.guestBuvid` 重新生成（identity generator 对 guest owner 确定性，故测试断言 regenerated == initial）。
- **analyze 236 → 226**（-10）：buvid_lifecycle 13→5 errors，剩 5 全 T8（debugSetAppSupportDirPath/LoginHttp.appHeaders/createLoginSessionIdentity）；identity_migration 仍 3（T8）。剩余 226 = 85 孤儿 part + test/ RED，全部已知基线。

## [2026-07-31] Task: T8（RequestIdentityAdapter + http 身份接入 + wbi 风控）
- **analyze 226 → 181**（-45）：request_identity_adapters 16→0、web_gaia 10→0、identity_migration 3→0、buvid_lifecycle 5→0、grpc_identity 11→4（剩 4 全 T9 ImGrpc.buildSendMsgRequest/buildSyncFetchSessionMsgsRequest）。剩余 181 = 85 孤儿 part + 6 vendored（editable_text/vertical_slider）+ 90 非 T8 测试 RED。
- **RequestIdentityAdapter 按 A 原样移植零改动**：B 的 identity_core/app_device_profile/Constants.baseHeaders('x-bili-aurora-zone'=sh001)/IdUtils.genAuroraEid 与 A 字节级同构，A 文件可直接落盘（6285 字节）。T6/T7 的 Account.buvid/deviceProfile、OwnerScopedIdentitySnapshot、Accounts.mainIdentity 全被消费。
- **B 的 `Pref.buvid` 已 deprecated 且委托 guestBuvid**（storage_pref.dart:1164），故 B 的 `LoginUtils.buvid`（=Pref.buvid）语义与 A 的 `Pref.guestBuvid` 等价——grpc_headers.dart:19 仍依赖它，T8 不动。
- **身份字段接入要"补辅助方法 + 改调用点"两层**：test 只引用 @visibleForTesting 辅助方法（recommendAppQueryParameters/recommendAppIdentityHeaders/liveFeedIndexQueryParameters/appIdentityHeaders），但真正替换占位符（fp '1'*64、session '11111111'、device_name 'android'/'vivo'、buvid 全局单例）需把请求方法改走辅助方法。
- **member/dynamics/follow 的 web 身份字段 B 原本硬编码等价 JSON**（重构级差异），唯一真实差异：dynamics.createDynamic 的 device-req-json **缺 spmid**（B 版 `{"platform":"web","device":"pc"}` vs A 含 spmid 333.999）——移植后补上；member 的 dm_img 字段从随机 `Utils.base64EncodeRandomString` 换成 identity 确定性推导。
- **relationMod 的 fp=BrowserUa.pc 语义错误留 T16**（issues.md 既定决策），T8 不碰。
- **wbi 风控**：`encWbi` 首行 `appendRiskFingerprintParams`（4 个 dm_img_* 默认值，`??=` 不覆盖自定义）+ `getWbiKeys` else 分支 `.catchError` 兜底（debugPrint + return ''）。
- **accounts.dart 不 export Account**（只 import），http 文件签名要用 `Account` 类型需显式 `import .../accounts/account.dart`。
- **analyze 陷阱**：改掉某文件唯一的使用方后要复查 unused_import（member.dart 的 utils.dart、video.dart 的 constants.dart 因移除占位字段变孤儿 import，需同步删）。
- **现有 2 条 pre-existing warning**（storage_pref→login_utils、block_filter_settings→storage_pref 的 unused_import）非 T8 引入，文件未改不动。



## [2026-07-31] Task: T9（GrpcHeaders 按账号快照）
- **fawkes 双形态冲突**：Dart 不允许 getter 与同名函数共存。A 是 `fawkes(String sessionId)` 函数，B 的 T7 hack 调无参 getter——解法：保留无参 getter（`_buildFawkes(generateSessionId())`），newHeaders 走私有 `_buildFawkes(derived.sessionId)`。任务约束"不改 delete()"成立（getter 返回新 map 时索引赋值退化为无副作用，但编译通过）。
- **grpcHeaders 从 `late final`/`final` 改 getter**：account_mgr.dart:66 `options.headers.addAll(account.grpcHeaders)` 每请求调用 getter → 天然按账号快照；改 getter 不破坏 dio_http2_adapter 传输，grpc_req/init.dart 零改动。
- **`_buvid => LoginUtils.buvid` 回退等价性**：B 的 `LoginUtils.buvid` 是 `static final = Pref.buvid`（首次访问即冻结），而 `Pref.buvid` 委托 getter `guestBuvid`（实时）。按 A 用 `Pref.guestBuvid` 不仅语义等价且避免冻结旧值——比字面保留 LoginUtils.buvid 更正确。
- **纯 Dart harness 命名技巧**：临时 harness 的 pubspec `name` 必须与源码包名一致（`name: PiliPlus`），否则 `package:PiliPlus/...` 全解析失败。T6 的"import 重写"模式在复制真实文件到同路径时可省略——stub 放在原路径即可。
- **metadata/*.pb.dart 自包含**：只 import protobuf/fixnum + 自身 pbenum，无 part/pbjson 依赖，可独立复制进 harness。grpc_identity_test 4 个剩余 error 全是 T17 的 `ImGrpc.buildSendMsgRequest`/`buildSyncFetchSessionMsgsRequest`（T8 证据误标 T9，task brief 明确 T17）。
- **harness 断言即测试规格**：grpc_identity_test 中所有非 ImGrpc 断言（user-agent/authorization/buvid/mid/aurora-eid/device 字段/fp/guestId/metadata）已用 harness 56/56 PASS 覆盖，T17 落地后测试应整体转绿。


## [2026-07-31] Task: T10（BUVID 激活重试 + setCookie 对齐 + 昵称缓存）
- **generateSecureRandomBytes 在 B 全库 0 命中**（A 的 buvidActive 用 Utils.generateSecureRandomBytes(36)）——T8 的 _secureRandom 系列并不存在于 B 的 Utils；buvidActive 保留 B 的 Utils.random 生成（32+4 随机字节 + PNG IEND 魔数）。
- **B 的 setCookie sync 是旧上游继承，非 OHOS 选择**：git log -- lib/http/init.dart 只显示上游同步（sync: 跟进至 2.1.0）+ 上游 tweaks/fix，无 OHOS 改 sync 提交 → 安全对齐 A（async + wait Accounts.refresh()）。唯一调用方 main.dart:162 不 await（A 同），且 analysis_options 无 unawaited_futures/discarded_futures lint，无新 warning。
- **B 的 Accounts.refresh() T7 已是 Future<void>**，原 sync setCookie 里 Accounts.refresh(); 是 fire-and-forget（setWebCookie 可能与 refresh 竞态），await 后修复排序。
- **重试语义必须配 dio.post 直调**：Request().post() 内部 catch DioException 返回合成 Response（statusCode -1），非 2xx/网络错误不会抛出 → catch 永不触发 → activated 照样置 true，重试形同虚设。A 的注释明确这一点，直接移植。
- **mine/controller.dart 的 queryUserInfo 也写 setAccountUname**（A mine controller:107 对齐）——写入方共 2 处：login_utils.onLoginMain + mine.queryUserInfo；读取方 storage_pref.getAccountDisplayName。
- **analyze 基线 181 errors 保持**（B T9 后基线）；37 warnings 全 pre-existing（vendored 引擎 unreachable_switch/undefined_hidden_name、孤儿 part unused_import、test/ RED unused_import、buvid_lifecycle_test:11 已知 unused import）。
- **T7 的 delete() 确认无缺口**：Future.wait([cookieJar.deleteAll(), Pref.deleteGuestBuvid()]).whenComplete(setBuvid3) + fawkes hack，本任务未动 account.dart。

## [2026-07-31] Task: T11（CustomHost/HkApi 拦截器 + api_host_page 入口）
- **B 的 `api_hosts.dart` 与 A 逐字节同构**（apiHostEntries 12 项全同）——两个拦截器可直接消费，无需同步；B 的 storage_pref 已有 enableCustomApiHost/apiHKUrl/customAppBaseUrl 死键（T2 已发现），本任务接上消费方。
- **CustomHost/HkApi 两拦截器按 A 重写零改动可编译**（deps 全在：api_hosts/storage/storage_pref/constants/init/flutter_smart_dialog），只是 A 版的 Investigation Findings 长注释不保留（AGENTS 无注释约定 + 行号引用漂移）。
- **接入点 = RetryInterceptor 块后、LogInterceptor 块前**（B init.dart:236-257）——test/http/init_test.dart 断言链序 Retry < CustomHost < HkApi < Log，B 现有 AccountManager 是 setCookie 时追加（链尾），与测试无关。
- **B 的 extra_settings.dart 末尾（检查更新后）是加入口的正确位置**：B 版无 A 的"设置港澳台代理"+"自定义 API 主机"两项；因 B 的 ApiHostPage 内嵌开关，只加单个 NormalModel `Get.toNamed('/apiHostSetting')` 导航即可（不复制 A 的 SwitchModel+NormalModel 双项）。
- **A 的 grpc_req.dart:62-65 的 customAppBaseUrl 三元判断是唯一差异**，B 架构（gRPC-over-HTTP 走 Request().post）完全支持，按 A 补即可，无需重构传输层。
- **hk_api_retry_interceptor 固有 2 条 info lint**（avoid_void_async:9 onResponse、unnecessary_await_in_return:71）——dio onResponse 签名是 void 但要 await 重试，A 原实现同款；info 级不阻塞 gate。
- **analyze 181 → 163（−18）**：恰为 init_test.dart 的 18 个 undefined 错误转绿；37 warnings 保持（T10 基线），无新增 error/warning。
- **PowerShell 陷阱**：`$out = cmd 2>&1` 后 Select-String 计数可能为 0（ErrorRecord 对象），要直接管道 `cmd 2>&1 | Select-String -SimpleMatch "warning - "` 才准。

## [2026-07-31] Task: T12（港澳台番剧 hk_bangumi + media_hk_bangumi + pgc 代理）
- **B 的 http/search.dart 缺 storage_pref import**：A 有 utils/storage_pref.dart（line 17），B 的对应位置是 wbi_sign——补 hk 分支后必须补 import，否则 Pref undefined。移植 A 时**先对比 import 清单**。
- **B 的 pgc/controller.dart 缺 http/api.dart import**：A 的 controller 引 Api.pgcTimeline/pgcIndexResult，B 之前硬编码在 PgcHttp 内；恢复 apiUrl 参数后 controller 直接引 Api，需补 import。
- **apiUrl 参数恢复的调用方全量检查**：PgcHttp.pgcIndex/pgcTimeline 全库调用方只有 pgc/controller.dart（grep 确认 2 处）——加 
equired String apiUrl 不破坏其他调用点。
- **枚举追加的穷尽性检查清单**：改 SearchType/HomeTabType 后 grep switch (this) / switch (item) / switch (searchType) 找穷尽 switch；live_search/member_search 的 searchType 是独立枚举，不受影响。
- **HomeTabType.values 自动接线**：home/controller.dart 默认 tabs = values → 新枚举值自动出现；style_settings defaultBars 同。hk_bangumi 插在 bangumi 后使 cinema index 5→6，与 A 一致即可（不迁移 tabBarSort）。
- **info 级 lint 容忍**：hk_bangumi 触发 constant_identifier_names（info），A 同文件同 lint，不阻塞 gate；baseline 只按 error/warning 计数。
- **analyze 159 vs 163**：T12 后 error 数比 T11 基线少 4（全在既有 test/ RED，非本任务引入）；7 改动文件 0 error。验收标准是"不新增"，比基线低即达标。

## [2026-07-31] Task: T17（sessionDetail + build* 包装 + whisper 标为已读）
- **SessionInfo 双定义**：`app/im/v1.pb.dart:4137` 与 `im/type.pb.dart:3055` 都有 SessionInfo；sessionDetail 响应用 type.pb 的（含 ackSeqno:3273 供标已读），im.dart import 首行加 `hide SessionInfo`（A 同款），whisper item 的 Session 仍来自 app/im（show 子句不受影响）。
- **ReqSessionDetail 字段**（interfaces/v1.pb.dart:1764）：talkerId(1,int64)/sessionType(2,int32)/uid(3,int64)，B 已含，无需重新生成 pb。
- **T9 注入保留法**：恢复 build* 时把 sendMsg/syncFetchSessionMsgs 内联的 ReqSendMsg/ReqSessionMsg 抽成 build* 方法并返回，`devId: GrpcHeaders.currentImDeviceId()` 原样保留——测试断言 devId==derived.deviceId 且 isNot('1') 由该注入满足。
- **showMenu spread 陷阱**：items 列表用 `if (...) ...[` 展开后无法推断 E（PopupMenuEntry<dynamic> vs List<StatefulWidget> 报错），必须显式 `items: <PopupMenuEntry<Never>>[`（A 原版就这么写）。
- **长按 dialog context**：builder 参数必须 `(_)`（A 模式），否则闭包里 context 是 dialog 的，`(context as Element).markNeedsBuild()` 不会重建 ListTile；desktop 右键菜单内 _updateAck(context) 用的是 ListTile 外层 context（闭包捕获 build 的 context），天然正确。
- **analyze 计数瞬时抖动**：并行 Task（T12/T13 写 pgc/search）时 analyze 首跑可能瞬时报 250，等稳定后再取数；159 = 163 基线 − 4（grpc_identity 全绿），分布 85 context_menu + 68 test + 6 vendored 与基线结构一致。
- **grpc_identity_test 转绿**：剩 4 错误（buildSendMsgRequest/buildSyncFetchSessionMsgsRequest 各×2）本任务清零，T9 learnings 确认的验收目标达成。

## [2026-07-31] Task: T13（AI 总结多服务：router + legacy/multimodal/subtitle + 设置组）
- **B 的 ai_summary 基础设施已齐，T13 只补 router+adapters**：Pref.aiSummaryService/BaseUrl/ApiKey/TextModel/MultimodalModel/TimeoutSeconds + SettingBoxKey 全在；openai_compatible_summary_provider / ai_summary_service / video_summary_provider / bilibili_legacy_summary_adapter / video_ai_conclusion 全套模型均与 A 逐字节 SAME → 3 个新文件按 A verbatim 零改动可编译。
- **B 的 video.dart 不 import material**（只 show compute, visibleForTesting），A 能直接用 data.durl?.firstOrNull 是因为 A 走 material 间接 re-export；B 必须补 import 'package:collection/collection.dart' show IterableExtension;，否则 firstOrNull 未定义。
- **B 的 ugc/controller 保留 static getAiConclusion**：A 已删除该方法但 video_popup_menu.dart 仍调用（A 是编译破坏的遗留）；B 不能删，否则 popup menu 的 AI总结 入口编译失败。实例 aiConclusion() 换成 router 版即可。
- **鸿蒙待适配 TODO 不动**：pages/video/view.dart:1951 showAiBottomSheet 仍消费 iConclusionResult!（AiConclusionResult?），controller 字段类型不变就不会碰它。
- **_ => 兜底 warning 是 A verbatim 固有**：messageForResult 的 sealed switch 穷尽后 _ => 触发 unreachable_switch_case（warning 级，--no-fatal-warnings 不 gate）；A 同代码同 warning，为保一致保留。
- **widget 测试在本仓库无法编译**：lib/common/widgets/flutter/text_field/editable_text.dart:5559（ExtendSelectionByPageIntent not found）是基线 error，任何间接 import material 的测试（含无关的 fractionally_sized_box_test）都编译失败 → 环境性限制，RED 验证只能以 analyze 级 0 error 为准。
- **source-contract 测试是可行的运行验证**：video_summary_routing_test（dart:io File 读源 + flutter_test）2/2 PASS；test/http/ai_summary_test.dart 38/39 PASS，唯一失败 model_result.dart 期望 List<Subtitle>? subtitle 是既有契约 bug（模型两仓库 SAME 且无该字段，A 同样失败）。
- **analyze 计数**：159（T12/T17 后基线）→ 146（−13 = 12×messageForResult + 1×hasContent），与 T17 notepad 的基线推导一致。

## [2026-08-01] Task: T14（checkBlockReason 5 策略 + BlockedReplyBanner）
- **B 的 reply_item_grpc 是 StatelessWidget，A 是 StatefulWidget**：banner 折叠需要 ``_expanded`` 状态，必须整类转换（全部字段加 ``widget.`` 前缀 + 静态成员加 ``ReplyItemGrpc.`` 前缀）。机械但必须谨慎；T15/T16 也在同文件，转换后 ``_ReplyItemGrpcState`` 是后续宿主。
- **测试契约优先于 A 实现**：B/A 相同的 ``blocked_reply_banner_test.dart`` 要求 ``BlockedReplyBanner(onExpand:)`` 无 replyItem 可构造，且 ``find.text('此评论已被屏蔽。')`` 精确匹配——A 恒渲染 ``'…（$briefReason）。'`` 且 replyItem 必填，A 自身也过不了该测试。适配：replyItem 可选，briefReason 默认 ``'被屏蔽'`` 时渲染无括号文案。
- **``checkBlockReason`` 不写 ``_blockedReasons``**：只有 ``mainList``/``detailList``/``dialogList``（banner 模式）和 ``blockReply`` 落库。``getBriefBlockReason``/``isClientBlocked`` 读的是内部 map——harness 里直接调 ``checkBlockReason`` 后断言 ``isClientBlocked`` 是错的（首次 harness 3 个假失败即此）。
- **blocked_reply_filter_test 的 ``_applyBannerMode``/``_applyRemoveMode`` 是测试内复刻**，断言 marked id 集合，不调用 ``isClientBlocked``——真实 mainList 的落库行为由 mainList 直接测试（canned response 桩）验证。
- **pure-Dart harness 复用配方（T6/T9/T13 升级版）**：pubspec ``name: PiliPlus`` + fixnum 1.1.1/protobuf **6.0.0**/hive_ce 2.19.3（**必须钉 protobuf 6.0.0**，生成 pb 引用私有成员 ``$_clearField``/``ProtobufEnum.$_initByValueList``，新版 3.x 无）；复制真实 ``lib/grpc/reply.dart`` + 全部 ``lib/grpc/bilibili/**``（99 文件自包含）；stub GrpcReq/GrpcUrl/Constants/LoadingState/GlobalData/Pref/GStorage/SettingBoxKey。GrpcReq stub 用 ``Map<String, List<GeneratedMessage>>`` FIFO 队列即可驱动真实 ``mainList`` 递归 auto-page。
- **PowerShell 陷阱**：``print('RESULT: $(_passed)...')`` 的 ``$(...)`` 在双引号 here-string 里被求值，必须用单引号 here-string 写含 ``$()`` 的文本；``SettingBoxKey`` 无 blackMids（在 ``LocalCacheKey``）。
- **analyze 计数**：146 → **116**（−30），三测试文件清零（block_reason 23/blocked_filter 6/banner 3），改动文件 0 error 0 warning，总 warning 无新增。
- **``flutter test`` 会改 pubspec.lock（pub 镜像 URL 重写 pub.flutter-io.cn→pub.dev）**——验证后需 ``git checkout -- pubspec.lock`` 恢复，保持 diff 干净。

## [2026-08-01] Task: T15（评论翻译横幅 + 站内评论申诉）
- **B 的 TranslateReplyResp 双定义**：`grpc/reply_translate.dart`（手写，SAME）与 `grpc/bilibili/**/v1.pb.dart:14093`（生成，B 重新生成过）都定义 TranslateReplyResp；B 的 grpc/reply.dart 不 import reply_translate.dart（避免冲突），返回类型解析自 v1.pb.dart。controller 只用模式匹配 `Success(:final response)` + `response.translatedReplies[rpid]`，不 import reply_translate.dart 也不会歧义。
- **B 的 translateReply 签名是单条** `{required Int64 type, required Int64 oid, required Int64 rpid}`（T14 保留），controller.translateReply 直接按此调用，与 A 的 `rpids: List<int>` 批量签名不同——无需强改。
- **`DefaultCookieJar.toJson()` 来自 account.dart 的 `BiliCookieJar` extension**（account.dart:348）——删掉 `import .../accounts/account.dart` 后 reply_utils 立刻 undefined_method（新 error）。extension 方法计入 import 使用，恢复 import 无 unused 警告。删 import 前先 grep 依赖它的 extension。
- **移除内联 `_buildTranslateBtn` 后 http/loading_state.dart import 变孤儿**（该文件曾用 `Success` 模式匹配）——改为 param 式翻译后 `res case Success` 移入 controller，widget 不再需要。检查被删函数独占的 import 是否成了孤儿。
- **view.dart 是翻译功能必需接线点**（brief 未列但必须改）：`onTranslate`/`translatedText`/`isTranslating` 全靠消费方传入；`onTranslate == null` 时 buttonAction 回退 cardLabels 分支（不显示翻译按钮）。功能接线改动属任务核心而非范围蔓延。
- **B 的 ReplyHttp.replyReplyList 无 `account:` 参数**（isLogin:true 内部走 Accounts.main）——A 状态机的 `account: Accounts.reply` 调用点在 B 直接省略。
- **模型已支持 8 状态机**：ReplyItemModel.rpid/invisible、ReplyReplyData.replies/root、ReplyRoot.invisible 全在，无需补模型。
- **analyze 116 保持**（T14 基线）：6 改动文件 0 error 0 warning。中间 117 因 account.dart import 丢失，116 因 loading_state.dart 孤儿 import 修正（1 上 1 下回平）。
- **test/ 无 appealComment/translateReply RED 引用**（仅 reply_translate_test 引 pb 层 map，与功能无关）——本任务无测试转绿负担。

## [2026-08-01] Task: T16（canSort + 长按拉黑/分享 + 手动加载图 + 孤儿 part 删除）
- **删 3 孤儿 part 即 −85 errors**：`dyn_menu_helper/reply_menu_helper/live_menu_helper` 声明 `part of` 但宿主无 `part` 声明。`git rm` 后 analyze 116 → **31**（= 25 test RED + 6 vendored，全已知基线）。这是 B 史上最大单次 analyze 下降。
- **canSort 全套 4 点**：`ReplyController` 加 `RxBool canSort = true.obs`；`customHandleResponse` isRefresh 里 `canSort.value = subjectControl.switcherType == Int64(1)`（pb 的 switcherType 是 `Int64`，直接 == 编译通过）；`onRefresh` 复位 true；`queryBySort` 加 `!canSort.value` guard。view 侧按钮 onPressed/icon/label 三处门控 + 「排序不可用」。T15 的 inline 翻译架构不动，故不移植 A 的 translatedReplies/translateReply。
- **长按菜单拉黑/分享照 A verbatim 可编译**：`VideoHttp.relationMod(mid, act:5, reSrc:11)`、`GlobalData().blackMids.add`（Set<int>）、`Pref.setBlackMid`、`ShareUtils.shareText(url)`、`IdUtils.av2bv` 全部已存在于 B——T16 只做 UI 接线。分享 URL switch 分支（1=video/12=cv/11||17=opus/_=兜底）直接照抄。
- **手动加载图的最小移植**：B 的 `ImageGridView`（OHOS 版）**没有** `tempUnblockedUrls` 参数——A 的 `_buildCommentImages` 里 temp-unblock/key 重建逻辑属图片屏蔽（Task 20），本任务只移植 `_loadManualImages` + 占位按钮，不传 tempUnblockedUrls。删减 A 代码时先确认依赖参数在 B 存在，否则留到对应 Task。
- **relationMod fp 修正**：B 原 `'fp': BrowserUa.pc`（T1 issues #11）。修法：`RequestIdentityAdapter.fromAccount(account: Accounts.main, userAgent: BrowserUa.pc).fpLocal`。A 用 `_accountTypeForRelationAct(act)`（5||6→blacklist）但 B 无此函数（T5 已记录），保持 B 的 `Accounts.main` 语义是正确折中。B 的 video.dart 已 import request_identity_adapter.dart（T8 遗留），零新 import。
- **test/ RED 检查**：storage_pref_test:212 只查 `SettingBoxKey.manualLoadCommentImage` key 存在（已在），canSort/relationMod 无测试引用——本任务无转绿负担。
- **scope 纪律**：A 的 morePanel 还有 屏蔽图片/恢复图片显示/临时恢复 + 举报 onBlockImages（Pref.enableImageBlock）——基础设施 B 全有（image_block_service.dart/全局 4 引用），但属 Task 20 域，本任务不碰，避免与 T20 冲突。

## [2026-08-01] Task: T23（历史续播 progress + SponsorBlock 无痕抑制）
- **T23 的 page_utils 只需验证，viewPugv(progress:) 属 T27**：plan 里 Task 27 明确管 `viewPugv(progress:)`，T23 的 `viewPgc/viewUgc` 判定中 viewPgc 与 toVideoPage（UGC 入口）都已有 progress 参数——**不要**在 T23 顺手给 viewPugv 加 progress，避免与 T27 冲突。item.dart 的 cheese 分支把 progress 传给 viewPgcFromUri（B 的 viewPgcFromUri 接收 progress 但对 pugv 路径丢弃，forward-compatible，等 T27 接线）。
- **resumeProgress 语义**：item.progress 单位是秒、且 `-1` 表示已看完、`0` 表示未看——A 用 `switch (item.progress) { final int progress when progress > 0 => progress * 1000, _ => null }` 过滤，播放页 progress 单位是毫秒。直接照抄 A 的表达式即可（item.progress 是 `int?`，pattern 匹配 int 自动处理 null）。
- **B 的 block_mixin 缺两个 import**：B 原本 `foundation show kDebugMode`（缺 debugPrint）、无 `pages/mine/controller.dart`。补上才过编译。`Pref.suppressSponsorBlockIncognito`（storage_pref.dart:906）与 `MineController.anonymity`（static RxBool）在 B 都**已存在**，T23 只是恢复使用点。
- **catchError 链式缩进**：B 的 `_doVote` 是单行 `SponsorBlock.voteOnSponsorTime(...).then(...)`，追加 `.catchError` 后注意缩进（A 用 `.catchError((e) { debugPrint(...); })`）。debugPrint 不触发 avoid_print。
- **RED 检查结论**：test/ 只有 storage_pref_test 断言 SettingBoxKey key 存在（T 系列通用），无 block_mixin/history 行为引用 → 本任务无转绿负担。
- **analyze 31 保持**：改动 2 文件（history/item + block_mixin）0 error 0 warning，总 error 数 31 = T16 基线，无新增。与并行任务（T18-T22 写 live/http/accounts 等）共存不影响计数。

## [2026-08-01] Task: T21 — 直播不感兴趣反馈（liveFeedback）
- **T5 预留验证：未加**。B 的 api_type.dart recommend 路由表只有到 `Api.liveSearch`（T5 时 `Api.liveFeedback` 常量不存在，加不进）——本任务补上，与 A 位置一致（`Api.liveSearch` 之后、`Api.bgmRecommend` 之前）。
- **B 删的不止 http 层**：`liveFeedback` 全库 grep 0 命中，但 `models_new/live/live_feed_index/feedback.dart`（Feedback/Reason 模型）**还在**，只是 `CardLiveItem` 没接 `feedback` 字段。恢复需 3 处：`api.dart` 常量 + `live.dart` 方法 + `card_data_list_item.dart` 字段解析。
- **`liveFeedback` 方法参数**：`Object roomId, Object id, String type`（roomid/id 用 Object 因为 JSON 可能是 int 或 String），`type: 'dislike'` 固定。签名照抄 A（live.dart:773-808），B 的 `?recommend.accessKey` null-aware 语法已支持。
- **按钮位置**：任务描述写"右上角"，但 A 实际实现是 Stack 右下（`right: -5, bottom: -2`）——照 A 实现为准，不要改位置。
- **live_item_app 依赖**：需补 import `http/live.dart`、`feedback.dart`、`search_text.dart`、`iterable_ext.dart`、`flutter_smart_dialog`、`get`——B 全已存在（无新依赖），只是 A 版 import 被删。
- **analyze 31 保持**：5 文件改动（api/live/card_data_list_item/live_item_app/api_type）0 error，总 error 数 31 = T16 基线。

## [2026-08-01 00:41] Task: T22（快速分享 + pmShare + enableQuickShare/quickShareId）
- **B 的 pmShare 已完整，零修改 request_utils.dart**：T3 审计确认正确——用 `Accounts.main` + `SelectableText`（OHOS 适配已就位）。A 的 `avoidGetBack = false` 参数是死参数（A 函数体内从未引用，grep 仅声明行），B 调用方正确省略。
- **3 处 onLongPress 只需 import + ActionItem 追加**：header_control.dart 缺 `request_utils` import；ugc/view.dart 缺 `storage_pref` import；pgc/view.dart 缺 `request_utils`+`storage_pref`+`flutter_smart_dialog`（common/widgets/dialog/dialog.dart 不 re-export SmartDialog，须直接 import flutter_smart_dialog）。consumption 模式照 A verbatim（Pref.enableQuickShare 门控 + Pref.quickShareId ?? 1004428694 + pmShare），仅删 avoidGetBack。
- **pmShare 消息结构**（3 处一致）：`{id: aid, title, headline, source: 5, thumb: pic, author: owner.name, author_id: owner.mid}`——A/B 逐字相同。
- **storage_pref_test 已绿**：test/storage_pref_test.dart:171,175 只断言 SettingBoxKey.enableQuickShare/quickShareId 键存在，Pref getter 已用，无 RED 负担。
- **analyze 31 = 基线持平**：3 改动文件 0 error；grep SelectionText( 在 lib/pages/video/ 0 命中，request_utils.dart 保持 SelectableText（line 364,581）——无泄漏。

## [2026-08-01] Task: T20（图片屏蔽 pHash UI 接入）
- **B 的 image_block_service.dart 是 SAME**（含 evaluateBlock/getCachedBlockResult/addBlockedImage/blockImage/unblockImages/invalidateResultCache + `Pref.enableImageBlock` 守卫 + 持久 Isolate worker）；T20 只做 UI 消费。gallery_viewer 的 blockImage 手动去重逻辑照 A（pHash 去重 + invalidateResultCache），image_grid 的 addBlockedImage 内部已去重无需手动。
- **visibility_detector 是 B 的传递依赖（0.4.0+2，lock 已解析）非直接依赖**——`depend_on_referenced_packages` 未启用（grep analysis_options 0 命中），但为干净起见提升为直接依赖 `^0.4.0`（graph 无新包，pub get 不变更 lock）。这是「不引入新依赖」guardrail 的最小平移。
- **BlockedImagePlaceholder 构造签名破坏性变更**（无参 → 必填 width/height）：全库仅 image_grid_view 消费（grep 确认），无其他调用方破坏。
- **image_grid_view 的 StatefulWidget 转换**：B 版参数（picArr/onViewImage/fullScreen）+ OHOS 适配（PlatformUtils.isMobile/isDesktop、`dart:io show Platform`）与 A 版同构，A 是超集 → 整体按 A 落盘零冲突；`Style.mdRadius`/`imgRadius`/`imgMaxRatio`/`context.mediaQueryShortestSide`/`size_ext.cacheSize` B 全有。
- **举报联动消费点**：T16 已把 reply_item_grpc 的 morePanel 屏蔽菜单+onBlockImages 明确留给 T20——brief 交付物列 4 个 common 文件，但任务标题含「举报联动」且 T16 notepad 有转移记录，故补做了 reply_item_grpc 消费接线（`_tempUnblockImageUrls`/`_blockImageVersion` 状态 + tempUnblockedUrls 传参 + 屏蔽图片（多图多选 dialog）+ 恢复图片显示 + report onBlockImages）。B 的 ownerMid 用 `Accounts.main.mid`（A 用 `Accounts.reply.mid`），保留 B 语义。
- **hasBlockedImages/hasUnblockedImages 检测**：`getCachedBlockResult` 三态（null=cache miss 视为未屏蔽），仅 Pref.enableImageBlock 开启时检测；屏蔽菜单按 hasUnblockedImages 显示、恢复菜单按 hasBlockedImages 显示。
- **analyze 31 保持**（T16 基线）：4 个 common 文件 + reply_item_grpc + pubspec 改动 0 error 0 warning；image_grid_view_test/image_block_service_test/phash_cross_resolution_test 全转绿（analyze 级）。并行任务（T18/T19/T21/T22/T23）写入时 analyze 计数会瞬时抖动（37→31），等稳定后再取数。
- **Runtime-pending**：pHash 屏蔽评估、长按查看、举报联动屏蔽图片需真机验证；验收以 analyze 0-error + 符号接线为准。

## [2026-08-01] Task: T18（Stein 互动视频模型 + 进度恢复）
- **4 个 edgeinfo 模型可直接按 A 逐字节恢复**：choice/data/edges/question 依赖（preload/skin/story_list/video/dimension/interaction）在 A/B 全部 SHA SAME，B 只需恢复这 4 个 DIFF；git diff --no-index 空输出即字节一致，但 Windows CRLF 会导致 --stat 显示差异，用归一化（CRLF→LF）后字符串比较判等。
- **controller 的 stein 逻辑可整段移植**：A 的 steinResumeNode/_checkSteinResume/goToSteinStoryNode/历史栈不触播放器内核，依赖（UgcIntroController.onChangeEpisode 的 isStein 参数、Part(cid:)、plPlayerController.seekTo、firstOrNull）在 B 全在，逐段移植零改动可编译。
- **goToSteinStoryNode 的 seek 语义**：storyNode.cursor>0 优先；startPos<10000 时 ×1000（秒→毫秒）；500ms 延迟等待 onChangeEpisode 生效后再 seek。
- **_findCurrentSteinNode 兜底构造**：edgeInfo.edgeId==requestedEdgeId 且 story_list 找不到时，用 StoryList(edgeId,title,cid: preload?.video?.firstOrNull?.cid ?? cid.value, isCurrent:1) 从顶层字段构造——API 的 story_list 可能只有起点。
- **进度恢复对话框 UI 属 T19**：A 的 _showSteinResumeDialog/_showSteinHistorySheet/_steinResumeWorker/interactiveChild/showStein 全在 pages/video/view.dart + pl_player（06_video_report §22.4）；T18 只交付控制器侧 Rx 信号（steinResumeNode）+ goToSteinStoryNode + steinHistory/recordCurrentSteinNode，T19 view 用 ever(steinResumeNode,...) 弹框并在选项点击前调 recordCurrentSteinNode。
- **info 级 lint 容忍**：A verbatim 的 _checkSteinResume 有 curly_braces_in_flow_control_structures（controller.dart:1194，A 同 1180），info 级不 gate，--no-fatal-warnings 通过。
- **analyze 31 保持**：4 模型 + controller 0 error 0 warning；test/ 无 stein 引用（0 RED 负担）。
- **并行任务干扰**：git status 含 T20-T23 文件改动（image_block/report/live/api 等），本任务只动 5 个文件，diff 需按文件隔离查看。

## [2026-08-01] Task: T26（下载按 UP 主名过滤 + 保存评论图强制原文）
- **UP 过滤只需加 ownerName 到 where 子句**：B 的 `BiliDownloadEntryInfo.ownerName`（String?）早在模型（bili_download_entry_info.dart:38），`customGetData()` 照 A 补 `(e.ownerName?.toLowerCase().contains(text) ?? false)` 即可，无需补模型或 import。
- **forceShowOriginalContent 消费点 = save_panel/view.dart 的 ReplyItemGrpc**：T15 只在 reply_item_grpc.dart 定义了参数（默认 false，`!widget.forceShowOriginalContent` 分支控制折叠/原图，reply_item_grpc.dart:178,207），A 的消费点就在 SavePanel 的保存渲染里（A save_panel/view.dart:378）。接线 = 在该处传 `forceShowOriginalContent: true`，一行搞定。
- **保存图「强制原文」的语义**：SavePanel 用 IgnorePointer + ReplyItemGrpc 渲染静态保存图，`true` 使图片不被折叠为小图/不触发布局限制，走原图分支——非保存场景（真实回复列表）保持默认 false，不回归。
- **analyze 31 保持**：改动 2 文件（download/search/controller + save_panel/view）0 error 0 warning，总 error 数 31 = T16 基线。改动点与其他并行任务（T24/T25/T27-29）不重叠。
- **约束满足**：下载多选分享（onRemove/多选逻辑）未触碰；download_manager/download_service 未改；无桌面分支；无 *.g.dart/*.pb*.dart 编辑。

## [2026-08-01] Task: T19（Stein 互动视频播放器 UI）
- **B 已残留部分 stein UI**：playerListener onCompleted 的 stein 检查（`steinEdgeInfo?.edges?.questions?.firstOrNull?.choices?.isNotEmpty` → showSteinEdgeInfo=true）和 videoPlayer（竖屏）的 stein 选项 Obx 在 B 原本就在（`lib/pages/video/view.dart`，与 A 同款且无 recordCurrentSteinNode）。T19 真正缺的是：枚举值 + PLVideoPlayer 的 showStein/interactiveChild 参数 + 进度恢复弹框/回溯面板 + 横屏/通用播放器的 interactiveChild 选项条（含 recordCurrentSteinNode）。
- **A 的 `.stein` 不在默认底部控制列表**：`buildBottomControl` 的 switch case（`BottomControlType.stein => ComBtn(...)`）存在，但 `userSpecifyItemRight` 默认列表**不含** `.stein`（A 自身如此）；`isStein` 局部变量在 A view.dart 也是死代码（401-403 计算后从未使用）。stein 主入口是 interactiveChild 的「进度回溯」TextButton（`steinHistory.length > 1` 时显示）。照 A 保持，不把 .stein 挂进默认列表。
- **HistoryNode 在 interaction.dart 非 story_list.dart**：`models_new/video/video_play_info/interaction.dart` 定义 HistoryNode（nodeId/title/cid），`story_list.dart` 定义 StoryList（nodeId/edgeId/title/cid/startPos/cover/isCurrent/cursor）——view 需要两个 import 才能过编译。
- **`StoryList? targetNode = ... ?? storyList.last` 触发 unnecessary_null_comparison**：`?? storyList.last` 兜底使 RHS 非空，后续 `if (targetNode != null)` 恒真。A 同代码同 warning（A view.dart:257），A verbatim 保留。
- **A verbatim 也会带 lint 噪音**：pages/video/view.dart 的 stein Container（仅 Decoration）触发 use_decorated_box（info，A view.dart:275 同款）——判断"是否引入新 lint"时先跑 A 对照，同款即接受。
- **grep 到 274 行 diff 全是 view 接线**：pl_player 只 +19 行（构造器 2 参数 + 字段 2 + switch case 13 + interactiveChild 2），真正主体在 pages/video/view.dart（弹框 + 面板 + 选项条）。controller 零改动（T18 已交付 VideoDetailController 侧全部字段，PlPlayerController 无 stein，A 同）。
- **analyze 31 保持**：改动 3 文件 0 error；新增 1 warning + 1 info 均为 A verbatim（对照 A 分析确认）。T25 与 T19 同文件（pl_player view），改动点不重叠（T19: 构造器/switch/interactiveChild；T25: 快捷操作），串行即可。

## [2026-08-01] Task: T25（播放器快捷操作：长按倍速/比例 + fastForBackwardDuration_ + HDR 弹窗）
- **B 的 storage_pref/storage_key 双键早已存在**：Pref.fastForBackwardDuration（forward，storage_pref.dart:658）与 Pref.fastForBackwardDuration_（backward，storage_pref.dart:661）及对应 SettingBoxKey 全在——T25 只需在 controller 补 late final fastForBackwardDuration_ = Duration(seconds: Pref.fastForBackwardDuration_);，view 的 BackwardSeekIndicator 改引用它；ForwardSeekIndicator 保持 astForBackwardDuration。
- **B 的 controller 方法已齐**：setPlaybackSpeed（:1227）/	oggleVideoFit（:1403）B 原本就有——长按切换零新增方法，只做 UI 包裹。
- **view.dart 缺 feed_back.dart import**：B 的 eedBack()（utils/feed_back.dart，与 A 逐字节同构）存在但 view.dart 未 import，补 import 'package:PiliPlus/utils/feed_back.dart';（插在 android/bindings.g.dart 前，对齐 A 顺序）。
- **fit 分支 B 用局部 inal fit 捕获**（A 在回调内实时读 ideoFit.value）：因 Obx 随 videoFit 变化同步重建，闭包捕获的 fit 恒为最新，功能等价；保留 B 的局部变量风格更省 diff。
- **qa HDR 弹窗插入点**：inal newQa = VideoQuality.fromCode(quality); 之后、ideoDetailController..cacheVideoQa... 之前；VideoQuality.hdrVivid/dolbyVision/hdr（video_quality.dart:2,4,5）B 全在。弹窗仅提示不阻断（OHOS HDR 显示管线未知，UI 层安全）。
- **analyze 计数漂移注意**：T25 落地后 analyze 为 **27 errors**（基线 31 少了 4），因并行任务（T24/T26 等）修掉了部分 test RED——同文件并行写入（controller.dart 出现 hideStatusBar 段）时 diff 需按文件隔离查看，只认自己改的段落。
- **RED 检查**：test/ 仅断言 astForBackwardDuration/astForBackwardDuration_ 的 SettingBoxKey 存在（storage_key_test:17、storage_pref_test:145-147，键早已存在），无待转绿测试。

## [2026-08-01] Task: T29（videoPush 换源 + hideStatusBar + 无痕空降）
- **B 的 app_scheme.dart 已有完整 videoPush**（line 881，签名与 A 完全一致含 showDialog/off/progress/part）——本任务只需在 video.dart 补弹窗调用，不用动 app_scheme。任务标题里的「检查 videoPush 是否存在」答案：存在。
- **hideStatusBar 消费点在 pl_player/controller.dart 的 triggerFullScreen 退出分支**（不在 view.dart）。B 的 fullscreen.dart 已带 `StatusBar.i` OHOS 适配（hideSystemBar 置 `StatusBar.i.hidden = true`），移植 A 的 `if (!Pref.hideStatusBar) showSystemBar() else hideSystemBar()` 时直接用 B 现有 hideSystemBar/showSystemBar，不复制 A 的纯 SystemChrome 写法。
- **无痕空降 = SponsorBlock 无痕抑制**，T23 已完成消费（block_mixin.dart:68 querySponsorBlock + :256 viewedVideoSponsorTime 双点 `Pref.suppressSponsorBlockIncognito && MineController.anonymity.value`）；T29 只补 UI 开关「无痕模式不发送查询」（extra_settings.dart 的 SwitchModel）。B 的 extra_settings 原本有「空降助手」SplitModel 但缺该开关。
- **video.dart 是纯 http 文件不 import material**：补弹窗要新增 3 个 import（flutter/material、flutter_smart_dialog、utils/app_scheme）——A 因走 material 间接 re-export 能直接用 SmartDialog，B 必须显式 import。
- **extra_settings.dart 是并行任务高频冲突点**（T28 也在加设置项）：编辑前先读当前文件确认行号已漂移，用 edit 按上下文精确匹配即可，analyze 验证兜底。
- **analyze 27 vs 基线 31**：并行任务修掉 4 个 test RED 导致总错误数下降，本任务 3 文件 0 error 0 warning，验收以「不新增」判定。

## [2026-08-01] Task: T27（selectable_region 替代 + insertOrAdd + viewPugv(progress:)）
- **selectable_region_ext_test.dart 删除决策**：该测试引用 `SelectableRegionStateExt`（hideAndClear/selectedText/isUncollapsed）——A 原版 API 的核心字段访问（(this as dynamic).selectable）T4 已实证在 A 自身运行时即 NoSuchMethodError，B 不移植；替代实现是 B 原生 SelectableText 菜单内联接线（非独立可单测单元），保留旧测试只会保留对不存在 API 的 4 个编译错误 → 删除。analyze 31 → 23（−8 = extension_test 4 转绿 + selectable_region_ext_test 4 移除）。
- **「打开」按钮的公共 API 配方**：`state.textEditingValue.selection.textInside(state.textEditingValue.text).trim()` + 守卫 `!selection.isCollapsed && selected.isNotEmpty`——全公共 API，无 (this as dynamic) 越权，2 处消费点（content_panel._contextMenuBuilder / reply_item_grpc._filterMenuBuilder）同一配方。superchat（SelectionArea）无公共选区文本，保持原生不实现（与 A 实际损坏行为一致）。
- **viewPugv(progress:) 双透传点**：viewPugv 签名加 `int? progress` + toVideoPage 调用的 `progress:` 参数 + viewPgcFromUri 的 pugv 分支补传 `progress: progress`（A 的 viewPgcFromUri 两分支都透传，B 原本只 pgc 分支透传）。
- **extension_test.dart 头部注释会撒谎**：T16 之前它写着 "See test/utils/selectable_region_ext_test.dart for standalone tests"——T27 删除该文件后必须同步更新注释，否则注释指向不存在的文件。
- **`flutter test test/utils/extension_test.dart` 24/24 PASS**：本文件只 import flutter_test + 轻依赖（extended_nested_scroll_view/fixnum/pb show Dimension），不拉全依赖图，本地 3.44.4 可跑——insertOrAdd 4 断言真绿。跑完仍需 `git checkout -- pubspec.lock`（pub 镜像 URL 重写，T14 gotcha 复现）。

## [2026-08-01] Task: T28（恢复设置项 + 账号选择器昵称）
- **B 的 extra_settings 已含 AI 总结组 + 港澳台代理**（T13/T11 已补）：启用AI总结/后台总结/服务选择/Base URL/API Key/文本模型/多模态模型/超时 + apiHKUrl 全在；本任务只补缺失 5 项（accountDisplayName/saveImgPath/defaultAppealReason/enableQuickShare/enableCommentTranslate）+ 登出/切换昵称。
- **saveImgPath 在 A/B 都是"展示型偏好"**：grep 全库 `Pref.saveImgPath` 两仓均零消费（图片保存走 saver_gallery `_albumPath` 硬编码 `Pictures/${Constants.appName}`）；getSaveImgPathModel 只是写键。移植纯 UI，无接线负担。
- **saveImgPath 门控必须加 OS.isHarmony**：A 是 `if (Platform.isAndroid)`，OHOS 上 Platform.isAndroid=false，不加鸿蒙门控则设置项不可见——用 B 既有的 `Platform.isAndroid || OS.isHarmony` 模式（extra_settings 已 import os_type）。
- **账号昵称消费点共 3 处**：switchAccountDialog（login/controller.dart:715-721 options map）+ _logoutDialog 两处（setting/view.dart MultiSelect values + 确认文案），B 全缺；三处都要 `Pref.accountDisplayName` + `Pref.getAccountDisplayName(mid)`（storage_pref.dart:101-106 读取方 T10 已建，写入方 login_utils.onLoginMain/mine.controller 已就位）。
- **login/controller.dart 与 setting/view.dart 原本零 Pref 引用**：补昵称必须同步补 `import utils/storage_pref.dart`，否则 undefined_name。补前先 grep 该文件是否已 import storage_pref。
- **getSaveImgPathModel 依赖 Constants.appName**：B 的 model.dart 原本不 import common/constants.dart（09_report §6 记录），加函数必须同步补 import。
- **RED 检查方法**：storage_pref_test 对 5 个新键只断言 `SettingBoxKey.*` 存在（storage_key.dart 已定义），无行为断言 → 零转绿负担。
- **analyze 27 → 26**：改动 4 文件 0 error 0 warning；并行任务（T24-T27）持续写入使总计数抖动（26/27），验收按"改动文件 0 error + 不增 warning"判定；extra_settings.dart:743 的 `unnecessary_lambdas` 是 A 同款 pre-existing info，非本任务引入。
- **并行写同一文件风险**：git diff 里出现本任务之外的同文件改动（如 suppressSponsorBlockIncognito UI 由并行任务写入 extra_settings）——确认自己的 Edit 未被覆盖，diff 隔离按文件核对即可。

## [2026-08-01] Task: T24（动态/首页刷新 FAB + 剪贴板搜索）
- **B 的 fab_mixin.dart 缺 fabAnimWrapper/onNotification**：A 的 BaseFabMixin 封装 abAnimWrapper({required Widget child})（具名参数）+ onNotification；B 此前只在 common_dyn_page 本地定义位置参数 abAnimWrapper(Widget child)。改为 A 模式后必须同步 4 个消费点（article/dynamics_detail/match_info/music）从 abAnimWrapper(child) → abAnimWrapper(child: child)，否则 invalid override 编译错。
- **ScrollDirection 不在 material 导出**：lutter/material.dart 不 re-export ScrollDirection（rendering 层），显式写 ScrollDirection.forward 需补 import 'package:flutter/rendering.dart'；A 用点简写 .forward（按 static type 解析，无需 import）才避开。B 用显式名时两个文件（fab_mixin/common_dyn_page）都要注意。而 UserScrollNotification 由 widgets 导出，material 可解析。
- **axisDirection 是 AxisDirection 枚举**：
otification.metrics.axisDirection == .down 是 AxisDirection.down，不是 ScrollDirection.down（我第一版写错触发 undefined_enum_constant）。
- **动态页 FAB 用 GetSingleTickerProviderStateMixin（A 同款）**：A 的 dynamics controller 用单 Ticker mixin + TabController(1 ticker) + fab AnimationController(2nd ticker) → 调试模式会触发 GetSingleTickerProviderStateMixin 的 multiple-tickers assert（release 无）。忠实移植 A，home 则按任务约束升 GetTickerProviderStateMixin。潜在 A 继承问题，真机若 debug 崩可后续升级 dynamics 为多 Ticker。
- **home FAB 升级 GetTickerProviderStateMixin 无冲突**：GetX 的多 Ticker mixin 是超集（Set 跟踪 + onClose 断言 active ticker），tabController + fab 双 AnimationController 安全；home controller dispose 需加 _fabAnimationCtr?.dispose()（A 同款），否则 onClose 断言。
- **analyze 23（基线 31 不增）**：改动 7+4 文件 0 error 0 warning；23 = 6 vendored + 17 test RED，其中 8 个（android_helper×6 + platform_utils isHarmony×2）被并行任务清零。残余 2 info 非本任务引入（common_dyn_page rendering import 改动前即冗余；home cascade_invocations 为 A verbatim 同款）。

## [2026-08-01] Task: T33（关键路径冒烟报告）
- **T6 harness 仍可重跑**：`%LOCALAPPDATA%\Temp\opencode\hive_migration_verify` 未删，`dart run bin/verify.dart` 直接复跑 31/31 PASS（T9 的 t9_harness 同理 56/56）——T33 无需新造 harness，复用即得运行级证据。
- **account_type.dart 是零依赖纯枚举**（无 import）→ 可直接 `dart run` 做 AccountType.values 断言（6 值/序/desc），不必只靠 grep；wbi/grpc 头因依赖面重走 grep + 既有 harness 组合。
- **analyze 错误级计数法**：`dart analyze --no-fatal-warnings` 总 issues（271）含 info/warning，验收只看 ` - error - ` 行；23 = 6 vendored（editable_text/vertical_slider）+ 17 test RED，PowerShell 正则 `^test[\\/]` 在双引号串里 `\\`→`\` 导致不匹配，要用单引号或 `[\\]` 写成 `[\\]`（PowerShell 里 `[\\\\/]`）。
- **git status 未提交残留在 T33 属正常**：`M test/utils/extension_test.dart` + `D test/utils/selectable_region_ext_test.dart` 是 T27 的验证产物（已跑 24/24），HEAD 8723476f9 已含 batch4；T33 只读不改，不代 T27 收尾提交。
- **runtime-pending 汇总方法**：grep 全部 evidence 的 `runtime-pending|仅设备|真机` 得到 15 项（batch0-smoke-plan §三 12 项 + F17/F19/T29 细分），写报告时引用每项 task evidence 行号。

## [2026-08-01] Task: T32 — OHOS 保留 + 受保护文件 + 依赖 override 完整性检查
### 结论：全部断言通过，0 违规。
### 检查方法（可复用）
- 基线 = 886b57dd9（batch0 recon），移植范围 = 50039f462..8723476f9（T5-T29 共 16 commit）。
- **OHOS 保留 5 项**：SelectionText 移植文件 0 命中（真命中仅 pre-existing 定义 selection_text.dart + getSelectionText 方法名 + pb 生成文件）；TargetPlatform/Platform.is* 用 git diff --unified=0 只筛 ^\+ 行（删除旧桌面代码是预期）；text_selection.dart:2921/3044 逐行读确认仍注释 + git diff --name-only 确认文件未触碰；@Deprecated 用 storage_pref.dart 行数(1001==1001)证明字节未动；4 个「鸿蒙待适配」TODO 逐个 baseline/current 对文本（行号可漂移，内容必须一致）。
- **受保护文件**：git log --name-only 全范围管道过滤 \.g\.dart$|\.pb.*\.dart$|GeneratedPluginRegistrant|bindings\.g\.dart|build-profile\.json5 即可，0 命中 = 0 触碰。
- **依赖 override**：pubspec diff 应只含计划批准的新依赖（本波 = visibility_detector 一项）；gitcode.com 计数 current==baseline==13 是强证明。
### 重要观察
- 计划措辞"~37 gitcode overrides"实为"~37 git overrides（含 github cnoim/My-Resp forks）"：dependency_overrides 24 项（17 git-sourced）+ dependencies 区 git 依赖，gitcode 计数 13。断言时应数 git: 键（34）而非 gitcode URL。
- 工作区有 pre-existing 未提交改动（AGENTS.md/ohos/AGENTS.md 知识库刷新、Task27 删 selectable_region_ext 测试），不属本波，勿误报为违规。

## [2026-08-01] Task: T31

### 19 功能族接线验证结果：19/19 PASS（无孤儿）

- 方法：grep 符号 + 消费点双重验证，全部真实命中，无虚构。所有符号从 main.dart 可达链成立（main → /videoV,/history,/whisper,/setting,apiHostSetting → pages → http/grpc）。
- 完整报告：.sisyphus/evidence/batch5-wiring.md。

### 关键观察

1. **Accounts.reply/blacklist getter**（accounts.dart:35,43）无直接 Accounts.reply 调用方，但经 ApiType.apiTypeSet 路由表（api_type.dart:102,111）+ account_mgr _resolveAccountSelection（:266-274）在运行时按 path 选择 reply/blacklist 账号——这是消费路径，非孤儿。对比 A 直接消费（http/black.dart 等），B 用路由表方式等价接线。
2. **analyze 基线 31 errors 在 T18-T29 期间已降至 ~23-27**（孤儿 part 删除 -85、test RED 逐项清零），T31 纯验证无改动。
3. **pmShare**：request_utils.dart:73 是 B 原有（SelectableText 适配），T22 只加 3 处 onLongPress 消费，未改函数本身。
4. **viewPugv(progress:)**：page_utils.dart:745 签名已含 int? progress（T27 恢复），透传 toVideoPage:775。
5. **insertOrAdd**：iterable_ext.dart:72 + extension_test 4 断言（24/24 PASS，T27）。
6. **「打开」替代实现**：content_panel.dart:122 + reply_item_grpc.dart:1716，用 EditableTextState.textEditingValue 公共 API，A 原版 selectable_region_ext 未移植（T4 决策正确）。
7. **videoPush/hideStatusBar/FAB/下载过滤/设置项** 作为补充锚点全部有消费点，无孤儿。
8. **runtime-pending 8 项**（Stein/播放器/直播/快速分享/图片屏蔽/「打开」菜单/续播/无痕空降）按 batch0-smoke-plan §三 如实标注。

## [2026-08-01] Task: T30（全量 analyze + hap 构建验证）
- **analyze 23 errors 精确匹配基线**：6 vendored（editable_text 3 + vertical_slider 3）+ 17 test RED（connectivity_utils 7 + android_helper 6 + platform_utils 4），全项目 0 新增、无非基线 lib/ 错误。PowerShell 计数法：`dart analyze --no-fatal-warnings 2>&1 | Select-String -Pattern "^\s*error - "` 后按 `[1] -replace ':\d+:\d+$',''` 提取文件聚合。
- **本机双 Flutter 并存**：全局 `D:\Program\Flutter\flutter` = 标准 3.44.4（`flutter build --help` 只有 apk，无 hap target）；`D:\Program\Flutter\flutter-ohos` = **3.41.10-ohos-0.0.2-beta**（支持 hap target，与 B 声明的 CI oh-3.41.9-release 同族）。跑 hap 必须显式 `& "D:\Program\Flutter\flutter-ohos\bin\flutter.bat"`。
- **hap 构建环境硬缺项 = HOS SDK**：ohos flutter 的 build/analyze 都在 **pub get 之后、Dart 编译之前** 死在 `[!] No Hmos SDK found. Try setting the HOS_SDK_HOME environment variable.` ——本机无 DevEco Studio/hdc/HOS_SDK_HOME，这是纯环境缺口，**不是代码错误**（编译阶段根本没到）。判断"环境 vs 代码"：pub get 成功(231 deps 全解析) + 失败点在 SDK 发现 + analyze 0 非基线错误 三信号齐备即可下结论。
- **ohos flutter pub get 会重写 pubspec.lock**（280+/264- 漂移，镜像 URL + 重解析）——跑完必须 `git checkout -- pubspec.lock` 恢复（T14/T27 gotcha 第三次复现）。前置检查通过：ohos/build-profile.json5 存在（signingConfigs []，SDK 5.0.3(15)）+ .vscode/env.json 206B。
- **git override 计数修正（T32 延续）**：34 个 `git:` 键 = dependencies 区 17（get/extended_nested_scroll_view/.../super_sliver_list）+ dependency_overrides 区 17；pubspec 在移植范围内唯一改动 = T20 的 visibility_detector +1 行。agures "~37 overrides" 是含 github fork 的宽松数。
- **Guardrails 复核**：SelectionText( 全库命中仅定义文件 selection_text.dart:4（init 遗留）+ pb 生成 + 框架副本，移植文件 0；text_selection.dart:2921/3044 注释逐行完好；git log 近 10 commit 对 *.g.dart/*.pb*/GeneratedPluginRegistrant/bindings.g.dart 0 触碰。
- **警告基线 39**：全 pre-existing（vendored unreachable_switch/undefined_hidden_name、A-verbatim ai_conclusion/video/view、孤儿 part unused_import、identity_generators 5 unused_field、theme_utils 4、test RED 14）——无移植引入的 warning。验收只看 error 级（--no-fatal-warnings 不 gate warning/info）。
