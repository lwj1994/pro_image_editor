// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:pro_image_editor/pro_image_editor.dart';

// Project imports:
import '/core/constants/example_constants.dart';
import '/core/mixin/example_helper.dart';

/// A widget that demonstrates the focus interaction on selected layer feature.
///
/// When [focusInteractionOnSelectedLayer] is enabled, selecting a layer will
/// block gesture interactions (move, scale, rotate) on all other non-selected
/// layers. This prevents accidental interactions with other layers while
/// focusing on a specific layer.
///
/// Example usage:
/// ```dart
/// FocusLayerInteractionExample();
/// ```
class FocusLayerInteractionExample extends StatefulWidget {
  /// Creates a new [FocusLayerInteractionExample] widget.
  const FocusLayerInteractionExample({super.key});

  @override
  State<FocusLayerInteractionExample> createState() =>
      _FocusLayerInteractionExampleState();
}

class _FocusLayerInteractionExampleState
    extends State<FocusLayerInteractionExample>
    with ExampleHelperState<FocusLayerInteractionExample> {
  /// Whether the focus interaction feature is enabled.
  bool _focusEnabled = true;

  @override
  void initState() {
    super.initState();
    preCacheImage(assetPath: kImageEditorExampleAssetPath);
  }

  @override
  Widget build(BuildContext context) {
    if (!isPreCached) return const PrepareImageWidget();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Layer Interaction'),
        actions: [
          Row(
            children: [
              const Text('Focus Mode'),
              Switch(
                value: _focusEnabled,
                onChanged: (value) {
                  setState(() {
                    _focusEnabled = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(
              _focusEnabled
                  ? '✅ Focus Mode ON: When a layer is selected, '
                      'other layers ignore gestures.'
                  : '❌ Focus Mode OFF: All layers respond to gestures.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ProImageEditor.asset(
              kImageEditorExampleAssetPath,
              key: ValueKey(_focusEnabled),
              callbacks: ProImageEditorCallbacks(
                onImageEditingStarted: onImageEditingStarted,
                onImageEditingComplete: onImageEditingComplete,
                onCloseEditor: (editorMode) => onCloseEditor(
                  editorMode: editorMode,
                  enablePop: !isDesktopMode(context),
                ),
                mainEditorCallbacks: MainEditorCallbacks(
                  helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
                ),
              ),
              configs: ProImageEditorConfigs(
                designMode: platformDesignMode,
                mainEditor: MainEditorConfigs(
                  enableCloseButton: !isDesktopMode(context),
                ),
                imageGeneration: const ImageGenerationConfigs(
                  processorConfigs: ProcessorConfigs(
                    processorMode: ProcessorMode.auto,
                  ),
                ),
                layerInteraction: LayerInteractionConfigs(
                  /// Enable layer selection mode.
                  selectable: LayerInteractionSelectable.enabled,

                  /// Automatically select newly created layers.
                  initialSelected: true,

                  /// When enabled, selecting a layer blocks gestures on
                  /// all other non-selected layers.
                  focusInteractionOnSelectedLayer: _focusEnabled,

                  style: const LayerInteractionStyle(
                    buttonRadius: 10,
                    strokeWidth: 1.2,
                    borderElementWidth: 7,
                    borderElementSpace: 5,
                    borderColor: Colors.blue,
                    borderStyle: LayerInteractionBorderStyle.solid,
                    showTooltips: true,
                  ),
                ),
                i18n: const I18n(
                  layerInteraction: I18nLayerInteraction(
                    remove: 'Remove',
                    edit: 'Edit',
                    rotateScale: 'Rotate and Scale',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
