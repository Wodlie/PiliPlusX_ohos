# PiliPlusX 独有功能移植到 PiliPlusX_ohos

## TL;DR

> **Quick Summary**: 将 A=D:\coding\PiliPlusX 中【X独有】且 B=D:\coding\PiliPlusX_ohos 缺失的功能全部移植到 B（按需重写，OHOS 适配），**排除 log（logger.dart/catcher_2）与桌面端专属功能**。
>
> **Deliverables**:
> - 账号身份体系（6 账号类型、每账号 BUVID/deviceProfile、RequestIdentityAdapter、gRPC 头、wbi 风控）
> - 自定义 API Host + 港澳台代理（拦截器 + gRPC 支持）
> - 港澳台番剧（HomeTab/搜索/pgc 代理）
> - AI 总结多服务（router + adapters + 设置组）
> - 评论体系（5 策略屏蔽/横幅、翻译横幅、申诉、canSort、长按拉黑分享、手动加载图）
> - 互动视频 Stein（进度恢复/回溯面板）
> - 图片屏蔽 pHash UI、私信会话详情、直播反馈、快速分享、历史续播、SponsorBlock 无痕
> - 刷新 FAB、剪贴板搜索、下载过滤、播放器快捷操作、selectable_region_ext、设置项恢复
>
> **Estimated Effort**: XL（19 功能族，约 40+ 任务）
> **Parallel Execution**: YES — 5 波次
> **Critical Path**: Batch 0 侦察 → Batch 1 账号基础设施 → Batch 2-4 功能 → Batch 5 验证 → Final 审查

---

## Context

### Original Request
> 实现 A 有 B 没有的（除 log、catch 以外的）全部功能。

### 用户确认的决策
1. **桌面端专属功能排除**（Darwin 弹跳物理、桌面键盘选区、窗口管理、平台快捷键）
2. **log/catch 边界**：排除 `services/logger.dart` + `catcher_2` 异常上报；`logs.dart`/`log_table` 页面保留
3. **验证策略**：`dart analyze --no-fatal-warnings` 零错误 + 迁移编译 + 关键路径冒烟（OHOS 真机不可用则编译通过为准）
4. **移植方式：按需重写**（不复制 A 文件；以 A 实现为参照、以 B 现状为基底、复用 B 死代码残留，实现 OHOS 适配版本）

### Metis Review（已采纳的关键缺口）
- **Hive 4→6 迁移**：B 现有用户持久化 4 类型账号，升级后枚举读取或 API 路由错位是数据级风险 → 必须有迁移函数 + Dart 验证测试（Batch 1 末尾落地，全计划最高优先级验收项）
- **存储键冲突审计**：A/B 可能同名键不同语义 → Batch 0 需键命名空间审计
- **337-diff 三分类**：diff 含 A 功能 / B 的 OHOS 适配 / 双方漂移 → 不能把 diff 当"都是 A 功能"，需逐 hunk 分类
- **3.44→3.41 API 兼容**：A 用新 API（点简写、records、新 widget），B 引擎 3.32.4-ohos → 逐功能 API 可用性检查
- **27 个 ONLY_A 文件分类**：leaf 功能 vs 传递依赖 → 只移植功能依赖的工具文件
- **gRPC 架构**：B 用 gRPC-over-HTTP，A 的每账号 gRPC 头/customAppBaseUrl 是否兼容需检查
- **wbi dm_img_* 风控字段**：可能改变签名串 → 需确认对 B 现有请求无破坏
- **media_kit OHOS fork API 面**：A 播放器功能调用的是上游 API，B fork 可能缺失 → 逐功能检查
- **selectable_region_ext × text_selection.dart:2921,3044**：OHOS 引擎禁恢复注释代码，该功能可能受阻
- **死代码残留 provenance**：B 中 block_filter_settings UI/ai_summary 模型/api_host_page 是旧 A 残留还是 B 自建 → 决定 reuse/replace
- **每批 gate**：不能只在 Batch 5 验证 → 每批 `dart analyze` + `flutter build hap` + OHOS 保留检查
- **诚实声明**：设备不可用时验收 = 编译 + analyze + 符号接线 + Hive 迁移测试；仅设备可验证的功能标记 "runtime-pending"

---

## Work Objectives

### Core Objective
把 A 独有、B 缺失的全部功能按需重写移植进 B，保持 B 的 OHOS 适配完整性，零回归。

### Definition of Done
- [ ] `dart analyze --no-fatal-warnings` 全项目零错误
- [ ] `flutter build hap --release --dart-define-from-file=.vscode/env.json` 编译通过（若环境允许）
- [ ] 19 功能族逐一符号接线验证（grep/lsp 证明从 main.dart 可达）
- [ ] Hive 4→6 迁移测试通过（旧 4 类型账号数据加载无崩溃）
- [ ] OHOS 保留检查通过（无 SelectionText 恢复、无桌面分支新增、text_selection.dart:2921,3044 注释完好）

### Must Have
- 账号身份体系（AccountType 6 值 + 每账号 BUVID/deviceProfile + RequestIdentityAdapter + gRPC 头 + wbi 风控 + BUVID 激活重试 + 登出清理 + 昵称缓存）
- 自定义 API Host + 港澳台代理拦截器
- 港澳台番剧（HomeTabType.hk_bangumi + SearchType.media_hk_bangumi + pgc 代理）
- AI 总结多服务（router + 至少 legacy+multimodal 两 adapter + 设置组）
- 评论体系（checkBlockReason 5 策略 + BlockedReplyBanner + 翻译横幅 + 申诉 + canSort + 长按拉黑/分享 + 手动加载图）
- 互动视频 Stein（进度恢复 + 回溯面板 + BottomControlType.stein）
- 图片屏蔽 pHash UI、私信会话详情、直播反馈、快速分享、历史续播、SponsorBlock 无痕
- 动态/首页刷新 FAB、剪贴板搜索、下载按 UP 过滤、保存评论图原文、播放器快捷操作、selectable_region_ext、viewPugv(progress:)、设置项恢复

### Must NOT Have (Guardrails)
- **不恢复** `SelectionText`（B 用 `SelectableText`/`SelectionArea`）
- **不新增** 桌面平台分支（`TargetPlatform.macOS/windows/linux`、`Platform.isWindows` UI 路径）
- **不动** `lib/common/widgets/flutter/text_field/text_selection.dart:2921,3044`（注释代码，OHOS 引擎不支持）
- **不动** 4 个「鸿蒙待适配」TODO（exception capture、subtitle strokeStyle、AI-summary sheet、connectivity workaround）
- **不编辑** `*.g.dart`、`GeneratedPluginRegistrant.ets`、`*.pb*.dart`、`lib/utils/android/bindings.g.dart`
- **不加** 上游 media_kit/audio_service/video_player/url_launcher 等非 OHOS-fork 依赖（必须用 B 的 ~37 gitcode overrides）
- **不升** Flutter/Dart SDK 约束（B 钉 3.41.9）
- **不改** `ohos/entry/build-profile.json5` abiFilters；**不提交** `ohos/build-profile.json5`
- **不引入** 非必需新依赖（除非 A 功能确实需要且 B 无对应物，须在计划标注）
- **不重构** 与移植功能无关的 B 代码（防范围蔓延）

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — 所有验收由 agent 执行命令验证。

### Test Decision
- **基础设施存在**: 无自动化测试框架（CI 不跑测试）
- **自动化测试**: 仅 Hive 迁移测试（一次性验证产物，非永久测试套件）
- **主验证手段**: `dart analyze --no-fatal-warnings` + `flutter build hap` + 符号接线 grep + ast_grep OHOS 保留检查 + git diff 完整性检查

### QA Policy
每个任务必须有 agent 执行的 QA 场景，证据保存到 `.sisyphus/evidence/`。

- **编译验证**: `dart analyze --no-fatal-warnings`（0 error）
- **符号接线**: `grep`/`lsp_find_references` 证明功能符号从 `lib/main.dart` 可达
- **OHOS 保留**: `ast_grep_search` 断言无 `SelectionText(`、无桌面分支、注释代码完好
- **文件完整性**: `git diff --name-only` 断言未触碰受保护文件
- **依赖保护**: `git diff pubspec.yaml` 断言 ~37 gitcode overrides 保留、无上游依赖混入
- **仅设备可验证的功能**（播放器、Stein、直播、下载、图片 pHash）标记 **runtime-pending**

---

## Execution Strategy

### 波次规划

```
Batch 0（侦察，全并行，无任何实现开始前必须完成）:
├── Task 1: 337-diff 三分类 + 27-exclusive 传递依赖分类 + 死代码残留 provenance
├── Task 2: Hive schema/键命名空间审计 + 4→6 迁移方案设计
├── Task 3: 3.44→3.41 API 可用性 + media_kit OHOS fork API 面检查
└── Task 4: selectable_region/text_selection 冲突检查 + 冒烟路径定义

Batch 1（账号基础设施，依赖 Batch 0，分两波）:
Wave 1.1（并行 4）:
├── Task 5: AccountType 6 值 + api_type 路由表 + desc
├── Task 6: Hive 持久化扩展(field 4/5) + 4→6 迁移 + 迁移测试（最高优先级）
├── Task 7: Accounts 生命周期状态机(canonicalize/snapshot/reply/blacklist)
└── Task 8: RequestIdentityAdapter + 身份解析接入
Wave 1.2（并行 3）:
├── Task 9: gRPC 头按账号快照 + wbi dm_img_* 风控字段
├── Task 10: BUVID 激活重试 + 登出清理 + 昵称缓存
└── Task 11: CustomHostInterceptor + HkApiRetryInterceptor + api_host_page 入口

Batch 2（内容功能，并行 6）:
├── Task 12: 港澳台番剧（枚举+pgc+search）
├── Task 13: AI 总结 router + legacy/multimodal adapters + 设置组
├── Task 14: 评论屏蔽 checkBlockReason 5 策略 + BlockedReplyBanner
├── Task 15: 评论翻译横幅 + 申诉
├── Task 16: canSort + 长按拉黑/分享 + 手动加载图
└── Task 17: 私信会话详情 + whisper 标为已读

Batch 3（交互功能，并行 6）:
├── Task 18: Stein 互动视频数据模型 + 进度恢复
├── Task 19: Stein 播放器 UI（回溯面板/BottomControlType.stein/showStein）
├── Task 20: 图片屏蔽 pHash UI 接入
├── Task 21: 直播反馈 + 卡片反馈按钮
├── Task 22: 快速分享 + pmShare + enableQuickShare/quickShareId
└── Task 23: 历史续播 + SponsorBlock 无痕抑制

Batch 4（页面/杂项，并行 6）:
├── Task 24: 动态/首页刷新 FAB + 剪贴板搜索
├── Task 25: 播放器快捷操作（长按倍速/比例、fastForBackwardDuration_、HDR 提示）
├── Task 26: 下载按 UP 过滤 + 保存评论图原文
├── Task 27: selectable_region_ext + ListExt.insertOrAdd + viewPugv(progress:)
├── Task 28: 设置项恢复（AI 组/评论 AI 翻译/申诉理由/图片路径/快速分享目标/HK URL）
└── Task 29: 视频换源跳转 videoPush + 隐藏状态栏 + 账号昵称 + 无痕空降

Batch 5（验证收尾，并行 4）:
├── Task 30: 全量 dart analyze + flutter build hap
├── Task 31: 19 功能符号接线验证（grep/lsp）
├── Task 32: OHOS 保留 + 生成文件 + 依赖 override 完整性检查
└── Task 33: 关键路径冒烟报告（编译可达 + Hive 迁移 + 可执行断言）

Final Verification Wave（4 并行审查 → 用户确认）:
├── F1: Plan Compliance Audit (oracle)
├── F2: Code Quality Review (unspecified-high)
├── F3: Real Manual QA (unspecified-high)
└── F4: Scope Fidelity Check (deep)

Critical Path: Task 1-4 → 5-8 → 9-11 → 12-29 → 30-33 → F1-F4 → user okay
```

### 依赖矩阵（核心）
- **5-8**: 1,2,3,4 — 9-11
- **9**: 5,6,7,8 — 12,13,14
- **10**: 6,7,8 — 14,22
- **11**: 1,3 — 12,28
- **12-17**: 5,8,9 — 24,28
- **18,19**: 9,13 — 25
- **20**: 5 — 27
- **22**: 9,10 — 28
- **23**: 9,10 — 24
- **24-29**: 12-17,18-23 — 30
- **30-33**: 24-29 — F1-F4

### Agent Dispatch Summary
- **Batch 0**: 4 个 `deep`（侦察/审计类）
- **Batch 1**: 7 个 `deep`（基础设施，逻辑重）
- **Batch 2-3**: 12 个 `deep`（功能移植）
- **Batch 4**: 6 个 `deep`（页面/杂项）
- **Batch 5**: 4 个 `unspecified-high`
- **FINAL**: oracle/unspecified-high/deep

---

## TODOs

### Batch 0 — 前置侦察（4 任务全并行，未完成前任何实现不得开始）

