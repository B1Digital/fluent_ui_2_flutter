import 'dart:ui' as ui;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_time.dart' as d3;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// Records the fills and shapes `paintSeries` emits. `noSuchMethod` swallows
/// everything else, so a painter that starts clipping or saving layers is not
/// silently accepted — those calls simply do not land in these lists, and the
/// assertions below are on what did.
class _RecordingCanvas implements Canvas {
  final List<Rect> rects = <Rect>[];
  final List<RRect> rrects = <RRect>[];
  final List<Color> fills = <Color>[];
  final List<ui.Shader?> shaders = <ui.Shader?>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add(rect);
    fills.add(paint.color);
    shaders.add(paint.shader);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    rrects.add(rrect);
    rects.add(rrect.outerRect);
    fills.add(paint.color);
    shaders.add(paint.shader);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The Gantt delegate is exercised three ways: by hand-derived arithmetic, for
/// the clamps whose inputs no capture exposes; against Oracle B's two captured
/// GanttChart stories, which pin the band centring, the draw order and every
/// bar rect to geometry upstream actually rendered; and through a recording
/// canvas, because the high-contrast flattening is a paint property no rect
/// geometry proves.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final style = resolveFluentGanttChartStyle(theme);
  final measurer = FluentChartTextMeasurer();

  const placeholder = Color(0xFF010203);
  const canvasText = Color(0xFFFFFFFF);
  FluentChartColors colours({bool isHighContrast = false}) => FluentChartColors(
    axisText: canvasText,
    axisTick: placeholder,
    axisTitle: placeholder,
    gridLine: placeholder,
    markStroke: placeholder,
    surface: placeholder,
    popoverSurface: placeholder,
    tooltipSurface: placeholder,
    legendDimmed: placeholder,
    isHighContrast: isHighContrast,
  );

  FluentGanttChartDelegate delegate({
    required List<FluentGanttChartDataPoint> points,
    double? barHeight,
    List<String> selectedLegends = const <String>[],
    String? hoveredLegend,
    bool isHighContrast = false,
    bool enableGradient = false,
    bool roundCorners = false,
    FluentAxisCategoryOrder yAxisCategoryOrder =
        FluentAxisCategoryOrder.defaultOrder,
  }) => FluentGanttChartDelegate(
    points: points,
    style: style,
    colors: colours(isHighContrast: isHighContrast),
    measurer: measurer,
    selectedLegends: selectedLegends,
    hoveredLegend: hoveredLegend,
    barHeightProp: barHeight,
    enableGradient: enableGradient,
    roundCorners: roundCorners,
    yAxisCategoryOrder: yAxisCategoryOrder,
  );

  /// One point per entry of [yValues], each spanning `[10i, 10i + 5]` unless
  /// [spans] overrides it.
  FluentGanttChartDelegate ganttDelegate({
    required List<Object> yValues,
    List<FluentGanttSpan>? spans,
    double? barHeight,
  }) => delegate(
    points: <FluentGanttChartDataPoint>[
      for (var i = 0; i < yValues.length; i++)
        FluentGanttChartDataPoint(
          x: spans == null
              ? FluentGanttSpan(start: i * 10, end: i * 10 + 5)
              : spans[i],
          y: yValues[i],
          legend: 'Legend $i',
        ),
    ],
    barHeight: barHeight,
  );

  FluentCartesianChildContext context({
    required d3.Scale xScale,
    required d3.Scale yScale,
    double containerWidth = 600,
    double containerHeight = 400,
  }) => FluentCartesianChildContext(
    xScale: xScale,
    yScalePrimary: yScale,
    containerWidth: containerWidth,
    containerHeight: containerHeight,
  );

  /// A band y scale over [labels], ranged the way
  /// `createStringYAxisForHorizontalBarChartWithAxis` ranges one
  /// (`utilities.ts:923-925`): bottom first, so `domain[0]` sits at the foot of
  /// the plot.
  d3.Scale bandScale(
    List<String> labels, {
    required double bottom,
    required double top,
    double padding = 0.5,
  }) => d3.scaleBand()
    ..domainOf(labels.cast<Object>())
    ..rangeOf(<double>[bottom, top])
    ..padding(padding);

  d3.Scale linearScale({
    List<double> domain = const <double>[0, 100],
    List<double> range = const <double>[0, 500],
  }) => d3.scaleLinear()
    ..domainOf(domain)
    ..rangeOf(range);

  FluentCartesianChildContext ganttContext() => context(
    xScale: linearScale(),
    yScale: bandScale(<String>['a'], bottom: 400, top: 0),
  );

