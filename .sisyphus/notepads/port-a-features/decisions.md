# decisions.md

## [2026-07-31] Task: T1 — 残留复用决策（写入 batch0-triage.md 第三部分）

1. **block_filter_settings.dart（模型）**: reuse-as-is —— 列表与 A 逐项一致（仅路由名 `/atFilter` 不同，B 已自洽注册），逻辑由 T14 补，不 replace。
2. **ai_summary_service.dart**: reuse-as-is —— A/B 字节相同（SHA 一致），T13 只补 router+adapters。
3. **api_host_page（B 版）**: reuse-as-is —— B 版内嵌开关+重置优于 A 版，T11 只加入口+拦截器，不复制 A 版。
4. **7 个设置页壳（B 独有）**: reuse-as-is —— B 架构保留；A 设置项增强落 models/*.dart。
5. **draggable_sheet / layout_builder / sliver_layout_builder（vendored）**: 保留不动 —— 零引用但属引擎补丁基础设施，删除有编译回退风险。
6. **msg_type.dart / reply_type.dart**: replace（收尾清理）—— 全注释死代码，零引用，无 A 对照，但移植期间不动。
7. **执行基调**: "只加不改" —— 所有 a+b 混存文件以 B 现状为基底，按 A 补缺失符号，保留 B 的 OHOS 分支（OS.isHarmony/connectivity 单值/SelectableText/media_kit fork API）。



## [2026-07-31] Orchestrator 决策（Batch 0 验证后）
- **T16 guardrail 更新**：3 个孤儿 part 文件（dyn_menu_helper/reply_menu_helper/live_menu_helper）是死代码且造成 B HEAD 85 个 analyze 错误——允许删除（原'不动 reply_menu_helper.dart'假设错误）。
- **T27 方案更新**：不移植 A 原版 selectable_region_ext.dart（运行时 NoSuchMethodError，A 自身也是坏的）；改 B 原生 SelectableText 菜单加'打开'按钮。
- **T6 迁移方案确认**：方案 A（cookie buvid3 seed）保持线上 buvid 头不漂移，推荐采用；幂等 migrateAccountBoxV4ToV6 + Accounts.refresh() 自愈双保险。
- **T18/19/25 硬约束**：graft 到 B 现有 pl_player，严禁复制 A 的 _initPlayer/_createVideoController/SimpleVideo 段落（fork API 不存在）。
- **B HEAD 基线 276 errors**：85 孤儿 part + ~191 test/ 引用未移植符号——test/ 是 RED 验收契约（移植后转绿），非阻塞；但 analyze gate 需以'非孤儿 part、非 test/'为基准。