- [x] 1. 差异三分类 + 传递依赖分类 + 死代码残留 provenance 审计

  **What to do**:
  - 对 337 个 DIFF 文件逐文件分类：A 功能 / B 的 OHOS 适配 / 双方漂移（用 `git -C D:\coding\PiliPlusX log --oneline -- <file>` 与 B 的提交历史交叉验证）
  - 对 27 个 ONLY_A 文件分类：leaf 功能 vs 功能传递依赖（如 `ListExt.insertOrAdd`、identity 工具类）
  - 审计 B 死代码残留：`lib/pages/setting/models/block_filter_settings.dart`、`lib/models/common/video/ai_summary_service.dart`、`lib/pages/setting/pages/api_host_page.dart` 的 provenance（是否旧 A 版本残留/B 自建/上游产物），决定每残留策略：reuse-as-is / extend / replace（默认 replace）
  - 输出文件：`.sisyphus/evidence/batch0-triage.md`（含每文件分类表）

  **Must NOT do**:
  - 不修改任何代码（纯侦察）
  - 不臆测分类，无法确定的标注"无法确定"并列出证据

  **Recommended Agent Profile**:
  - **Category**: `deep` — 需跨仓库 git 历史追踪与逐文件分析
  - **Skills**: []（无特定技能）

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 0 (Tasks 1-4)
  - **Blocks**: 5-11（Batch 1 全部）
  - **Blocked By**: None

  **References**:
  - 15 份对比报告：`C:\Users\dashan\AppData\Local\Temp\opencode\cmp_reports\*.md`（已分类的差异证据，直接复用）
  - 差异清单：`C:\Users\dashan\AppData\Local\Temp\opencode\cmp_reports\0*_*.txt`（每文件状态）
  - `git -C D:\coding\PiliPlusX log --oneline -20 -- <file>`（A 侧提交链）
  - `git -C D:\coding\PiliPlusX_ohos log --oneline -20 -- <file>`（B 侧提交链）
  - B 知识库：`D:\coding\PiliPlusX_ohos\AGENTS.md`（禁止恢复的注释代码、待适配 TODO 位置）

  **Acceptance Criteria**:
  - [ ] `.sisyphus/evidence/batch0-triage.md` 存在，含 337 DIFF + 27 ONLY_A 全量分类表
  - [ ] 每分类标注证据（git 提交 / 报告引用）
  - [ ] 死代码残留逐一给出 reuse/extend/replace 决策
  - [ ] 分类结果与 15 份报告总结无矛盾

  **QA Scenarios**:
  ```
  Scenario: 分类表完整性
    Tool: Bash
    Preconditions: batch0-triage.md 已生成
    Steps:
      1. 统计文件中分类条目数 == 337 + 27
      2. 抽查 10 个文件的分类与 15 份报告结论一致
    Expected Result: 全量覆盖，抽查一致
    Failure Indicators: 条目数不符 / 抽查矛盾
    Evidence: .sisyphus/evidence/task-1-triage-complete.md

  Scenario: 残留决策完整
    Tool: Bash
    Preconditions: 同上
    Steps:
      1. 对 block_filter_settings / ai_summary_service / api_host_page 等 ≥5 个残留
      2. 断言每个都有 reuse-as-is/extend/replace 决策 + 理由
    Expected Result: 5/5 有决策
    Failure Indicators: 任一残留无决策
    Evidence: .sisyphus/evidence/task-1-remnant-decisions.md
  ```

  **Commit**: NO（侦察产物不提交，仅存 evidence）

- [x] 2. Hive schema/键命名空间审计 + 4→6 迁移方案设计

  **What to do**:
  - 审计 B 的 Hive box 打开方式（`lib/utils/storage.dart`）：box 名、adapter 注册、`@HiveField` 注解版本
  - 对比 A 的 `lib/utils/accounts/account_adapter.dart`（6 字段含 field 4 buvid/5 deviceProfile）vs B（4 字段）
  - 审计 SharedPreferences/Hive 键命名空间：`lib/utils/storage_key.dart`、`lib/utils/storage_pref.dart` 中 A/B 同名键不同语义的情况（如 buvid/guestBuvid、account_type）
  - 设计 4→6 AccountType 迁移函数：旧 B 用户持久化 4 类型账号 → 新 6 类型枚举如何映射（枚举按 index 序列化，4→6 追加是安全的，但需验证 adapter 行为）
  - 输出文件：`.sisyphus/evidence/batch0-hive-audit.md`（含迁移方案伪代码）

  **Must NOT do**:
  - 不修改任何代码
  - 不假设 adapter 有版本号——必须实读代码确认

  **Recommended Agent Profile**:
  - **Category**: `deep` — 数据迁移方案设计
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 0 (Tasks 1-4)
  - **Blocks**: 6（Hive 持久化扩展）、10（登出清理）
  - **Blocked By**: None

  **References**:
  - A: `D:\coding\PiliPlusX\lib\utils\accounts\account_adapter.dart`（6 字段 adapter）
  - B: `D:\coding\PiliPlusX_ohos\lib\utils\accounts\account_adapter.dart`（4 字段）
  - 两仓库 `lib/utils/storage.dart`（box 注册）
  - 两仓库 `lib/utils/storage_key.dart`、`lib/utils/storage_pref.dart`（键命名空间）
  - 两仓库 `lib/models/common/account_type.dart`（4 vs 6 枚举）
  - 对比报告 `02_accounts_report.md`、`05a_models_report.md`

  **Acceptance Criteria**:
  - [ ] `.sisyphus/evidence/batch0-hive-audit.md` 存在
  - [ ] 键命名空间冲突表：列出所有 A/B 同名键、语义差异、风险等级
  - [ ] 4→6 迁移方案含：迁移函数签名、边界情况（无账号/游客/损坏数据）、回滚策略
  - [ ] 明确标注"B 现有用户升级后是否需手动迁移"

  **QA Scenarios**:
  ```
  Scenario: 迁移方案完整
    Tool: Bash
    Preconditions: batch0-hive-audit.md 已生成
    Steps:
      1. 断言包含键冲突表（≥5 条目）
      2. 断言包含迁移函数伪代码 + 边界处理
    Expected Result: 全部包含
    Failure Indicators: 缺键冲突表或迁移伪代码
    Evidence: .sisyphus/evidence/task-2-hive-audit.md
  ```

  **Commit**: NO

- [x] 3. 3.44→3.41 API 可用性 + media_kit OHOS fork API 面检查

  **What to do**:
  - 对 A 的 27 个 ONLY_A 文件 + 功能相关 diff hunk，检查 Dart/Flutter API 在 B 的 3.41.9/3.32.4-ohos 是否可用：点简写（Dart 3.10+）、records/patterns、`ScrollCacheExtent`、`enableInlinePrediction`、新 Material widget 等
  - 对 A 播放器功能（stein 回溯、长按倍速/比例、fastForBackwardDuration_、HDR 提示）检查 media_kit OHOS fork（`~/.pub-cache` 或 B 的 git 依赖）是否暴露所需 API：`Player`、`VideoController`、`setProperty`、`screenshot`、`SimpleVideo` 等
  - 对 A 的 `selectable_region_ext` 检查是否依赖 B 中注释掉的 `text_selection.dart:2921,3044` 相关 API
  - 输出文件：`.sisyphus/evidence/batch0-api-audit.md`（每功能: 可用/需改写/受阻 + 改写建议）

  **Must NOT do**:
  - 不修改代码
  - 不臆测 API 可用性——必须实读 B 的依赖源码或 lock 版本

  **Recommended Agent Profile**:
  - **Category**: `deep` — API 兼容审计
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 0 (Tasks 1-4)
  - **Blocks**: 12-29（全部功能批次，特别是 13/18/19/25/27）
  - **Blocked By**: None

  **References**:
  - B pubspec: `D:\coding\PiliPlusX_ohos\pubspec.yaml`（gitcode overrides，确定依赖版本）
  - B lock: `D:\coding\PiliPlusX_ohos\pubspec.lock`
  - media_kit fork 源码（pub 缓存路径 `~/.pub-cache/git/` 或 `gitcode.com/cnoim/media_kit` feat-ohos）
  - A 27 个 ONLY_A 文件（`C:\Users\dashan\AppData\Local\Temp\opencode\cmp_reports\*_*.txt` 中 ONLY_A 行）
  - 对比报告 `04b_common_flutter_report.md`（引擎差异细节）

  **Acceptance Criteria**:
  - [ ] `.sisyphus/evidence/batch0-api-audit.md` 存在
  - [ ] 每功能标注：可用/需改写/受阻 + 改写建议
  - [ ] media_kit fork 检查 ≥10 个 A 调用的 API 是否存在
  - [ ] selectable_region_ext 冲突结论明确（可移植/需替代实现/受阻）

  **QA Scenarios**:
  ```
  Scenario: API 审计完整
    Tool: Bash
    Preconditions: batch0-api-audit.md 已生成
    Steps:
      1. 断言包含 ≥19 功能族的 API 可用性结论
      2. 断言 selectable_region_ext 有明确结论
    Expected Result: 全部包含
    Failure Indicators: 缺功能族或结论模糊
    Evidence: .sisyphus/evidence/task-3-api-audit.md
  ```

  **Commit**: NO

- [x] 4. selectable_region/text_selection 冲突检查 + 冒烟路径定义

  **What to do**:
  - 实读 B 的 `lib/common/widgets/flutter/text_field/text_selection.dart:2921,3044` 注释代码区域，确认哪些 API 不可用
  - 检查 A 的 `lib/utils/extension/selectable_region_ext.dart` 是否依赖这些 API
  - 若受阻：设计 OHOS 替代实现（如用 `SelectionArea` 或自定义 contextMenuBuilder）
  - 定义"冒烟路径"清单：哪些功能可在无设备时验证（编译/analyze/符号接线/迁移测试），哪些标记 runtime-pending
  - 输出文件：`.sisyphus/evidence/batch0-smoke-plan.md`（冒烟路径 + runtime-pending 清单）

  **Must NOT do**:
  - 不恢复 text_selection.dart 注释代码
  - 不修改任何文件

  **Recommended Agent Profile**:
  - **Category**: `deep` — 引擎兼容分析
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 0 (Tasks 1-4)
  - **Blocks**: 27（selectable_region_ext）
  - **Blocked By**: None

  **References**:
  - B: `D:\coding\PiliPlusX_ohos\lib\common\widgets\flutter\text_field\text_selection.dart`（2921,3044 区域）
  - A: `D:\coding\PiliPlusX\lib\utils\extension\selectable_region_ext.dart`
  - B AGENTS.md（禁止恢复声明）
  - 对比报告 `04b_common_flutter_report.md`

  **Acceptance Criteria**:
  - [ ] `.sisyphus/evidence/batch0-smoke-plan.md` 存在
  - [ ] selectable_region_ext 可行性结论 + 替代方案（若受阻）
  - [ ] 冒烟路径清单：每功能标注验证方式（编译/analyze/接线/迁移/仅设备）
  - [ ] runtime-pending 清单明确列出

  **QA Scenarios**:
  ```
  Scenario: 冒烟计划完整
    Tool: Bash
    Preconditions: batch0-smoke-plan.md 已生成
    Steps:
      1. 断言 19 功能族每项有验证方式标注
      2. 断言 selectable_region_ext 有可行性结论
    Expected Result: 全量覆盖
    Failure Indicators: 缺标注或结论
    Evidence: .sisyphus/evidence/task-4-smoke-plan.md
  ```

  **Commit**: NO

### Batch 1 — 账号基础设施（依赖 Batch 0；Wave 1.1: Tasks 5-8 并行）

