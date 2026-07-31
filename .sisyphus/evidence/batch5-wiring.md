# Batch 5 — 19 功能族符号接线验证报告（Task 31）

> **Task:** port-a-features Task 31
> **Date:** 2026-08-01
> **Repo:** D:\coding\PiliPlusX_ohos (B)
> **方法:** 纯 grep/read 符号 + 消费点双重验证（从 `lib/main.dart` 可达链：main → router/app_pages → pages → widgets → http/grpc）
> **基线:** 不做代码修改；所有命中为真实 grep 输出
> **验收:** 19/19 接线 + 无「已移植但未接线」功能

## 结果总览

| # | 功能族 | 符号存在 | 消费点 | 状态 |
|---|--------|---------|--------|------|
| 1 | 账号 6 类型 | ✅ | ✅ | compile-verified |
| 2 | 自定义 API Host + 港澳台代理 | ✅ | ✅ | compile-verified |
| 3 | 港澳台番剧 | ✅ | ✅ | compile-verified |
| 4 | AI 总结多服务 | ✅ | ✅ | compile-verified |
| 5 | 评论屏蔽 5 策略 + 横幅 | ✅ | ✅ | compile-verified |
| 6 | 评论翻译横幅 | ✅ | ✅ | compile-verified |
| 7 | 评论申诉 | ✅ | ✅ | compile-verified |
| 8 | canSort | ✅ | ✅ | compile-verified |
| 9 | 长按拉黑/分享 | ✅ | ✅ | compile-verified |
| 10 | 手动加载评论图 | ✅ | ✅ | compile-verified |
| 11 | Stein 互动视频 | ✅ | ✅ | compile-verified + runtime-pending |
| 12 | 图片屏蔽 pHash UI | ✅ | ✅ | compile-verified + runtime-pending |
| 13 | 私信会话详情 + 标为已读 | ✅ | ✅ | compile-verified |
| 14 | 直播反馈 | ✅ | ✅ | compile-verified + runtime-pending |
| 15 | 快速分享 + pmShare | ✅ | ✅ | compile-verified + runtime-pending |
| 16 | 历史续播 | ✅ | ✅ | compile-verified + runtime-pending |
| 17 | SponsorBlock 无痕抑制 | ✅ | ✅ | compile-verified |
| 18 | 播放器快捷操作 | ✅ | ✅ | compile-verified + runtime-pending |
| 19 | selectable_region 替代 + insertOrAdd + viewPugv | ✅ | ✅ | compile-verified + runtime-pending |

**汇总: 19/19 接线成功，无孤儿功能。**

---

## 逐功能验证明细

### 1. 账号身份体系（AccountType 6 值 + reply/blacklist 路由）

**符号存在:**
```
lib/models/common/account_type.dart
  1: enum AccountType {
  2: main(...)  3: heartbeat(...)  4: recommend(...)  5: video(...)
  6: reply('评论操作', ...)  7: blacklist('黑名单操作', ...);
  → AccountType.values.length == 6 ✓（6 个枚举值，index 0-5）
```

**消费点:**
```
lib/utils/accounts.dart:36   final reply = accountMode[AccountType.reply.index];
lib/utils/accounts.dart:44   final blacklist = accountMode[AccountType.blacklist.index];
lib/utils/accounts/api_type.dart:102  AccountType.reply: { Api.replyAdd, Api.replyDel, Api.likeReply, Api.hateReply, Api.replyTop, Api.replyReport, Api.replySubjectModify }
lib/utils/accounts/api_type.dart:111  AccountType.blacklist: { Api.blackLst, Api.relationMod }
lib/utils/accounts/account_manager/account_mgr.dart:266-274  _resolveAccountSelection: ApiType.apiTypeSet[i]?.contains(path) → Accounts.snapshot(type) + Accounts.get(type)
lib/utils/accounts/account_manager/account_mgr.dart:277-284  _findAccount 同路由
```

**可达链:** main.dart:323 GetMaterialApp → `/setting`(app_pages:99) → api_type 路由表（login/switchAccount 消费 6 类型）；`/apiHostSetting` 等。reply/blacklist 账号在 http/grpc 请求经 AccountManager 拦截器按 path 路由选择。

**状态: compile-verified**

---

### 2. 自定义 API Host + 港澳台代理拦截器

