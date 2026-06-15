import 'package:flutter/foundation.dart';

/// Log severity levels used by [Logger].
enum LoggerLevel {
  /// Verbose diagnostic details.
  debug,

  /// General informational messages.
  info,

  /// Recoverable unexpected states.
  warning,

  /// Errors that may require fallback or investigation.
  error,
}

/// External log sink for hosts that want to collect package logs.
typedef LoggerHook = void Function({
  required String tag,
  required String message,
  required LoggerLevel level,
});

/// A lightweight debug logger that only prints in debug mode.
class Logger {
  const Logger._(
    this.tag, {
    this.consoleEnabled = true,
  });

  /// Global runtime switch for package console logs.
  ///
  /// The optional [hook] is invoked regardless of this flag.
  static bool enabled = true;

  /// Optional external hook invoked for every log call.
  ///
  /// Hosts can attach their own logger, analytics, or crash-reporting sink
  /// without depending on Flutter's console output.
  static LoggerHook? hook;

  /// The tag prefix for log messages.
  final String tag;

  /// Whether this logger instance should print to the debug console.
  final bool consoleEnabled;

  /// Logger instance for padding/spacing highlight debugging.
  static const paddingLine = Logger._(
    'paddingLine',
    consoleEnabled: false,
  );

  /// Logs a message through the package logger.
  static void log({
    required String tag,
    required String message,
    LoggerLevel level = LoggerLevel.info,
    bool consoleEnabled = true,
  }) {
    hook?.call(tag: tag, message: message, level: level);

    if (!kDebugMode || !enabled || !consoleEnabled) return;
    debugPrint('[pro_image_editor][${level.name}][$tag] $message');
  }

  /// Logs a message using this logger's tag.
  void message(String message, {LoggerLevel level = LoggerLevel.info}) {
    Logger.log(
      tag: tag,
      message: message,
      level: level,
      consoleEnabled: consoleEnabled,
    );
  }

  /// Logs a debug message.
  void debug(String message) {
    this.message(message, level: LoggerLevel.debug);
  }

  /// Logs an informational message.
  void info(String message) {
    this.message(message);
  }

  /// Logs a warning message.
  void warning(String message) {
    this.message(message, level: LoggerLevel.warning);
  }

  /// Logs an error message.
  void error(String message) {
    this.message(message, level: LoggerLevel.error);
  }

  /// Logs a labeled value.
  void value(
    String label,
    Object? value, {
    LoggerLevel level = LoggerLevel.info,
  }) {
    message('$label: $value', level: level);
  }
}