- [x] 5. AccountType 6 值 + api_type 路由表 + desc

  **What to do**:
  - 按需重写 `lib/models/common/account_type.dart`：加 `reply`/`blacklist` 枚举值 + `desc` 字段（参照 A）
  - 按需重写 `lib/utils/accounts/api_type.dart`：新增 reply/blacklist 路由表 + recommend 补 `Api.liveFeedback`（若 Task 21 确认 liveFeedback 接口保留则一并加）
  - 检查 B 中 `AccountType.values` 所有消费点（`lib/utils/accounts.dart`、`lib/pages/login/controller.dart`、`lib/pages/setting/models/privacy_settings.dart`）的循环/索引逻辑与 6 值兼容
  - 检查 `lib/utils/accounts/account_type_adapter.dart`（Hive 序列化按 index）与迁移方案一致

  **Must NOT do**:
  - 不编辑 `*.g.dart`、`*.pb*.dart`
  - 不新增桌面分支
  - 不改 B 已有的 `OS.isHarmony` 守卫

  **Recommended Agent Profile**:
  - **Category**: `deep` — 枚举扩展波及面广
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 1 Wave 1.1 (Tasks 5-8)
  - **Blocks**: 9,12,13,14,16
  - **Blocked By**: 1,2

  **References**:
  - A: `D:\coding\PiliPlusX\lib\models\common\account_type.dart`（6 值 + desc）
  - A: `D:\coding\PiliPlusX\lib\utils\accounts\api_type.dart`（路由表）
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\models\common\account_type.dart`（4 值）
  - B 消费点: `lib/utils/accounts.dart`、`lib/pages/login/controller.dart`、`lib/pages/setting/models/privacy_settings.dart`
  - 迁移方案: `.sisyphus/evidence/batch0-hive-audit.md`（Task 2 产物）

  **Acceptance Criteria**:
  - [ ] `lib/models/common/account_type.dart` 含 6 值 + desc
  - [ ] `lib/utils/accounts/api_type.dart` 含 reply/blacklist 路由表
  - [ ] `dart analyze --no-fatal-warnings` 0 error
  - [ ] 所有 `AccountType.values` 循环消费点兼容 6 值

  **QA Scenarios**:
  ```
  Scenario: 6 值枚举生效
    Tool: Bash (dart 脚本)
    Preconditions: 代码修改完成
    Steps:
      1. 临时脚本断言 AccountType.values.length == 6
      2. 断言 reply/blacklist 存在且 title/desc 非空
    Expected Result: 6 值，desc 完整
    Failure Indicators: length != 6
    Evidence: .sisyphus/evidence/task-5-accounttype.md

  Scenario: 消费点兼容
    Tool: Bash
    Preconditions: 同上
    Steps:
      1. dart analyze 全量 0 error
      2. grep 确认 login controller 的账号循环处理 6 类型不越界
    Expected Result: 0 error，无越界
    Failure Indicators: analyze error / 越界风险
    Evidence: .sisyphus/evidence/task-5-accounttype-analyze.md
  ```

  **Commit**: YES
  - Message: `feat(accounts): extend AccountType to 6 values with reply/blacklist`
  - Files: `lib/models/common/account_type.dart`, `lib/utils/accounts/api_type.dart`（及相关消费点）
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [x] 6. Hive 持久化扩展（field 4/5）+ 4→6 迁移 + 迁移测试（最高优先级）

  **What to do**:
  - 按需重写 `lib/utils/accounts/account_adapter.dart`：读写 6 字段（新增 field 4 buvid、field 5 deviceProfile，参照 A）
  - 按需重写 `lib/utils/accounts/account.dart`：`LoginAccount` 增加 buvid/deviceProfile 字段 + `_resolveLoginAccountIdentity` + `needsBuvidPersist` + `_persistedAccount`（按 Task 2 迁移方案适配）
  - 按需重写 `lib/utils/accounts/identity_persistence.dart` 消费点：`OwnerScopedIdentityPersistence.resolve`（stored→legacy→generated）
  - 在 `lib/utils/accounts/` 增加 4→6 迁移函数（若 B 无版本号则用显式迁移：读取旧 box → 校验 → 映射到新枚举）
  - **编写一次性迁移验证 Dart 测试**（`test/hive_migration_test.dart` 或 tool 脚本）：构造 4 类型旧 box 数据 → 跑迁移 → 断言 6 值枚举解析无崩溃
  - `lib/utils/storage.dart` 注册 `AppDeviceProfileAdapter`（若 A 有、B 无）

  **Must NOT do**:
  - 不编辑 `*.g.dart`
  - 不破坏 B 现有无账号/游客路径
  - 不引入非必需新依赖

  **Recommended Agent Profile**:
  - **Category**: `deep` — 数据迁移正确性至关重要
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 1 Wave 1.1 (Tasks 5-8)
  - **Blocks**: 9,10,13,14,22,23
  - **Blocked By**: 2

  **References**:
  - A: `D:\coding\PiliPlusX\lib\utils\accounts\account_adapter.dart`（6 字段）
  - A: `D:\coding\PiliPlusX\lib\utils\accounts\account.dart`（buvid/deviceProfile 逻辑）
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\utils\accounts\account_adapter.dart`、`account.dart`
  - 两仓库 `lib/utils/storage.dart`（adapter 注册）
  - 迁移方案: `.sisyphus/evidence/batch0-hive-audit.md`

  **Acceptance Criteria**:
  - [ ] adapter 读写 6 字段
  - [ ] 迁移函数存在且处理边界（无账号/游客/损坏数据）
  - [ ] `test/hive_migration_test.dart` 存在且通过：4 类型 box → 迁移 → 6 值无崩溃
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 迁移测试通过（全计划最高优先级验收）
    Tool: Bash
    Preconditions: 迁移函数 + 测试已写
    Steps:
      1. 构造 4 类型旧 box（typeId 0-3）写入临时 Hive 目录
      2. 运行迁移函数
      3. 断言 AccountType.values[0..3] 映射正确、新值可解析
      4. 断言损坏 box（缺字段）不崩溃（容错）
    Expected Result: 全部断言通过
    Failure Indicators: 任一断言失败 / 崩溃
    Evidence: .sisyphus/evidence/task-6-migration-test.md

  Scenario: adapter 6 字段读写
    Tool: Bash
    Preconditions: adapter 修改完成
    Steps:
      1. 断言 read/write 覆盖 6 字段（含 field 4/5）
      2. dart analyze 0 error
    Expected Result: 6 字段完整
    Failure Indicators: 缺字段
    Evidence: .sisyphus/evidence/task-6-adapter.md
  ```

  **Commit**: YES
  - Message: `feat(accounts): persist per-account buvid/deviceProfile with 4→6 migration`
  - Files: `lib/utils/accounts/account_adapter.dart`, `lib/utils/accounts/account.dart`, `lib/utils/storage.dart`, `test/hive_migration_test.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings && dart test test/hive_migration_test.dart`

- [x] 7. Accounts 生命周期状态机（canonicalize/snapshot/reply/blacklist）

  **What to do**:
  - 按需重写 `lib/utils/accounts.dart`：`_AccountLifecycleState` + `canonicalize` + `mainIdentity/videoIdentity/heartbeatIdentity` getter + `reply`/`blacklist` getter + `refresh` 回写 BUVID + 清理旧 `'buvid'` 键
  - 按需重写 `lib/utils/accounts/account_manager/account_mgr.dart`：`_resolveAccountSelection`（identity snapshot）+ 心跳检查用 identity.isLogin + 保留 B 的 `OS.isHarmony` dioError 分支
  - 按需重写 `lib/utils/accounts/account.dart` 的 `AnonymousAccount.delete()`：删 guest BUVID + 重置 buvid3（保留 B 的 fawkes hack？按 Task 1 残留决策）
  - 检查 `lib/http/init.dart` 的 `setCookie`/`Accounts.refresh` 调用点适配

  **Must NOT do**:
  - 不删除 B 的 `OS.isHarmony` 分支（account_mgr dioError）
  - 不破坏 B 的 connectivity_plus 5.x 单值 API（`.desc` 而非 `.first.desc`）
  - 不改 `identity_owner.dart`（两仓库逐字节相同）

  **Recommended Agent Profile**:
  - **Category**: `deep` — 生命周期状态机逻辑重
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 1 Wave 1.1 (Tasks 5-8)
  - **Blocks**: 9,10,16,22,23
  - **Blocked By**: 1,2,5

  **References**:
  - A: `D:\coding\PiliPlusX\lib\utils\accounts.dart`（状态机）
  - A: `D:\coding\PiliPlusX\lib\utils\accounts\account_manager\account_mgr.dart`
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\utils\accounts.dart`、`account_manager\account_mgr.dart`
  - 对比报告 `02_accounts_report.md`

  **Acceptance Criteria**:
  - [ ] `Accounts` 含 canonicalize + 3 identity getter + reply/blacklist getter
  - [ ] `account_mgr` 的 OHOS 分支（OS.isHarmony、单值 connectivity）保留
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 状态机符号存在
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'canonicalize' lib/utils/accounts.dart → 命中
      2. grep 'mainIdentity' → 命中
      3. grep 'Accounts.reply' 在 http/ 中命中
    Expected Result: 全部命中
    Failure Indicators: 任一 grep 空
    Evidence: .sisyphus/evidence/task-7-state-machine.md

  Scenario: OHOS 分支保留
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'OS.isHarmony' lib/utils/accounts/account_manager/account_mgr.dart → 命中
      2. grep '\.desc' 确认单值 connectivity 用法
    Expected Result: 命中
    Failure Indicators: OHOS 分支丢失
    Evidence: .sisyphus/evidence/task-7-ohos-preserved.md
  ```

  **Commit**: YES
  - Message: `feat(accounts): add lifecycle state machine with canonicalize/snapshots`
  - Files: `lib/utils/accounts.dart`, `lib/utils/accounts/account_manager/account_mgr.dart`, `lib/utils/accounts/account.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [x] 8. RequestIdentityAdapter + 身份解析接入

  **What to do**:
  - 按需重写 A 的 `lib/utils/accounts/request_identity_adapter.dart`（ONLY_A，A 独有）到 B（新建文件）：`RequestIdentityAdapter` 身份装饰器
  - 接入 B 的 `lib/http/login.dart`、`lib/http/member.dart`、`lib/http/video.dart`、`lib/http/live.dart`、`lib/http/search.dart`、`lib/http/follow.dart`、`lib/http/dynamics.dart` 中 A 使用的身份字段（buvid/localId/deviceId/sessionId/traceId/fp）
  - 按需重写 `lib/utils/login_utils.dart`：`generateBuvid()` 接 identity、恢复 `setAccountUname` 调用、`buvid` getter 语义（保持 B 的 `genDeviceId()` 若被 http 使用）
  - 按需重写 `lib/utils/wbi_sign.dart`：`encWbi` 追加 `appendRiskFingerprintParams`（dm_img_* 风控字段）+ `getWbiKeys` catchError

  **Must NOT do**:
  - 不破坏 B 现有登录流程（扫码/密码登录）
  - 不删除 B 的 `genDeviceId`（可能被 http/login 使用）
  - 不引入新依赖（identity 用现有 crypto/utils）

  **Recommended Agent Profile**:
  - **Category**: `deep` — 跨 http 层接入面广
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 1 Wave 1.1 (Tasks 5-8)
  - **Blocks**: 9,12,13,16,17
  - **Blocked By**: 1,3,5

  **References**:
  - A: `D:\coding\PiliPlusX\lib\utils\accounts\request_identity_adapter.dart`（唯一参照）
  - A: `D:\coding\PiliPlusX\lib\utils\login_utils.dart`、`lib\utils\wbi_sign.dart`
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\utils\login_utils.dart`、`wbi_sign.dart`
  - B http 层消费点: `lib/http/login.dart` 等 7 文件
  - 对比报告 `01_http_report.md`、`02_accounts_report.md`

  **Acceptance Criteria**:
  - [ ] `request_identity_adapter.dart` 存在且编译通过
  - [ ] wbi 签名含 dm_img_* 风控字段
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 身份适配器编译可达
    Tool: Bash
    Preconditions: 修改完成
    Steps:
      1. grep 'RequestIdentityAdapter' lib/utils/accounts/request_identity_adapter.dart → 类存在
      2. grep 其在 lib/http/login.dart 中引用 → 命中
      3. dart analyze 0 error
    Expected Result: 全部命中
    Failure Indicators: 未接线 / analyze error
    Evidence: .sisyphus/evidence/task-8-identity-adapter.md

  Scenario: wbi 风控字段
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'appendRiskFingerprintParams\|dm_img' lib/utils/wbi_sign.dart → 命中
    Expected Result: 命中
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-8-wbi.md
  ```

  **Commit**: YES
  - Message: `feat(accounts): port RequestIdentityAdapter and wbi risk fields`
  - Files: `lib/utils/accounts/request_identity_adapter.dart`（新）, `lib/utils/login_utils.dart`, `lib/utils/wbi_sign.dart`, `lib/http/*.dart`（接入点）
  - Pre-commit: `dart analyze --no-fatal-warnings`

### Batch 1 Wave 1.2 — Tasks 9-11 并行

