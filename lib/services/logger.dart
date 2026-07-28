import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/utils/json_file_handler.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final logger = PiliLogger();

class PiliLogger extends Logger {
  PiliLogger() : super();

  @override
  void log(
    Level level,
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    if (level == Level.error || level == Level.fatal) {
      _writeToLogFile(level, message,
          error: error, stackTrace: stackTrace, time: time);
    }
    super.log(level, message, error: error, stackTrace: stackTrace, time: time);
  }

  Future<void> _writeToLogFile(
    Level level,
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) async {
    try {
      if (!Pref.enableLog) return;
      final file = await LoggerUtils.getLogsPath();
      final entry = {
        'level': level.toString(),
        'message': message?.toString(),
        'error': error?.toString(),
        'stackTrace': stackTrace?.toString(),
        'time': (time ?? DateTime.now()).toIso8601String(),
      };
      await file.writeAsString(
        '${jsonEncode(entry)}\n',
        mode: FileMode.writeOnlyAppend,
      );
    } catch (_) {
      // Silently fail — logging should never crash the app
    }
  }
}

abstract final class LoggerUtils {
  static File? _logFile;

  static Future<File> getLogsPath() async {
    if (_logFile != null) return _logFile!;

    String dir = (await getApplicationDocumentsDirectory()).path;
    final String filename = p.join(dir, '.pili_logs.json');
    final File file = File(filename);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    return _logFile = file;
  }

  static Future<bool> clearLogs() async {
    try {
      if (Pref.enableLog) {
        await JsonFileHandler.add(
          (raf) => raf.setPosition(0).then((raf) => raf.truncate(0)),
        );
      } else {
        final file = await getLogsPath();
        await file.writeAsBytes(const [], flush: true);
      }
    } catch (e) {
      return false;
    }
    return true;
  }
}
