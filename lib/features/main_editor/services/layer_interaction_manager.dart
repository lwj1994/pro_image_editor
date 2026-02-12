// Dart imports:
import 'dart:async';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '/core/models/editor_callbacks/main_editor/helper_lines/helper_lines_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/history/last_layer_interaction_position.dart';
import '/core/models/layers/layer.dart';
import '/shared/utils/debounce.dart';
import '/shared/utils/unique_id_generator.dart';

/// A helper class responsible for managing layer interactions in the editor.
///
/// The `LayerInteractionManager` class provides methods for handling various
/// interactions with layers in an image editing environment, including
/// scaling, rotating, flipping, and zooming. It also manages the display of
/// helper lines and provides haptic feedback when interacting with these lines
/// to enhance the user experience.
class LayerInteractionManager {
  /// Creates an instance of [LayerInteractionManager].
  ///
  /// - [helperLinesCallbacks]: An optional instance of [HelperLinesCallbacks]
  ///   to handle helper line hit events.
  LayerInteractionManager({
    required this.helperLinesCallbacks,
    required this.configs,
    this.onSelectedLayerChanged,
    required this.onSelectedLayersChanged,
  });

  /// An optional instance of [HelperLinesCallbacks] that defines callback
  ///  functions for handling helper line interactions.
  final HelperLinesCallbacks? helperLinesCallbacks;

  /// The configuration settings for the Pro Image Editor.
  ///
  /// This object contains various customizable options and parameters
  /// that define the behavior and appearance of the image editor.
  final ProImageEditorConfigs configs;

  /// Callback function to be called when the selected layer changes.
  final ValueChanged<String>? onSelectedLayerChanged;

  /// Callback function to be called when the selected layer changes.
  final ValueChanged<Set<String>>? onSelectedLayersChanged;

  /// Debounce for scaling actions in the editor.
  late Debounce scaleDebounce;

  /// Y-coordinate of the rotation helper line.
  double rotationHelperLineY = 0;

  /// X-coordinate of the rotation helper line.
  double rotationHelperLineX = 0;

  /// Rotation angle of the rotation helper line.
  double rotationHelperLineDeg = 0;

  /// A list that stores the layers selected at the start of a scaling
  /// operation.
  /// This is used to keep track of the initial state of the selected layers
  /// before any scaling transformations are applied.
  List<Layer> selectedLayersScaleStart = [];

  /// The base scale factor from the layer;
  final Map<String, double> _baseScaleFactor = {};

  /// The base angle factor from the layer;
  final Map<String, double> _baseAngleFactor = {};

  /// Initial rotation angle when snapping started.
  final Map<String, double> _snapStartRotation = {};

  /// Last recorded rotation angle during snapping.
  final Map<String, double> _snapLastRotation = {};

  /// X-coordinate where snapping started.
  double snapStartPosX = 0;

  /// Y-coordinate where snapping started.
  double snapStartPosY = 0;

  /// Flag indicating if vertical helper lines should be displayed.
  bool showVerticalHelperLine = false;

  /// Flag indicating if horizontal helper lines should be displayed.
  bool showHorizontalHelperLine = false;

  /// Flag indicating if rotation helper lines should be displayed.
  bool showRotationHelperLine = false;

  /// Whether to show the vertical alignment line for the active layer.
  bool isVerticalGuideVisible = false;

  /// Whether to show the horizontal alignment line for the active layer.
  bool isHorizontalGuideVisible = false;

  /// Offset of the horizontal alignment line relative to the editor center.
  Offset horizontalGuideOffset = Offset.zero;

  /// Offset of the vertical alignment line relative to the editor center.
  Offset verticalGuideOffset = Offset.zero;

  /// Highlight blocks for equal-spacing guides (gap/margin).
  final List<Rect> _layerSpacingHighlightRects = [];

  /// Immutable access to spacing highlight blocks.
  List<Rect> get layerSpacingHighlightRects =>
      List.unmodifiable(_layerSpacingHighlightRects);

  /// Flag indicating if rotation helper lines have started.
  bool _rotationStartedHelper = false;

  /// Flag indicating if helper lines should be displayed.
  bool showHelperLines = false;

  /// Flag indicating if the remove button is hovered.
  bool hoverRemoveBtn = false;

  /// Enables or disables hit detection.
  /// When `true`, allows detecting user interactions
  /// with the painted layer.
  bool enabledHitDetection = true;

  /// Tracks the last tapped layer during pointer
  /// interaction. Set during layer tap handling and
  /// consumed by the body's onPointerUp callback to
  /// pass to [MainEditorCallbacks.onTap].
  /// Reset on each new pointer down event.
  Layer? lastTappedLayer;

  /// Flag indicating if the scaling tool is active.
  bool _activeScale = false;

  /// Tracks whether any layer has been transformed (moved, scaled, rotated)
  /// during the current editing session.
  bool layerWasTransformed = false;

  /// Checks if there are any selected layers.
  ///
  /// Returns `true` if the list of selected layer IDs is not empty,
  /// indicating that at least one layer is selected. Otherwise, returns
  /// `false`.
  bool get hasSelectedLayers => selectedLayerIds.isNotEmpty;

  double _getLayerBaseScale(String layerId) {
    return _baseScaleFactor[layerId] ?? 1;
  }

  double _getLayerBaseAngle(String layerId) {
    return _baseAngleFactor[layerId] ?? 0;
  }

  double _getLayerSnapStartRotation(String layerId) {
    return _snapStartRotation[layerId] ?? 0;
  }

  double _getLayerSnapLastRotation(String layerId) {
    return _snapLastRotation[layerId] ?? 0;
  }

  /// The set of currently selected layer IDs (for multi-select support).
  final Set<String> selectedLayerIds = <String>{};

  /// Returns the currently selected layer ID.
  ///
  /// If multiple layers are selected, this returns the **last one inserted**.
  /// Returns an empty string if no layer is selected.
  String get selectedLayerId =>
      selectedLayerIds.isNotEmpty ? selectedLayerIds.first : '';

  /// Sets the [selectedLayerIds] to a single [id], replacing any existing
  /// selection.
  ///
  /// This is useful when only single selection is needed.
  set selectedLayerId(String id) {
    selectedLayerIds
      ..clear()
      ..add(id);
    _notifySelectionChanged();
  }

  /// Add a layer to the selection set.
  void addSelectedLayer(String id) {
    selectedLayerIds.add(id);
    _notifySelectionChanged();
  }

  /// Adds multiple layer IDs to the set of selected layers.
  ///
  /// This method takes a set of layer IDs and adds each ID to the
  /// `selectedLayerIds` collection. After updating the selection,
  /// it triggers a notification to indicate that the selection has changed.
  ///
  /// [value] A set of layer IDs to be added to the selection.
  void addMultipleSelectedLayers(Set<String> value) {
    for (final id in value) {
      selectedLayerIds.add(id);
    }
    _notifySelectionChanged();
  }

  /// Remove a layer from the selection set.
  void removeSelectedLayer(String id) {
    selectedLayerIds.remove(id);
    _notifySelectionChanged();
  }

  /// Removes multiple layers from the selection based on the provided set
  /// of layer IDs.
  ///
  /// This method iterates through the given set of layer IDs and removes each
  /// one from the `selectedLayerIds` collection. After the removal process,
  /// it triggers a notification to indicate that the selection has changed.
  ///
  /// [value] A set of layer IDs to be removed from the selection.
  void removeMultipleSelectedLayers(Set<String> value) {
    for (final id in value) {
      selectedLayerIds.remove(id);
    }
    _notifySelectionChanged();
  }

  /// Clear all selected layers.
  void clearSelectedLayers() {
    selectedLayerIds.clear();
    _notifySelectionChanged();
  }

  /// Set selected layers to a specific set.
  void setSelectedLayers(Iterable<String> ids) {
    selectedLayerIds
      ..clear()
      ..addAll(ids);
    _notifySelectionChanged();
  }