- [x] 9. gRPC 头按账号快照 + wbi 风控字段

  **What to do**:
  - 按需重写 `lib/utils/accounts/grpc_headers.dart`：按账号快照解析身份（buvid/deviceProfile/mid/auroraEid）、`Device` proto 填真实 brand/model/osver 与 fpLocal/fpRemote/guestId、带 `x-bili-mid`/`x-bili-restriction-bin`/`x-bili-ticket`（参照 A；B 全静态占位）
  - 接入 B 的 `lib/grpc/grpc_req.dart`、`lib/grpc/im.dart`（如 A 的 `GrpcHeaders.currentImDeviceId` 使用点）
  - **关键检查**：B 用 gRPC-over-HTTP（dio_http2_adapter），A 的每账号 gRPC 头注入机制是否兼容——若 B 的 gRPC 是单例，需改为按请求取账号头（Task 3 审计结论落地）
  - 保留 B 的 `_buvid => LoginUtils.buvid` 回退路径（无账号时）

  **Must NOT do**:
  - 不编辑 `*.pb*.dart`（protobuf 生成）
  - 不破坏 B gRPC-over-HTTP 传输架构（除非 Task 3 明确判定需改）
  - 不改 `identity_owner.dart`

  **Recommended Agent Profile**:
  - **Category**: `deep` — gRPC 头注入机制适配
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 1 Wave 1.2 (Tasks 9-11)
  - **Blocks**: 12,13,14,17,18,23
  - **Blocked By**: 5,6,7,8,3

  **References**:
  - A: `D:\coding\PiliPlusX\lib\utils\accounts\grpc_headers.dart`（按账号快照）
  - A: `D:\coding\PiliPlusX\lib\grpc\grpc_req.dart`、`lib\grpc\im.dart`
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\utils\accounts\grpc_headers.dart`、`lib\grpc\grpc_req.dart`
  - 对比报告 `02_accounts_report.md`（gRPC 头差异细节）

  **Acceptance Criteria**:
  - [ ] grpc_headers 按账号快照构建（含真实 device 字段 + mid/restriction/ticket）
  - [ ] B 的 gRPC-over-HTTP 传输不破坏（编译 + 结构审查）
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: gRPC 头按账号
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'x-bili-mid\|restriction-bin\|ticket' lib/utils/accounts/grpc_headers.dart → 命中
      2. grep 'deviceProfile' 在 grpc_headers 中 → 命中
    Expected Result: 命中
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-9-grpc-headers.md

  Scenario: gRPC 架构不破坏
    Tool: Bash
    Preconditions: 修改完成
    Steps:
      1. 审查 grpc_req.dart 的 channel 创建仍走 B 的 HTTP/2 适配
      2. dart analyze 0 error
    Expected Result: 架构保留
    Failure Indicators: 架构被改
    Evidence: .sisyphus/evidence/task-9-grpc-arch.md
  ```

  **Commit**: YES
  - Message: `feat(accounts): per-account gRPC headers with real device identity`
  - Files: `lib/utils/accounts/grpc_headers.dart`, `lib/grpc/grpc_req.dart`, `lib/grpc/im.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [x] 10. BUVID 激活重试 + 登出清理 + 昵称缓存

  **What to do**:
  - 按需重写 `lib/http/init.dart` 的 `buvidActive`：成功后才置 `activated=true`、失败保持可重试（参照 A 语义；保留 B 的 `Utils.random` 生成方式与 OHOS 注释）
  - 按需重写 `lib/utils/accounts/account.dart` 的 `AnonymousAccount.delete()`：删 guest BUVID + 重置 buvid3（按 Task 1 残留决策决定 fawkes hack 去留）
  - 恢复 `lib/utils/login_utils.dart` 的 `setAccountUname` 调用 + `lib/pages/mine/controller.dart` 写入 `accountUnameMap`（多账号昵称缓存）
  - 检查 `lib/http/init.dart` 的 `setCookie` 是否 await `Accounts.refresh()`（A 语义）——按需对齐但保留 B 的 sync 约束（若 B 有原因）

  **Must NOT do**:
  - 不破坏 B 的 `Utils.random`/`OS.isHarmony` 用法
  - 不改 `storage_pref.dart` 的 `accountUnameMap` 读取逻辑（B 已有读取方）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 1 Wave 1.2 (Tasks 9-11)
  - **Blocks**: 14,22,28
  - **Blocked By**: 6,7

  **References**:
  - A: `D:\coding\PiliPlusX\lib\http\init.dart`（buvidActive 重试语义）
  - A: `D:\coding\PiliPlusX\lib\utils\accounts\account.dart`（delete 清理）
  - A: `D:\coding\PiliPlusX\lib\utils\login_utils.dart`、`lib\pages\mine\controller.dart`（setAccountUname）
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\http\init.dart`、`lib\utils\accounts\account.dart`
  - 对比报告 `02_accounts_report.md`（第 7、9、10 条）

  **Acceptance Criteria**:
  - [ ] buvidActive 失败可重试（activated 仅在成功后置 true）
  - [ ] delete() 清理 guest BUVID
  - [ ] setAccountUname 有调用方（login_utils 或 mine controller）
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: BUVID 激活重试语义
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. 审查 init.dart：activated=true 赋值在请求成功之后
      2. grep 'activated' 确认失败路径不置 true
    Expected Result: 重试语义正确
    Failure Indicators: 顺序错误
    Evidence: .sisyphus/evidence/task-10-buvid-retry.md

  Scenario: 昵称缓存写入
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'setAccountUname' lib/ → 命中 login_utils 或 mine/controller
      2. grep 'accountUnameMap' lib/utils/storage_pref.dart → 命中读取方
    Expected Result: 写入方 + 读取方都存在
    Failure Indicators: 无写入方
    Evidence: .sisyphus/evidence/task-10-nickname.md
  ```

  **Commit**: YES
  - Message: `feat(accounts): buvid activation retry, logout cleanup, nickname cache`
  - Files: `lib/http/init.dart`, `lib/utils/accounts/account.dart`, `lib/utils/login_utils.dart`, `lib/pages/mine/controller.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [x] 11. CustomHostInterceptor + HkApiRetryInterceptor + api_host_page 入口

  **What to do**:
  - 新建 `lib/http/custom_host_interceptor.dart`（参照 A，ONLY_A）：自定义 API Host 重写拦截器
  - 新建 `lib/http/hk_api_retry_interceptor.dart`（参照 A，ONLY_A）：港澳台代理重试拦截器
  - 接入 `lib/http/init.dart` 的 dio 拦截器链（保留 B 现有拦截器顺序，新拦截器插入正确位置）
  - gRPC 层 `Pref.customAppBaseUrl` 支持（若 Task 3 确认 B gRPC-over-HTTP 可支持）
  - 恢复 `lib/pages/setting/pages/api_host_page.dart` 入口（B 已注册 `/apiHostSetting` 路由但无入口；在设置页加入口）
  - 检查 `Pref.enableCustomApiHost`/`apiHKUrl` 消费点激活

  **Must NOT do**:
  - 不删除 B 现有拦截器（retry_interceptor 等）
  - 港澳台代理默认关闭（`Pref.apiHKUrl` 默认空，避免大陆用户被代理）
  - 不新增网络依赖

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 1 Wave 1.2 (Tasks 9-11)
  - **Blocks**: 12（hk_bangumi 依赖代理）,28
  - **Blocked By**: 1,3

  **References**:
  - A: `D:\coding\PiliPlusX\lib\http\custom_host_interceptor.dart`、`lib\http\hk_api_retry_interceptor.dart`（唯一参照）
  - A: `D:\coding\PiliPlusX\lib\http\init.dart`（拦截器链）
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\http\init.dart`、`lib\pages\setting\pages\api_host_page.dart`
  - B 设置页: `lib/pages/setting/view.dart`（加入口）
  - 对比报告 `01_http_report.md`（拦截器差异）

  **Acceptance Criteria**:
  - [ ] 两个拦截器文件存在且接入 dio 链
  - [ ] api_host_page 有设置入口可达
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 拦截器接入
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'CustomHostInterceptor\|HkApiRetryInterceptor' lib/http/init.dart → 命中
      2. 审查拦截器链顺序（自定义 host 在最前）
    Expected Result: 接入且顺序正确
    Failure Indicators: 未接入
    Evidence: .sisyphus/evidence/task-11-interceptors.md

  Scenario: 设置入口
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'apiHostSetting\|ApiHostPage' lib/pages/setting/ → 入口存在
      2. grep 'Pref.enableCustomApiHost' 在 init.dart 消费 → 命中
    Expected Result: 入口可达 + Pref 被消费
    Failure Indicators: 死设置
    Evidence: .sisyphus/evidence/task-11-api-host.md
  ```

  **Commit**: YES
  - Message: `feat(http): custom API host and HK/TW proxy interceptors`
  - Files: `lib/http/custom_host_interceptor.dart`（新）, `lib/http/hk_api_retry_interceptor.dart`（新）, `lib/http/init.dart`, `lib/pages/setting/pages/api_host_page.dart`, `lib/pages/setting/view.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

### Batch 2 — 内容功能（依赖 Batch 1；6 任务并行）

- [ ] 12. 港澳台番剧（HomeTab/搜索/pgc 代理）

  **What to do**:
  - `lib/models/common/home_tab_type.dart`：加 `hk_bangumi` 枚举值 + `ctr`/`page` switch 分支（参照 A）
  - `lib/models/common/search/search_type.dart`：加 `media_hk_bangumi`（参照 A）
  - `lib/pages/pgc/controller.dart` + `view.dart`：`HomeTabType.hk_bangumi` 支持 + `Pref.apiHKUrl` 代理（依赖 Task 11 拦截器）+ 未配置代理 Error 提示
  - `lib/pages/search_result/view.dart`：加 `media_hk_bangumi` 搜索 Tab
  - `lib/http/pgc.dart`、`lib/http/search.dart`：hk 分支（参照 A，按需重写，B 已删除）

  **Must NOT do**:
  - 不把港澳台代理设为默认开启（Pref.apiHKUrl 默认空）
  - 不改 `home_tab_type` 的既有 6 值行为

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 2 (Tasks 12-17)
  - **Blocks**: 24,28
  - **Blocked By**: 5,9,11

  **References**:
  - A: `D:\coding\PiliPlusX\lib\models\common\home_tab_type.dart`、`lib\models\common\search\search_type.dart`
  - A: `D:\coding\PiliPlusX\lib\pages\pgc\controller.dart`、`lib\pages\pgc\view.dart`、`lib\pages\search_result\view.dart`
  - A: `D:\coding\PiliPlusX\lib\http\pgc.dart`、`lib\http\search.dart`
  - B 现状: 对应文件（B 已删 hk 分支）
  - 对比报告 `05a_models_report.md`、`08_live_search_report.md`

  **Acceptance Criteria**:
  - [ ] home_tab_type 含 hk_bangumi + switch 分支
  - [ ] search_type 含 media_hk_bangumi
  - [ ] pgc controller 处理 hk_bangumi + apiHKUrl 代理 + 未配置提示
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 枚举 + 路由接线
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'hk_bangumi' lib/models/common/home_tab_type.dart → 命中
      2. grep 'media_hk_bangumi' lib/models/common/search/search_type.dart → 命中
      3. grep 'apiHKUrl' lib/pages/pgc/controller.dart → 命中
    Expected Result: 全部命中
    Failure Indicators: 任一缺失
    Evidence: .sisyphus/evidence/task-12-hk-bangumi.md

  Scenario: 代理默认关闭
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. 检查 Pref.apiHKUrl 默认值为空
      2. 检查 hk_bangumi 分支在 apiHKUrl 为空时给 Error 提示
    Expected Result: 默认关闭 + 提示
    Failure Indicators: 默认开启
    Evidence: .sisyphus/evidence/task-12-hk-default.md
  ```

  **Commit**: YES
  - Message: `feat(bangumi): HK/TW bangumi tab and search with proxy support`
  - Files: `lib/models/common/home_tab_type.dart`, `lib/models/common/search/search_type.dart`, `lib/pages/pgc/controller.dart`, `lib/pages/pgc/view.dart`, `lib/pages/search_result/view.dart`, `lib/http/pgc.dart`, `lib/http/search.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 13. AI 总结多服务（router + legacy/multimodal adapters + 设置组）

  **What to do**:
  - 新建 `lib/http/ai_summary_service_router.dart`（参照 A，ONLY_A）：`AiSummaryServiceRouter` 服务选择路由
  - 新建 `lib/http/bilibili_multimodal_summary_adapter.dart`、`bilibili_subtitle_summary_adapter.dart`（参照 A；若 Task 3 判定 API 不可用则标注并降级）
  - 新建 `lib/http/openai_compatible_summary_provider.dart`（参照 A，B 已有同名？确认 B 现状——对比报告显示 `openai_compatible_summary_provider.dart` 两仓库 SAME，则复用）
  - 恢复 `VideoHttp.ugcSummaryMp4Url`、`VideoHttp.transcriptSubtitles`（lib/http/video.dart，参照 A）
  - 接入 `lib/pages/video/ai_conclusion/view.dart`（B 现有，确认调用 router 而非直连）
  - 设置组恢复：`Pref.enableAiSummaryBackground` + AI 总结配置项（Base URL/API Key/模型/超时/服务选择）

  **Must NOT do**:
  - 不引入新依赖（OpenAI 兼容 provider 用 B 现有 http）
  - 不删 B 的 `bilibili_legacy_summary_adapter.dart`（两仓库 SAME）
  - 不动 4 个「鸿蒙待适配」TODO 之一（AI-summary sheet）——弹层拖拽问题保留

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 2 (Tasks 12-17)
  - **Blocks**: 24,28
  - **Blocked By**: 5,8,9

  **References**:
  - A: `D:\coding\PiliPlusX\lib\http\ai_summary_service_router.dart`、`bilibili_multimodal_summary_adapter.dart`、`bilibili_subtitle_summary_adapter.dart`（唯一参照）
  - A: `D:\coding\PiliPlusX\lib\http\video.dart`（ugcSummaryMp4Url/transcriptSubtitles）
  - B 现状: `lib/http/openai_compatible_summary_provider.dart`（SAME）、`lib/pages/video/ai_conclusion/view.dart`
  - B 设置: `lib/pages/setting/`（AI 总结配置组）
  - 对比报告 `01_http_report.md`（AI 总结收缩细节）

  **Acceptance Criteria**:
  - [ ] router + ≥2 adapter（legacy+multimodal）存在
  - [ ] ugcSummaryMp4Url/transcriptSubtitles 恢复
  - [ ] ai_conclusion view 走 router
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: router 接线
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'AiSummaryServiceRouter' lib/http/ai_summary_service_router.dart → 类存在
      2. grep 'AiSummaryServiceRouter' lib/pages/video/ai_conclusion/ → 被消费
      3. grep 'ugcSummaryMp4Url' lib/http/video.dart → 命中
    Expected Result: 全部命中
    Failure Indicators: 未接线
    Evidence: .sisyphus/evidence/task-13-ai-summary.md

  Scenario: 设置组恢复
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'enableAiSummaryBackground' lib/pages/setting/ → 设置项存在
      2. grep 'aiSummaryService' Pref → 消费点存在
    Expected Result: 设置组可用
    Failure Indicators: 死设置
    Evidence: .sisyphus/evidence/task-13-ai-settings.md
  ```

  **Commit**: YES
  - Message: `feat(ai): multi-service AI summary router with adapters`
  - Files: `lib/http/ai_summary_service_router.dart`（新）, `lib/http/bilibili_multimodal_summary_adapter.dart`（新）, `lib/http/bilibili_subtitle_summary_adapter.dart`（新）, `lib/http/video.dart`, `lib/pages/video/ai_conclusion/view.dart`, `lib/pages/setting/*`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 14. 评论屏蔽 checkBlockReason 5 策略 + BlockedReplyBanner

  **What to do**:
  - 按需重写 `lib/grpc/reply.dart`：恢复 `checkBlockReason`（关键词/带货/等级/@过滤/黑名单 5 策略）+ `blockReply`/`clearBlockedReasons`/`isClientBlocked`/`getBlockReason`/`getBriefBlockReason`（参照 A）
  - 恢复 `lib/pages/video/reply/widgets/reply_item_grpc.dart` 的 BlockedReplyBanner 折叠横幅 + "查看评论"展开（B 现状为静默删除）
  - 恢复 `Pref.showBlockedReplyBanner`、`minLevelForReply` 的实际消费（B 中字段保留但逻辑失效）
  - 恢复 `Pref.enableAtFilter` 的 @过滤逻辑（A 在 grpc/reply 层；B 无）
  - 评论排序 `canSort`（`subjectControl.switcherType`）——放 Task 16

  **Must NOT do**:
  - 不编辑 `*.pb*.dart`（回复相关 protobuf 生成文件两仓库 DIFF，但禁止手改）
  - 不删 B 的 `reply_translate.dart`（虽孤儿，但勿动）
  - 不动 `lib/common/widgets/flutter/text_field/text_selection.dart`

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 2 (Tasks 12-17)
  - **Blocks**: 24
  - **Blocked By**: 5,6,7,10

  **References**:
  - A: `D:\coding\PiliPlusX\lib\grpc\reply.dart`（5 策略 + 横幅相关）
  - A: `D:\coding\PiliPlusX\lib\pages\video\reply\widgets\reply_item_grpc.dart`
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\grpc\reply.dart`（仅关键词+带货）、`lib\pages\video\reply\widgets\reply_item_grpc.dart`
  - B 设置: `lib/pages/setting/models/block_filter_settings.dart`（UI 残留，Task 1 决策复用）
  - 对比报告 `01_http_report.md`（评论屏蔽收缩）、`06_video_report.md`

  **Acceptance Criteria**:
  - [ ] checkBlockReason 5 策略恢复
  - [ ] BlockedReplyBanner 横幅恢复（非静默删除）
  - [ ] showBlockedReplyBanner/minLevelForReply 有消费点
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 5 策略屏蔽
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'checkBlockReason' lib/grpc/reply.dart → 命中
      2. grep 'blockReply\|clearBlockedReasons' → 命中
      3. grep 'enableAtFilter' lib/grpc/reply.dart → @过滤策略命中
    Expected Result: 全部命中
    Failure Indicators: 策略缺失
    Evidence: .sisyphus/evidence/task-14-block-reason.md

  Scenario: 横幅恢复
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'BlockedReplyBanner\|showBlockedReplyBanner' lib/pages/video/reply/ → 命中
      2. 审查 reply_item_grpc 中屏蔽评论走横幅而非 removeWhere 静默删
    Expected Result: 横幅路径恢复
    Failure Indicators: 仍静默删除
    Evidence: .sisyphus/evidence/task-14-banner.md
  ```

  **Commit**: YES
  - Message: `feat(reply): restore 5-strategy client-side blocking with banner`
  - Files: `lib/grpc/reply.dart`, `lib/pages/video/reply/widgets/reply_item_grpc.dart`, `lib/pages/setting/models/block_filter_settings.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 15. 评论翻译横幅 + 评论申诉

  **What to do**:
  - 按需重写 `lib/pages/video/reply/controller.dart`：`translatedReplies` RxMap + `translateReply(ReplyInfo)`（参照 A 横幅式）
  - 按需重写 `lib/pages/video/reply/widgets/reply_item_grpc.dart`：`translatedText`/`isTranslating`/`onTranslate` 参数 + `forceShowOriginalContent`（横幅交互）
  - 确认 B 的 `lib/grpc/reply_translate.dart`（SAME 文件）中 `translateReply` 可用；若 B 的 `GrpcUrl.translateReply` 签名单 rpid 而 A 批量——按 B 现状适配（Task 1/3 结论）
  - 评论申诉：`lib/http/reply.dart` 恢复 `appealComment` + `Api.replyAppealSubmit`（lib/http/api.dart）+ `Pref.defaultAppealReason` 设置 + 申诉对话框（参照 A `lib/utils/reply_utils.dart` 的站内申诉）

  **Must NOT do**:
  - 不编辑 `*.pb*.dart`
  - 不删 B 的 `reply_translate.dart`（若 B 用它则接 B 签名）
  - 不恢复 `SelectionText`（A 的 reply_utils 用 SelectionText——按 B 适配为 SelectableText）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 2 (Tasks 12-17)
  - **Blocks**: 24
  - **Blocked By**: 5,8,9

  **References**:
  - A: `D:\coding\PiliPlusX\lib\pages\video\reply\controller.dart`（横幅式翻译）
  - A: `D:\coding\PiliPlusX\lib\utils\reply_utils.dart`（8 状态机 + 站内申诉）
  - A: `D:\coding\PiliPlusX\lib\http\reply.dart`、`lib\http\api.dart`（appealComment/replyAppealSubmit）
  - B 现状: `lib\pages\video\reply\controller.dart`、`lib\utils\reply_utils.dart`、`lib\grpc\reply_translate.dart`
  - 对比报告 `03_utils_report.md`、`06_video_report.md`

  **Acceptance Criteria**:
  - [ ] 翻译横幅（translatedReplies + translatedText 参数）恢复
  - [ ] appealComment + replyAppealSubmit + defaultAppealReason 设置恢复
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 翻译横幅
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'translatedReplies' lib/pages/video/reply/controller.dart → 命中
      2. grep 'forceShowOriginalContent' lib/pages/video/reply/ → 命中
    Expected Result: 横幅式翻译接线
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-15-translate.md

  Scenario: 申诉恢复
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'appealComment' lib/http/reply.dart → 命中
      2. grep 'replyAppealSubmit' lib/http/api.dart → 命中
      3. grep 'defaultAppealReason' lib/pages/setting/ → 设置存在
    Expected Result: 全部命中
    Failure Indicators: 申诉缺失
    Evidence: .sisyphus/evidence/task-15-appeal.md
  ```

  **Commit**: YES
  - Message: `feat(reply): banner-style translation and comment appeal`
  - Files: `lib/pages/video/reply/controller.dart`, `lib/pages/video/reply/widgets/reply_item_grpc.dart`, `lib/http/reply.dart`, `lib/http/api.dart`, `lib/utils/reply_utils.dart`, `lib/pages/setting/*`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 16. canSort + 长按拉黑/分享 + 手动加载评论图

  **What to do**:
  - `canSort` 排序可用性开关：`lib/pages/main_reply/view.dart` + `lib/pages/common/reply_controller.dart`（`subjectControl.switcherType` 控制，参照 A）
  - 评论长按菜单扩展：拉黑评论者（`relationMod act:5` + 黑名单）+ 分享评论（`ShareUtils.shareText`）（参照 A `reply_item_grpc` 长按菜单）
  - 手动加载评论图：`Pref.manualLoadCommentImage` + 加载按钮（参照 A）
  - `Pref.enableImageBlock` 评论图屏蔽（与 Task 20 图片屏蔽联动，此处只做评论上下文）

  **Must NOT do**:
  - 不删 B 现有评论长按菜单项（superchat 等）
  - **已更新（Batch 0）**：允许删除 3 个孤儿 part 文件（`context_menu/dyn_menu_helper.dart`、`reply_menu_helper.dart`、`live_menu_helper.dart`）——它们是死代码（宿主库无 `part` 声明）且造成 B HEAD 85 个 analyze 错误；原 guardrail「不动 reply_menu_helper.dart」基于错误假设，作废

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 2 (Tasks 12-17)
  - **Blocks**: 24
  - **Blocked By**: 5,7,8

  **References**:
  - A: `D:\coding\PiliPlusX\lib\pages\main_reply\view.dart`、`lib\pages\common\reply_controller.dart`（canSort）
  - A: `D:\coding\PiliPlusX\lib\pages\video\reply\widgets\reply_item_grpc.dart`（长按菜单）
  - A: `D:\coding\PiliPlusX\lib\utils\share_utils.dart`
  - B 现状: 对应文件
  - 对比报告 `07_dynamics_report.md`（canSort）、`06_video_report.md`

  **Acceptance Criteria**:
  - [ ] canSort 逻辑恢复（switcherType 控制排序按钮可用性）
  - [ ] 长按菜单含拉黑评论者 + 分享评论
  - [ ] manualLoadCommentImage 生效
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: canSort
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'canSort' lib/pages/main_reply/view.dart → 命中
      2. grep 'switcherType' lib/pages/common/reply_controller.dart → 命中
    Expected Result: canSort 接线
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-16-cansort.md

  Scenario: 长按菜单
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'relationMod' 长按菜单处理 → 拉黑命中
      2. grep 'ShareUtils.shareText' → 分享命中
      3. grep 'manualLoadCommentImage' Pref 消费 → 命中
    Expected Result: 全部命中
    Failure Indicators: 菜单项缺失
    Evidence: .sisyphus/evidence/task-16-longpress.md
  ```

  **Commit**: YES
  - Message: `feat(reply): canSort, long-press blacklist/share, manual image load`
  - Files: `lib/pages/main_reply/view.dart`, `lib/pages/common/reply_controller.dart`, `lib/pages/video/reply/widgets/reply_item_grpc.dart`, `lib/utils/share_utils.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 17. 私信会话详情 + whisper 标为已读

  **What to do**:
  - 按需重写 `lib/grpc/im.dart`：恢复 `sessionDetail`（参照 A；B 已删，whisper item 已改造）
  - 按需重写 `lib/grpc/url.dart`：恢复 `GrpcUrl.sessionDetail`
  - 恢复 whisper 会话"标为已读"：`lib/pages/whisper/widgets/item.dart` 长按/右键菜单（参照 A）
  - 确认 B 的 gRPC-over-HTTP 支持该 RPC（不重新生成 pb stub——若 `*.pb*.dart` 缺该方法，检查 B 的 `lib/grpc/bilibili/app/im/v1.pb.dart` 是否已有（SAME 文件两仓库相同，则存在））

  **Must NOT do**:
  - 不编辑 `*.pb*.dart`
  - 不删 B 的 whisper 改造逻辑（仅补回标为已读）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 2 (Tasks 12-17)
  - **Blocks**: 24
  - **Blocked By**: 9

  **References**:
  - A: `D:\coding\PiliPlusX\lib\grpc\im.dart`、`lib\grpc\url.dart`（sessionDetail）
  - A: `D:\coding\PiliPlusX\lib\pages\whisper\widgets\item.dart`（标为已读）
  - B 现状: 对应文件
  - B pb: `lib/grpc/bilibili/app/im/v1.pb.dart`（确认 SAME）
  - 对比报告 `01_http_report.md`（sessionDetail 移除）、`07_dynamics_report.md`（标为已读删除）

  **Acceptance Criteria**:
  - [ ] ImGrpc.sessionDetail + GrpcUrl.sessionDetail 恢复
  - [ ] whisper item 标为已读菜单恢复
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: sessionDetail 恢复
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'sessionDetail' lib/grpc/im.dart → 命中
      2. grep 'sessionDetail' lib/grpc/url.dart → 命中
    Expected Result: 命中
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-17-session.md

  Scenario: 标为已读
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep '标为已读\|markRead\|setRead' lib/pages/whisper/widgets/item.dart → 命中
    Expected Result: 菜单恢复
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-17-markread.md
  ```

  **Commit**: YES
  - Message: `feat(whisper): session detail RPC and mark-as-read`
  - Files: `lib/grpc/im.dart`, `lib/grpc/url.dart`, `lib/pages/whisper/widgets/item.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

