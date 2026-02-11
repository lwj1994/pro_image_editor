// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:pro_image_editor/pro_image_editor.dart';

// Project imports:
import '/core/constants/example_constants.dart';
import '/core/mixin/example_helper.dart';

/// Demonstrates the [MainEditorCallbacks.onTap] callback.
///
/// When the user taps on the editor body, the callback
/// provides:
/// - [Offset] localPosition: the tap coordinates
///   relative to the body area.
/// - [Layer]? layer: the tapped layer, or `null`
///   if no layer was hit.
///
/// A log panel at the bottom displays each tap event.
class CanvasTapExample extends StatefulWidget {
  /// Creates a new [CanvasTapExample] widget.
  const CanvasTapExample({super.key});

  @override
  State<CanvasTapExample> createState() => _CanvasTapExampleState();
}

class _CanvasTapExampleState extends State<CanvasTapExample>
    with ExampleHelperState<CanvasTapExample> {
  /// Stores the recent tap log entries.
  final List<String> _tapLogs = [];

  /// Maximum number of log entries to keep.
  static const int _maxLogEntries = 20;

  @override
  void initState() {
    super.initState();
    preCacheImage(
      assetPath: kImageEditorExampleAssetPath,
    );
  }

  /// Handles the onTap callback from the editor.
  void _handleTap(
    Offset localPosition,
    Layer? layer,
  ) {
    final posStr = '(${localPosition.dx.toStringAsFixed(1)}, '
        '${localPosition.dy.toStringAsFixed(1)})';

    String log;
    if (layer != null) {
      String layerType = 'Unknown';
      if (layer is TextLayer) {
        layerType = 'Text';
      } else if (layer is EmojiLayer) {
        layerType = 'Emoji';
      } else if (layer is WidgetLayer) {
        layerType = 'Widget';
      } else if (layer is PaintLayer) {
        layerType = 'Paint';
      }
      log = '🎯 Layer tapped: '
          '$layerType at $posStr';
    } else {
      log = '🖱️ Canvas tapped at $posStr';
    }

    setState(() {
      _tapLogs.insert(0, log);
      if (_tapLogs.length > _maxLogEntries) {
        _tapLogs.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isPreCached) {
      return const PrepareImageWidget();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas Tap Example'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ProImageEditor.asset(
              kImageEditorExampleAssetPath,
              callbacks: ProImageEditorCallbacks(
                onImageEditingStarted: onImageEditingStarted,
                onImageEditingComplete: onImageEditingComplete,
                onCloseEditor: (editorMode) => onCloseEditor(
                  editorMode: editorMode,
                  enablePop: !isDesktopMode(context),
                ),
                mainEditorCallbacks: MainEditorCallbacks(
                  onTap: _handleTap,
                  helperLines: HelperLinesCallbacks(
                    onLineHit: vibrateLineHit,
                  ),
                ),
              ),
              configs: ProImageEditorConfigs(
                designMode: platformDesignMode,
                mainEditor: MainEditorConfigs(
                  enableCloseButton: !isDesktopMode(context),
                ),
                layerInteraction: const LayerInteractionConfigs(
                  selectable: LayerInteractionSelectable.enabled,
                  initialSelected: true,
                ),
                imageGeneration: const ImageGenerationConfigs(
                  processorConfigs: ProcessorConfigs(
                    processorMode: ProcessorMode.auto,
                  ),
                ),
              ),
            ),
          ),
          // Tap log panel
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Tap Events',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_tapLogs.isNotEmpty)
                        GestureDetector(
                          onTap: _tapLogs.clear,
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  color: Colors.white24,
                ),
                Expanded(
                  child: _tapLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'Tap on the canvas '
                            'or a layer...',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          itemCount: _tapLogs.length,
                          itemBuilder: (_, i) {
                            return Text(
                              _tapLogs[i],
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
