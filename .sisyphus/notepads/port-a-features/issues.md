# issues.md

## [2026-07-31] Task: T1 — 分类与残留审计发现

- **txt 快照不全**：15 份报告附带的 `*_*.txt` 差异清单遗漏 9 个 DIFF + 9 个 ONLY_A（`pages/common/*`、`pages/mine/*`、`scripts/*`、`tcp/`）。已用权威 SHA-256 清单覆盖（`cmp_reports/authoritative_lib.txt`）。后续 Task 若复用 txt 清单必须先对照权威清单。
- **`api_host_page` 双版本**：A 在 `setting/api_host_page.dart`（可达），B 在 `setting/pages/api_host_page.dart`（注册路由 `/apiHostSetting` 但全库无 `toNamed`，死页面）。决策：保留 B 版（内嵌开关+重置更好），只加入口。A 版仅参照。
- **`msg_type.dart`/`reply_type.dart` 是全注释死代码**（B 独有、零引用、自 init 起未改）——非"可复用残留"，建议 Batch 5 收尾清理。
- **`draggable_sheet/*` + `layout_builder.dart`/`sliver_layout_builder.dart` vendored 文件零引用**但属引擎兼容补丁基础设施，删除有编译回退风险，保留不动。
- **`app_device_profile.dart` 内容两仓相同但 B 侧零引用 + adapter 未注册**：这是 B 最大的隐性死代码，T6 注册 adapter 必须做否则 Hive 反序列化崩。
- **`color_select.dart` B 是 bug**（`AnimatedHeight(expand: dynamicColor)` 反向），移植时顺手修正（不属范围蔓延，是 A 已修 bug 对齐）。
- **`relationMod` fp 字段 B 写 `BrowserUa.pc`**（语义错误，风控隐患）——B 侧现状，移植 T16 拉黑功能时建议一并修。



## [2026-07-31] Task: T2 (Hive 审计)
- 键命名空间：A 无独有键（0），B 独有 8 键（OHOS 适配 + defaultDecode/secondDecode 废弃残留）。同名不同语义真冲突 = 0。
- 任务简报称的「A 新增键」（quickShareId/defaultAppealReason/apiHKUrl/saveImgPath 等）在 B 均已存在，只是死键（缺消费方）——移植时禁止改名。
- 迁移要点：枚举按 index 序列化（AccountTypeAdapter typeId10，elementAtOrNull??main 兜底），4→6 尾部追加天然安全；真正的迁移是每账号 buvid/deviceProfile 回填（needsBuvidPersist 自愈 + 显式 migrateAccountBoxV4ToV6）。全自动，无需手动。
- 回填策略：推荐 seed = cookie buvid3（保持线上 buvid 头不漂移），非 A 的 generated 方案。
- B 已有 identity_core/identity_persistence（guest 侧已迁移完），account 侧缺失 = Task 6 范围。
- AppDeviceProfileAdapter(typeId13) 文件 B 已存在（逐字节同 A）但未注册、零引用（死代码）；T6 只需补注册。
- hive_ce 2.19.3 eager decode：结构损坏记录在 openBox 即崩（A/B 一致），迁移只解决 schema 旧的数据。
- 重要：B test/ 已移植 A 的目标态测试（identity_migration/buvid_lifecycle/request_identity_adapters/grpc_identity），引用 lib 缺失符号，当前 RED 且未排除出 analyze——T6/7/8 落地后转绿。

## [2026-07-31] Task: T3 (3.44→3.41 API + media_kit fork 审计)
- **语言特性零阻塞**：B sdk>=3.11.1（本机实际 3.12.2），点简写/records/patterns/switch 表达式全可用；B 现有代码已用 `const .symmetric(...)`、`({int tagid,...})`。
- **引擎漂移 API 与功能无关**：ScrollCacheExtent/enableInlinePrediction/Alignment.bottomStart/onFocusReceived 只存在于 B vendored `common/widgets/flutter/**`（3.32.4 副本，B 已适配）；功能代码 0 命中。
- **media_kit fork API 面差异大**：A fork(1.1.11) 有 `Player.create`/`VideoController.create`/`setMediaHeader`/`SimpleVideo`，B fork(cnoim 1.2.3) 全无；B 用 `Player()`/`VideoController()`/`Media(httpHeaders:)`/`audio-files`/`Video(controls:NoVideoControls)`/`screenshot→Uint8List`。4 播放器功能（stein/长按/fastForBackwardDuration_/HDR）只用 B fork 已有 API——**T18/19/25 必须 graft 到 B 现有 pl_player，严禁复制 A 的 _initPlayer/_createVideoController/SimpleVideo 段落**。
- **B 三处孤儿 part 文件**：`context_menu/dyn_menu_helper.dart`/`reply_menu_helper.dart`/`live_menu_helper.dart` 声明 `part of` 但宿主库无 `part` 声明 → 不参与编译的死代码。T27 恢复 selectable_region_ext 时须一并恢复 part 声明，否则"长按打开 URL"不接线。
- **selectable_region_ext 运行时受阻**：`(this as dynamic).selectable`/`.selectionDelegate` 依赖 A 的 12KB selectable_region.patch 引擎补丁；B 框架与 vendored 副本都只有私有 `_selectable`/`_selectionDelegate` → 直译移植会 NoSuchMethodError。改写 2 方案：A) 给 B vendored selectable_region.dart 补公共 getter + 路由到 vendored SelectionArea；B) SelectionListener 公共 API。都不碰 text_selection.dart:2921,3044。
- **B 死代码可复用**：`common/widgets/selection_text.dart`（SAME、无人 import，T22/T15 可复用它或按 guardrail 用 selectableText()）；`request_utils.dart:73 pmShare` 已存在（用 Accounts.main）——T22 只需 UI onLongPress 接线。
- **模型前置基本就位**：T13 的 service_result/model_result/outline/part_outline 全部存在；T17 pb `im/interfaces/v1.pb.dart` sessionDetail 两仓都有；T18 StoryList/HistoryNode 文件 B 已存在（仅 4 个 edgeinfo 模型为精简版）。
- **版本事实**：本机全局 Flutter 3.44.4/Dart 3.12.2（fvm 3.41.9/3.44.8 未安装）；A fvm 3.44.8、B 声明目标 3.41.9。

