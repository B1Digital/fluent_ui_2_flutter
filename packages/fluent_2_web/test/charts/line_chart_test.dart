import 'dart:math';
import 'dart:ui' as ui;

import 'package:fluent_2_core/fluent_2_core.dart';
// The barrel is owned by the integration task, so these files are imported
// directly until `line_chart.dart` is exported from it.
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2_web/src/charts/chrome/event_annotation.dart';
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/internal/marker_geometry.dart';
import 'package:fluent_2_web/src/charts/line_chart.dart';
import 'package:fluent_2_web/src/charts/line_chart_style.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/chart_annotation.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
import 'package:flutter/widgets.dart';
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

  group('LineChart engine A', () {
    test(
      'engine A is chosen when there is no curve and no large-data flag',
      () {
        expect(
          _lineDelegate().usesSinglePathEngine,
          isFalse,
          reason:
              'LineChart.tsx:671 switches only on optimizeLargeData || curve',
        );
        expect(
          _lineDelegate(curve: FluentLineCurve.natural).usesSinglePathEngine,
          isTrue,
          reason: 'a set curve forces the single-path engine',
        );
      },
    );

    test('n points yield n-1 segments', () {
      expect(
        _lineDelegate(
          ys: const <double>[1, 2, 3, 4],
        ).segmentsFor(_ctx()).length,
        3,
        reason: 'LineChart.tsx:836 iterates j from 1 to n-1',
      );
    });

    test('a gap removes exactly the segments inside it', () {
      final d = _lineDelegate(
        ys: const <double>[1, 2, 3, 4, 5],
        gaps: const <FluentLineChartGap>[
          FluentLineChartGap(startIndex: 1, endIndex: 3),
        ],
      );
      expect(
        d.segmentsFor(_ctx()).map((segment) => segment.pointIndex).toList(),
        <int>[1, 4],
        reason:
            'a point is in a gap when index > startIndex && index <= '
            'endIndex, LineChart.tsx:1432-1444',
      );
    });

    test('gaps are honoured whatever order they arrive in', () {
      final d = _lineDelegate(
        ys: const <double>[1, 2, 3, 4, 5],
        gaps: const <FluentLineChartGap>[
          FluentLineChartGap(startIndex: 3, endIndex: 4),
          FluentLineChartGap(startIndex: 0, endIndex: 1),
        ],
      );
      expect(
        d.isInGap(0, 1),
        isTrue,
        reason:
            'LineChart.tsx:667 sorts gaps ascending by startIndex before '
            '_checkInGap walks them with a monotonic cursor',
      );
      expect(
        d.isInGap(0, 4),
        isTrue,
        reason:
            'the second gap must be found too: the port scans the whole '
            'sorted list, so no cursor can run past it',
      );
    });

    test('a non-plottable endpoint drops the whole segment', () {
      expect(
        _lineDelegate(
          ys: const <double>[1, double.nan, 3],
        ).segmentsFor(_ctx()).length,
        0,
        reason: 'both endpoints must be plottable, LineChart.tsx:1210-1214',
      );
    });

    test('a dimmed segment carries opacity 0.1 and a dimmed marker 0.01', () {
      final d = _lineDelegate(
        legends: const <String>['a', 'b'],
        selectedLegend: 'a',
      );
      expect(
        d.segmentsFor(_ctx()).first.opacity,
        0.1,
        reason:
            'LineChart.tsx:1293-1307 dims a non-selected line to 0.1. The '
            'FIRST segment belongs to the LAST series, because :535 walks the '
            'series backwards so series 0 paints on top',
      );
      expect(
        d.segmentsFor(_ctx()).last.opacity,
        1,
        reason: 'the selected legend keeps opacity 1, LineChart.tsx:1293',
      );
      expect(
        d.markerOpacityFor('b'),
        0.01,
        reason: 'parity: LineChart.tsx:915 dims a marker to 0.01, not 0.1',
      );
    });

    test('mode "markers" suppresses the segments but keeps the markers', () {
      final d = _lineDelegate(
        mode: const FluentLineMode(lines: false, markers: true),
      );
      expect(
        d.segmentsFor(_ctx()),
        isEmpty,
        reason:
            'LineChart.tsx:1213 requires mode.includes("lines") once any '
            'series is in markers mode',
      );
      expect(
        d.markerOpacityFor('a'),
        1,
        reason: 'nothing is highlighted, so the marker stays fully opaque',
      );
    });

    test('a series with a line border widens the stroke by the border', () {
      final d = _lineDelegate(lineBorderWidth: 2);
      final s = d.segmentsFor(_ctx()).first;
      expect(
        s.borderWidth,
        s.strokeWidth + 2,
        reason: 'LineChart.tsx:1224 sets strokeWidth + lineBorderWidth',
      );
      expect(
        _lineDelegate().segmentsFor(_ctx()).first.borderWidth,
        isNull,
        reason: 'LineChart.tsx:1222 draws no border at all when it is zero',
      );
    });

    test('a one-number strokeDasharray means on and off by that number', () {
      expect(
        _lineDelegate(
          strokeDasharray: '2',
        ).segmentsFor(_ctx()).first.dashPattern,
        <double>[2, 2],
        reason:
            'SVG treats an odd dash list as repeated, which Flutter must '
            'spell out; the gaps story carries strokeDasharray="2"',
      );
      expect(
        _lineDelegate(
          strokeDasharray: '5, 5',
        ).segmentsFor(_ctx()).first.dashPattern,
        <double>[5, 5],
        reason: 'comma and whitespace are both SVG separators',
      );
    });

    test('high contrast flattens the fill and the border differently', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final colours = FluentChartColors.of(theme);
      final s = _lineDelegate(
        lineBorderWidth: 2,
        withTheme: theme,
      ).segmentsFor(_ctx()).first;
      expect(
        s.colour,
        colours.flattenMark(FluentDataVizPalette.next(0)),
        reason: 'spec §5.3: a series mark flattens to the system colour',
      );
      expect(
        s.borderColour,
        colours.flattenMarkStroke(theme.colors.neutralBackground1),
        reason:
            'the halo stroked behind the line flattens to the CANVAS colour, '
            'not to CanvasText, or the line and its halo merge',
      );
      expect(
        s.colour,
        isNot(s.borderColour),
        reason: 'flattening both the same way would erase the halo',
      );
    });

    test('paintSeries strokes every border before any line', () {
      final recorder = _LineRecorder();
      _lineDelegate(lineBorderWidth: 4).paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      expect(
        recorder.strokeWidths,
        <double>[8, 8, 4, 4],
        reason:
            'LineChart.tsx:1363-1364 renders bordersForLine before '
            'linesForLine, so the halo never covers a neighbouring segment',
      );
    });

    test('paintSeries walks a dashed line by hand', () {
      final recorder = _LineRecorder();
      _lineDelegate(strokeDasharray: '2').paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      expect(
        recorder.drawn.length,
        greaterThan(2),
        reason:
            'Canvas has no stroke-dasharray, so the two segments must be cut '
            'into more than one draw each',
      );
      expect(
        (recorder.drawn.first.$2 - recorder.drawn.first.$1).distance,
        closeTo(2, 1e-9),
        reason: 'the first dash is as long as the pattern says',
      );
    });

    test('paintSeries paints a marker at every data point', () {
      final recorder = _LineRecorder();
      _lineDelegate(ys: const <double>[1, 2, 3]).paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      expect(
        recorder.paths.map((entry) => entry.$2).toList(),
        const <PaintingStyle>[
          PaintingStyle.fill,
          PaintingStyle.stroke,
          PaintingStyle.fill,
          PaintingStyle.stroke,
          PaintingStyle.fill,
          PaintingStyle.stroke,
        ],
        reason:
            'LineChart.tsx:936 pushes one <path> marker per point carrying '
            'both a fill and a stroke, so three points is three filled and '
            'three stroked paths',
      );
    });
  });

  group('LineChart engine A against Oracle B', () {
    test('line-chart-basic reproduces every captured segment chain', () {
      final story = loadOracleStory('charts-linechart--line-chart-basic');
      final groups = _plotLineGroups(story);
      expect(
        groups.length,
        greaterThanOrEqualTo(2),
        reason:
            'the basic story draws two lines; with no group the loop below '
            'asserts nothing',
      );
      for (final group in groups) {
        final d = _delegateFromCapturedChain(group);
        final segments = d.segmentsFor(_identityCtx());
        expect(
          segments.length,
          group.lines.length,
          reason:
              'engine A emits one <line> per adjacent pair, and the capture '
              'holds ${group.lines.length} of them',
        );
        for (var i = 0; i < group.lines.length; i++) {
          final line = group.lines[i];
          expectOracleOffset(
            'basic segment $i start',
            Offset(line.x1!, line.y1!),
            segments[i].start,
          );
          expectOracleOffset(
            'basic segment $i end',
            Offset(line.x2!, line.y2!),
            segments[i].end,
          );
          expectOracleNumber(
            'basic segment $i stroke width',
            line.strokeWidth,
            segments[i].strokeWidth,
          );
          expectOracleNumber(
            'basic segment $i border width',
            group.borders[i].strokeWidth,
            segments[i].borderWidth!,
          );
          expectOracleColour(
            'basic segment $i border colour',
            group.borders[i].stroke,
            segments[i].borderColour,
          );
        }
      }
    });

    test('line-chart-gaps drops exactly the segments the browser dropped', () {
      final story = loadOracleStory('charts-linechart--line-chart-gaps');
      final groups = _plotLineGroups(story);
      // The story draws the gapped series and a second, dashed series that
      // fills the gaps, so the union of the two tiles the x range. The pair is
      // found by that property — a dashed group whose first segment starts
      // exactly where one other group's segment ends — because the story also
      // carries an unrelated dashed reference line.
      _CapturedSeries? filler;
      _CapturedSeries? gapped;
      for (final candidate in groups) {
        if (candidate.lines.first.strokeDasharray == 'none') {
          continue;
        }
        final start = Offset(
          candidate.lines.first.x1!,
          candidate.lines.first.y1!,
        );
        final partners = groups
            .where(
              (group) =>
                  group != candidate &&
                  group.lines.any(
                    (line) =>
                        (Offset(line.x2!, line.y2!) - start).distance <
                        kOracleGeometryTolerance,
                  ),
            )
            .toList();
        if (partners.length == 1) {
          filler = candidate;
          gapped = partners.single;
          break;
        }
      }
      expect(
        filler,
        isNotNull,
        reason:
            'the gaps story must contain a dashed gap-filler abutting one '
            'other series, or there is no gap to assert against',
      );
      final fillerLines = filler!.lines;
      final gappedLines = gapped!.lines;
      final union = <OracleElement>[...gappedLines, ...fillerLines]
        ..sort((a, b) => a.x1!.compareTo(b.x1!));
      expect(
        union.length,
        gappedLines.length + fillerLines.length,
        reason: 'the union must keep every captured segment',
      );
      expect(
        fillerLines.length,
        greaterThanOrEqualTo(1),
        reason: 'without a filler segment the gap assertion is vacuous',
      );

      final points = <Offset>[
        Offset(union.first.x1!, union.first.y1!),
        for (final line in union) Offset(line.x2!, line.y2!),
      ];
      final gaps = <FluentLineChartGap>[
        for (var j = 1; j <= union.length; j++)
          if (fillerLines.contains(union[j - 1]))
            FluentLineChartGap(startIndex: j - 1, endIndex: j),
      ];
      final segments = _delegateFromPoints(
        points,
        gaps: gaps,
      ).segmentsFor(_identityCtx());
      expect(
        segments.length,
        gappedLines.length,
        reason:
            'LineChart.tsx:1432-1444 must drop the ${gaps.length} gap '
            'segments and keep the rest',
      );
      for (var i = 0; i < gappedLines.length; i++) {
        final line = gappedLines[i];
        expectOracleOffset(
          'gapped segment $i start',
          Offset(line.x1!, line.y1!),
          segments[i].start,
        );
        expectOracleOffset(
          'gapped segment $i end',
          Offset(line.x2!, line.y2!),
          segments[i].end,
        );
      }
    });
  });

  group('LineChart markers', () {
    test('every plottable point gets a marker, gap or no gap', () {
      final marks = _lineDelegate(
        ys: const <double>[1, 2, 3, 4],
        gaps: const <FluentLineChartGap>[
          FluentLineChartGap(startIndex: 1, endIndex: 2),
        ],
      ).markersFor(_ctx());
      expect(
        marks.map((mark) => mark.pointIndex),
        <int>[0, 1, 2, 3],
        reason:
            '_checkInGap is read at LineChart.tsx:1215 for the line only; '
            'the marker pushes at :846 and :1010 never consult it',
      );
    });

    test('a non-plottable point is skipped rather than drawn at NaN', () {
      expect(
        _lineDelegate(
          ys: const <double>[1, double.nan, 3],
        ).markersFor(_ctx()).map((mark) => mark.pointIndex),
        <int>[0, 2],
        reason: 'LineChart.tsx:845 gates the whole push on isPlottable',
      );
    });

    test('without allowMultipleShapesForPoints every marker is shape 0', () {
      final marks = _lineDelegate(
        legends: const <String>['a', 'b', 'c'],
      ).markersFor(_ctx());
      expect(
        marks.map((mark) => mark.shapeIndex).toSet(),
        <int>{0},
        reason:
            'LineChart.tsx:492 short-circuits the cycle to 0 when the flag is '
            'off, whatever the series index is',
      );
      expect(
        marks.map((mark) => mark.size).toSet(),
        <double>{FluentLineMarkerPainter.kInvisibleSize},
        reason:
            'and :474-478 gives every point the invisible size, because the '
            'first/last exemption lives inside the flag',
      );
    });

    test('allowMultipleShapesForPoints cycles the shape over the series', () {
      final marks = _lineDelegate(
        legends: <String>[for (var i = 0; i < 9; i++) 's$i'],
        allowMultipleShapesForPoints: true,
      ).markersFor(_ctx());
      expect(
        <int>{for (final mark in marks) mark.seriesIndex},
        <int>{for (var i = 0; i < 9; i++) i},
        reason: 'all nine series must contribute, or the cycle is untested',
      );
      for (final mark in marks) {
        expect(
          mark.shapeIndex,
          mark.seriesIndex % 8,
          reason:
              'LineChart.tsx:492 indexes by the SERIES index — `_points[i]'
              '.index`, injected at :283 — so series 8 is a circle again',
        );
      }
    });

    test(
      'a wide shape is narrowed by its width ratio, a narrow one is not',
      () {
        // The eighth series is the octagon, whose 2.414 ratio is the largest.
        final marks = _lineDelegate(
          legends: <String>[for (var i = 0; i < 8; i++) 's$i'],
          allowMultipleShapesForPoints: true,
        ).markersFor(_ctx());
        final first = <int, FluentLineMark>{
          for (final mark in marks)
            if (mark.pointIndex == 0) mark.seriesIndex: mark,
        };
        expect(
          first.length,
          8,
          reason: 'one first point per shape, or the table below is unindexed',
        );
        // The first point of a series is exempt, so its box is the full
        // strokeWidth * PATH_MULTIPLY_SIZE (LineChart.tsx:468).
        const box = 4 * FluentLineMarkerPainter.kPathMultiplySize;
        for (var i = 0; i < 8; i++) {
          final ratio = FluentLineMarkerPainter.kWidthRatios[i];
          expect(
            first[i]!.size,
            ratio > 1 ? box / ratio : box,
            reason:
                'LineChart.tsx:494 divides only when widthRatio > 1, and shape '
                '$i has ratio $ratio (utilities.ts:1747-1771)',
          );
        }
      },
    );

    test('markers mode swaps the shape for a sized circle', () {
      final marks = _lineDelegate(
        mode: const FluentLineMode(markers: true, lines: false),
      ).markersFor(_ctx());
      expect(
        marks.map((mark) => mark.shapeIndex).toSet(),
        <int?>{null},
        reason: 'LineChart.tsx:850 renders a <circle>, not _getPointPath',
      );
      expect(
        marks.map((mark) => mark.size).toSet(),
        <double>{3.5},
        reason:
            'and sizes it with calculateMarkerRadius, whose falsy-markerSize '
            'branch is the 3.5 default (utilities.ts:2324)',
      );
    });

    test('text mode alone also swaps the shape for a circle', () {
      expect(
        _lineDelegate(
          mode: const FluentLineMode(text: true, lines: false),
        ).markersFor(_ctx()).map((mark) => mark.shapeIndex).toSet(),
        <int?>{null},
        reason:
            'LineChart.tsx:850 is `mode.includes(markers) || supportsTextMode`',
      );
    });

    test('a markers-only series still draws markers while drawing no line', () {
      final d = _lineDelegate(
        mode: const FluentLineMode(markers: true, lines: false),
      );
      expect(
        d.segmentsFor(_ctx()),
        isEmpty,
        reason: 'LineChart.tsx:1213 suppresses the line outside lines mode',
      );
      expect(
        d.markersFor(_ctx()),
        hasLength(3),
        reason:
            'but markers and lines are independently switchable: :846 pushes '
            'a marker whatever the mode says',
      );
    });

    test('a one-point series is a bare circle at 0.1, not engine A 0.01', () {
      final marks = _lineDelegate(
        ys: const <double>[5],
        legends: const <String>['a', 'b'],
        selectedLegend: 'b',
      ).markersFor(_ctx());
      final lone = marks.firstWhere((mark) => mark.seriesIndex == 0);
      expect(
        lone.shapeIndex,
        isNull,
        reason: 'LineChart.tsx:577 draws a <circle> before either engine runs',
      );
      expect(
        lone.strokeWidth,
        0,
        reason: 'LineChart.tsx:623 strokes it only while active',
      );
      expect(
        lone.opacity,
        0.1,
        reason:
            'LineChart.tsx:591 dims it to 0.1, unlike the 0.01 of the engine '
            'A markers at :909',
      );
    });

    test('engine B draws markers only in markers mode', () {
      expect(
        _lineDelegate(curve: FluentLineCurve.linear).markersFor(_ctx()),
        isEmpty,
        reason:
            'LineChart.tsx:773 gates the engine B marker loop on '
            'mode.includes(markers); a curved line with no mode draws none',
      );
      final marks = _lineDelegate(
        curve: FluentLineCurve.linear,
        mode: const FluentLineMode(markers: true),
      ).markersFor(_ctx());
      expect(
        marks,
        hasLength(3),
        reason: 'LineChart.tsx:775 walks every point, not every segment',
      );
      expect(
        marks.map((mark) => mark.strokeWidth).toSet(),
        <double>{1},
        reason: 'LineChart.tsx:803 pins the engine B marker stroke to 1',
      );
    });

    test('an engine B marker never grows, because upstream compares ids', () {
      expect(
        _lineDelegate(
          curve: FluentLineCurve.linear,
          mode: const FluentLineMode(markers: true),
          activePointId: '0_1',
        ).markersFor(_ctx()).map((mark) => mark.size).toSet(),
        <double>{3.5},
        reason:
            'parity: LineChart.tsx:790 tests activePoint against the id '
            'PREFIX _circleId, never against this marker own id, so the '
            'active radius 5.5 is unreachable there',
      );
    });

    test('the active point grows to the hover box and inverts its fill', () {
      final theme = _theme();
      final marks = _lineDelegate(activePointId: '0_1').markersFor(_ctx());
      final active = marks[1];
      expect(
        active.size,
        FluentLineMarkerPainter.kHoverSize,
        reason: 'PointSize.hoverSize is 11, LineChart.tsx:64 and :466',
      );
      expect(
        active.fill,
        FluentChartColors.of(theme).markStroke,
        reason:
            '_getPointFill inverts the active marker to '
            'colorNeutralBackground1, LineChart.tsx:499',
      );
      expect(
        marks[0].size,
        FluentLineMarkerPainter.kInvisibleSize,
        reason: 'its neighbours stay at the invisible size',
      );
    });

    test('an active circle marker grows to the 5.5 active radius', () {
      expect(
        _lineDelegate(
          mode: const FluentLineMode(markers: true),
          activePointId: '0_2',
        ).markersFor(_ctx())[2].size,
        5.5,
        reason:
            'calculateMarkerRadius returns activeRadius 5.5 on the falsy '
            'markerSize branch, utilities.ts:2325 and :2343',
      );
    });

    test('a point markerColor beats both the series colour and the hover', () {
      const authored = Color(0xFF884422);
      final marks = _lineDelegate(
        markerColor: authored,
        activePointId: '0_1',
      ).markersFor(_ctx());
      expect(
        marks[1].fill,
        authored,
        reason:
            'LineChart.tsx:910 is `markerColor || _getPointFill(…)`, and the '
            'JS || short-circuits ahead of the active inversion',
      );
      expect(
        marks[0].fill,
        authored,
        reason: 'an inactive point reads the same colour',
      );
    });

    test('hideInactiveDots dims every marker but the active one', () {
      final marks = _lineDelegate(
        hideInactiveDots: true,
        activePointId: '0_1',
      ).markersFor(_ctx());
      expect(
        marks.map((mark) => mark.opacity),
        <double>[0.01, 1, 0.01],
        reason:
            'currentPointHidden (LineChart.tsx:841) folds into the same 0.01 '
            'the legend dimming uses at :909',
      );
    });

    test('a marker of an unhighlighted legend dims to 0.01', () {
      expect(
        _lineDelegate(legends: const <String>['a', 'b'], selectedLegend: 'a')
            .markersFor(_ctx())
            .where((mark) => mark.seriesIndex == 1)
            .map((mark) => mark.opacity),
        everyElement(0.01),
        reason: 'LineChart.tsx:909 — engine A dims markers to 0.01',
      );
    });

    test('paintSeries paints each series markers after its own line', () {
      final recorder = _LineRecorder();
      _lineDelegate(ys: const <double>[1, 2]).paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      expect(
        recorder.paths,
        hasLength(4),
        reason:
            'two points, each filled then stroked (LineChart.tsx:1366 puts '
            'pointsForLine last inside the series <g>)',
      );
      for (final painted in recorder.paths) {
        expect(
          painted.$1.width,
          closeTo(
            FluentLineMarkerPainter.kInvisibleSize,
            _kPathBoundsTolerance,
          ),
          reason: 'and each painted path is the 1px invisible box',
        );
      }
    });

    test('an inactive one-point marker is filled but never stroked', () {
      final recorder = _LineRecorder();
      _lineDelegate(ys: const <double>[5]).paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      expect(
        recorder.paths.map((entry) => entry.$2),
        <PaintingStyle>[PaintingStyle.fill],
        reason:
            'strokeWidth 0 is SVG for no outline (LineChart.tsx:623); Flutter '
            'would draw a hairline if it were stroked anyway',
      );
    });

    test('high contrast flattens the marker fill and stroke differently', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final colours = FluentChartColors.of(theme);
      final mark = _lineDelegate(withTheme: theme).markersFor(_ctx()).first;
      expect(
        mark.fill,
        colours.flattenMark(FluentDataVizPalette.next(0)),
        reason: 'spec §5.3: a series mark flattens to the system colour',
      );
      expect(
        mark.stroke,
        colours.flattenMarkStroke(FluentDataVizPalette.next(0)),
        reason:
            'while its outline flattens to the CANVAS colour, or a 4px '
            'stroke around a 1px box erases the marker it outlines',
      );
      expect(
        mark.stroke,
        isNot(mark.fill),
        reason: 'flattening both the same way would erase the outline',
      );
    });

    test('high contrast flattens an authored line border colour', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final colours = FluentChartColors.of(theme);
      // An authored colour, unlike the colorNeutralBackground1 default, is not
      // already equal to what flattenMarkStroke returns — which is what makes
      // this assertion bite where a default-coloured halo cannot.
      const authored = Color(0xFF884422);
      final segment = _lineDelegate(
        lineBorderWidth: 2,
        lineBorderColor: authored,
        withTheme: theme,
      ).segmentsFor(_ctx()).first;
      expect(
        segment.borderColour,
        colours.flattenMarkStroke(authored),
        reason:
            'LineChart.tsx:1233 takes lineBorderColor as authored, and spec '
            '§5.3 flattens the halo to the canvas colour under forced colours',
      );
      expect(
        segment.borderColour,
        isNot(authored),
        reason:
            'the authored colour must not survive high contrast, or the halo '
            'is indistinguishable from the flattened line in front of it',
      );
    });
  });

  group('LineChart markers against Oracle B', () {
    // Every LineChart story leaves allowMultipleShapesForPoints unset and
    // declares no mode, so all 236 captured markers are shape 0 at the
    // invisible size. That is what the corpus can prove: placement, count,
    // size, paint and dimming. The twenty-four shape coefficients are proved
    // separately against `_getPointPath` by the bounds group above.
    for (final id in oracleStoryIds(component: 'LineChart')) {
      test('$id reproduces every captured marker', () {
        final story = loadOracleStory(id);
        final groups = _plotMarkerGroups(story);
        if (id == 'charts-linechart--line-chart-large-data') {
          expect(
            groups,
            isEmpty,
            reason:
                'the one optimizeLargeData story renders its points through '
                'the engine B circle branch, so it must contribute no shape '
                'marker at all',
          );
          return;
        }
        expect(
          groups,
          isNotEmpty,
          reason:
              '$id must contribute a marker group, or this test is a pass '
              'having measured nothing',
        );
        for (final captured in groups) {
          final marks = _delegateFromCapturedMarkers(
            captured,
          ).markersFor(_identityCtx());
          expect(
            marks.length,
            captured.length,
            reason:
                'engine A emits one marker per point (LineChart.tsx:846 and '
                ':1010) and the capture holds ${captured.length}',
          );
          for (var i = 0; i < captured.length; i++) {
            final numbers = svgPathNumbers(captured[i].d!);
            // M x-w/2 y  A w/2 w/2 0 1 0 x+w/2 y  M …  A … — eighteen numbers,
            // of which the chord is the box width _getBoxWidthOfShape chose.
            final box = numbers[7] - numbers[0];
            expectOracleNumber('$id marker $i box width', box, marks[i].size);
            expect(
              marks[i].shapeIndex,
              0,
              reason:
                  'the captured d is two 180° arcs, which is allPointPaths[0] '
                  '(LineChart.tsx:84-88)',
            );
            expectOracleSvgPath(
              '$id marker $i path',
              captured[i].d!,
              _shapeZeroPath(marks[i].path.getBounds()),
            );
            expectOracleNumber(
              '$id marker $i stroke width',
              captured[i].strokeWidth,
              marks[i].strokeWidth,
            );
            expectOracleNumber(
              '$id marker $i opacity',
              captured[i].opacity,
              marks[i].opacity,
            );
            expectOracleColour(
              '$id marker $i fill',
              captured[i].fill,
              marks[i].fill,
            );
            expectOracleColour(
              '$id marker $i stroke',
              captured[i].stroke,
              marks[i].stroke,
            );
          }
        }
      });
    }

    test('line-chart-basic reproduces its one-point circle at r 3.5', () {
      final story = loadOracleStory('charts-linechart--line-chart-basic');
      // The story also carries two `opacity: 0` r-8 circles at cx 680 — the
      // invisible callout latches of LineChart.tsx:1155-1165, not markers — so
      // the drawn one is the visible one, exactly as marker_geometry_test.dart
      // already selects it.
      final circles = story
          .byTag('circle')
          .where((circle) => circle.opacity != 0)
          .toList();
      expect(
        circles.length,
        1,
        reason:
            'the basic story captures one visible circle, its one-point '
            'series; a different count would read the radius off the wrong '
            'element',
      );
      final captured = circles.single;
      final mark = _delegate(
        <FluentLineChartSeries>[
          FluentLineChartSeries(
            legend: 'lone',
            color: captured.fill,
            data: <FluentLineChartDataPoint>[
              FluentLineChartDataPoint(x: captured.cx!, y: captured.cy!),
            ],
          ),
        ],
        theme: _theme(),
        selectedLegend: '',
      ).markersFor(_identityCtx()).single;
      expect(
        mark.shapeIndex,
        isNull,
        reason:
            'LineChart.tsx:577 draws a one-point series as a <circle>, never '
            'through _getPointPath',
      );
      expectOracleOffset(
        'the one-point circle centre',
        captured.centre,
        mark.centre,
      );
      expectOracleNumber('the one-point circle radius', captured.r!, mark.size);
      expectOracleNumber(
        'the one-point circle stroke width',
        captured.strokeWidth,
        mark.strokeWidth,
      );
      expectOracleNumber(
        'the one-point circle opacity',
        captured.opacity,
        mark.opacity,
      );
      expectOracleColour('the one-point circle fill', captured.fill, mark.fill);
    });

    test('the corpus dims some markers and leaves others opaque', () {
      // Without both cases present every opacity assertion above could pass on
      // a port that hard-codes 1.
      final opacities = <double>{
        for (final id in oracleStoryIds(component: 'LineChart'))
          for (final group in _plotMarkerGroups(loadOracleStory(id)))
            for (final marker in group) marker.opacity,
      };
      expect(
        opacities,
        <double>{1, 0.01},
        reason:
            'the gaps story highlights one of its four legends, so the corpus '
            'carries both the undimmed 1 and the engine A 0.01 of '
            'LineChart.tsx:909',
      );
    });
  });

  group('LineChart engine B', () {
    test('the path is broken at every non-plottable point', () {
      final d = _lineDelegate(
        ys: const <double>[1, 2, double.nan, 3, 4],
        curve: FluentLineCurve.linear,
      );
      final path = d.singlePathFor(0, _ctx());
      expect(
        path!.computeMetrics().length,
        2,
        reason:
            'defined(isPlottable) makes d3.line emit two sub-paths, '
            'LineChart.tsx:678',
      );
    });

    test('a series shorter than two points has no path at all', () {
      expect(
        _lineDelegate(
          ys: const <double>[1],
          curve: FluentLineCurve.linear,
        ).singlePathFor(0, _ctx()),
        isNull,
        reason:
            'LineChart.tsx:670 gates the whole path branch on '
            'data.length > 1',
      );
    });

    test('engine B markers pin the stroke width to 1', () {
      final d = _lineDelegate(curve: FluentLineCurve.linear);
      expect(
        d.markerStrokeWidthForEngineB,
        1,
        reason:
            'parity: LineChart.tsx:803 uses 1 regardless of the series '
            'stroke width, unlike engine A',
      );
    });

    test('engine B dims markers to 0.1, not 0.01', () {
      final d = _lineDelegate(
        curve: FluentLineCurve.linear,
        legends: const <String>['a', 'b'],
        selectedLegend: 'a',
      );
      expect(
        d.markerOpacityForEngineB('b'),
        0.1,
        reason: 'LineChart.tsx:804 — the two engines dim markers differently',
      );
      expect(
        d.markerOpacityFor('b'),
        0.01,
        reason: 'engine A still dims to 0.01, LineChart.tsx:909',
      );
    });

    test('engine A contributes no single path', () {
      expect(
        _lineDelegate().singlePathsFor(_ctx()),
        isEmpty,
        reason:
            'LineChart.tsx:816 is an else-if on the same condition, so the '
            'segment engine and the path engine never both run',
      );
      expect(
        _lineDelegate(curve: FluentLineCurve.linear).segmentsFor(_ctx()),
        isEmpty,
        reason: 'and the exclusion holds in the other direction too',
      );
    });

    test('shouldDrawLines suppresses the stroke only for bare markers', () {
      expect(
        _lineDelegate(
          curve: FluentLineCurve.linear,
          mode: const FluentLineMode(lines: false, markers: true),
        ).singlePathsFor(_ctx()),
        isEmpty,
        reason:
            'shouldDrawLines (LineChart.tsx:698) gates both arms, :699 and '
            ':736, so a markers-only series strokes nothing',
      );
      expect(
        _lineDelegate(
          curve: FluentLineCurve.linear,
          mode: const FluentLineMode(markers: true, text: true),
        ).singlePathsFor(_ctx()),
        hasLength(1),
        reason:
            "only the bare 'markers' literal loses its line — 'markers+text' "
            'keeps one (LineChart.tsx:698)',
      );
    });

    test('the deselected arm dims the line and drops its halo', () {
      final singles = _lineDelegate(
        curve: FluentLineCurve.linear,
        legends: const <String>['a', 'b'],
        selectedLegend: 'a',
        lineBorderWidth: 4,
      ).singlePathsFor(_ctx());
      final selected = singles.firstWhere((s) => s.seriesIndex == 0);
      final dimmed = singles.firstWhere((s) => s.seriesIndex == 1);
      expect(
        selected.opacity,
        1,
        reason: 'LineChart.tsx:729 — the selected arm is opaque',
      );
      expect(
        selected.borderWidth,
        8,
        reason:
            'LineChart.tsx:711 strokes the halo at strokeWidth + '
            'lineBorderWidth, i.e. the 4px default plus 4',
      );
      expect(
        dimmed.opacity,
        0.1,
        reason:
            'LineChart.tsx:750 — engine B dims a line to 0.1, the same as '
            'engine A at :1306 and not the 0.01 it dims a marker to',
      );
      expect(
        dimmed.borderWidth,
        isNull,
        reason:
            'the else-if at LineChart.tsx:736 pushes the line alone, so a '
            'dimmed series shows no halo even having asked for one',
      );
    });

    test('the engine B line and its halo flatten apart', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final colours = FluentChartColors.of(theme);
      final single = _lineDelegate(
        curve: FluentLineCurve.linear,
        lineBorderWidth: 2,
        withTheme: theme,
      ).singlePathsFor(_ctx()).single;
      expect(
        single.colour,
        colours.flattenMark(FluentDataVizPalette.next(0)),
        reason:
            'LineChart.tsx:723 strokes the same `lineColor` engine A does at '
            ':1282, so spec §5.3 must flatten it the same way',
      );
      expect(
        single.borderColour,
        colours.flattenMarkStroke(theme.colors.neutralBackground1),
        reason:
            'the halo at LineChart.tsx:713 flattens to the CANVAS colour, or '
            'it merges with the line it sits behind',
      );
    });

    test('paintSeries strokes the engine B halo before its line', () {
      final recorder = _LineRecorder();
      _lineDelegate(
        curve: FluentLineCurve.linear,
        lineBorderWidth: 4,
      ).paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      expect(
        recorder.pathPaints.map((entry) => entry.strokeWidth).toList(),
        const <double>[8, 4],
        reason:
            'LineChart.tsx:1362-1363 renders bordersForLine before '
            'linesForLine, so the halo never covers a neighbouring series',
      );
    });

    test('paintSeries cuts a dashed engine B path into its runs', () {
      ({double length, int contours}) stroke({String? dash}) {
        final recorder = _LineRecorder();
        _lineDelegate(
          curve: FluentLineCurve.linear,
          strokeDasharray: dash,
        ).paintSeries(
          recorder,
          _ctx(),
          _layout(),
          FluentChartColors.of(_theme()),
        );
        final only = recorder.pathPaints.single;
        return (length: only.length, contours: only.contours);
      }

      // `Path.computeMetrics` measures in float32 and `extractPath` re-rounds
      // every contour it cuts, so the error accumulates with the run count.
      // Four orders below the 2-unit dash this test is about.
      const float32Slack = 1e-4;
      // ys 1,2,3 at x 0,1,2 under `_ctx` is two 10x10 steps.
      final solid = stroke();
      expect(
        solid.length,
        closeTo(2 * sqrt(200), float32Slack),
        reason: 'the undashed path walks both steps of the polyline',
      );
      expect(
        solid.contours,
        1,
        reason: 'and it walks them without lifting the pen',
      );
      // `strokeDasharray='2'` parses to [2, 2] — on and off by two.
      const on = 2.0;
      final cycles = (solid.length / (on * 2)).floor();
      final tail = solid.length - cycles * on * 2;
      final dashed = stroke(dash: '2');
      expect(
        dashed.length,
        closeTo(cycles * on + (tail < on ? tail : on), float32Slack),
        reason:
            'LineChart.tsx:730 dashes the line, and Canvas has no dash '
            'support, so the path itself must be cut into its on runs',
      );
      expect(
        dashed.contours,
        cycles + 1,
        reason:
            'one contour per surviving run plus the tail that starts on a '
            'dash; a single contour means the pattern was ignored',
      );
    });
  });

  group('LineChart engine B against Oracle B', () {
    // `line-chart-large-data` is the one story that sets optimizeLargeData, so
    // it is the only capture of the single-path engine in the corpus. Each of
    // its two series is captured twice — the 8px halo and the 4px line share
    // one `d`, which is exactly what a port emitting one Path per series must
    // reproduce.
    test('line-chart-large-data reproduces the captured single path', () {
      final story = loadOracleStory('charts-linechart--line-chart-large-data');
      final paths = story
          .byTag('path')
          .where((e) => e.d != null && e.strokeWidth == 4 && e.d!.length > 200)
          .toList();
      expect(
        paths.length,
        2,
        reason:
            'the story draws two optimizeLargeData series; with none the '
            'loop below asserts nothing',
      );
      for (final captured in paths) {
        final numbers = svgPathNumbers(captured.d!);
        expect(
          numbers.length.isEven && numbers.length >= 4,
          isTrue,
          reason: 'an M followed by Ls is two numbers per point',
        );
        final points = <Offset>[
          for (var i = 0; i < numbers.length; i += 2)
            Offset(numbers[i], numbers[i + 1]),
        ];
        final path = _delegateFromPoints(
          points,
        ).singlePathFor(0, _identityCtx())!;
        final metrics = path.computeMetrics().toList();
        expect(
          metrics.length,
          1,
          reason:
              'every captured point is plottable, so defined() never breaks '
              'the path — LineChart.tsx:678 emits one sub-path',
        );
        var polyline = 0.0;
        for (var i = 1; i < points.length; i++) {
          polyline += (points[i] - points[i - 1]).distance;
        }
        expect(
          metrics.single.length,
          closeTo(polyline, points.length * kOracleGeometryTolerance),
          reason:
              'the ported path must walk all ${points.length} captured '
              'points in order under the linear curve',
        );
        expectOracleRect(
          'large-data path bounds',
          Rect.fromLTRB(
            points.map((p) => p.dx).reduce(min),
            points.map((p) => p.dy).reduce(min),
            points.map((p) => p.dx).reduce(max),
            points.map((p) => p.dy).reduce(max),
          ),
          path.getBounds(),
          tolerance: kOracleMeasuredTolerance,
        );
      }
    });
  });

  group('LineChart colour fill bars', () {
    test('the rect is padded 3px above and 3px taller', () {
      final d = _lineDelegateWithFillBar(startX: 2, endX: 5);
      final bar = d.colorFillBarRectsFor(_ctx(), _layout()).single;
      expect(
        bar.rect.top,
        closeTo(_ctx().yScalePrimary(_yMax)! - 3, 1e-9),
        reason: 'FILL_Y_PADDING == 3, LineChart.tsx:1381 and :1404',
      );
      expect(
        bar.rect.height,
        closeTo(
          _ctx().yScalePrimary(0)! - _ctx().yScalePrimary(_yMax)! + 3,
          1e-9,
        ),
        reason:
            'height = yScale(yMinValue || 0) - yScale(yMax) + 3, '
            'LineChart.tsx:1406',
      );
      expect(
        bar.rect.left,
        closeTo(_ctx().xScale(2)!, 1e-9),
        reason: 'left-to-right takes x from startX, LineChart.tsx:1403',
      );
      expect(
        bar.rect.width,
        closeTo((_ctx().xScale(5)! - _ctx().xScale(2)!).abs(), 1e-9),
        reason: 'width is the absolute span, LineChart.tsx:1405',
      );
    });

    test('an unpatterned bar is 0.4 and a patterned one is 1', () {
      expect(
        _lineDelegateWithFillBar(
          startX: 2,
          endX: 5,
        ).colorFillBarRectsFor(_ctx(), _layout()).single.opacity,
        0.4,
        reason: 'LineChart.tsx:1828-1830',
      );
      expect(
        _lineDelegateWithFillBar(
          startX: 2,
          endX: 5,
          applyPattern: true,
        ).colorFillBarRectsFor(_ctx(), _layout()).single.opacity,
        1,
        reason: 'applyPattern lifts the opacity to 1',
      );
    });

    test('a bar the highlighted legend is not dims to 0.1', () {
      expect(
        _lineDelegateWithFillBar(
          startX: 2,
          endX: 5,
          selectedLegend: 'a',
        ).colorFillBarRectsFor(_ctx(), _layout()).single.opacity,
        0.1,
        reason:
            'LineChart.tsx:1396-1398 dims a bar whose legend is not the '
            'selected one, patterned or not',
      );
    });

    test('high contrast flattens the fill colour', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      const authored = Color(0xFF884422);
      expect(
        _lineDelegateWithFillBar(
          startX: 2,
          endX: 5,
          color: authored,
          withTheme: theme,
        ).colorFillBarRectsFor(_ctx(), _layout()).single.colour,
        FluentChartColors.of(theme).flattenMark(authored),
        reason: 'spec §5.3: a series mark flattens to the system colour',
      );
    });

    test('a plain band is painted behind every line and marker', () {
      final recorder = _LineRecorder();
      final delegate = _lineDelegateWithFillBar(startX: 2, endX: 5);
      delegate.paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      final band = recorder.rects.single;
      expect(
        band.rect,
        delegate.colorFillBarRectsFor(_ctx(), _layout()).single.rect,
        reason:
            'the painted rect is the one colorFillBarRectsFor resolved, or the '
            'geometry the five assertions above pin is not what reaches the '
            'canvas',
      );
      expect(
        // Read as 32-bit ARGB because `Paint` keeps its colour in 32-bit
        // floats: 0.4 comes back out as 0.4000000059604645, so the components
        // do not compare equal to the doubles they were set from.
        band.colour.toARGB32(),
        const Color(0xFF0078D4).withValues(alpha: 0.4).toARGB32(),
        reason:
            'fill={color} fillOpacity={0.4} (LineChart.tsx:1401-1402 with '
            ':1828-1830)',
      );
      expect(
        <int>[band.pathsBefore, band.linesBefore],
        const <int>[0, 0],
        reason:
            'LineChart.tsx:1951-1952 puts _renderedColorFillBars ahead of '
            '{lines} inside one <g>, so the band is behind every segment, '
            'halo and marker of the series loop',
      );
    });

    test('a patterned band tiles the stripe pattern instead of filling', () {
      final style = resolveFluentLineChartStyle(_theme());
      final tileSize = style.stripeTileSize!.resolve(<WidgetState>{})!;
      final stripeWidth = style.stripeStrokeWidth!.resolve(<WidgetState>{})!;
      final delegate = _lineDelegateWithFillBar(
        startX: 2,
        endX: 5,
        applyPattern: true,
      );
      final rect = delegate.colorFillBarRectsFor(_ctx(), _layout()).single.rect;
      final recorder = _LineRecorder();
      delegate.paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      expect(
        recorder.rects,
        isEmpty,
        reason:
            'LineChart.tsx:1401 fills a patterned band with url(#pattern), so '
            'no flat rect is drawn for one',
      );
      // patternUnits="userSpaceOnUse" (LineChart.tsx:1425) anchors the tile
      // grid on the plot origin rather than on the rect, so the first tile of
      // each axis is the last multiple of the tile size at or before that edge.
      var tiles = 0;
      for (
        var x = (rect.left / tileSize).floorToDouble() * tileSize;
        x < rect.right;
        x += tileSize
      ) {
        for (
          var y = (rect.top / tileSize).floorToDouble() * tileSize;
          y < rect.bottom;
          y += tileSize
        ) {
          tiles++;
        }
      }
      expect(
        tiles,
        greaterThan(1),
        reason:
            'the fixture band must span more than one tile or the count below '
            'cannot tell a tiled pattern from a single stamp',
      );
      expect(
        recorder.strokeWidths.where((width) => width == stripeWidth).length,
        tiles * 3,
        reason:
            'every tile draws the three diagonals of M-4,4 l8,-8 M0,16 '
            'l16,-16 M12,20 l8,-8 (LineChart.tsx:1418) at strokeWidth 1.25 '
            '(:1427); an anchor on rect.left instead of on the plot origin '
            'lands on a different tile count',
      );
    });

    test('a painted band flattens its colour under high contrast', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      const authored = Color(0xFF884422);
      final recorder = _LineRecorder();
      _lineDelegateWithFillBar(
        startX: 2,
        endX: 5,
        color: authored,
        withTheme: theme,
      ).paintSeries(recorder, _ctx(), _layout(), FluentChartColors.of(theme));
      expect(
        recorder.rects.single.colour.toARGB32(),
        FluentChartColors.of(
          theme,
        ).flattenMark(authored).withValues(alpha: 0.4).toARGB32(),
        reason:
            'spec §5.3: the colour that reaches the canvas is the flattened '
            'one, at the 0.4 of LineChart.tsx:1830',
      );
    });
  });

  group('FluentChartStripeTilePainter', () {
    test('paints three diagonals inside a 16px tile', () {
      final recorder = _LineRecorder();
      FluentChartStripeTilePainter(
        color: const Color(0xFF112233),
        strokeWidth: 1.25,
      ).paint(recorder, const Size(16, 16));
      expect(
        recorder.drawn.length,
        3,
        reason:
            'the tile path is M-4,4 l8,-8 M0,16 l16,-16 M12,20 l8,-8, '
            'LineChart.tsx:1418',
      );
      expect(
        recorder.drawn,
        const <(Offset, Offset)>[
          (Offset(-4, 4), Offset(4, -4)),
          (Offset(0, 16), Offset(16, 0)),
          (Offset(12, 20), Offset(20, 12)),
        ],
        reason: 'each l8,-8 / l16,-16 is a 45° diagonal up and to the right',
      );
      expect(recorder.strokeWidths, const <double>[
        1.25,
        1.25,
        1.25,
      ], reason: 'strokeWidth={1.25}, LineChart.tsx:1427');
    });

    test('a tile repaints only when its colour or width changes', () {
      final tile = FluentChartStripeTilePainter(
        color: const Color(0xFF112233),
        strokeWidth: 1.25,
      );
      expect(
        tile.shouldRepaint(
          FluentChartStripeTilePainter(
            color: const Color(0xFF112233),
            strokeWidth: 1.25,
          ),
        ),
        isFalse,
        reason: 'an identical tile is the same picture',
      );
      expect(
        tile.shouldRepaint(
          FluentChartStripeTilePainter(
            color: const Color(0xFF112233),
            strokeWidth: 2,
          ),
        ),
        isTrue,
        reason: 'a different stroke width is a different picture',
      );
    });
  });

  // `LineChart.tsx:645-660`, `:916-935` and `:1082-1100` are the only three
  // places a point's own `text` is drawn. All three gate on
  // `!_isScatterPolar && supportsTextMode && text`, where `supportsTextMode` is
  // `lineOptions.mode?.includes('text')` (`:571`, `:842`, `:1008`) — a
  // per-series substring test, and NOT `isTextMode` (`utilities.ts:2216-2221`),
  // which compares the whole literal across every series and is what
  // ScatterChart reads instead.
  group('FluentLineChartDelegate point text labels', () {
    FluentLineMode textMode() => FluentLineMode.parse(_kTextMode);

    /// `calculateMarkerRadius`'s own `defaultRadius` (`utilities.ts:2324`), the
    /// radius of a point that names no `markerSize`.
    const defaultRadius = 3.5;

    /// `markerLabelGap`, the `+ 12` at `LineChart.tsx:652`, `:929` and `:1095`.
    const gap = 12.0;

    test('a point in text mode carries its own text below its marker', () {
      final marks = _lineDelegate(
        ys: const <double>[1, 2, 3],
        mode: textMode(),
        texts: const <String?>['a', 'b', 'c'],
      ).markersFor(_ctx());
      expect(
        marks.map((mark) => mark.label).toList(),
        // parity: the LAST point is labelled from `data[j - 1]`. `:1099`
        // renders `text`, the binding made at `:843` for the point *before* j,
        // while the gate at `:1082` reads `lastText` = `data[j].text` from
        // `:1009`. Reproduced, not repaired: the two bindings are one line
        // apart upstream and the gate is what decides whether anything is
        // drawn at all.
        <String?>['a', 'b', 'b'],
        reason:
            'LineChart.tsx:843 labels each point from its own text; :1009 and '
            ':1099 disagree about which point the last label belongs to',
      );
      expect(
        marks.map((mark) => mark.labelBaselineOffset).toList(),
        everyElement(closeTo(defaultRadius + gap, 1e-9)),
        reason:
            'LineChart.tsx:919-929 adds calculateMarkerRadius(...) to 12, and '
            'no point here names a markerSize',
      );
    });

    test('hovering a point grows its marker but never moves its label', () {
      final marks = _lineDelegate(
        ys: const <double>[1, 2, 3],
        mode: textMode(),
        texts: const <String?>['a', 'b', 'c'],
        activePointId: '0_1',
      ).markersFor(_ctx());
      expect(
        marks[1].size,
        closeTo(5.5, 1e-9),
        reason:
            'the circle at LineChart.tsx:860-866 passes isActive, so it grows '
            'to activeRadius (utilities.ts:2325)',
      );
      expect(
        marks[1].labelBaselineOffset,
        closeTo(defaultRadius + gap, 1e-9),
        reason:
            'the label at LineChart.tsx:920-926 passes NO isActive, so it '
            'keeps the inactive radius while the marker under it grows',
      );
    });

    test('a dimmed series still paints its last label fully opaque', () {
      final marks = _lineDelegate(
        ys: const <double>[1, 2, 3],
        mode: textMode(),
        texts: const <String?>['a', 'b', 'c'],
        selectedLegend: 'another legend',
      ).markersFor(_ctx());
      expect(
        marks.map((mark) => mark.opacity).toList(),
        everyElement(closeTo(0.01, 1e-9)),
        reason:
            'LineChart.tsx:909 dims every marker of an unselected legend to '
            '0.01',
      );
      expect(
        marks.map((mark) => mark.labelOpacity).toList(),
        <Matcher>[closeTo(0.01, 1e-9), closeTo(0.01, 1e-9), closeTo(1, 1e-9)],
        reason:
            'parity: :933 carries the same opacity as its circle, but the '
            'last-point label at :1085-1097 carries no opacity attribute at '
            'all, so SVG leaves it at 1 while its own circle is at 0.01',
      );
    });

    test('a one-point series floors its label offset where the marker does '
        'not', () {
      final marks = _lineDelegate(
        ys: const <double>[1],
        mode: textMode(),
        texts: const <String?>['solo'],
      ).markersFor(_ctx());
      expect(
        marks.single.label,
        'solo',
        reason: 'LineChart.tsx:572 reads data[0].text and :659 renders it',
      );
      expect(
        marks.single.size,
        closeTo(defaultRadius, 1e-9),
        reason:
            'the circle at LineChart.tsx:578-585 is calculateMarkerRadius, '
            'which returns defaultRadius unclamped',
      );
      expect(
        marks.single.labelBaselineOffset,
        closeTo(kMarkerMinPixel + gap, 1e-9),
        reason:
            'parity: LineChart.tsx:650 inlines its own radius — '
            'Math.max(size ? ... : 3.5, 4) — instead of calling '
            'calculateMarkerRadius, so the label is floored at 4 while the '
            'marker it hangs from is 3.5',
      );
    });

    test('a series that names no text mode paints no labels', () {
      expect(
        _lineDelegate(
          ys: const <double>[1, 2, 3],
          texts: const <String?>['a', 'b', 'c'],
        ).markersFor(_ctx()).map((mark) => mark.label),
        everyElement(isNull),
        reason:
            'supportsTextMode is false without a mode, so the && at '
            'LineChart.tsx:645 short-circuits before the text is read',
      );
    });

    test('a point with no text of its own is not labelled', () {
      expect(
        _lineDelegate(
          ys: const <double>[1, 2, 3],
          mode: textMode(),
          texts: const <String?>['a', null, 'c'],
        ).markersFor(_ctx()).map((mark) => mark.label).toList(),
        // Index 2 reads index 1's text, which is the null.
        <String?>['a', null, null],
        reason: 'the `&& text` conjunct of LineChart.tsx:916 rejects it',
      );
    });

    test('one scatterpolar trace suppresses every other series labels', () {
      final marks = _delegate(
        <FluentLineChartSeries>[
          FluentLineChartSeries(
            legend: 'labelled',
            lineOptions: FluentLineOptions(mode: textMode()),
            data: <FluentLineChartDataPoint>[
              for (var i = 0; i < 3; i++)
                FluentLineChartDataPoint(x: i, y: i + 1, text: 'p$i'),
            ],
          ),
          FluentLineChartSeries(
            legend: 'radar',
            lineOptions: FluentLineOptions(
              mode: FluentLineMode.parse('scatterpolar'),
            ),
            data: <FluentLineChartDataPoint>[
              for (var i = 0; i < 3; i++)
                FluentLineChartDataPoint(x: i, y: i + 1),
            ],
          ),
        ],
        theme: _theme(),
        selectedLegend: '',
      ).markersFor(_ctx());
      expect(
        marks.map((mark) => mark.label),
        everyElement(isNull),
        reason:
            '_isScatterPolar is isScatterPolarSeries(_points), a `.some` over '
            'the WHOLE chart (utilities.ts:2205), and the !_isScatterPolar at '
            'LineChart.tsx:916 is read for every series — one radar trace '
            'silences a text trace beside it',
      );
    });

    test('paintSeries centres each label on its marker at the baseline', () {
      final delegate = _lineDelegate(
        ys: const <double>[1, 2, 3],
        mode: textMode(),
        texts: const <String?>['a', 'b', 'c'],
      );
      final recorder = _LineRecorder();
      delegate.paintSeries(
        recorder,
        _ctx(),
        _layout(),
        FluentChartColors.of(_theme()),
      );
      final marks = delegate.markersFor(_ctx());
      final style = FluentChartTextStyles.of(_theme()).markerLabel;
      final measurer = FluentChartTextMeasurer();
      expect(
        recorder.paragraphs,
        <Offset>[
          for (final mark in marks)
            Offset(
              mark.centre.dx - measurer.measure(mark.label!, style).width / 2,
              mark.centre.dy +
                  mark.labelBaselineOffset -
                  measurer.measure(mark.label!, style).ascent,
            ),
        ],
        reason:
            'text-anchor: middle on the alphabetic baseline of an SVG <text> '
            '(Common.styles.ts:72-81), the same reading ScatterChart.tsx:'
            '481-488 already settled',
      );
    });
  });

  group('FluentLineChart', () {
    Future<void> pump(
      WidgetTester tester,
      Widget chart, {
      Size size = const Size(700, 350),
    }) => tester.pumpWidget(
      FluentApp(
        theme: _theme(),
        home: Center(
          child: SizedBox(width: size.width, height: size.height, child: chart),
        ),
      ),
    );

    FluentCartesianChart shellOf(WidgetTester tester) =>
        tester.widget<FluentCartesianChart>(find.byType(FluentCartesianChart));

    testWidgets('the mounted chart really paints its point labels', (
      tester,
    ) async {
      // `markersFor` can resolve a label and `paintSeries` can still drop it,
      // which is exactly how four helpers before this one shipped green and
      // uncalled. Only the paragraph count the widget's OWN painter emits is
      // evidence, and it is read as a delta so the axis tick labels — which
      // are identical between the two mounts — cancel out.
      Future<int> paragraphsFor(List<String?> texts) async {
        await pump(tester, FluentLineChart(data: _textModeLineData(texts)));
        final plot = find
            .descendant(
              of: find.byType(FluentCartesianChart),
              matching: find.byType(CustomPaint),
            )
            .first;
        final recorder = _LineRecorder();
        tester
            .widget<CustomPaint>(plot)
            .painter!
            .paint(recorder, tester.getSize(plot));
        return recorder.paragraphs.length;
      }

      final labelled = await paragraphsFor(const <String?>['a', 'b', 'c', 'd']);
      final bare = await paragraphsFor(const <String?>[null, null, null, null]);
      expect(
        labelled - bare,
        4,
        reason:
            'LineChart.tsx:916 labels points 0..2 from their own text and '
            ':1082 labels point 3 from point 2 — four <text> nodes for a '
            'four-point line. A delta of 0 means paintSeries never reaches '
            'them from FluentLineChart.build',
      );
    });

    testWidgets('the mounted chart really paints its markers', (tester) async {
      // Every other marker test drives a hand-built delegate. This one takes
      // the painter the widget itself mounted, so it fails if `markersFor`
      // stops being reached from `FluentLineChart.build` — the delegate the
      // shell is handed, the layout it solved, the size it was given.
      await pump(tester, FluentLineChart(data: _lineData()));
      // The plot is the first CustomPaint under the shell: the Column puts it
      // ahead of the legend (`cartesian_chart.dart:370-382`), and it is built
      // with `painter: FluentCartesianChartPainter` at `:542-543`.
      final plot = find
          .descendant(
            of: find.byType(FluentCartesianChart),
            matching: find.byType(CustomPaint),
          )
          .first;
      final recorder = _LineRecorder();
      tester
          .widget<CustomPaint>(plot)
          .painter!
          .paint(recorder, tester.getSize(plot));
      expect(
        recorder.paths,
        hasLength(16),
        reason:
            'the eight plotted points of _lineData, each filled then stroked '
            '(LineChart.tsx:936); nothing else under the shell draws a path, '
            'because the axes stroke lines (axis_painter.dart:93 and :105) '
            'and every label paints a paragraph',
      );
      final plotRect = Offset.zero & tester.getSize(plot);
      for (final (bounds, _) in recorder.paths) {
        expect(
          bounds.width,
          closeTo(
            FluentLineMarkerPainter.kInvisibleSize,
            _kPathBoundsTolerance,
          ),
          reason:
              'an inactive point of a single-shape line is a 1px box '
              '(LineChart.tsx:479); a zero-width one means the markers are '
              'wired up but draw nothing',
        );
        expect(
          plotRect.contains(bounds.center),
          isTrue,
          reason: 'a marker painted outside $plotRect is not on the plot',
        );
      }
      expect(
        recorder.paths.map((entry) => entry.$1.center.dx).toSet(),
        hasLength(4),
        reason:
            'both series of _lineData share the same four x values, so the '
            'sixteen paths stand on four columns; one column would mean every '
            'marker collapsed onto the same point',
      );
    });

    testWidgets('the mounted chart really paints its engine B lines', (
      tester,
    ) async {
      // The engine-B counterpart of the marker test above: it takes the
      // painter the widget mounted, so it fails if the single-path renderer
      // stops being reached from `FluentLineChart.build`. `_lineData` names no
      // mode, so engine B draws no markers (`LineChart.tsx:773`) and every
      // path the plot emits is a series line.
      await pump(
        tester,
        FluentLineChart(data: _lineData(), optimizeLargeData: true),
      );
      final plot = find
          .descendant(
            of: find.byType(FluentCartesianChart),
            matching: find.byType(CustomPaint),
          )
          .first;
      final recorder = _LineRecorder();
      tester
          .widget<CustomPaint>(plot)
          .painter!
          .paint(recorder, tester.getSize(plot));
      expect(
        recorder.paths.map((entry) => entry.$2).toList(),
        const <PaintingStyle>[PaintingStyle.stroke, PaintingStyle.stroke],
        reason:
            'LineChart.tsx:718 pushes one stroked path per optimizeLargeData '
            'series and _lineData carries two; an empty list means engine B '
            'paints nothing',
      );
      expect(
        recorder.pathPaints.map((entry) => entry.strokeWidth).toList(),
        const <double>[4, 4],
        reason:
            'DEFAULT_LINE_STROKE_SIZE (LineChart.tsx:71) is what :682 falls '
            'back to when neither the series nor the chart names a width',
      );
      final plotRect = Offset.zero & tester.getSize(plot);
      for (var i = 0; i < recorder.paths.length; i++) {
        final bounds = recorder.paths[i].$1;
        expect(
          plotRect.contains(bounds.center),
          isTrue,
          reason: 'a line painted outside $plotRect is not on the plot',
        );
        expect(
          recorder.pathPaints[i].length,
          greaterThan(bounds.width),
          reason:
              'the four points of _lineData rise or fall monotonically, so a '
              'polyline through all four is longer than its own bounding '
              'width; a path holding one point would measure 0',
        );
      }
      expect(
        recorder.paths[0].$1.center.dy,
        isNot(closeTo(recorder.paths[1].$1.center.dy, 1)),
        reason:
            'alpha rises and beta falls, so the two series paths must not '
            'land on top of each other',
      );
    });

    testWidgets('the mounted chart really paints its colour fill bars', (
      tester,
    ) async {
      // `colorFillBarRectsFor` shipped fully tested and uncalled, while
      // line_chart.dart:238 already built a legend entry per band — so a chart
      // given colorFillBars listed them in the legend and painted none of
      // them. Only what the widget's OWN painter emits is evidence.
      Future<_LineRecorder> plotOf(List<FluentColorFillBar> bars) async {
        await pump(
          tester,
          FluentLineChart(data: _lineData(), colorFillBars: bars),
        );
        final plot = find
            .descendant(
              of: find.byType(FluentCartesianChart),
              matching: find.byType(CustomPaint),
            )
            .first;
        final recorder = _LineRecorder();
        tester
            .widget<CustomPaint>(plot)
            .painter!
            .paint(recorder, tester.getSize(plot));
        return recorder;
      }

      const colour = Color(0xFF0078D4);
      FluentColorFillBar bar({required bool applyPattern}) =>
          FluentColorFillBar(
            legend: 'band',
            color: colour,
            applyPattern: applyPattern,
            data: const <FluentColorFillBarRange>[
              FluentColorFillBarRange(startX: 2, endX: 3),
            ],
          );

      final bare = await plotOf(const <FluentColorFillBar>[]);
      expect(
        bare.rects,
        isEmpty,
        reason:
            '_lineData names no chart title and the shell has no axis titles '
            'to back, so nothing else under the plot draws a rect and the '
            'two mounts below can be read directly',
      );
      final plain = await plotOf(<FluentColorFillBar>[
        bar(applyPattern: false),
      ]);
      final band = plain.rects.single;
      expect(
        band.colour.toARGB32(),
        FluentChartColors.of(
          _theme(),
        ).flattenMark(colour).withValues(alpha: 0.4).toARGB32(),
        reason:
            'fill={color} fillOpacity={0.4} (LineChart.tsx:1401-1402 with '
            ':1828-1830); no rect at all means paintSeries never reaches '
            'colorFillBarRectsFor from FluentLineChart.build',
      );
      final plotRect =
          Offset.zero &
          tester.getSize(
            find
                .descendant(
                  of: find.byType(FluentCartesianChart),
                  matching: find.byType(CustomPaint),
                )
                .first,
          );
      expect(
        band.rect.width,
        greaterThan(0),
        reason:
            'x runs 1..4 and the band spans 2..3, so a zero-width rect means '
            'the x scale never reached the band',
      );
      expect(
        plotRect.overlaps(band.rect),
        isTrue,
        reason: 'a band painted clear of $plotRect is not on the plot',
      );
      final patterned = await plotOf(<FluentColorFillBar>[
        bar(applyPattern: true),
      ]);
      expect(
        patterned.rects,
        isEmpty,
        reason:
            'LineChart.tsx:1401 fills a patterned band with url(#pattern) '
            'instead of the flat colour',
      );
      final stripeWidth = resolveFluentLineChartStyle(
        _theme(),
      ).stripeStrokeWidth!.resolve(<WidgetState>{})!;
      expect(
        patterned.strokeWidths.where((width) => width == stripeWidth).length -
            bare.strokeWidths.where((width) => width == stripeWidth).length,
        greaterThan(0),
        reason:
            'the diagonals of LineChart.tsx:1418 are the only thing the plot '
            'strokes at 1.25 (:1427); a delta of 0 means the stripe tile is '
            'unreachable from the mounted widget',
      );
    });

    testWidgets('isCalloutForStack defaults to true', (tester) async {
      await pump(tester, FluentLineChart(data: _lineData()));
      expect(
        tester
            .widget<FluentLineChart>(find.byType(FluentLineChart))
            .isCalloutForStack,
        isTrue,
        reason: 'the destructured default at LineChart.tsx:147',
      );
    });

    testWidgets('isCalloutForStack false narrows the popover to one datum', (
      tester,
    ) async {
      await pump(
        tester,
        FluentLineChart(data: _lineData(), isCalloutForStack: false),
      );
      final state = tester.state<FluentLineChartState>(
        find.byType(FluentLineChart),
      );
      expect(
        state.hoverValuesFor(2).length,
        1,
        reason: 'LineChart.tsx:1660-1668 filters found.values by matching y',
      );
    });

    testWidgets('isCalloutForStack true keeps every series at that x', (
      tester,
    ) async {
      await pump(tester, FluentLineChart(data: _lineData()));
      final state = tester.state<FluentLineChartState>(
        find.byType(FluentLineChart),
      );
      expect(
        state.hoverValuesFor(2).map((point) => point.legend),
        <String>['alpha', 'beta'],
        reason: 'LineChart.tsx:1655 hands the whole stack to the callout',
      );
    });

    testWidgets('event annotations reserve the label band at the top', (
      tester,
    ) async {
      await pump(
        tester,
        FluentLineChart(
          data: _dateLineData(),
          eventAnnotations: <FluentEventAnnotation>[
            FluentEventAnnotation(
              date: DateTime.utc(2024, 3, 15),
              event: 'Launch',
            ),
          ],
          eventAnnotationMergedLabel: (int n) => '$n events',
        ),
      );
      expect(
        find.byType(FluentEventAnnotationLayer),
        findsOneWidget,
        reason: 'LineChart.tsx:1958-1959 mounts the annotation layer',
      );
      expect(
        shellOf(tester).props.eventLabelHeight,
        36,
        reason: 'eventLabelHeight defaults to 36, LineChart.tsx:166',
      );
    });

    testWidgets('no annotations means no layer and a zero band', (
      tester,
    ) async {
      await pump(tester, FluentLineChart(data: _dateLineData()));
      expect(
        find.byType(FluentEventAnnotationLayer),
        findsNothing,
        reason: 'LineChart.tsx:1954 gates the layer on eventAnnotationProps',
      );
      expect(
        shellOf(tester).props.eventLabelHeight,
        0,
        reason: 'nothing to reserve when the band is not drawn',
      );
    });

    testWidgets('the legend row appends the colour-fill bars after the lines', (
      tester,
    ) async {
      await pump(
        tester,
        FluentLineChart(
          data: _lineData(),
          colorFillBars: const <FluentColorFillBar>[
            FluentColorFillBar(
              legend: 'Weekend',
              color: Color(0xFF00FF00),
              data: <FluentColorFillBarRange>[
                FluentColorFillBarRange(startX: 2, endX: 3),
              ],
            ),
          ],
        ),
      );
      final legends = shellOf(tester).legends;
      expect(
        legends.last.title,
        'Weekend',
        reason: 'LineChart.tsx:451 spreads colorFillBarsLegendDataItems last',
      );
      expect(
        legends.map((item) => item.title),
        <String>['alpha', 'beta', 'Weekend'],
        reason: 'the lines keep author order ahead of the bars',
      );
    });

    testWidgets('hovering a legend redraws the bands at the new opacity', (
      tester,
    ) async {
      // The dimming rule is resolved by colorFillBarRectsFor and pinned above,
      // but the loop that carries a hover into it runs through setState and a
      // rebuilt delegate. This drives the legend callbacks the shell was
      // handed and reads the alpha that reaches the canvas, so it fails if any
      // link of that chain is missing.
      await pump(
        tester,
        FluentLineChart(
          data: _lineData(),
          colorFillBars: const <FluentColorFillBar>[
            FluentColorFillBar(
              legend: 'Weekend',
              color: Color(0xFF00FF00),
              data: <FluentColorFillBarRange>[
                FluentColorFillBarRange(startX: 1, endX: 2),
              ],
            ),
            FluentColorFillBar(
              legend: 'Holiday',
              color: Color(0xFF00FF00),
              data: <FluentColorFillBarRange>[
                FluentColorFillBarRange(startX: 3, endX: 4),
              ],
            ),
          ],
        ),
      );
      Future<List<double>> alphasAfter(void Function() hover) async {
        hover();
        await tester.pump();
        final recorder = _LineRecorder();
        final plot = find
            .descendant(
              of: find.byType(FluentCartesianChart),
              matching: find.byType(CustomPaint),
            )
            .first;
        tester
            .widget<CustomPaint>(plot)
            .painter!
            .paint(recorder, tester.getSize(plot));
        // The rects come back in colorFillBars order (Weekend, then Holiday),
        // which is the order colorFillBarRectsFor walks them in.
        return recorder.rects
            .map((entry) => entry.colour.a)
            .toList(growable: false);
      }

      final legends = shellOf(tester).legends;
      expect(
        legends.map((item) => item.title),
        const <String>['alpha', 'beta', 'Weekend', 'Holiday'],
        reason:
            'the hovers below index into this row, so an order change must '
            'fail here rather than silently hover the wrong entry',
      );
      expect(
        await alphasAfter(legends[2].onHoverAction!),
        <Matcher>[closeTo(0.4, 1e-6), closeTo(0.1, 1e-6)],
        reason:
            'LineChart.tsx:1396-1398 keeps the highlighted bar at its own '
            'opacity (:1830) and drops every other one to 0.1',
      );
      expect(
        await alphasAfter(legends[0].onHoverAction!),
        <Matcher>[closeTo(0.1, 1e-6), closeTo(0.1, 1e-6)],
        reason:
            'hovering a line highlights no bar, so both fall to the 0.1 of '
            ':1398',
      );
      expect(
        await alphasAfter(
          () => legends[0].onMouseOutAction!(isLegendFocused: false),
        ),
        <Matcher>[closeTo(0.4, 1e-6), closeTo(0.4, 1e-6)],
        reason:
            '_noLegendHighlighted is true again once the hover clears '
            '(:1397), which restores both bars',
      );
    });

    testWidgets('the semantic title counts lines', (tester) async {
      await pump(
        tester,
        FluentLineChart(data: _lineData(chartTitle: 'Latency')),
      );
      expect(
        shellOf(tester).props.chartTitleForSemantics,
        'Latency. Line chart with 2 lines. ',
        reason: 'LineChart.tsx:1843-1846',
      );
    });

    testWidgets('the legend is single-select', (tester) async {
      await pump(tester, FluentLineChart(data: _lineData()));
      expect(
        shellOf(tester).legendSelectionMode,
        FluentChartLegendSelectionMode.single,
        reason: 'LineChart.tsx:186 tracks one selectedLegend, not a list',
      );
    });

    testWidgets(
      'Oracle B: the events story pins the band top and the bottom inset',
      (tester) async {
        final story = loadOracleStory('charts-linechart--line-chart-events');
        final rules = story
            .byTag('line')
            .where((element) => element.strokeDasharray == '8px')
            .toList();
        expect(
          rules,
          hasLength(3),
          reason: 'the capture holds three deduplicated event rules',
        );
        await pump(
          tester,
          FluentLineChart(
            data: _dateLineData(),
            // The story passes `eventAnnotationProps.labelHeight`, which
            // overrides the 36 at LineChart.tsx:180-181.
            style: FluentLineChartStyle.from(eventLabelHeight: 18),
            eventAnnotations: <FluentEventAnnotation>[
              FluentEventAnnotation(
                date: DateTime.utc(2024, 3, 15),
                event: 'Launch',
              ),
            ],
            eventAnnotationMergedLabel: (int n) => '$n events',
          ),
          size: Size(story.width, story.height),
        );
        final layer = tester.widget<FluentEventAnnotationLayer>(
          find.byType(FluentEventAnnotationLayer),
        );
        // EventAnnotation.tsx:19-20 — `textY = chartYTop - 20` and
        // `lineTopY = textY + 7`, so the captured rule starts 13px below the
        // chartYTop this widget computes.
        expectOracleNumber('chartYTop', rules.first.y1! + 13, layer.chartTop);
        // `chartYBottom = containerHeight - 35` (LineChart.tsx:1959) measured
        // against the capture rather than hard-coded.
        expectOracleNumber(
          'the bottom inset',
          story.height - rules.first.y2!,
          tester.getSize(find.byType(FluentEventAnnotationLayer)).height -
              layer.chartBottom,
        );
      },
    );
  });
}

