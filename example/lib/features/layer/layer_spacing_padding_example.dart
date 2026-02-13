import 'package:example/core/constants/example_constants.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '/core/mixin/example_helper.dart';

/// Example page for testing equal-spacing snap and padding highlights.
class LayerSpacingPaddingExample extends StatefulWidget {
  /// Creates a new [LayerSpacingPaddingExample] widget.
  const LayerSpacingPaddingExample({super.key});

  @override
  State<LayerSpacingPaddingExample> createState() =>
      _LayerSpacingPaddingExampleState();
}

class _LayerSpacingPaddingExampleState extends State<LayerSpacingPaddingExample>
    with ExampleHelperState<LayerSpacingPaddingExample> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    preCacheImage(assetPath: kImageEditorExampleAssetPath);
  }

  void _seedDemoLayers() {
    final editor = editorKey.currentState;
    if (editor == null || _seeded) return;
    _seeded = true;

    editor.removeAllLayers();

    final bodySize = editor.sizesManager.bodySize;
    final spacing = (bodySize.width * 0.08).clamp(20.0, 44.0);
    final blockWidth = (bodySize.width * 0.20).clamp(72.0, 120.0);
    final blockHeight = (bodySize.height * 0.10).clamp(56.0, 84.0);
    final y = -(bodySize.height * 0.18).clamp(64.0, 120.0);

    final leftEdge = -bodySize.width / 2;
    final rightEdge = bodySize.width / 2;

    final aCenterX = leftEdge + spacing + blockWidth / 2;
    final bCenterX = aCenterX + blockWidth + spacing;

    final cTargetX = bCenterX + blockWidth + spacing;
    final cStartX =
        (cTargetX + spacing * 0.9).clamp(aCenterX + blockWidth, rightEdge - 20);

    editor
      ..addLayer(
        WidgetLayer(
          offset: Offset(aCenterX, y),
          widget: _buildBlock(
            label: 'A',
            color: Colors.blue.shade600,
            width: blockWidth,
            height: blockHeight,
          ),
        ),
        blockCaptureScreenshot: true,
      )
      ..addLayer(
        WidgetLayer(
          offset: Offset(bCenterX, y),
          widget: _buildBlock(
            label: 'B',
            color: Colors.orange.shade600,
            width: blockWidth,
            height: blockHeight,
          ),
        ),
        blockCaptureScreenshot: true,
      )
      ..addLayer(
        WidgetLayer(
          offset: Offset(cStartX, y),
          widget: _buildBlock(
            label: 'C',
            color: Colors.green.shade600,
            width: blockWidth,
            height: blockHeight,
          ),
        ),
        blockCaptureScreenshot: true,
      )
      // Layer D: excluded from spacing highlight via enableSpacingHighlight
      ..addLayer(
        WidgetLayer(
          enableSpacingHighlight: false,
          offset: Offset(aCenterX, y + blockHeight + spacing),
          widget: _buildBlock(
            label: 'D (ignored)',
            color: Colors.grey.shade500,
            width: blockWidth,
            height: blockHeight,
          ),
        ),
        blockCaptureScreenshot: true,
      )
      ..unselectAllLayers();
  }

  Widget _buildBlock({
    required String label,
    required Color color,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTipsPanel(ProImageEditorState editor) {
    if (editor.isLayerBeingTransformed || editor.isSubEditorOpen) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      bottom: 12,
      child: GestureInterceptor(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Spacing Demo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '1. Drag C towards B\n'
                '2. Watch margin/gap blocks highlight\n'
                '3. Snap triggers when equal spacing is near\n'
                '4. D (grey) is excluded from highlights',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  _seeded = false;
                  _seedDemoLayers();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset Demo Layers'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  late final _callbacks = ProImageEditorCallbacks(
    onImageEditingStarted: onImageEditingStarted,
    onImageEditingComplete: onImageEditingComplete,
    onCloseEditor: (editorMode) => onCloseEditor(
      editorMode: editorMode,
      enablePop: !isDesktopMode(context),
    ),
    mainEditorCallbacks: MainEditorCallbacks(
      onAfterViewInit: _seedDemoLayers,
      helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!isPreCached) return const PrepareImageWidget();

    return ProImageEditor.asset(
      kImageEditorExampleAssetPath,
      key: editorKey,
      callbacks: _callbacks,
      configs: ProImageEditorConfigs(
        designMode: platformDesignMode,
        helperLines: const HelperLineConfigs(
          showVerticalLine: true,
          showHorizontalLine: true,
          showRotateLine: true,
          showLayerAlignLine: true,
          showLayerSpacingLine: true,
          layerSpacingSnapThreshold: 7,
          style: HelperLineStyle(
            layerSpacingColor: Color(0x6634A853),
          ),
        ),
        layerInteraction: const LayerInteractionConfigs(
          selectable: LayerInteractionSelectable.enabled,
          initialSelected: false,
        ),
        mainEditor: MainEditorConfigs(
          enableCloseButton: !isDesktopMode(context),
          widgets: MainEditorWidgets(
            bodyItems: (editor, rebuildStream) => [
              ReactiveWidget(
                stream: rebuildStream,
                builder: (_) => _buildTipsPanel(editor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
