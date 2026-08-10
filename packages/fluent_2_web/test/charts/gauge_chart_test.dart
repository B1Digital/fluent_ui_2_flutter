import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/gauge_chart.dart';
import 'package:flutter/gestures.dart';
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

  FluentGaugeChartPainter painterOf(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find
                    .descendant(
                      of: find.byKey(key),
                      matching: find.byType(CustomPaint),
                    )
                    .first,
              )
              .painter!
          as FluentGaugeChartPainter;

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
      expect(
        painterOf(tester).colours,
        <Color>[const Color(0xFF107C10), const Color(0xFFC50F1F)],
        reason: 'A normal theme keeps the caller\'s fills untouched.',
      );

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
      for (final expected in <String>['Storage capacity', 'used']) {
        expect(
          find.text(expected),
          findsOneWidget,
          reason:
              'GaugeChart.tsx:601 and :687 render the title and the sublabel; '
              'the capture records both.',
        );
      }
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