/// One four-point line in `'lines+markers+text'` mode.
///
/// [texts] is per point; a null entry is a point with no `text`, which is what
/// the `&& text` conjunct of `LineChart.tsx:645` rejects.
FluentChartData _textModeLineData(List<String?> texts) => FluentChartData(
  lineChartData: <FluentLineChartSeries>[
    FluentLineChartSeries(
      legend: 'alpha',
      lineOptions: FluentLineOptions(mode: FluentLineMode.parse(_kTextMode)),
      data: <Object>[
        for (var i = 0; i < texts.length; i++)
          FluentLineChartDataPoint(x: i, y: i * 10.0, text: texts[i]),
      ],
    ),
  ],
);

/// A mode literal whose `includes('text')` is true — `supportsTextMode`
/// (`LineChart.tsx:571`, `:842`, `:1008`).
const String _kTextMode = 'lines+markers+text';

/// Two four-point lines sharing the x values 1..4.
FluentChartData _lineData({String? chartTitle}) => FluentChartData(
  chartTitle: chartTitle,
  lineChartData: <FluentLineChartSeries>[
    FluentLineChartSeries(
      legend: 'alpha',
      data: <Object>[
        for (var i = 1; i <= 4; i++)
          FluentLineChartDataPoint(x: i, y: i * 10.0),
      ],
    ),
    FluentLineChartSeries(
      legend: 'beta',
      data: <Object>[
        for (var i = 1; i <= 4; i++)
          FluentLineChartDataPoint(x: i, y: 45 - i * 5.0),
      ],
    ),
  ],
);