**符号存在 + 消费点（同一 grep）：**
```
lib/http/init.dart:243  dio.interceptors.add(CustomHostInterceptor());
lib/http/init.dart:246  dio.interceptors.add(HkApiRetryInterceptor());
  链序：Retry → CustomHost → HkApi → Log（与 test/http/init_test.dart 断言一致）
lib/grpc/grpc_req.dart:63-64  (Pref.enableCustomApiHost && Pref.customAppBaseUrl.isNotEmpty) ? Pref.customAppBaseUrl : HttpString.appBaseUrl
lib/pages/setting/models/extra_settings.dart:846-907  「设置港澳台代理」(写 Pref.apiHKUrl) + 「自定义 API 主机」(Get.toNamed('/apiHostSetting'))
lib/router/app_pages.dart:148  /apiHostSetting → ApiHostPage()（注册路由可达）
```

**可达链:** main.dart → `/setting` → extra_settings（设置项入口）→ `/apiHostSetting`（api_host_page）。

**状态: compile-verified**

---

### 3. 港澳台番剧（hk_bangumi + media_hk_bangumi）

**符号存在:**
```
lib/models/common/home_tab_type.dart:22  hk_bangumi('港澳台番剧'),
lib/models/common/home_tab_type.dart:36  ctr switch: HomeTabType.hk_bangumi || ... => PgcController
lib/models/common/home_tab_type.dart:46  page switch: hk_bangumi => PgcPage(tabType: hk_bangumi)
```

**消费点:**
```
lib/pages/pgc/controller.dart:75-76   if (tabType == hk_bangumi && Pref.apiHKUrl.isNotEmpty) apiUrl = Pref.apiHKUrl + Api.pgcTimeline
lib/pages/pgc/controller.dart:151-155 if (tabType == hk_bangumi) { apiHKUrl.isEmpty → Error('请...设置代理服务器') ; else apiUrl = apiHKUrl + pgcIndexResult }
lib/pages/home/controller.dart:72      this.tabs = HomeTabType.values → 自动含港澳台番剧 tab
lib/http/search.dart（media_hk_bangumi → 代理/错误提示分支）
lib/pages/search_result/view.dart     SearchType.media_hk_bangumi → SearchPgcPanel
```

**可达链:** main.dart → `/`（MainApp → home tab）→ HomeTabType.values → PgcPage/PgcController。

**状态: compile-verified**

---

### 4. AI 总结多服务（AiSummaryServiceRouter）

**符号存在 + 消费点：**
```
lib/http/ai_summary_service_router.dart   abstract final class AiSummaryServiceRouter（summarizeUgcVideo 按 Pref.aiSummaryService 分发）
lib/pages/video/introduction/ugc/controller.dart:809  return AiSummaryServiceRouter.summarizeUgcVideo(...)
  上游：_requestAiConclusion → aiConclusion() → _aiBtn（ugc/view.dart）
lib/http/video.dart  ugcSummaryMp4Url + transcriptSubtitles（multimodal/subtitle adapter 依赖）
lib/pages/setting/models/extra_settings.dart  AI 总结设置组（aiSummaryBaseUrl/ApiKey/模型/超时/服务选择）
```

**可达链:** main.dart → `/videoV` → VideoDetailPage → ugc introduction → `_aiBtn` → ugc/controller → router。

**状态: compile-verified**（A 的 1 个既有测试契约 mismatch 与本功能无关，见 T13）

---

### 5. 评论屏蔽 5 策略 + BlockedReplyBanner

**符号存在:**
```
lib/grpc/reply.dart:239  static String? checkBlockReason(ReplyInfo reply)   ← 5 策略核心
lib/pages/video/reply/widgets/reply_item_grpc.dart:59  class BlockedReplyBanner extends StatelessWidget
```

**消费点（同文件多处）:**
```
lib/grpc/reply.dart:311  checkBlockReason(reply) != null（内部调用）
lib/grpc/reply.dart:365/381/387/461/493  checkBlockReason(...)（mainList/detailList/dialogList 过滤）
lib/grpc/reply.dart:313  isClientBlocked → 335 blockReply / 330 clearBlockedReasons / 322 getBriefBlockReason
lib/pages/video/reply/widgets/reply_item_grpc.dart:179-182  isClientBlocked && Pref.showBlockedReplyBanner → return BlockedReplyBanner(...)
lib/pages/video/reply/widgets/reply_item_grpc.dart:208-209  子回复同横幅
lib/pages/video/reply/widgets/reply_item_grpc.dart:782  .where((r) => !ReplyGrpc.isClientBlocked(r))
```

