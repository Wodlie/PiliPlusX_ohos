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
