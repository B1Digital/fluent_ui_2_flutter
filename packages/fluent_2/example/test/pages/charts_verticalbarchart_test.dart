import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// VerticalBarChart's page is eleven demos, nine of them knob-driven, and every
/// one of those knobs reaches a canvas rather than a widget: a bar, a bar
/// label, an axis title and a tick label are all `Canvas` calls inside one
/// `CustomPaint`. So every assertion below reads the chart's own display list —
/// [paintOps] — or the geometry the painter was handed. A knob that flips the
/// demo's state and leaves the display list untouched is the defect this suite
/// exists to catch, and there is exactly one knob on this page that is
/// *supposed* to do that; it is asserted as inert on purpose.
void main() {
  const String page = 'charts-verticalbarchart';

  group('vertical bar default', () {
    final DocsSection section = sectionOf(
      'charts-verticalbarchart--vertical-bar-default',
    );

    testWidgets('the width and height sliders resize the plot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentVerticalBarChart);
      final Finder width = find.byType(FluentSlider).at(0);
      final Finder height = find.byType(FluentSlider).at(1);
      expect(tester.getSize(chart), const Size(650, 350));
      final double reach = _bars(tester).last.right;

      await dropSliderAt(tester, width, 1);
      // The box must be exactly the number the slider now reports: a demo that
      // rounds, clamps or ignores the value would still "move" and be wrong.
      expect(
        tester.getSize(chart).width,
        tester.widget<FluentSlider>(width).value,
      );
      expect(tester.getSize(chart).width, greaterThan(900));
      expect(
        _bars(tester).last.right,
        greaterThan(reach),
        reason: 'a wider box must spread the bars, not just pad them',
      );

      final double tallest = _tallest(tester);
      await dropSliderAt(tester, height, 1);
      expect(
        tester.getSize(chart).height,
        tester.widget<FluentSlider>(height).value,
      );
      expect(_tallest(tester), greaterThan(tallest));

      // Round trip: both sliders back to their floor, which is the one value a
      // rail tap reaches exactly.
      await dropSliderAt(tester, width, 0);
      await dropSliderAt(tester, height, 0);
      expect(tester.getSize(chart), const Size(200, 200));
    });

    testWidgets('the single-colour checkbox collapses the palette', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder single = find.byType(FluentCheckbox).at(0);
      expect(_fills(tester).toSet().length, greaterThan(1));

      // A real mouse on the page's primary knob: FluentCheckbox draws its glyph
      // in a CustomPaint under an interaction wrapper, so a control that only
      // answers a synthetic tap would be dead under a pointer.
      await mouseClick(tester, single);
      expect(tester.widget<FluentCheckbox>(single).checked, isTrue);
      expect(
        _fills(tester).toSet(),
        hasLength(1),
        reason: 'useSingleColor must repaint every bar in one colour',
      );

      await mouseClick(tester, single);
      expect(tester.widget<FluentCheckbox>(single).checked, isFalse);
      expect(_fills(tester).toSet().length, greaterThan(1));
    });

    testWidgets('hiding the labels drops one paragraph per bar', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder hide = find.byType(FluentCheckbox).at(1);
      final int bars = _bars(tester).length;
      final int labelled = _paragraphs(tester);

      await tapAndSettle(tester, hide, what: 'the hide-labels checkbox');
      expect(tester.widget<FluentCheckbox>(hide).checked, isTrue);
      // Exactly one label per bar disappears. A looser "fewer paragraphs" would
      // also pass if the chart dropped its tick labels instead.
      expect(_paragraphs(tester), labelled - bars);

      await tapAndSettle(tester, hide, what: 'the hide-labels checkbox');
      expect(_paragraphs(tester), labelled);
    });

    testWidgets('the axis-titles switch paints both titles', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder titles = find.byType(FluentSwitch).at(0);
      final int bare = _paragraphs(tester);

      await tapAndSettle(tester, titles, what: 'the axis-titles switch');
      expect(tester.widget<FluentSwitch>(titles).checked, isTrue);
      expect(
        _paragraphs(tester),
        bare + 2,
        reason: 'the x and y titles are one paragraph each',
      );

      await tapAndSettle(tester, titles, what: 'the axis-titles switch');
      expect(_paragraphs(tester), bare);
    });

    testWidgets('the multi-select switch keeps a second legend selected', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rows = find.byType(FluentChartLegendRow);
      expect(rows, findsWidgets);

      // Two different series, whichever two the strip has room for. The line's
      // own legend is skipped: it dims the polyline, not a bar.
      final List<String> pair = _barLegendTitles(tester).take(2).toList();
      expect(pair, hasLength(2));

      await mouseClick(tester, _legendRow(pair[0]));
      expect(_highlighted(tester), 1);
      await mouseClick(tester, _legendRow(pair[1]));
      expect(
        _highlighted(tester),
        1,
        reason:
            'single selection must drop the first legend when the second '
            'is picked',
      );

      // The switch only changes what the NEXT press does; the standing
      // selection survives it, so this adds the first legend back to it.
      await tapAndSettle(
        tester,
        find.byType(FluentSwitch).at(1),
        what: 'the multi-select switch',
      );
      await mouseClick(tester, _legendRow(pair[0]));
      expect(
        _highlighted(tester),
        2,
        reason: 'multiple selection must keep both legends lit',
      );
    });

    testWidgets('the callout radios commit while the demo stays inert', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder group = find.byType(FluentRadioGroup<String>);
      final List<Rect> before = _bars(tester);

      await mouseClick(tester, find.text('Custom Callout Example'));
      expect(
        tester.widget<FluentRadioGroup<String>>(group).value,
        'Custom Callout Example',
      );
      // Upstream's radio pair swaps in `onRenderCalloutPerDataPoint`, which is
      // commented out in the story source; the port documents the same inert
      // behaviour, so the plot must NOT move. This assertion is what would fail
      // if the pair were ever wired up without the docs following.
      expect(_bars(tester), before);
    });
  });

  group('vertical bar custom accessibility', () {
    final DocsSection section = sectionOf(
      'charts-verticalbarchart--vertical-bar-custom-accessibility',
    );

    testWidgets('the line checkbox draws and removes the overlaid line', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder line = find.byType(FluentCheckbox).at(0);
      expect(tester.widget<FluentCheckbox>(line).checked, isTrue);
      expect(_dots(tester), greaterThan(0));

      await mouseClick(tester, line);
      expect(tester.widget<FluentCheckbox>(line).checked, isFalse);
      expect(
        _dots(tester),
        0,
        reason: 'clearing lineData must remove the dots as well as the stroke',
      );
      expect(_paths(tester), 0);

      await mouseClick(tester, line);
      expect(_dots(tester), greaterThan(0));
    });

    testWidgets('the single-colour checkbox restores the custom ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder single = find.byType(FluentCheckbox).at(1);
      expect(tester.widget<FluentCheckbox>(single).checked, isTrue);
      expect(_fills(tester).toSet(), hasLength(1));

      await tapAndSettle(tester, single, what: 'the single-colour checkbox');
      expect(
        _fills(tester).toSet().length,
        greaterThan(1),
        reason: 'clearing it must hand the bars the three-green ramp back',
      );
    });
  });

  group('vertical bar date axis', () {
    testWidgets('the custom formatter labels every tick', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('charts-verticalbarchart--vertical-bar-date-axis'),
      );
      expect(_bars(tester), hasLength(5));
      // The demo hands the shell five explicit tick values and a `%m/%d`
      // formatter. The formatter lands; the tick values do not — the axis
      // labels thirteen generated monthly ticks instead of the five dates the
      // section names. Upstream's own capture of this story
      // (`test/fixtures/charts/oracle_b/charts-verticalbarchart--vertical-bar-
      // date-axis.json`) carries exactly five x labels, one per tick value, so
      // this is the port dropping the prop: `FluentCartesianChartProps
      // .tickValues` reaches the domain solve and then the three x builders are
      // handed `delegate.tickParams`, which no delegate ever fills in.
      expect(_painter(tester).xAxis.tickLabels, <String>[
        '01/01',
        '03/01',
        '07/01',
        '10/01',
        '01/01',
      ]);
    });
  });

  group('vertical bar axis tooltip', () {
    final DocsSection section = sectionOf(
      'charts-verticalbarchart--vertical-bar-axis-tooltip',
    );

    testWidgets('the barWidth spin button widens every bar', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder barWidth = find.byType(FluentSpinButton).at(0);
      expect(_bars(tester).map((Rect r) => r.width).toSet(), <double>{16});

      await typeAndCommit(tester, barWidth, '40');
      expect(tester.widget<FluentSpinButton>(barWidth).value, 40);
      expect(_bars(tester).map((Rect r) => r.width).toSet(), <double>{40});

      await typeAndCommit(tester, barWidth, '16');
      expect(_bars(tester).map((Rect r) => r.width).toSet(), <double>{16});
    });

    testWidgets('the maxBarWidth spin button clamps the bars', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await typeAndCommit(tester, find.byType(FluentSpinButton).at(0), '200');
      expect(
        _bars(tester).map((Rect r) => r.width).toSet(),
        <double>{100},
        reason: 'maxBarWidth is 100, so a 200px request must be cut to it',
      );

      await typeAndCommit(tester, find.byType(FluentSpinButton).at(1), '30');
      expect(_bars(tester).map((Rect r) => r.width).toSet(), <double>{30});
    });

    testWidgets("clearing the barWidth checkbox hands the bars 'auto'", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder enabled = find.byType(FluentCheckbox).at(0);
      final double fixed = _bars(tester).first.width;

      await mouseClick(tester, enabled);
      expect(tester.widget<FluentCheckbox>(enabled).checked, isFalse);
      expect(
        find.text("'auto'"),
        findsOneWidget,
        reason: 'the spin button is replaced by the literal it stands in for',
      );
      expect(find.byType(FluentSpinButton), findsOneWidget);
      expect(
        _bars(tester).first.width,
        isNot(closeTo(fixed, 0.5)),
        reason: "'auto' must take the band's own width",
      );

      await mouseClick(tester, enabled);
      expect(_bars(tester).first.width, fixed);
    });

    testWidgets('the inner-padding slider changes the gap between bars', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder gate = find.byType(FluentCheckbox).at(1);
      final Finder slider = find.byType(FluentSlider).at(2);
      final double step = _step(tester);
      // 2:1 spacing is the documented default: two bar widths of air for every
      // bar width of ink, so the step is three times the 16px bar.
      expect(step, closeTo(48, 1));

      // Disabled until its checkbox is ticked: the slider must refuse to move
      // while the prop it feeds is null.
      await dropSliderAt(tester, slider, 1);
      expect(tester.widget<FluentSlider>(slider).value, 0.67);
      expect(_step(tester), step);

      await tapAndSettle(tester, gate, what: 'the inner-padding checkbox');
      await dropSliderAt(tester, slider, 0);
      expect(tester.widget<FluentSlider>(slider).value, 0);
      expect(
        _step(tester),
        closeTo(_bars(tester).first.width, 0.01),
        reason:
            'no inner padding must close the gap entirely, leaving the '
            'bars flank to flank',
      );
    });

    testWidgets('the outer-padding slider insets the first bar', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder gate = find.byType(FluentCheckbox).at(2);
      final Finder slider = find.byType(FluentSlider).at(3);

      await tapAndSettle(tester, gate, what: 'the outer-padding checkbox');
      // Measured after the gate, not before it: ticking the box alone turns an
      // absent padding into an explicit 0, which is a different chart. What
      // this test owns is the slider on top of that.
      final Rect first = _bars(tester).first;

      await dropSliderAt(tester, slider, 1);
      expect(tester.widget<FluentSlider>(slider).value, 1);
      expect(
        _bars(tester).first,
        isNot(first),
        reason: 'outer padding must move the first bar off the axis start',
      );

      await dropSliderAt(tester, slider, 0);
      expect(_bars(tester).first, first);
    });

    testWidgets('the tick radios swap wrapping for truncation', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder group = find.byType(FluentRadioGroup<String>);
      final int truncated = _paragraphs(tester);

      await mouseClick(tester, find.text('Wrap X Axis Ticks'));
      expect(
        tester.widget<FluentRadioGroup<String>>(group).value,
        'WrapTickValues',
      );
      expect(
        _paragraphs(tester),
        greaterThan(truncated),
        reason:
            'wrapping splits a long tick label into several lines, each of '
            'which is its own paragraph',
      );

      await mouseClick(tester, find.text('Show Tooltip at X Axis Ticks'));
      expect(_paragraphs(tester), truncated);
    });
  });

  group('vertical bar rotate labels', () {
    testWidgets('the long tick labels are rotated rather than wrapped', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('charts-verticalbarchart--vertical-bar-rotate-labels'),
      );
      final FluentXAxisLabelLayout? layout = _painter(tester).xLabelLayout;
      expect(layout, isNotNull);
      expect(
        layout!.rotationRadians,
        isNot(0),
        reason: 'rotateXAxisLables is the whole subject of this section',
      );
      expect(_bars(tester), hasLength(4));
    });
  });

  group('vertical bar styled', () {
    final DocsSection section = sectionOf(
      'charts-verticalbarchart--vertical-bar-styled',
    );

    testWidgets('the line checkbox removes the overlaid line', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_dots(tester), greaterThan(0));

      await mouseClick(tester, find.byType(FluentCheckbox).at(0));
      expect(_dots(tester), 0);

      await mouseClick(tester, find.byType(FluentCheckbox).at(0));
      expect(_dots(tester), greaterThan(0));
    });

    testWidgets('the single-colour checkbox restores the custom ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_fills(tester).toSet(), hasLength(1));

      await tapAndSettle(
        tester,
        find.byType(FluentCheckbox).at(1),
        what: 'the single-colour checkbox',
      );
      expect(_fills(tester).toSet().length, greaterThan(1));
    });
  });

  group('vertical bar dynamic', () {
    final DocsSection section = sectionOf(
      'charts-verticalbarchart--vertical-bar-dynamic',
    );

    testWidgets('the data-size slider changes the number of bars', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_bars(tester), hasLength(5));

      // Index 3 is the data-size rail: width, inner padding and outer padding
      // come first.
      await dropSliderAt(tester, find.byType(FluentSlider).at(3), 1);
      expect(_bars(tester), hasLength(50));

      await dropSliderAt(tester, find.byType(FluentSlider).at(3), 0);
      expect(
        find.descendant(
          of: find.byType(FluentVerticalBarChart),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
        reason: 'an empty series draws no plot at all, only its live region',
      );
    });

    testWidgets('the x-axis radios rebuild the axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder group = find.byType(FluentRadioGroup<String>);
      expect(_painter(tester).xAxis.tickLabels.first, isNot('Label 1'));

      await mouseClick(tester, find.text('String'));
      expect(tester.widget<FluentRadioGroup<String>>(group).value, 'string');
      // Not every category earns a tick — the band axis drops labels that would
      // collide — but every tick that is drawn must now be a category name.
      expect(_painter(tester).xAxis.tickLabels, isNotEmpty);
      expect(
        _painter(
          tester,
        ).xAxis.tickLabels.every((String label) => label.startsWith('Label ')),
        isTrue,
      );

      await mouseClick(tester, find.text('Date'));
      expect(tester.widget<FluentRadioGroup<String>>(group).value, 'date');
      expect(
        _painter(tester).xAxis.tickLabels.first,
        isNot('Label 1'),
        reason: 'a date axis must format its own ticks',
      );
    });

    testWidgets('"Change Data" and "Change Color" repaint the bars', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<Rect> shape = _bars(tester);
      final Set<Color> palette = _fills(tester).toSet();

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentButton, 'Change Data'),
        what: 'the Change Data button',
      );
      expect(_bars(tester), isNot(shape));

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentButton, 'Change Color'),
        what: 'the Change Color button',
      );
      expect(
        _fills(tester).toSet().intersection(palette),
        isEmpty,
        reason: 'the next colour set shares no token with the current one',
      );
    });

    testWidgets('the barWidth checkbox cycles default, auto and fixed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder gate = find.byType(FluentCheckbox).at(0);
      // On the string axis first: this demo's numeric x values are randomised
      // on every mount, and with them the width the auto solve lands on, so a
      // band scale is the only place the three states can be told apart by a
      // fixed number.
      await mouseClick(tester, find.text('String'));
      expect(tester.widget<FluentCheckbox>(gate).checked, isFalse);
      expect(
        _bars(tester).first.width,
        16,
        reason: 'the absent prop is 16, capped by the band width',
      );

      await mouseClick(tester, gate);
      expect(
        tester.widget<FluentCheckbox>(gate).checked,
        isNull,
        reason: "'auto' is upstream's mixed state",
      );
      expect(find.text('auto'), findsOneWidget);
      expect(
        _bars(tester).first.width,
        greaterThan(16),
        reason: "'auto' hands each bar its whole band",
      );

      await mouseClick(tester, gate);
      expect(tester.widget<FluentCheckbox>(gate).checked, isTrue);
      expect(find.byType(FluentSpinButton), findsNWidgets(2));
      expect(_bars(tester).first.width, 16);
    });

    testWidgets('the padding sliders only bite on a string axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder inner = find.byType(FluentCheckbox).at(1);

      // The checkbox itself is disabled while x is numeric — the two padding
      // props are spread into the shell only for a band scale.
      await tapAndSettle(tester, inner, what: 'the inner-padding checkbox');
      expect(tester.widget<FluentCheckbox>(inner).checked, isFalse);

      await mouseClick(tester, find.text('String'));
      await tapAndSettle(tester, inner, what: 'the inner-padding checkbox');
      expect(tester.widget<FluentCheckbox>(inner).checked, isTrue);

      final double spaced = _step(tester);
      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 0);
      expect(
        _step(tester),
        lessThan(spaced),
        reason: 'no inner padding must close the gap between the bars',
      );
    });
  });

  group('vertical bar negatives', () {
    for (final String id in <String>[
      'charts-verticalbarchart--vertical-bar-all-negative',
      'charts-verticalbarchart--vertical-bar-negative',
    ]) {
      final DocsSection section = sectionOf(id);

      testWidgets('$id rounds every bar on demand', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        final int bars = _bars(tester).length;
        expect(bars, 8);
        expect(_rounded(tester), isEmpty);

        await tapAndSettle(
          tester,
          find.byType(FluentSwitch).at(1),
          what: 'the rounded-corners switch',
        );
        expect(
          _rounded(tester),
          hasLength(bars),
          reason: 'every bar must be drawn as a rounded rect, not a plain one',
        );
        expect(
          _rounded(tester).first.blRadiusX,
          3,
          reason: "3 is upstream's own rx for a rounded bar",
        );
        expect(_bars(tester), isEmpty);

        await tapAndSettle(
          tester,
          find.byType(FluentSwitch).at(1),
          what: 'the rounded-corners switch',
        );
        expect(_bars(tester), hasLength(bars));
      });

      testWidgets('$id drops the axis titles on demand', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        final Finder titles = find.byType(FluentSwitch).at(0);
        expect(tester.widget<FluentSwitch>(titles).checked, isTrue);
        final int titled = _paragraphs(tester);

        await tapAndSettle(tester, titles, what: 'the axis-titles switch');
        expect(_paragraphs(tester), titled - 2);

        await tapAndSettle(tester, titles, what: 'the axis-titles switch');
        expect(_paragraphs(tester), titled);
      });

      testWidgets('$id commits its callout radios while staying inert', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        final Finder group = find.byType(FluentRadioGroup<String>);
        final List<Rect> before = _bars(tester);

        await mouseClick(tester, find.text('Custom Callout Example'));
        expect(
          tester.widget<FluentRadioGroup<String>>(group).value,
          'Custom Callout Example',
        );
        // The same inert pair the default section carries: upstream's story
        // comments out the renderer they select, and the port keeps both the
        // control and the inertness.
        expect(_bars(tester), before);
      });

      testWidgets('$id hides its labels and collapses its palette', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        final int bars = _bars(tester).length;
        final int labelled = _paragraphs(tester);

        await mouseClick(tester, find.byType(FluentCheckbox).at(1));
        expect(_paragraphs(tester), labelled - bars);

        expect(_fills(tester).toSet().length, greaterThan(1));
        await mouseClick(tester, find.byType(FluentCheckbox).at(0));
        expect(_fills(tester).toSet(), hasLength(1));
      });
    }
  });

  group('vertical bar chart responsive', () {
    testWidgets('the chart fills whatever box it is given', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('charts-verticalbarchart--vertical-bar-chart-responsive'),
      );
      expect(tester.getSize(find.byType(FluentVerticalBarChart)).width, 1600);
      expect(_bars(tester), hasLength(8));
      expect(
        _bars(tester).last.right,
        greaterThan(1000),
        reason: 'the bars must use the width, not sit in a 650-wide huddle',
      );
    });
  });

  group('vertical bar secondary y axis', () {
    final DocsSection section = sectionOf(
      'charts-verticalbarchart--vertical-bar-secondary-y-axis',
    );

    testWidgets('the line is plotted against a second scale', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentCartesianChartPainter painter = _painter(tester);
      expect(painter.yAxisSecondary, isNotNull);
      expect(
        painter.yAxisSecondary!.tickLabels,
        isNot(painter.yAxisPrimary.tickLabels),
        reason: 'a secondary axis over its own domain must label differently',
      );
    });

    testWidgets('the sliders resize the plot', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentVerticalBarChart);
      expect(tester.getSize(chart), const Size(700, 300));

      await dropSliderAt(tester, find.byType(FluentSlider).at(0), 0);
      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(tester.getSize(chart).width, 200);
      expect(tester.getSize(chart).height, greaterThan(900));
    });
  });

  group('sizing', () {
    testWidgets('every width and height rail on the page moves the chart', (
      WidgetTester tester,
    ) async {
      // Found by the label the demo gives them rather than by position: the
      // dynamic section has a width rail and no height rail, and the tooltip
      // section puts two padding rails after them.
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final Finder chart = find.byType(FluentVerticalBarChart);

        final Finder width = _rail('Change Width');
        if (width.evaluate().isNotEmpty) {
          await dropSliderAt(tester, width, 0);
          expect(tester.getSize(chart).width, 200, reason: section.id);
        }
        final Finder height = _rail('Change Height');
        if (height.evaluate().isNotEmpty) {
          await dropSliderAt(tester, height, 1);
          expect(
            tester.getSize(chart).height,
            greaterThan(900),
            reason: section.id,
          );
        }
      }
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The chart's display list.
///
/// The plot is the first `CustomPaint` under the chart; the legend's swatches
/// are the others, and they come after it in tree order.
List<RecordedInvocation> _ops(WidgetTester tester) => paintOps(
  tester,
  find.descendant(
    of: find.byType(FluentVerticalBarChart),
    matching: find.byType(CustomPaint),
  ),
);

/// Every square-cornered bar the chart drew, in paint order.
List<Rect> _bars(WidgetTester tester) => <Rect>[
  for (final ({Paint paint, Rect rect}) mark in paintedRects(_ops(tester)))
    mark.rect,
];

/// The rounded bars, which are drawn as RRects and so are absent from [_bars].
List<RRect> _rounded(WidgetTester tester) =>
    opArgs<RRect>(_ops(tester), #drawRRect);

/// The fill each bar was painted with, alpha included.
List<Color> _fills(WidgetTester tester) => <Color>[
  for (final ({Paint paint, Rect rect}) mark in paintedRects(_ops(tester)))
    mark.paint.color,
];

/// How many bars are at full opacity — the legend-highlight count.
///
/// A dimmed bar keeps its colour and drops to a tenth of its alpha
/// (`barOpacity` under `WidgetState.disabled`), so alpha is the only place a
/// legend selection reaches the canvas.
int _highlighted(WidgetTester tester) =>
    _fills(tester).where((Color color) => color.a > 0.5).length;

/// The height of the tallest bar.
double _tallest(WidgetTester tester) => _bars(
  tester,
).fold(0, (double best, Rect bar) => bar.height > best ? bar.height : best);

/// Every line-marker circle. The overlaid line draws a fill and a ring per dot.
int _dots(WidgetTester tester) => countOps(_ops(tester), #drawCircle);

/// The stroked paths: the line and the halo under it.
int _paths(WidgetTester tester) => countOps(_ops(tester), #drawPath);

/// Every run of text the chart painted — tick labels, bar labels, axis titles.
int _paragraphs(WidgetTester tester) => countOps(_ops(tester), #drawParagraph);

/// The distance between the starts of two neighbouring bars.
double _step(WidgetTester tester) {
  final List<Rect> bars = _bars(tester);
  return bars[1].left - bars[0].left;
}

/// The slider a demo labelled [semanticLabel], wherever it sits in its row.
Finder _rail(String semanticLabel) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentSlider && widget.semanticLabel == semanticLabel,
);

/// The painter the chart handed the canvas, for the geometry no display list
/// spells out: tick labels, the rotated-label layout, the secondary axis.
FluentCartesianChartPainter _painter(WidgetTester tester) =>
    paintersOf<FluentCartesianChartPainter>(tester).first;

/// The titles of the legend rows that stand for a bar series, in strip order.
///
/// The line's own legend is dropped: pressing it dims the polyline and leaves
/// every bar at full opacity, which is not what [_highlighted] counts. Titles
/// rather than finders, because pressing one rebuilds the whole strip and a
/// `find.byWidget` on the old row would then match nothing.
List<String> _barLegendTitles(WidgetTester tester) => <String>[
  for (final FluentChartLegendRow row
      in tester.widgetList<FluentChartLegendRow>(
        find.byType(FluentChartLegendRow),
      ))
    if (row.item.title != 'just line') row.item.title,
];

/// The legend row titled [title], re-resolved on every call.
Finder _legendRow(String title) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentChartLegendRow && widget.item.title == title,
);
