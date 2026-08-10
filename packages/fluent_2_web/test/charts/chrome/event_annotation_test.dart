import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/event_annotation.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_time.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/chart_annotation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

void main() {
  group('event annotation constants', () {
    test('the default label width is 105, not the packer width', () {
      expect(
        kEventAnnotationDefaultLabelWidth,
        105,
        reason:
            'EventAnnotation.tsx:17 — `props.labelWidth ? props.labelWidth : '
            '105`. The 110 that appears in the cross-plan contract is '
            'textWidth + textPadding from :37, which is the PACKER width, not '
            'the prop default.',
      );
      expect(
        kEventAnnotationTextPadding,
        5,
        reason: 'EventAnnotation.tsx:20 — `const textPadding = 5`.',
      );
    });

    test('the rule starts 13 above the plot top', () {
      expect(
        kEventAnnotationTextTopOffset,
        20,
        reason: 'EventAnnotation.tsx:18 — `textY = chartYTop - 20`.',
      );
      expect(
        kEventAnnotationLineTopOffset,
        13,
        reason:
            'EventAnnotation.tsx:19 — `lineTopY = textY + 7`, so the rule '
            'starts chartYTop - 20 + 7 = chartYTop - 13.',
      );
    });

    test('the rule is dashed at 8', () {
      expect(
        kEventAnnotationDashArray,
        <double>[8],
        reason: 'EventAnnotation.tsx:34 — `strokeDasharray="8"`.',
      );
    });

    test('the line height is 18 raw pixels', () {
      expect(
        kEventAnnotationLineHeight,
        18,
        reason:
            'EventAnnotation.tsx:21 sets lineHeight to 18 and Textbox.tsx:40 '
            'uses it as a RAW dy, not an em value, which is why the wrapped '
            'block lifts by -numLines * 18 at :44.',
      );
    });
  });

  group('fluentPackEventAnnotationLabels', () {
    test('a single event anchors to whichever side has room', () {
      final placed = fluentPackEventAnnotationLabels(
        <double>[200],
        110,
        400,
        0,
      );
      expect(
        placed.single.anchor,
        FluentEventLabelAnchor.end,
        reason:
            'EventAnnotation.tsx:78-79 — with lastX (0) below the left '
            'boundary (200 - 110 = 90) the label goes on the left, anchored at '
            'its end.',
      );
      expect(placed.single.aggregatedIndices, <int>[
        0,
      ], reason: 'One event, one index.');
    });

    test('a single event with no room on the left flips to start', () {
      final placed = fluentPackEventAnnotationLabels(<double>[50], 110, 400, 0);
      expect(
        placed.single.anchor,
        FluentEventLabelAnchor.start,
        reason:
            'EventAnnotation.tsx:80-81 — the left boundary is negative, so the '
            'label goes right instead, provided x + textWidth clears maxX.',
      );
    });

    test('a single event with room on neither side is dropped', () {
      expect(
        fluentPackEventAnnotationLabels(<double>[50], 110, 100, 0),
        isEmpty,
        reason:
            'EventAnnotation.tsx:84 returns an empty list when neither branch '
            'fits, so the event keeps its rule but loses its label.',
      );
    });

    test('crowded events are swallowed into one aggregated label', () {
      final placed = fluentPackEventAnnotationLabels(
        <double>[200, 205, 210],
        110,
        300,
        0,
      );
      expect(
        placed.length,
        1,
        reason:
            'EventAnnotation.tsx:96-116 — backtrack scans forward for the first '
            'event clear of the label just placed and folds everything between '
            'into it. The first label is anchored `end`, so the boundary is 200; '
            'neither 205 nor 210 clears it on the left (95 and 100 are both '
            'below 200) nor on the right (315 and 320 both exceed maxX 300), so '
            'the scan at :99-103 finds nothing and both are swallowed.',
      );
      expect(
        placed.single.aggregatedIndices,
        <int>[0, 1, 2],
        reason: 'EventAnnotation.tsx:108-111 collects i .. idx - 1.',
      );
    });

    test('a crowded successor with right-hand room is not swallowed', () {
      // The plan's own crowding case, at maxX 400 rather than 300. Upstream
      // aggregates on the :101 disjunction, whose second arm
      // (`ds.x + textWidth < maxX`) is satisfied at 400 — so 205 escapes the
      // fold and carries 210 in a second label of its own.
      final placed = fluentPackEventAnnotationLabels(
        <double>[200, 205, 210],
        110,
        400,
        0,
      );
      expect(
        placed.map((p) => p.aggregatedIndices).toList(),
        <List<int>>[
          <int>[0],
          <int>[1, 2],
        ],
        reason:
            'EventAnnotation.tsx:99-103 — findIndex from currentIdx + 1 accepts '
            '205 because 205 > 200 and 205 + 110 = 315 < 400, so backtrack(0) '
            'aggregates only itself and recurses at 205.',
      );
      expect(
        placed.map((p) => p.anchor).toList(),
        <FluentEventLabelAnchor>[
          FluentEventLabelAnchor.end,
          FluentEventLabelAnchor.start,
        ],
        reason:
            'EventAnnotation.tsx:87-93 — the first clears its left boundary (0 '
            '< 90) so it anchors end; the second does not (200 > 95) so it '
            'anchors start.',
      );
    });

    test('well-spaced events each get their own label', () {
      final placed = fluentPackEventAnnotationLabels(
        <double>[120, 300],
        110,
        400,
        0,
      );
      expect(
        placed.length,
        2,
        reason:
            'Two events 180 apart both clear the 110 label width, so neither '
            'is aggregated.',
      );
    });

    test('an empty list packs to nothing', () {
      expect(
        fluentPackEventAnnotationLabels(<double>[], 110, 400, 0),
        isEmpty,
        reason: 'EventAnnotation.tsx:63-65 — the first base case.',
      );
    });

    test('an event left of the axis range stops the pack outright', () {
      // EventAnnotation.tsx:72-74 returns [] rather than skipping the event,
      // which truncates the whole series. Only the first event can trip it:
      // every later index comes from the :99-103 scan, which only accepts
      // candidates already clear of the running boundary.
      expect(
        fluentPackEventAnnotationLabels(<double>[-10, 200], 110, 400, 0),
        isEmpty,
        reason:
            'EventAnnotation.tsx:72-74 — x (-10) is below lastX (minX 0), so '
            'calculateLabel bails and 200 never gets a label either.',
      );
    });
  });

  group('charts-linechart--line-chart-events', () {
    // The one captured story with event annotations. Its five events share
    // three distinct dates, so `uniqBy` (EventAnnotation.tsx:33) draws three
    // dashed rules while the packer still sees all five lineDefs (:37 is fed
    // the undeduplicated list), which is why the first label reads
    // `3 events` — mergedLabel(3) from LabelLink.tsx:69.
    final story = loadOracleStory('charts-linechart--line-chart-events');
    final rules = story
        .byTag('line')
        .where((e) => e.strokeDasharray == '8px')
        .toList();
    // Only the event labels carry a `width` — LabelLink.tsx:79 sets it and the
    // axis labels have none — and they arrive in document, i.e. packed, order.
    final labels = story.byTag('text').where((e) => e.width != null).toList();

    test('the capture carries three rules and three labels', () {
      expect(
        rules.length,
        3,
        reason:
            'Guard: the assertions below are vacuous if the dasharray filter '
            'matches nothing. EventAnnotation.tsx:33-35 draws one rule per '
            'distinct date.',
      );
      expect(
        labels.length,
        3,
        reason:
            'Guard: three packed labels, one per LabelLink from :37. Two of the '
            'five events were folded into the first.',
      );
    });

    test('the dash pattern renders as the captured 8px', () {
      for (final rule in rules) {
        expect(
          rule.strokeDasharray,
          '${kEventAnnotationDashArray.single.toInt()}px',
          reason:
              'EventAnnotation.tsx:34 — the capture resolves '
              'strokeDasharray="8" to `8px`, which is one 8-unit dash and one '
              '8-unit gap.',
        );
      }
    });

    test('the label sits 20 above the plot top and the rule 13', () {
      // textY = chartYTop - 20 (:18), so the captured baseline of 18 puts the
      // plot top at 38 — which is also where the rule's own offset must land.
      final baseline = labels.first.y!;
      final chartYTop = baseline + kEventAnnotationTextTopOffset;
      expectOracleNumber(
        'chartYTop derived from the label baseline',
        38,
        chartYTop,
      );
      for (final rule in rules) {
        expectOracleNumber(
          'rule #${rule.index} top',
          chartYTop - kEventAnnotationLineTopOffset,
          rule.y1!,
        );
      }
      expectOracleNumber(
        'rule top minus label baseline',
        kEventAnnotationTextTopOffset - kEventAnnotationLineTopOffset,
        rules.first.y1! - baseline,
        // EventAnnotation.tsx:19 — lineTopY = textY + 7.
      );
    });

    test('the packer reproduces every captured label x and anchor', () {
      // The rules stand on the three distinct event dates; the packer is fed
      // one position per event, so the first date appears three times
      // (EventAnnotation.tsx:37 passes lineDefs, not the uniqBy result).
      final positions = <double>[
        rules[0].x1!,
        rules[0].x1!,
        rules[0].x1!,
        rules[1].x1!,
        rules[2].x1!,
      ];
      // The story sets labelWidth to 50 — the captured `width` on each <text>,
      // which LabelLink.tsx:79 passes straight through from :44. The packer
      // gets that plus the padding (:37).
      final labelWidth = labels.first.width!;
      expect(
        labelWidth,
        50,
        reason:
            'Guard: LabelLink.tsx:79 sets width from textWidth, so a changed '
            'capture would silently repack.',
      );
      // The x scale's range is the axis domain path `M40.5,6V0.5H680.5V6`
      // (element #1), i.e. [40, 680] before the 0.5 crisp offset.
      final placed = fluentPackEventAnnotationLabels(
        positions,
        labelWidth + kEventAnnotationTextPadding,
        680,
        40,
      );

      expect(
        placed.length,
        labels.length,
        reason: 'One LabelLink per placement (EventAnnotation.tsx:37-51).',
      );
      for (var i = 0; i < placed.length; i++) {
        expectOracleNumber('label $i x', labels[i].x!, placed[i].x);
        expect(
          placed[i].anchor.name,
          labels[i].textAnchor,
          reason:
              'LabelLink.tsx:81 puts labelDef.anchor on textAnchor, and all '
              'three captured labels resolve to `end` — each clears its own '
              'left boundary (EventAnnotation.tsx:87-89).',
        );
      }
      expect(
        placed.first.aggregatedIndices,
        <int>[0, 1, 2],
        reason:
            'The captured text is `3 events`, i.e. mergedLabel(3) at '
            'LabelLink.tsx:69, so the first placement must swallow the two '
            'events sharing its date.',
      );
      expect(
        placed.map((p) => p.aggregatedIndices.length).toList(),
        <int>[3, 1, 1],
        reason:
            'The other two captured labels read a single event name each '
            '(LabelLink.tsx:66-67).',
      );
    });
  });

  group('FluentEventAnnotationLayer', () {
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    // `scaleTime()` is the local-time scale; the layer feeds it epoch
    // milliseconds, so the zone never enters the arithmetic.
    final scale = scaleTime()
      ..domainOfDates(<DateTime>[
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 31),
      ])
      ..rangeOf(<double>[0, 300]);

    Future<void> pump(
      WidgetTester tester,
      List<FluentEventAnnotation> events, {
      Color? strokeColor,
    }) => tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            height: 200,
            child: FluentEventAnnotationLayer(
              events: events,
              xScale: scale,
              chartTop: 40,
              chartBottom: 180,
              strokeColor: strokeColor,
              mergedLabel: (count) => '$count events',
            ),
          ),
        ),
      ),
    );

    FluentEventAnnotationPainter painterOf(WidgetTester tester) => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<FluentEventAnnotationPainter>()
        .first;

    testWidgets('events are sorted by date before packing', (tester) async {
      await pump(tester, <FluentEventAnnotation>[
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 20), event: 'later'),
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 5), event: 'earlier'),
      ]);
      expect(
        painterOf(tester).rules.first.dx < painterOf(tester).rules.last.dx,
        isTrue,
        reason: 'EventAnnotation.tsx:27 sorts lineDefs ascending by +date.',
      );
    });

    testWidgets('duplicate dates share one rule', (tester) async {
      await pump(tester, <FluentEventAnnotation>[
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 10), event: 'a'),
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 10), event: 'b'),
      ]);
      expect(
        painterOf(tester).rules.length,
        1,
        reason:
            'EventAnnotation.tsx:33 deduplicates by date.toString() before '
            'drawing the rules, though the LABELS still see both events.',
      );
    });

    testWidgets('the rule spans chartTop - 13 to chartBottom', (tester) async {
      await pump(tester, <FluentEventAnnotation>[
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 10), event: 'a'),
      ]);
      final painter = painterOf(tester);
      expect(
        painter.lineTop,
        40 - kEventAnnotationLineTopOffset,
        reason:
            'EventAnnotation.tsx:18-19 — textY = chartYTop - 20 and lineTopY = '
            'textY + 7.',
      );
      expect(
        painter.lineBottom,
        180,
        reason: 'EventAnnotation.tsx:34 — y2 is chartYBottom.',
      );
    });

    testWidgets('several crowded events collapse into a merged label', (
      tester,
    ) async {
      await pump(tester, <FluentEventAnnotation>[
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 10), event: 'a'),
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 11), event: 'b'),
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 12), event: 'c'),
      ]);
      expect(
        painterOf(tester).labels.single.text,
        '3 events',
        reason:
            'LabelLink.tsx:66-70 uses the event text for a single index and '
            'mergedLabel(count) for several.',
      );
    });

    testWidgets('a palette token is resolved against the live theme', (
      tester,
    ) async {
      await pump(
        tester,
        <FluentEventAnnotation>[
          FluentEventAnnotation(date: DateTime.utc(2026, 1, 10), event: 'a'),
        ],
        strokeColor: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      );
      expect(
        painterOf(tester).strokeColor.toARGB32(),
        FluentDataVizPalette.resolve(FluentDataVizToken.color3).toARGB32(),
        reason:
            'EventAnnotation.tsx:29-31 hard-codes isDarkTheme to false with an '
            'inline `ToDo fix`. That is a defect the source itself disowns, and '
            'reproducing it would put light-theme palette values on a dark '
            'chart, so the port reads the theme instead (contract section 6.7).',
      );
    });

    testWidgets('labels are not keyboard reachable', (tester) async {
      await pump(tester, <FluentEventAnnotation>[
        FluentEventAnnotation(date: DateTime.utc(2026, 1, 10), event: 'a'),
      ]);
      expect(
        // The plan's unscoped `find.byType(Focus)` cannot hold: FluentApp's own
        // shell puts Focus widgets in the tree. Scoped to the layer, which is
        // what the assertion is actually about.
        find.descendant(
          of: find.byType(FluentEventAnnotationLayer),
          matching: find.byType(Focus),
        ),
        findsNothing,
        reason:
            'LabelLink.tsx:74 sets data-is-focusable to false, so the labels '
            'are not tab stops. The click callout there is dead code (:35-59), '
            'so there is nothing to reach anyway.',
      );
    });
  });
}
