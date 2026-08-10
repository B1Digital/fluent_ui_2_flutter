import 'dart:math';
import 'dart:ui';

import 'package:fluent_2_core/fluent_2_core.dart';
// The barrel is owned by the integration task, so these files are imported
// directly until `line_chart.dart` is exported from it.
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/line_chart.dart';
import 'package:fluent_2_web/src/charts/line_chart_style.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
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
}

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
  String? strokeDasharray,
  FluentThemeData? withTheme,
}) => _delegate(
  <FluentLineChartSeries>[
    for (final legend in legends)
      FluentLineChartSeries(
        legend: legend,
        gaps: gaps,
        lineOptions: FluentLineOptions(
          curve: curve,
          mode: mode,
          lineBorderWidth: lineBorderWidth,
          strokeDasharray: strokeDasharray,
        ),
        data: <FluentLineChartDataPoint>[
          for (var i = 0; i < ys.length; i++)
            FluentLineChartDataPoint(x: i, y: ys[i]),
        ],
      ),
  ],
  theme: withTheme ?? _theme(),
  selectedLegend: selectedLegend,
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
}) => FluentLineChartDelegate(
  series: series,
  style: resolveFluentLineChartStyle(theme),
  colors: FluentChartColors.of(theme),
  measurer: FluentChartTextMeasurer(),
  textStyles: FluentChartTextStyles.of(theme),
  selectedLegend: selectedLegend,
  colorFillBars: colorFillBars,
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

/// Records the stroke widths [Canvas.drawLine] was called with, in order.
///
/// `implements Canvas` plus `noSuchMethod`, the trick `slider_test.dart` uses:
/// the point is the paint order, not the pixels.
class _LineRecorder implements Canvas {
  final List<double> strokeWidths = <double>[];
  final List<(Offset, Offset)> drawn = <(Offset, Offset)>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    strokeWidths.add(paint.strokeWidth);
    drawn.add((p1, p2));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
