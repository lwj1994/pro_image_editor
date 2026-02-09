// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:pro_image_editor/pro_image_editor.dart';

// Project imports:
import '/core/constants/example_constants.dart';
import '/core/mixin/example_helper.dart';

/// Example that demonstrates the padding highlight while dragging layers.
class PaddingHighlightExample extends StatefulWidget {
  /// Creates a new [PaddingHighlightExample] widget.
  const PaddingHighlightExample({super.key});

  @override
  State<PaddingHighlightExample> createState() =>
      _PaddingHighlightExampleState();
}

class _PaddingHighlightExampleState extends State<PaddingHighlightExample>
    with ExampleHelperState<PaddingHighlightExample> {
  bool _layersInserted = false;

  @override
  void initState() {
    super.initState();
    preCacheImage(assetPath: kImageEditorExampleAssetPath);
  }

  void _onAfterViewInit() {
    if (_layersInserted) return;
    _layersInserted = true;

    final editor = editorKey.currentState;
    if (editor == null) return;

    editor
      ..addLayer(
        WidgetLayer(
          offset: const Offset(-160, -40),
          widget: _buildCard(
            title: 'A',
            subtitle: 'Drag me',
            color: const Color(0xFFF7C97C),
          ),
        ),
      )
      ..addLayer(
        WidgetLayer(
          offset: const Offset(160, 40),
          widget: _buildCard(
            title: 'B',
            subtitle: 'Gap target',
            color: const Color(0xFFEDEDED),
          ),
        ),
      );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 160,
      height: 230,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Container(
            height: 10,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 110,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
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
      onAfterViewInit: _onAfterViewInit,
      helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
    ),
  );

  late final _configs = ProImageEditorConfigs(
    designMode: platformDesignMode,
    helperLines: const HelperLineConfigs(
      showVerticalLine: false,
      showHorizontalLine: false,
      showRotateLine: false,
      showLayerAlignLine: true,
      style: HelperLineStyle(
        layerAlignColor: Color(0xFFF2A15B),
      ),
    ),
    layerInteraction: const LayerInteractionConfigs(
      selectable: LayerInteractionSelectable.enabled,
      initialSelected: true,
      focusInteractionOnSelectedLayer: true,
      style: LayerInteractionStyle(
        overlayPadding: EdgeInsets.all(20),
        borderColor: Color(0xFFF2A15B),
        borderStyle: LayerInteractionBorderStyle.solid,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!isPreCached) return const PrepareImageWidget();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Padding Highlight'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFF3E6),
            child: const Text(
              'Drag layer A near layer B or the canvas edges to see the '
              'orange padding highlight.',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ProImageEditor.asset(
              kImageEditorExampleAssetPath,
              key: editorKey,
              configs: _configs,
              callbacks: _callbacks,
            ),
          ),
        ],
      ),
    );
  }
}