### Batch 3 — 交互功能（依赖 Batch 1-2；6 任务并行）

- [ ] 18. Stein 互动视频数据模型 + 进度恢复

  **What to do**:
  - 按需重写 `lib/models_new/video/video_stein_edgeinfo/*.dart`（choice/data/edges/question 4 个 DIFF，参照 A 的 fork 完整版；B 为精简版）
  - 按需重写 `lib/pages/video/controller.dart`：`steinResumeNode` + `goToSteinStoryNode` + 本地历史栈/进度回溯数据 + 进度恢复对话框（参照 A）
  - 确认 B 的 `video_detail` 模型含 `rights.isSteinGate` 判定（SAME 文件则无需改）

  **Must NOT do**:
  - 不编辑 `*.g.dart`、`*.pb*.dart`
  - **不改 B 播放器核心**（除非 Task 19 一并处理）
  - **已更新（Batch 0）**：严禁复制 A 的 `_initPlayer`/`_createVideoController`/`SimpleVideo` 段落——A fork（My-Responsitories 1.1.11）的 `Player.create`/`setMediaHeader`/`SimpleVideo` 在 B fork（cnoim 1.2.3）中不存在；Stein 逻辑必须 graft 到 B 现有 pl_player（`Player()`/`VideoController()`/`Media(httpHeaders:)`/`Video(controls:NoVideoControls)`）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 3 (Tasks 18-23)
  - **Blocks**: 19,25
  - **Blocked By**: 9,13

  **References**:
  - A: `D:\coding\PiliPlusX\lib\models_new\video\video_stein_edgeinfo\`（4 DIFF 文件）
  - A: `D:\coding\PiliPlusX\lib\pages\video\controller.dart`（stein 逻辑）
  - B 现状: 对应文件
  - 对比报告 `05b_models_new_report.md`（stein 模型差异）、`06_video_report.md`

  **Acceptance Criteria**:
  - [ ] stein 模型恢复 fork 完整版（choice/data/edges/question）
  - [ ] video controller 含 steinResumeNode/goToSteinStoryNode/历史栈
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: Stein 模型完整
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'steinResumeNode' lib/pages/video/controller.dart → 命中
      2. grep 'goToSteinStoryNode' → 命中
      3. 断言 video_stein_edgeinfo 4 文件与 A 版本字段对齐（抽查）
    Expected Result: 全部命中
    Failure Indicators: 模型或逻辑缺失
    Evidence: .sisyphus/evidence/task-18-stein-model.md
  ```

  **Commit**: YES
  - Message: `feat(stein): interactive video models and progress resume`
  - Files: `lib/models_new/video/video_stein_edgeinfo/*.dart`, `lib/pages/video/controller.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 19. Stein 播放器 UI（回溯面板/BottomControlType.stein/showStein/interactiveChild）

  **What to do**:
  - `lib/plugin/pl_player/models/bottom_control_type.dart`：加 `stein` 枚举值（参照 A；B 已删）
  - `lib/plugin/pl_player/controller.dart` + `view/view.dart`：`showStein` 回调 + `interactiveChild` 参数 + 进度回溯面板 `_showSteinHistorySheet`（参照 A；B 已删）
  - `lib/plugin/pl_player/models/fullscreen_mode.dart`、`data_source.dart` 若 A 有 stein 相关字段则一并恢复
  - **关键**：Task 3 确认 media_kit OHOS fork 是否支持所需 API；不支持则用 B 现有播放器能力实现等价交互
  - **runtime-pending** 标记：回溯面板 UI 交互仅设备可验证

  **Must NOT do**:
  - 不改 B 的 media_kit OHOS fork 接入方式（Player()/setProperty）
  - 不删 B 播放器现有稳定适配（stall watchdog、PiP 等）
  - 不动 `text_selection.dart`

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 3 (Tasks 18-23)
  - **Blocks**: 25
  - **Blocked By**: 18,3

  **References**:
  - A: `D:\coding\PiliPlusX\lib\plugin\pl_player\models\bottom_control_type.dart`、`controller.dart`、`view\view.dart`（stein/showStein/interactiveChild）
  - B 现状: 对应文件
  - 对比报告 `06_player_report.md`（stein 移除）、`06_video_report.md`

  **Acceptance Criteria**:
  - [ ] bottom_control_type 含 stein
  - [ ] PLVideoPlayer 含 showStein/interactiveChild 参数
  - [ ] 回溯面板存在
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 播放器 stein 接线
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'stein' lib/plugin/pl_player/models/bottom_control_type.dart → 命中
      2. grep 'showStein\|interactiveChild' lib/plugin/pl_player/view/view.dart → 命中
      3. dart analyze 0 error
    Expected Result: 全部命中
    Failure Indicators: 播放器参数缺失
    Evidence: .sisyphus/evidence/task-19-stein-player.md
  ```

  **Commit**: YES
  - Message: `feat(stein): player backtrack panel and interactive child`
  - Files: `lib/plugin/pl_player/models/bottom_control_type.dart`, `lib/plugin/pl_player/controller.dart`, `lib/plugin/pl_player/view/view.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 20. 图片屏蔽 pHash UI 接入

  **What to do**:
  - 按需重写 `lib/common/widgets/image/blocked_image_placeholder.dart`：新版（"图片已屏蔽/长按查看" + 参数化，参照 A）
  - 接入 `lib/common/widgets/image_grid/image_grid_view.dart`：pHash 评估（`ImageBlockService.evaluateBlock`）+ `tempUnblockedUrls` + 屏蔽菜单 + `VisibilityDetector`（参照 A；B 为 StatelessWidget 无屏蔽）
  - 接入 `lib/common/widgets/image_viewer/gallery_viewer.dart`：屏蔽菜单 + 长按
  - 接入 `lib/common/widgets/dialog/report.dart`：举报联动屏蔽图片（`onBlockImages`）
  - `Pref.enableImageBlock`/`imageBlockHashList` 消费激活

  **Must NOT do**:
  - 不引入新依赖（pHash 用 B 现有 image_block_service + image 包；若 OHOS 缺原生通道则用纯 Dart 哈希——Task 3 确认）
  - 不删 B 的 `image_block_service.dart`（SAME）
  - 不动 `text_selection.dart`

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 3 (Tasks 18-23)
  - **Blocks**: 27
  - **Blocked By**: 5,16,3

  **References**:
  - A: `D:\coding\PiliPlusX\lib\common\widgets\image\blocked_image_placeholder.dart`、`image_grid\image_grid_view.dart`、`image_viewer\gallery_viewer.dart`、`dialog\report.dart`
  - B 现状: 对应文件（B 为旧版）
  - 对比报告 `04a_common_report.md`（图片屏蔽 UI 缺口）

  **Acceptance Criteria**:
  - [ ] BlockedImagePlaceholder 新版
  - [ ] image_grid_view 含 pHash 评估 + tempUnblockedUrls
  - [ ] report.dart 含 onBlockImages
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 图片屏蔽接线
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'ImageBlockService' lib/common/widgets/image_grid/image_grid_view.dart → 命中
      2. grep 'tempUnblockedUrls' → 命中
      3. grep 'onBlockImages' lib/common/widgets/dialog/report.dart → 命中
    Expected Result: 全部命中
    Failure Indicators: 屏蔽 UI 未接入
    Evidence: .sisyphus/evidence/task-20-image-block.md
  ```

  **Commit**: YES
  - Message: `feat(image): pHash blocking UI integration`
  - Files: `lib/common/widgets/image/blocked_image_placeholder.dart`, `lib/common/widgets/image_grid/image_grid_view.dart`, `lib/common/widgets/image_viewer/gallery_viewer.dart`, `lib/common/widgets/dialog/report.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 21. 直播反馈 + 卡片反馈按钮

  **What to do**:
  - 按需重写 `lib/http/api.dart`：恢复 `liveFeedback` 常量（参照 A）
  - 按需重写 `lib/http/live.dart`：恢复 `LiveHttp.liveFeedback` 方法（参照 A；保留 B 的 `sendLiveMsg` 等现有实现）
  - 恢复 `lib/pages/live/widgets/live_item_app.dart` 右上角反馈按钮（参照 A）
  - api_type.dart recommend 路由表补 `Api.liveFeedback`（若 Task 5 未含）

  **Must NOT do**:
  - 不删 B 的直播现有逻辑（live 是 OHOS 适配最密集子系统——保留 OS.isHarmony 分支）
  - 不编辑 `*.pb*.dart`

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 3 (Tasks 18-23)
  - **Blocks**: 24
  - **Blocked By**: 5

  **References**:
  - A: `D:\coding\PiliPlusX\lib\http\api.dart`（liveFeedback）、`lib\http\live.dart`、`lib\pages\live\widgets\live_item_app.dart`
  - B 现状: 对应文件
  - 对比报告 `01_http_report.md`（liveFeedback 移除）、`08_live_search_report.md`

  **Acceptance Criteria**:
  - [ ] Api.liveFeedback + LiveHttp.liveFeedback 恢复
  - [ ] live_item_app 反馈按钮恢复
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 直播反馈接线
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'liveFeedback' lib/http/api.dart → 命中
      2. grep 'LiveHttp.liveFeedback\|liveFeedback' lib/http/live.dart → 命中
      3. grep 'liveFeedback' lib/pages/live/widgets/live_item_app.dart → 按钮命中
    Expected Result: 全部命中
    Failure Indicators: 任一缺失
    Evidence: .sisyphus/evidence/task-21-live-feedback.md
  ```

  **Commit**: YES
  - Message: `feat(live): restore feedback endpoint and card button`
  - Files: `lib/http/api.dart`, `lib/http/live.dart`, `lib/pages/live/widgets/live_item_app.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 22. 快速分享 + pmShare + enableQuickShare/quickShareId

  **What to do**:
  - 按需重写 `lib/utils/request_utils.dart`：恢复 `pmShare`（参照 A；注意 A 的 pmShare 用 `SelectionText`——B 适配为 `SelectableText`）
  - 恢复分享按钮 `onLongPress`：`lib/pages/video/widgets/header_control.dart`、`lib/pages/video/introduction/ugc/view.dart`、`lib/pages/video/introduction/pgc/view.dart`（参照 A 三处）
  - `Pref.enableQuickShare`/`quickShareId` 设置项 + 消费
  - 设置项恢复放 Task 28 联动

  **Must NOT do**:
  - 不删 B 现有分享实现（Share.shareXFiles）
  - 不恢复 SelectionText
  - 不动 share_plus 版本（B 用 10.x）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 3 (Tasks 18-23)
  - **Blocks**: 24,28
  - **Blocked By**: 6,7,8,10

  **References**:
  - A: `D:\coding\PiliPlusX\lib\utils\request_utils.dart`（pmShare）
  - A: `D:\coding\PiliPlusX\lib\pages\video\widgets\header_control.dart`、`lib\pages\video\introduction\ugc\view.dart`、`lib\pages\video\introduction\pgc\view.dart`
  - B 现状: 对应文件
  - 对比报告 `06_video_report.md`（快速分享移除）

  **Acceptance Criteria**:
  - [ ] pmShare 恢复（SelectableText 适配）
  - [ ] 分享按钮 onLongPress 恢复（3 处）
  - [ ] enableQuickShare/quickShareId 消费点存在
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 快速分享接线
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'pmShare' lib/utils/request_utils.dart → 命中
      2. grep 'onLongPress' lib/pages/video/widgets/header_control.dart → 命中
      3. grep 'quickShareId' lib/pages/video/ → 消费命中
    Expected Result: 全部命中
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-22-quick-share.md

  Scenario: 无 SelectionText 恢复
    Tool: ast_grep
    Preconditions: 修改完成
    Steps:
      1. ast_grep_search pattern 'SelectionText(' in lib/pages/video/ lib/utils/request_utils.dart → 0 命中
    Expected Result: 0 命中（B 用 SelectableText）
    Failure Indicators: SelectionText 泄漏
    Evidence: .sisyphus/evidence/task-22-no-selectiontext.md
  ```

  **Commit**: YES
  - Message: `feat(share): quick share long-press with pmShare`
  - Files: `lib/utils/request_utils.dart`, `lib/pages/video/widgets/header_control.dart`, `lib/pages/video/introduction/ugc/view.dart`, `lib/pages/video/introduction/pgc/view.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 23. 历史续播 + SponsorBlock 无痕抑制

  **What to do**:
  - 历史续播：`lib/pages/history/widgets/item.dart` 把进度传入 pgc/ugc 播放页（参照 A；`PageUtils.viewPgc`/`viewUgc` progress 参数——确认 B 的 page_utils 是否有 progress 参数，无则按需加）
  - SponsorBlock 无痕：`lib/pages/sponsor_block/block_mixin.dart` 恢复 `Pref.suppressSponsorBlockIncognito` 判定（无痕/游客不拉取、不上报）+ `_doVote` catchError（参照 A）

  **Must NOT do**:
  - 不删 B 的 `viewPgc`/`viewUgc` 现有调用方
  - 不改 `sponsor_block_api.dart`（SAME）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 3 (Tasks 18-23)
  - **Blocks**: 24,27
  - **Blocked By**: 7,8,10

  **References**:
  - A: `D:\coding\PiliPlusX\lib\pages\history\widgets\item.dart`（续播）
  - A: `D:\coding\PiliPlusX\lib\pages\sponsor_block\block_mixin.dart`（无痕）
  - B 现状: 对应文件
  - 对比报告 `03_utils_report.md`（viewPugv progress）、`08_live_search_report.md`（SponsorBlock 无痕）

  **Acceptance Criteria**:
  - [ ] history item 传 progress 到播放页
  - [ ] block_mixin 含 suppressSponsorBlockIncognito 判定 + catchError
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 续播接线
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'progress' lib/pages/history/widgets/item.dart → 命中
      2. grep 'progress' lib/utils/page_utils.dart（viewPgc/viewUgc 签名）→ 命中
    Expected Result: 续播参数传递
    Failure Indicators: 无 progress 参数
    Evidence: .sisyphus/evidence/task-23-resume.md

  Scenario: SponsorBlock 无痕
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'suppressSponsorBlockIncognito' lib/pages/sponsor_block/block_mixin.dart → 命中
      2. grep 'catchError' block_mixin → _doVote 命中
    Expected Result: 全部命中
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-23-sponsorblock.md
  ```

  **Commit**: YES
  - Message: `feat(history): resume progress; feat(sponsorblock): incognito suppression`
  - Files: `lib/pages/history/widgets/item.dart`, `lib/utils/page_utils.dart`, `lib/pages/sponsor_block/block_mixin.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

### Batch 4 — 页面/杂项（依赖 Batch 1-3；6 任务并行）

- [ ] 24. 动态/首页刷新 FAB + 剪贴板搜索

  **What to do**:
  - 动态页刷新 FAB：`lib/pages/dynamics/controller.dart` + `view.dart`（`Pref.showDynamicsRefreshFab` + 滚动方向显隐动画，参照 A `fab_mixin`）
  - 首页刷新 FAB：`lib/pages/home/controller.dart`（GetTickerProviderStateMixin + FAB 动画）+ `view.dart`（NotificationListener + FAB，`Pref.showHomeRefreshFab`）
  - 剪贴板搜索：`lib/pages/home/view.dart` 搜索栏 `Pref.showClipboardSearch` + 粘贴图标（参照 A；B 已删 Clipboard import）
  - 确认 B 的 storage_pref 已有这些 Pref 键（对比报告称残留）——直接激活消费

  **Must NOT do**:
  - 不删 B 的 home 页现有逻辑（native tabs、OS.isHarmony 守卫）
  - 不新增桌面分支

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 4 (Tasks 24-29)
  - **Blocks**: 30
  - **Blocked By**: 12,14,15,16,17,21,22,23

  **References**:
  - A: `D:\coding\PiliPlusX\lib\pages\dynamics\controller.dart`、`view.dart`、`lib\pages\common\fab_mixin.dart`
  - A: `D:\coding\PiliPlusX\lib\pages\home\controller.dart`、`view.dart`（FAB + 剪贴板搜索）
  - B 现状: 对应文件
  - 对比报告 `07_dynamics_report.md`（动态 FAB）、`06_player_report.md`（home 结构）

  **Acceptance Criteria**:
  - [ ] 动态 FAB + 首页 FAB 恢复（Pref 消费激活）
  - [ ] 剪贴板搜索恢复
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: FAB 恢复
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'showDynamicsRefreshFab' lib/pages/dynamics/ → 消费命中
      2. grep 'showHomeRefreshFab' lib/pages/home/ → 消费命中
    Expected Result: 全部命中
    Failure Indicators: Pref 死键
    Evidence: .sisyphus/evidence/task-24-fab.md

  Scenario: 剪贴板搜索
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'showClipboardSearch' lib/pages/home/view.dart → 消费命中
    Expected Result: 命中
    Failure Indicators: 死键
    Evidence: .sisyphus/evidence/task-24-clipboard.md
  ```

  **Commit**: YES
  - Message: `feat(home): refresh FABs and clipboard search`
  - Files: `lib/pages/dynamics/controller.dart`, `lib/pages/dynamics/view.dart`, `lib/pages/common/fab_mixin.dart`, `lib/pages/home/controller.dart`, `lib/pages/home/view.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 25. 播放器快捷操作（长按倍速/比例、fastForBackwardDuration_、HDR 提示）

  **What to do**:
  - 长按切换倍速（1.0x↔2.0x）与画面比例（contain↔cover）：`lib/plugin/pl_player/view/view.dart` speed/qa 控件的 GestureDetector（参照 A；B 已删 onLongPress/onSecondaryTap）
  - `fastForBackwardDuration_`：`lib/plugin/pl_player/controller.dart` 字段 + `lib/plugin/pl_player/view/view.dart` BackwardSeekIndicator 使用（参照 A；B 只用一个时长）
  - HDR/杜比视界 SDR 解析提示弹窗：`lib/plugin/pl_player/view/view.dart` qa 选择时（参照 A；B 已删）——OHOS 显示管线 HDR 支持需 Task 3 确认，不支持则保留提示逻辑（仅提示不崩溃）
  - **runtime-pending** 标记

  **Must NOT do**:
  - 不改 B 的 media_kit OHOS fork 接入
  - 不删 B 播放器现有适配

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 4 (Tasks 24-29)
  - **Blocks**: 30
  - **Blocked By**: 19,3

  **References**:
  - A: `D:\coding\PiliPlusX\lib\plugin\pl_player\view\view.dart`（长按/HDR/快退时长）
  - A: `D:\coding\PiliPlusX\lib\plugin\pl_player\controller.dart`（fastForBackwardDuration_）
  - B 现状: 对应文件
  - 对比报告 `06_player_report.md`（播放器快捷操作）

  **Acceptance Criteria**:
  - [ ] 长按切换倍速/比例恢复
  - [ ] fastForBackwardDuration_ 恢复（独立双时长）
  - [ ] HDR 提示弹窗恢复（不崩溃）
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 播放器快捷操作
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'onLongPress' lib/plugin/pl_player/view/view.dart → 倍速/比例命中
      2. grep 'fastForBackwardDuration_' lib/plugin/pl_player/controller.dart → 命中
      3. grep 'hdrVivid\|dolbyVision' view.dart → HDR 提示命中
    Expected Result: 全部命中
    Failure Indicators: 任一缺失
    Evidence: .sisyphus/evidence/task-25-player-shortcuts.md
  ```

  **Commit**: YES
  - Message: `feat(player): long-press toggles, dual seek durations, HDR dialog`
  - Files: `lib/plugin/pl_player/view/view.dart`, `lib/plugin/pl_player/controller.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 26. 下载按 UP 过滤 + 保存评论图原文

  **What to do**:
  - 下载搜索按 UP 主名过滤：`lib/pages/download/search/controller.dart`（参照 A；B 无 UP 过滤）
  - 保存评论图强制原文：`lib/pages/video/reply/` 相关（`forceShowOriginalContent` 与 Task 15 联动，确认已恢复则本任务只做下载关联部分）
  - 若 `forceShowOriginalContent` 已在 Task 15 完成，本任务仅剩下载过滤

  **Must NOT do**:
  - 不删 B 下载的多选分享（B 领先功能，勿动）
  - 不改 download_manager/download_service（SAME）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 4 (Tasks 24-29)
  - **Blocks**: 30
  - **Blocked By**: 12,15

  **References**:
  - A: `D:\coding\PiliPlusX\lib\pages\download\search\controller.dart`（UP 过滤）
  - B 现状: 对应文件
  - 对比报告 `08_live_search_report.md`（下载差异）

  **Acceptance Criteria**:
  - [ ] 下载搜索支持按 UP 主名过滤
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 下载 UP 过滤
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'upName\|up_name\|filterUp' lib/pages/download/search/controller.dart → 命中
    Expected Result: 命中
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-26-download.md
  ```

  **Commit**: YES
  - Message: `feat(download): filter by UP name`
  - Files: `lib/pages/download/search/controller.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 27. selectable_region_ext + insertOrAdd + viewPugv(progress:)（方案已按 Batch 0 更新）

  **What to do**:
  - **已更新（Batch 0 决策）**：不移植 A 原版 `selectable_region_ext.dart`——该扩展用 `(this as dynamic).selectable/.selectionDelegate` 访问私有字段，两 SDK 均无公共 getter，运行时必 NoSuchMethodError（A 自身也是坏的，B 维护者已在 d1916d920 删除）。改为 **B 原生 SelectableText 菜单**（EditableTextState.textEditingValue 公共可取选区）加「打开」按钮
  - **先决处理**：删除 3 个孤儿 part 文件（`context_menu/dyn_menu_helper.dart`、`reply_menu_helper.dart`、`live_menu_helper.dart`）——它们声明 `part of` 但宿主库无 `part` 声明，是死代码且造成 B HEAD 85 个 analyze 错误（T16 guardrail 已同步更新）
  - `lib/utils/extension/iterable_ext.dart`：恢复 `insertOrAdd`（参照 A；B 已删）
  - `lib/utils/page_utils.dart`：恢复 `viewPugv(progress:)` 课程续播参数（参照 A；B 已删 progress）
  - 检查 A 的 `selectable_region_ext` 调用点（reply/dyn/superchat 菜单）——按 Batch 0 结论在 B 对应页面用原生菜单实现「打开 URL」能力

  **Must NOT do**:
  - 不恢复 `text_selection.dart:2921,3044` 注释代码
  - 不删 B 的 `selectable_text.dart` 工具（B 独有，勿动）
  - 不移植 A 原版 `selectable_region_ext.dart`（运行时 NoSuchMethodError，Batch 0 实证）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 4 (Tasks 24-29)
  - **Blocks**: 30
  - **Blocked By**: 4,20,23

  **References**:
  - A: `D:\coding\PiliPlusX\lib\utils\extension\selectable_region_ext.dart`、`lib\utils\extension\iterable_ext.dart`、`lib\utils\page_utils.dart`
  - B 现状: 对应文件
  - Task 4 结论: `.sisyphus/evidence/batch0-smoke-plan.md`
  - 对比报告 `03_utils_report.md`（insertOrAdd/viewPugv）

  **Acceptance Criteria**:
  - [ ] selectable_region_ext 按 Task 4 结论落地（移植或替代）
  - [ ] insertOrAdd 恢复
  - [ ] viewPugv(progress:) 恢复
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 文本选择 + 工具恢复
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'insertOrAdd' lib/utils/extension/iterable_ext.dart → 命中
      2. grep 'progress' lib/utils/page_utils.dart（viewPugv 签名）→ 命中
      3. selectable_region_ext 结论落地（文件存在或替代方案接线）
    Expected Result: 全部命中
    Failure Indicators: 缺失
    Evidence: .sisyphus/evidence/task-27-selectable.md

  Scenario: text_selection 注释完好
    Tool: Bash
    Preconditions: 修改完成
    Steps:
      1. 确认 text_selection.dart:2921,3044 仍为注释状态（grep 注释标记）
    Expected Result: 注释完好
    Failure Indicators: 注释被恢复
    Evidence: .sisyphus/evidence/task-27-textselection.md
  ```

  **Commit**: YES
  - Message: `feat(utils): selectable region ext, insertOrAdd, viewPugv progress`
  - Files: `lib/utils/extension/selectable_region_ext.dart`, `lib/utils/extension/iterable_ext.dart`, `lib/utils/page_utils.dart`（及相关页面）
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 28. 设置项恢复（AI 组/评论 AI 翻译/申诉理由/图片路径/快速分享目标/HK URL）

  **What to do**:
  - 逐项恢复设置 UI 与消费点（参照 A `lib/pages/setting/`）：
    - AI 总结配置组（Task 13 联动）
    - 评论区 AI 翻译开关
    - 默认申诉理由（Task 15 联动）
    - 图片&截图保存路径
    - 快速分享目标（Task 22 联动）
    - 港澳台代理 URL（Task 11/12 联动）
  - 检查 B 的 storage_pref 是否已有这些 Pref 键（残留）——已有则只激活 UI 与消费；没有则按 A 新增
  - 账号选择器显示昵称（`accountUnameMap`，Task 10 联动）——若 A 的账号切换对话框有昵称展示则恢复

  **Must NOT do**:
  - 不删 B 的设置页拆分架构（7 分类页保留）
  - 不把 B 已改名的条目（屏蔽与过滤）改回 A 文案（保持 B 现状，除非用户明确要求）
  - 不动 `text_selection.dart`

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 4 (Tasks 24-29)
  - **Blocks**: 30
  - **Blocked By**: 11,12,13,15,22

  **References**:
  - A: `D:\coding\PiliPlusX\lib\pages\setting\`（完整设置组）
  - B 现状: `D:\coding\PiliPlusX_ohos\lib\pages\setting\`（7 分类页 + 残留 Pref）
  - 对比报告 `09_setting_report.md`（设置项差异）

  **Acceptance Criteria**:
  - [ ] 6 项设置全部恢复（UI 项存在 + Pref 消费点激活）
  - [ ] 账号选择器昵称恢复
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 设置项激活
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'aiSummaryBaseUrl\|aiSummaryApiKey' lib/pages/setting/ → AI 组命中
      2. grep 'defaultAppealReason' → 命中
      3. grep 'imageSavePath\|saveImagePath' → 命中
      4. grep 'quickShareId' → 命中
    Expected Result: 全部命中且非死键
    Failure Indicators: 任一设置仍死键
    Evidence: .sisyphus/evidence/task-28-settings.md
  ```

  **Commit**: YES
  - Message: `feat(settings): restore AI/translate/appeal/image/quick-share/HK settings`
  - Files: `lib/pages/setting/*`（相关文件）
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 29. 视频换源跳转 videoPush + 隐藏状态栏 + 账号昵称 + 无痕空降

  **What to do**:
  - 视频换源：恢复 `lib/http/video.dart` 中 -404 时的 `PiliScheme.videoPush` 换源跳转弹窗（参照 A；B 已删）
  - 隐藏状态栏：恢复 `Pref.hideStatusBar` 消费（全屏时状态栏显隐，参照 A `triggerFullScreen` 逻辑——Task 25 播放器一并处理或本任务补）
  - 账号昵称：`lib/pages/login/controller.dart` 登录成功 `Pref.setAccountUname`（Task 10 联动确认）+ 账号切换框昵称显示
  - 无痕空降：`Pref.incognitoMode` 下不发空降助手查询（参照 A）
  - 检查 `PiliScheme` 类在 B 的位置（`lib/utils/app_scheme.dart`——DIFF 文件，确认 videoPush 方法是否存在）

  **Must NOT do**:
  - 不删 B 的 app_scheme 现有方法
  - 不动 4 个「鸿蒙待适配」TODO

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 4 (Tasks 24-29)
  - **Blocks**: 30
  - **Blocked By**: 8,10,25

  **References**:
  - A: `D:\coding\PiliPlusX\lib\http\video.dart`（videoPush 弹窗）、`lib\utils\app_scheme.dart`
  - A: `D:\coding\PiliPlusX\lib\pages\login\controller.dart`（setAccountUname）
  - A: 无痕空降逻辑（`lib/pages/` 中空降助手调用点）
  - B 现状: 对应文件
  - 对比报告 `01_http_report.md`（换源）、`09_setting_report.md`（隐藏状态栏/昵称）

  **Acceptance Criteria**:
  - [ ] videoPush 换源弹窗恢复
  - [ ] hideStatusBar 消费恢复
  - [ ] setAccountUname 登录时调用
  - [ ] 无痕模式不发空降查询
  - [ ] `dart analyze --no-fatal-warnings` 0 error

  **QA Scenarios**:
  ```
  Scenario: 换源 + 杂项恢复
    Tool: Bash (grep)
    Preconditions: 修改完成
    Steps:
      1. grep 'videoPush' lib/http/video.dart → 命中
      2. grep 'hideStatusBar' lib/plugin/pl_player/view/ → 消费命中
      3. grep 'setAccountUname' lib/pages/login/controller.dart → 命中
      4. grep 'incognito' 空降助手调用点 → 命中
    Expected Result: 全部命中
    Failure Indicators: 任一缺失
    Evidence: .sisyphus/evidence/task-29-misc.md
  ```

  **Commit**: YES
  - Message: `feat(video): source-change redirect, status bar, nickname, incognito`
  - Files: `lib/http/video.dart`, `lib/utils/app_scheme.dart`, `lib/pages/login/controller.dart`, `lib/plugin/pl_player/view/view.dart`
  - Pre-commit: `dart analyze --no-fatal-warnings`

