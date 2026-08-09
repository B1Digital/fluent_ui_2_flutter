import 'package:fluent_2_web/src/charts/model/chart_annotation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the annotation enums', () {
    test('cover exactly the upstream literal unions', () {
      expect(
        FluentAnnotationYAxis.values.length,
        2,
        reason: "types/ChartAnnotation.ts:12 — 'primary' | 'secondary'.",
      );
      expect(
        FluentCoordinateSpace.values.length,
        3,
        reason: "types/ChartAnnotation.ts:33 — 'data' | 'relative' | 'pixel'.",
      );
      expect(
        FluentChartAnnotationAlign.values.length,
        3,
        reason: "types/ChartAnnotation.ts:41 — 'start' | 'center' | 'end'.",
      );
      expect(
        FluentChartAnnotationVerticalAlign.values.length,
        3,
        reason: "types/ChartAnnotation.ts:42 — 'top' | 'middle' | 'bottom'.",
      );
      expect(
        FluentChartAnnotationArrowHead.values.length,
        4,
        reason: "types/ChartAnnotation.ts:44 — 'none'|'start'|'end'|'both'.",
      );
      expect(
        FluentChartAnnotationBorderStyle.values.length,
        4,
        reason:
            'types/ChartAnnotation.ts:88 is the open CSS borderStyle type; the '
            'four values the annotation layer actually paints are solid, '
            'dashed, dotted and none.',
      );
    });
  });

  group('FluentChartAnnotationCoordinate', () {
    test('data carries a domain pair and a y-axis selector', () {
      final coordinate = FluentDataCoordinate(
        x: DateTime.utc(2024),
        y: 42,
        yAxis: FluentAnnotationYAxis.secondary,
      );
      expect(
        coordinate.x,
        DateTime.utc(2024),
        reason: 'types/ChartAnnotation.ts:8 `number | string | Date`.',
      );
      expect(coordinate.y, 42, reason: 'types/ChartAnnotation.ts:10.');
      expect(
        coordinate.yAxis,
        FluentAnnotationYAxis.secondary,
        reason: 'types/ChartAnnotation.ts:12.',
      );
    });

    test('data defaults its y-axis selector to primary', () {
      const coordinate = FluentDataCoordinate(x: 1, y: 2);
      expect(
        coordinate.yAxis,
        FluentAnnotationYAxis.primary,
        reason:
            'types/ChartAnnotation.ts:12 is optional; primary is the base '
            'scale.',
      );
    });

    test('relative and pixel take two doubles each', () {
      const relative = FluentRelativeCoordinate(x: 0.25, y: 0.75);
      const pixel = FluentPixelCoordinate(x: 120, y: 40);
      expect(relative.x, 0.25, reason: 'types/ChartAnnotation.ts:18 fraction.');
      expect(pixel.y, 40, reason: 'types/ChartAnnotation.ts:28 pixel offset.');
    });

    test('mixed names a space per axis', () {
      const mixed = FluentMixedCoordinate(
        xSpace: FluentCoordinateSpace.data,
        ySpace: FluentCoordinateSpace.relative,
        x: 'Jan',
        y: 0.5,
      );
      expect(
        mixed.xSpace,
        FluentCoordinateSpace.data,
        reason: 'types/ChartAnnotation.ts:33 xCoordinateType.',
      );
      expect(
        mixed.ySpace,
        FluentCoordinateSpace.relative,
        reason: 'types/ChartAnnotation.ts:34 yCoordinateType.',
      );
    });

    test('a switch over the sealed type is exhaustive', () {
      const coordinates = <FluentChartAnnotationCoordinate>[
        FluentDataCoordinate(x: 1, y: 2),
        FluentRelativeCoordinate(x: 0, y: 0),
        FluentPixelCoordinate(x: 0, y: 0),
        FluentMixedCoordinate(
          xSpace: FluentCoordinateSpace.pixel,
          ySpace: FluentCoordinateSpace.pixel,
          x: 0,
          y: 0,
        ),
      ];
      final names = coordinates
          .map(
            (c) => switch (c) {
              FluentDataCoordinate() => 'data',
              FluentRelativeCoordinate() => 'relative',
              FluentPixelCoordinate() => 'pixel',
              FluentMixedCoordinate() => 'mixed',
            },
          )
          .toList();
      expect(
        names,
        <String>['data', 'relative', 'pixel', 'mixed'],
        reason:
            'The four arms of types/ChartAnnotation.ts:3-39, and the compiler '
            'proves there is no fifth.',
      );
    });
  });

  group('FluentChartAnnotationConnector', () {
    test('carries the four resolved defaults from the styles file', () {
      const connector = FluentChartAnnotationConnector();
      expect(
        connector.startPadding,
        12,
        reason:
            'useChartAnnotationLayer.styles.ts:29 '
            'DEFAULT_CONNECTOR_START_PADDING.',
      );
      expect(
        connector.endPadding,
        0,
        reason:
            'useChartAnnotationLayer.styles.ts:30 DEFAULT_CONNECTOR_END_PADDING.',
      );
      expect(
        connector.strokeWidth,
        2,
        reason:
            'useChartAnnotationLayer.styles.ts:31 '
            'DEFAULT_CONNECTOR_STROKE_WIDTH.',
      );
      expect(
        connector.arrow,
        FluentChartAnnotationArrowHead.end,
        reason: 'useChartAnnotationLayer.styles.ts:32 DEFAULT_CONNECTOR_ARROW.',
      );
      expect(
        connector.strokeColor,
        isNull,
        reason:
            'getDefaultConnectorStrokeColor is theme-resolved, so the model '
            'carries no colour.',
      );
    });
  });

  group('FluentChartAnnotationLayout', () {
    test('defaults align, verticalAlign and both offsets', () {
      const layout = FluentChartAnnotationLayout();
      expect(
        layout.align,
        FluentChartAnnotationAlign.center,
        reason: 'ChartAnnotationLayer.tsx:26 DEFAULT_HORIZONTAL_ALIGN.',
      );
      expect(
        layout.verticalAlign,
        FluentChartAnnotationVerticalAlign.middle,
        reason: 'ChartAnnotationLayer.tsx:27 DEFAULT_VERTICAL_ALIGN.',
      );
      expect(
        layout.offsetX,
        0,
        reason: 'types/ChartAnnotation.ts:67 optional.',
      );
      expect(
        layout.offsetY,
        0,
        reason: 'types/ChartAnnotation.ts:69 optional.',
      );
    });

    test('clipToBounds is tri-state and defaults to null', () {
      const unset = FluentChartAnnotationLayout();
      const off = FluentChartAnnotationLayout(clipToBounds: false);
      const on = FluentChartAnnotationLayout(clipToBounds: true);
      expect(
        unset.clipToBounds,
        isNull,
        reason:
            'ChartAnnotationLayer.tsx:385 clamps the anchor only when truthy, '
            'while :544 selects the clamping viewport with `!= false`, so null '
            'behaves like neither true nor false.',
      );
      expect(unset.clampsAnchor, isFalse, reason: 'null is not truthy (:385).');
      expect(
        unset.clampsViewport,
        isTrue,
        reason: 'null `!= false` is true (:544).',
      );
      expect(off.clampsAnchor, isFalse, reason: 'false is not truthy (:385).');
      expect(off.clampsViewport, isFalse, reason: 'false == false (:544).');
      expect(on.clampsAnchor, isTrue, reason: 'true is truthy (:385).');
      expect(on.clampsViewport, isTrue, reason: 'true `!= false` (:544).');
    });
  });

  group('FluentChartAnnotationStyle', () {
    test('defaults opacity to the styles-file constant', () {
      const style = FluentChartAnnotationStyle();
      expect(
        style.opacity,
        0.8,
        reason:
            'useChartAnnotationLayer.styles.ts:27 '
            'DEFAULT_ANNOTATION_BACKGROUND_OPACITY.',
      );
    });
    test('takes Flutter-native padding, weight and shadow types', () {
      const style = FluentChartAnnotationStyle(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        fontWeight: FontWeight.w600,
        boxShadow: <BoxShadow>[BoxShadow(blurRadius: 2)],
      );
      expect(
        style.padding,
        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        reason:
            'useChartAnnotationLayer.styles.ts:28 DEFAULT_ANNOTATION_PADDING '
            "is '4px 8px'.",
      );
      expect(
        style.fontWeight,
        FontWeight.w600,
        reason: 'types/ChartAnnotation.ts:96.',
      );
      expect(
        style.boxShadow!.length,
        1,
        reason: 'types/ChartAnnotation.ts:92.',
      );
    });
  });

  group('FluentChartAnnotationSemantics', () {
    test("defaults the role to 'note'", () {
      const semantics = FluentChartAnnotationSemantics();
      expect(
        semantics.role,
        'note',
        reason: 'types/ChartAnnotation.ts:113 role, defaulted by the layer.',
      );
    });
  });

  group('FluentChartAnnotation', () {
    test('requires only text and coordinates', () {
      const annotation = FluentChartAnnotation(
        text: 'Launch',
        coordinates: FluentPixelCoordinate(x: 10, y: 20),
      );
      expect(
        annotation.text,
        'Launch',
        reason: 'types/ChartAnnotation.ts:120.',
      );
      expect(
        annotation.id,
        isNull,
        reason: 'types/ChartAnnotation.ts:118 optional.',
      );
      expect(
        annotation.layout,
        isNull,
        reason: 'types/ChartAnnotation.ts:124 optional.',
      );
    });
  });

  group('the foreign-object constants', () {
    test('match the layer defaults', () {
      expect(
        kDefaultForeignObjectWidth,
        180,
        reason: 'ChartAnnotationLayer.tsx:28.',
      );
      expect(
        kDefaultForeignObjectHeight,
        60,
        reason: 'ChartAnnotationLayer.tsx:29.',
      );
    });
  });

  group('FluentEventAnnotation', () {
    test('pairs a date with an event label', () {
      final annotation = FluentEventAnnotation(
        date: DateTime.utc(2024, 6, 1),
        event: 'GA',
      );
      expect(
        annotation.date,
        DateTime.utc(2024, 6, 1),
        reason: 'types/EventAnnotation.ts:4.',
      );
      expect(annotation.event, 'GA', reason: 'types/EventAnnotation.ts:5.');
      expect(
        annotation.cardBuilder,
        isNull,
        reason: 'types/EventAnnotation.ts:6 onRenderCard is optional.',
      );
    });
  });
}