**可达链:** main.dart → `/videoV` → reply section → reply_item_grpc（横幅渲染）→ grpc/reply（策略）。

**状态: compile-verified**

---

### 6. 评论翻译横幅

**符号存在 + 消费点：**
```
lib/pages/video/reply/controller.dart:30  final RxMap<Int64, String> translatedReplies = ...
lib/pages/video/reply/controller.dart:50  Future<void> translateReply(ReplyInfo replyItem)（调用 ReplyGrpc.translateReply，写 translatedReplies）
lib/pages/video/reply/widgets/reply_item_grpc.dart:126-128  构造参数 translatedText / isTranslating / onTranslate
lib/pages/video/reply/widgets/reply_item_grpc.dart:146-152  字段声明
lib/pages/video/reply/widgets/reply_item_grpc.dart:447/482/505  翻译中横幅 + 译文横幅渲染
lib/pages/video/reply/widgets/reply_item_grpc.dart:705-750  翻译按钮（onTranslate/translatedText 驱动 '翻译'/'原文'）
lib/pages/video/reply/view.dart   Obx 内传 translatedText/isTranslating/onTranslate（T15 接线）
```

**可达链:** main.dart → `/videoV` → reply/view → reply_item_grpc（横幅+按钮）→ controller.translateReply。

**状态: compile-verified**

---

### 7. 评论申诉（appealComment + replyAppealSubmit + defaultAppealReason）

**符号存在 + 消费点：**
```
lib/http/reply.dart:237  static Future<...> appealComment({...})
lib/http/api.dart:177     static const String replyAppealSubmit = '/x/v2/reply/appeal/submit';
lib/utils/reply_utils.dart:131  final defaultReason = Pref.defaultAppealReason;   ← 申诉对话框消费
lib/pages/setting/models/extra_settings.dart:409-436  默认申诉理由设置项（读/写 Pref.defaultAppealReason）
lib/utils/storage_pref.dart:344-347  defaultAppealReason getter/setter
```

**可达链:** main.dart → `/videoV` → reply 长按/举报 → reply_utils 站内申诉对话框 → ReplyHttp.appealComment；`/setting` → 默认申诉理由设置。

**状态: compile-verified**

---

### 8. canSort

**符号存在 + 消费点：**
```
lib/pages/common/reply_controller.dart:25  final RxBool canSort = true.obs;
lib/pages/common/reply_controller.dart:69  canSort.value = data.subjectControl.switcherType == Int64(1);
lib/pages/common/reply_controller.dart:87  onRefresh: canSort.value = true;
lib/pages/common/reply_controller.dart:93  if (isLoading || !canSort.value) return;   ← queryBySort 门控
lib/pages/main_reply/view.dart:198-215  排序按钮 onPressed: canSort.value ? queryBySort : null + 置灰「排序不可用」
```

**可达链:** main.dart → `/videoV` 或动态 → reply → common/reply_controller → main_reply/view 排序按钮。

**状态: compile-verified**

---

### 9. 长按拉黑 / 分享评论

**符号存在 + 消费点（reply_item_grpc 长按菜单）:**
```
lib/pages/video/reply/widgets/reply_item_grpc.dart:1460-1462  VideoHttp.relationMod(mid, act: 5, reSrc: 11)   ← 拉黑评论者
lib/pages/video/reply/widgets/reply_item_grpc.dart:1515        ShareUtils.shareText(url)                        ← 分享评论（#reply 链接）
```

**可达链:** main.dart → `/videoV` → reply_item_grpc 长按 morePanel → relationMod(act:5)/ShareUtils.shareText。

**状态: compile-verified**

---

### 10. 手动加载评论图

**符号存在 + 消费点：**
```
lib/utils/storage_pref.dart:1055-1056  static bool get manualLoadCommentImage => _setting.get(SettingBoxKey.manualLoadCommentImage, defaultValue: false);
lib/pages/video/reply/widgets/reply_item_grpc.dart:591  if (!Pref.manualLoadCommentImage || _loadManualImages) { ImageGridView } else { 「点击加载图片（共N张）」onTap → _loadManualImages = true }
```

**可达链:** main.dart → `/videoV` → reply_item_grpc._buildContent → _buildCommentImages。

**状态: compile-verified**

---

### 11. Stein 互动视频（steinResumeNode + showStein + interactiveChild）