  /// Notifies selection change callbacks, both single and multi-select.
  void _notifySelectionChanged() {
    onSelectedLayerChanged?.call(selectedLayerId);
    onSelectedLayersChanged?.call(selectedLayerIds);
  }

  /// Groups the currently selected layers by assigning them a common groupId.
  ///
  /// This method creates a group from all currently selected layers by giving
  /// them the same unique groupId. After grouping, whenever any layer in the
  /// group is selected, all layers in the group will be automatically selected.
  ///
  /// [activeLayers] The list of all active layers in the editor.
  /// [onHistoryChanged] Callback to trigger when the layer history
  /// needs to be updated.
  ///
  /// Returns the groupId that was assigned to the layers, or null
  /// if no layers were selected.
  String? groupSelectedLayers(
    List<Layer> activeLayers,
    Function(List<Layer> layers) onHistoryChanged,
  ) {
    if (selectedLayerIds.isEmpty) return null;

    // Generate a unique group ID
    final groupId = generateUniqueId();

    // Create a copy of the layers list for history
    final updatedLayers = <Layer>[];
    for (final layer in activeLayers) {
      final layerCopy = _copyLayer(layer);
      if (selectedLayerIds.contains(layer.id)) {
        // Assign the new groupId to selected layers
        layerCopy.groupId = groupId;
      }
      updatedLayers.add(layerCopy);
    }

    // Update history with the modified layers
    onHistoryChanged(updatedLayers);

    return groupId;
  }

  /// Ungroups the specified layer by removing its groupId.
  ///
  /// This method removes the groupId from the specified layer and all other
  /// layers that share the same groupId, effectively breaking the group.
  ///
  /// [layer] The layer to ungroup.
  /// [activeLayers] The list of all active layers in the editor.
  /// [onHistoryChanged] Callback to trigger when the layer history
  /// needs to be updated.
  ///
  /// Returns true if any layers were ungrouped, false otherwise.
  bool ungroupLayer(
    Layer layer,
    List<Layer> activeLayers,
    Function(List<Layer> layers) onHistoryChanged,
  ) {
    if (layer.groupId == null) return false;

    final groupIdToRemove = layer.groupId!;

    // Create a copy of the layers list for history
    final updatedLayers = <Layer>[];
    bool hasChanges = false;

    for (final currentLayer in activeLayers) {
      final layerCopy = _copyLayer(currentLayer);
      if (currentLayer.groupId == groupIdToRemove) {
        // Remove the groupId from layers in the group
        layerCopy.groupId = null;
        hasChanges = true;
      }
      updatedLayers.add(layerCopy);
    }

    if (hasChanges) {
      // Update history with the modified layers
      onHistoryChanged(updatedLayers);
    }

    return hasChanges;
  }

  /// Creates a copy of a layer with all its properties.
  Layer _copyLayer(Layer originalLayer) {
    // Copy layer-specific properties based on layer type
    if (originalLayer is TextLayer) {
      return TextLayer(
        id: originalLayer.id,
        text: originalLayer.text,
        textStyle: originalLayer.textStyle,
        colorMode: originalLayer.colorMode,
        color: originalLayer.color,
        background: originalLayer.background,
        align: originalLayer.align,
        fontScale: originalLayer.fontScale,
        customSecondaryColor: originalLayer.customSecondaryColor,
        maxTextWidth: originalLayer.maxTextWidth,
        hit: originalLayer.hit,
        key: originalLayer.key,
        interaction: originalLayer.interaction,
        offset: originalLayer.offset,
        rotation: originalLayer.rotation,
        scale: originalLayer.scale,
        flipX: originalLayer.flipX,
        flipY: originalLayer.flipY,
        meta: originalLayer.meta,
        boxConstraints: originalLayer.boxConstraints,
      )..groupId = originalLayer.groupId;
    } else if (originalLayer is EmojiLayer) {
      return EmojiLayer(
        id: originalLayer.id,
        emoji: originalLayer.emoji,
        key: originalLayer.key,
        interaction: originalLayer.interaction,
        offset: originalLayer.offset,
        rotation: originalLayer.rotation,
        scale: originalLayer.scale,
        flipX: originalLayer.flipX,
        flipY: originalLayer.flipY,
        meta: originalLayer.meta,
        boxConstraints: originalLayer.boxConstraints,
      )..groupId = originalLayer.groupId;
    } else if (originalLayer is PaintLayer) {
      return PaintLayer(
        id: originalLayer.id,
        item: originalLayer.item,
        rawSize: originalLayer.rawSize,
        opacity: originalLayer.opacity,
        key: originalLayer.key,
        interaction: originalLayer.interaction,
        offset: originalLayer.offset,
        rotation: originalLayer.rotation,
        scale: originalLayer.scale,
        flipX: originalLayer.flipX,
        flipY: originalLayer.flipY,
        meta: originalLayer.meta,
        boxConstraints: originalLayer.boxConstraints,
      )..groupId = originalLayer.groupId;
    } else if (originalLayer is WidgetLayer) {
      return WidgetLayer(
        id: originalLayer.id,
        widget: originalLayer.widget,
        exportConfigs: originalLayer.exportConfigs,
        key: originalLayer.key,
        interaction: originalLayer.interaction,
        offset: originalLayer.offset,
        rotation: originalLayer.rotation,
        scale: originalLayer.scale,
        flipX: originalLayer.flipX,
        flipY: originalLayer.flipY,
        meta: originalLayer.meta,
        boxConstraints: originalLayer.boxConstraints,
      )..groupId = originalLayer.groupId;
    }

    // Fallback for base Layer type
    return Layer(
      id: originalLayer.id,
      key: originalLayer.key,
      interaction: originalLayer.interaction,
      offset: originalLayer.offset,
      rotation: originalLayer.rotation,
      scale: originalLayer.scale,
      flipX: originalLayer.flipX,
      flipY: originalLayer.flipY,
      meta: originalLayer.meta,
      boxConstraints: originalLayer.boxConstraints,
      groupId: originalLayer.groupId,
    );
  }

  /// Helper variable for scaling during rotation of a layer.
  double? rotateScaleLayerScaleHelper;

  /// Helper variable for storing the size of a layer during rotation and
  /// scaling operations.
  Size? rotateScaleLayerSizeHelper;

  /// Represents the layer being interacted with during a
  /// scale or rotate gesture.
  ///
  /// This is set when the user drags the scale/rotate button from the
  /// selection overlay.
  Layer? activeInteractionLayer;

  /// Last recorded X-axis position for layers.
  LayerLastPosition lastPositionX = LayerLastPosition.center;

  /// Last recorded Y-axis position for layers.
  LayerLastPosition lastPositionY = LayerLastPosition.center;

  Offset? _rotateScaleButtonStartPosition;
  final _horizontalSnapHelper = _LayerAlignGuideHelper();
  final _verticalSnapHelper = _LayerAlignGuideHelper();

  /// Configuration settings for displaying and managing helper lines within
  /// the editor.
  HelperLineConfigs get helperLineConfigs => configs.helperLines;

  /// Resets the state of the layer interaction manager by:
  ///
  /// - Setting `_rotateScaleButtonStartPosition` to `null`.
  /// - Setting `_rotationStartedHelper` to `false`.
  /// - Enabling the display of helper lines by setting `showHelperLines` to
  /// `true`.
  void reset() {
    _rotateScaleButtonStartPosition = null;
    _rotationStartedHelper = false;
    showHelperLines = true;
  }

  Offset _getFractionalLayerOffset(Layer layer) {
    if (layer.isTextLayer) {
      return configs.textEditor.layerFractionalOffset;
    } else if (layer.isEmojiLayer) {
      return configs.emojiEditor.layerFractionalOffset;
    } else if (layer.isWidgetLayer) {
      return configs.stickerEditor.layerFractionalOffset;
    } else if (layer.isPaintLayer) {
      return configs.paintEditor.layerFractionalOffset;
    }
    return const Offset(-0.5, -0.5);
  }