### Batch 5 — 验证收尾（依赖 Batch 4；4 任务并行）

- [ ] 30. 全量 dart analyze + flutter build hap

  **What to do**:
  - 运行 `dart analyze --no-fatal-warnings` 全项目，修复所有 error（warning 按项目现有标准容忍）
  - 尝试 `flutter build hap --release --dart-define-from-file=.vscode/env.json`（若 JDK 17 + HarmonyOS SDK 5.0.3 环境可用；B 的 CI 该步骤 continue-on-error，故尽力而为）
  - 输出编译/构建报告：`.sisyphus/evidence/batch5-build.md`

  **Must NOT do**:
  - 不修改受保护文件来"消除"错误（真 bug 必须修代码）
  - 不降低 analyze 阈值

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 5 (Tasks 30-33)
  - **Blocks**: F1-F4
  - **Blocked By**: 24-29

  **References**:
  - B 构建文档: `D:\coding\PiliPlusX_ohos\AGENTS.md`（COMMANDS 节）
  - B 构建模板: `ohos/关于build-profile.json5`（若缺 build-profile.json5 需先复制）

  **Acceptance Criteria**:
  - [ ] `dart analyze --no-fatal-warnings` 0 error
  - [ ] hap 构建成功或记录明确失败原因（环境缺失 vs 代码错误）
  - [ ] `batch5-build.md` 存在

  **QA Scenarios**:
  ```
  Scenario: analyze 零错误
    Tool: Bash
    Preconditions: 所有 Batch 1-4 完成
    Steps:
      1. 运行 dart analyze --no-fatal-warnings
      2. 断言 exit code 0 且无 error 行
    Expected Result: 0 error
    Failure Indicators: 任一 error
    Evidence: .sisyphus/evidence/task-30-analyze.md

  Scenario: hap 构建
    Tool: Bash
    Preconditions: 构建环境可用
    Steps:
      1. 运行 flutter build hap
      2. 记录 exit code + 产物路径（或环境缺失说明）
    Expected Result: 构建成功或环境原因记录
    Failure Indicators: 代码错误导致构建失败
    Evidence: .sisyphus/evidence/task-30-hap.md
  ```

  **Commit**: YES（修复 commit）
  - Message: `fix: resolve analyze/build errors after feature port`
  - Files: 修复涉及的 lib/**/*.dart
  - Pre-commit: `dart analyze --no-fatal-warnings`

