import 'package:flutter/widgets.dart';

import '../styles/helper_line_style.dart';

export '../styles/helper_line_style.dart';

/// The `HelperLineConfigs` class defines the settings for displaying helper
/// lines in the image editor.
/// Helper lines are used to guide users in positioning and rotating layers.
class HelperLineConfigs {
  /// Creates an instance of the `HelperLines` class with the specified
  /// settings.
  const HelperLineConfigs({
    this.showVerticalLine = true,
    this.showHorizontalLine = true,
    this.showRotateLine = true,
    this.showLayerAlignLine = true,
    this.showPaddingAlignHighlight = true,
    this.isDisabledAtZoom = false,
    this.releaseThreshold = 10.0,
    this.paddingAlignHighlightColor,
    this.style = const HelperLineStyle(),
  });

  /// Specifies whether to show the vertical helper line.
  final bool showVerticalLine;

  /// Specifies whether to show the horizontal helper line.
  final bool showHorizontalLine;

  /// Specifies whether to show the rotate helper line.
  final bool showRotateLine;

  /// Specifies whether to show the layer align helper line.
  final bool showLayerAlignLine;

  /// Specifies whether to show padding align highlights for equal spacing.
  final bool showPaddingAlignHighlight;

  /// Determines whether the helper lines are disabled when the editor is
  /// zoomed in.
  ///
  /// If set to `true`, helper lines will not be displayed when the zoom level
  /// is increased.
  /// If set to `false`, helper lines will remain visible regardless of the
  /// zoom level.
  final bool isDisabledAtZoom;

  /// Style configuration for helper lines.
  final HelperLineStyle style;

  /// Optional color override for padding align highlights.
  ///
  /// If null, the color falls back to [style.layerAlignColor] with opacity.
  final Color? paddingAlignHighlightColor;

  /// The minimum distance in logical pixels that a draggable element must be
  /// released from a helper line for the snapping effect to be deactivated.
  final double releaseThreshold;

  /// Creates a copy of this `HelperLineConfigs` object with the given fields
  /// replaced with new values.
  ///
  /// The [copyWith] method allows you to create a new instance of
  /// [HelperLineConfigs] with some properties updated while keeping the
  /// others unchanged.
  HelperLineConfigs copyWith({
    bool? showVerticalLine,
    bool? showHorizontalLine,
    bool? showRotateLine,
    bool? showLayerAlignLine,
    bool? showPaddingAlignHighlight,
    bool? isDisabledAtZoom,
    double? releaseThreshold,
    Color? paddingAlignHighlightColor,
    HelperLineStyle? style,
  }) {
    return HelperLineConfigs(
      showVerticalLine: showVerticalLine ?? this.showVerticalLine,
      showHorizontalLine: showHorizontalLine ?? this.showHorizontalLine,
      showRotateLine: showRotateLine ?? this.showRotateLine,
      showLayerAlignLine: showLayerAlignLine ?? this.showLayerAlignLine,
      showPaddingAlignHighlight:
          showPaddingAlignHighlight ?? this.showPaddingAlignHighlight,
      isDisabledAtZoom: isDisabledAtZoom ?? this.isDisabledAtZoom,
      releaseThreshold: releaseThreshold ?? this.releaseThreshold,
      paddingAlignHighlightColor:
          paddingAlignHighlightColor ?? this.paddingAlignHighlightColor,
      style: style ?? this.style,
    );
  }
}