**符号存在 + 消费点：**
```
lib/pages/video/controller.dart:1153  late final Rx<HistoryNode?> steinResumeNode   ← 进度恢复信号
lib/pages/video/controller.dart:1127  recordCurrentSteinNode() / :1137 steinHistory / :1205 goToSteinStoryNode()
lib/plugin/pl_player/view/view.dart:104/106  this.showStein / this.interactiveChild  ← PLVideoPlayer 参数
lib/plugin/pl_player/view/view.dart:130/131  final VoidCallback? showStein; final Widget? interactiveChild;
lib/plugin/pl_player/view/view.dart:608/617  BottomControlType.stein => ComBtn(... onTap: widget.showStein)  ← 「进度回溯」按钮
lib/plugin/pl_player/view/view.dart:1760     if (widget.interactiveChild != null) widget.interactiveChild!;
lib/pages/video/view.dart:2176              PLVideoPlayer 接线 showStein: _showSteinHistorySheet + interactiveChild: Obx(...)
  上游：_steinResumeWorker = ever(steinResumeNode, ...) → _showSteinResumeDialog（video/view.dart，T19）
lib/plugin/pl_player/models/bottom_control_type.dart  追加 stein 枚举值
```

**可达链:** main.dart → `/videoV` → VideoDetailPage/VideoDetailController（stein 逻辑）→ PLVideoPlayer(showStein/interactiveChild)。

**状态: compile-verified；runtime-pending（进度恢复弹框触发、回溯面板交互、选项点击更新——需真机播放 isSteinGate 视频）**

---

### 12. 图片屏蔽 pHash UI

**符号存在 + 消费点：**
```
lib/common/widgets/image_grid/image_grid_view.dart:123  await ImageBlockService.evaluateBlock(imgSrc)
lib/common/widgets/image_grid/image_grid_view.dart:163/309  ImageBlockService.addBlockedImage(...)
lib/common/widgets/image_grid/image_grid_view.dart:386  ImageBlockService.getCachedBlockResult(...)
lib/common/widgets/image_grid/image_grid_view.dart:75/86/104  tempUnblockedUrls 参数（临时解屏蔽）
lib/common/widgets/dialog/report.dart:17/135/137  onBlockImages 参数 + await onBlockImages(imageUrls)   ← 举报联动屏蔽
lib/common/widgets/image_viewer/gallery_viewer.dart  长按「屏蔽图片」（T20）
lib/pages/video/reply/widgets/reply_item_grpc.dart  tempUnblockedUrls + 屏蔽图片/恢复图片显示菜单 + report 传参
```

**可达链:** main.dart → `/videoV` → reply_item_grpc 图片区 → ImageGridView（pHash 评估）→ 屏蔽菜单；举报对话框 → onBlockImages。

**状态: compile-verified；runtime-pending（pHash 屏蔽评估/长按查看/举报联动 UX——算法本身已被 phash_cross_resolution_test 覆盖）**

---

### 13. 私信会话详情 + whisper 标为已读

**符号存在 + 消费点：**
```
lib/grpc/im.dart:242   static Future<LoadingState<SessionInfo>> sessionDetail({talkerId, sessionType, uid})
lib/grpc/url.dart:47   static const sessionDetail = '$im/SessionDetail';
lib/pages/whisper/widgets/item.dart:41-50  _updateAck: ImGrpc.sessionDetail → response.ackSeqno → MsgHttp.ackSessionMsg → toast「已标为已读」+ clearUnread
lib/pages/whisper/widgets/item.dart:102-104/143-144  「标为已读」长按菜单项 + 右键菜单项 → _updateAck
```

**可达链:** main.dart → `/whisper` → WhisperPage → whisper/item（长按「标为已读」）→ ImGrpc.sessionDetail。

**状态: compile-verified**

---

### 14. 直播反馈

**符号存在 + 消费点：**
```
lib/http/api.dart:1021   static const String liveFeedback = '.../xlive/app-interface/v2/index/feedback'
lib/http/live.dart:773   static Future<LoadingState<void>> liveFeedback(roomId, id, type, {page})
lib/http/live.dart:800   Api.liveFeedback
lib/pages/live/widgets/live_item_app.dart:92   final res = await LiveHttp.liveFeedback(...)   ← 卡片反馈按钮（more_vert → SimpleDialog 反馈原因）
lib/utils/accounts/api_type.dart  recommend 路由表含 Api.liveFeedback（T21）
```

