import 'dart:ui' show PictureRecorder;

import 'package:fluent_2/src/charts/chrome/chart_title.dart';
import 'package:fluent_2/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2/src/charts/internal/d3/axis_geometry.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// Segoe UI's `hhea` ascender, against a `unitsPerEm` of 2048.
///
/// The capture browser resolved Segoe UI and rounds the scaled ascent and
/// descent to whole device pixels at DPR 1, which is why the two are rounded
/// separately below. Not taken on faith: the `alphabetic` test reads the ascent
/// straight off three `auto` labels of one story, and
/// `the capture font's line box` checks
/// `round(ascent) + round(descent) == bbox.height` on every `<text>` in the
/// corpus.
const double _captureAscender = 2210 / 2048;

/// Segoe UI's `hhea` descender over the same `unitsPerEm`. See
/// [_captureAscender].
const double _captureDescender = 514 / 2048;

/// The metrics the capture browser measured [element]'s glyphs with.
///
/// [FluentChartTextMetrics.width] is the captured ink width, which no baseline
/// offset reads; the vertical numbers are the ones under test.
FluentChartTextMetrics _captureMetrics(OracleElement element) {
  final ascent = (element.fontSize * _captureAscender).roundToDouble();
  final descent = (element.fontSize * _captureDescender).roundToDouble();
  return FluentChartTextMetrics(
    width: element.bbox!.width,
    height: ascent + descent,
    ascent: ascent,
    descent: descent,
    xHeight: element.fontSize * FluentChartTextMetrics.xHeightRatio,
  );
}

/// Where the capture put the top of [element]'s line box: `bbox.top`.
double _capturedLineBoxTop(OracleElement element) => element.bbox!.top;

/// Where [baseline] predicts the top of [element]'s line box is.
///
/// The captured `bbox` of a `<text>` is its ascent-plus-descent box, so its top
/// is one ascent above the alphabetic baseline, and the alphabetic baseline is
/// [fluentChartBaselineOffset] below the element's own `y`.
double _predictedLineBoxTop(
  OracleElement element,
  FluentChartTitleBaseline baseline,
) {
  final metrics = _captureMetrics(element);
  return element.y! +
      fluentChartBaselineOffset(baseline, metrics) -
      metrics.ascent;
}