/// One line on a date axis spanning March 2024, the axis an event annotation
/// needs.
FluentChartData _dateLineData() => FluentChartData(
  lineChartData: <FluentLineChartSeries>[
    FluentLineChartSeries(
      legend: 'alpha',
      data: <Object>[
        for (var day = 10; day <= 20; day += 2)
          FluentLineChartDataPoint(x: DateTime.utc(2024, 3, day), y: day * 1.0),
      ],
    ),
  ],
);

FluentThemeData _theme() =>
    FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

/// A linear x and a linear y over `0..10`, mapped to `0..100`.
FluentCartesianChildContext _ctx() => FluentCartesianChildContext(
  xScale: d3.scaleLinear()
    ..domainOf(<double>[0, 10])
    ..rangeOf(<double>[0, 100]),
  yScalePrimary: d3.scaleLinear()
    ..domainOf(<double>[0, 10])
    ..rangeOf(<double>[100, 0]),
  containerWidth: 100,
  containerHeight: 100,
);

/// Both scales the identity, so a data value in pixels comes back unchanged.
///
/// That is what lets a captured segment endpoint be fed back in as data: the
/// scales are Oracle A's business, and this test is about the segment loop.
FluentCartesianChildContext _identityCtx() => FluentCartesianChildContext(
  xScale: d3.scaleLinear()
    ..domainOf(<double>[0, 1000])
    ..rangeOf(<double>[0, 1000]),
  yScalePrimary: d3.scaleLinear()
    ..domainOf(<double>[0, 1000])
    ..rangeOf(<double>[0, 1000]),
  containerWidth: 1000,
  containerHeight: 1000,
);