- [ ] 31. 19 功能符号接线验证（grep/lsp）

  **What to do**:
  - 对 19 功能族逐一验证符号从 `lib/main.dart` 可达：
    1. AccountType.values.length==6、2. CustomHostInterceptor 在 init.dart 链中、3. hk_bangumi 枚举+pgc 消费、4. AiSummaryServiceRouter 被 ai_conclusion 消费、5. checkBlockReason 在 reply 消费、6. BlockedReplyBanner 在 reply_item 消费、7. translatedReplies 在 reply controller、8. appealComment 消费、9. canSort 消费、10. sessionDetail 消费、11. liveFeedback 消费、12. videoPush 消费、13. pmShare 消费、14. progress 续播传递、15. suppressSponsorBlockIncognito 消费、16. FAB Pref 消费、17. stein/showStein 播放器接线、18. fastForBackwardDuration_ 消费、19. imageBlock UI 消费
  - 输出符号接线报告：`.sisyphus/evidence/batch5-wiring.md`（每功能: 符号 + 证明）

  **Must NOT do**:
  - 不修改代码（纯验证）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 5 (Tasks 30-33)
  - **Blocks**: F1-F4
  - **Blocked By**: 24-29

  **References**:
  - 各任务的 grep 断言（task-5 至 task-29 的 evidence）
  - `C:\Users\dashan\AppData\Local\Temp\opencode\cmp_reports\FINAL_综合对比报告.md`（功能清单）

  **Acceptance Criteria**:
  - [ ] 19 功能族全部有符号 + 可达证明
  - [ ] `batch5-wiring.md` 存在
  - [ ] 无"已移植但未接线"的功能

  **QA Scenarios**:
  ```
  Scenario: 符号接线全量
    Tool: Bash (grep/lsp)
    Preconditions: 所有实现完成
    Steps:
      1. 逐功能 grep 符号 + 消费点
      2. 断言 19/19 接线
    Expected Result: 19/19
    Failure Indicators: 任一功能孤儿
    Evidence: .sisyphus/evidence/task-31-wiring.md
  ```

  **Commit**: NO