  /// Determines if layers are selectable based on the configuration and device
  /// type.
  bool layersAreSelectable(ProImageEditorConfigs configs) {
    if (configs.layerInteraction.selectable ==
        LayerInteractionSelectable.auto) {
      return isDesktop;
    }
    return configs.layerInteraction.selectable ==
        LayerInteractionSelectable.enabled;
  }

  /// Calculates scaling and rotation based on user interactions.
  void calculateInteractiveButtonScaleRotate({
    required double editorScaleFactor,
    required Offset editorScaleOffset,
    required ProImageEditorConfigs configs,
    required ScaleUpdateDetails details,
    required List<Layer> selectedLayers,
    required Size editorSize,
    required LayerInteractionStyle layerTheme,
  }) {
    /// Calculates the rotation angle (in radians) for a button moved to a
    /// new position.
    /// [oldPosition] is the initial button position,
    /// [newPosition] is the final button position.
    double calculateRotation(Offset oldPosition, Offset newPosition) {
      // Calculate the vectors from the origin to the old and new positions
      Offset oldVector = oldPosition;
      Offset newVector = newPosition;

      // Get the angle of each vector relative to the x-axis
      double oldAngle = atan2(oldVector.dy, oldVector.dx);
      double newAngle = atan2(newVector.dy, newVector.dx);

      // Calculate the rotation angle
      double rotation = newAngle - oldAngle;

      // Normalize the rotation angle to be between -pi and pi
      if (rotation > pi) rotation -= 2 * pi;
      if (rotation < -pi) rotation += 2 * pi;

      return rotation; // In radians
    }

    /// Calculates the scale factor based on the movement of a button.
    /// [oldPosition] is the initial button position,
    /// [newPosition] is the final button position.
    double calculateScale(Offset oldPosition, Offset newPosition) {
      // Calculate distances from the origin to the old and new positions
      double oldDistance = (oldPosition).distance;
      double newDistance = (newPosition).distance;

      // Calculate the scale factor
      if (oldDistance == 0 || newDistance == 0) {
        return 1;
      }

      return newDistance / oldDistance;
    }

    for (Layer layer in selectedLayers) {
      /// Optionally, this could be extended to allow multiple layers to be
      /// transformed using a single layer interaction button.
      if (activeInteractionLayer?.id != layer.id) continue;

      Offset layerOffset = layer.offset;

      Offset realTouchPosition =
          (details.localFocalPoint - editorScaleOffset) / editorScaleFactor;

      Offset touchPositionFromLayerCenter =
          realTouchPosition - editorSize.center(Offset.zero) - layerOffset;

      if (layer.flipX) {
        touchPositionFromLayerCenter = Offset(
          -touchPositionFromLayerCenter.dx,
          touchPositionFromLayerCenter.dy,
        );
      }
      if (layer.flipY) {
        touchPositionFromLayerCenter = Offset(
          touchPositionFromLayerCenter.dx,
          -touchPositionFromLayerCenter.dy,
        );
      }

      _rotateScaleButtonStartPosition ??= touchPositionFromLayerCenter;

      if (layer.interaction.enableScale) {
        layer.scale = _getLayerBaseScale(layer.id) *
            calculateScale(
              _rotateScaleButtonStartPosition!,
              touchPositionFromLayerCenter,
            );
        _setMinMaxScaleFactor(configs, layer);
      }

      if (layer.interaction.enableRotate) {
        layer.rotation = _getLayerBaseAngle(layer.id) +
            calculateRotation(
              _rotateScaleButtonStartPosition!,
              touchPositionFromLayerCenter,
            );

        checkRotationLine(
          layer: layer,
          editorSize: editorSize,
          editorScaleFactor: editorScaleFactor,
        );
      }
    }
  }

  /// Calculates movement of a layer based on user interactions, considering
  /// various conditions such as hit areas and screen boundaries.
  void calculateMovement({
    required double editorScaleFactor,
    required Size editorBodySize,
    required Size imageSize,
    required BuildContext context,
    required ScaleUpdateDetails detail,
    required List<Layer> selectedLayers,
    required List<Layer> layerList,
    required GlobalKey removeAreaKey,
    required Function(bool value) onHoveredRemoveChanged,
    required StreamController<void> helperLineCtrl,
  }) {
    if (_activeScale) return;

    _checkLayerHoverRemoveArea(
      detail: detail,
      onHoveredRemoveChanged: onHoveredRemoveChanged,
      removeAreaKey: removeAreaKey,
    );

    bool hasMultiSelection = selectedLayers.length > 1;
    if (!layerWasTransformed) {
      layerWasTransformed = selectedLayers.isNotEmpty;
    }
    for (Layer layer in selectedLayers) {
      if (!layer.interaction.enableMove) continue;

      Offset fractionalOffset = _getFractionalLayerOffset(layer);

      layer.offset = Offset(
        layer.offset.dx + detail.focalPointDelta.dx / editorScaleFactor,
        layer.offset.dy + detail.focalPointDelta.dy / editorScaleFactor,
      );

      if (hasMultiSelection ||
          (editorScaleFactor > 1 && helperLineConfigs.isDisabledAtZoom)) {
        continue;
      }

      final Offset localPointFromCenter = layer.computeLocalCenterOffset(
        fractionalOffset,
      );
      final Offset layerCenterOffset = layer.computeOffsetFromCenterFraction(
        fractionalOffset,
      );

      final releaseThreshold = helperLineConfigs.releaseThreshold;
      bool hasLineHit = false;
      double posX = layerCenterOffset.dx;
      double posY = layerCenterOffset.dy;

      bool hitAreaX =
          detail.focalPoint.dx >= snapStartPosX - releaseThreshold &&
              detail.focalPoint.dx <= snapStartPosX + releaseThreshold;
      bool hitAreaY =
          detail.focalPoint.dy >= snapStartPosY - releaseThreshold &&
              detail.focalPoint.dy <= snapStartPosY + releaseThreshold;

      bool helperGoNearLineLeft =
          posX >= 0 && lastPositionX == LayerLastPosition.left;
      bool helperGoNearLineRight =
          posX <= 0 && lastPositionX == LayerLastPosition.right;
      bool helperGoNearLineTop =
          posY >= 0 && lastPositionY == LayerLastPosition.top;
      bool helperGoNearLineBottom =
          posY <= 0 && lastPositionY == LayerLastPosition.bottom;

      /// Calc vertical helper line
      if (helperLineConfigs.showVerticalLine) {
        if ((!showVerticalHelperLine &&
                (helperGoNearLineLeft || helperGoNearLineRight)) ||
            (showVerticalHelperLine && hitAreaX)) {
          if (!showVerticalHelperLine) {
            hasLineHit = true;
            snapStartPosX = detail.focalPoint.dx;
          }
          showVerticalHelperLine = true;
          layer.offset = Offset(-localPointFromCenter.dx, layer.offset.dy);
          lastPositionX = LayerLastPosition.center;
        } else {
          showVerticalHelperLine = false;
          lastPositionX =
              posX <= 0 ? LayerLastPosition.left : LayerLastPosition.right;
        }
      }

      if (helperLineConfigs.showHorizontalLine) {
        /// Calc horizontal helper line
        if ((!showHorizontalHelperLine &&
                (helperGoNearLineTop || helperGoNearLineBottom)) ||
            (showHorizontalHelperLine && hitAreaY)) {
          if (!showHorizontalHelperLine) {
            hasLineHit = true;
            snapStartPosY = detail.focalPoint.dy;
          }
          showHorizontalHelperLine = true;
          layer.offset = Offset(layer.offset.dx, -localPointFromCenter.dy);
          lastPositionY = LayerLastPosition.center;
        } else {
          showHorizontalHelperLine = false;
          lastPositionY =
              posY <= 0 ? LayerLastPosition.top : LayerLastPosition.bottom;
        }
      }

      _updateAlignmentGuides(
        detail: detail,
        layerList: layerList,
        activeLayer: layer,
        helperLineCtrl: helperLineCtrl,
        editorScaleFactor: editorScaleFactor,
        editorBodySize: editorBodySize,
        imageSize: imageSize,
        fractionalOffset: fractionalOffset,
      );

      if (hasLineHit) {
        if (showHorizontalHelperLine) {
          helperLinesCallbacks?.handleHorizontalLineHit();
        }
        if (showVerticalHelperLine) {
          helperLinesCallbacks?.handleVerticalLineHit();
        }
      }
    }
  }

