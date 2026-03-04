import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/core/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/core/models/layers/layer.dart';
import 'package:pro_image_editor/features/main_editor/services/layer_interaction_manager.dart';

const _kEditorBodySize = Size(200, 100);
const _kImageSize = Size(200, 100);

const _kTestConfigs = ProImageEditorConfigs(
  helperLines: HelperLineConfigs(
    showVerticalLine: false,
    showHorizontalLine: false,
    showRotateLine: false,
    showLayerAlignLine: true,
    showLayerSpacingLine: false,
  ),
);

const _kCenterOffsetConfigs = ProImageEditorConfigs(
  helperLines: HelperLineConfigs(
    showVerticalLine: false,
    showHorizontalLine: false,
    showRotateLine: false,
    showLayerAlignLine: true,
    showLayerSpacingLine: false,
  ),
  stickerEditor: StickerEditorConfigs(
    layerFractionalOffset: Offset.zero,
  ),
);

LayerInteractionManager _createManager({
  ProImageEditorConfigs configs = _kTestConfigs,
}) {
  return LayerInteractionManager(
    helperLinesCallbacks: null,
    configs: configs,
    onSelectedLayerChanged: null,
    onSelectedLayersChanged: (_) {},
  );
}

Layer _layer(double x, double y) => Layer(offset: Offset(x, y));

WidgetLayer _widgetLayer(double x, double y) => WidgetLayer(
      offset: Offset(x, y),
      widget: const SizedBox.shrink(),
    );

