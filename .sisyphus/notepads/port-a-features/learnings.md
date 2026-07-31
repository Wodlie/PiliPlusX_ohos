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
