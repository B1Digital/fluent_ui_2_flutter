import 'package:fluent_2_web/src/charts/chrome/chart_title.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
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
}
