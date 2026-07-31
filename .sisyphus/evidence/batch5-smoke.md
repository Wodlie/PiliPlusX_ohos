# Batch 5 关键路径冒烟报告（Task 33）

> port-a-features Task 33 · 关键路径冒烟（无设备可执行断言 + runtime-pending 清单）· 2026-08-01
> 环境：Windows，Dart 3.12.2（本机非 OHOS SDK，`flutter test` 传递依赖图阻塞，见 §四）
> HEAD：`8723476f9 feat(batch4)`（T24-T29 已落地）

---

## 一、Hive 迁移验证（全计划最高优先级）→ 31/31 PASS

- T6 一次性验证 harness 仍存在于 `%LOCALAPPDATA%\Temp\opencode\hive_migration_verify`
  （真实复制 `account.dart`/`account_adapter.dart`/`account_migration.dart`/`app_device_profile.dart`/`identity_core/*`/`identity_persistence.dart`/`account_type*.dart`，仅 stub 5 个无关重依赖）。
- **本次重跑** `dart run bin/verify.dart` → **`ALL PASS (31 checks)`**，与 T6 evidence 逐字节一致：

| 组 | 断言内容 | 结果 |
|---|---|---|
| A1-A14 | 旧 4 字段记录解码（type 0-3 映射、field5 null、needsBuvidPersist=true）+ 迁移回填（field4==cookie buvid3 逐字节、field5=确定性默认档案） | 14/14 |
| B1-B2 | 迁移幂等（二次迁移 0 条） | 2/2 |
| C1-C2 | 空 box 返回 0、无副作用 | 2/2 |
| D1-D6 | 缺 buvid3 记录容错（现场生成、不崩溃、格式合法、档案回填） | 6/6 |
| E1-E5 | 重开值稳定、已 6 字段跳过、不覆盖已有 buvid、档案保留 | 5/5 |
| F1-F2 | 重开+再迁移 field4 仍为同一 cookie buvid3（跨启动值稳定） | 2/2 |

**结论**：T6 验收项在 T33 复核时仍全绿；4→6 迁移升级路径无回归。

## 二、可执行断言（无设备可跑）→ 全部 PASS

### 2.1 AccountType 6 值 → PASS（临时脚本执行，非仅 grep）

`lib/models/common/account_type.dart` 无任何 import（纯枚举），临时目录直接 `dart run` 断言：

```
length==6: true
reply=4 blacklist=5: true
all title+desc nonempty: true
existing 0-3 order preserved: true
ACCOUNT_TYPE_ASSERT: PASS
```

枚举顺序硬约束满足：`main/heartbeat/recommend/video`（index 0-3）原序不动，`reply=4`/`blacklist=5` 追加尾部（与 A 一致，Hive 按 index 序列化无错位）。

### 2.2 wbi 风控字段 → PASS（grep 实证，T8 产物）

`lib/utils/wbi_sign.dart`：
- `:66` `encWbi` 首行调用 `appendRiskFingerprintParams(params)`
- `:82-90` 定义：`dm_img_list='[]'`、`dm_img_str`（web GL 指纹）、`dm_cover_img_str`、`dm_img_inter={"ds":[],"wh":[0,0,0],"of":[0,0,0]}`，均 `??=` 不覆盖调用方自定义
- `getWbiKeys` else 分支 `.catchError`（debugPrint + return ''）容错

### 2.3 gRPC 头按账号快照 → 56/56 PASS（T9 harness 重跑）

- T9 一次性 harness（`%LOCALAPPDATA%\Temp\opencode\t9_harness`，真实复制 `grpc_headers.dart` + identity_core + app_device_profile + 5 个 metadata/device/fawkes pb）本次重跑：
  **`PASS: 56  FAIL: 0`**
- 覆盖：登录（mid=2101）`x-bili-mid=2101`/`x-bili-aurora-eid`/`authorization`/`user-agent=androidHd`/device.brand≠android 占位/fp 字段=derived/`currentImDeviceId()==derived.deviceId`；游客（`x-bili-mid=0`、无 aurora-eid）；兜底（`Pref.guestBuvid`）；fawkes getter 可解码。
- 结构 grep 佐证（`lib/utils/accounts/grpc_headers.dart`）：`:60 x-bili-mid`、`:90 x-bili-restriction-bin`、`:93 x-bili-ticket`、`:108 currentImDeviceId`、`:116 _resolveHeaderIdentity`、`:175-176` deviceProfile 按账号解析。
- 传输架构：`grpc_req.dart`/`http/init.dart` 0 变更（gRPC-over-HTTP + dio_http2_adapter 保留，T9 已确认）。

### 2.4 F17 回归（插叙）→ 24/24 PASS（T27 evidence 记录）

`flutter test test/utils/extension_test.dart` 在 T27 已跑 **24/24 PASS**（含 4 个 insertOrAdd 断言）。本任务不重跑（避免 pubspec.lock 镜像重写往返），直接引用 task-27 evidence §5.2。

## 三、analyze 复核 → 23 errors = 基线

`dart analyze --no-fatal-warnings` 本次实测 **23 errors / 0 warnings（error 级）**，与 T24/T27 基线一致：