Future<BuildContext> _pumpHarness({
  required WidgetTester tester,
  required List<Layer> layers,
  required GlobalKey removeAreaKey,
  Map<String, Size> layerSizes = const {},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          key: const ValueKey('layer-align-test-stack'),
          children: [
            for (final layer in layers)
              Builder(builder: (_) {
                final size = layerSizes[layer.id] ?? const Size(20, 20);
                return SizedBox(
                  key: layer.keyInternalSize,
                  width: size.width,
                  height: size.height,
                );
              }),
            Positioned(
              left: 300,
              top: 300,
              child: SizedBox(
                key: removeAreaKey,
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.element(find.byKey(const ValueKey('layer-align-test-stack')));
}

void _runMovement({
  required LayerInteractionManager manager,
  required BuildContext context,
  required Layer activeLayer,
  required List<Layer> layers,
  required GlobalKey removeAreaKey,
  required StreamController<void> helperLineCtrl,
  Offset focalPoint = const Offset(0, 0),
  Offset focalPointDelta = Offset.zero,
}) {
  manager.calculateMovement(
    editorScaleFactor: 1,
    editorBodySize: _kEditorBodySize,
    imageSize: _kImageSize,
    context: context,
    detail: ScaleUpdateDetails(
      focalPoint: focalPoint,
      localFocalPoint: focalPoint,
      focalPointDelta: focalPointDelta,
    ),
    selectedLayers: [activeLayer],
    layerList: layers,
    removeAreaKey: removeAreaKey,
    onHoveredRemoveChanged: (_) {},
    helperLineCtrl: helperLineCtrl,
  );
}

void main() {
  group('Layer edge align snap', () {
    testWidgets('snaps top edge to top edge and shows top guide',
        (tester) async {
      final manager = _createManager();
      final anchor = _layer(0, 10);
      final active = _layer(50, 5);
      final layers = [anchor, active];
      final removeAreaKey = GlobalKey();
      final context = await _pumpHarness(
        tester: tester,
        layers: layers,
        removeAreaKey: removeAreaKey,
        layerSizes: {
          anchor.id: const Size(30, 30),
          active.id: const Size(20, 20),
        },
      );
      final helperLineCtrl = StreamController<void>.broadcast();
      addTearDown(helperLineCtrl.close);

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
      );

      expect(active.offset.dy, closeTo(5, 0.001));
      expect(manager.isHorizontalGuideVisible, isTrue);
      expect(manager.horizontalGuideOffset.dy, closeTo(-5, 0.001));
    });

    testWidgets('snaps bottom edge to bottom edge and shows bottom guide',
        (tester) async {
      final manager = _createManager();
      final anchor = _layer(0, 10);
      final active = _layer(50, 15);
      final layers = [anchor, active];
      final removeAreaKey = GlobalKey();
      final context = await _pumpHarness(
        tester: tester,
        layers: layers,
        removeAreaKey: removeAreaKey,
        layerSizes: {
          anchor.id: const Size(30, 30),
          active.id: const Size(20, 20),
        },
      );
      final helperLineCtrl = StreamController<void>.broadcast();
      addTearDown(helperLineCtrl.close);

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
      );

      expect(active.offset.dy, closeTo(15, 0.001));
      expect(manager.isHorizontalGuideVisible, isTrue);
      expect(manager.horizontalGuideOffset.dy, closeTo(25, 0.001));
    });

    testWidgets('snaps left edge to left edge and shows left guide',
        (tester) async {
      final manager = _createManager();
      final anchor = _layer(10, 0);
      final active = _layer(5, 40);
      final layers = [anchor, active];
      final removeAreaKey = GlobalKey();
      final context = await _pumpHarness(
        tester: tester,
        layers: layers,
        removeAreaKey: removeAreaKey,
        layerSizes: {
          anchor.id: const Size(30, 30),
          active.id: const Size(20, 20),
        },
      );
      final helperLineCtrl = StreamController<void>.broadcast();
      addTearDown(helperLineCtrl.close);

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
      );

      expect(active.offset.dx, closeTo(5, 0.001));
      expect(manager.isVerticalGuideVisible, isTrue);
      expect(manager.verticalGuideOffset.dx, closeTo(-5, 0.001));
    });

    testWidgets('snaps right edge to right edge and shows right guide',
        (tester) async {
      final manager = _createManager();
      final anchor = _layer(10, 0);
      final active = _layer(15, 40);
      final layers = [anchor, active];
      final removeAreaKey = GlobalKey();
      final context = await _pumpHarness(
        tester: tester,
        layers: layers,
        removeAreaKey: removeAreaKey,
        layerSizes: {
          anchor.id: const Size(30, 30),
          active.id: const Size(20, 20),
        },
      );
      final helperLineCtrl = StreamController<void>.broadcast();
      addTearDown(helperLineCtrl.close);

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
      );

      expect(active.offset.dx, closeTo(15, 0.001));
      expect(manager.isVerticalGuideVisible, isTrue);
      expect(manager.verticalGuideOffset.dx, closeTo(25, 0.001));
    });

    testWidgets('snaps active left edge to other right edge and shows guide',
        (tester) async {
      final manager = _createManager();
      final anchor = _layer(10, 0);
      final active = _layer(32, 40);
      final layers = [anchor, active];
      final removeAreaKey = GlobalKey();
      final context = await _pumpHarness(
        tester: tester,
        layers: layers,
        removeAreaKey: removeAreaKey,
        layerSizes: {
          anchor.id: const Size(30, 30),
          active.id: const Size(20, 20),
        },
      );
      final helperLineCtrl = StreamController<void>.broadcast();
      addTearDown(helperLineCtrl.close);

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
      );

      expect(active.offset.dx, closeTo(35, 0.001));
      expect(manager.isVerticalGuideVisible, isTrue);
      expect(manager.verticalGuideOffsets, contains(closeTo(25, 0.001)));
    });

    testWidgets('shows center and edge guides together when both satisfy',
        (tester) async {
      final manager = _createManager(configs: _kCenterOffsetConfigs);
      final anchor = _widgetLayer(0, 0);
      final active = _widgetLayer(2, 40);
      final layers = [anchor, active];
      final removeAreaKey = GlobalKey();
      final context = await _pumpHarness(
        tester: tester,
        layers: layers,
        removeAreaKey: removeAreaKey,
        layerSizes: {
          anchor.id: const Size(20, 20),
          active.id: const Size(20, 20),
        },
      );
      final helperLineCtrl = StreamController<void>.broadcast();
      addTearDown(helperLineCtrl.close);

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
      );

      expect(active.offset.dx, closeTo(0, 0.001));
      expect(manager.isVerticalGuideVisible, isTrue);
      expect(manager.verticalGuideOffsets.length, greaterThanOrEqualTo(3));
      expect(manager.verticalGuideOffsets, contains(closeTo(0, 0.001)));
      expect(manager.verticalGuideOffsets, contains(closeTo(10, 0.001)));
      expect(manager.verticalGuideOffsets, contains(closeTo(20, 0.001)));
    });

    testWidgets('shows top and bottom guides together when both satisfy',
        (tester) async {
      final manager = _createManager(configs: _kCenterOffsetConfigs);
      final anchor = _widgetLayer(0, 0);
      final active = _widgetLayer(40, 2);
      final layers = [anchor, active];
      final removeAreaKey = GlobalKey();
      final context = await _pumpHarness(
        tester: tester,
        layers: layers,
        removeAreaKey: removeAreaKey,
        layerSizes: {
          anchor.id: const Size(20, 20),
          active.id: const Size(20, 20),
        },
      );
      final helperLineCtrl = StreamController<void>.broadcast();
      addTearDown(helperLineCtrl.close);

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
      );

      expect(active.offset.dy, closeTo(0, 0.001));
      expect(manager.isHorizontalGuideVisible, isTrue);
      expect(manager.horizontalGuideOffsets.length, greaterThanOrEqualTo(3));
      expect(manager.horizontalGuideOffsets, contains(closeTo(0, 0.001)));
      expect(manager.horizontalGuideOffsets, contains(closeTo(10, 0.001)));
      expect(manager.horizontalGuideOffsets, contains(closeTo(20, 0.001)));
    });

    testWidgets('releases guide when drag keeps moving away in small steps',
        (tester) async {
      final manager = _createManager();
      final anchor = _layer(0, 10);
      final active = _layer(50, 5);
      final layers = [anchor, active];
      final removeAreaKey = GlobalKey();
      final context = await _pumpHarness(
        tester: tester,
        layers: layers,
        removeAreaKey: removeAreaKey,
        layerSizes: {
          anchor.id: const Size(30, 30),
          active.id: const Size(20, 20),
        },
      );
      final helperLineCtrl = StreamController<void>.broadcast();
      addTearDown(helperLineCtrl.close);

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
        focalPoint: const Offset(0, 0),
        focalPointDelta: Offset.zero,
      );
      expect(manager.isHorizontalGuideVisible, isTrue);
      expect(active.offset.dy, closeTo(5, 0.001));

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
        focalPoint: const Offset(0, 2),
        focalPointDelta: const Offset(0, 2),
      );
      expect(manager.isHorizontalGuideVisible, isTrue);
      expect(active.offset.dy, closeTo(5, 0.001));

      _runMovement(
        manager: manager,
        context: context,
        activeLayer: active,
        layers: layers,
        removeAreaKey: removeAreaKey,
        helperLineCtrl: helperLineCtrl,
        focalPoint: const Offset(0, 4),
        focalPointDelta: const Offset(0, 2),
      );

      expect(manager.isHorizontalGuideVisible, isFalse);
      expect(active.offset.dy, closeTo(7, 0.001));
    });
  });
}
