import 'package:PiliPlus/grpc/reply.dart';
import 'package:PiliPlus/models/dynamics/result.dart' show DynamicsDataModel;
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Block/filter related settings items.
///
/// These settings can be imported and concatenated into other setting models
/// (e.g., extra settings) or used independently.
List<SettingsModel> get blockFilterSettings => [
  NormalModel(
    title: '低质量 @ 评论过滤',
    subtitle: '点击配置过滤规则',
    leading: const Icon(Icons.alternate_email),
    onTap: (context, setState) => Get.toNamed('/atFilter'),
  ),
  NormalModel(
    title: '屏蔽图片设置',
    subtitle: '管理已屏蔽图片的 pHash 列表',
    leading: const Icon(Icons.block),
    onTap: (context, setState) => Get.toNamed('/imageBlockSetting'),
  ),
  getBanWordModel(
    title: '评论关键词过滤',
    key: SettingBoxKey.banWordForReply,
    onChanged: (value) {
      ReplyGrpc.replyRegExp = value;
      ReplyGrpc.enableFilter = value.pattern.isNotEmpty;
    },
  ),
  getBanWordModel(
    title: '动态关键词过滤',
    key: SettingBoxKey.banWordForDyn,
    onChanged: (value) {
      DynamicsDataModel.banWordForDyn = value;
      DynamicsDataModel.enableFilter = value.pattern.isNotEmpty;
    },
  ),
];