**可达链:** main.dart → `/` → live tab → live_item_app 反馈按钮 → LiveHttp.liveFeedback。

**状态: compile-verified；runtime-pending（真实直播流提交反馈）**

---

### 15. 快速分享 + pmShare

**符号存在 + 消费点：**
```
lib/utils/request_utils.dart:73   static Future<bool> pmShare({...})（SelectableText 适配，无 SelectionText）
3 处 onLongPress 消费（onTap=actionShareVideo 保留，onLongPress 为新增并行手势）：
  lib/pages/video/widgets/header_control.dart:2193-2212   onLongPress → Pref.enableQuickShare 门控 → RequestUtils.pmShare(receiverId: Pref.quickShareId ?? ...)
  lib/pages/video/introduction/ugc/view.dart:532/547-548  同模式
  lib/pages/video/introduction/pgc/view.dart:450/466-467  同模式
lib/pages/setting/models/extra_settings.dart  快速分享给指定用户设置项（enableQuickShare/quickShareId）
```

**可达链:** main.dart → `/videoV` → header_control / ugc / pgc 分享按钮 onLongPress → RequestUtils.pmShare。

**状态: compile-verified；runtime-pending（长按分享 → 私信目标选择流程）**

---

### 16. 历史续播（progress 传递）

**符号存在 + 消费点：**
```
lib/pages/history/widgets/item.dart:42   final resumeProgress = switch (item.progress) { >0 => progress*1000, _ => null };
lib/pages/history/widgets/item.dart:78    PageUtils.viewPgc(epId:..., progress: resumeProgress)
lib/pages/history/widgets/item.dart:86    viewPgcFromUri(..., progress: resumeProgress)
lib/pages/history/widgets/item.dart:112   toVideoPage(..., progress: resumeProgress)
lib/pages/history/widgets/item.dart:182   progress: item.progress == -1 ...
lib/utils/page_utils.dart  viewPgc/toVideoPage 签名已含 progress（B 原已有）
```

**可达链:** main.dart → `/history` → HistoryPage → history/item → PageUtils.viewPgc/toVideoPage(progress) → `/videoV` 播放页续播。

**状态: compile-verified；runtime-pending（播放页跳转续播）**

---

### 17. SponsorBlock 无痕抑制

**符号存在 + 消费点：**
```
lib/pages/sponsor_block/block_mixin.dart:68    if (Pref.suppressSponsorBlockIncognito && MineController.anonymity.value) return;   ← 无痕不拉取
lib/pages/sponsor_block/block_mixin.dart:256   !(Pref.suppressSponsorBlockIncognito && MineController.anonymity.value)   ← 无痕不上报 viewedVideoSponsorTime
lib/pages/sponsor_block/block_mixin.dart:331   .catchError((e) { debugPrint(...) })   ← _doVote 兜底
lib/pages/setting/models/extra_settings.dart  「无痕模式不发送查询」SwitchModel（T29 补 UI 开关）
```

**可达链:** main.dart → `/videoV` → sponsor_block block_mixin（混入播放页）→ querySponsorBlock。

**状态: compile-verified**

---

### 18. 播放器快捷操作（长按倍速/比例、fastForBackwardDuration_、HDR 提示）

**符号存在 + 消费点：**
```
lib/plugin/pl_player/controller.dart:383-384  late final fastForBackwardDuration_ = Duration(seconds: Pref.fastForBackwardDuration_)   ← 独立快退时长
lib/plugin/pl_player/view/view.dart:2130      plPlayerController.fastForBackwardDuration_   ← BackwardSeekIndicator 使用
lib/plugin/pl_player/view/view.dart:594       onLongPress（fit 分支，contain↔cover 切换）
lib/plugin/pl_player/view/view.dart:704       onLongPress（speed 分支，1.0x↔2.0x 切换）
lib/plugin/pl_player/view/view.dart:874       onLongPress（qa 分支）
lib/plugin/pl_player/view/view.dart:939-941   newQa == VideoQuality.hdrVivid || dolbyVision || hdr → SDR 解析提示弹窗
```

**可达链:** main.dart → `/videoV` → PLVideoPlayer（view.dart）→ 倍速/比例/画质长按 + 快退指示器。

**状态: compile-verified；runtime-pending（长按切换、HDR/杜比提示弹窗需真机）**

---

### 19. selectable_region 替代 + ListExt.insertOrAdd + viewPugv(progress:)

