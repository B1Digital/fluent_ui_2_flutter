// Hover geometry of charts-linechart--line-chart-basic against the live
// @fluentui/react-charts render.
//
// The numbers are what Chrome reported after a real mouse hovered each target
// (hover-chart-visual-1 `up/charts-linechart--line-chart-basic__<target>.json`:
// the active marker's `d`, the verticalLine's transform and y2, and the
// callout surface's rect), all relative to the 700x300 chart root. The chart
// is mounted the way the parity suite mounts it, with its fonts, so the plot
// geometry is the storybook's.
import 'dart:ui' as ui;

import 'package:fluent_2/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_painter.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2/src/charts/internal/chart_colors.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/line_chart.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../parity/support/react_parity.dart' show loadParityFonts;

/// One upstream hover: where the pointer went, which point that activated,
/// where Chrome drew that point's marker, and where the callout surface landed.
typedef _Target = ({
  String name,
  Offset pointer,
  String activePointId,
  Offset marker,
  double surfaceTop,
  double? surfaceLeft,
});

const List<_Target> _targets = <_Target>[
  (
    name: 'pt_legacy_0306',
    pointer: Offset(372, 38.27),
    activePointId: '0_5',
    marker: Offset(372, 38.26859776168532),
    surfaceTop: 64,
    surfaceLeft: null,
  ),
  (
    name: 'pt_all_0307',
    pointer: Offset(474.67, 68.72),
    activePointId: '1_4',
    marker: Offset(474.66666666666663, 68.71626069782752),
    surfaceTop: 94,
    surfaceLeft: null,
  ),
  // Between the 03-04 and 03-05 points of 'All': the segment hovers its start.
  (
    name: 'between_all_0304_0305',
    pointer: Offset(218, 32.79),
    activePointId: '1_1',
    marker: Offset(166.66666666666666, 32.17906517445689),
    surfaceTop: 58,
    surfaceLeft: null,
  ),
  // The last point: the surface is shifted in against the root's right edge.
  (
    name: 'pt_all_last_0309',
    pointer: Offset(680, 23.65),
    activePointId: '1_6',
    marker: Offset(680, 23.65371955233707),
    surfaceTop: 49,
    surfaceLeft: 508,
  ),
  (
    name: 'single_point',
    pointer: Offset(320.67, 63.84),
    activePointId: '2_0',
    marker: Offset(320.6666666666667, 63.844634628044766),
    surfaceTop: 89,
    surfaceLeft: null,
  ),
];

/// Where every verticalLine ended: `translate(x, y)` plus `y2`, which is
/// `lineHeight - 5 - y` with `lineHeight = containerHeight - margins.bottom +
/// 6` (`LineChart.tsx:542`, `:1674`) — 206 for all five.
const double _ruleEnd = 206;

void main() {
  setUpAll(loadParityFonts);

  for (final target in _targets) {
    testWidgets('hovering ${target.name} matches the storybook', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 700, height: 300, child: _lineChartBasic()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: const Offset(790, 390));
      addTearDown(gesture.removePointer);
      // A pixel short first, then onto the target, as a hand arrives.
      await gesture.moveTo(target.pointer - const Offset(1, 0));
      await tester.pump();
      await gesture.moveTo(target.pointer);
      await tester.pumpAndSettle();

      final painter =
          tester
                  .widget<CustomPaint>(
                    find
                        .descendant(
                          of: find.byType(FluentCartesianChart),
                          matching: find.byType(CustomPaint),
                        )
                        .first,
                  )
                  .painter!
              as FluentCartesianChartPainter;
      final delegate = painter.delegate as FluentLineChartDelegate;
      expect(delegate.activePointId, target.activePointId);

      final context = FluentCartesianChildContext(
        xScale: painter.xAxis.scale,
        yScalePrimary: painter.yAxisPrimary.scale,
        containerWidth: painter.layout.size.width,
        containerHeight: painter.layout.size.height,
      );
      final active = delegate
          .markersFor(context)
          .firstWhere(
            (mark) =>
                '${mark.seriesIndex}_${mark.pointIndex}' ==
                target.activePointId,
          );
      expect(
        active.path.getBounds(),
        rectMoreOrLessEquals(
          Rect.fromCircle(center: target.marker, radius: 5.5),
          epsilon: 0.05,
        ),
        reason: 'Chrome grew the marker to A5.5 about the same centre',
      );
      expect(active.strokeWidth, 4);

      final recorder = _PathRecorder();
      delegate.paintSeries(
        recorder,
        context,
        painter.layout,
        FluentChartColors.of(theme),
      );
      final rule = recorder.paths.first;
      expect(rule.colour.toARGB32(), 0xFF323130);
      expect(rule.strokeWidth, 1);
      // '5,5' from the point, so the last dash stops short of the end when the
      // length leaves a partial gap.
      final length = _ruleEnd - target.marker.dy;
      final lastDashEnd = (length ~/ 10) * 10 + 5.0;
      expect(
        rule.bounds,
        rectMoreOrLessEquals(
          Rect.fromLTRB(
            target.marker.dx,
            target.marker.dy,
            target.marker.dx,
            target.marker.dy + (lastDashEnd < length ? lastDashEnd : length),
          ),
          epsilon: 0.05,
        ),
      );

      final surface = tester.getRect(
        find.descendant(
          of: find.byType(FluentChartPopover),
          matching: find.byType(ExcludeFocus),
        ),
      );
      expect(
        surface.top,
        target.surfaceTop,
        reason:
            'flipped below the 11px active marker, 20px clear of it '
            '(ChartPopover.tsx:48)',
      );
      if (target.surfaceLeft == null) {
        // Selawik and Segoe UI measure the readings a little differently, so
        // the width is not compared; the centring is.
        expect(surface.center.dx, closeTo(target.marker.dx, 0.6));
      } else {
        expect(surface.right, closeTo(700, 0.6));
      }
    });
  }
}

/// `const data: ChartProps` in charts-linechart--line-chart-basic.tsx, as the
/// parity suite transcribes it.
FluentLineChart _lineChartBasic() => FluentLineChart(
  data: FluentChartData(
    chartTitle: 'Line Chart Basic Example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        data: <Object>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3, 0), y: 216000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3, 10), y: 218123),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3, 11), y: 217124),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 248000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 252000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 274000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 260000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 304000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 218000),
        ],
      ),
      FluentLineChartSeries(
        legend: 'All',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        data: <Object>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 297000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 284000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 282000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 294000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 224000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 300000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 298000),
        ],
      ),
      FluentLineChartSeries(
        legend: 'single point',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
        data: <Object>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5, 12), y: 232000),
        ],
      ),
    ],
  ),
  props: const FluentCartesianChartProps(
    yMinValue: 200,
    yMaxValue: 301,
    xAxisTickCount: 10,
    useUTC: true,
    xAxisTitle: 'Values of each category',
    yAxisTitle:
        'Different categories of mail flow each of which are '
        'categorized into different categories',
  ),
  culture: 'en-US',
);

/// Records every [Canvas.drawPath] with the stroke it was drawn with, in
/// order. The hover rule is the first thing the series paint draws.
class _PathRecorder implements Canvas {
  final List<({Rect bounds, Color colour, double strokeWidth})> paths =
      <({Rect bounds, Color colour, double strokeWidth})>[];

  @override
  void drawPath(Path path, Paint paint) => paths.add((
    bounds: path.getBounds(),
    colour: paint.color,
    strokeWidth: paint.strokeWidth,
  ));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