  FluentCartesianLayout layout({double height = 400, double width = 600}) =>
      FluentCartesianLayout.resolve(
        size: Size(width, height),
        margins: const FluentChartMargins(
          left: 40,
          right: 20,
          top: 28,
          bottom: 43,
        ),
        xAxisLabelReserve: 0,
        isRtl: false,
        startFromX: 0,
      );

  FluentGanttChartDelegate ganttOrderedDelegate() => delegate(
    points: <FluentGanttChartDataPoint>[
      // Two rows, four bars. The rows are authored 10 first, so the *numeric*
      // label order is ascending — 10, 20 — and the last-to-first walk over it
      // has to emit row 20's bars before row 10's.
      const FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: 30, end: 35),
        y: 10,
        legend: 'A',
      ),
      const FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: 40, end: 45),
        y: 10,
        legend: 'A',
      ),
      const FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: 5, end: 15),
        y: 20,
        legend: 'B',
      ),
      const FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: 15, end: 25),
        y: 20,
        legend: 'B',
      ),
    ],
  );

  FluentGanttChartDelegate ganttDateDelegate({
    required DateTime start,
    required DateTime end,
  }) => delegate(
    points: <FluentGanttChartDataPoint>[
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: start, end: end),
        y: 'Job',
        legend: 'Legend',
      ),
    ],
  );

  group('FluentGanttChartDelegate bar height', () {
    test('a string y axis clamps the bandwidth to 24', () {
      final d = ganttDelegate(yValues: <Object>['a', 'b', 'c', 'd']);
      // range [365, 20], padding 0.5, n=4:
      // step = 345 / (4 - 0.5 + 2*0.5) = 345 / 4.5 ; bandwidth = 0.5 * step
      expect(
        d.barHeightFor(345 / 4.5 * 0.5),
        24,
        reason:
            'maxBarHeight 24 wins over the 38.3px bandwidth, '
            'GanttChart.tsx:333-348',
      );
    });

    test('the auto numeric bar height is clamped and feeds the margin', () {
      final d = ganttDelegate(yValues: <Object>[0, 10, 20, 30]);
      // totalHeight = 400 - (20 + 8) - (35 + 8) = 329
      // closestPairDiff 10, range 30, innerPadding 0.5
      // floor(329 * 10 * 0.5 / (30 + 10 * 0.5)) = floor(1645 / 35) = 47
      expect(
        d.barHeightFor(47),
        24,
        reason: 'GanttChart.tsx:336-340 clamps to maxBarHeight 24',
      );
      expect(
        d.yDomainMargins(400)!.top,
        closeTo(20 + 8 + 12, 1e-9),
        reason:
            'domainMargin = 8 + barHeight/2 = 8 + 12, GanttChart.tsx:525-555',
      );
    });

    test('an explicit barHeight overrides the auto value before clamping', () {
      final d = ganttDelegate(yValues: <Object>['a'], barHeight: 100);
      expect(
        d.barHeightFor(8),
        24,
        reason: 'the explicit 100 is still clamped by maxBarHeight 24, :338',
      );
    });

    test('the 1px floor survives a zero bandwidth', () {
      final d = ganttDelegate(yValues: <Object>['a']);
      expect(
        d.barHeightFor(0),
        1,
        reason: 'MIN_BAR_HEIGHT is 1 and is applied last, GanttChart.tsx:344',
      );
    });

    test('a category y axis leaves the domain margin at 8', () {
      final d = ganttDelegate(yValues: <Object>['a', 'b']);
      final margins = d.yDomainMargins(400)!;
      expect(
        <double?>[margins.top, margins.bottom],
        <double>[28, 43],
        reason:
            'GanttChart.tsx:541 skips the bar-height half only for a string '
            'axis, so both ends keep MIN_DOMAIN_MARGIN alone.',
      );
    });
  });

  group('FluentGanttChartDelegate bars', () {
    test('a zero-length span still paints two pixels', () {
      final d = ganttDelegate(
        yValues: <Object>['a'],
        spans: <FluentGanttSpan>[const FluentGanttSpan(start: 5, end: 5)],
      );
      expect(
        d.barsFor(ganttContext(), layout()).single.rect.width,
        2,
        reason: 'Math.max(|end - start|, 2) at GanttChart.tsx:415',
      );
    });

    test('bars are ordered bottom label first, start ascending within', () {
      final d = ganttOrderedDelegate();
      expect(
        d
            .barsFor(
              context(
                xScale: linearScale(),
                yScale: linearScale(
                  domain: <double>[0, 30],
                  range: <double>[400, 0],
                ),
              ),
              layout(),
            )
            .map((FluentGanttBar b) => b.index)
            .toList(),
        <int>[2, 3, 0, 1],
        reason:
            'GanttChart.tsx:350-369 walks _yAxisLabels last-to-first and '
            'sorts by x.start ascending inside each label',
      );
    });

    test('bars that start together keep their author order', () {
      // 40 is above dart:core's insertion-sort threshold of 32, below which
      // `List.sort` happens to be stable; only a genuinely stable sort keeps
      // this many ties in order, and JavaScript's Array.prototype.sort — the
      // one at GanttChart.tsx:364 — has been stable since ES2019.
      const tied = 40;
      final d = delegate(
        points: <FluentGanttChartDataPoint>[
          for (var i = 0; i < tied; i++)
            const FluentGanttChartDataPoint(
              x: FluentGanttSpan(start: 5, end: 15),
              y: 'a',
            ),
        ],
      );
      expect(
        d
            .barsFor(ganttContext(), layout())
            .map((FluentGanttBar b) => b.index)
            .toList(),
        List<int>.generate(tied, (int i) => i),
        reason: 'a tie at GanttChart.tsx:364 never reorders the two bars',
      );
    });

    test('the default string order is the insertion order reversed', () {
      expect(
        ganttDelegate(yValues: <Object>['a', 'b', 'c']).orderedYAxisLabels,
        <String>['c', 'b', 'a'],
        reason: 'GanttChart.tsx:154 reverses Object.keys for the default order',
      );
    });

    test('a numeric y axis sorts ascending numerically', () {
      expect(
        ganttDelegate(yValues: <Object>[30, 10, 20]).orderedYAxisLabels,
        <String>['10', '20', '30'],
        reason: 'GanttChart.tsx:151 sorts +a - +b for a non-string axis',
      );
    });

    test(
      'a dimmed bar keeps its geometry and loses nine tenths of its ink',
      () {
        final d = delegate(
          points: <FluentGanttChartDataPoint>[
            const FluentGanttChartDataPoint(
              x: FluentGanttSpan(start: 0, end: 10),
              y: 'a',
              legend: 'kept',
            ),
            const FluentGanttChartDataPoint(
              x: FluentGanttSpan(start: 20, end: 30),
              y: 'a',
              legend: 'dropped',
            ),
          ],
          selectedLegends: const <String>['kept'],
        );
        expect(
          d
              .barsFor(ganttContext(), layout())
              .map((FluentGanttBar b) => b.opacity)
              .toList(),
          <double>[1, 0.1],
          reason:
              'GanttChart.tsx:421 is `opacity={shouldHighlight ? 1 : 0.1}` and '
              ':410 highlights on the multi-select model.',
        );
      },
    );

    test('an unhighlighted bar is not focusable and shows no callout', () {
      final d = delegate(
        points: <FluentGanttChartDataPoint>[
          const FluentGanttChartDataPoint(
            x: FluentGanttSpan(start: 0, end: 10),
            y: 'a',
            legend: 'kept',
          ),
          const FluentGanttChartDataPoint(
            x: FluentGanttSpan(start: 20, end: 30),
            y: 'a',
            legend: 'dropped',
          ),
        ],
        selectedLegends: const <String>['kept'],
      );
      final regions = d.buildHitRegions(ganttContext(), layout());
      expect(
        regions.map((FluentChartHitRegion r) => r.legend).toList(),
        <String>['kept'],
        reason:
            'GanttChart.tsx:427 gives an unhighlighted rect tabIndex -1 and '
            ':285 refuses to open its callout.',
      );
    });

    test('a Gantt popover never carries a custom body', () {
      final d = ganttDelegate(yValues: <Object>['a']);
      final regions = d.buildHitRegions(ganttContext(), layout());
      expect(
        regions,
        isNotEmpty,
        reason: 'a vacuous every() over an empty list would prove nothing',
      );
      expect(
        regions.every(
          (FluentChartHitRegion r) =>
              r.popoverData.customContentBuilder == null,
        ),
        isTrue,
        reason:
            'parity: GanttChart.tsx:604 hands customizedCallout to '
            'CartesianChart as a top-level prop, but CartesianChart.tsx:444-445 '
            'renders only calloutProps, so onRenderCalloutPerDataPoint never '
            'reaches ChartPopover.tsx:54 and the custom callout never appears.',
      );
    });

    test('the popover reads the row on top and the span underneath', () {
      final d = ganttDateDelegate(
        start: DateTime.utc(2024, 3, 15),
        end: DateTime.utc(2024, 3, 22),
      );
      final data = d
          .buildHitRegions(
            context(
              xScale: d3.scaleUtc()
                ..domainOfDates(<DateTime>[
                  DateTime.utc(2024, 3, 15),
                  DateTime.utc(2024, 3, 22),
                ])
                ..rangeOf(<double>[0, 500]),
              yScale: bandScale(<String>['Job'], bottom: 400, top: 0),
            ),
            layout(),
          )
          .single
          .popoverData;
      expect(
        <String?>[data.xValue, data.yValue],
        <String>['Job', d.formattedSpan(d.points.single)],
        reason:
            'GanttChart.tsx:298-299 sets XValue from the y value and YValue '
            'from the formatted span.',
      );
    });
  });

  group('FluentGanttChartDelegate date formatting', () {
    test('the format level spans both ends of every point', () {
      final d = ganttDateDelegate(
        start: DateTime.utc(2024, 3, 15),
        end: DateTime.utc(2024, 3, 22),
      );
      expect(
        d.formattedSpan(d.points.single),
        'Fri 15 - Fri 22',
        reason:
            'getDateFormatLevel gives 4 (day) for both ends, and the (4, 4) '
            'cell of the matrix at chart-utilities formatter.ts:274 is D — '
            "{weekday: 'short', day: '2-digit'} at :219-222 — not a numeric "
            'date.',
      );
    });

    test('a minute-level start widens the matrix lookup', () {
      final d = ganttDateDelegate(
        start: DateTime.utc(2024, 3, 15, 10, 30),
        end: DateTime.utc(2024, 6, 1),
      );
      expect(
        d.dateFormatLevels,
        (2, 6),
        reason:
            'getDateFormatLevel is 2 for a minute boundary and 6 for a '
            'month boundary, utilities.ts:410-438',
      );
      expect(
        d.formattedSpan(d.points.single),
        'Mar 15, 10:30 AM - Jun 01, 12:00 AM',
        reason:
            'the (2, 6) cell of the matrix at formatter.ts:272 is MIN_H_D_W_M, '
            'aliased to MIN_H_D_W at :186 — a short month, a two-digit day and '
            'a twelve-hour time, with no year, at :176-184.',
      );
    });

    test('a numeric span is stringified, not formatted', () {
      final d = ganttDelegate(yValues: <Object>['a']);
      expect(
        d.formattedSpan(d.points.single),
        '0 - 5',
        reason:
            'GanttChart.tsx:216-219 takes the toString branch off a '
            'non-date x axis.',
      );
    });
  });

  group('FluentGanttChartDelegate axes', () {
    test('the x domain is the raw extent, with no padding and no nice', () {
      final d = ganttDelegate(
        yValues: <Object>['a', 'b'],
        spans: <FluentGanttSpan>[
          const FluentGanttSpan(start: 3, end: 17),
          const FluentGanttSpan(start: 11, end: 42),
        ],
      );
      final range = d.resolveXDomainRange(
        margins: const FluentChartMargins(left: 40, right: 20),
        containerWidth: 600,
        isRtl: false,
        barWidth: null,
        tickValues: null,
      );
      expect(
        <Object>[
          range.dStartValue,
          range.dEndValue,
          range.rStartValue,
          range.rEndValue,
        ],
        <Object>[3, 42, 40.0, 580.0],
        reason: 'GanttChart.tsx:174-187 min/maxes every start and end.',
      );
    });

    test('an epoch-zero date is not swallowed by the falsy guard', () {
      final start = DateTime.utc(1970);
      final d = ganttDateDelegate(start: start, end: DateTime.utc(1971));
      expect(
        d
            .resolveXDomainRange(
              margins: const FluentChartMargins(left: 0, right: 0),
              containerWidth: 600,
              isRtl: false,
              barWidth: null,
              tickValues: null,
            )
            .dStartValue,
        start,
        reason:
            '`d3Min(...) || 0` at GanttChart.tsx:179 only swallows a falsy '
            'value, and a Date object is always truthy however small its '
            'epoch.',
      );
    });

    test('a numeric zero IS swallowed by the falsy guard', () {
      final d = ganttDelegate(
        yValues: <Object>['a'],
        spans: <FluentGanttSpan>[const FluentGanttSpan(start: 0, end: 9)],
      );
      expect(
        d
            .resolveXDomainRange(
              margins: const FluentChartMargins(left: 0, right: 0),
              containerWidth: 600,
              isRtl: false,
              barWidth: null,
              tickValues: null,
            )
            .dStartValue,
        0,
        reason:
            'parity: `|| 0` at GanttChart.tsx:179 replaces a numeric 0 with '
            'the same 0, which is only harmless because the two agree.',
      );
    });

    test('rtl swaps the two ends of the domain', () {
      final d = ganttDelegate(
        yValues: <Object>['a', 'b'],
        spans: <FluentGanttSpan>[
          const FluentGanttSpan(start: 3, end: 17),
          const FluentGanttSpan(start: 11, end: 42),
        ],
      );
      final range = d.resolveXDomainRange(
        margins: const FluentChartMargins(left: 40, right: 20),
        containerWidth: 600,
        isRtl: true,
        barWidth: null,
        tickValues: null,
      );
      expect(
        <Object>[range.dStartValue, range.dEndValue],
        <Object>[42, 3],
        reason: 'GanttChart.tsx:183-184 swaps on isRTL.',
      );
    });

    test('an empty chart still declares a date x axis', () {
      final d = delegate(points: const <FluentGanttChartDataPoint>[]);
      expect(
        <Object>[d.xAxisType, d.yAxisType],
        <Object>[FluentChartAxisType.date, FluentChartAxisType.category],
        reason: 'GanttChart.tsx:102-114 falls back to a date x and string y.',
      );
    });

    test('a numeric y axis reports the raw y extent', () {
      final d = ganttDelegate(yValues: <Object>[0, 10, 20, 30]);
      final minMax = d.resolveYMinMax();
      expect(
        <double>[minMax.startValue, minMax.endValue],
        <double>[0, 30],
        reason:
            'findHBCWANumericMinMaxOfY (utilities.ts:1661-1678) is wired at '
            'GanttChart.tsx:603.',
      );
    });

    test('a category y axis reports a zero extent', () {
      final d = ganttDelegate(yValues: <Object>['a', 'b']);
      final minMax = d.resolveYMinMax();
      expect(
        <double>[minMax.startValue, minMax.endValue],
        <double>[0, 0],
        reason:
            'utilities.ts:1677 returns { startValue: 0, endValue: 0 } for a '
            'non-numeric y axis.',
      );
    });

    test('the band domain is the ordered label list', () {
      final d = ganttDelegate(yValues: <Object>['a', 'b', 'c']);
      expect(
        d.stringDatasetForYAxisDomain,
        <String>['c', 'b', 'a'],
        reason:
            'GanttChart.tsx:596 hands _yAxisLabels to the shell as '
            'stringDatasetForYAxisDomain.',
      );
    });
  });

  group('FluentGanttChartDelegate painting', () {
    FluentGanttChartDelegate paintDelegate({
      bool isHighContrast = false,
      bool enableGradient = false,
      bool roundCorners = false,
    }) => delegate(
      points: <FluentGanttChartDataPoint>[
        const FluentGanttChartDataPoint(
          x: FluentGanttSpan(start: 0, end: 40),
          y: 'a',
          legend: 'A',
          color: Color(0xFF637CEF),
          gradient: (Color(0xFF637CEF), Color(0xFFE3008C)),
        ),
      ],
      isHighContrast: isHighContrast,
      enableGradient: enableGradient,
      roundCorners: roundCorners,
    );

    _RecordingCanvas paint(FluentGanttChartDelegate d) {
      final canvas = _RecordingCanvas();
      d.paintSeries(canvas, ganttContext(), layout(), d.colors);
      return canvas;
    }

    test('an ordinary theme keeps the series colour', () {
      expect(
        // Paint stores its colour as four float32s, so the round trip is
        // compared as a packed ARGB word rather than component by component.
        paint(paintDelegate()).fills.single.toARGB32(),
        const Color(0xFF637CEF).toARGB32(),
        reason: 'flattenMark is the identity outside high contrast.',
      );
    });

    test('high contrast flattens the bar to the system colour', () {
      expect(
        paint(paintDelegate(isHighContrast: true)).fills.single.toARGB32(),
        canvasText.toARGB32(),
        reason:
            'design spec section 5.3: a forced-colours browser paints every '
            'rect in CanvasText, so FluentChartColors.flattenMark must be on '
            "the Gantt bar's fill.",
      );
    });

    test('high contrast flattens both gradient stops', () {
      final bar = paintDelegate(
        isHighContrast: true,
        enableGradient: true,
      ).barsFor(ganttContext(), layout()).single;
      expect(
        <Color>[bar.startColour, bar.endColour],
        <Color>[canvasText, canvasText],
        reason:
            'GanttChart.tsx:388-392 builds the gradient from the two legend '
            'colours; both are series ink and both flatten.',
      );
    });

    test('a gradient bar paints through a shader', () {
      expect(
        paint(paintDelegate(enableGradient: true)).shaders.single,
        isNotNull,
        reason:
            'GanttChart.tsx:420 fills with url(#gradient) whenever '
            'enableGradient is set.',
      );
    });

    test('rounded corners use the 3px radius', () {
      final canvas = paint(paintDelegate(roundCorners: true));
      expect(
        canvas.rrects.single.trRadiusX,
        3,
        reason: 'GanttChart.tsx:419 is `rx={props.roundCorners ? 3 : 0}`.',
      );
    });

    test('square corners draw a plain rect', () {
      expect(
        paint(paintDelegate()).rrects,
        isEmpty,
        reason: 'rx is 0 without roundCorners, GanttChart.tsx:419.',
      );
    });
  });

  group('FluentGanttChartStyle', () {
    test('the literals match the upstream constants', () {
      const states = <WidgetState>{};
      expect(
        <double?>[
          style.maxBarHeight!.resolve(states),
          style.minBarHeight!.resolve(states),
          style.minBarWidth!.resolve(states),
          style.barCornerRadius!.resolve(states),
          style.yAxisPadding!.resolve(states),
          style.barOpacity!.resolve(states),
          style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        ],
        <double>[24, 1, 2, 3, 0.5, 1, 0.1],
        reason:
            'GanttChart.tsx:41 DEFAULT_BAR_HEIGHT/maxBarHeight 24, :42 '
            'MIN_BAR_HEIGHT 1, :417 the 2px floor, :419 the 3px radius, :117 '
            'the 1/2 scale padding and :421 the 1 / 0.1 opacities.',
      );
    });

    test('barHeight is unset, so the auto solve wins', () {
      expect(
        style.barHeight,
        isNull,
        reason:
            'GanttChart.tsx:336 takes props.barHeight only when it is a '
            'number, so the resolved style must not invent one.',
      );
    });

    test('merge layers the other style over this one', () {
      final merged = style.merge(FluentGanttChartStyle.from(maxBarHeight: 40));
      expect(
        <double?>[
          merged.maxBarHeight!.resolve(const <WidgetState>{}),
          merged.minBarWidth!.resolve(const <WidgetState>{}),
        ],
        <double>[40, 2],
        reason: 'a non-null field of the argument wins; the rest are kept.',
      );
    });

    test('copyWith replaces one field and equality follows it', () {
      final copy = style.copyWith(
        minBarWidth: const WidgetStatePropertyAll<double?>(9),
      );
      expect(copy, isNot(style), reason: 'a changed field changes ==');
      expect(
        style.copyWith().hashCode,
        style.hashCode,
        reason: 'an empty copyWith is the identity, so the hash is stable',
      );
    });
  });

  group('FluentGanttChartDelegate against oracle B', () {
    // Both captured GanttChart stories draw their bars into the primary svg,
    // so every rect below is upstream's own geometry rather than a
    // hand-derivation. `crispOffset` is read off the story: the axis domain
    // path carries it on both ends (`d3-axis/src/axis.js:78`), and the scale
    // range is the path minus that offset.
    ({double bottom, double top}) yRangeOf(OracleStory story) {
      final path = story.soleElement(
        'path',
        where: (OracleElement e) => e.d!.startsWith('M-6,'),
      );
      final numbers = svgPathNumbers(path.d!);
      return (
        bottom: numbers[1] - story.crispOffset,
        top: numbers[3] - story.crispOffset,
      );
    }

    List<double> xRangeOf(OracleStory story) {
      final path = story.soleElement(
        'path',
        where: (OracleElement e) => e.d!.endsWith('V6'),
      );
      final numbers = svgPathNumbers(path.d!);
      return <double>[
        numbers[0] - story.crispOffset,
        numbers[3] - story.crispOffset,
      ];
    }

    void expectBarsMatch(
      OracleStory story,
      List<FluentGanttBar> bars, {
      required List<Color> fills,
    }) {
      final rects = story.byTag('rect');
      expect(
        bars.length,
        rects.length,
        reason: '${story.id} captured ${rects.length} bars',
      );
      expect(rects, isNotEmpty, reason: 'an empty rect list proves nothing');
      for (var i = 0; i < rects.length; i++) {
        final rect = rects[i];
        expectOracleRect(
          '${story.id} bar $i',
          Rect.fromLTWH(rect.x!, rect.y!, rect.width!, rect.height!),
          bars[i].rect,
        );
        expectOracleColour('${story.id} bar $i fill', fills[i], rect.fill);
        expectOracleColour(
          '${story.id} bar $i flattened fill',
          fills[i],
          bars[i].startColour,
        );
      }
    }

    test('GanttChartBasic reproduces all three captured bars', () {
      final story = loadOracleStory('charts-ganttchart--gantt-chart-basic');
      // Recovered from the capture: each bar's x and width invert through the
      // scale below onto midnight UTC, and the six month ticks land on the
      // same scale to within 0.001px.
      const blue = Color(0xFF637CEF);
      const pink = Color(0xFFE3008C);
      final d = delegate(
        points: <FluentGanttChartDataPoint>[
          FluentGanttChartDataPoint(
            x: FluentGanttSpan(
              start: DateTime.utc(2009),
              end: DateTime.utc(2009, 2, 28),
            ),
            y: 'Job A',
            legend: 'Job A',
            color: blue,
          ),
          FluentGanttChartDataPoint(
            x: FluentGanttSpan(
              start: DateTime.utc(2009, 3, 5),
              end: DateTime.utc(2009, 4, 15),
            ),
            y: 'Job B',
            legend: 'Job B',
            color: blue,
          ),
          FluentGanttChartDataPoint(
            x: FluentGanttSpan(
              start: DateTime.utc(2009, 2, 20),
              end: DateTime.utc(2009, 5, 30),
            ),
            y: 'Job C',
            legend: 'Job C',
            color: pink,
          ),
        ],
      );

      final margins = d.yDomainMargins(story.height)!;
      final yRange = yRangeOf(story);
      expectOracleNumber(
        '${story.id} y range bottom',
        yRange.bottom,
        story.height - margins.bottom!,
      );
      expectOracleNumber('${story.id} y range top', yRange.top, margins.top!);

      expect(
        d.orderedYAxisLabels,
        <String>['Job C', 'Job B', 'Job A'],
        reason:
            'the captured labels run Job A, Job B, Job C top to bottom, and '
            'the band scale ranges bottom-first, so the domain is reversed.',
      );

      final xRange = xRangeOf(story);
      final bars = d.barsFor(
        context(
          // The domain is the raw extent nice()d by createDateXAxis, which is
          // the axis builder's business, not the delegate's — Jan 1 to Jun 1
          // is what the six captured month ticks resolve to.
          xScale: d3.scaleUtc()
            ..domainOfDates(<DateTime>[
              DateTime.utc(2009),
              DateTime.utc(2009, 6),
            ])
            ..rangeOf(xRange),
          yScale: bandScale(
            d.orderedYAxisLabels,
            bottom: yRange.bottom,
            top: yRange.top,
          ),
          containerWidth: story.width,
          containerHeight: story.height,
        ),
        layout(width: story.width, height: story.height),
      );
      expectBarsMatch(story, bars, fills: const <Color>[blue, blue, pink]);
    });

    test('GanttChartGrouped reproduces the draw order of eight bars', () {
      final story = loadOracleStory('charts-ganttchart--gantt-chart-grouped');
      const green = Color(0xFF107C10);
      const orange = Color(0xFFF7630C);
      const red = Color(0xFFC50F1F);
      FluentGanttChartDataPoint point(
        String y,
        int startDay,
        int endDay,
        Color colour,
      ) => FluentGanttChartDataPoint(
        x: FluentGanttSpan(
          start: DateTime.utc(2017).add(Duration(days: startDay)),
          end: DateTime.utc(2017).add(Duration(days: endDay)),
        ),
        y: y,
        legend: '$colour',
        color: colour,
      );
      // Authored with each row's bars in DESCENDING start, so the emitted
      // order can only come from the sort at GanttChart.tsx:364 — and with the
      // rows first seen in the captured top-to-bottom order 1, 2, 4, 3.
      final d = delegate(
        points: <FluentGanttChartDataPoint>[
          point('Job-1', 45, 73, orange),
          point('Job-1', 0, 32, green),
          point('Job-2', 16, 47, green),
          point('Job-2', 16, 47, red),
          point('Job-4', 13, 72, green),
          point('Job-3', 137, 168, red),
          point('Job-3', 68, 78, red),
          point('Job-3', 90, 109, red),
        ],
      );
      final yRange = yRangeOf(story);
      final bars = d.barsFor(
        context(
          xScale: d3.scaleUtc()
            ..domainOfDates(<DateTime>[
              DateTime.utc(2017),
              DateTime.utc(2017, 7),
            ])
            ..rangeOf(xRangeOf(story)),
          yScale: bandScale(
            d.orderedYAxisLabels,
            bottom: yRange.bottom,
            top: yRange.top,
          ),
          containerWidth: story.width,
          containerHeight: story.height,
        ),
        layout(width: story.width, height: story.height),
      );
      expect(
        bars.map((FluentGanttBar b) => b.index).toList(),
        <int>[1, 0, 2, 3, 4, 6, 7, 5],
        reason:
            'every row is emitted in ascending start, and the two tied Job-2 '
            'bars keep their author order.',
      );
      expectBarsMatch(
        story,
        bars,
        fills: const <Color>[green, orange, green, red, green, red, red, red],
      );
    });
  });

  group('FluentGanttChart', () {
    /// Four spans on one row, tiling `[0, 100]` end to end, with the first
    /// legend reused so the colour map has to collapse two points onto one
    /// entry (`GanttChart.tsx:72-100`). One row and a full tiling is what makes
    /// the pointer tests below deterministic: every x inside the plot is over a
    /// bar, and every bar shares the row the popover names.
    const ganttPoints = <FluentGanttChartDataPoint>[
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: 0, end: 25),
        y: 'Design',
        legend: 'Planned',
      ),
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: 25, end: 50),
        y: 'Design',
        legend: 'Active',
      ),
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: 50, end: 75),
        y: 'Design',
        legend: 'Planned',
      ),
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(start: 75, end: 100),
        y: 'Design',
        legend: 'Done',
      ),
    ];

    /// The bar is grown to 240px, well past the 24px default, because the
    /// pointer tests hover the chart's own centre and the row's band centre
    /// sits above it by however tall the legend row turns out to be. 240 is a
    /// test constant, not a ported one.
    Widget ganttChart({WidgetBuilder? popoverBuilder, String? chartTitle}) =>
        FluentGanttChart(
          data: ganttPoints,
          chartTitle: chartTitle,
          popoverBuilder: popoverBuilder,
          barHeight: 240,
          maxBarHeight: 240,
        );

    Future<void> pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: Center(child: SizedBox(width: 800, height: 400, child: chart)),
      ),
    );

    Future<void> hoverCentre(WidgetTester tester) async {
      final g = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      await g.moveTo(tester.getCenter(find.byType(FluentCartesianChart)));
      await tester.pumpAndSettle();
    }

    FluentGanttChartDelegate mountedDelegate(WidgetTester tester) =>
        tester
                .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
                .delegate
            as FluentGanttChartDelegate;

    testWidgets('popoverBuilder IS wired, unlike upstream', (tester) async {
      await pump(
        tester,
        ganttChart(popoverBuilder: (BuildContext c) => const Text('custom')),
      );
      await hoverCentre(tester);
      expect(
        find.text('custom'),
        findsOneWidget,
        reason:
            'ponytail: upstream passes customizedCallout as a top-level '
            'CartesianChart prop (GanttChart.tsx:604) which CartesianChart.tsx '
            'never reads, so onRenderCalloutPerDataPoint is dead there. Wiring '
            'it is the smaller diff than reproducing a prop that does nothing.',
      );
    });

    testWidgets('the popover carries the category on top and the span below', (
      tester,
    ) async {
      await pump(tester, ganttChart());
      await hoverCentre(tester);
      final popover = tester.widget<FluentChartPopover>(
        find.byType(FluentChartPopover),
      );
      expect(
        popover.data.xValue,
        'Design',
        reason:
            'XValue = yAxisCalloutData || String(point.y), '
            'GanttChart.tsx:572-580',
      );
      expect(
        popover.data.isCalloutForStack,
        isFalse,
        reason:
            'parity: Gantt never sets isCartesian, so the popover uses the '
            'non-cartesian 28px typography, GanttChart.tsx:572-580',
      );
    });

    testWidgets('one palette colour per legend, not per data point', (
      tester,
    ) async {
      await pump(tester, ganttChart());
      expect(
        mountedDelegate(
          tester,
        ).points.map((FluentGanttChartDataPoint p) => p.color).toList(),
        <Color>[
          FluentDataVizPalette.next(0),
          FluentDataVizPalette.next(1),
          FluentDataVizPalette.next(0),
          FluentDataVizPalette.next(2),
        ],
        reason:
            'the `_points` memo mints one getNextColor(colorIndex, 0) per '
            'unique legend and rewrites every point with it, so the two '
            'Planned bars share a colour, GanttChart.tsx:72-100',
      );
    });

    testWidgets('selecting a legend reaches the delegate', (tester) async {
      await pump(tester, ganttChart());
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(
        mountedDelegate(tester).selectedLegends,
        <String>['Active'],
        reason:
            '_onLegendSelectionChange stores the selection and :410 dims every '
            'bar outside it, GanttChart.tsx:463-475',
      );
    });

    testWidgets('the semantic title counts data points', (tester) async {
      await pump(tester, ganttChart(chartTitle: 'Roadmap'));
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .props
            .chartTitleForSemantics,
        'Roadmap. Gantt chart with 4 data points. ',
        reason: 'GanttChart.tsx:517-519',
      );
    });

    testWidgets('an empty chart is an alert, not a plot', (tester) async {
      await pump(
        tester,
        const FluentGanttChart(data: <FluentGanttChartDataPoint>[]),
      );
      expect(
        find.byType(FluentCartesianChart),
        findsNothing,
        reason: 'GanttChart.tsx:612-615 renders an aria-label alert instead',
      );
    });
  });
}