## [2026-07-31] Task: T4 — selectable_region/text_selection 冲突检查 + 冒烟路径定义

### 结论
- selectable_region_ext 与 text_selection.dart:2921,3044 **无直接冲突**（前者操作 SelectableRegionState/SelectionArea，后者是 TextField 手柄覆盖层）。
- A 扩展**不可原样移植**：selectedText/isUncollapsed 用 (this as dynamic).selectable/selectionDelegate 访问私有字段，两 SDK（3.44.4 / 3.41.10-ohos）均无公共 getter → 运行时必 NoSuchMethodError（temp 脚本实证），A 自身也是坏的。B 维护者今日 d1916d920 已以 "nonexistent APIs" 删除之。
- 替代方案：B 现行 SelectableText 菜单（EditableTextState，textEditingValue 公共可取选区）直接加「打开」按钮；superchat（SelectionArea）不实现；不恢复 3 个孤儿 part 文件。

### 阻塞/需 orchestrator 决策
1. **3 个孤儿 part 文件**（reply_menu_helper/dyn_menu_helper/live_menu_helper）造成 **85 个真实 analyze 错误**（B HEAD 基线），且函数全为死代码。Task 16 guardrail「不动 reply_menu_helper.dart」基于错误假设，**需更新允许删除**。
2. Task 27 不应创建 A 原版 selectable_region_ext.dart，改为 B 原生菜单实现「打开」。

### 环境陷阱（Batch 5 前置）
- 本地 package_config.json 指向 3.44.4（错）；需 OHOS SDK 重新 pub get。
- file_picker_ohos 本地缓存 commit 错误（lock 钉 04eec7fdb，缓存是 aae2f8828 name=file_picker）→ 假象错误，CI 不受影响。

### 发现（B HEAD 真实状态）
- B HEAD 本地 analyze 276 errors：85 孤儿 part + ~191 test/ 引用未移植符号（request_identity_adapter/selectable_region_ext/custom_host_interceptor 等）。
- B test/ 有 ~20 个继承自 A 的测试文件，可作各功能族无设备验证 harness（F1/F2/F4/F5/F9/F17 等）。
- B SDK = flutter-ohos 3.41.10-ohos-0.0.2-beta（CI 用 oh-3.41.9-release，本地略新）。

## [2026-07-31] Orchestrator 验证记录（T6 完成后）
- **.gitignore 第 152 行 'test*' 过宽**：吞掉 test/ 下新测试文件，提交需 git add -f test/<file>。后续 T6-T29 的测试文件都要注意。
- **flutter_test 本地编译阻塞**：本地 3.44.4 无法编译 B 的传递依赖图（vendored 3.32.4-ohos 补丁、font_awesome 10.9.0、git fork 平台成员）——任何 import lib 的测试本地都编不过。验证方案：纯 Dart harness（临时目录 + stub 依赖 + 真实复制核心文件）已验证可行（T6 31/31 PASS）。后续涉及测试的任务沿用此模式。
- **analyze 基线更新**：276 → 236（T6 后）。孤儿 part 85 + test RED 是已知基线。

## [2026-08-01] Task: T27 — selectable_region_ext_test 删除决策
- **删除 `test/utils/selectable_region_ext_test.dart`**：它测试 `SelectableRegionStateExt`（A 原版 API），而 T4 已实证该 API 运行时 NoSuchMethodError（(this as dynamic) 访问私有字段），B 不移植。替代实现是 B 原生 SelectableText 菜单内联接线，非可单测单元 → 保留旧测试 = 保留对不存在 API 的 4 个编译错误。删除后 analyze 31 → 23。
- 若未来要单测「打开」菜单行为：需把 2 处 menu builder 的选区提取逻辑抽成独立函数/扩展（EditableTextState 纯函数），再配轻依赖测试——本任务按 T4 结论内联实现，未抽象。

