# Test Infrastructure — TDD Workflow

## RED → GREEN → REFACTOR

This project follows **test-driven development (TDD)**. Every feature starts with a failing test.

### Workflow

1. **RED** — Write a test that fails (the feature doesn't exist yet).
2. **GREEN** — Write the minimum implementation to make the test pass.
3. **REFACTOR** — Clean up the implementation while keeping tests green.

```dart
// 1. RED — write a failing test
test('myFeature does the thing', () {
  expect(myFeature(), equals('expected result'));
});

// 2. GREEN — implement the minimum code
String myFeature() => 'expected result';

// 3. REFACTOR — improve without breaking the test
String myFeature() {
  // cleaner implementation
  return 'expected result';
}
```

## Running Tests

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/path/to/my_test.dart

# Run tests matching a name
flutter test --name "myFeature"

# Run with verbose output
flutter test --reporter expanded
```

## Test Directory Layout

```
test/
├── smoke_test.dart                 # Basic smoke test (always passes)
├── block_reason_test.dart          # Reply blocking reason logic
├── blocked_reply_banner_test.dart  # Blocked reply banner UI
├── blocked_reply_filter_test.dart  # Reply filtering modes (banner/remove)
├── buvid_lifecycle_test.dart       # BUVID lifecycle (guest/login)
├── connectivity_utils_test.dart    # Connectivity error handling
├── grpc_identity_test.dart         # gRPC identity headers
├── identity_migration_test.dart    # Identity migration from legacy
├── identity_profile_test.dart      # Identity core generators
├── image_block_service_test.dart   # Image blocking service
├── lru_cache_test.dart             # LRU cache data structure
├── phash_cross_resolution_test.dart# pHash consistency across resolutions
├── platform_utils_test.dart        # Platform detection utilities
├── request_identity_adapters_test.dart # Request identity adapters
├── storage_key_test.dart           # Storage key constants
├── video_summary_failure_states_test.dart  # AI summary failure states
├── video_summary_routing_test.dart # AI summary router contracts
├── video_summary_settings_test.dart# AI summary provider settings
├── video_summary_ugc_widget_test.dart # UGC AI summary widgets
├── web_gaia_identity_test.dart     # Web Gaia identity fields
├── fixtures/                       # Test fixtures (images, etc.)
│   ├── image_full.png
│   ├── image_thumb_100w_q10.jpg
│   ├── image2_full.png
│   └── image2_thumb_100w_q10.jpg
├── utils/                          # Utility tests
├── http/                           # HTTP-related tests
├── grpc/                           # gRPC-related tests
├── models/                         # Model tests
├── pages/                          # Page/widget tests
├── helpers/                        # Test helpers
└── widgets/                        # Widget tests
    └── image_grid_view_test.dart
```

## Conventions

- Use `package:PiliPlus/` imports (not relative paths).
- Always use `TestWidgetsFlutterBinding.ensureInitialized()` when Hive storage is needed.
- Clean up temp directories in `tearDownAll`.
- Prefer `group()` for logical test organization.
- Follow the existing test patterns — they mirror the app's structure under `lib/`.

## Ported Tests

All tests in this directory were ported from the upstream `PiliPlusX` project. Tests depending on `jni`/`jnigen`/Android-specific packages were excluded. See `.sisyphus/notepads/test-infra/learnings.md` for the porting record.
