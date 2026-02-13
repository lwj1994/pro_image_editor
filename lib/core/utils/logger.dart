import 'package:flutter/foundation.dart';

/// A lightweight debug logger that only prints in debug mode.
class Logger {
  const Logger._(this.tag);

  /// Global runtime switch for package logs.
  ///
  /// Defaults to `false` so logs are disabled unless explicitly enabled by
  /// hosts such as `example` or `test` entry points.
  static bool enabled = false;

  /// The tag prefix for log messages.
  final String tag;

  /// Logger instance for padding/spacing highlight debugging.
  static const paddingLine = Logger._('padddingLine');

  /// Logs an informational message.
  void info(String message) {
    if (!kDebugMode || !enabled) return;
    debugPrint('[pro_image_editor][$tag] $message');
  }

  /// Logs a labeled value.
  void value(String label, Object? value) {
    if (!kDebugMode || !enabled) return;
    debugPrint('[pro_image_editor][$tag] $label: $value');
  }
}
