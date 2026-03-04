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
    showLayerAlignLine: false,
    showLayerSpacingLine: true,
    layerSpacingSnapThreshold: 6,
  ),
);

LayerInteractionManager _createManager() {
  return LayerInteractionManager(
    helperLinesCallbacks: null,
    configs: _kTestConfigs,
    onSelectedLayerChanged: null,
    onSelectedLayersChanged: (_) {},
  );
}

Layer _layer(double x, double y) => Layer(offset: Offset(x, y));

Future<BuildContext> _pumpHarness({
  required WidgetTester tester,
  required List<Layer> layers,
  required GlobalKey removeAreaKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          key: const ValueKey('layer-spacing-test-stack'),
          children: [
            for (final layer in layers)
              SizedBox(
                key: layer.keyInternalSize,
                width: 20,
                height: 20,
              ),
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
  return tester.element(find.byKey(const ValueKey('layer-spacing-test-stack')));
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
  group('Layer spacing highlight', () {
    testWidgets(
      'Case 1: snaps gap to equal anchor margin and highlights both blocks',
      (tester) async {
        final manager = _createManager();
        final anchor = _layer(-60, 0);
        final active = _layer(-8, 0);
        final layers = [anchor, active];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
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

        expect(active.offset.dx, closeTo(-10, 0.001));
        expect(
            manager.layerSpacingHighlightRects.length, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      'Regression: dragging left layer also highlights edge+gap symmetry',
      (tester) async {
        final manager = _createManager();
        final active = _layer(-58, 0);
        final anchor = _layer(-10, 0);
        final layers = [active, anchor];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
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

        expect(active.offset.dx, closeTo(-60, 0.001));
        expect(
            manager.layerSpacingHighlightRects.length, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      'Case 2: no highlight when Y projection does not overlap',
      (tester) async {
        final manager = _createManager();
        final anchor = _layer(-60, -40);
        final active = _layer(-8, 40);
        final layers = [anchor, active];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
        );
        final helperLineCtrl = StreamController<void>.broadcast();
        addTearDown(helperLineCtrl.close);

        final beforeOffset = active.offset;

        _runMovement(
          manager: manager,
          context: context,
          activeLayer: active,
          layers: layers,
          removeAreaKey: removeAreaKey,
          helperLineCtrl: helperLineCtrl,
        );

        expect(active.offset, beforeOffset);
        expect(manager.layerSpacingHighlightRects, isEmpty);
      },
    );

    testWidgets(
      'Case 3: highlights cascaded sequence when continuing equal spacing',
      (tester) async {
        final manager = _createManager();
        final a = _layer(-60, 0);
        final b = _layer(-10, 0);
        final c = _layer(42, 0);
        final layers = [a, b, c];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
        );
        final helperLineCtrl = StreamController<void>.broadcast();
        addTearDown(helperLineCtrl.close);

        _runMovement(
          manager: manager,
          context: context,
          activeLayer: c,
          layers: layers,
          removeAreaKey: removeAreaKey,
          helperLineCtrl: helperLineCtrl,
        );

        expect(c.offset.dx, closeTo(40, 0.001));
        expect(
            manager.layerSpacingHighlightRects.length, greaterThanOrEqualTo(3));
      },
    );

    testWidgets(
      'Case 4: snaps active layer to midpoint between two fixed layers',
      (tester) async {
        final manager = _createManager();
        final left = _layer(-60, 0);
        final active = _layer(-18, 0);
        final right = _layer(20, 0);
        final layers = [left, active, right];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
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

        expect(active.offset.dx, closeTo(-20, 0.001));
        expect(
            manager.layerSpacingHighlightRects.length, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      'Case 5: disables spacing highlight when layers physically overlap',
      (tester) async {
        final manager = _createManager();
        final anchor = _layer(-10, 0);
        final active = _layer(0, 0);
        final layers = [anchor, active];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
        );
        final helperLineCtrl = StreamController<void>.broadcast();
        addTearDown(helperLineCtrl.close);

        final beforeOffset = active.offset;

        _runMovement(
          manager: manager,
          context: context,
          activeLayer: active,
          layers: layers,
          removeAreaKey: removeAreaKey,
          helperLineCtrl: helperLineCtrl,
        );

        expect(active.offset, beforeOffset);
        expect(manager.layerSpacingHighlightRects, isEmpty);
      },
    );

    testWidgets(
      'Vertical symmetry: snaps and highlights for top edge + gap relation',
      (tester) async {
        final manager = _createManager();
        final active = _layer(0, -23);
        final anchor = _layer(0, 10);
        final layers = [active, anchor];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
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

        expect(active.offset.dy, closeTo(-25, 0.001));
        expect(
            manager.layerSpacingHighlightRects.length, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      'Vertical regression: keeps highlights on equal m-gaps only when edge n is merely near threshold',
      (tester) async {
        final manager = _createManager();
        // Canvas top/bottom are -50/50; this layout creates:
        // top edge -> A = 8 (n), A->B = 12 (m), B->C = 12 (m), C->bottom = 8 (n).
        // With snap threshold 6, n is close to m but should not be highlighted.
        final active = _layer(0, -33.11); // Slightly above the m target.
        final b = _layer(0, 0);
        final c = _layer(0, 32);
        final layers = [active, b, c];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
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

        // Snap to keep A-B and B-C equal (m = 12), but do not cascade to edge n.
        expect(active.offset.dy, closeTo(-32, 0.001));
        expect(manager.layerSpacingHighlightRects.length, 2);
      },
    );

    testWidgets(
      'Regression: outside-canvas anchor should not produce spacing highlights',
      (tester) async {
        final manager = _createManager();
        // Canvas X bounds are [-100, 100].
        // Active layer A is fully outside on the left and would previously
        // trigger a margin-gap snap against inside B (false positive).
        final activeAOutside = _layer(-110, 0);
        final insideB = _layer(-70, 0);
        final layers = [activeAOutside, insideB];
        final removeAreaKey = GlobalKey();
        final context = await _pumpHarness(
          tester: tester,
          layers: layers,
          removeAreaKey: removeAreaKey,
        );
        final helperLineCtrl = StreamController<void>.broadcast();
        addTearDown(helperLineCtrl.close);

        _runMovement(
          manager: manager,
          context: context,
          activeLayer: activeAOutside,
          layers: layers,
          removeAreaKey: removeAreaKey,
          helperLineCtrl: helperLineCtrl,
        );

        expect(manager.layerSpacingHighlightRects, isEmpty);
      },
    );
  });
}