FluentCartesianLayout _layout() => FluentCartesianLayout.resolve(
  size: const Size(100, 100),
  margins: const FluentChartMargins(left: 0, right: 0, top: 0, bottom: 0),
  xAxisLabelReserve: 0,
  isRtl: false,
  startFromX: 0,
);

FluentLineChartDelegate _lineDelegate({
  List<double> ys = const <double>[1, 2, 3],
  List<FluentLineChartGap>? gaps,
  FluentLineCurve? curve,
  List<String> legends = const <String>['a'],
  String selectedLegend = '',
  FluentLineMode? mode,
  double? lineBorderWidth,
  Color? lineBorderColor,
  String? strokeDasharray,
  FluentThemeData? withTheme,
  bool allowMultipleShapesForPoints = false,
  bool optimizeLargeData = false,
  bool hideInactiveDots = false,
  String? activePointId,
  Color? markerColor,
  double? markerSize,
  List<String?>? texts,
}) => _delegate(
  <FluentLineChartSeries>[
    for (final legend in legends)
      FluentLineChartSeries(
        legend: legend,
        gaps: gaps,
        hideInactiveDots: hideInactiveDots,
        lineOptions: FluentLineOptions(
          curve: curve,
          mode: mode,
          lineBorderWidth: lineBorderWidth,
          lineBorderColor: lineBorderColor,
          strokeDasharray: strokeDasharray,
        ),
        data: <FluentLineChartDataPoint>[
          for (var i = 0; i < ys.length; i++)
            FluentLineChartDataPoint(
              x: i,
              y: ys[i],
              text: texts?[i],
              markerColor: markerColor,
              markerSize: markerSize,
            ),
        ],
      ),
  ],
  theme: withTheme ?? _theme(),
  selectedLegend: selectedLegend,
  allowMultipleShapesForPoints: allowMultipleShapesForPoints,
  optimizeLargeData: optimizeLargeData,
  activePointId: activePointId,
);

