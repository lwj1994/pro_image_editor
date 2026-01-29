import 'package:flutter/widgets.dart';

/// Enum representing the alignment position of the background image within the
/// canvas.
///
/// This determines where the image is positioned when it doesn't fill the
/// entire canvas area.
///
/// Example Usage:
/// ```dart
/// MainEditorConfigs(
///   canvasAlignment: CanvasAlignment.centerTop,
/// )
/// ```
enum CanvasAlignment {
  /// Centers the image both horizontally and vertically.
  center,

  /// Centers the image horizontally at the top of the canvas.
  centerTop,

  /// Centers the image horizontally at the bottom of the canvas.
  centerBottom,

  /// Aligns the image to the top-left corner.
  topLeft,

  /// Aligns the image to the top-right corner.
  topRight,

  /// Aligns the image to the bottom-left corner.
  bottomLeft,

  /// Aligns the image to the bottom-right corner.
  bottomRight,

  /// Centers the image vertically on the left side.
  centerLeft,

  /// Centers the image vertically on the right side.
  centerRight,
}

/// Extension methods for [CanvasAlignment].
extension CanvasAlignmentExtension on CanvasAlignment {
  /// Converts the [CanvasAlignment] to a Flutter [Alignment].
  Alignment toAlignment() {
    switch (this) {
      case CanvasAlignment.center:
        return Alignment.center;
      case CanvasAlignment.centerTop:
        return Alignment.topCenter;
      case CanvasAlignment.centerBottom:
        return Alignment.bottomCenter;
      case CanvasAlignment.topLeft:
        return Alignment.topLeft;
      case CanvasAlignment.topRight:
        return Alignment.topRight;
      case CanvasAlignment.bottomLeft:
        return Alignment.bottomLeft;
      case CanvasAlignment.bottomRight:
        return Alignment.bottomRight;
      case CanvasAlignment.centerLeft:
        return Alignment.centerLeft;
      case CanvasAlignment.centerRight:
        return Alignment.centerRight;
    }
  }
}
