import 'package:fluent_2_web/src/charts/model/chart_annotation.dart';
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
}