/// The y-domain ceiling of [_ctx]. The fill-bar rect is pinned to it, so the
/// two must agree or the padding assertions say nothing.
const double _yMax = 10;

FluentLineChartDelegate _lineDelegateWithFillBar({
  required num startX,
  required num endX,
  bool applyPattern = false,
  Color color = const Color(0xFF0078D4),
  String selectedLegend = '',
  FluentThemeData? withTheme,
}) => _delegate(
  <FluentLineChartSeries>[
    const FluentLineChartSeries(
      legend: 'a',
      data: <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 0, y: 1),
        FluentLineChartDataPoint(x: 1, y: 2),
      ],
    ),
  ],
  theme: withTheme ?? _theme(),
  selectedLegend: selectedLegend,
  colorFillBars: <FluentColorFillBar>[
    FluentColorFillBar(
      legend: 'band',
      color: color,
      applyPattern: applyPattern,
      data: <FluentColorFillBarRange>[
        FluentColorFillBarRange(startX: startX, endX: endX),
      ],
    ),
  ],
);

FluentLineChartDelegate _delegateFromPoints(
  List<Offset> points, {
  List<FluentLineChartGap>? gaps,
  double? strokeWidth,
  double? lineBorderWidth,
}) => _delegate(
  <FluentLineChartSeries>[
    FluentLineChartSeries(
      legend: 'captured',
      gaps: gaps,
      lineOptions: FluentLineOptions(
        strokeWidth: strokeWidth,
        lineBorderWidth: lineBorderWidth,
      ),
      data: <FluentLineChartDataPoint>[
        for (final point in points)
          FluentLineChartDataPoint(x: point.dx, y: point.dy),
      ],
    ),
  ],
  theme: _theme(),
  selectedLegend: '',
);

