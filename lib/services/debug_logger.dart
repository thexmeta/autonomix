import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Debug logger for tracking settings persistence issues
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  static const String _logFileName = 'autonomix_debug.log';
  File? _logFile;
  final List<String> _buffer = [];
  bool _initialized = false;

  /// Initialize the logger
  Future<void> _init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _logFile = File(path.join(dir.path, _logFileName));
      _initialized = true;
      _flushBuffer();
    } catch (e) {
      print('[DebugLogger] Failed to initialize: $e');
    }
  }

  /// Flush buffered logs
  Future<void> _flushBuffer() async {
    if (_logFile == null || _buffer.isEmpty) return;
    try {
      final content = _buffer.join('\n') + '\n';
      await _logFile!.writeAsString(content, mode: FileMode.append);
      _buffer.clear();
    } catch (e) {
      print('[DebugLogger] Failed to write log: $e');
    }
  }

  /// Log a message
  Future<void> log(String category, String message, {Map<String, dynamic>? data}) async {
    await _init();
    final timestamp = DateTime.now().toString().substring(0, 19);
    var logMsg = '[$timestamp] [$category] $message';
    if (data != null && data.isNotEmpty) {
      logMsg += ' | Data: ${data.map((k, v) => MapEntry(k, v.toString())).entries.map((e) => '${e.key}=${e.value}').join(', ')}';
    }
    
    // Add to buffer
    _buffer.add(logMsg);
    
    // Write immediately for critical debugging
    if (_logFile != null && _initialized) {
      await _flushBuffer();
    }
  }

  /// Clear the log file
  Future<void> clear() async {
    await _init();
    if (_logFile != null) {
      await _logFile!.writeAsString('');
    }
  }

  /// Get log file path
  Future<String?> getLogFilePath() async {
    await _init();
    return _logFile?.path;
  }
}

// Convenience functions
Future<void> dlog(String category, String message, {Map<String, dynamic>? data}) =>
    DebugLogger().log(category, message, data: data);

Future<void> dlogClear() => DebugLogger().clear();

Future<String?> dlogPath() => DebugLogger().getLogFilePath();
