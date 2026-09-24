import 'dart:math' as math;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The two label functions are pure and carry four branches each, so they are
/// asserted directly rather than through the rendered text.
///
/// Oracle B stories used here: `charts-gaugechart--gauge-chart-basic` and
/// `charts-gaugechart--gauge-chart-single-segment`. The layout chain itself is
/// already asserted against all three gauge stories by
/// `gauge_chart_layout_test.dart`; what those two add here is the TEXT the
/// browser rendered — the centred value, the two limits, the title and the
/// sublabel — which is exactly what this task's two label functions and the
/// widget's text slots produce.
void main() {
  const key = Key('gauge');
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  const segments = <FluentGaugeChartSegment>[
    FluentGaugeChartSegment(legend: 'Low', size: 30),
    FluentGaugeChartSegment(legend: 'High', size: 70),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget chart, {
    Size size = const Size(400, 300),
    FluentThemeData? themeData,
  }) => tester.pumpWidget(
    FluentApp(
      theme: themeData ?? theme,
      home: Center(
        child: SizedBox(width: size.width, height: size.height, child: chart),
      ),
    ),
  );

  /// The [CustomPaint] carrying a painter of type [P] inside the gauge. A
  /// titled gauge paints its title on a [CustomPaint] of its own.
  Finder paintOf<P extends CustomPainter>() => find.descendant(
    of: find.byKey(key),
    matching: find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is P,
    ),
  );

  FluentGaugeChartPainter painterOf(WidgetTester tester) =>
      tester.widget<CustomPaint>(paintOf<FluentGaugeChartPainter>()).painter!
          as FluentGaugeChartPainter;

  /// [local], a point in the gauge painter's own box, on the screen.
  Offset onScreen(WidgetTester tester, Offset local) =>
      tester.getTopLeft(paintOf<FluentGaugeChartPainter>()) + local;

  /// The box of segment [index], as upstream's `getBoundingClientRect`
  /// reports it: the arc path's bounds.
  Rect bandBounds(WidgetTester tester, int index) {
    final painter = painterOf(tester);
    final arc = painter.arcs.firstWhere((arc) => arc.segmentIndex == index);
    return arc.path.getBounds().shift(onScreen(tester, painter.layout.origin));
  }

  /// A screen point in the middle of segment [index]'s band. d3 measures the
  /// angle clockwise from twelve o'clock.
  Offset bandPoint(WidgetTester tester, int index) {
    final painter = painterOf(tester);
    final layout = painter.layout;
    final arc = painter.arcs.firstWhere((arc) => arc.segmentIndex == index);
    final mid = (arc.startAngle + arc.endAngle) / 2;
    final radius = (layout.innerRadius + layout.outerRadius) / 2;
    return onScreen(
      tester,
      layout.origin + Offset(math.sin(mid) * radius, -math.cos(mid) * radius),
    );
  }

  /// The popover surface's rect on the screen.
  Rect surfaceRect(WidgetTester tester) => tester.getRect(
    find.descendant(
      of: find.byType(FluentChartPopover),
      matching: find.byType(ExcludeFocus),
    ),
  );

  Future<TestGesture> mouseAt(WidgetTester tester, Offset position) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(position);
    await tester.pump();
    // A real pointer drifts; a second move must not change the answer.
    await mouse.moveTo(position + const Offset(1, 0));
    await tester.pump();
    return mouse;
  }

  group('segment labels', () {
    const segment = FluentGaugeSegment(
      legend: 'Low',
      size: 30,
      colour: Color(0xFF000000),
      start: 0,
      end: 30,
    );

    test('a single-segment gauge from zero shows the share', () {
      expect(
        fluentGaugeSegmentLabel(
          segment,
          0,
          100,
          FluentGaugeChartVariant.singleSegment,
          forSemantics: false,
        ),
        '30 (30%)',
        reason:
            'GaugeChart.tsx:68-69 — `\${size} (\${percent}%)` with toFixed() '
            'and therefore no decimals.',
      );
    });

    test('any other combination shows the range', () {
      expect(
        fluentGaugeSegmentLabel(
          segment,
          0,
          100,
          FluentGaugeChartVariant.multipleSegments,
          forSemantics: false,
        ),
        '0 - 30',
        reason:
            'GaugeChart.tsx:70 — `\${start} - \${end}` with spaces round the '
            'dash.',
      );
    });

    test('the accessible form of a single segment names the legend', () {
      expect(
        fluentGaugeSegmentLabel(
          segment,
          0,
          100,
          FluentGaugeChartVariant.singleSegment,
          forSemantics: true,
        ),
        'Low, 30 out of 100 or 30%',
        reason: 'GaugeChart.tsx:62-63.',
      );
    });

    test('the accessible form otherwise reads the range as "to"', () {
      expect(
        fluentGaugeSegmentLabel(
          segment,
          20,
          100,
          FluentGaugeChartVariant.singleSegment,
          forSemantics: true,
        ),
        'Low, 0 to 30',
        reason:
            'GaugeChart.tsx:64 — a non-zero minimum takes the range arm even '
            'for a single segment.',
      );
    });
  });

  group('chart value labels', () {
    test('the on-chart form defaults to a percentage', () {
      expect(
        fluentGaugeValueLabel(25, 0, 100, null, forCallout: false),
        '25%',
        reason:
            'GaugeChart.tsx:94 — anything other than the literal \'fraction\', '
            'including undefined, takes the percentage arm.',
      );
    });

    test('the on-chart fraction form is value over maximum', () {
      expect(
        fluentGaugeValueLabel(
          25,
          0,
          100,
          FluentGaugeValueFormat.fraction,
          forCallout: false,
        ),
        '25/100',
        reason: 'GaugeChart.tsx:95.',
      );
    });

    test('the callout deliberately shows the other representation', () {
      expect(
        fluentGaugeValueLabel(25, 0, 100, null, forCallout: true),
        '25/100',
        reason:
            'GaugeChart.tsx:80-87 — the comment there says the callout uses '
            'fractions when the chart shows percentages and vice versa, to '
            'avoid repeating the same number.',
      );
      expect(
        fluentGaugeValueLabel(
          25,
          0,
          100,
          FluentGaugeValueFormat.fraction,
          forCallout: true,
        ),
        '25%',
        reason: 'The mirror of the case above.',
      );
    });

    test('a non-zero minimum prints the raw value in both forms', () {
      expect(
        fluentGaugeValueLabel(25, 10, 100, null, forCallout: false),
        '25',
        reason: 'GaugeChart.tsx:92-93 short-circuits on minValue !== 0.',
      );
    });

    test('a callback format receives the swept and total spans', () {
      expect(
        fluentGaugeValueLabel(
          25,
          10,
          100,
          (double swept, double total) => '$swept of $total',
          forCallout: false,
        ),
        '15.0 of 90.0',
        reason: 'GaugeChart.tsx:90-91 passes [value - min, max - min].',
      );
    });
  });

  testWidgets('the gauge is labelled as a region with its segment count', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentGaugeChart(key: key, chartValue: 50, segments: segments),
    );
    expect(
      tester.getSemantics(find.byKey(key)).label,
      'Gauge chart with 2 segments. ',
      reason:
          'GaugeChart.tsx:577-579 — the title prefix when present, then '
          '`Gauge chart with \${n} segments. ` with the trailing space.',
    );
  });

  testWidgets('the title is prefixed onto the region label', (tester) async {
    await pump(
      tester,
      const FluentGaugeChart(
        key: key,
        chartValue: 50,
        chartTitle: 'Risk',
        segments: segments,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key)).label,
      'Risk. Gauge chart with 2 segments. ',
      reason: 'GaugeChart.tsx:578 — `chartTitle ? `\${chartTitle}. ` : \'\'`.',
    );
  });

  testWidgets('the needle is announced with the on-chart value form', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentGaugeChart(key: key, chartValue: 50, segments: segments),
    );
    expect(
      find.bySemanticsLabel('Current value: 50%'),
      findsOneWidget,
      reason: 'GaugeChart.tsx:275-277 uses the non-callout form.',
    );
  });

  testWidgets('the min and max labels sit outside the arc', (tester) async {
    await pump(
      tester,
      const FluentGaugeChart(key: key, chartValue: 50, segments: segments),
    );
    expect(
      find.bySemanticsLabel('Min value: 0'),
      findsOneWidget,
      reason: 'GaugeChart.tsx:612-618.',
    );
    expect(
      find.bySemanticsLabel('Max value: 100'),
      findsOneWidget,
      reason: 'GaugeChart.tsx:622-628.',
    );
  });

  testWidgets('hideMinMax removes both labels', (tester) async {
    await pump(
      tester,
      const FluentGaugeChart(
        key: key,
        chartValue: 50,
        hideMinMax: true,
        segments: segments,
      ),
    );
    expect(
      find.bySemanticsLabel('Min value: 0'),
      findsNothing,
      reason:
          'GaugeChart.tsx:610 gates both on !hideMinMax, and their absence is '
          'also what shrinks the side margins to 16.',
    );
    expect(
      painterOf(tester).minLabel,
      isNull,
      reason: 'The painted limits go with the semantics nodes.',
    );
  });

  testWidgets('selecting a legend dims the other segment', (tester) async {
    await pump(
      tester,
      const FluentGaugeChart(key: key, chartValue: 50, segments: segments),
    );
    await tester.tap(find.text('Low'));
    await tester.pump();
    expect(
      painterOf(tester).opacities,
      <double>[1.0, 0.1],
      reason:
          'GaugeChart.tsx:646 — the multi-select predicate at :338-350 gates '
          'the opacity.',
    );
  });

  testWidgets('the legend includes the auto-appended Unknown filler', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentGaugeChart(
        key: key,
        chartValue: 50,
        maxValue: 150,
        segments: segments,
      ),
    );
    expect(
      find.text('Unknown'),
      findsOneWidget,
      reason:
          'GaugeChart.tsx:283-297 builds the legend from _segments, which '
          'already contains the filler pushed at :200-209.',
    );
  });

  testWidgets('the chart value is centred and hidden from assistive tech', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentGaugeChart(key: key, chartValue: 50, segments: segments),
    );
    expect(
      tester.getSemantics(find.text('50%')).label,
      isEmpty,
      reason:
          'GaugeChart.tsx:679 marks the chart value aria-hidden="true"; the '
          'needle already announces it.',
    );
  });

  testWidgets('hovering the needle opens the inverted callout', (tester) async {
    await pump(
      tester,
      const FluentGaugeChart(key: key, chartValue: 50, segments: segments),
    );
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    addTearDown(pointer.removePointer);
    await pointer.moveTo(
      tester.getCenter(find.bySemanticsLabel('Current value: 50%')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Current value is 50/100'),
      findsOneWidget,
      reason:
          'GaugeChart.tsx:386-387 — the popover inverts the painted 50% into '
          'the fraction so the two readings do not repeat each other.',
    );
    for (final label in <String>['0 - 30', '30 - 100']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason:
            'GaugeChart.tsx:389-396 lists every undimmed segment, through '
            'getSegmentLabel; the multiple-segments variant reads as a range '
            'and the running totals are seeded with the minimum.',
      );
    }

    await pointer.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(
      find.text('Current value is 50/100'),
      findsNothing,
      reason: 'GaugeChart.tsx:409-414 — leaving the svg hides the callout.',
    );
  });

  testWidgets('hideTooltip suppresses the callout entirely', (tester) async {
    await pump(
      tester,
      const FluentGaugeChart(
        key: key,
        chartValue: 50,
        hideTooltip: true,
        segments: segments,
      ),
    );
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    addTearDown(pointer.removePointer);
    await pointer.moveTo(
      tester.getCenter(find.bySemanticsLabel('Current value: 50%')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Current value is 50/100'),
      findsNothing,
      reason: 'GaugeChart.tsx:703 gates the whole ChartPopover on it.',
    );
  });

  group('hover', () {
    const chart = FluentGaugeChart(
      key: key,
      chartValue: 50,
      segments: segments,
    );

    testWidgets('a hovered segment is never stroked, during or after', (
      tester,
    ) async {
      await pump(tester, chart);
      final mouse = await mouseAt(tester, bandPoint(tester, 0));
      expect(find.text('Current value is 50/100'), findsOneWidget);
      expect(
        painterOf(tester).focusedIndex,
        isNull,
        reason:
            'GaugeChart.tsx:405-407 sets focusedElement on focus events only, '
            'so the 2px ARC_PADDING outline (:653) is a keyboard indicator; '
            'upstream draws no stroke on hover.',
      );

      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(find.text('Current value is 50/100'), findsNothing);
      expect(
        painterOf(tester).focusedIndex,
        isNull,
        reason: 'Nor may an outline be left behind once the pointer leaves.',
      );
    });

    testWidgets('keyboard focus strokes the segment and blur clears it', (
      tester,
    ) async {
      await pump(tester, chart);
      final node = Focus.of(
        tester.element(find.bySemanticsLabel('Low, 0 to 30')),
      )..requestFocus();
      await tester.pump();
      expect(painterOf(tester).focusedIndex, 0);
      expect(
        find.text('Current value is 50/100'),
        findsOneWidget,
        reason: 'GaugeChart.tsx:354-356 — focus opens the callout too.',
      );

      node.unfocus();
      // The focus manager applies the change in a microtask after the first
      // frame, so the rebuild it asks for lands on the second.
      await tester.pump();
      await tester.pump();
      expect(painterOf(tester).focusedIndex, isNull);
      expect(
        find.text('Current value is 50/100'),
        findsNothing,
        reason: 'GaugeChart.tsx:358-360 — blur hides it and clears the ring.',
      );
    });

    testWidgets('the hollow of an arc\'s bounding box is empty plot', (
      tester,
    ) async {
      await pump(tester, chart);
      // Low spans nine o'clock to 54 degrees above it, so its box's inner
      // corner is inside the hole, off the needle and off the value.
      final bounds = bandBounds(tester, 0);
      await mouseAt(tester, bounds.bottomRight - const Offset(3, 3));
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason:
            'GaugeChart.tsx:655-659 put the handlers on the <path>, so only '
            'the painted band opens the callout.',
      );
    });

    testWidgets('leaving a segment closes the callout; the needle keeps it', (
      tester,
    ) async {
      await pump(tester, chart);
      final hollow = bandBounds(tester, 0).bottomRight - const Offset(3, 3);
      final mouse = await mouseAt(tester, bandPoint(tester, 0));
      expect(find.byType(FluentChartPopover), findsOneWidget);

      await mouse.moveTo(hollow);
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason:
            "GaugeChart.tsx:658 — a segment's onMouseLeave dismisses the "
            'callout even though the pointer is still over the svg.',
      );

      await mouse.moveTo(
        tester.getCenter(find.bySemanticsLabel('Current value: 50%')),
      );
      await tester.pump();
      expect(find.byType(FluentChartPopover), findsOneWidget);
      await mouse.moveTo(hollow);
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason:
            'GaugeChart.tsx:268-273 give the needle no leave handler, so its '
            'callout stays up until the pointer leaves the svg (:597).',
      );
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(find.byType(FluentChartPopover), findsNothing);
    });

    testWidgets('the callout hangs off the hovered segment, not the pointer', (
      tester,
    ) async {
      await pump(tester, chart);
      final mouse = await mouseAt(tester, bandPoint(tester, 0));
      final bounds = bandBounds(tester, 0);
      final surface = surfaceRect(tester);
      expect(
        surface.center.dx,
        moreOrLessEquals(bounds.center.dx, epsilon: 0.5),
        reason:
            'GaugeChart.tsx:402 targets the segment element, so the surface '
            "centres on its box (Popover's default align: center).",
      );
      expect(
        surface.bottom,
        moreOrLessEquals(bounds.top - 20, epsilon: 0.5),
        reason:
            'Above the segment box and 20px clear of it (ChartPopover.tsx:48). '
            'Measured upstream: Low Risk 450..486 x 199..251 put a 156x203 '
            'surface at x 390 — centred on 468.',
      );

      await mouse.moveTo(bandPoint(tester, 0) + const Offset(0, -6));
      await tester.pump();
      expect(
        surfaceRect(tester),
        surface,
        reason: 'The target is the element, so moving over it moves nothing.',
      );
    });

    testWidgets('the needle and the value anchor on their own boxes', (
      tester,
    ) async {
      await pump(tester, chart);
      final needle = tester.getRect(
        find.bySemanticsLabel('Current value: 50%'),
      );
      final origin = onScreen(tester, painterOf(tester).layout.origin);
      expect(
        needle.center.dx,
        moreOrLessEquals(origin.dx, epsilon: 0.01),
        reason:
            'At 50% the needle stands straight up (GaugeChart.tsx:265), and '
            'its box is the rotated one — upstream 508,186 8x22 on the basic '
            'story — not the unrotated shape lying along nine o\'clock.',
      );
      expect(needle.height, greaterThan(needle.width));

      final mouse = await mouseAt(tester, needle.center);
      expect(
        surfaceRect(tester).bottom,
        moreOrLessEquals(needle.top - 20, epsilon: 0.5),
      );
      await mouse.moveTo(Offset.zero);
      await tester.pump();

      final value = tester.getRect(find.text('50%'));
      await mouse.moveTo(value.center);
      await tester.pump();
      expect(
        find.text('Current value is 50/100'),
        findsOneWidget,
        reason: 'GaugeChart.tsx:667-669 — the chart value opens it as well.',
      );
      expect(
        surfaceRect(tester).bottom,
        moreOrLessEquals(value.top - 20, epsilon: 0.5),
        reason:
            'Measured upstream on the basic story: the value box 492.49,230 '
            '39.02x27 put the surface at 434,7 — centred on it, 20px above.',
      );
      expect(
        surfaceRect(tester).center.dx,
        moreOrLessEquals(value.center.dx, epsilon: 0.5),
      );
    });

    testWidgets('the callout still opens once hideTooltip is lifted', (
      tester,
    ) async {
      // Mounts, unmounts and remounts the OverlayPortal the callout floats
      // in; a remounted portal starts hidden.
      await pump(tester, chart);
      await pump(
        tester,
        const FluentGaugeChart(
          key: key,
          chartValue: 50,
          hideTooltip: true,
          segments: segments,
        ),
      );
      await pump(tester, chart);
      await mouseAt(tester, bandPoint(tester, 0));
      expect(find.text('Current value is 50/100'), findsOneWidget);
    });

    testWidgets('the callout body is useGaugeChartStyles, not ChartPopover', (
      tester,
    ) async {
      await pump(tester, chart);
      await mouseAt(tester, bandPoint(tester, 0));
      final colors = theme.colors;

      final header = tester.renderObject<RenderParagraph>(
        find.text('Current value is 50/100'),
      );
      expect(
        header.text.style!.color,
        colors.neutralForeground1.withValues(alpha: 0.85),
        reason:
            'useGaugeChartStyles.styles.ts:92-96 — calloutContentX at opacity '
            '0.85 over the surface colour, colorNeutralForeground1.',
      );

      final reading = tester.renderObject<RenderParagraph>(find.text('0 - 30'));
      expect(reading.text.style!.fontSize, 14);
      expect(reading.text.style!.fontWeight, FluentFontWeight.semibold);
      expect(
        reading.size.height,
        22,
        reason:
            ':114-118 — calloutContentY is body1Strong on a 22px line; the '
            "generic popover's reading is 16px bold.",
      );

      final bars = <Rect>[
        for (final colour in <Color>[
          FluentDataVizPalette.next(0),
          FluentDataVizPalette.next(1),
        ])
          tester.getRect(
            find.descendant(
              of: find.byType(FluentChartPopover),
              matching: find.byWidgetPredicate(
                (widget) => widget is ColoredBox && widget.color == colour,
              ),
            ),
          ),
      ];
      expect(
        bars.map((bar) => bar.size),
        everyElement(const Size(4, 38)),
        reason:
            ':97-104 put the 13px margin on the bordered block itself, so each '
            'bar spans only its 16px legend and 22px reading.',
      );
      expect(
        bars[1].top - bars[0].bottom,
        13,
        reason: 'The margins sit between the bars instead.',
      );
    });
  });

  group('high contrast', () {
    testWidgets('every segment fill flattens to the system foreground', (
      tester,
    ) async {
      const explicit = <FluentGaugeChartSegment>[
        // The three fills charts-gaugechart--gauge-chart-basic captures.
        FluentGaugeChartSegment(
          legend: 'Low Risk',
          size: 40,
          color: Color(0xFF107C10),
        ),
        FluentGaugeChartSegment(
          legend: 'High Risk',
          size: 60,
          color: Color(0xFFC50F1F),
        ),
      ];
      await pump(
        tester,
        const FluentGaugeChart(key: key, chartValue: 50, segments: explicit),
      );
      expect(painterOf(tester).colours, <Color>[
        const Color(0xFF107C10),
        const Color(0xFFC50F1F),
      ], reason: 'A normal theme keeps the caller\'s fills untouched.');

      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        const FluentGaugeChart(key: key, chartValue: 50, segments: explicit),
        themeData: hc,
      );
      final flattened = FluentChartColors.of(hc).axisText;
      expect(
        painterOf(tester).colours,
        <Color>[flattened, flattened],
        reason:
            'Design spec section 5.3 — GaugeChart.tsx:645 sets `fill` with no '
            '`forced-color-adjust`, so a forced-colours browser rewrites every '
            'segment to CanvasText. FluentChartColors.flattenMark is what does '
            'that here.',
      );
    });
  });

  group('Oracle B', () {
    testWidgets('charts-gaugechart--gauge-chart-basic', (tester) async {
      final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
      // The three arcs the capture records are exactly 60 degrees each
      // (`M-61.992,-1 A62,62,0,0,1,-32.417,-52.85 ...`), so the segments are
      // equal thirds; the centred `50%` then fixes the total at 100.
      final thirds = <FluentGaugeChartSegment>[
        for (final legend in <String>['Low Risk', 'Medium Risk', 'High Risk'])
          FluentGaugeChartSegment(legend: legend, size: 100 / 3),
      ];
      await pump(
        tester,
        FluentGaugeChart(key: key, chartValue: 50, segments: thirds),
        // GaugeChart.tsx:594 draws the svg _legendsHeight shorter than the
        // root, so the logical box is the captured svg plus the 32px strip.
        size: Size(story.width, story.height + 32),
      );

      final texts = story.byTag('text');
      expect(
        texts.length,
        3,
        reason:
            'The story must have captured the two limits and the centred '
            'value, and nothing else, for the reads below to be unambiguous.',
      );
      final centred = story.soleElement(
        'text',
        where: (element) => element.textAnchor == 'middle',
      );
      expect(
        find.bySemanticsLabel('Current value: ${centred.text}'),
        findsOneWidget,
        reason:
            'GaugeChart.tsx:672 paints getChartValueLabel and :276 reads the '
            'SAME string out on the needle; the capture records it as '
            '"${centred.text}". The label is asserted rather than the painted '
            'Text because the on-chart copy is clipped to the hole '
            '(`GaugeChart.tsx:681`) and the test font is a fixed-advance one, '
            'so it truncates at a width Segoe UI would not.',
      );
      final painter = painterOf(tester);
      expect(
        <String?>[painter.minLabel, painter.maxLabel],
        <String>[
          story.soleElement('text', where: (e) => e.textAnchor == 'end').text!,
          story
              .soleElement('text', where: (e) => e.textAnchor == 'start')
              .text!,
        ],
        reason:
            'GaugeChart.tsx:619 and :629 paint formatScientificLimitWidth of '
            'the resolved minimum and maximum.',
      );
      expectOracleNumber(
        'chart value font size',
        centred.fontSize,
        painter.chartValueTextStyle.fontSize!,
      );

      final legendLabels = story
          .boxes('fui-legend__text')
          .map((box) => box.text)
          .toList();
      expect(
        legendLabels,
        <String>['Low Risk', 'Medium Risk', 'High Risk'],
        reason:
            'The legend is HTML upstream, so its labels come back as boxes '
            'rather than svg text.',
      );
      expect(
        tester
            .widget<FluentChartLegend>(find.byType(FluentChartLegend))
            .legends
            .map((item) => item.title)
            .toList(),
        legendLabels,
        reason:
            'GaugeChart.tsx:283-297 builds one row per segment, in segment '
            'order. The rows are asserted rather than found by text because at '
            'the captured 252px the strip collapses into the overflow menu.',
      );
    });

    // The story above is captured with `width: 252` inside a 944px root, and
    // the capture's own two html boxes say what upstream does with the
    // difference: `fui-gc__chartWrapper` is at x 370 and 252 wide, while
    // `fui-legend__root` is at x 24 and 944 wide. 370 - 24 = 346 = (944 - 252)
    // / 2 — the chart is CENTRED and the legend is not, because the root is
    // `display: flex; flex-direction: column; align-items: center; width: 100%`
    // (`useGaugeChartStyles.styles.ts:35-43`) and `legendsContainer` overrides
    // that with `width: 100%` (`:126-128`).
    //
    // Every coordinate `FluentGaugeLayout` solves — the origin above all — is
    // relative to the svg, so the box handed to the painter has to be the
    // svg's. Give it the root's and the whole gauge slides 346px left, which is
    // what `test/parity/gauge_and_polar_parity_test.dart` measured as 4.2%.
    testWidgets('a chart narrower than its root is centred inside it', (
      tester,
    ) async {
      final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
      final wrapper = story.boxes('fui-gc__chartWrapper').single.rect;
      final root = story.boxes('fui-legend__root').single.rect;
      final box = Size(root.width, wrapper.height + root.height);
      // 944 is wider than the 800px default surface, which would otherwise
      // clamp the root and quietly move the number under test.
      tester.view.physicalSize = box;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pump(
        tester,
        FluentGaugeChart(
          key: key,
          chartValue: 50,
          width: wrapper.width,
          height: box.height,
          segments: segments,
        ),
        size: box,
      );

      final rootRect = tester.getRect(find.byKey(key));
      final chartArea = tester
          .getRect(
            find
                .descendant(
                  of: find.byKey(key),
                  matching: find.byType(CustomPaint),
                )
                .first,
          )
          .shift(-rootRect.topLeft);
      expectOracleRect(
        'the painted chart area inside the root',
        Rect.fromLTWH(
          wrapper.left - root.left,
          0,
          wrapper.width,
          wrapper.height,
        ),
        chartArea,
      );
      expectOracleNumber(
        'the gauge pivot inside the root',
        // GaugeChart.tsx:599 translates by `_width / 2` — 126 — inside an svg
        // whose own left edge is at 346, so the pivot lands on the root's
        // horizontal centre.
        root.width / 2,
        chartArea.left + painterOf(tester).layout.origin.dx,
      );
      expectOracleNumber(
        'the legend width',
        root.width,
        tester.getRect(find.byType(FluentChartLegend)).width,
      );
    });

    testWidgets('charts-gaugechart--gauge-chart-single-segment', (
      tester,
    ) async {
      final story = loadOracleStory(
        'charts-gaugechart--gauge-chart-single-segment',
      );
      const halves = <FluentGaugeChartSegment>[
        // The capture's two arcs are equal halves and the centred value reads
        // 50/100, so both segments are 50.
        FluentGaugeChartSegment(legend: 'Used', size: 50),
        FluentGaugeChartSegment(legend: 'Available', size: 50),
      ];
      await pump(
        tester,
        const FluentGaugeChart(
          key: key,
          chartValue: 50,
          segments: halves,
          chartTitle: 'Storage capacity',
          sublabel: 'used',
          chartValueFormat: FluentGaugeValueFormat.fraction,
          variant: FluentGaugeChartVariant.singleSegment,
        ),
        size: Size(story.width, story.height + 32),
      );

      final centred = story.soleElement(
        'text',
        where: (element) => element.textAnchor == 'middle' && element.y == 0,
      );
      expect(
        centred.text,
        '50/100',
        reason:
            'The fraction arm of getChartValueLabel (`GaugeChart.tsx:95`) is '
            'what this story exercises.',
      );
      expect(
        find.text('used'),
        findsOneWidget,
        reason: 'GaugeChart.tsx:687 renders the sublabel; the capture has it.',
      );
      final title =
          tester
                  .widget<CustomPaint>(paintOf<FluentChartTitlePainter>())
                  .painter!
              as FluentChartTitlePainter;
      final layout = painterOf(tester).layout;
      final captured = story.soleElement(
        'text',
        where: (element) => element.text == 'Storage capacity',
      );
      expect(
        title.text,
        captured.text,
        reason: 'GaugeChart.tsx:601 renders the title; the capture has it.',
      );
      expect(
        title.baseline,
        FluentChartTitleBaseline.alphabetic,
        reason:
            'ChartTitle.tsx:67-74 — no titleYAnchor, so `dominant-baseline: '
            'auto`: the y places the alphabetic baseline.',
      );
      expectOracleNumber(
        'title baseline above the origin',
        captured.y!,
        title.anchor.dy - layout.origin.dy,
      );
      expectOracleNumber('title anchor x', layout.origin.dx, title.anchor.dx);
      expect(
        find.bySemanticsLabel('Current value: 50/100'),
        findsOneWidget,
        reason:
            'GaugeChart.tsx:276 labels the needle with the SAME non-callout '
            'form the story paints in the middle.',
      );
      expect(
        find.bySemanticsLabel('Used, 50 out of 100 or 50%'),
        findsOneWidget,
        reason:
            'GaugeChart.tsx:62-63 — the single-segment variant from a zero '
            'minimum takes the share arm of the accessible label.',
      );
    });

    test('every captured gauge story is accounted for', () {
      expect(
        oracleStoryIds(component: 'GaugeChart'),
        <String>[
          'charts-gaugechart--gauge-chart-basic',
          'charts-gaugechart--gauge-chart-responsive',
          'charts-gaugechart--gauge-chart-single-segment',
        ],
        reason:
            'The responsive story differs from the basic one only in the box '
            'it is given, which gauge_chart_layout_test.dart already asserts; '
            'a re-capture that adds a story must be triaged here too.',
      );
    });
  });
}