FluentLineChartDelegate _delegate(
  List<FluentLineChartSeries> series, {
  required FluentThemeData theme,
  required String selectedLegend,
  List<FluentColorFillBar> colorFillBars = const <FluentColorFillBar>[],
  bool allowMultipleShapesForPoints = false,
  bool optimizeLargeData = false,
  String? activePointId,
}) => FluentLineChartDelegate(
  series: series,
  style: resolveFluentLineChartStyle(theme),
  colors: FluentChartColors.of(theme),
  measurer: FluentChartTextMeasurer(),
  textStyles: FluentChartTextStyles.of(theme),
  selectedLegend: selectedLegend,
  colorFillBars: colorFillBars,
  allowMultipleShapesForPoints: allowMultipleShapesForPoints,
  optimizeLargeData: optimizeLargeData,
  activePointId: activePointId,
);

/// The captured `<line>` elements of one series group: the halo strokes first,
/// then the line strokes (`LineChart.tsx:1363-1364`).
class _CapturedSeries {
  const _CapturedSeries(this.borders, this.lines);

  final List<OracleElement> borders;
  final List<OracleElement> lines;
}

/// Groups a story's plot `<line>` elements by their parent `<g>`.
///
/// Axis ticks, grid lines and the hidden hover rule are all stroked at 1, which
/// is what separates them from a series stroked at its 4px default.
List<_CapturedSeries> _plotLineGroups(OracleStory story) {
  final byParent = <int, List<OracleElement>>{};
  for (final element in story.byTag('line')) {
    if (element.x1 == null || element.strokeWidth <= 1) {
      continue;
    }
    (byParent[element.parent] ??= <OracleElement>[]).add(element);
  }
  final out = <_CapturedSeries>[];
  for (final group in byParent.values) {
    final widest = group
        .map((element) => element.strokeWidth)
        .reduce((a, b) => a > b ? a : b);
    final borders = group
        .where((element) => element.strokeWidth == widest)
        .toList();
    final lines = group
        .where((element) => element.strokeWidth < widest)
        .toList();
    if (lines.isNotEmpty) {
      out.add(_CapturedSeries(borders, lines));
    }
  }
  return out;
}

