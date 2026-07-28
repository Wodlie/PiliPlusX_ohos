import 'package:PiliPlus/utils/accounts/identity_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdentityOwnerKey', () {
    test('guest key has correct kind and key value', () {
      final guest = const IdentityOwnerKey.guest();
      expect(guest.kind, IdentityOwnerKind.guest);
      expect(guest.key, 'guest');
      expect(guest.isPersistent, isTrue);
      expect(guest.isWorkflowOnly, isFalse);
    });

    test('account key requires positive mid', () {
      expect(() => IdentityOwnerKey.account(0), throwsArgumentError);
      expect(() => IdentityOwnerKey.account(-1), throwsArgumentError);
      final account = IdentityOwnerKey.account(1001);
      expect(account.kind, IdentityOwnerKind.account);
      expect(account.key, 'account:1001');
      expect(account.isPersistent, isTrue);
    });

    test('workflow key requires non-empty scope', () {
      expect(() => IdentityOwnerKey.workflow(''), throwsArgumentError);
      final workflow = IdentityOwnerKey.workflow('test-scope');
      expect(workflow.kind, IdentityOwnerKind.workflow);
      expect(workflow.key, 'workflow:test-scope');
      expect(workflow.isPersistent, isFalse);
      expect(workflow.isWorkflowOnly, isTrue);
    });
  });

  group('IdentityCoreProfile', () {
    test('rejects empty buvid', () {
      expect(
        () => IdentityCoreProfile(
          owner: const IdentityOwnerKey.guest(),
          buvid: '',
        ),
        throwsArgumentError,
      );
      expect(
        () => IdentityCoreProfile(
          owner: const IdentityOwnerKey.guest(),
          buvid: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('trims buvid whitespace', () {
      final profile = IdentityCoreProfile(
        owner: const IdentityOwnerKey.guest(),
        buvid: '  XYAABBCCDDEEFFGGHHIIJJKKLLMMNNOOPP  ',
      );
      expect(profile.buvid, 'XYAABBCCDDEEFFGGHHIIJJKKLLMMNNOOPP');
    });

    test('copyWith preserves values', () {
      final original = IdentityCoreProfile(
        owner: IdentityOwnerKey.account(42),
        buvid: 'XY1234567890ABCDEF1234567890ABCDEF12',
      );
      final copied = original.copyWith();
      expect(copied.owner.key, original.owner.key);
      expect(copied.buvid, original.buvid);

      final modified = original.copyWith(buvid: 'XUMODIFIEDBUVID0000000000000000000');
      expect(modified.owner.key, original.owner.key);
      expect(modified.buvid, 'XUMODIFIEDBUVID0000000000000000000');
    });
  });

  group('BUVID generation and validation', () {
    test('deriveBuvidFromSeed produces valid 37-char BUVID', () {
      final buvid = IdentityCoreGenerators.deriveBuvidFromSeed('test-seed');
      expect(buvid.length, 37);
      expect(buvid, equals(buvid.toUpperCase()));
      expect(IdentityCoreGenerators.validateBuvid(buvid).isValid, isTrue);
    });

    test('validateBuvid accepts valid BUVID', () {
      final buvid = IdentityCoreGenerators.deriveBuvidFromSeed('VALIDATION-TEST');
      final result = IdentityCoreGenerators.validateBuvid(buvid);
      expect(result.isValid, isTrue);
    });

    test('validateBuvid rejects malformed BUVID', () {
      expect(
        IdentityCoreGenerators.validateBuvid('').isValid,
        isFalse,
      );
      expect(
        IdentityCoreGenerators.validateBuvid('SHORT').isValid,
        isFalse,
      );
      expect(
        IdentityCoreGenerators.validateBuvid('XY11111111111111111111111111111111111')
            .isValid,
        isFalse,
      );
    });

    test('generateBuvid creates valid BUVID using guest owner', () {
      final buvid = IdentityCoreGenerators.generateBuvid();
      expect(
        IdentityCoreGenerators.validateBuvid(buvid).isValid,
        isTrue,
      );
      // Should match guest seed
      final guestBuvid = IdentityCoreGenerators.generateBuvidForOwner(
        const IdentityOwnerKey.guest(),
      );
      expect(buvid, guestBuvid);
    });

    test('different owners produce different BUVIDs', () {
      final guestBuvid = IdentityCoreGenerators.generateBuvidForOwner(
        const IdentityOwnerKey.guest(),
      );
      final accountBuvid = IdentityCoreGenerators.generateBuvidForOwner(
        IdentityOwnerKey.account(42),
      );
      expect(guestBuvid, isNot(accountBuvid));
    });

    test('same owner produces stable BUVID', () {
      final first = IdentityCoreGenerators.generateBuvidForOwner(
        IdentityOwnerKey.account(7701),
      );
      final second = IdentityCoreGenerators.generateBuvidForOwner(
        IdentityOwnerKey.account(7701),
      );
      expect(first, second);
    });
  });

  group('Derived profile generation', () {
    test('deriveProfile generates all required fields', () {
      final derived = IdentityCoreGenerators.deriveProfile(
        owner: IdentityOwnerKey.account(2048),
        now: DateTime.utc(2026, 6, 1, 12, 0, 0),
      );

      expect(derived.profile.owner.key, 'account:2048');
      expect(derived.profile.buvid.length, 37);
      expect(derived.buvid3, isNotEmpty);
      expect(derived.deviceId.length, 34);
      expect(derived.sessionId.length, 8);
      expect(derived.traceId, contains(':0:0'));
      expect(derived.fpLocal.length, 64);
      expect(derived.fpRemote, derived.fpLocal);

      expect(
        IdentityCoreGenerators.validateBuvid(derived.profile.buvid).isValid,
        isTrue,
      );
      expect(
        IdentityCoreGenerators.validateBuvid3(derived.buvid3).isValid,
        isTrue,
      );
      expect(
        IdentityCoreGenerators.validateDeviceLocalId(derived.deviceId).isValid,
        isTrue,
      );
      expect(
        IdentityCoreGenerators.validateSessionId(derived.sessionId).isValid,
        isTrue,
      );
      expect(
        IdentityCoreGenerators.validateTraceId(derived.traceId).isValid,
        isTrue,
      );
      expect(
        IdentityCoreGenerators.validateFp(derived.fpLocal).isValid,
        isTrue,
      );
    });

    test('deriveProfile reuses valid stored profile', () {
      final owner = IdentityOwnerKey.account(1001);
      final storedBuvid = IdentityCoreGenerators.deriveBuvidFromSeed('stored');
      final storedProfile = IdentityCoreProfile(owner: owner, buvid: storedBuvid);

      final derived = IdentityCoreGenerators.deriveProfile(
        owner: owner,
        storedProfile: storedProfile,
      );

      expect(derived.profile.buvid, storedBuvid);
    });
  });

  group('Profile generator and validator', () {
    test('generator reuses valid stored profile for same owner', () {
      final owner = IdentityOwnerKey.account(1001);
      final storedProfile = IdentityCoreProfile(
        owner: owner,
        buvid: IdentityCoreGenerators.deriveBuvidFromSeed('AABBCCDDEEFF'),
      );

      final generated = const IdentityCoreProfileGenerator().generate(
        IdentityCoreGenerationContext(
          owner: owner,
          storedProfile: storedProfile,
        ),
      );

      expect(generated.owner.key, owner.key);
      expect(generated.buvid, storedProfile.buvid);
      expect(
        const IdentityCoreProfileValidator().validate(generated).isValid,
        isTrue,
      );
    });

    test('generator regenerates when owner changes', () {
      final guestOwner = const IdentityOwnerKey.guest();
      final accountOwner = IdentityOwnerKey.account(1002);
      final storedProfile = IdentityCoreProfile(
        owner: guestOwner,
        buvid: IdentityCoreGenerators.deriveBuvidFromSeed('001122334455'),
      );

      final generated = const IdentityCoreProfileGenerator().generate(
        IdentityCoreGenerationContext(
          owner: accountOwner,
          storedProfile: storedProfile,
        ),
      );

      expect(generated.owner.key, accountOwner.key);
      expect(generated.buvid, isNot(storedProfile.buvid));
      expect(
        IdentityCoreGenerators.validateBuvid(generated.buvid).isValid,
        isTrue,
      );
    });

    test('validator rejects profile with invalid BUVID', () {
      final profile = IdentityCoreProfile(
        owner: const IdentityOwnerKey.guest(),
        buvid: IdentityCoreGenerators.deriveBuvidFromSeed('test'),
      );
      expect(
        const IdentityCoreProfileValidator().validate(profile).isValid,
        isTrue,
      );

      final invalidProfile = IdentityCoreProfile(
        owner: const IdentityOwnerKey.guest(),
        buvid: 'INVALID',
      );
      expect(
        const IdentityCoreProfileValidator().validate(invalidProfile).isValid,
        isFalse,
      );
    });
  });

  group('buvid3 validation', () {
    test('generated buvid3 is valid', () {
      final buvid3 = IdentityCoreGenerators.generateBuvid3();
      expect(
        IdentityCoreGenerators.validateBuvid3(buvid3).isValid,
        isTrue,
      );
    });
  });

  group('traceId validation', () {
    test('generated traceId is valid', () {
      final traceId = IdentityCoreGenerators.generateTraceId(
        now: DateTime.utc(2026, 5, 6, 12, 0, 0),
      );
      expect(
        IdentityCoreGenerators.validateTraceId(traceId).isValid,
        isTrue,
      );
    });
  });

  group('sessionId validation', () {
    test('generated sessionId is valid', () {
      final sessionId = IdentityCoreGenerators.generateSessionId();
      expect(
        IdentityCoreGenerators.validateSessionId(sessionId).isValid,
        isTrue,
      );
    });
  });

  group('deviceLocalId validation', () {
    test('generated deviceLocalId is valid and owner-scoped', () {
      final guestBuvid = IdentityCoreGenerators.deriveBuvidFromSeed('guest');
      final accountBuvid = IdentityCoreGenerators.deriveBuvidFromSeed('account');

      final guestDeviceId = IdentityCoreGenerators.generateDeviceLocalId(
        owner: const IdentityOwnerKey.guest(),
        buvid: guestBuvid,
      );
      final accountDeviceId = IdentityCoreGenerators.generateDeviceLocalId(
        owner: IdentityOwnerKey.account(42),
        buvid: accountBuvid,
      );

      expect(
        IdentityCoreGenerators.validateDeviceLocalId(guestDeviceId).isValid,
        isTrue,
      );
      expect(
        IdentityCoreGenerators.validateDeviceLocalId(accountDeviceId).isValid,
        isTrue,
      );
      expect(guestDeviceId, isNot(accountDeviceId));
    });
  });

  group('fp validation', () {
    test('generated fp is valid', () {
      final fp = IdentityCoreGenerators.generateFp(
        owner: IdentityOwnerKey.account(2048),
        buvid: IdentityCoreGenerators.deriveBuvidFromSeed('C0FFEE2048'),
        now: DateTime.utc(2026, 5, 6, 11, 22, 33),
      );

      expect(IdentityCoreGenerators.validateFp(fp).isValid, isTrue);
    });
  });
}
