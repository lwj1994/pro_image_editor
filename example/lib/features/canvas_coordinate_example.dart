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
/// - Use contentOnly mode to render only the canvas
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
  CoordinateOrigin _coordinateOrigin = CoordinateOrigin.center;
  bool _useCustomBgBuilder = false;
  bool _useCustomCanvasSize = false;
  bool _contentOnly = false;
  double _canvasWidth = 300;
  double _canvasHeight = 400;

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
        coordinateOrigin: _coordinateOrigin,
        contentOnly: _contentOnly,
        canvasSize:
            _useCustomCanvasSize ? Size(_canvasWidth, _canvasHeight) : null,
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
          ..writeln('  offset: Offset($dx, $dy)')
          ..writeln('  scale: $scale')
          ..writeln('  rotation: $rotation°')
          ..writeln('');

        // Print layer offset to console when moving
        if (kDebugMode) {
          // ignore: avoid_print
          print('Layer ${_getLayerType(layer)} offset: Offset($dx, $dy)');
        }
      }

      _layerInfo = buffer.toString();
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

          const SizedBox(height: 16),

          // Content Only Mode Toggle
          Card(
            child: SwitchListTile(
              title: const Text('Content Only Mode'),
              subtitle: const Text(
                'Renders only canvas without Scaffold, AppBar, BottomBar',
              ),
              value: _contentOnly,
              onChanged: (value) {
                setState(() {
                  _contentOnly = value;
                  _updateConfigs();
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Canvas Size Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Use Custom Canvas Size'),
                    subtitle: const Text(
                      'Constrain canvas to a fixed size instead of full body',
                    ),
                    value: _useCustomCanvasSize,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _useCustomCanvasSize = value;
                        _updateConfigs();
                      });
                    },
                  ),
                  if (_useCustomCanvasSize) ...[
                    const SizedBox(height: 16),
                    Text('Width: ${_canvasWidth.toInt()}'),
                    Slider(
                      value: _canvasWidth,
                      min: 100,
                      max: 500,
                      divisions: 40,
                      label: _canvasWidth.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          _canvasWidth = value;
                          _updateConfigs();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Height: ${_canvasHeight.toInt()}'),
                    Slider(
                      value: _canvasHeight,
                      min: 100,
                      max: 700,
                      divisions: 60,
                      label: _canvasHeight.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          _canvasHeight = value;
                          _updateConfigs();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Canvas Size: ${_canvasWidth.toInt()} x '
                      '${_canvasHeight.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
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
    if (_contentOnly) {
      return _ContentOnlyEditorPage(
        configs: _configs,
        callbacks: _callbacks,
        editorKey: editorKey,
      );
    }
    return ProImageEditor.asset(
      kImageEditorExampleAssetPath,
      key: editorKey,
      callbacks: _callbacks,
      configs: _configs,
    );
  }
}

/// A page that demonstrates contentOnly mode with custom UI controls
class _ContentOnlyEditorPage extends StatelessWidget {
  const _ContentOnlyEditorPage({
    required this.configs,
    required this.callbacks,
    required this.editorKey,
  });

  final ProImageEditorConfigs configs;
  final ProImageEditorCallbacks callbacks;
  final GlobalKey<ProImageEditorState> editorKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Only Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions),
            tooltip: 'Add Emoji',
            onPressed: () => editorKey.currentState?.openEmojiEditor(),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Done',
            onPressed: () => editorKey.currentState?.doneEditing(),
          ),
        ],
      ),
      body: ProImageEditor.asset(
        kImageEditorExampleAssetPath,
        key: editorKey,
        callbacks: callbacks,
        configs: configs,
      ),
    );
  }
}
