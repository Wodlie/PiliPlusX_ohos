# Batch 0 Triage Report — 337 DIFF 三分类 + 27 ONLY_A + 死代码残留审计

> **生成时间**: 2026-07-31
> **任务**: port-a-features 计划 Batch 0 Task 1（只读侦察，不修改任何代码）
> **方法**: 复用 15 份对比报告（`C:\Users\dashan\AppData\Local\Temp\opencode\cmp_reports\`）逐文件分类结论 + 两仓库 git log 交叉验证 + 全量 SHA-256 权威清单（`authoritative_lib.txt`）核对
> **权威清单**: 337 DIFF / 27 ONLY_A / 163 ONLY_B / 991 SAME（TOTAL 1518）
> **注**: txt 快照（328 DIFF / 18 ONLY_A）遗漏 9 个 DIFF + 9 个 ONLY_A（均在 `lib/pages/common/`、`lib/pages/mine/`、`lib/scripts/`、`lib/tcp/`、`lib/pages/AGENTS.md`），本报告以全量重算为准。
> **分类约定**：
> - **(a) A 功能** = 仅 A 存在/领先、B 缺失，需按 A 参照移植
> - **(b) B 的 OHOS 适配** = B 为鸿蒙平台/依赖 fork 做的改动，移植时必须保留
> - **(c) 双方漂移** = 同步漂移/重构/风格/死代码，无功能移植需求（或仅需最小对齐）
> - 混合 = 主类+次类（如 `a+b` 表示同文件 A 功能与 B 适配并存，移植时须分区处理）

---

## 一、337 DIFF 三分类汇总

### 1.1 lib/grpc + lib/http（19 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/grpc/bilibili/main/community/reply/v1.pb.dart | c | B 重新生成（TranslationSwitch 枚举、field 17、TranslateReplyReq/Resp 内联）；A 手改 pb + 独立 reply_translate.dart。wire 一致，**禁止手改 *.pb*.dart**（01 报告 §11） |
| lib/grpc/bilibili/main/community/reply/v1.pbjson.dart | c | 与 pb 对应；B 完整、A 缺 JSON 条目，二进制传输无线上差异（01 报告 §11） |
| lib/grpc/grpc_req.dart | a | A 的 baseUrl 支持 `Pref.customAppBaseUrl`（自定义 API Host gRPC 支持）；B 固定 appBaseUrl（01 报告）→ 归 Task 11 |
| lib/grpc/im.dart | a+b | a: 删除 `sessionDetail()` 方法（Task 17 恢复）；b: `devId` 从持久化 → 随机 UUID / `'1'` 硬编码（B 适配，保留） |
| lib/grpc/reply.dart | a | A 完整 5 策略屏蔽体系（checkBlockReason/横幅/@过滤/等级/黑名单）+ 批量 translateReply；B 仅关键词+带货静默删除（01 报告 §评论屏蔽）→ Task 14/15 |
| lib/grpc/url.dart | a | 仅删 `sessionDetail` 常量，配合 im.dart 恢复 → Task 17 |
| lib/http/api.dart | a+c | a: `replyAppealSubmit`+`liveFeedback` 常量被删（Task 15/21）；c: `latestApp` 仓库地址漂移、replyReport 重排（无功能影响） |
| lib/http/black.dart | a | A 用 `Accounts.blacklist`（多账号黑名单独立账号）；B 统一 `Accounts.main` → Task 5/7/16 |
| lib/http/dynamics.dart | c | 4 处 identity 调用替换为等价硬编码 query 参数（值一致） |
| lib/http/follow.dart | c | sortFollowTag identity 硬编码，值一致 |
| lib/http/init.dart | a+b | a: `CustomHostInterceptor`+`HkApiRetryInterceptor` 注册删除（Task 11）、buvidActive 重试语义（Task 10）、setCookie 不 await；b: connectivity_plus 5.x 单值回调、UA `grpc-go→Dart/3.6`（保留） |
| lib/http/live.dart | a+b | a: `liveFeedback` 删除（Task 21）；b: app 端头硬编码（fp/session 占位）、`_appProfile` 内联（数值与 A 一致） |
| lib/http/login.dart | a+b | a: RequestIdentityAdapter 登录身份层删除（Task 8）；b: 硬编码 `device_name: 'vivo'`/`local_id: '0'`/genDeviceId（B 适配，保留） |
| lib/http/member.dart | c | identity webDmImageQueryFields 改随机 dm 字段（B 重构，长度分布不同但签名可用） |
| lib/http/pgc.dart | a | `pgcIndex`/`pgcTimeline` 去掉 `apiUrl` 参数（港澳台代理删除的连锁）→ Task 12 |
| lib/http/reply.dart | a | `appealComment()` + `Accounts.reply` 删除 → Task 15 |
| lib/http/search.dart | a+c | a: `media_hk_bangumi` 分支删除（Task 12）；c: gaia 风控字段内联（行为等价） |
| lib/http/user.dart | c | followedUp/sameFollowing identity 硬编码，值一致 |
| lib/http/video.dart | a+b | a: videoPush 换源弹窗、ugcSummaryMp4Url、transcriptSubtitles、Accounts.reply（Task 13/22/26/29）；b: recommendApp 头硬编码占位、relationMod fp=BrowserUa.pc（B 疑似 bug，保留但记录） |

### 1.2 lib/utils/accounts + 相关（16 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/utils/accounts.dart | a | A 生命周期状态机（_AccountLifecycleState/canonicalize/identity 快照/reply+blacklist getter/BUVID 回写）；B 数组槽位 → Task 7 |
| lib/utils/accounts/account.dart | a | A 持久化 buvid(Hive4)/deviceProfile(Hive5)+三级身份解析+onChange 回写；B cookie 现场推导。B 保留旧 fawkes hack → Task 6/7/10 |
| lib/utils/accounts/account_adapter.dart | a | A 6 字段 / B 4 字段（Hive 读写）→ Task 6 |
| lib/utils/accounts/account_manager/account_mgr.dart | a+b | a: _resolveAccountSelection/canonicalize；b: `OS.isHarmony` 跳过 connectivity（TODO 鸿蒙待适配）+ connectivity 5.x `.desc` 单值（保留）→ Task 7 |
| lib/utils/accounts/api_type.dart | a | A 新增 reply/blacklist 路由表 + recommend 补 liveFeedback → Task 5 |
| lib/utils/accounts/app_device_profile.dart | c | 内容逐字节相同（仅 CRLF）；**但 B 中零引用 + adapter 未注册**（B 侧死代码，A 侧活）→ Task 6 需注册 adapter |
| lib/utils/accounts/grpc_headers.dart | a | A 按账号快照构建头（真实 device/fp/guestId/x-bili-mid/eid/restriction/ticket）；B 全静态占位 → Task 9 |
| lib/utils/accounts/identity_core.dart | c | 内容一致仅行尾差异（CRLF/LF） |
| lib/utils/accounts/identity_core/identity_contracts.dart | c | 接口逐字节一致，仅 import 风格差异 |
| lib/utils/accounts/identity_core/identity_generators.dart | c | 算法逐字节一致，仅 import 风格差异 |
| lib/utils/accounts/identity_core/identity_profile.dart | c | 内容一致，仅 import 风格差异 |
| lib/utils/accounts/identity_core/identity_snapshot.dart | c | 内容一致，仅 import 风格差异 |
| lib/utils/accounts/identity_persistence.dart | c | 逻辑逐字节一致，仅注释差异 |
| lib/utils/login_utils.dart | a | A 增加 setAccountUname 调用（多账号昵称缓存）+ buvid→Pref.guestBuvid 语义 + generateBuvid 确定性；B 保留 genDeviceId（**保留**，http/login 使用）→ Task 8/10 |
| lib/utils/request_utils.dart | a+b | a: pmShare（快速分享，Task 22）；b: SelectionText→SelectableText（OHOS 适配，保留） |
| lib/utils/wbi_sign.dart | a | A 追加 appendRiskFingerprintParams（dm_img_* 风控字段）+ getWbiKeys catchError → Task 8 |

### 1.3 lib/utils（30 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/utils/android/android_helper.dart | b | B 纯空壳替身（PiP/反诈/快捷方式空实现），A jni 实现 → 保留 B |
| lib/utils/android/bindings.g.dart | b | B 手写 43 行 OHOS stub（AGENTS 禁编辑）→ 保留 B |
| lib/utils/app_scheme.dart | c | `Future.syncValue`→`Future.value`（兼容改写） |
| lib/utils/bili_utils.dart | c | 内容一致仅行尾 |
| lib/utils/blocked_image_storage.dart | c | 内容一致仅行尾 |
| lib/utils/cache_manager.dart | b | cached_network_image_ce 无 fork API → 重写（保留 B + cache_manager_ext 配合） |
| lib/utils/connectivity_utils.dart | b | connectivity_plus 5.x 单值比较 |
| lib/utils/extension/dimension_ext.dart | c | 内容一致仅行尾 |
| lib/utils/extension/iterable_ext.dart | a | 缺 `ListExt.insertOrAdd`（selectable_region_ext 传递依赖）→ Task 27 |
| lib/utils/extension/nested_scroll_ext.dart | c | 内容一致仅行尾 |
| lib/utils/extension/scroll_controller_ext.dart | c | animTo 默认 500ms→800ms + easeOutCirc（漂移，无移植需求） |
| lib/utils/extension/theme_ext.dart | c | 枚举显式全名（等价） |
| lib/utils/id_utils.dart | b | genBuvid3/genTraceId 本地重写（因无 identity_core），上游算法一致 |
| lib/utils/image_block_service.dart | b | getSingleFile→Request.dio 下载（B 适配，行为略异但可用） |
| lib/utils/image_utils.dart | b+c | b: file_picker_ohos/share_plus 10/saveByteImg OS.isHarmony + thumbnailUrlWithSize（B 独有）；c: SaverGallery 参数漂移 |
| lib/utils/json_file_handler.dart | c | catcher_2 版本 API 漂移 |
| lib/utils/page_utils.dart | a+b | a: viewPugv 删 `progress` 参数（课程续播，Task 27/23）；b: enterPip 改 floating 插件方案（保留） |
| lib/utils/path_utils.dart | c | 删除 @visibleForTesting 测试钩子 |
| lib/utils/platform_shortcuts.dart | b | OS.isHarmony Ctrl 修饰键分支 |
| lib/utils/platform_utils.dart | b | os_type 包替代 dart:io Platform；删 isDarwin |
| lib/utils/reply_utils.dart | a+b | a: A 完整 8 状态机 + 站内申诉 showAppealDialog（Task 15）；b: B webview 申诉方案（保留，若按 A 移植则替换为站内） |
| lib/utils/share_utils.dart | b | share_plus 10.x API（鸿蒙 fork 停留版本） |
| lib/utils/storage.dart | a | B 移除 AppDeviceProfileAdapter 注册（A 有）→ Task 6 |
| lib/utils/storage_key.dart | b+c | b: OHOS-specific keys（enableHdsBar/enableLGBar 等 5 个）+ @Deprecated defaultDecode/secondDecode（AGENTS 禁删）；c: 其余一致 |
| lib/utils/storage_pref.dart | b+c+a | b: OHOS 默认值（preInitPlayer=OS.isHarmony/autoPlayEnable=false 等）；c: springDescription 等漂移；a: A guestBuvid 内存缓存（B 无缓存，非必须） |
| lib/utils/storage_utils.dart | b | FilePicker.platform.saveFile（file_picker_ohos） |
| lib/utils/subtitle_utils.dart | c | 枚举分号格式 |
| lib/utils/theme_utils.dart | b | 系统字重映射 + 强制 HarmonyOS_Sans + 删 useSystemFont 消费 |
| lib/utils/update.dart | b | commitHash 级版本比对 + qinshah/PiliPlus ohos 分支（B 独有增强，保留） |
| lib/utils/utils.dart | b | MethodChannel 保留；删 _secureRandom/generateSecureRandomBytes/copyJson/levelName/parseColor（A 侧 identity 需要 generateSecureRandom* 时须补回） |

### 1.4 lib/common（47 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/common/constants.dart | a+b | a: traceId getter 动态生成（identity_core）；b: appName/sourceCodeUrl 品牌差异（保留 B） |
| lib/common/skeleton/dynamic_card.dart | c | 点简写 vs 全名（等价） |
| lib/common/skeleton/msg_feed_top.dart | c | Align vs UnconstrainedBox（上游漂移，等价） |
| lib/common/skeleton/whisper_item.dart | c | 同上 |
| lib/common/style.dart | c | A 多 `placeHolder='\uFFFC'` 常量（富文本光标占位，B 用局部 const 替代） |
| lib/common/widgets/animated_height.dart | c | 构造器写法 |
| lib/common/widgets/animated_multi_height.dart | c | 构造器写法 |
| lib/common/widgets/avatars.dart | c | 点简写 |
| lib/common/widgets/cropped_image.dart | c | 构造器写法 |
| lib/common/widgets/custom_arc.dart | c | 构造器写法 |
| lib/common/widgets/custom_height_widget.dart | c | 构造器写法 |
| lib/common/widgets/custom_tooltip.dart | c | 构造器写法 |
| lib/common/widgets/dialog/export_import.dart | b | file_picker→file_picker_ohos |
| lib/common/widgets/dialog/report.dart | a | A 多 `onBlockImages`（举报联动屏蔽图片）→ Task 20 |
| lib/common/widgets/dialog/report_member.dart | c | 点简写 |
| lib/common/widgets/disabled_icon.dart | c | 构造器写法 |
| lib/common/widgets/draggable_sheet/topic.dart | c | 构造器写法 |
| lib/common/widgets/extra_hittest_stack.dart | c | 逐字节一致（清单 DIFF 误报） |
| lib/common/widgets/fractionally_sized_box.dart | c | 构造器写法 |
| lib/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart | b | _calcAngle 放宽 dx>3dy→dx>dy（B 注释明确 OHOS 定制） |
| lib/common/widgets/gesture/mouse_interactive_viewer.dart | b+c | b: touchSlop ohos=1；c: A 侧滚轮平移守卫 |
| lib/common/widgets/image/blocked_image_placeholder.dart | a | A 新版参数化（长按查看/屏蔽）→ Task 20 |
| lib/common/widgets/image/cached_network_svg_image.dart | b+c | b: cache_manager_ext.getSingleFile；c: 构造器写法 |
| lib/common/widgets/image/image_save.dart | a+b | a: autoAddToWatchLater（Task 28）；b: HarmonyChannel 隐藏系统栏 + SelectableText |
| lib/common/widgets/image/network_img_layer.dart | b+c | b: thumbnailUrlWithSize + Duration.zero；c: errorWidget→errorBuilder（cached_network_image 版本） |
| lib/common/widgets/image_grid/image_grid_builder.dart | c | 构造器写法 |
| lib/common/widgets/image_grid/image_grid_view.dart | a | A StatefulWidget 完整图片屏蔽 UI（pHash/tempUnblockedUrls/VisibilityDetector）→ Task 20 |
| lib/common/widgets/image_viewer/gallery_viewer.dart | a+b | a: 屏蔽图片菜单（Task 20）；b: media_kit 旧构造 API（保留 B） |
| lib/common/widgets/image_viewer/loading_indicator.dart | c | 构造器写法 |
| lib/common/widgets/loading_widget/http_error.dart | b | SelectableText + NeverScrollableScrollPhysics |
| lib/common/widgets/loading_widget/m3e_loading_indicator.dart | c | 构造器写法 |
| lib/common/widgets/marquee.dart | c | 构造器写法 |
| lib/common/widgets/pendant_avatar.dart | c | 点简写 |
| lib/common/widgets/progress_bar/audio_video_progress_bar.dart | c | 构造器写法 |
| lib/common/widgets/progress_bar/segment_progress_bar.dart | c | A 侧残留未用 fontFamily 死变量（不移植） |
| lib/common/widgets/progress_bar/video_progress_indicator.dart | c | 构造器写法 |
| lib/common/widgets/scale_app.dart | b | scaleFactorNotifier（鸿蒙缩放重建机制） |
| lib/common/widgets/scroll_behavior.dart | c | A 无参构造+Android overscroll；B 带参构造（漂移，B 保持） |
| lib/common/widgets/scroll_physics.dart | c | A Darwin 桌面弹跳物理（**桌面端专属，计划排除**）；B static final |
| lib/common/widgets/sliver/sliver_floating_header.dart | c | 构造器写法 |
| lib/common/widgets/sliver/sliver_pinned_dynamic_header.dart | c | 构造器写法 |
| lib/common/widgets/sliver/sliver_pinned_header.dart | c | 构造器写法 |
| lib/common/widgets/sliver_wrap.dart | c | 构造器写法 |
| lib/common/widgets/translucent_column.dart | c | B 领先：B 实现 updateRenderObject，A 缺失（保留 B） |
| lib/common/widgets/video_card/video_card_h.dart | b | _CoverBuilderH 封面缓存（OHOS 性能） |
| lib/common/widgets/video_card/video_card_v.dart | b+c | b: _CachedLayoutBuilder 缓存；c: emote→BorderRadius.zero 修复（B 领先） |
| lib/common/widgets/video_popup_menu.dart | a | A Accounts.main.isLogin 守卫 + Accounts.get(.recommend) 差异化提示 → Task 5/7 |

### 1.5 lib/common/widgets/flutter（14 文件，全部 B OHOS 引擎 vendored 区）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/common/widgets/flutter/chat_list_view.dart | c | cacheExtent vs scrollCacheExtent（3.41 vs 3.32） |
| lib/common/widgets/flutter/page/page_view.dart | c | ScrollCacheExtent/cacheExtent + onPageChanged 触发时机（ScrollEnd/ScrollUpdate，真实行为差异但为引擎版本所致） |
| lib/common/widgets/flutter/popup_menu.dart | c | 点简写 |
| lib/common/widgets/flutter/refresh_indicator.dart | b+c | b: 引入 fork 包 RefreshScrollPhysics；c: SizeTransition alignment 版本漂移 |
| lib/common/widgets/flutter/text/paragraph.dart | b | `set text`→`set setText`（OHOS 引擎 API 冲突改名） |
| lib/common/widgets/flutter/text/rich_text.dart | b | 配套 setText 改名 |
| lib/common/widgets/flutter/text_field/controller.dart | b+c | b: 插入后强制 newSelection 光标定位；c: 私有命名参数写法 |
| lib/common/widgets/flutter/text_field/cupertino/text_field.dart | b | default: 兜底 ohos 移动端行为 |
| lib/common/widgets/flutter/text_field/editable.dart | b | caret 高度/词选 macOS 移桌面组、ohos 落居中组 |
| lib/common/widgets/flutter/text_field/editable_text.dart | b+c | b: updateStyle→setStyle 5 参数 + default: 兜底；c: enableInlinePrediction 等 3.41 API 删除；a(排除): 桌面 _deletedRange（计划排除桌面） |
| lib/common/widgets/flutter/text_field/spell_check_suggestions_toolbar.dart | b | hide AdaptiveTextSelectionToolbar 解析 vendored 类 |
| lib/common/widgets/flutter/text_field/text_field.dart | b+c | b: default: material 配置；c: 版本漂移 |
| lib/common/widgets/flutter/text_field/text_selection.dart | b | **知识库点名文件**：2921,3044 注释代码，禁止恢复 |
| lib/common/widgets/flutter/vertical_slider.dart | b | ohos 归入 Android 组 |

### 1.6 lib/models（7 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/models/common/account_type.dart | a | A 6 值（reply/blacklist + desc），B 4 值 → Task 5 |
| lib/models/common/home_tab_type.dart | a | A 多 `hk_bangumi` + ctr/page switch → Task 12 |
| lib/models/common/member/user_info_type.dart | c | 点简写 vs 显式 Alignment（等价） |
| lib/models/common/search/search_type.dart | a | A 多 `media_hk_bangumi` → Task 12 |
| lib/models/common/setting_type.dart | b+c | b: B 独有 experimentalSetting（液态玻璃，保留）；c: blockFilterSetting 文案 + switch 顺序 |
| lib/models/dynamics/result.dart | a | A 对 decorate/decoration_card、num_str/num_desc 回退解析（健壮性）→ 可选移植 |
| lib/models/video/play/url.dart | c | B 构造可传 lastPlayTime（等价重构） |

### 1.7 lib/models_new（11 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/models_new/AGENTS.md | c | 文档各自描述自己树 |
| lib/models_new/download/bili_download_entry_info.dart | b | B 独有下载分享 shareSelf（qshh f11e538d6，保留） |
| lib/models_new/followee_votes/vote.dart | c | 构造器私有命名参数写法 |
| lib/models_new/history/list.dart | a | A 多 playbackProgress getter（上游 #2458 历史续播）→ Task 23 |
| lib/models_new/live/live_feed_index/card_data_list_item.dart | a | A 多 feedback 字段（上游 #2456 直播反馈）→ Task 21 |
| lib/models_new/live/live_superchat/item.dart | a | A 多 startSime 字段（SC 开始时间，可选） |
| lib/models_new/space/space/data.dart | a | A 多 guestRelation 字段（member 关系，可选） |
| lib/models_new/video/video_stein_edgeinfo/choice.dart | a | A fork 完整版（platformAction/nativeAction/condition/isDefault）→ Task 18 |
| lib/models_new/video/video_stein_edgeinfo/data.dart | a | A 多 title/edgeId/storyList/buvid/preload/isLeaf → Task 18 |
| lib/models_new/video/video_stein_edgeinfo/edges.dart | a | A 多 dimension/skin → Task 18 |
| lib/models_new/video/video_stein_edgeinfo/question.dart | a | A 多 id/type/startTimeR/duration/pauseVideo/title → Task 18 |

### 1.8 lib/plugin/pl_player + lib/router（10 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/plugin/pl_player/controller.dart | b+a | b: media_kit fork/audio-files/PiP floating/continuation/stall watchdog/音量回显；a: fastForBackwardDuration_（Task 25） |
| lib/plugin/pl_player/models/bottom_control_type.dart | a | A 多 `stein` 枚举 → Task 19 |
| lib/plugin/pl_player/models/data_source.dart | b | FileSource 绝对路径规整（鸿蒙下载目录修复） |
| lib/plugin/pl_player/models/fullscreen_mode.dart | c | gravity desc 文案 |
| lib/plugin/pl_player/utils/danmaku_options.dart | b | 硬编码 HarmonyOS_Sans |
| lib/plugin/pl_player/utils/fullscreen.dart | b | harmonyLandscapeAutoMode/harmonyFullAutoMode/_invalidateOrientationCache/allowRotateScreen |
| lib/plugin/pl_player/view/view.dart | b+a | b: media_kit Video 替代 SimpleVideo、字幕拖动 Dart 侧、亮度兜底、状态栏切换按钮；a: stein/showStein/interactiveChild/长按比例倍速/HDR 提示（Task 19/25） |
| lib/plugin/pl_player/view/widgets.dart | c | 构造器写法 |
| lib/plugin/pl_player/widgets/mpv_convert_webp.dart | b | FFI 改经 MediaKitAdapt |
| lib/router/app_pages.dart | c | B 多 13 条设置拆分路由（上游演进）；A `/atFilterSetting` vs B `/atFilter` 命名差异；`/apiHostSetting` B 已注册（Task 11 只需加入口） |

### 1.9 lib/pages/video（24 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/pages/video/ai_conclusion/view.dart | a+b | a: hasContent/messageForResult/showResultMessage（服务型 AI 结果，Task 13）；b: selectableText 替换 SelectionArea |
| lib/pages/video/controller.dart | b+a | b: continuation/autoPlay args/durl 仅首段/字幕临时 vtt/imageview 标志；a: stein 历史恢复体系整体删除（Task 18） |
| lib/pages/video/download_panel/view.dart | b | connectivity 单值 |
| lib/pages/video/introduction/pgc/controller.dart | b | onSkipToPrevious/Next（播控中心） |
| lib/pages/video/introduction/pgc/view.dart | a+c | a: 分享 onLongPress 快速分享（Task 22）；c: ImageType 显式 |
| lib/pages/video/introduction/pgc/widgets/intro_detail.dart | b | selectableText |
| lib/pages/video/introduction/ugc/controller.dart | a+b | a: AI 总结服务体系（Task 13）；b: onSkipToPrevious/Next |
| lib/pages/video/introduction/ugc/view.dart | a+b | a: 快速分享 + AI 总结点击逻辑（Task 13/22）；b: SelectionArea 替换 |
| lib/pages/video/introduction/ugc/widgets/menu_row.dart | c | 格式化 |
| lib/pages/video/member/controller.dart | c | Future.syncValue→Future.value |
| lib/pages/video/member/view.dart | c | 点简写展开 |
| lib/pages/video/pay_coins/view.dart | c | DoubleExt 扩展名变化 |
| lib/pages/video/post_panel/popup_menu_text.dart | c | BOM + 点简写 |
| lib/pages/video/reply/controller.dart | a | A translatedReplies RxMap + translateReply(ReplyInfo)（翻译横幅，Task 15） |
| lib/pages/video/reply/view.dart | a+c | a: canSort + translatedReplies 重建（Task 15/16）；c: FAB 显隐内联化 |
| lib/pages/video/reply/widgets/reply_item_grpc.dart | a+b+c | a: BlockedReplyBanner/翻译横幅参数/手动加载图/拉黑评论者/分享评论/屏蔽图片/举报 onBlockImages（Task 14/15/16/20）；b: ExtraHitTestWidget；c: 内联翻译（上游形态，保留） |
| lib/pages/video/reply_new/view.dart | b+c | b: keepChatPanel/screenshot 返回字节；c: ContextExtensions |
| lib/pages/video/reply_reply/view.dart | a+c | a: translatedReplies + canSort（Task 15/16）；c: onLoadMore postFrame 包装 |
| lib/pages/video/reply_search_item/view.dart | c | BOM + 点简写 |
| lib/pages/video/send_danmaku/view.dart | c | physics 常量替换 |
| lib/pages/video/view.dart | b+a | b: 大段 OHOS（didPushNext/HeroDialogRoute/pipModeRx/statusBarTap/方向自动全屏/NoOverscrollBehavior）；a: stein 全套 UI 删除（Task 19） |
| lib/pages/video/widgets/header_control.dart | b+a | b: media_kit_adapt/听视频 playerInit/file_picker_ohos/PiP floating；a: 快速分享 + HDR 提示（Task 22/25） |
| lib/pages/video/widgets/header_mixin.dart | c | 重构 |
| lib/pages/video/widgets/player_focus.dart | a | fastForBackwardDuration_（键盘快退独立时长）→ Task 25 |

### 1.10 lib/pages/dynamics + 社交域（58 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/pages/dynamics/controller.dart | a+b | a: 刷新 FAB（Task 24）；b: statusBarTap 注册 |
| lib/pages/dynamics/view.dart | a | 刷新 FAB UI（Task 24） |
| lib/pages/dynamics/widgets/action_panel.dart | b+c | b: HarmonyChannel 隐藏系统栏；c: tapTargetSize |
| lib/pages/dynamics/widgets/additional_panel.dart | c | SelectionText vs SelectableText（上游漂移）+ 点简写 |
| lib/pages/dynamics/widgets/author_panel.dart | b+a | b: ExtraHitTestWidget + 隐藏系统栏；a: 三处空安全兜底（?. + ??，A 更稳） |
| lib/pages/dynamics/widgets/content_panel.dart | c | SelectionText vs SelectableText + dyn_menu_helper 孤儿化 |
| lib/pages/dynamics/widgets/dynamic_panel.dart | c | 点简写 + margin 微差 |
| lib/pages/dynamics/widgets/interaction.dart | c | 点简写 |
| lib/pages/dynamics/widgets/live_panel_sub.dart | b | CachedLayoutBuilder |
| lib/pages/dynamics/widgets/live_rcmd_panel.dart | b | CachedLayoutBuilder |
| lib/pages/dynamics/widgets/rich_node_panel.dart | c | EmoteSpan vs WidgetSpan + 行高/空格微差 |
| lib/pages/dynamics/widgets/up_panel.dart | c | clipBehavior |
| lib/pages/dynamics/widgets/video_panel.dart | b | CachedLayoutBuilder |
| lib/pages/dynamics/widgets/vote.dart | b+c | b: CachedLayoutBuilder；c: 点简写 |
| lib/pages/dynamics_create/view.dart | b+c | b: 隐藏系统栏 + keepChatPanel；c: 点简写 |
| lib/pages/dynamics_create_vote/controller.dart | c | 内容完全一致（仅换行符） |
| lib/pages/dynamics_create_vote/view.dart | c | BOM + 点简写 |
| lib/pages/dynamics_detail/controller.dart | c | 内容完全一致 |
| lib/pages/dynamics_detail/view.dart | b+c | b: 隐藏系统栏；c: fabAnimWrapper 签名漂移 + placeHolder 局部化 |
| lib/pages/dynamics_mention/controller.dart | c | 内容完全一致 |
| lib/pages/dynamics_mention/view.dart | b+c | b: 隐藏系统栏；c: 点简写 |
| lib/pages/dynamics_mention/widgets/item.dart | c | 点简写 |
| lib/pages/dynamics_repost/view.dart | c+a | c: physics 替换；a: A 空安全 `...?` 展开 |
| lib/pages/dynamics_select_topic/controller.dart | c | 内容完全一致 |
| lib/pages/dynamics_select_topic/view.dart | c | BOM + 点简写 |
| lib/pages/dynamics_topic/controller.dart | c | toggle vs 显式赋值 |
| lib/pages/dynamics_topic/view.dart | c | fabAnimWrapper/SelectionText/Material+Ink 漂移 |
| lib/pages/fav/video/controller.dart | c | Future.syncValue |
| lib/pages/fav_create/view.dart | b+c | b: WebUiSettings（image_cropper 鸿蒙）；c: context 生命周期处理 |
| lib/pages/fav_folder_sort/view.dart | b | onReorderItem→onReorder + newIndex 修正 |
| lib/pages/fav_sort/view.dart | b | 同上 |
| lib/pages/follow/child/child_view.dart | c | fabAnimWrapper 内联化 |
| lib/pages/follow/widgets/follow_item.dart | c | 仅 BOM |
| lib/pages/follow_tag_sort/view.dart | b | onReorder 修正 |
| lib/pages/main_reply/view.dart | a+c | a: canSort 开关（Task 16）；c: fabAnimWrapper |
| lib/pages/member/controller.dart | c | guestRelation 分支删除（A 领先，可选对齐） |
| lib/pages/member/view.dart | b+c | b: 状态栏点击回顶；c: NoOverscrollIndicator 删除 |
| lib/pages/member/widget/reserve_button.dart | c | 构造器写法 |
| lib/pages/member/widget/user_info_card.dart | c | relation==-1 分支（A 领先）+ SelectionText 漂移 |
| lib/pages/member_coin_arc/widgets/item.dart | c | B 领先（a0fbb7fb4 封面零圆角修复） |
| lib/pages/member_dynamics/controller.dart | c | Future.syncValue |
| lib/pages/member_favorite/view.dart | c | 点简写 |
| lib/pages/member_favorite/widget/item.dart | b | CachedLayoutBuilder |
| lib/pages/member_home/view.dart | c | ContextExtensions |
| lib/pages/member_home/widgets/video_card_v_member_home.dart | c | B 领先封面修复 |
| lib/pages/member_opus/view.dart | c | fabAnimWrapper |
| lib/pages/member_opus/widgets/space_opus_item.dart | b | CachedLayoutBuilder |
| lib/pages/member_profile/view.dart | b+c | b: WebUiSettings + get hide；c: BOM |
| lib/pages/member_search/view.dart | c | BOM + 点简写 |
| lib/pages/member_shop/widgets/item.dart | b | CachedLayoutBuilder |
| lib/pages/member_video/view.dart | c | fabAnimWrapper |
| lib/pages/msg_feed_top/like_me/controller.dart | c | Future.syncValue |
| lib/pages/whisper/view.dart | c | 点简写 + BOM |
| lib/pages/whisper/widgets/item.dart | a | 标为已读删除（依赖 sessionDetail，Task 17） |
| lib/pages/whisper_block/view.dart | c | 点简写 |
| lib/pages/whisper_detail/view.dart | c | physics 常量 |
| lib/pages/whisper_detail/widget/chat_item.dart | c | EmoteSpan/SelectionText 漂移 + B 领先封面修复 |
| lib/pages/whisper_link_setting/controller.dart | c | toggle 写法 |

### 1.11 lib/pages/live / search / pgc / download / misc（56 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/pages/about/view.dart | b+c | b: appName 鸿蒙版标注 + commitHash 回退 HEAD；c: 上游 Source Code 项 |
| lib/pages/article/controller.dart | b+c | b: holdContinuation；c: Future.syncValue |
| lib/pages/article/view.dart | c | fabAnimWrapper |
| lib/pages/article/widgets/article_ops.dart | c | 构造器写法 |
| lib/pages/article/widgets/opus_content.dart | c | Hero tag 消歧 + link card 简化 |
| lib/pages/audio/controller.dart | b+c | b: media_kit fork/continuation/skip；c: autoplay 参数（上游接续特性） |
| lib/pages/audio/view.dart | b+c | b: selectableText；c: volume API/player 构造 |
| lib/pages/blacklist/view.dart | c | 点简写 |
| lib/pages/download/detail/widgets/item.dart | b | 分享本地文件（B 独有，保留） |
| lib/pages/download/search/controller.dart | a | A 按 UP 主名过滤（Task 26） |
| lib/pages/download/view.dart | b+c | b: 多选分享 + CachedLayoutBuilder；c: 点简写 |
| lib/pages/emote/view.dart | c | physics 常量 |
| lib/pages/history/widgets/item.dart | a | A 传 progress 续播（Task 23） |
| lib/pages/hot/view.dart | c | 点简写 |
| lib/pages/live/view.dart | c | 点简写 |
| lib/pages/live/widgets/live_item_app.dart | a+b | a: 举报/反馈按钮（Task 21）；b: emote→BorderRadius.zero + AnimatedOpacity |
| lib/pages/live_area/controller.dart | c | toggle 写法 |
| lib/pages/live_dm_block/view.dart | c | NoOverscrollIndicator 移除 |
| lib/pages/live_emote/view.dart | c | physics 常量 |
| lib/pages/live_follow/widgets/live_item_follow.dart | b+c | b: 封面零圆角 + AnimatedOpacity；c: 点简写 |
| lib/pages/live_room/contribution_rank/view.dart | c | 点简写 |
| lib/pages/live_room/controller.dart | b+c | b: videoParams 替代 size + continuation + onlyAudio；c: autoplay 参数 |
| lib/pages/live_room/send_danmaku/view.dart | c | RichTextType 显式 |
| lib/pages/live_room/superchat/superchat_card.dart | b+c | b: SelectionArea 替代 SelectionText（live_menu_helper 孤儿化）；c: SC 划线/时间漂移 |
| lib/pages/live_room/superchat/superchat_panel.dart | c | physics 常量 |
| lib/pages/live_room/view.dart | b+c | b: pipModeRx/holdDecorDark/Floating；c: dispose 重构 |
| lib/pages/live_room/widgets/bottom_control.dart | a | A 长按/右键比例切换（Task 25） |
| lib/pages/live_room/widgets/chat_panel.dart | c | physics 常量 |
| lib/pages/live_room/widgets/header_control.dart | b+c | b: PiP floating + 音量回显；c: toggle 写法 |
| lib/pages/live_search/view.dart | c | 点简写 |
| lib/pages/live_search/widgets/live_search_room.dart | b+c | b: 封面零圆角；c: 点简写 |
| lib/pages/login/controller.dart | a | 登录会话身份/_ensureLoginSessionIdentity/buvidActive/账号显示名/登录新账号按钮（Task 8/10/29） |
| lib/pages/login/geetest/geetest_webview_dialog.dart | b | Linux webview 移除 + HTML 居中 |
| lib/pages/match_info/view.dart | c | fabAnimWrapper |
| lib/pages/music/view.dart | b+c | b: selectableText；c: fabAnimWrapper |
| lib/pages/pgc/controller.dart | a | hk_bangumi 时间表/订阅/index + apiHKUrl 代理 + Error 提示（Task 12） |
| lib/pages/pgc/view.dart | a | hk_bangumi 更多按钮（Task 12） |
| lib/pages/pgc_index/view.dart | c | toggle 写法 |
| lib/pages/pgc_review/child/view.dart | b+c | b: SelectableText；c: const 构造 |
| lib/pages/pgc_review/post/view.dart | c | toggle 写法 |
| lib/pages/save_panel/view.dart | a+c | a: forceShowOriginalContent（保存评论图原文，Task 26）；c: share_plus 版本 |
| lib/pages/search/controller.dart | c | B 领先：光标移到末尾（桌面，保留） |
| lib/pages/search/view.dart | c | 仅 BOM |
| lib/pages/search/widgets/hot_keyword.dart | c | 构造器写法 |
| lib/pages/search_panel/article/controller.dart | c | ContextExtensions |
| lib/pages/search_panel/live/widgets/item.dart | b+c | b: 封面零圆角；c: 点简写 |
| lib/pages/search_panel/user/controller.dart | c | ContextExtensions |
| lib/pages/search_panel/video/controller.dart | c | ContextExtensions |
| lib/pages/search_result/view.dart | a | media_hk_bangumi 搜索 Tab（Task 12） |
| lib/pages/search_trending/view.dart | c | ContextExtensions |
| lib/pages/settings_search/view.dart | c | B 未接入 blockFilterSettings（可选对齐） |
| lib/pages/share/view.dart | c | 点简写 |
| lib/pages/sponsor_block/block_mixin.dart | a | 无痕抑制 suppressSponsorBlockIncognito + _doVote catchError（Task 23） |
| lib/pages/sponsor_block/view.dart | c | 点简写 |
| lib/pages/subscription/controller.dart | c | Future.syncValue |
| lib/pages/webview/view.dart | b+c | b: 国际头/导航栏 JS 生效 + SelectableText；c: shouldOverrideUrlLoading 重构 |

### 1.12 lib/pages/setting（19 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/pages/setting/models/block_filter_settings.dart | a+c | 列表与 A 一致；仅路由 `/atFilterSetting`→`/atFilter` 差异（B 已注册）。**UI 是残留但可直接复用**（见第三部分） |
| lib/pages/setting/models/extra_settings.dart | a+b | a: A 独有大量设置项（accountDisplayName/suppressSponsorBlockIncognito/defaultAppealReason/saveImgPath/showClipboardSearch/enableQuickShare/手动加载图/评论区AI翻译/AI总结配置组/apiHKUrl/自定义API主机）；b: file_picker_ohos/preInitPlayer=OS.isHarmony。B 中键多残留但无消费 → Task 11/13/15/16/22/28 |
| lib/pages/setting/models/model.dart | a+c | a: getSaveImgPathModel（Task 28）；c: getVideoFilterSelectModel 签名 |
| lib/pages/setting/models/play_settings.dart | a+c | a: fastForBackwardDuration_ 拆分 + 查看快捷键入口（Task 25）；c: autoPlayEnable/enableQuickDouble 默认值漂移；b: allowRotateScreen + 后台 PiP OS.isHarmony |
| lib/pages/setting/models/privacy_settings.dart | a | A 账号模式 desc + SelectionArea 可选中（Task 5 配套） |
| lib/pages/setting/models/recommend_settings.dart | c | B 额外关键词过滤项（重复暴露）+ 脚注（漂移，保留） |
| lib/pages/setting/models/style_settings.dart | a+b | a: showHomeRefreshFab/showDynamicsRefreshFab/hideStatusBar/useSystemFont 设置项（Task 24，B 键残留无 UI）；b: hideBottomBar onChanged setShellBarsScrollHidden |
| lib/pages/setting/pages/at_filter.dart | c | 逻辑一致仅缩进 |
| lib/pages/setting/pages/bar_set.dart | c | onReorderItem→onReorder（Flutter 版本） |
| lib/pages/setting/pages/color_select.dart | c | **B 是 bug**：`AnimatedHeight(expand: dynamicColor)` 反向（A `!dynamicColor` 正确）；保留 B 现状不移植 bug，可顺手修正 |
| lib/pages/setting/pages/logs.dart | c | 两套实现（A 高亮堆栈 vs B 自定义 Report + 14 天自动清理，各自可用） |
| lib/pages/setting/pages/play_speed_set.dart | c | ContextExtensions |
| lib/pages/setting/view.dart | a+c | a: 登出框昵称显示（Task 29）+ 切换账号标题；c: B 设置页拆分架构（保留）+ experimentalSetting 入口 |
| lib/pages/setting/widgets/dual_slider_dialog.dart | c | 逐字节一致（点简写） |
| lib/pages/setting/widgets/multi_select_dialog.dart | c | 完全一致 |
| lib/pages/setting/widgets/ordered_multi_select_dialog.dart | c | 完全一致 |
| lib/pages/setting/widgets/select_dialog.dart | c | 完全一致 |
| lib/pages/setting/widgets/shortcut_keys_dialog.dart | c | A/B 快捷键分组不同（B 无引用死代码，保留） |
| lib/pages/setting/widgets/switch_item.dart | c | 完全一致 |

### 1.14 lib/pages/home / main / rcmd（6 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/pages/home/controller.dart | a | A 独有首页刷新 FAB（GetTickerProviderStateMixin + fabAnimation）→ Task 24 |
| lib/pages/home/view.dart | a | A 独有刷新 FAB + 剪贴板搜索（showClipboardSearch，B pref 残留无消费）→ Task 24 |
| lib/pages/main/controller.dart | b+c | b: 原生 HDS 底栏（useNativeTabs/_initHdsBar/HarmonyChannel）；c: setIndex 二次点击"我的"逻辑删除（A 领先，可选对齐 Task 29） |
| lib/pages/main/view.dart | b | 原生底栏集成（_primaryColorValue/_nativeTabsWorker/HarmonyChannel 同步 + OS.isHarmony 返回键） |
| lib/pages/rcmd/controller.dart | c | onRefresh 差异（A 多"推荐已刷新"toast，行为等价） |
| lib/pages/rcmd/view.dart | c | B 领先：滚动监听预加载 + ValueKey + cacheExtent 800（保留 B） |

### 1.15 lib/ 根级 + services（5 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/build_config.dart | c | versionTag 默认值 `'N/A'` vs `versionName`（漂移） |
| lib/main.dart | b | 鸿蒙启动序列（OS.initHarmonyDeviceType/setScreenOrientationUser/ShellBarsObserver/ImageMemoryCleaner/continuation/字重）+ catcher_2 鸿蒙禁用（TODO 待适配）+ 缩放重建 |
| lib/services/audio_handler.dart | b+c | b: onSkipToNext/Previous（播控中心）+ local() 工厂 + 直播 duration:Duration.zero；c: 通知渠道 id 品牌差异 |
| lib/services/logger.dart | c | A ProductionFilter+PrettyLogPrinter / B PiliLogger+DevelopmentFilter（release 静默，log 排除在移植范围外） |
| lib/services/shutdown_timer_service.dart | c | 直播弹窗强制暗色 vs 随当前主题（A 侧新增，非必须） |

### 1.13 lib/pages/common / mine / scripts（14 文件）

| 文件 | 分类 | 证据 |
|---|---|---|
| lib/pages/AGENTS.md | c | 文档各自描述自己树 |
| lib/pages/common/common_controller.dart | b | B 新增 StatusBarTapObserver（状态栏回顶） |
| lib/pages/common/common_intro_controller.dart | c | toggle vs 显式赋值 |
| lib/pages/common/common_page.dart | b | B 新增 HarmonyChannel.setShellBarsScrollHidden（原生 HDS 底栏滚动显隐） |
| lib/pages/common/dyn/common_dyn_page.dart | a | A 独有 canSort 排序开关（Task 16）+ onNotification 覆写（fab_mixin 相关） |
| lib/pages/common/fab_mixin.dart | a | A 独有 fabAnimWrapper/onNotification（Task 24 动态/详情 FAB 传递依赖） |
| lib/pages/common/publish/common_publish_page.dart | b+c | b: keepChatPanel/restoreChatPanel；c: ContextExtensions |
| lib/pages/common/publish/common_rich_text_pub_page.dart | b+c | b: keepChatPanel 图片查看 + cache_manager_ext；c: 点简写 |
| lib/pages/common/publish/publish_route.dart | c | 构造器写法 |
| lib/pages/common/reply_controller.dart | a | A 独有 canSort + translatedReplies + translateReply（Task 15/16，核心） |
| lib/pages/common/search/common_search_controller.dart | c | Future.syncValue |
| lib/pages/common/search/common_search_page.dart | c | 点简写 |
| lib/pages/mine/controller.dart | a+b | a: A 有 setAccountUname 调用（昵称缓存，Task 10）；b: HarmonyChannel 隐藏系统栏 + Future.value |
| lib/pages/mine/view.dart | c | trackGap 参数（LinearProgressIndicator API 版本） |
| lib/scripts/selectable_region.patch | c | A 跨 5 文件大补丁 vs B 1 文件 16 行最小复刻（同效果不同实现，保留 B） |
| lib/pages/AGENTS.md | c | 文档（含 pages/common/AGENTS.md 已并入文档类） |

---

## 二、27 ONLY_A 分类（leaf 功能 vs 传递依赖）

| 文件 | 类别 | 说明 |
|---|---|---|
| lib/http/ai_summary_service_router.dart | **leaf 功能** | AiSummaryServiceRouter 服务选择路由 → Task 13 |
| lib/http/bilibili_multimodal_summary_adapter.dart | **leaf 功能** | 多模态 AI 总结（依赖 ugcSummaryMp4Url）→ Task 13 |
| lib/http/bilibili_subtitle_summary_adapter.dart | **leaf 功能** | 字幕 AI 总结（依赖 transcriptSubtitles）→ Task 13 |
| lib/http/custom_host_interceptor.dart | **leaf 功能** | 自定义 API Host 拦截器 → Task 11 |
| lib/http/hk_api_retry_interceptor.dart | **leaf 功能** | 港澳台代理重试拦截器 → Task 11 |
| lib/pages/setting/api_host_page.dart | **leaf 功能** | A 版 API Host 页面（**注意**：B 有 `setting/pages/api_host_page.dart` 不同实现，见第三部分） |
| lib/utils/accounts/request_identity_adapter.dart | **leaf 功能** | RequestIdentityAdapter 每请求身份装饰器 → Task 8 |
| lib/utils/extension/selectable_region_ext.dart | **leaf 功能** | 选中文本"打开"菜单 → Task 27（传递依赖 ListExt.insertOrAdd = iterable_ext.dart） |
| lib/scripts/build.ps1 | 传递依赖/构建 | A 的 PowerShell 版本管理（B 用 build_env.dart，**不移植**） |
| lib/scripts/patch.ps1 | 传递依赖/构建 | A 的 SDK 打补丁脚本（B 用 vendored，**不移植**） |
| lib/scripts/editable_text.patch | 传递依赖/SDK patch | A 引擎补丁（B vendored 替代，**不移植**） |
| lib/scripts/scroll_position.patch | 传递依赖/SDK patch | 同上 |
| lib/scripts/selection_placeholder.patch | 传递依赖/SDK patch | 同上 |
| lib/scripts/text_field.patch | 传递依赖/SDK patch | 同上 |
| lib/common/widgets/AGENTS.md | 文档 | A 知识库（B 有 common/AGENTS.md 对应物） |
| lib/grpc/AGENTS.md | 文档 | A 知识库 |
| lib/http/AGENTS.md | 文档 | A 知识库 |
| lib/models/AGENTS.md | 文档 | A 知识库 |
| lib/pages/common/AGENTS.md | 文档 | A 知识库 |
| lib/pages/setting/AGENTS.md | 文档 | A 知识库 |
| lib/pages/video/AGENTS.md | 文档 | A 知识库 |
| lib/plugin/pl_player/AGENTS.md | 文档 | A 知识库 |
| lib/scripts/AGENTS.md | 文档 | A 知识库（CI 约定） |
| lib/services/AGENTS.md | 文档 | A 知识库 |
| lib/tcp/AGENTS.md | 文档 | A 知识库 |
| lib/utils/accounts/AGENTS.md | 文档 | A 知识库 |
| lib/utils/AGENTS.md | 文档 | A 知识库 |

**统计**: leaf 功能 8 个（全部纳入移植计划对应任务）、传递依赖 6 个（scripts/*，B 已有等价物不移植）、文档 13 个（不移植）。

---

## 三、死代码残留 provenance 与决策

> 审计范围：B 中"存在但逻辑失效/无入口/无引用"的残留，判定其来源（旧 A 残留 / B 自建 / 上游产物），并给 reuse-as-is / extend / replace 决策（默认 replace，除非有证据证明残留与 A 当前实现结构一致）。

### 残留 1: `lib/pages/setting/models/block_filter_settings.dart`

- **现状**: B 有完整设置 UI 列表（10 项，与 A 逐项一致，仅 `/atFilterSetting`→`/atFilter` 路由差异）；`minLevelForReply`/`showBlockedReplyBanner`/`enableAtFilter` 等 Pref 键存在且设置页可写；但 `lib/grpc/reply.dart` 只实现关键词+带货过滤（`needRemoveGrpc`），等级/@/黑名单/横幅逻辑**全部失效**（设置成为死设置）。
- **来源定性**: **旧 A 残留（Wodlie fork 血统）**。B 提交链证实：`5a4dd671f init`（Wodlie 2026-07-28 建仓）→ `b11857c1e restore fork-specific features` → `dda954016 minimize restoring block filter settings`（明确"保留 block-filter 相关代码，回退其余到上游"）。UI 模型是 fork 的，逻辑被 `dda954016` 裁剪。
- **与 A 结构一致性**: 列表定义与 A **一致**（仅路由名），属同一 fork 血统。
- **决策**: **reuse-as-is**（模型层） + **extend**（逻辑层由 Task 14 恢复）。不 replace——B 的 UI 模型可直接作为 Task 14 的基底，仅需补 `checkBlockReason` 5 策略与 `BlockedReplyBanner` 横幅消费。路由 `/atFilter`（B）无需改回 A 的 `/atFilterSetting`（B 已自洽注册）。

### 残留 2: `lib/models/common/video/ai_summary_service.dart`

- **现状**: 两仓库**逐字节相同**（SHA-256 一致，属 991 SAME）；B 中 `storage_pref.dart` import 它（`AiSummaryService` 枚举 getter），`bilibili_legacy_summary_adapter.dart` + `service_result.dart` 消费其类型。但 `BilibiliLegacySummaryAdapter` 本身**全库无调用方**（孤儿），`Pref.aiSummaryService` 有 getter 无消费。
- **来源定性**: **上游产物（非残留）**。文件内容 A=B 完全相同，是共享上游快照；B 无 router 是因为 router 本身是 ONLY_A（`ai_summary_service_router.dart`）。
- **决策**: **reuse-as-is**。文件已是 A 的最新内容，Task 13 无需改它，只需在其上补 router + 两个 adapter + `video.dart` 的 `ugcSummaryMp4Url`/`transcriptSubtitles` + 设置组。

### 残留 3: `lib/pages/setting/pages/api_host_page.dart`（B 独有）

- **现状**: B 注册路由 `/apiHostSetting` 但**全库无 `toNamed('apiHostSetting')`**（死页面，无入口）；页面内嵌 `enableCustomApiHost` 开关但该 Pref 仅被页面自身 + storage 读写，无任何拦截器消费（死设置）。`Pref.apiHKUrl` 仅 storage 键，全库无业务引用。
- **来源定性**: **B 自建（fork 独立演化）**。A 的对应物是 `lib/pages/setting/api_host_page.dart`（ONLY_A，路径不同、`showAppBar` 参数、无内嵌开关、从 `extra_settings.dart` 可达）。B 的版本来自其上游 dev4harmony 血统（独立实现），**不是** A 文件的复制。
- **决策**: **reuse-as-is（保留 B 页面本体）**，不 replace 成 A 版。理由：B 版内嵌启用开关 + 输入即写 + 重置按钮，结构比 A 版更适合鸿蒙；Task 11 只需 (1) 在 `setting/view.dart` 或 `extra_settings.dart` 加入口、(2) 新建两个拦截器并消费 `Pref.enableCustomApiHost`/`apiHKUrl`、(3) gRPC 层支持 `customAppBaseUrl`。A 版仅作参照不复制。

### 残留 4: B 独有 7 个设置页（block_filter_setting / extra_setting / play_setting / privacy_setting / recommend_setting / style_setting / video_setting）

- **现状**: 7 个薄壳页面（StatefulWidget + ListView 渲染 models），全部经命名路由可达（`/blockFilterSetting` 等 13 条 B 独有路由），由 `setting/view.dart` 分发。**不是死代码**——是 B 的设置页拆分架构（A 用单页 `CommonSetting`）。
- **来源定性**: **B 自建架构**（qshh dev4harmony 提交 `327050892` 起，`b11857c1e` 恢复）。与 A 的 `CommonSetting` 单页是两种架构实现。
- **决策**: **reuse-as-is**。B 架构保留；A 的设置项增强（AI 总结配置组/快速分享/申诉理由等）落在 `models/*.dart`（DIFF 文件）中扩展，薄壳页面不动。**注意**: Task 11 的 api_host 入口应加在 `extra_setting.dart`（模型层）或 `view.dart`，而不是新建壳页。

### 残留 5: `lib/common/widgets/flutter/draggable_sheet/*`（2 个 ONLY_B vendored 文件）

- **现状**: `draggable_scrollable_sheet_dyn.dart`(1153 行) + `draggable_scrollable_sheet_topic.dart`(1139 行)，为引擎 `draggable_scrollable_sheet.dart` 的完整独立拷贝 + `DynDraggableScrollableSheet`/`TopicDraggableScrollableSheet` 扩展。**全库零引用**（grep 无任何 import）；实际页面用共享 `lib/common/widgets/draggable_sheet/*.dart` + part 文件。
- **来源定性**: **B 自建（vendored 补丁集）**。B 因无法给 OHOS 引擎打补丁，把 `layout_builder.patch` 等改动以文件形式内置；这 2 个文件与 `layout_builder.dart`/`sliver_layout_builder.dart` 构成"自洽但未被页面引用"的补丁集（04b 报告 §2.4/2.5/2.6，可能为移植遗留/备用）。
- **决策**: **reuse-as-is（保留不动）**。虽未引用，但属 B 的引擎兼容补丁基础设施；删除可能影响编译回退路径。不移植（A 无对应 standalone 文件，A 靠引擎补丁）。

### 残留 6: `lib/models/common/msg/msg_type.dart` + `lib/models/common/reply/reply_type.dart`（ONLY_B）

- **现状**: 两文件**整体被注释**（27 行 / 49 行全部 `//`），全库零引用（私信/评论逻辑用 protobuf 生成的 `im/type.pbenum.dart` 与 HTTP 字面量，不依赖此文件）。
- **来源定性**: **上游早期产物残留**。自 B 初始提交 `5a4dd671f init` 起存在、从未被修改；A 无此文件（更干净的快照已删除）。属"清理前旧形态死代码"的 `models/` 版（对应 121 个 models_new ONLY_B 死代码）。
- **决策**: **replace（删除或保持注释）**。无任何功能价值、无引用、无 A 对照。但按"不重构与移植功能无关代码"的守则，Task 期间**不改动**；建议在最终收尾（Batch 5）单独提清理（若用户同意）。对移植流程本身: 无影响。

### 其他相关残留（附注）

- **`lib/pages/setting/widgets/shortcut_keys_dialog.dart`**: B 存在但无引用（A 由 play_settings"查看快捷键"入口使用）→ 随 Task 25 恢复入口时 **reuse**。
- **`lib/http/bilibili_legacy_summary_adapter.dart`（两仓库 SAME）**: B 中孤儿（无调用方）→ Task 13 补 router 后即被消费，**reuse-as-is**。
- **`lib/utils/accounts/app_device_profile.dart`**: 内容与 A 逐字节相同，但 B 中零引用 + `AppDeviceProfileAdapter` 未注册 → Task 6 注册 adapter + Task 8/9 消费，**reuse-as-is**。
- **`lib/common/widgets/flutter/layout_builder.dart` + `sliver_layout_builder.dart`（ONLY_B）**: 同残留 5 的 vendored 补丁集，零引用（waterfall.dart 用引擎版）→ 保留不动。
- **121 个 models_new ONLY_B**: 已全量核实为 A `279f21857^` 清理前旧模型（去空白逐字一致），全孤儿 → 不动。

**决策汇总**: reuse-as-is 5 处（block_filter_settings 模型、ai_summary_service、api_host_page B 版、7 设置页壳、legacy adapter/app_device_profile）、保留不动 2 处（draggable_sheet vendored、layout_builder vendored）、replace 1 处（msg_type/reply_type 注释死代码，收尾清理）。

---

## 四、对 Batch 1 的执行建议

### 4.1 应以 A 为参照**重写**（B 现状为简化/旧形态，无法直接复用）

| 文件 | 建议 | 对应任务 |
|---|---|---|
| lib/models/common/account_type.dart | 直接按 A 6 值 + desc 重写 | T5 |
| lib/utils/accounts/api_type.dart | 按 A 补 reply/blacklist 路由表 + recommend liveFeedback | T5 |
| lib/utils/accounts/account_adapter.dart | 按 A 6 字段重写（含 4→6 迁移函数） | T6 |
| lib/utils/accounts.dart | 按 A 状态机重写（canonicalize/snapshot/reply/blacklist） | T7 |
| lib/utils/accounts/grpc_headers.dart | 按 A 按账号快照重写（保留 B 无账号回退 `_buvid=>LoginUtils.buvid`） | T9 |
| lib/utils/wbi_sign.dart | 按 A 追加 appendRiskFingerprintParams + catchError | T8 |
| lib/utils/accounts/request_identity_adapter.dart | 全新（ONLY_A 参照） | T8 |
| lib/http/custom_host_interceptor.dart / hk_api_retry_interceptor.dart | 全新（ONLY_A 参照） | T11 |
| lib/http/init.dart 拦截器链 | 按 A 插入两个拦截器（保留 B 的 connectivity/UA 适配） | T11 |
| lib/grpc/reply.dart（checkBlockReason 部分） | 按 A 恢复 5 策略（保留 B 已生成的 pb） | T14 |

### 4.2 应**复用 B 残留**（已核实结构上与 A 一致或为 B 自建最优）

| 文件 | 建议 | 对应任务 |
|---|---|---|
| lib/pages/setting/models/block_filter_settings.dart | 直接复用 B 模型层，只补逻辑消费 | T14 |
| lib/models/common/video/ai_summary_service.dart | 复用（A=B 字节相同），补 router+adapter | T13 |
| lib/pages/setting/pages/api_host_page.dart | 复用 B 页面，加入口 + 拦截器消费 | T11 |
| lib/http/bilibili_legacy_summary_adapter.dart | 复用（SAME），补 router 接线 | T13 |
| lib/utils/accounts/app_device_profile.dart | 复用（SAME），注册 adapter + 接线 | T6/T9 |
| lib/pages/setting/7 个壳页 | 保留 B 架构，扩展 models | T28 |
| lib/common/widgets/image/image_block_service.dart / blocked_image_storage.dart | 复用 B（SAME/近同），只补 widget 层 UI | T20 |

### 4.3 移植时**必须保留的 B 适配点**（防回归清单）

1. `account_mgr.dart` 的 `OS.isHarmony` dioError 分支 + connectivity `.desc` 单值（T7）
2. `login_utils.dart` 的 `genDeviceId()`（http/login 使用，T8 不得删）
3. `http/init.dart` 的 connectivity 单值回调 + `Dart/3.6` UA（T10/11）
4. `request_utils.dart`/`reply_utils.dart`/`ai_conclusion` 的 `SelectableText` 替换（T15/22，不恢复 SelectionText）
5. `text_selection.dart:2921,3044` 注释（全计划禁动）
6. `storage_key.dart` 的 OHOS-specific keys + `@Deprecated defaultDecode/secondDecode`（AGENTS 禁删）
7. pl_player/media_kit fork API（`audio-files`、`maybeAsNativePlayer`、PiP floating、stall watchdog、continuation）——T19/25 只加不拆
8. `theme_utils.dart` 强制 HarmonyOS_Sans + 系统字重映射（T28 不恢复 useSystemFont 消费）

### 4.4 阻断/风险提示

- **wbi dm_img_* 风控字段（T8）**: 与 B 现有 `member.dart` 的随机 dm 字段方案并存时，需确认 A 的确定性推导不破坏 B 现有请求签名。已在 T8 QA 中设 `appendRiskFingerprintParams` 命中断言。
- **gRPC 按账号头（T9）**: B 是 gRPC-over-HTTP 单例通道，A 是每账号头注入；需把头构建改为按请求取账号快照，但**不得改传输层**（dio_http2_adapter）。Task 3 的审计结论落地点。
- **AccountType 6 值**: B 的 `AccountType.values.length` 消费点（accounts.dart 数组初始化、login controller、privacy_settings）必须与 6 值兼容；4→6 追加安全但需迁移测试（T6 最高优先）。
- **app_device_profile 注册**: T6 必须在 `storage.dart` 补 `AppDeviceProfileAdapter` 注册，否则 Hive 反序列化崩。

---

## 五、完整性 QA

- 全量分类条目数: 337 DIFF + 27 ONLY_A = **364** ✓（见一、二部分）
- 残留决策数: **9 处**（≥5 要求）✓（第三部分）
- 与 15 份报告交叉验证: 抽查一致（grpc/im、http/video、grpc/reply、accounts.dart、reply_controller、pl_player/controller 等关键文件分类与 01/02/03/04b/06 报告结论无矛盾）✓
- 无法确定项: 0（全部基于报告 + git 提交链 + SHA-256 实读；仅 `enableQuickDouble`/`autoPlayEnable` 默认值哪方更接近上游标注为漂移不判定，不影响移植决策）
