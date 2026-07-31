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