- [ ] 32. OHOS 保留 + 生成文件 + 依赖 override 完整性检查

  **What to do**:
  - ast_grep 断言：无 `SelectionText(` 恢复、无 `TargetPlatform.macOS/windows/linux` 新增分支、`text_selection.dart:2921,3044` 注释完好、`@Deprecated` defaultDecode/secondDecode 保留、4 个「鸿蒙待适配」TODO 未动
  - `git diff --name-only` 断言未触碰：`*.g.dart`、`GeneratedPluginRegistrant.ets`、`*.pb*.dart`、`lib/utils/android/bindings.g.dart`、`ohos/entry/build-profile.json5`、`ohos/build-profile.json5`
  - `git diff pubspec.yaml` 断言：~37 gitcode overrides 保留、无上游 media_kit/audio_service 等混入、无 SDK 约束提升
  - 输出检查报告：`.sisyphus/evidence/batch5-guardrails.md`

  **Must NOT do**:
  - 不修改代码（纯检查）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 5 (Tasks 30-33)
  - **Blocks**: F1-F4
  - **Blocked By**: 24-29

  **References**:
  - 本计划 Guardrails 节
  - `D:\coding\PiliPlusX_ohos\AGENTS.md`（禁止恢复项）

  **Acceptance Criteria**:
  - [ ] 全部 OHOS 保留断言通过
  - [ ] 受保护文件 0 触碰
  - [ ] pubspec overrides 完整
  - [ ] `batch5-guardrails.md` 存在

  **QA Scenarios**:
  ```
  Scenario: OHOS 保留
    Tool: ast_grep + git
    Preconditions: 所有实现完成
    Steps:
      1. ast_grep 'SelectionText(' → 0 命中（lib/ 移植文件）
      2. ast_grep 'TargetPlatform.macOS|windows|linux' 新增 → 0
      3. 检查 text_selection.dart 注释区域完好
      4. git diff --name-only 无受保护文件
      5. git diff pubspec.yaml 无上游依赖
    Expected Result: 全部通过
    Failure Indicators: 任一违反
    Evidence: .sisyphus/evidence/task-32-guardrails.md
  ```

  **Commit**: NO

- [ ] 33. 关键路径冒烟报告

  **What to do**:
  - 运行可执行断言（无设备）：
    - `dart test test/hive_migration_test.dart`（Task 6 迁移测试回归）
    - 临时脚本断言 AccountType 6 值 / wbi dm_img 字段生成 / grpc 头结构
    - `dart analyze` 零错误（Task 30 复核）
  - 汇总 runtime-pending 清单（Task 4 定义）：播放器/Stein/直播/下载/图片 pHash 等仅设备可验证项
  - 输出冒烟报告：`.sisyphus/evidence/batch5-smoke.md`（通过项 + runtime-pending 项）

  **Must NOT do**:
  - 不虚构设备验证结果（未验证就标 runtime-pending）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Batch 5 (Tasks 30-33)
  - **Blocks**: F1-F4
  - **Blocked By**: 24-29

  **References**:
  - `.sisyphus/evidence/batch0-smoke-plan.md`（Task 4）
  - `test/hive_migration_test.dart`（Task 6）

  **Acceptance Criteria**:
  - [ ] 迁移测试通过
  - [ ] 可执行断言全部通过
  - [ ] runtime-pending 清单明确
  - [ ] `batch5-smoke.md` 存在

  **QA Scenarios**:
  ```
  Scenario: 冒烟通过
    Tool: Bash
    Preconditions: 所有实现完成
    Steps:
      1. dart test test/hive_migration_test.dart → PASS
      2. 运行 AccountType/wbi/grpc 断言脚本 → PASS
      3. 核对 runtime-pending 清单与 batch0 定义一致
    Expected Result: 全部 PASS
    Failure Indicators: 任一失败
    Evidence: .sisyphus/evidence/task-33-smoke.md
  ```

  **Commit**: NO

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 个审查 agent 并行运行。全部 APPROVE 后向用户呈现汇总，**等用户明确确认**后才完成。
> 未获用户确认前，不得将 F1-F4 标记为完成。

- [ ] F1. **Plan Compliance Audit** — `oracle`
  逐任务核对：19 功能族的 "Must Have" 是否全部实现（读文件 + grep 符号）；"Must NOT Have"（Guardrails）是否全部遵守（ast_grep + git diff 搜索违禁模式）。检查 evidence 文件存在。
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  运行 `dart analyze --no-fatal-warnings` + 审查改动文件：无 `as any`/`@ts-ignore`（Dart 为 `dynamic`/`// ignore`）、无空 catch、无 release print、无注释代码恢复、无未用 import。检查 AI slop：过度注释、过度抽象、通用命名。
  Output: `Build [PASS/FAIL] | Lint [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  从干净状态执行可执行 QA 场景（迁移测试、analyze、符号接线、冒烟脚本）。逐任务执行 QA 场景并捕获证据。对 runtime-pending 项标注"待真机"。测试跨功能交互（账号切换→屏蔽→翻译链路）。
  Output: `Scenarios [N/N pass] | Integration [N/N] | Runtime-pending [N 项] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  逐任务读 "What to do" + 读实际 git diff。验证 1:1：规格内全部实现、规格外无新增（无桌面分支、无 log/catch 移植、无无关重构）。检查跨任务污染（Task N 碰 Task M 文件）。标记未记录的改动。
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| 批次 | Commit 数 | 说明 |
|---|---|---|
| Batch 0 | 0 | 侦察产物存 evidence，不提交 |
| Batch 1 | 7 (Task 5-11 各一) | 账号基础设施原子提交，每提交跑 analyze |
| Batch 2 | 6 (Task 12-17 各一) | 内容功能原子提交 |
| Batch 3 | 6 (Task 18-23 各一) | 交互功能原子提交 |
| Batch 4 | 6 (Task 24-29 各一) | 页面/杂项原子提交 |
| Batch 5 | 1+ (修复) | 验证后统一修复提交 |

提交前一律 `dart analyze --no-fatal-warnings`；不修改受保护文件；commit message 遵循 `feat(scope): desc` / `fix(scope): desc`。

---

## Success Criteria

### Verification Commands
```bash
dart analyze --no-fatal-warnings   # Expected: 0 error
dart test test/hive_migration_test.dart  # Expected: PASS（4→6 迁移无崩溃）
flutter build hap --release --dart-define-from-file=.vscode/env.json  # Expected: 构建成功（环境可用时）
```

### Final Checklist
- [ ] 19 功能族全部移植且符号接线（batch5-wiring.md 19/19）
- [ ] Hive 4→6 迁移测试通过
- [ ] OHOS 保留检查通过（无 SelectionText 恢复、无桌面分支、注释代码完好）
- [ ] 受保护文件 0 触碰（.g.dart/pb/registrant/bindings/build-profile）
- [ ] pubspec ~37 gitcode overrides 完整、无上游依赖混入
- [ ] `dart analyze` 0 error、hap 构建通过或环境原因明确记录
- [ ] runtime-pending 清单明确交付（播放器/Stein/直播/下载/图片 pHash 等）
- [ ] F1-F4 全部 APPROVE + 用户确认