/// The shape-0 `<path>` markers of a story, grouped by the series `<g>` they
/// were rendered into, in document order.
///
/// A shape-0 marker is `M A M A` — two 180° arcs — which is the only path in
/// the corpus with that command signature: the axis domains are `M V H V` and
/// `M H V H`, an engine B line is `M L…L`, and the stripe pattern is
/// `M l M l M l`. Selecting on the signature rather than on a class or an
/// index is what keeps a re-capture from silently matching the wrong element.
List<List<OracleElement>> _plotMarkerGroups(OracleStory story) {
  final byParent = <int, List<OracleElement>>{};
  for (final element in story.byTag('path')) {
    final d = element.d;
    if (d == null) {
      continue;
    }
    final commands = tokeniseSvgPath(
      d,
    ).where((token) => double.tryParse(token) == null).join();
    if (commands != 'MAMA') {
      continue;
    }
    (byParent[element.parent] ??= <OracleElement>[]).add(element);
  }
  return List<List<OracleElement>>.unmodifiable(byParent.values);
}

/// A single-series delegate whose points are exactly [markers]' centres.
///
/// The identity context of [_identityCtx] then maps each datum straight back
/// to the pixel the browser drew it at, so the scales — Oracle A's business —
/// are out of the way and what is left under test is the marker resolution
/// itself. The series colour and stroke width are read off the capture for the
/// same reason: they are what upstream fed the marker, so a port that reached
/// for the halo colour or the engine B stroke width fails here.
FluentLineChartDelegate _delegateFromCapturedMarkers(
  List<OracleElement> markers,
) {
  final centres = <Offset>[
    for (final marker in markers)
      () {
        final numbers = svgPathNumbers(marker.d!);
        return Offset((numbers[0] + numbers[7]) / 2, numbers[1]);
      }(),
  ];
  return _delegate(
    <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'captured',
        color: markers.first.fill,
        lineOptions: FluentLineOptions(strokeWidth: markers.first.strokeWidth),
        data: <FluentLineChartDataPoint>[
          for (final centre in centres)
            FluentLineChartDataPoint(x: centre.dx, y: centre.dy),
        ],
      ),
    ],
    theme: _theme(),
    // A captured marker below full opacity is one upstream dimmed because a
    // different legend was highlighted, which is the only way this corpus
    // exercises LineChart.tsx:909.
    selectedLegend: markers.first.opacity == 1 ? '' : 'another legend',
  );
}