**符号存在 + 消费点：**
```
lib/utils/extension/iterable_ext.dart:72   void insertOrAdd(int index, T element)
test/utils/extension_test.dart:89-110      4 个 insertOrAdd 断言（24/24 PASS，T27）
lib/utils/page_utils.dart:745-751           viewPugv({seasonId, epId, aid, int? progress, off})  ← progress 参数恢复
lib/utils/page_utils.dart:775               toVideoPage(..., progress: progress)   ← 透传
lib/pages/dynamics/widgets/content_panel.dart:122-123   「打开」按钮 → PageUtils.launchURL(selected)   ← SelectableText 菜单（替代 selectable_region_ext）
lib/pages/video/reply/widgets/reply_item_grpc.dart:1716-1717  「打开」按钮 → PageUtils.launchURL(selected)
  选区文本 = state.textEditingValue.selection.textInside(...)，全公共 API（T4 决策落地）
```

**可达链:** main.dart → `/videoV`/动态 → content_panel/reply_item_grpc 的 SelectableText contextMenuBuilder（「打开」）→ PageUtils.launchURL；课程视频 viewPugv(progress:)。

**状态: compile-verified；runtime-pending（长按选中文本→「打开」菜单 UI、课程续播跳转）**

---

## 补充锚点确认（非 19 主表，但属 W 锚点表/计划功能，均无孤儿）

| 符号 | 位置 | 消费点 | 状态 |
|------|------|--------|------|
| `videoPush` 换源 | lib/http/video.dart:307 `PiliScheme.videoPush(null, bvid, showDialog: false)` | videoUrl() code!=0 且 bvid 匹配 → SmartDialog「视频可能换源」弹窗 | compile-verified + runtime-pending |
| `hideStatusBar` | lib/plugin/pl_player/controller.dart `triggerFullScreen` 退出全屏按 Pref.hideStatusBar 显隐 | 播放页全屏状态栏 | compile-verified + runtime-pending |
| `showHomeRefreshFab` / `showClipboardSearch` | lib/pages/home/view.dart:80/107/218 | 首页 FAB + 剪贴板搜索按钮 | compile-verified |
| `showDynamicsRefreshFab` | lib/pages/dynamics/view.dart:173/223 | 动态页 FAB | compile-verified |
| 下载按 UP 过滤 | lib/pages/download/search/controller.dart:36 `e.ownerName?.toLowerCase().contains(text)` | 下载搜索过滤 | compile-verified |
| 保存评论图原文 | lib/pages/save_panel/view.dart `forceShowOriginalContent: true` → ReplyItemGrpc | 保存评论图不折叠 | compile-verified |
| 设置项恢复 | extra_settings.dart：AI 组/评论区AI翻译/申诉理由/图片保存路径/快速分享目标/港澳台代理 URL + 账号选择器昵称 | 均写 Pref + 消费点（T11/T13/T15/T22 验证） | compile-verified |

---

## Runtime-pending 汇总（仅设备可验证，无设备不虚标）

| 功能 | 说明 |
|------|------|
| Stein（F8/T18-19） | 进度恢复弹框触发、回溯面板交互、选项点击后选项条更新（需 isSteinGate 真机视频） |
| 播放器（F15/T25 + 续播 + 状态栏 + 换源） | 长按倍速/比例、HDR/杜比提示、快退双时长、续播跳转、状态栏显隐、-404 换源弹窗 |
| 直播反馈（F11/T21） | 真实直播流提交反馈 |
| 快速分享（F12/T22） | 长按分享 → 私信目标选择 |
| 图片 pHash 屏蔽 UX（F9/T20） | 屏蔽/临时解屏蔽菜单交互 |
| selectable_region「打开」菜单（F17/T27） | 长按选中文本 → 「打开」→ 外部分流 |
| 历史续播跳转（F13/T23） | 播放页续播 |
| 无痕空降抑制（F13/T23） | 登录 + 无痕 + 开开关后验证不查 SponsorBlock 服务器 |

> 以上按 batch0-smoke-plan §三 清单如实标注；编译 + analyze + 符号接线已全部通过。

---

## 验收核对

- [x] 19 功能族逐一验证（符号 + 消费点双重 grep，全部真实命中）
- [x] `.sisyphus/evidence/batch5-wiring.md` 生成（本文件）
- [x] 无「已移植但未接线」功能（19/19 + 补充锚点全部有消费点）
- [x] 未修改任何代码（纯验证）