| 分组 | 数量 | 文件 |
|---|---|---|
| vendored OHOS 引擎 | 6 | `editable_text.dart`（ExtendSelectionByPageIntent ×3）、`vertical_slider.dart`（TargetPlatform.ohos ×3） |
| test/ RED | 17 | `android_helper_test` 6、`connectivity_utils_test` 7、`platform_utils_test` 4 |
| **合计** | **23** | 全为已知基线，无移植新增 |

> 注：`--no-fatal-warnings` 下总 issues 数 271 含 info/warning；错误级 23 达标。warnings 全部为 pre-existing（vendored 引擎、孤儿 import、A verbatim 同款），无本批次引入。

## 四、验证口径说明

- 本机 Flutter 3.44.4 无法编译 B 的传递依赖图（T6 实证：vendored 3.32.4-ohos 补丁 `ExtendSelectionByPageIntent`、font_awesome 10.9 的 IconData final class、git fork 的 `ohos` 平台成员），`flutter test` 需 OHOS 3.41.9（CI）。
- 故本报告的运行级验证 = 纯 Dart harness（Hive 31/31、gRPC 56/56、AccountType 断言）+ `dart analyze` 23 基线；UI/网络交互如实标记 runtime-pending，不虚构设备结果。

## 五、runtime-pending 清单（仅设备可验证，未验证不虚标）

> 逐项按 batch0-smoke-plan §三 定义 + 各任务 evidence 的 runtime 备注汇总。验收口径：编译 + analyze + 符号接线 + 逻辑测试为通过线。

| # | 功能族 | 待验证项 | 依据 |
|---|---|---|---|
| 1 | **播放器**（F15/F13/F18） | 长按倍速/画面比例切换、右键切换、HDR/杜比选择弹窗、快退双时长、进度续播跳转、状态栏显隐、-404 换源弹窗（videoPush） | task-25 §Runtime-pending、task-29 §runtime-pending、batch0-smoke-plan §三.1 |
| 2 | **Stein 互动视频**（F8） | 进度恢复对话框、回溯面板、interactiveChild——需真机播放互动视频（rights.isSteinGate） | task-18/task-19、batch0-smoke-plan §三.2 |
| 3 | **直播**（F11） | liveFeedback 提交、直播卡片反馈按钮 | task-21、batch0-smoke-plan §三.3 |
| 4 | **下载**（F16） | 下载搜索按 UP 过滤的实际下载流程 | task-26、batch0-smoke-plan §三.4 |
| 5 | **图片 pHash 屏蔽 UX**（F9/F20） | 屏蔽评估/长按查看/举报联动屏蔽 UI（pHash 算法已被测试覆盖） | task-20、batch0-smoke-plan §三.5 |
| 6 | 快速分享 pmShare（F12） | 长按分享 → 私信目标选择流程 | task-22、batch0-smoke-plan §三.6 |
| 7 | 评论翻译横幅/申诉、长按拉黑/分享、BlockedReplyBanner（F5/F6/F7） | 网络调用 + 横幅/菜单交互 | batch0-smoke-plan §三.7 |
| 8 | 港澳台番剧、自定义 API Host/港澳台代理（F3/F2） | 真实网络 + 代理连通 | batch0-smoke-plan §三.8 |
| 9 | AI 总结（F4） | 真实 AI 服务调用（router 路由与失败态可被测试覆盖） | batch0-smoke-plan §三.9 |
| 10 | 剪贴板搜索、动态/首页 FAB 动画（F14） | 剪贴板读取 + 滚动手势动画 | task-24 §Runtime-Pending |
| 11 | 历史续播跳转、SponsorBlock 无痕抑制（F13） | 播放页跳转 + 无痕/游客网络抑制 | batch0-smoke-plan §三.11 |
| 12 | 账号登录/切换/登出、BUVID 激活重试（F1） | 网络 + 身份状态机 | batch0-smoke-plan §三.12 |
| 13 | 「打开」菜单按钮（F17） | 长按选中文本 → 菜单「打开」→ 外部分流；pugv 课程按进度续播 | task-27 §6 |
| 14 | 设置交互（F19） | 快速分享 mid 输入、AI 总结超时校验、图片保存路径选择、账号昵称显示 | task-28 §待真机验证 |
| 15 | 无痕空降（F18/T29） | 登录+无痕+开关开启时验证不查 SponsorBlock 服务器 | task-29 §runtime-pending |

**合计 15 项 runtime-pending**（对应 batch0-smoke-plan §三 12 项 + F17/F19/T29 细分补充）。

## 六、结论

- ✅ Hive 4→6 迁移：**31/31 PASS**（重跑确认，全计划最高优先级验收项通过）
- ✅ AccountType 6 值 / wbi dm_img 风控 / gRPC 头按账号快照：**全部断言通过**
- ✅ `dart analyze --no-fatal-warnings`：**23 errors**（= 基线，无移植新增）
- ✅ 符号接线（T24-T29 各 task evidence 已逐项 grep/lsp 证明）
- ⏳ **15 项 runtime-pending**：仅设备可验证，按清单如实标注，不虚构
- 依赖：Blocked By T24-T29（均完成）｜ Blocks F1-F4（Final 审查波次）
