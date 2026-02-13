import 'package:flutter/foundation.dart';

/// A lightweight debug logger that only prints in debug mode.
class Logger {
  const Logger._(this.tag);

  /// The tag prefix for log messages.
  final String tag;

  /// Logger instance for padding/spacing highlight debugging.
  static const paddingLine = Logger._('padddingLine');

  /// Logs an informational message.
  void info(String message) {
    if (!kDebugMode) return;
    debugPrint('[pro_image_editor][$tag] $message');
  }

  /// Logs a labeled value.
  void value(String label, Object? value) {
    if (!kDebugMode) return;
    debugPrint('[pro_image_editor][$tag] $label: $value');
  }
}
