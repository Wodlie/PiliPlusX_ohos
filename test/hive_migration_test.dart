import 'dart:io';

import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/accounts/account_adapter.dart';
import 'package:PiliPlus/utils/accounts/account_migration.dart';
import 'package:PiliPlus/utils/accounts/account_type_adapter.dart';
import 'package:PiliPlus/utils/accounts/app_device_profile.dart';
import 'package:PiliPlus/utils/accounts/cookie_jar_adapter.dart';
import 'package:PiliPlus/utils/accounts/identity_core.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// 旧 4 字段 LoginAccountAdapter 副本（模拟 T6 之前的 B 写入格式）：
/// writeByte(4) + 仅 field 0=cookieJar / 1=accessKey / 2=refresh / 3=type。
class _LegacyLoginAccountAdapterV4 extends TypeAdapter<LoginAccount> {
  @override
  final int typeId = 9;

  @override
  LoginAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoginAccount(
      fields[0] as DefaultCookieJar,
      fields[1] as String?,
      fields[2] as String?,
      (fields[3] as List?)?.cast<AccountType>().toSet(),
    );
  }

  @override
  void write(BinaryWriter writer, LoginAccount obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.cookieJar)
      ..writeByte(1)
      ..write(obj.accessKey)
      ..writeByte(2)
      ..write(obj.refresh)
      ..writeByte(3)
      ..write(obj.type.toList());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LegacyLoginAccountAdapterV4 &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_migration_test_');
    Hive
      ..init(tempDir.path)
      ..registerAdapter(BiliCookieJarAdapter())
      ..registerAdapter(AccountTypeAdapter())
      ..registerAdapter(AppDeviceProfileAdapter())
      ..registerAdapter(LoginAccountAdapter());
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 用旧 4 字段 adapter 写入 [records]（typeId 9 序列化），随后换回新
  /// 6 字段 adapter——完整模拟「B 旧版本写入 → 升级后用新版本重开」。
  Future<void> writeLegacyBox(
    String boxName,
    Map<String, LoginAccount> records,
  ) async {
    Hive.registerAdapter(_LegacyLoginAccountAdapterV4(), override: true);
    final box = await Hive.openBox<LoginAccount>(boxName);
    await box.putAll(records);
    await box.close();
    Hive.registerAdapter(LoginAccountAdapter(), override: true);
  }

  String buvid3Of(DefaultCookieJar jar) =>
      jar.domainCookies['bilibili.com']!['/']!['buvid3']!.cookie.value;

  group('4→6 hive migration', () {
    test(
      'old 4-field records decode without crash and migrate to 6 fields with cookie buvid3 seed',
      () async {
        const boxName = 'migrate_old_records';
        const buvid3_2001 = '0123456789ABCDEF0123456789ABCDEF12345infoc';
        const buvid3_2002 = 'FEDCBA9876543210FEDCBA987654321098765infoc';
        final jar2001 = _createCookieJar(
          mid: 2001,
          buvid3: buvid3_2001,
        );
        final jar2002 = _createCookieJar(
          mid: 2002,
          buvid3: buvid3_2002,
        );
        await writeLegacyBox(boxName, {
          '2001': LoginAccount(
            jar2001,
            'ACCESS_KEY_2001',
            'REFRESH_2001',
            {AccountType.main},
          ),
          '2002': LoginAccount(
            jar2002,
            'ACCESS_KEY_2002',
            'REFRESH_2002',
            {
              AccountType.recommend,
              AccountType.heartbeat,
              AccountType.video,
            },
          ),
        });

        final box = await Hive.openBox<LoginAccount>(boxName);

        final decoded2001 = box.get('2001')!;
        expect(decoded2001.accessKey, 'ACCESS_KEY_2001');
        expect(decoded2001.type, {AccountType.main});
        expect(decoded2001.deviceProfile, isNull);
        expect(decoded2001.needsBuvidPersist, isTrue,
            reason: '旧 4 字段记录缺 field4/field5，须标记待回填');
        final decoded2002 = box.get('2002')!;
        expect(decoded2002.type, {
          AccountType.recommend,
          AccountType.heartbeat,
          AccountType.video,
        });
        expect(decoded2002.needsBuvidPersist, isTrue);

        final migrated = await migrateAccountBoxV4ToV6(box);
        expect(migrated, 2);

        final persisted2001 = box.get('2001')!;
        expect(persisted2001.buvid, buvid3_2001,
            reason: 'field4 须与 cookie buvid3 逐字节一致（方案 A，线上头不漂移）');
        expect(persisted2001.deviceProfile, isNotNull);
        expect(
          persisted2001.deviceProfile,
          AppDeviceProfiles.defaultDeviceProfileForOwner('account:2001'),
        );
        expect(persisted2001.deviceProfile!.hasGenericPlaceholderFields, isFalse);
        expect(persisted2001.needsBuvidPersist, isFalse);
        expect(persisted2001.accessKey, 'ACCESS_KEY_2001');
        expect(persisted2001.type, {AccountType.main});

        final persisted2002 = box.get('2002')!;
        expect(persisted2002.buvid, buvid3_2002);
        expect(persisted2002.deviceProfile, isNotNull);
        expect(persisted2002.type, {
          AccountType.recommend,
          AccountType.heartbeat,
          AccountType.video,
        });
        await box.close();
      },
    );

    test('migration is idempotent (second run returns 0)', () async {
      const boxName = 'migrate_idempotent';
      await writeLegacyBox(boxName, {
        '2006': LoginAccount(
          _createCookieJar(mid: 2006, buvid3: 'ABCDEF0123456789ABCDEF012345678901234infoc'),
          'ACCESS_KEY_2006',
          'REFRESH_2006',
          {AccountType.main},
        ),
      });

      final box = await Hive.openBox<LoginAccount>(boxName);
      expect(await migrateAccountBoxV4ToV6(box), 1);
      expect(await migrateAccountBoxV4ToV6(box), 0,
          reason: '已 6 字段且 needsBuvidPersist==false 的记录必须跳过');
      await box.close();
    });

    test('empty account box migrates to 0 without side effects', () async {
      final box = await Hive.openBox<LoginAccount>('migrate_empty_box');
      expect(await migrateAccountBoxV4ToV6(box), 0);
      expect(box.length, 0);
      await box.close();
    });

    test(
      'missing buvid3 cookie falls back to a fresh generated buvid3 seed without crashing',
      () async {
        const boxName = 'migrate_missing_buvid3';
        final jar = _createCookieJar(mid: 2003, buvid3: null);
        final account = LoginAccount(
          jar,
          'ACCESS_KEY_2003',
          'REFRESH_2003',
          {AccountType.main},
        );
        // 构造期 setBuvid3 已写入 buvid3；移除它以模拟损坏/缺失 cookie 状态。
        jar.domainCookies['bilibili.com']!['/']!.remove('buvid3');
        await writeLegacyBox(boxName, {'2003': account});

        final box = await Hive.openBox<LoginAccount>(boxName);
        expect(box.get('2003')!.needsBuvidPersist, isTrue);

        expect(await migrateAccountBoxV4ToV6(box), 1);

        final persisted = box.get('2003')!;
        expect(persisted.buvid, isNotEmpty);
        expect(
          persisted.buvid,
          buvid3Of(persisted.cookieJar),
          reason: '缺 buvid3 时现场生成并作为 field4 落盘',
        );
        expect(
          IdentityCoreGenerators.validateBuvid3(persisted.buvid).isValid,
          isTrue,
        );
        expect(persisted.deviceProfile, isNotNull);
        expect(persisted.needsBuvidPersist, isFalse);
        await box.close();
      },
    );

    test(
      'already-migrated 6-field records are skipped and their buvid is not overwritten',
      () async {
        const boxName = 'migrate_already_six';
        final storedBuvid = IdentityCoreGenerators.deriveBuvidFromSeed(
          'stored-2005',
        );
        final storedProfile = AppDeviceProfile(
          brand: 'Xiaomi',
          model: '23046RP50C',
          osver: '15',
        );
        final jar = _createCookieJar(mid: 2005);
        final account = LoginAccount(
          jar,
          'ACCESS_KEY_2005',
          'REFRESH_2005',
          {AccountType.main},
          storedBuvid,
          storedProfile,
        );

        final box = await Hive.openBox<LoginAccount>(boxName);
        await box.put('2005', account);
        await box.close();

        final reopened = await Hive.openBox<LoginAccount>(boxName);
        expect(reopened.get('2005')!.needsBuvidPersist, isFalse);
        expect(reopened.get('2005')!.buvid, storedBuvid);

        expect(await migrateAccountBoxV4ToV6(reopened), 0);

        expect(reopened.get('2005')!.buvid, storedBuvid,
            reason: '已 6 字段记录不得被迁移覆盖');
        expect(reopened.get('2005')!.deviceProfile, storedProfile);
        await reopened.close();
      },
    );
  });
}

DefaultCookieJar _createCookieJar({
  required int mid,
  String? buvid3 = '0123456789ABCDEF0123456789ABCDEF00000infoc',
}) {
  final cookieJar = DefaultCookieJar(ignoreExpires: true);
  final cookies = <Cookie>[
    Cookie('DedeUserID', '$mid')..setBiliDomain(),
    Cookie('bili_jct', 'csrf_$mid')..setBiliDomain(),
    Cookie('SESSDATA', 'sess_$mid')..setBiliDomain(),
    if (buvid3 != null) Cookie('buvid3', buvid3)..setBiliDomain(),
  ];
  cookieJar.domainCookies['bilibili.com'] = {
    '/': {
      for (final cookie in cookies) cookie.name: SerializableCookie(cookie),
    },
  };
  return cookieJar;
}