/// Upstream's `allPointPaths[0]` template (`LineChart.tsx:84-88`), written
/// from the box a resolved mark actually paints.
///
/// The numbers come from `Path.getBounds()` of the mark under test, not from a
/// re-derivation of `_getPointPath`, so this compares the painted geometry
/// against the captured `d` rather than one transcription against another.
String _shapeZeroPath(Rect box) {
  final r = box.width / 2;
  final y = box.center.dy;
  return 'M${box.left} $y A$r $r 0 1 0 ${box.right} $y '
      'M${box.left} $y A $r $r 0 1 1 ${box.right} $y';
}

FluentLineChartDelegate _delegateFromCapturedChain(_CapturedSeries group) =>
    _delegateFromPoints(
      <Offset>[
        Offset(group.lines.first.x1!, group.lines.first.y1!),
        for (final line in group.lines) Offset(line.x2!, line.y2!),
      ],
      strokeWidth: group.lines.first.strokeWidth,
      lineBorderWidth:
          group.borders.first.strokeWidth - group.lines.first.strokeWidth,
    );

/// Records the stroke widths [Canvas.drawLine] was called with, in order,
/// and every [Canvas.drawPath] beside them.
///
/// `implements Canvas` plus `noSuchMethod`, the trick `slider_test.dart` uses:
/// the point is the paint order, not the pixels. Markers arrive through
/// `drawPath` and lines through `drawLine`, so the two lists never mix.
class _LineRecorder implements Canvas {
  final List<double> strokeWidths = <double>[];
  final List<(Offset, Offset)> drawn = <(Offset, Offset)>[];
  final List<(Rect, PaintingStyle)> paths = <(Rect, PaintingStyle)>[];

  /// The width, colour and contour metrics behind each entry of [paths].
  ///
  /// Kept beside [paths] rather than folded into it because two tests
  /// destructure that record positionally. Length and contour count come from
  /// [Path.computeMetrics] because an engine-B stroke is judged by how far it
  /// travels and where it lifts, neither of which its bounding box can say.
  final List<({double strokeWidth, Color colour, double length, int contours})>
  pathPaints =
      <({double strokeWidth, Color colour, double length, int contours})>[];

  /// The origin every [Canvas.drawParagraph] was handed, in order.
  ///
  /// A point's `text` label (`LineChart.tsx:646-659`) is the only paragraph
  /// [FluentLineChartDelegate.paintSeries] emits, so a recorder driven by
  /// `paintSeries` alone sees labels and nothing else; one driven by the
  /// mounted plot painter also sees the axis tick labels.
  final List<Offset> paragraphs = <Offset>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphs.add(offset);

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    strokeWidths.add(paint.strokeWidth);
    drawn.add((p1, p2));
  }

  /// Every [Canvas.drawRect], with how much had already been drawn when it
  /// arrived.
  ///
  /// `pathsBefore` and `linesBefore` are what make a z-order assertion
  /// readable: a colour fill bar sits ahead of `{lines}` in the same `<g>`
  /// (`LineChart.tsx:1950-1953`), so both counts must be 0 when its rect is
  /// drawn.
  final List<({Rect rect, Color colour, int pathsBefore, int linesBefore})>
  rects = <({Rect rect, Color colour, int pathsBefore, int linesBefore})>[];

  @override
  void drawRect(Rect rect, Paint paint) => rects.add((
    rect: rect,
    colour: paint.color,
    pathsBefore: paths.length,
    linesBefore: drawn.length,
  ));

  @override
  void drawPath(Path path, Paint paint) {
    paths.add((path.getBounds(), paint.style));
    final metrics = path.computeMetrics().toList();
    pathPaints.add((
      strokeWidth: paint.strokeWidth,
      colour: paint.color,
      length: metrics.fold(0, (sum, metric) => sum + metric.length),
      contours: metrics.length,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
