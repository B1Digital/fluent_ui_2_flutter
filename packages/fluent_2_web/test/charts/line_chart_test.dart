import 'dart:ui';

// The barrel is owned by the integration task, so this file is imported
// directly until `line_chart.dart` is exported from it.
import 'package:fluent_2_web/src/charts/line_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// Tolerance for a coordinate read back out of [Path.getBounds].
///
/// `Path` stores its points as 32-bit floats, so `0.2886 * 10` comes back as
/// 2.885999917984009 — an absolute error of 8.2e-8 at this magnitude, and
/// 6.1e-7 at the octagon's 24.14. The plan's 1e-9 is below the storage
/// precision and is unachievable by any implementation.
const double _kPathBoundsTolerance = 1e-5;

void main() {
  group('FluentLineMarkerPainter.pathFor', () {
    test('a square is exactly w by w about the centre', () {
      final b = FluentLineMarkerPainter.pathFor(
        1,
        const Offset(50, 50),
        10,
      ).getBounds();
      expect(
        b,
        const Rect.fromLTWH(45, 45, 10, 10),
        reason: 'LineChart.tsx:89-93 places corners at x±w/2, y±w/2',
      );
    });

    test('a triangle spans 0.2886w above and 0.5774w below', () {
      final b = FluentLineMarkerPainter.pathFor(
        2,
        const Offset(0, 0),
        10,
      ).getBounds();
      expect(
        b.top,
        closeTo(-2.886, _kPathBoundsTolerance),
        reason: 'LineChart.tsx:95 uses y - 0.2886 * w',
      );
      expect(
        b.bottom,
        closeTo(5.774, _kPathBoundsTolerance),
        reason: 'LineChart.tsx:97 uses y + 0.5774 * w',
      );
    });

    test('a hexagon is 2w wide before the widthRatio division', () {
      final b = FluentLineMarkerPainter.pathFor(
        5,
        const Offset(0, 0),
        10,
      ).getBounds();
      expect(
        b.width,
        closeTo(20, _kPathBoundsTolerance),
        reason: 'LineChart.tsx:110-116 reaches x ± w, hence widthRatio 2',
      );
    });

    test('a pentagon spans 0.851w up and 0.6884w down', () {
      final b = FluentLineMarkerPainter.pathFor(
        6,
        const Offset(0, 0),
        10,
      ).getBounds();
      expect(
        b.top,
        closeTo(-8.51, _kPathBoundsTolerance),
        reason: 'LineChart.tsx:119',
      );
      expect(
        b.bottom,
        closeTo(6.884, _kPathBoundsTolerance),
        reason: 'LineChart.tsx:121-122',
      );
    });

    test('an octagon spans 1.207w in both axes', () {
      final b = FluentLineMarkerPainter.pathFor(
        7,
        const Offset(0, 0),
        10,
      ).getBounds();
      expect(
        b.width,
        closeTo(24.14, _kPathBoundsTolerance),
        reason: 'LineChart.tsx:126-133',
      );
      expect(
        b.height,
        closeTo(24.14, _kPathBoundsTolerance),
        reason: 'LineChart.tsx:126-133',
      );
    });

    test('the width ratios normalise the wide shapes back to w', () {
      const ratios = <int, double>{5: 2, 6: 1.168, 7: 2.414};
      for (final e in ratios.entries) {
        final w = 10 / e.value;
        expect(
          FluentLineMarkerPainter.pathFor(
            e.key,
            Offset.zero,
            w,
          ).getBounds().width,
          // The hexagon and the octagon come back to exactly 10; the pentagon
          // does not, because its 1.168 is the ratio of its *height* to its
          // width (0.851 + 0.6884 == 1.5394, and 1.5394 / 1.3768 == 1.1181 —
          // near enough that upstream reuses one number for both). Its width
          // therefore lands at 2 * 0.6884 * 10 / 1.168 == 11.789.
          closeTo(e.key == 6 ? 11.789 : 10, 0.05),
          reason:
              'utilities.ts:1747-1771 divides w by widthRatio at '
              'LineChart.tsx:494',
        );
      }
    });

    test('shapeIndex outside 0..7 is rejected rather than clamped', () {
      expect(
        () => FluentLineMarkerPainter.pathFor(8, Offset.zero, 10),
        throwsArgumentError,
        reason:
            'LineChart.tsx:136 indexes an eight-element literal array, so '
            'anything else is a caller bug, not a shape',
      );
    });
  });

  group('FluentLineMarkerPainter against Oracle B', () {
    // Every LineChart story in the corpus renders its points as this
    // two-semicircle path. None of the thirteen sets
    // allowMultipleShapesForPoints, so every captured marker is shape 0 at the
    // invisible size — which is exactly what the corpus can prove.
    const stories = <String>[
      'charts-linechart--line-chart-basic',
      'charts-linechart--line-chart-gaps',
      'charts-linechart--line-chart-multiple',
    ];

    for (final id in stories) {
      test('$id draws every marker as shape 0 at the invisible size', () {
        final story = loadOracleStory(id);
        // 18 numbers: M x1 y, A r r 0 1 0 x2 y, M x1 y, A r r 0 1 1 x2 y.
        final markers = story
            .byTag('path')
            .map((e) => e.d)
            .whereType<String>()
            .map(svgPathNumbers)
            .where((n) => n.length == 18)
            .toList();
        expect(
          markers.length,
          greaterThanOrEqualTo(3),
          reason:
              '$id must contribute markers, or the loop below asserts '
              'nothing',
        );

        for (final n in markers) {
          final x1 = n[0];
          final x2 = n[7];
          final y = n[1];
          final w = x2 - x1;
          expect(
            w,
            closeTo(
              FluentLineMarkerPainter.boxWidthFor(
                allowMultipleShapes: false,
                isActive: false,
                isFirstOrLast: true,
                strokeWidth: FluentLineMarkerPainter.kDefaultLineStrokeSize,
              ),
              kOracleGeometryTolerance,
            ),
            reason:
                'the captured chord is the box width _getBoxWidthOfShape '
                'returned (LineChart.tsx:474-478)',
          );
          expect(
            n[2],
            closeTo(w / 2, kOracleGeometryTolerance),
            reason: 'the arc radius is w/2 (LineChart.tsx:86)',
          );
          // The ported circle covers the same box the browser drew.
          expectOracleRect(
            '$id marker at $x1',
            Rect.fromLTRB(x1, y - w / 2, x2, y + w / 2),
            FluentLineMarkerPainter.pathFor(
              0,
              Offset((x1 + x2) / 2, y),
              w,
            ).getBounds(),
          );
        }
      });
    }
  });

  group('FluentLineMarkerPainter.boxWidthFor', () {
    test('an active point is always the hover size', () {
      expect(
        FluentLineMarkerPainter.boxWidthFor(
          allowMultipleShapes: false,
          isActive: true,
          isFirstOrLast: false,
          strokeWidth: 4,
        ),
        11,
        reason: 'PointSize.hoverSize == 11, LineChart.tsx:64',
      );
    });

    test('without multiple shapes an inactive point is invisible', () {
      expect(
        FluentLineMarkerPainter.boxWidthFor(
          allowMultipleShapes: false,
          isActive: false,
          isFirstOrLast: true,
          strokeWidth: 4,
        ),
        1,
        reason:
            'PointSize.invisibleSize == 1, LineChart.tsx:65; the '
            'first/last exemption only applies when allowMultipleShapes is set',
      );
    });

    test('with multiple shapes the first and last points stay visible', () {
      expect(
        FluentLineMarkerPainter.boxWidthFor(
          allowMultipleShapes: true,
          isActive: false,
          isFirstOrLast: true,
          strokeWidth: 4,
        ),
        10,
        reason: '4 * PATH_MULTIPLY_SIZE 2.5 == 10, LineChart.tsx:468',
      );
    });
  });
}
