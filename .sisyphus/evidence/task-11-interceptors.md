# Task 11 — CustomHostInterceptor + HkApiRetryInterceptor + api_host_page 入口

**Date:** 2026-07-31
**Branch:** master (B = D:\coding\PiliPlusX_ohos)

## 交付物

1. **`lib/http/custom_host_interceptor.dart`（新建）** — 参照 A 重写（剔除 A 的 Investigation Findings 长注释，保留核心逻辑）：master toggle `Pref.enableCustomApiHost` → HK 代理优先跳过 GET → 按 `apiHostEntries` 构建 hostMap → 全 URL/baseUrl 重写。B 的 `api_hosts.dart` 与 A 逐字节同构，直接消费。
2. **`lib/http/hk_api_retry_interceptor.dart`（新建）** — 参照 A 重写：GET + `Pref.apiHKUrl` 非空 + code -404/-10403 → 构造新 URL 走 `Request.dio.request` 重试，失败 `SmartDialog.showToast`。
3. **`lib/http/init.dart` 接入** — 保留 B 全部现有拦截器（RetryInterceptor/AccountManager），在 RetryInterceptor 与 LogInterceptor 之间插入 CustomHost → HkApi 两枚。最终顺序：Retry → CustomHost → HkApi → Log，与 test/http/init_test.dart 断言完全一致。UA、connectivity 5.x 单值、`_cloneHttp11Dio`、`OS.isHarmony` 分支均未动。
4. **api_host_page 入口恢复** — B 的 `/apiHostSetting` 路由（app_pages.dart:148）原为死路由（无 toNamed）。在 `lib/pages/setting/models/extra_settings.dart` 末尾（检查更新之后）新增：
   - `设置港澳台代理` NormalModel（A 版 verbatim，dialog 写 `SettingBoxKey.apiHKUrl`）
   - `自定义 API 主机` NormalModel（`Get.toNamed('/apiHostSetting')` → B 版 ApiHostPage，内嵌开关+重置，**未复制 A 版页面**，符合 T1 决策 3）
5. **gRPC `customAppBaseUrl`** — `lib/grpc/grpc_req.dart` 与 A 逐字节同构补上：`(Pref.enableCustomApiHost && Pref.customAppBaseUrl.isNotEmpty) ? Pref.customAppBaseUrl : HttpString.appBaseUrl`，B 架构完全支持，无传输层重构。

## 验证证据

### dart analyze（基线 181 errors / 37 warnings）

```
ERRORS:   163   （181 → 163，−18，恰为 test/http/init_test.dart 的 18 个 CustomHost/HkApi 未定义 RED 错误）
WARNINGS:  37   （与 T10 基线逐项一致，全部 pre-existing）
INFO:     196   （含 2 条新 info：hk_api_retry_interceptor.dart avoid_void_async:9 + unnecessary_await_in_return:71，
                 系 A 原实现 dio onResponse async 模式的固有 lint，与 A 相同；非 error/warning，不阻塞 gate）
```

- `dart analyze` 在 `init_test / custom_host_interceptor / hk_api_retry_interceptor / grpc_req / extra_settings` 上 **0 error**（`Select-String " error "` 空）。
- 改动文件 0 warning；其余 37 warnings 均为 B 已知基线（vendored 引擎 unreachable_switch/undefined_hidden_name、孤儿 part unused_import、dynamics_mention/live_room/member_profile 既有项）。

### RED → GREEN

test/http/init_test.dart 18 错误（CustomHostInterceptor/HkApiRetryInterceptor 未定义）全部转绿（文件 0 error）。链序断言 Retry < CustomHost < HkApi < Log 与 init.dart 实际注册顺序一致；AccountManager/ConnectivityUtils/RetryInterceptor 引用符号均存在。

### 拦截器接入确认（init.dart）

```
dio.interceptors 顺序（_internal 注册）：
  0. RetryInterceptor        （Pref.retryCount != 0 时）
  1. CustomHostInterceptor   ← 新增（A 位置）
  2. HkApiRetryInterceptor   ← 新增（A 位置）
  3. LogInterceptor          （kDebugMode）
  4. AccountManager          （setCookie 时追加，未动）
```

### 入口可达性

- `/apiHostSetting` 路由：app_pages.dart:148 已注册 → `ApiHostPage()`（B 版，内嵌 enableCustomApiHost 开关 + 每子域重置按钮）。
- 新入口：设置 → 其它设置 → `自定义 API 主机`（`Get.toNamed('/apiHostSetting')`）+ `设置港澳台代理`。
- 港澳台代理默认关闭：`Pref.apiHKUrl` 默认空字符串，未设默认开启。

## 合规检查（MUST NOT DO）

- ✅ 未编辑 `*.g.dart` / `*.pb*.dart`
- ✅ 未删 B 现有拦截器（retry_interceptor、AccountManager）
- ✅ 保留 B 的 connectivity 单值、UA 'Dart/3.6 (dart:io)'、`OS.isHarmony` 分支、`_cloneHttp11Dio`
- ✅ 未复制 A 版 api_host_page（复用 B 版，只补入口）
- ✅ 港澳台代理默认关闭
- ✅ 未新增网络依赖、未新增桌面分支