void main() {
  // Segoe UI at 10px, the axis-tick size: ascent 0.9954em, descent 0.2129em,
  // x-height 0.5em. The numbers are the ones spec section 8 quotes.
  const metrics = FluentChartTextMetrics(
    width: 40,
    height: 12.083,
    ascent: 9.954,
    descent: 2.129,
    xHeight: 5,
  );

  group('fluentChartBaselineOffset', () {
    test('alphabetic is the identity', () {
      expect(
        fluentChartBaselineOffset(FluentChartTitleBaseline.alphabetic, metrics),
        0,
        reason:
            "SVG 'alphabetic', and the 'auto' that ChartTitle.tsx:74 falls "
            'back to, both place the text on its own alphabetic baseline, '
            'which is where TextPainter already draws it.',
      );
    });

    test('central is the em-box midpoint', () {
      expect(
        fluentChartBaselineOffset(FluentChartTitleBaseline.central, metrics),
        moreOrLessEquals((9.954 - 2.129) / 2, epsilon: 0.001),
        reason:
            "SVG 'central' aligns the midpoint of the em box with the given y, "
            'so the baseline sits (ascent - descent) / 2 below it. '
            'ChartTitle.tsx:72-73 selects it for titleYAnchor middle.',
      );
    });

    test('middle is the x-height midpoint and is NOT central', () {
      final central = fluentChartBaselineOffset(
        FluentChartTitleBaseline.central,
        metrics,
      );
      final middle = fluentChartBaselineOffset(
        FluentChartTitleBaseline.middle,
        metrics,
      );
      expect(
        middle,
        moreOrLessEquals(5 / 2, epsilon: 0.001),
        reason:
            "SVG 'middle' aligns the midpoint between the alphabetic baseline "
            'and the x-height, so the offset is xHeight / 2.',
      );
      expect(
        central - middle,
        moreOrLessEquals(1.4125, epsilon: 0.001),
        reason:
            'Spec section 8 puts the gap at roughly 2px for 10px Segoe. '
            'Treating the two as interchangeable would shift nine label sites '
            'by that much.',
      );
    });

    test('hanging comes from the metrics rather than being re-derived', () {
      expect(
        fluentChartBaselineOffset(FluentChartTitleBaseline.hanging, metrics),
        moreOrLessEquals(metrics.ascent - metrics.hangingOffset, epsilon: 1e-9),
        reason:
            'FluentChartTextMetrics owns the three non-trivial offsets '
            '(contract section 4.3), each measured down from the top of the '
            'line box; this helper only turns them round — the distance down '
            'from y at which the alphabetic baseline lands — and supplies the '
            'fourth.',
      );
      expect(
        fluentChartBaselineOffset(FluentChartTitleBaseline.hanging, metrics),
        moreOrLessEquals(
          FluentChartTextMetrics.hangingBaselineRatio * 9.954,
          epsilon: 0.001,
        ),
        reason:
            'The hanging baseline sits four fifths of the ascent above the '
            'alphabetic one, so putting it on y pushes the alphabetic baseline '
            'that far below y.',
      );
    });

    test('every value is one metrics offset turned round', () {
      expect(
        <FluentChartTitleBaseline, double>{
          for (final baseline in FluentChartTitleBaseline.values)
            baseline: fluentChartBaselineOffset(baseline, metrics),
        },
        <FluentChartTitleBaseline, double>{
          FluentChartTitleBaseline.hanging:
              metrics.ascent - metrics.hangingOffset,
          FluentChartTitleBaseline.central:
              metrics.ascent - metrics.centralOffset,
          FluentChartTitleBaseline.middle:
              metrics.ascent - metrics.middleOffset,
          FluentChartTitleBaseline.alphabetic:
              metrics.ascent - metrics.alphabeticOffset,
        },
        reason:
            'Four values, one rule: nothing here may grow a formula of its '
            'own, or the nine painted sites drift apart again (spec section 8).',
      );
    });
  });

  group('fluentChartBaselineOffset against the Oracle B capture', () {
    test("the capture font's line box is round(ascent) + round(descent)", () {
      var checked = 0;
      for (final id in oracleStoryIds()) {
        final story = loadOracleStory(id);
        for (final svg in story.svgs) {
          for (final element in svg.elements) {
            final bbox = element.bbox;
            // An empty <text> measures 0 high and says nothing about the font.
            if (element.tag != 'text' ||
                bbox == null ||
                bbox.height == 0 ||
                element.fontSize == 0) {
              continue;
            }
            checked++;
            expectOracleNumber(
              '$id <text> #${element.index} bbox.height',
              _captureMetrics(element).height,
              bbox.height,
              tolerance: kOracleMeasuredTolerance,
            );
          }
        }
      }
      expect(
        checked,
        1232,
        reason:
            'The whole corpus of measured text, so the two font constants are '
            'pinned by 1232 boxes across six font sizes rather than by the one '
            'element each baseline test picks.',
      );
    });

    test('alphabetic: four auto labels sit on their own baseline', () {
      // GaugeChart draws its own labels rather than a d3 axis, so none of these
      // carries the `dy="0.71em"` a tick label would (`d3-axis/src/axis.js`),
      // and `y - bbox.top` is the ascent outright.
      final story = loadOracleStory(
        'charts-gaugechart--gauge-chart-single-segment',
      );
      final labels = story
          .byTag('text')
          .where(
            (element) =>
                element.dominantBaseline == 'auto' && element.bbox != null,
          )
          .toList();
      expect(
        labels.length,
        4,
        reason:
            "The 'Storage capacity' title at 10px (GaugeChart.tsx renders it "
            'through ChartTitle), the 0 and 100 min and max labels at 12px and '
            "the '50/100' value at 20px — three font sizes, one story, so the "
            'ascent is read at three scales rather than one.',
      );
      for (final label in labels) {
        expectOracleNumber(
          "'${label.text}' at ${label.fontSize}px, line-box top",
          _capturedLineBoxTop(label),
          _predictedLineBoxTop(label, FluentChartTitleBaseline.alphabetic),
          tolerance: kOracleMeasuredTolerance,
        );
      }
    });

    test('central: the HorizontalBarChart value label centres its em box', () {
      // HorizontalBarChart.tsx:296.
      final story = loadOracleStory(
        'charts-horizontalbarchart--horizontal-bar-absolute-scale',
      );
      final label = story.soleElement(
        'text',
        where: (element) => element.dominantBaseline == 'central',
      );
      expectOracleNumber(
        "'${label.text}' line-box top, central",
        _capturedLineBoxTop(label),
        _predictedLineBoxTop(label, FluentChartTitleBaseline.central),
        tolerance: kOracleMeasuredTolerance,
      );
      expect(
        _predictedLineBoxTop(label, FluentChartTitleBaseline.central),
        moreOrLessEquals(
          label.y! - _captureMetrics(label).height / 2,
          epsilon: 1e-9,
        ),
        reason:
            'Centring the em box on y is the same statement as the line box '
            'straddling y, which is what the captured bbox shows: y = 6, '
            'bbox.top = -2, bbox.height = 16.',
      );
    });

    test('middle: the donut inside string sits on its x-height midpoint', () {
      // Pie.tsx:107 — `<text y={5} dominantBaseline="middle">`, 28px.
      final story = loadOracleStory('charts-donutchart--donut-chart-basic');
      final label = story.soleElement(
        'text',
        where: (element) => element.dominantBaseline == 'middle',
      );
      expectOracleNumber(
        "'${label.text}' line-box top, middle",
        _capturedLineBoxTop(label),
        _predictedLineBoxTop(label, FluentChartTitleBaseline.middle),
        tolerance: kOracleMeasuredTolerance,
      );
      expect(
        (_capturedLineBoxTop(label) -
                _predictedLineBoxTop(label, FluentChartTitleBaseline.central))
            .abs(),
        greaterThan(kOracleMeasuredTolerance),
        reason:
            'The discriminating case: painting this 28px string as `central` '
            'misses the capture by 4.5px, so spec section 8 is right that the '
            'two are not interchangeable.',
      );
    });

    test('hanging: the gauge sub-label hangs below its y', () {
      // GaugeChart.tsx:692 — the 'used' sub-label at y = 4, 12px.
      final story = loadOracleStory(
        'charts-gaugechart--gauge-chart-single-segment',
      );
      final label = story.soleElement(
        'text',
        where: (element) => element.dominantBaseline == 'hanging',
      );
      expectOracleNumber(
        "'${label.text}' line-box top, hanging",
        _capturedLineBoxTop(label),
        _predictedLineBoxTop(label, FluentChartTitleBaseline.hanging),
        tolerance: kOracleMeasuredTolerance,
      );
      expect(
        (_capturedLineBoxTop(label) -
                _predictedLineBoxTop(
                  label,
                  FluentChartTitleBaseline.alphabetic,
                ))
            .abs(),
        greaterThan(kOracleMeasuredTolerance),
        reason:
            'Blessing the browser fallback of four fifths of the ascent: '
            'ignoring it and painting on the alphabetic baseline misses the '
            'capture by 10.4px at 12px.',
      );
    });
  });

  group('fluentChartBaselineOffset on measured text', () {
    // The axis-tick slot, as chart_text_measurer_test.dart uses it: Selawik
    // 10/semibold, whose hhea ascent is 2027 and descent 431 over a unitsPerEm
    // of 2048.
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      fontFamily: 'Selawik',
    );

    test('orders the four baselines as SVG does', () {
      final measured = FluentChartTextMeasurer().measure('Jan', style);
      final offsets = <FluentChartTitleBaseline, double>{
        for (final baseline in FluentChartTitleBaseline.values)
          baseline: fluentChartBaselineOffset(baseline, measured),
      };
      expect(
        <double>[
          offsets[FluentChartTitleBaseline.alphabetic]!,
          offsets[FluentChartTitleBaseline.middle]!,
          offsets[FluentChartTitleBaseline.central]!,
          offsets[FluentChartTitleBaseline.hanging]!,
        ],
        orderedEquals(<Matcher>[
          moreOrLessEquals(0, epsilon: 1e-9),
          moreOrLessEquals(measured.xHeight / 2, epsilon: 1e-9),
          moreOrLessEquals(
            (measured.ascent - measured.descent) / 2,
            epsilon: 1e-9,
          ),
          moreOrLessEquals(
            FluentChartTextMetrics.hangingBaselineRatio * measured.ascent,
            epsilon: 1e-9,
          ),
        ]),
        reason:
            'Real font metrics, one measurer: alphabetic pushes the baseline '
            'nowhere, middle by half the x-height, central by half the em box '
            'and hanging by four fifths of the ascent — strictly increasing '
            'for any font whose ascent exceeds its x-height.',
      );
      expect(
        offsets.values.toList()..sort(),
        orderedEquals(<double>[
          offsets[FluentChartTitleBaseline.alphabetic]!,
          offsets[FluentChartTitleBaseline.middle]!,
          offsets[FluentChartTitleBaseline.central]!,
          offsets[FluentChartTitleBaseline.hanging]!,
        ]),
        reason:
            'Sorting must not reorder them: a chart that mixed two of these up '
            'would paint low rather than fail loudly.',
      );
    });
  });

  group('fluentChartTitleBackgroundRect', () {
    test('is asymmetric exactly as SVGTooltipText.tsx:169-179 writes it', () {
      final rect = fluentChartTitleBackgroundRect(
        const Offset(100, 50),
        const Size(60, 16),
      );
      expect(
        rect.left,
        100 - 60 / 2 - kChartTitleBackgroundPadding,
        reason: 'SVGTooltipText.tsx:169 — `x - textWidth / 2 - PADDING`.',
      );
      expect(
        rect.top,
        50 - 16 / 2 - 2 * kChartTitleBackgroundPadding,
        reason:
            'SVGTooltipText.tsx:170 — `y - textHeight / 2 - 2 * PADDING`. The '
            'vertical inset is twice the horizontal one, deliberately.',
      );
      expect(
        rect.width,
        60 + 2 * kChartTitleBackgroundPadding,
        reason: 'SVGTooltipText.tsx:178 — `textWidth + 2 * PADDING`.',
      );
      expect(
        rect.height,
        16 + kChartTitleBackgroundPadding,
        reason:
            'SVGTooltipText.tsx:179 — `textHeight + PADDING`, ONE padding, not '
            'two. The rect is lifted by 6 but grows by only 3, so it sits high '
            'of centre. Reproduced, not corrected.',
      );
    });

    test('PADDING is 3', () {
      expect(
        kChartTitleBackgroundPadding,
        3,
        reason: 'SVGTooltipText.tsx:43 — `const PADDING = 3`.',
      );
    });

    test('the horizontal centring ignores the text anchor', () {
      expect(
        fluentChartTitleBackgroundRect(
          const Offset(100, 50),
          const Size(60, 16),
        ).center.dx,
        100,
        reason:
            'SVGTooltipText.tsx:169 always subtracts half the width, so the '
            'rect is centred on x whatever the text anchor is. A start-anchored '
            'title therefore has its backing rect offset by half its width. '
            '// parity: reproduced.',
      );
    });

    test('matches the gauge chart title backdrop the capture rendered', () {
      // `GaugeChart.tsx` renders its title through `ChartTitle`, which passes
      // `showBackground: true` (`ChartTitle.tsx:91`), so the capture carries
      // the real `<rect>` upstream computed — element 1 — immediately before
      // the `<text>` it backs — element 2 — inside the same `<g>`, hence the
      // same coordinate space.
      final story = loadOracleStory(
        'charts-gaugechart--gauge-chart-single-segment',
      );
      final title = story.soleElement(
        'text',
        where: (element) => element.text == 'Storage capacity',
      );
      final backdrop = story.soleElement('rect');
      // `SVGTooltipText.tsx:58-63` feeds the rect from the text's own
      // `getBBox()`, which is the ascent-plus-descent box the capture recorded.
      final bbox = title.bbox!;
      final predicted = fluentChartTitleBackgroundRect(
        Offset(title.x!, title.y!),
        Size(bbox.width, bbox.height),
      );
      expect(
        backdrop.index,
        lessThan(title.index),
        reason:
            'SVGTooltipText.tsx:174-183 emits the rect before the Tooltip that '
            'wraps the text, so the text paints on top of it.',
      );
      expectOracleRect(
        'gauge title backdrop',
        Rect.fromLTWH(
          backdrop.x!,
          backdrop.y!,
          backdrop.width!,
          backdrop.height!,
        ),
        predicted,
      );
      expect(
        <double>[predicted.left, predicted.top, bbox.width, bbox.height],
        <double>[-40.609375, -86, 75.21875, 14],
        reason:
            'Pinning the arithmetic in the open so the assertion above cannot '
            'pass vacuously: the title sits at x = 0, y = -73 with a 75.21875 x '
            '14 box, so the rect lands at (0 - 37.609375 - 3, -73 - 7 - 6) and '
            'measures 81.21875 x 17 — three pixels wider each side, six above '
            'and none below.',
      );
    });
  });

  group('FluentChartTitlePainter', () {
    final measurer = FluentChartTextMeasurer();
    const style = TextStyle(fontSize: 12);

    test('shouldRepaint tracks the text, the anchor and the rotation', () {
      final base = FluentChartTitlePainter(
        text: 'Revenue',
        style: style,
        anchor: const Offset(100, 20),
        textAnchor: FluentAxisTextAnchor.middle,
        baseline: FluentChartTitleBaseline.alphabetic,
        rotationRadians: 0,
        showBackground: true,
        backgroundColor: const Color(0xFFFFFFFF),
        measurer: measurer,
      );
      expect(
        base.shouldRepaint(
          FluentChartTitlePainter(
            text: 'Revenue',
            style: style,
            anchor: const Offset(100, 20),
            textAnchor: FluentAxisTextAnchor.middle,
            baseline: FluentChartTitleBaseline.alphabetic,
            rotationRadians: 0,
            showBackground: true,
            backgroundColor: const Color(0xFFFFFFFF),
            measurer: measurer,
          ),
        ),
        isFalse,
        reason: 'Identical inputs must not repaint.',
      );
      expect(
        base.shouldRepaint(
          FluentChartTitlePainter(
            text: 'Revenue',
            style: style,
            anchor: const Offset(100, 20),
            textAnchor: FluentAxisTextAnchor.middle,
            baseline: FluentChartTitleBaseline.alphabetic,
            // The y-axis title is drawn rotated (CartesianChart.tsx:879).
            rotationRadians: -1.5707963267948966,
            showBackground: true,
            backgroundColor: const Color(0xFFFFFFFF),
            measurer: measurer,
          ),
        ),
        isTrue,
        reason: 'A rotation change moves every pixel.',
      );
    });

    testWidgets('paints the backing rect before the text', (tester) async {
      const inkColour = Color(0xFF000000);
      const backdropColour = Color(0xFFFF0000);
      const inked = TextStyle(fontSize: 12, color: inkColour);
      const anchor = Offset(60, 20);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      FluentChartTitlePainter(
        text: 'Revenue',
        style: inked,
        anchor: anchor,
        textAnchor: FluentAxisTextAnchor.middle,
        baseline: FluentChartTitleBaseline.alphabetic,
        rotationRadians: 0,
        showBackground: true,
        backgroundColor: backdropColour,
        measurer: measurer,
      ).paint(canvas, const Size(120, 40));
      final picture = recorder.endRecording();
      // `Picture.toImage` is completed by the engine, and the widget binding's
      // fake async never pumps that completion, so it must run for real.
      final pixels = (await tester.runAsync(() async {
        final image = await picture.toImage(120, 40);
        final bytes = await image.toByteData();
        image.dispose();
        return bytes;
      }))!;
      picture.dispose();
      // `toByteData` defaults to `rawRgba`, so the alpha byte moves to the top
      // to give the 0xAARRGGBB that `toARGB32` returns.
      int pixelAt(int x, int y) {
        final base = (y * 120 + x) * 4;
        return pixels.getUint8(base + 3) << 24 |
            pixels.getUint8(base) << 16 |
            pixels.getUint8(base + 1) << 8 |
            pixels.getUint8(base + 2);
      }

      final metrics = measurer.measure('Revenue', inked);
      final rect = fluentChartTitleBackgroundRect(
        Offset.zero,
        Size(metrics.width, metrics.height),
      ).shift(anchor);
      // Inside the rect's three-pixel left pad, so the glyphs cannot reach it.
      expect(
        pixelAt(rect.left.round() + 1, rect.center.dy.round()),
        backdropColour.toARGB32(),
        reason:
            'The backdrop must actually cover its rect: 0xFFFF0000 here proves '
            'the drawRect of SVGTooltipText.tsx:175-182 happened at the '
            'computed geometry rather than nowhere.',
      );
      var inkPixels = 0;
      for (var y = rect.top.round(); y < rect.bottom.round(); y++) {
        for (var x = rect.left.round(); x < rect.right.round(); x++) {
          if (pixelAt(x, y) != backdropColour.toARGB32()) {
            inkPixels++;
          }
        }
      }
      expect(
        inkPixels,
        greaterThan(0),
        reason:
            'Order, not merely presence: had the rect been filled after the '
            'text, every pixel inside it would be the backdrop and the title '
            'would have vanished. SVGTooltipText.tsx:174-183 emits the rect '
            'before the Tooltip that wraps the <text>, so the text is on top.',
      );
    });
  });

  group('fluentChartTitleDefaultY', () {
    test('is fontSize + 8, floored at 12', () {
      expect(
        fluentChartTitleDefaultY(13),
        21,
        reason:
            'ChartTitle.tsx:82-85 — max(fontSize + AXIS_TITLE_PADDING, '
            'CHART_TITLE_PADDING - AXIS_TITLE_PADDING) = max(13 + 8, 20 - 8).',
      );
      expect(
        fluentChartTitleDefaultY(null),
        21,
        reason:
            'ChartTitle.tsx:83 defaults a missing font size to 13, so the '
            'result is the same 21.',
      );
      expect(
        fluentChartTitleDefaultY(2),
        12,
        reason:
            'The 12 floor only binds below a 4px font, which no chart ships. '
            'It is ported because it is cheap and the alternative is an '
            'unexplained absence.',
      );
    });

    test('the two paddings are distinct constants', () {
      expect(
        kChartTitleAxisPadding,
        8,
        reason:
            'ChartTitle.tsx:8 declares its OWN AXIS_TITLE_PADDING, module-local '
            "and distinct from CartesianChart's copy.",
      );
      expect(
        kChartTitlePadding,
        20,
        reason: 'Common.styles.ts:10 — CHART_TITLE_PADDING.',
      );
    });
  });

  group('FluentChartTitle', () {
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: Center(child: child),
      ),
    );

    testWidgets('renders caption2Strong by default', (tester) async {
      await pump(tester, const FluentChartTitle(title: 'Revenue'));
      expect(
        tester.widget<Text>(find.text('Revenue')).style!.fontWeight,
        theme.typography.caption2Strong.fontWeight,
        reason:
            'Common.styles.ts:85 gives getChartTitleStyles typographyStyles'
            '.caption2Strong, which is what FluentChartTextStyles.chartTitle '
            'resolves to.',
      );
    });

    testWidgets('centres the title', (tester) async {
      await pump(tester, const FluentChartTitle(title: 'Revenue'));
      expect(
        tester.widget<Text>(find.text('Revenue')).textAlign,
        TextAlign.center,
        reason: 'Common.styles.ts:88 — `textAlign: center`.',
      );
    });

    testWidgets('truncates to maxWidth with an ellipsis', (tester) async {
      await pump(
        tester,
        const FluentChartTitle(
          title: 'A very long chart title indeed',
          maxWidth: 40,
        ),
      );
      expect(
        tester.widget<Text>(find.textContaining('...')).data,
        endsWith('...'),
        reason:
            'wrapContent (utilities.ts:1232-1248) shaves one character at a '
            'time and re-appends the ellipsis, which shrinkToFit ports; a '
            'title narrower than its box ends in one.',
      );
      expect(
        find.text('A very long chart title indeed'),
        findsNothing,
        reason:
            'Guard against a vacuous pass: the untruncated title must be gone, '
            'or the ellipsis assertion above could be matching the full string.',
      );
    });

    testWidgets('leaves a short title untouched', (tester) async {
      await pump(
        tester,
        const FluentChartTitle(title: 'Revenue', maxWidth: 400),
      );
      expect(
        tester.widget<Text>(find.text('Revenue')).data,
        'Revenue',
        reason:
            'shrinkToFit returns its input verbatim when it already fits '
            '(utilities.ts:1237), so maxWidth alone must not add an ellipsis.',
      );
    });

    testWidgets('reserves the 8px bottom margin', (tester) async {
      await pump(tester, const FluentChartTitle(title: 'Revenue'));
      expect(
        tester
            .widgetList<Padding>(find.byType(Padding))
            .map((p) => p.padding)
            .contains(const EdgeInsets.only(bottom: FluentSpacing.s)),
        isTrue,
        reason:
            'Common.styles.ts:89 — `marginBottom: spacingVerticalS`, which is 8.',
      );
    });

    testWidgets('honours an overriding textStyle', (tester) async {
      await pump(
        tester,
        const FluentChartTitle(
          title: 'Revenue',
          textStyle: TextStyle(fontSize: 31),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Revenue')).style!.fontSize,
        31,
        reason:
            'The chart supplies the resolved title style when it has one; the '
            'theme lookup is only the default.',
      );
    });
  });
}
