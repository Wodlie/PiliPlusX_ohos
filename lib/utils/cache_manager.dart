import 'dart:io' show Directory, File;

import 'package:PiliPlus/utils/path_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract final class CacheManager {
  /// Singleton DefaultCacheManager instance for file cache lookups.
  /// Uses the pub.dev DefaultCacheManager which lazily initializes.
  static final DefaultCacheManager manager = DefaultCacheManager();

  // 获取缓存目录
  @pragma('vm:notify-debugger-on-exception')
  static Future<int> loadApplicationCache() async {
    try {
      if (PlatformUtils.isDesktop) {
        return _legacyCacheSize();
      }

      final Directory tempDirectory = await getTemporaryDirectory();
      if (tempDirectory.existsSync()) {
        return await getTotalSizeOfFilesInDir(tempDirectory);
      }
    } catch (_) {}
    return 0;
  }

  /// Fallback cache size calculation for desktop platforms where
  /// DefaultCacheManager's cache directory may differ from temp.
  static Future<int> _legacyCacheSize() async {
    try {
      final Directory tempDirectory = await getTemporaryDirectory();
      final dir = Directory('${tempDirectory.path}/cached_network_image_ce');
      if (dir.existsSync()) {
        return await getTotalSizeOfFilesInDir(dir);
      }
    } catch (_) {}
    return 0;
  }

  // 循环计算文件的大小
  @pragma('vm:notify-debugger-on-exception')
  static Future<int> getTotalSizeOfFilesInDir(
    final Directory file, [
    final num maxSize = double.infinity,
  ]) async {
    int total = 0;
    await for (final child in file.list(recursive: true)) {
      if (child is File) {
        total += await child.length();
        if (total >= maxSize) break;
      }
    }
    return total;
  }

  // 缓存大小格式转换
  static String formatSize(num value) {
    const unitArr = ['B', 'K', 'M', 'G', 'T', 'P'];
    int index = 0;
    while (value >= 1024) {
      index++;
      value = value / 1024;
    }
    String size = value.toStringAsFixed(2);
    return size + (unitArr.elementAtOrNull(index) ?? '');
  }

  // 清除 Library/Caches 目录及文件缓存
  @pragma('vm:notify-debugger-on-exception')
  static Future<void> clearLibraryCache() async {
    try {
      await manager.emptyCache();
      try {
        final blockedDir = Directory(
          path.join(appSupportDirPath, 'blocked_images'),
        );
        if (blockedDir.existsSync()) {
          await blockedDir.delete(recursive: true);
        }
      } catch (_) {}
      if (PlatformUtils.isDesktop) return;

      final tempDirectory = await getTemporaryDirectory();
      if (tempDirectory.existsSync()) {
        await for (final file in tempDirectory.list(recursive: false)) {
          if (file is Directory &&
              path.basename(file.path) == 'cached_network_image_ce') {
            continue;
          }
          await file.delete(recursive: true);
        }
      }
    } catch (_) {}
  }

  static Future<void> autoClearCache() async {
    if (Pref.autoClearCache) {
      await clearLibraryCache();
    } else {
      final maxCacheSize = Pref.maxCacheSize;
      if (maxCacheSize != 0) {
        final currCache = await loadApplicationCache();
        if (currCache >= maxCacheSize) {
          await clearLibraryCache();
        }
      }
    }
  }
}