  void _checkLayerHoverRemoveArea({
    required ScaleUpdateDetails detail,
    required GlobalKey removeAreaKey,
    required Function(bool value) onHoveredRemoveChanged,
  }) {
    RenderBox? box =
        removeAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      Offset position = box.localToGlobal(Offset.zero);
      bool hit = Rect.fromLTWH(
        position.dx,
        position.dy,
        box.size.width,
        box.size.height,
      ).contains(detail.focalPoint);
      if (hoverRemoveBtn != hit) {
        hoverRemoveBtn = hit;
        onHoveredRemoveChanged.call(hoverRemoveBtn);
      }
    }
  }

  /// Calculates scaling and rotation of a layer based on user interactions.
  void calculateScaleRotate({
    required ProImageEditorConfigs configs,
    required ScaleUpdateDetails detail,
    required List<Layer> selectedLayers,
    required Size editorSize,
    required double editorScaleFactor,
    required EdgeInsets screenPaddingHelper,
  }) {
    _activeScale = true;
    bool enableMobilePinchScale =
        configs.layerInteraction.enableMobilePinchScale;
    bool enableMobilePinchRotate =
        configs.layerInteraction.enableMobilePinchRotate;

    if (enableMobilePinchScale || enableMobilePinchRotate) {
      if (!layerWasTransformed) {
        layerWasTransformed = selectedLayers.isNotEmpty;
      }
      for (Layer layer in selectedLayers) {
        if (layer.interaction.enableScale && enableMobilePinchScale) {
          layer.scale = _getLayerBaseScale(layer.id) * detail.scale;
          _setMinMaxScaleFactor(configs, layer);
        }
        if (layer.interaction.enableRotate && enableMobilePinchRotate) {
          layer.rotation = _getLayerBaseAngle(layer.id) + detail.rotation;

          if (selectedLayers.length <= 1) {
            checkRotationLine(
              layer: layer,
              editorSize: editorSize,
              editorScaleFactor: editorScaleFactor,
            );
          }
        }
      }
    }

    scaleDebounce(() => _activeScale = false);
  }

  /// Checks the rotation line based on user interactions, adjusting rotation
  /// accordingly.
  void checkRotationLine({
    required Layer layer,
    required Size editorSize,
    required double editorScaleFactor,
  }) {
    if (!helperLineConfigs.showRotateLine ||
        (editorScaleFactor > 1 && helperLineConfigs.isDisabledAtZoom)) {
      return;
    }

    double rotation = layer.rotation - _getLayerBaseAngle(layer.id);
    double hitSpanX = helperLineConfigs.releaseThreshold / 2;
    double deg = layer.rotation * 180 / pi;
    double degChange = rotation * 180 / pi;
    double degHit = (_getLayerSnapStartRotation(layer.id) + degChange) % 45;

    bool hitAreaBelow = degHit <= hitSpanX;
    bool hitAreaAfter = degHit >= 45 - hitSpanX;
    bool hitArea = hitAreaBelow || hitAreaAfter;

    double lastRotation = _getLayerSnapLastRotation(layer.id);

    if ((!showRotationHelperLine &&
            ((degHit > 0 && degHit <= hitSpanX && lastRotation < deg) ||
                (degHit < 45 &&
                    degHit >= 45 - hitSpanX &&
                    lastRotation > deg))) ||
        (showRotationHelperLine && hitArea)) {
      if (_rotationStartedHelper) {
        layer.rotation =
            (deg - (degHit > 45 - hitSpanX ? degHit - 45 : degHit)) / 180 * pi;
        rotationHelperLineDeg = layer.rotation;

        final Offset fractionalOffset = _getFractionalLayerOffset(layer);
        layer.computeLocalCenterOffset(fractionalOffset);
        final Offset layerCenterOffset = layer.computeOffsetFromCenterFraction(
          fractionalOffset,
        );

        double posY = layerCenterOffset.dy;
        double posX = layerCenterOffset.dx;

        rotationHelperLineX = posX + editorSize.width / 2;
        rotationHelperLineY = posY + editorSize.height / 2;
        if (!showRotationHelperLine) {
          helperLinesCallbacks?.handleRotateLineHit();
        }
        showRotationHelperLine = true;
      }
      _snapLastRotation[layer.id] = deg;
    } else {
      showRotationHelperLine = false;
      _rotationStartedHelper = true;
    }
  }

  /// Handles the initialization logic when a scaling gesture starts on a layer.
  void onScaleStart({
    required ScaleStartDetails details,
    required List<Layer> selectedLayers,
  }) {
    selectedLayersScaleStart = selectedLayers;
    snapStartPosX = details.focalPoint.dx;
    snapStartPosY = details.focalPoint.dy;

    for (Layer layer in selectedLayers) {
      _baseScaleFactor[layer.id] = layer.scale;
      _baseAngleFactor[layer.id] = layer.rotation;
      _snapStartRotation[layer.id] = layer.rotation * 180 / pi;
      _snapLastRotation[layer.id] = _getLayerSnapStartRotation(layer.id);
      reset();

      final fractionOffset = _getFractionalLayerOffset(layer);
      final centerOffset = layer.computeOffsetFromCenterFraction(
        fractionOffset,
      );
      double posX = centerOffset.dx;
      double posY = centerOffset.dy;

      final releaseThreshold = helperLineConfigs.releaseThreshold;

      lastPositionY = posY <= -releaseThreshold
          ? LayerLastPosition.top
          : posY >= releaseThreshold
              ? LayerLastPosition.bottom
              : LayerLastPosition.center;
      lastPositionX = posX <= -releaseThreshold
          ? LayerLastPosition.left
          : posX >= releaseThreshold
              ? LayerLastPosition.right
              : LayerLastPosition.center;
    }
  }

  /// Handles cleanup and resets various flags and states after scaling
  /// interaction ends.
  void onScaleEnd() {
    _baseScaleFactor.clear();
    _baseAngleFactor.clear();
    _snapStartRotation.clear();
    _snapLastRotation.clear();

    selectedLayersScaleStart.clear();
    enabledHitDetection = true;
    layerWasTransformed = false;
    showHorizontalHelperLine = false;
    showVerticalHelperLine = false;
    showRotationHelperLine = false;
    isVerticalGuideVisible = false;
    isHorizontalGuideVisible = false;
    _layerSpacingHighlightRects.clear();
    showHelperLines = false;
    hoverRemoveBtn = false;
  }

  /// Rotate a layer.
  ///
  /// This method rotates a layer based on various factors, including flip and
  /// angle.
  void rotateLayer({
    required Layer layer,
    required bool beforeIsFlipX,
    required double newImgW,
    required double newImgH,
    required double rotationScale,
    required double rotationRadian,
    required double rotationAngle,
  }) {
    if (beforeIsFlipX) {
      layer.rotation -= rotationRadian;
    } else {
      layer.rotation += rotationRadian;
    }

    if (rotationAngle == 90) {
      layer
        ..scale /= rotationScale
        ..offset = Offset(
          newImgW - layer.offset.dy / rotationScale,
          layer.offset.dx / rotationScale,
        );
    } else if (rotationAngle == 180) {
      layer.offset = Offset(
        newImgW - layer.offset.dx,
        newImgH - layer.offset.dy,
      );
    } else if (rotationAngle == 270) {
      layer
        ..scale /= rotationScale
        ..offset = Offset(
          layer.offset.dy / rotationScale,
          newImgH - layer.offset.dx / rotationScale,
        );
    }
  }

  /// Handles zooming of a layer.
  ///
  /// This method calculates the zooming of a layer based on the specified
  /// parameters.
  /// It checks if the layer should be zoomed and performs the necessary
  /// transformations.
  ///
  /// Returns `true` if the layer was zoomed, otherwise `false`.
  bool zoomedLayer({
    required Layer layer,
    required double scale,
    required double scaleX,
    required double oldFullH,
    required double oldFullW,
    required double pixelRatio,
    required Rect cropRect,
    required bool isHalfPi,
  }) {
    var paddingTop = cropRect.top / pixelRatio;
    var paddingLeft = cropRect.left / pixelRatio;
    var paddingRight = oldFullW - cropRect.right;
    var paddingBottom = oldFullH - cropRect.bottom;

    // important to check with < 1 and >-1 cuz crop-editor has rounding bugs
    if (paddingTop > 0.1 ||
        paddingTop < -0.1 ||
        paddingLeft > 0.1 ||
        paddingLeft < -0.1 ||
        paddingRight > 0.1 ||
        paddingRight < -0.1 ||
        paddingBottom > 0.1 ||
        paddingBottom < -0.1) {
      var initialIconX = (layer.offset.dx - paddingLeft) * scaleX;
      var initialIconY = (layer.offset.dy - paddingTop) * scaleX;
      layer
        ..offset = Offset(initialIconX, initialIconY)
        ..scale *= scale;
      return true;
    }
    return false;
  }

  /// Flip a layer horizontally or vertically.
  ///
  /// This method flips a layer either horizontally or vertically based on the
  /// specified parameters.
  void flipLayer({
    required Layer layer,
    required bool flipX,
    required bool flipY,
    required bool isHalfPi,
    required double imageWidth,
    required double imageHeight,
  }) {
    if (flipY) {
      if (isHalfPi) {
        layer.flipY = !layer.flipY;
      } else {
        layer.flipX = !layer.flipX;
      }
      layer.offset = Offset(imageWidth - layer.offset.dx, layer.offset.dy);
    }
    if (flipX) {
      layer
        ..flipX = !layer.flipX
        ..offset = Offset(layer.offset.dx, imageHeight - layer.offset.dy);
    }
  }

  void _setMinMaxScaleFactor(ProImageEditorConfigs configs, Layer layer) {
    if (layer is PaintLayer) {
      layer.scale = layer.scale.clamp(
        configs.paintEditor.minScale,
        configs.paintEditor.maxScale,
      );
    } else if (layer is TextLayer) {
      layer.scale = layer.scale.clamp(
        configs.textEditor.minScale,
        configs.textEditor.maxScale,
      );
    } else if (layer is EmojiLayer) {
      layer.scale = layer.scale.clamp(
        configs.emojiEditor.minScale,
        configs.emojiEditor.maxScale,
      );
    } else if (layer is WidgetLayer) {
      layer.scale = layer.scale.clamp(
        configs.stickerEditor.minScale,
        configs.stickerEditor.maxScale,
      );
    }
  }

  void _updateAlignmentGuides({
    required List<Layer> layerList,
    required Layer activeLayer,
    required ScaleUpdateDetails detail,
    required StreamController<void> helperLineCtrl,
    required double editorScaleFactor,
    required Size editorBodySize,
    required Size imageSize,
    required Offset fractionalOffset,
  }) {
    final snapThreshold = 3.0 / editorScaleFactor;
    final releaseThreshold = helperLineConfigs.releaseThreshold;
    final spacingSnapThreshold =
        helperLineConfigs.layerSpacingSnapThreshold / editorScaleFactor;
    final showLayerAlignLine = helperLineConfigs.showLayerAlignLine;
    final showLayerSpacingLine = helperLineConfigs.showLayerSpacingLine;

    final wasHorizontalGuideVisible = isHorizontalGuideVisible;
    final wasVerticalGuideVisible = isVerticalGuideVisible;
    final beforeSpacingHighlights =
        List<Rect>.from(_layerSpacingHighlightRects);
    final hadSpacingHighlights = beforeSpacingHighlights.isNotEmpty;

    isHorizontalGuideVisible = false;
    isVerticalGuideVisible = false;

    if (showLayerAlignLine) {
      Offset? horizontalOffset;
      Offset? verticalOffset;

      final Offset localPointFromCenter = activeLayer.computeLocalCenterOffset(
        fractionalOffset,
      );
      final Offset layerCenterOffset =
          activeLayer.computeOffsetFromCenterFraction(fractionalOffset);

      final uniqueDxOffsets = <Offset>[];
      final uniqueDyOffsets = <Offset>[];
      final seenDx = <double>{};
      final seenDy = <double>{};

      bool isSimilar(Set<double> seen, double value, double threshold) {
        return seen.any((v) => (v - value).abs() < threshold);
      }

      for (final layer in layerList) {
        if (layer == activeLayer) continue;
        if (!layer.enableSpacingHighlight) continue;
        final centerOffset = layer.computeOffsetFromCenterFraction(
          _getFractionalLayerOffset(layer),
        );

        final dx = centerOffset.dx;
        final dy = centerOffset.dy;

        if (!isSimilar(seenDx, dx, snapThreshold)) {
          seenDx.add(dx);
          uniqueDxOffsets.add(centerOffset);
        }

        if (!isSimilar(seenDy, dy, snapThreshold)) {
          seenDy.add(dy);
          uniqueDyOffsets.add(centerOffset);
        }
      }

      for (final layerOffset in uniqueDxOffsets) {
        if (verticalOffset != null) break;

        final dx = (layerOffset.dx - layerCenterOffset.dx).abs();

        // Vertical snapping (dx axis)
        if (dx <= snapThreshold &&
            _verticalSnapHelper.maybeSnap(
              focal: detail.focalPoint.dx,
              focalDelta: detail.focalPointDelta.dx,
              offset: layerOffset,
              threshold: snapThreshold,
              releaseThreshold: releaseThreshold,
              positiveDirection: LayerLastPosition.left,
              negativeDirection: LayerLastPosition.right,
            )) {
          verticalOffset = layerOffset;
        }
      }

      for (final layerOffset in uniqueDyOffsets) {
        if (horizontalOffset != null) break;

        final dy = (layerOffset.dy - layerCenterOffset.dy).abs();

        // Horizontal snapping (dy axis)
        if (dy <= snapThreshold &&
            _horizontalSnapHelper.maybeSnap(
              focal: detail.focalPoint.dy,
              focalDelta: detail.focalPointDelta.dy,
              offset: layerOffset,
              threshold: snapThreshold,
              releaseThreshold: releaseThreshold,
              positiveDirection: LayerLastPosition.top,
              negativeDirection: LayerLastPosition.bottom,
            )) {
          horizontalOffset = layerOffset;
        }
      }

      if (verticalOffset != null) {
        verticalGuideOffset = verticalOffset;
        isVerticalGuideVisible = true;

        activeLayer.offset = Offset(
          verticalOffset.dx - localPointFromCenter.dx,
          activeLayer.offset.dy,
        );
      }

      if (horizontalOffset != null) {
        horizontalGuideOffset = horizontalOffset;
        isHorizontalGuideVisible = true;

        activeLayer.offset = Offset(
          activeLayer.offset.dx,
          horizontalOffset.dy - localPointFromCenter.dy,
        );
      }
    }

    if (showLayerSpacingLine) {
      final spacingResult = _calculateLayerSpacingGuides(
        layerList: layerList,
        activeLayer: activeLayer,
        editorBodySize: editorBodySize,
        imageSize: imageSize,
        snapThreshold: spacingSnapThreshold,
      );

      _layerSpacingHighlightRects
        ..clear()
        ..addAll(spacingResult.highlightRects);

      if (spacingResult.snapDeltaX != 0 || spacingResult.snapDeltaY != 0) {
        activeLayer.offset +=
            Offset(spacingResult.snapDeltaX, spacingResult.snapDeltaY);
      }
    } else {
      _layerSpacingHighlightRects.clear();
    }

    final hasSpacingHighlights = _layerSpacingHighlightRects.isNotEmpty;
    final spacingChanged = !_areRectListsEqual(
        beforeSpacingHighlights, _layerSpacingHighlightRects);

    final hasChanged = isHorizontalGuideVisible != wasHorizontalGuideVisible ||
        isVerticalGuideVisible != wasVerticalGuideVisible ||
        spacingChanged;

    if (hasChanged) {
      helperLineCtrl.add(null);

      if ((isHorizontalGuideVisible && !wasHorizontalGuideVisible) ||
          (isVerticalGuideVisible && !wasVerticalGuideVisible) ||
          (hasSpacingHighlights && !hadSpacingHighlights)) {
        helperLinesCallbacks?.handleLayerAlignLineHit();
      }
    }
  }

  _LayerSpacingGuidesResult _calculateLayerSpacingGuides({
    required List<Layer> layerList,
    required Layer activeLayer,
    required Size editorBodySize,
    required Size imageSize,
    required double snapThreshold,
  }) {
    if (snapThreshold <= 0) {
      return _LayerSpacingGuidesResult.empty;
    }

    if (!activeLayer.enableSpacingHighlight) {
      return _LayerSpacingGuidesResult.empty;
    }

    final activeBounds = _getLayerBoundsSnapshot(activeLayer);
    if (activeBounds == null) {
      return _LayerSpacingGuidesResult.empty;
    }

    final otherBounds = <_LayerBoundsSnapshot>[];
    for (final layer in layerList) {
      if (layer == activeLayer) continue;
      if (!layer.enableSpacingHighlight) continue;
      final bounds = _getLayerBoundsSnapshot(layer);
      if (bounds != null) {
        otherBounds.add(bounds);
      }
    }

    if (otherBounds.isEmpty) {
      return _LayerSpacingGuidesResult.empty;
    }

    final hasOverlap =
        otherBounds.any((item) => item.rect.overlaps(activeBounds.rect));
    if (hasOverlap) {
      return _LayerSpacingGuidesResult.empty;
    }

    final canvasBounds = Rect.fromCenter(
      center: Offset.zero,
      width: imageSize.width,
      height: imageSize.height,
    );

    final horizontalResult = _calculateHorizontalSpacingGuides(
      activeBounds: activeBounds,
      otherBounds: otherBounds,
      canvasBounds: canvasBounds,
      snapThreshold: snapThreshold,
    );

    final verticalResult = _calculateVerticalSpacingGuides(
      activeBounds: activeBounds,
      otherBounds: otherBounds,
      canvasBounds: canvasBounds,
      snapThreshold: snapThreshold,
    );

    final highlightRects = _deduplicateRects([
      ...horizontalResult.highlightRects,
      ...verticalResult.highlightRects,
    ]);

    return _LayerSpacingGuidesResult(
      snapDeltaX: horizontalResult.snapDelta,
      snapDeltaY: verticalResult.snapDelta,
      highlightRects: highlightRects,
    );
  }

  _LayerSpacingAxisResult _calculateHorizontalSpacingGuides({
    required _LayerBoundsSnapshot activeBounds,
    required List<_LayerBoundsSnapshot> otherBounds,
    required Rect canvasBounds,
    required double snapThreshold,
  }) {
    final relevantBounds = otherBounds
        .where((item) =>
            _hasVerticalProjectionOverlap(activeBounds.rect, item.rect))
        .toList();
    if (relevantBounds.isEmpty) {
      return _LayerSpacingAxisResult.empty;
    }

    final references = <_LayerSpacingReference>[];
    for (final item in relevantBounds) {
      final overlapTop = max(activeBounds.rect.top, item.rect.top);
      final overlapBottom = min(activeBounds.rect.bottom, item.rect.bottom);
      if (overlapBottom <= overlapTop) continue;

      final leftMargin = item.rect.left - canvasBounds.left;
      if (leftMargin > 0) {
        references.add(
          _LayerSpacingReference(
            distance: leftMargin,
            highlightRect: Rect.fromLTRB(
              canvasBounds.left,
              overlapTop,
              item.rect.left,
              overlapBottom,
            ),
          ),
        );
      }

      final rightMargin = canvasBounds.right - item.rect.right;
      if (rightMargin > 0) {
        references.add(
          _LayerSpacingReference(
            distance: rightMargin,
            highlightRect: Rect.fromLTRB(
              item.rect.right,
              overlapTop,
              canvasBounds.right,
              overlapBottom,
            ),
          ),
        );
      }
    }

    final sortedBounds = List<_LayerBoundsSnapshot>.from(relevantBounds)
      ..sort((a, b) => a.rect.left.compareTo(b.rect.left));

    for (int i = 0; i < sortedBounds.length; i++) {
      for (int j = i + 1; j < sortedBounds.length; j++) {
        final leftItem = sortedBounds[i];
        final rightItem = sortedBounds[j];

        if (!_hasVerticalProjectionOverlap(leftItem.rect, rightItem.rect)) {
          continue;
        }

        final distance = rightItem.rect.left - leftItem.rect.right;
        if (distance <= 0) continue;

        final top = max(leftItem.rect.top, rightItem.rect.top);
        final bottom = min(leftItem.rect.bottom, rightItem.rect.bottom);
        if (bottom <= top) continue;

        references.add(
          _LayerSpacingReference(
            distance: distance,
            highlightRect: Rect.fromLTRB(
              leftItem.rect.right,
              top,
              rightItem.rect.left,
              bottom,
            ),
          ),
        );
      }
    }

    if (references.isEmpty) {
      return _LayerSpacingAxisResult.empty;
    }

    _LayerSpacingCandidate? bestCandidate;

    void considerCandidate({
      required double delta,
      required double distance,
      required List<Rect> highlightRects,
    }) {
      final deltaAbs = delta.abs();
      if (deltaAbs > snapThreshold) return;

      final deduplicatedRects = _deduplicateRects(highlightRects);
      if (deduplicatedRects.isEmpty) return;

      final candidate = _LayerSpacingCandidate(
        delta: delta,
        distance: distance,
        highlightRects: deduplicatedRects,
      );

      final bestDeltaAbs = bestCandidate?.delta.abs() ?? double.infinity;
      const precision = 0.0001;

      if (deltaAbs < bestDeltaAbs - precision ||
          ((deltaAbs - bestDeltaAbs).abs() <= precision &&
              bestCandidate != null &&
              candidate.highlightRects.length >
                  bestCandidate!.highlightRects.length)) {
        bestCandidate = candidate;
      }
      bestCandidate ??= candidate;
    }

    for (final anchor in relevantBounds) {
      final overlapTop = max(activeBounds.rect.top, anchor.rect.top);
      final overlapBottom = min(activeBounds.rect.bottom, anchor.rect.bottom);
      if (overlapBottom <= overlapTop) continue;

      for (final reference in references) {
        final distance = reference.distance;

        final targetLeftRight = anchor.rect.right + distance;
        final rightDelta = targetLeftRight - activeBounds.rect.left;
        final rightGapRect = Rect.fromLTRB(
          anchor.rect.right,
          overlapTop,
          targetLeftRight,
          overlapBottom,
        );

        considerCandidate(
          delta: rightDelta,
          distance: distance,
          highlightRects: [
            ..._collectRelatedReferenceRects(
              references: references,
              distance: distance,
              snapThreshold: snapThreshold,
            ),
            rightGapRect,
          ],
        );

        final targetLeftLeft =
            anchor.rect.left - distance - activeBounds.rect.width;
        final leftDelta = targetLeftLeft - activeBounds.rect.left;
        final leftGapRect = Rect.fromLTRB(
          targetLeftLeft + activeBounds.rect.width,
          overlapTop,
          anchor.rect.left,
          overlapBottom,
        );

        considerCandidate(
          delta: leftDelta,
          distance: distance,
          highlightRects: [
            ..._collectRelatedReferenceRects(
              references: references,
              distance: distance,
              snapThreshold: snapThreshold,
            ),
            leftGapRect,
          ],
        );
      }
    }

    for (int i = 0; i < sortedBounds.length; i++) {
      for (int j = i + 1; j < sortedBounds.length; j++) {
        final leftItem = sortedBounds[i];
        final rightItem = sortedBounds[j];

        if (!_hasVerticalProjectionOverlap(leftItem.rect, rightItem.rect)) {
          continue;
        }

        final availableSpace =
            rightItem.rect.left - leftItem.rect.right - activeBounds.rect.width;
        if (availableSpace <= 0) continue;

        final distance = availableSpace / 2;
        final targetLeft = leftItem.rect.right + distance;
        final delta = targetLeft - activeBounds.rect.left;

        final leftOverlapTop = max(activeBounds.rect.top, leftItem.rect.top);
        final leftOverlapBottom =
            min(activeBounds.rect.bottom, leftItem.rect.bottom);

        final rightOverlapTop = max(activeBounds.rect.top, rightItem.rect.top);
        final rightOverlapBottom =
            min(activeBounds.rect.bottom, rightItem.rect.bottom);

        final midpointHighlights = <Rect>[
          if (leftOverlapBottom > leftOverlapTop)
            Rect.fromLTRB(
              leftItem.rect.right,
              leftOverlapTop,
              targetLeft,
              leftOverlapBottom,
            ),
          if (rightOverlapBottom > rightOverlapTop)
            Rect.fromLTRB(
              targetLeft + activeBounds.rect.width,
              rightOverlapTop,
              rightItem.rect.left,
              rightOverlapBottom,
            ),
        ];

        considerCandidate(
          delta: delta,
          distance: distance,
          highlightRects: [
            ..._collectRelatedReferenceRects(
              references: references,
              distance: distance,
              snapThreshold: snapThreshold,
            ),
            ...midpointHighlights,
          ],
        );
      }
    }

    if (bestCandidate == null) {
      return _LayerSpacingAxisResult.empty;
    }

    return _LayerSpacingAxisResult(
      snapDelta: bestCandidate!.delta,
      highlightRects: bestCandidate!.highlightRects,
    );
  }

  _LayerSpacingAxisResult _calculateVerticalSpacingGuides({
    required _LayerBoundsSnapshot activeBounds,
    required List<_LayerBoundsSnapshot> otherBounds,
    required Rect canvasBounds,
    required double snapThreshold,
  }) {
    final relevantBounds = otherBounds
        .where((item) =>
            _hasHorizontalProjectionOverlap(activeBounds.rect, item.rect))
        .toList();
    if (relevantBounds.isEmpty) {
      return _LayerSpacingAxisResult.empty;
    }

    final references = <_LayerSpacingReference>[];
    for (final item in relevantBounds) {
      final overlapLeft = max(activeBounds.rect.left, item.rect.left);
      final overlapRight = min(activeBounds.rect.right, item.rect.right);
      if (overlapRight <= overlapLeft) continue;

      final topMargin = item.rect.top - canvasBounds.top;
      if (topMargin > 0) {
        references.add(
          _LayerSpacingReference(
            distance: topMargin,
            highlightRect: Rect.fromLTRB(
              overlapLeft,
              canvasBounds.top,
              overlapRight,
              item.rect.top,
            ),
          ),
        );
      }

      final bottomMargin = canvasBounds.bottom - item.rect.bottom;
      if (bottomMargin > 0) {
        references.add(
          _LayerSpacingReference(
            distance: bottomMargin,
            highlightRect: Rect.fromLTRB(
              overlapLeft,
              item.rect.bottom,
              overlapRight,
              canvasBounds.bottom,
            ),
          ),
        );
      }
    }

    final sortedBounds = List<_LayerBoundsSnapshot>.from(relevantBounds)
      ..sort((a, b) => a.rect.top.compareTo(b.rect.top));

    for (int i = 0; i < sortedBounds.length; i++) {
      for (int j = i + 1; j < sortedBounds.length; j++) {
        final topItem = sortedBounds[i];
        final bottomItem = sortedBounds[j];

        if (!_hasHorizontalProjectionOverlap(topItem.rect, bottomItem.rect)) {
          continue;
        }

        final distance = bottomItem.rect.top - topItem.rect.bottom;
        if (distance <= 0) continue;

        final left = max(topItem.rect.left, bottomItem.rect.left);
        final right = min(topItem.rect.right, bottomItem.rect.right);
        if (right <= left) continue;

        references.add(
          _LayerSpacingReference(
            distance: distance,
            highlightRect: Rect.fromLTRB(
              left,
              topItem.rect.bottom,
              right,
              bottomItem.rect.top,
            ),
          ),
        );
      }
    }

    if (references.isEmpty) {
      return _LayerSpacingAxisResult.empty;
    }

    _LayerSpacingCandidate? bestCandidate;

    void considerCandidate({
      required double delta,
      required double distance,
      required List<Rect> highlightRects,
    }) {
      final deltaAbs = delta.abs();
      if (deltaAbs > snapThreshold) return;

      final deduplicatedRects = _deduplicateRects(highlightRects);
      if (deduplicatedRects.isEmpty) return;

      final candidate = _LayerSpacingCandidate(
        delta: delta,
        distance: distance,
        highlightRects: deduplicatedRects,
      );

      final bestDeltaAbs = bestCandidate?.delta.abs() ?? double.infinity;
      const precision = 0.0001;

      if (deltaAbs < bestDeltaAbs - precision ||
          ((deltaAbs - bestDeltaAbs).abs() <= precision &&
              bestCandidate != null &&
              candidate.highlightRects.length >
                  bestCandidate!.highlightRects.length)) {
        bestCandidate = candidate;
      }
      bestCandidate ??= candidate;
    }

    for (final anchor in relevantBounds) {
      final overlapLeft = max(activeBounds.rect.left, anchor.rect.left);
      final overlapRight = min(activeBounds.rect.right, anchor.rect.right);
      if (overlapRight <= overlapLeft) continue;

      for (final reference in references) {
        final distance = reference.distance;

        final targetTopBottom = anchor.rect.bottom + distance;
        final bottomDelta = targetTopBottom - activeBounds.rect.top;
        final bottomGapRect = Rect.fromLTRB(
          overlapLeft,
          anchor.rect.bottom,
          overlapRight,
          targetTopBottom,
        );

        considerCandidate(
          delta: bottomDelta,
          distance: distance,
          highlightRects: [
            ..._collectRelatedReferenceRects(
              references: references,
              distance: distance,
              snapThreshold: snapThreshold,
            ),
            bottomGapRect,
          ],
        );

        final targetTopTop =
            anchor.rect.top - distance - activeBounds.rect.height;
        final topDelta = targetTopTop - activeBounds.rect.top;
        final topGapRect = Rect.fromLTRB(
          overlapLeft,
          targetTopTop + activeBounds.rect.height,
          overlapRight,
          anchor.rect.top,
        );

        considerCandidate(
          delta: topDelta,
          distance: distance,
          highlightRects: [
            ..._collectRelatedReferenceRects(
              references: references,
              distance: distance,
              snapThreshold: snapThreshold,
            ),
            topGapRect,
          ],
        );
      }
    }

    for (int i = 0; i < sortedBounds.length; i++) {
      for (int j = i + 1; j < sortedBounds.length; j++) {
        final topItem = sortedBounds[i];
        final bottomItem = sortedBounds[j];

        if (!_hasHorizontalProjectionOverlap(topItem.rect, bottomItem.rect)) {
          continue;
        }

        final availableSpace = bottomItem.rect.top -
            topItem.rect.bottom -
            activeBounds.rect.height;
        if (availableSpace <= 0) continue;

        final distance = availableSpace / 2;
        final targetTop = topItem.rect.bottom + distance;
        final delta = targetTop - activeBounds.rect.top;

        final topOverlapLeft = max(activeBounds.rect.left, topItem.rect.left);
        final topOverlapRight =
            min(activeBounds.rect.right, topItem.rect.right);

        final bottomOverlapLeft =
            max(activeBounds.rect.left, bottomItem.rect.left);
        final bottomOverlapRight =
            min(activeBounds.rect.right, bottomItem.rect.right);

        final midpointHighlights = <Rect>[
          if (topOverlapRight > topOverlapLeft)
            Rect.fromLTRB(
              topOverlapLeft,
              topItem.rect.bottom,
              topOverlapRight,
              targetTop,
            ),
          if (bottomOverlapRight > bottomOverlapLeft)
            Rect.fromLTRB(
              bottomOverlapLeft,
              targetTop + activeBounds.rect.height,
              bottomOverlapRight,
              bottomItem.rect.top,
            ),
        ];

        considerCandidate(
          delta: delta,
          distance: distance,
          highlightRects: [
            ..._collectRelatedReferenceRects(
              references: references,
              distance: distance,
              snapThreshold: snapThreshold,
            ),
            ...midpointHighlights,
          ],
        );
      }
    }

    if (bestCandidate == null) {
      return _LayerSpacingAxisResult.empty;
    }

    return _LayerSpacingAxisResult(
      snapDelta: bestCandidate!.delta,
      highlightRects: bestCandidate!.highlightRects,
    );
  }

  _LayerBoundsSnapshot? _getLayerBoundsSnapshot(Layer layer) {
    final renderBox = layer.keyInternalSize.currentContext?.findRenderObject();
    if (renderBox is! RenderBox) return null;

    final size = renderBox.size;
    if (size.isEmpty) return null;

    final normalizedFractionalOffset =
        _getFractionalLayerOffset(layer) + const Offset(0.5, 0.5);

    final center = layer.offset +
        Offset(
          size.width * normalizedFractionalOffset.dx,
          size.height * normalizedFractionalOffset.dy,
        );

    final bounds = _calculateRotatedBounds(
      center: center,
      size: size,
      rotation: layer.rotation,
    );

    return _LayerBoundsSnapshot(layer: layer, rect: bounds);
  }

  Rect _calculateRotatedBounds({
    required Offset center,
    required Size size,
    required double rotation,
  }) {
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    final absCos = cos(rotation).abs();
    final absSin = sin(rotation).abs();

    final aabbHalfWidth = halfWidth * absCos + halfHeight * absSin;
    final aabbHalfHeight = halfWidth * absSin + halfHeight * absCos;

    return Rect.fromCenter(
      center: center,
      width: aabbHalfWidth * 2,
      height: aabbHalfHeight * 2,
    );
  }

  bool _hasVerticalProjectionOverlap(Rect a, Rect b) {
    return min(a.bottom, b.bottom) - max(a.top, b.top) > 0;
  }

  bool _hasHorizontalProjectionOverlap(Rect a, Rect b) {
    return min(a.right, b.right) - max(a.left, b.left) > 0;
  }

  List<Rect> _collectRelatedReferenceRects({
    required List<_LayerSpacingReference> references,
    required double distance,
    required double snapThreshold,
  }) {
    return references
        .where((item) => (item.distance - distance).abs() <= snapThreshold)
        .map((item) => item.highlightRect)
        .toList();
  }

  List<Rect> _deduplicateRects(List<Rect> rects) {
    final uniqueRects = <String, Rect>{};
    for (final rect in rects) {
      if (rect.width <= 0 || rect.height <= 0) continue;
      final key = [
        rect.left.toStringAsFixed(3),
        rect.top.toStringAsFixed(3),
        rect.right.toStringAsFixed(3),
        rect.bottom.toStringAsFixed(3),
      ].join(':');
      uniqueRects[key] = rect;
    }

    final list = uniqueRects.values.toList()
      ..sort((a, b) {
        final leftCompare = a.left.compareTo(b.left);
        if (leftCompare != 0) return leftCompare;
        final topCompare = a.top.compareTo(b.top);
        if (topCompare != 0) return topCompare;
        final rightCompare = a.right.compareTo(b.right);
        if (rightCompare != 0) return rightCompare;
        return a.bottom.compareTo(b.bottom);
      });

    return list;
  }

  bool _areRectListsEqual(List<Rect> first, List<Rect> second) {
    if (first.length != second.length) return false;

    for (int i = 0; i < first.length; i++) {
      final a = first[i];
      final b = second[i];
      if (a.left != b.left ||
          a.top != b.top ||
          a.right != b.right ||
          a.bottom != b.bottom) {
        return false;
      }
    }
    return true;
  }
}

