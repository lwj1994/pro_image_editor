import 'package:example/core/constants/example_constants.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '/core/mixin/example_helper.dart';

/// Example page for testing layer-edge align and equal-spacing highlights.
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
    final alignDemoY = -(bodySize.height * 0.22).clamp(72.0, 130.0);

    final leftEdge = -bodySize.width / 2;
    final rightEdge = bodySize.width / 2;

    final anchorWidth = (blockWidth * 1.08).clamp(88.0, 132.0);
    final anchorHeight = (blockHeight * 1.16).clamp(64.0, 96.0);
    final dragWidth = (blockWidth * 0.78).clamp(64.0, 104.0);
    final dragHeight = (blockHeight * 0.82).clamp(52.0, 78.0);

    final aCenterX = leftEdge + spacing + anchorWidth / 2;
    final bCenterX = aCenterX + anchorWidth / 2 + dragWidth / 2 + spacing * 1.2;
    final bCenterY = alignDemoY + spacing * 0.4;

    final spacingDemoY = alignDemoY + anchorHeight / 2 + blockHeight + spacing;
    final s1CenterX = leftEdge + spacing + blockWidth / 2;
    final s2CenterX = s1CenterX + blockWidth + spacing;
    final s3TargetX = s2CenterX + blockWidth + spacing;
    final s3StartX = (s3TargetX + spacing * 0.9)
        .clamp(s1CenterX + blockWidth, rightEdge - 20);

    editor
      // Edge align demo (A-B): drag B around A to trigger top/bottom/left/right
      // helper line highlight and snapping.
      ..addLayer(
        WidgetLayer(
          offset: Offset(aCenterX, alignDemoY),
          widget: _buildBlock(
            label: 'A (anchor)',
            color: Colors.indigo.shade600,
            width: anchorWidth,
            height: anchorHeight,
          ),
        ),
        blockCaptureScreenshot: true,
      )
      ..addLayer(
        WidgetLayer(
          offset: Offset(bCenterX, bCenterY),
          widget: _buildBlock(
            label: 'B (drag)',
            color: Colors.deepOrange.shade500,
            width: dragWidth,
            height: dragHeight,
          ),
        ),
        blockCaptureScreenshot: true,
      )
      // Equal-spacing demo (S1-S3): drag S3 toward S2 to see gap highlights.
      ..addLayer(
        WidgetLayer(
          offset: Offset(s1CenterX, spacingDemoY),
          widget: _buildBlock(
            label: 'S1',
            color: Colors.blue.shade600,
            width: blockWidth,
            height: blockHeight,
          ),
        ),
        blockCaptureScreenshot: true,
      )
      ..addLayer(
        WidgetLayer(
          offset: Offset(s2CenterX, spacingDemoY),
          widget: _buildBlock(
            label: 'S2',
            color: Colors.orange.shade600,
            width: blockWidth,
            height: blockHeight,
          ),
        ),
        blockCaptureScreenshot: true,
      )
      ..addLayer(
        WidgetLayer(
          offset: Offset(s3StartX, spacingDemoY),
          widget: _buildBlock(
            label: 'S3',
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
          offset: Offset(s1CenterX, spacingDemoY + blockHeight + spacing),
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
          width: 320,
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
                '1. Drag B around A\n'
                '   Top/Bottom/Left/Right edge align shows a purple guide line\n'
                '2. Drag S3 towards S2\n'
                '   Margin/gap blocks highlight in green and spacing snaps\n'
                '3. D (grey) is excluded from spacing highlights',
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
