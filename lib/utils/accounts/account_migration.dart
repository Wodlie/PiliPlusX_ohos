import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:hive_ce/hive.dart';

/// 4→6 schema 迁移：把 B 旧 4 字段 `LoginAccount` 记录回填为 6 字段。
/// - field4 buvid：优先取账号 cookie 的 buvid3（保持升级前后线上 `buvid:` 头
///   逐字节不变），缺 buvid3 时回退旧 `buvid` cookie，否则现场生成稳定值。
/// - field5 deviceProfile：`AppDeviceProfiles.defaultDeviceProfileForOwner`。
/// 幂等：已 6 字段（[LoginAccount.needsBuvidPersist] == false）的记录跳过；
/// 重复执行返回 0。
/// 返回迁移条数。
Future<int> migrateAccountBoxV4ToV6(Box<LoginAccount> box) async {
  var migrated = 0;
  for (final key in box.keys) {
    final record = box.get(key);
    if (record == null) continue;
    if (!record.needsBuvidPersist) continue;
    await box.put(key, record.seededMigrationCopy());
    migrated++;
  }
  return migrated;
}