class _LayerBoundsSnapshot {
  const _LayerBoundsSnapshot({
    required this.layer,
    required this.rect,
  });

  final Layer layer;
  final Rect rect;
}

class _LayerSpacingReference {
  const _LayerSpacingReference({
    required this.distance,
    required this.highlightRect,
  });

  final double distance;
  final Rect highlightRect;
}

class _LayerSpacingCandidate {
  const _LayerSpacingCandidate({
    required this.delta,
    required this.distance,
    required this.highlightRects,
  });

  final double delta;
  final double distance;
  final List<Rect> highlightRects;
}

class _LayerSpacingAxisResult {
  const _LayerSpacingAxisResult({
    required this.snapDelta,
    required this.highlightRects,
  });

  final double snapDelta;
  final List<Rect> highlightRects;

  static const empty = _LayerSpacingAxisResult(
    snapDelta: 0,
    highlightRects: [],
  );
}

class _LayerSpacingGuidesResult {
  const _LayerSpacingGuidesResult({
    required this.snapDeltaX,
    required this.snapDeltaY,
    required this.highlightRects,
  });

  final double snapDeltaX;
  final double snapDeltaY;
  final List<Rect> highlightRects;

  static const empty = _LayerSpacingGuidesResult(
    snapDeltaX: 0,
    snapDeltaY: 0,
    highlightRects: [],
  );
}

class _LayerAlignGuideHelper {
  LayerLastPosition _lastSnapPosition = LayerLastPosition.center;
  Offset _lastSnapOffset = Offset.infinite;
  double? _lastSnapFocal;

  /// Returns true if snapping should occur, otherwise false
  bool maybeSnap({
    required double focal,
    required double focalDelta,
    required Offset offset,
    required double threshold,
    required double releaseThreshold,
    required LayerLastPosition positiveDirection,
    required LayerLastPosition negativeDirection,
  }) {
    final diff = (_lastSnapFocal ?? focal) - focal;

    if (_lastSnapFocal == null || diff.abs() < releaseThreshold) {
      final newPosition =
          focalDelta > 0 ? positiveDirection : negativeDirection;

      if (newPosition != _lastSnapPosition || _lastSnapOffset != offset) {
        _lastSnapFocal ??= focal;
        _lastSnapOffset = offset;
        _lastSnapPosition = LayerLastPosition.center;
        return true;
      }
    } else if (diff.abs() > releaseThreshold) {
      _lastSnapPosition =
          focal > _lastSnapFocal! ? positiveDirection : negativeDirection;
      _lastSnapFocal = null;
    }

    return false;
  }
}
