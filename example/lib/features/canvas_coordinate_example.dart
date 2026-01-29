import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '/core/constants/example_constants.dart';
import '/core/mixin/example_helper.dart';

/// An example demonstrating canvas alignment and coordinate system
/// configuration.
///
/// This example shows how to:
/// - Set the background image alignment (e.g., centerTop)
/// - Configure the coordinate system origin (topLeft vs center)
/// - Use a custom background image builder
/// - Print layer coordinates in real-time
class CanvasCoordinateExample extends StatefulWidget {
  /// Creates a new [CanvasCoordinateExample] widget.
  const CanvasCoordinateExample({super.key});

  @override
  State<CanvasCoordinateExample> createState() =>
      _CanvasCoordinateExampleState();
}

class _CanvasCoordinateExampleState extends State<CanvasCoordinateExample>
    with ExampleHelperState<CanvasCoordinateExample> {
  CanvasAlignment _canvasAlignment = CanvasAlignment.centerTop;
  CoordinateOrigin _coordinateOrigin = CoordinateOrigin.topLeft;
  bool _useCustomBgBuilder = false;

  // Store layer info for display
  String _layerInfo = 'No layers yet';

  late ProImageEditorConfigs _configs;
  late ProImageEditorCallbacks _callbacks;

  @override
  void initState() {
    super.initState();
    _updateConfigs();
  }

  void _updateConfigs() {
    _configs = ProImageEditorConfigs(
      designMode: platformDesignMode,
      mainEditor: MainEditorConfigs(
        canvasAlignment: _canvasAlignment,
        coordinateOrigin: _coordinateOrigin,
        bgImageBuilder: _useCustomBgBuilder ? _customBgImageBuilder : null,
      ),
    );

    _callbacks = ProImageEditorCallbacks(
      onImageEditingStarted: onImageEditingStarted,
      onImageEditingComplete: onImageEditingComplete,
      onCloseEditor: (editorMode) => onCloseEditor(editorMode: editorMode),
      mainEditorCallbacks: MainEditorCallbacks(
        helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
        onUpdateUI: _onUpdateUI,
      ),
    );
  }

  /// Custom background image builder example
  Widget _customBgImageBuilder(
    EditorImage? image,
    Size imageSize,
    ProImageEditorConfigs configs,
  ) {
    if (image == null) {
      return Container(
        width: imageSize.width,
        height: imageSize.height,
        color: Colors.grey[300],
        child: const Center(
          child: Text('No Image', style: TextStyle(fontSize: 24)),
        ),
      );
    }

    // Add a custom border around the image
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 3),
      ),
      child: Image.asset(
        kImageEditorExampleAssetPath,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Called when the editor UI updates - we use this to print layer coordinates
  void _onUpdateUI() {
    final state = editorKey.currentState;
    if (state == null) return;

    final layers = state.activeLayers;
    if (layers.isEmpty) {
      _layerInfo = 'No layers';
    } else {
      final buffer = StringBuffer()
        ..writeln('=== Layer Coordinates ===')
        ..writeln('Origin: ${_coordinateOrigin.name}')
        ..writeln('');

      for (int i = 0; i < layers.length; i++) {
        final layer = layers[i];
        final dx = layer.offset.dx.toStringAsFixed(1);
        final dy = layer.offset.dy.toStringAsFixed(1);
        final scale = layer.scale.toStringAsFixed(2);
        final rotation = (layer.rotation * 180 / 3.14159).toStringAsFixed(1);

        buffer
          ..writeln('Layer ${i + 1} (${_getLayerType(layer)}):')
          ..writeln('  offset: ($dx, $dy)')
          ..writeln('  scale: $scale')
          ..writeln('  rotation: $rotation°')
          ..writeln('');
      }

      _layerInfo = buffer.toString();

      // Print to console
      if (kDebugMode) {
        // ignore: avoid_print
        print(_layerInfo);
      }
    }
  }

  String _getLayerType(Layer layer) {
    if (layer is TextLayer) return 'Text';
    if (layer is EmojiLayer) return 'Emoji';
    if (layer is PaintLayer) return 'Paint';
    if (layer is WidgetLayer) return 'Widget';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas & Coordinate Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Canvas Alignment Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Canvas Alignment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Controls where the background image is positioned',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CanvasAlignment.values.map((alignment) {
                      return ChoiceChip(
                        label: Text(alignment.name),
                        selected: _canvasAlignment == alignment,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _canvasAlignment = alignment;
                              _updateConfigs();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Coordinate Origin Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coordinate Origin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Controls the origin point for layer positioning'),
                  const SizedBox(height: 12),
                  Row(
                    children: CoordinateOrigin.values.map((origin) {
                      return Expanded(
                        child: RadioListTile<CoordinateOrigin>(
                          title: Text(origin.name),
                          subtitle: Text(
                            origin == CoordinateOrigin.topLeft
                                ? '(0,0) = top-left'
                                : '(0,0) = center',
                          ),
                          value: origin,
                          groupValue: _coordinateOrigin,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _coordinateOrigin = value;
                                _updateConfigs();
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Custom Background Builder Toggle
          Card(
            child: SwitchListTile(
              title: const Text('Use Custom Background Builder'),
              subtitle: const Text('Adds a blue border around the image'),
              value: _useCustomBgBuilder,
              onChanged: (value) {
                setState(() {
                  _useCustomBgBuilder = value;
                  _updateConfigs();
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          // Open Editor Button
          ElevatedButton.icon(
            onPressed: () async {
              await precacheImage(
                AssetImage(kImageEditorExampleAssetPath),
                context,
              );
              if (!context.mounted) return;

              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => _buildEditor()),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Open Editor'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 24),

          // Layer Info Display
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Layer Coordinates (Console)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _layerInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return ProImageEditor.asset(
      kImageEditorExampleAssetPath,
      key: editorKey,
      callbacks: _callbacks,
      configs: _configs,
    );
  }
}
