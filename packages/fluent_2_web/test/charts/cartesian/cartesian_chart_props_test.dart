import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell's config bag. Two of its members are *resolvers*, not fields,
/// because upstream computes them with expressions that carry defects the port
/// reproduces: the `tickPadding` precedence bug at `CartesianChart.tsx:215`
/// and the `hideTickOverlap` override at `:220`.
void main() {
  group('FluentCartesianChartProps defaults', () {
    const props = FluentCartesianChartProps();

    test('carries the code-verified defaults, not the doc-comment ones', () {
      expect(
        props.hideTickOverlap,
        isTrue,
        reason: 'destructured on the component itself, CartesianChart.tsx:51',
      );
      expect(
        props.xAxisTickCount,
        6,
        reason: 'utilities.ts:285 reads `xAxisCount ?? 6`',
      );
      expect(
        props.xAxistickSize,
        6,
        reason:
            'utilities.ts:266 — the doc at CartesianChart.types.ts:314 says 10 '
            'and is wrong',
      );
      expect(
        props.yAxisTickCount,
        4,
        reason: 'destructure default in createNumericYAxis, utilities.ts:811',
      );
      expect(
        props.noOfCharsToTruncate,
        4,
        reason: 'CartesianChart.tsx:153 reads `|| 4`',
      );
      expect(
        props.showRoundOffXTickValues,
        isTrue,
        reason: 'CartesianChart.tsx:212 reads `?? true`',
      );
      expect(
        props.reflowMode,
        FluentChartReflowMode.none,
        reason: 'CartesianChart.types.ts:417',
      );
      expect(
        props.yMinValue,
        0,
        reason: 'CartesianChart.tsx:302 reads `props.yMinValue || 0`',
      );
      expect(props.yMaxValue, 0, reason: 'CartesianChart.tsx:303');
      expect(
        props.enableFirstRenderOptimization,
        isFalse,
        reason: 'CartesianChart.tsx:190 treats absence as false',
      );
      expect(
        props.annotations,
        isEmpty,
        reason: 'CartesianChart.tsx:463 reads `?? []`',
      );
    });

    test('secondary scale bounds default to 0 and 100, not 0 and 0', () {
      const options = FluentSecondaryYScaleOptions();
      expect(
        options.yMinValue,
        0,
        reason: 'CartesianChart.tsx:344 reads `|| 0`',
      );
      expect(
        options.yMaxValue,
        100,
        reason:
            'CartesianChart.tsx:345 reads `?? 100` — the only non-zero y bound '
            'default in the shell',
      );
    });
  });

  group('resolvedXAxisTickPadding reproduces the precedence defect', () {
    test('neither set gives 10', () {
      expect(
        const FluentCartesianChartProps().resolvedXAxisTickPadding,
        10,
        reason: 'CartesianChart.tsx:215 falls to the else arm',
      );
    });

    test('a user value is discarded and collapses to 5', () {
      expect(
        const FluentCartesianChartProps(
          tickPadding: 12,
        ).resolvedXAxisTickPadding,
        5,
        reason:
            'parity: JS parses `a || b ? 5 : 10` as `(a || b) ? 5 : 10`, so 12 '
            'is thrown away (CartesianChart.tsx:215)',
      );
    });

    test('an explicit zero is JS-falsy and does NOT collapse', () {
      expect(
        const FluentCartesianChartProps(
          tickPadding: 0,
        ).resolvedXAxisTickPadding,
        10,
        reason:
            '0 is falsy in JavaScript, so `props.tickPadding || ...` skips it '
            '(CartesianChart.tsx:215)',
      );
    });

    test('the tooltip flag alone collapses it to 5', () {
      expect(
        const FluentCartesianChartProps(
          showXAxisLablesTooltip: true,
        ).resolvedXAxisTickPadding,
        5,
        reason: 'the second operand of the || at CartesianChart.tsx:215',
      );
    });

    test('it agrees with the plan-03 resolver it delegates to', () {
      for (final tickPadding in <double?>[null, 0, 12, -3]) {
        for (final showTooltip in <bool>[false, true]) {
          expect(
            FluentCartesianChartProps(
              tickPadding: tickPadding,
              showXAxisLablesTooltip: showTooltip,
            ).resolvedXAxisTickPadding,
            resolveShellXAxisTickPadding(
              tickPadding: tickPadding,
              showXAxisLablesTooltip: showTooltip,
            ),
            reason:
                'the shell must not fork axis_builders.dart:33 — tickPadding '
                '$tickPadding, showXAxisLablesTooltip $showTooltip',
          );
        }
      }
    });
  });

  group('resolveHideTickOverlap', () {
    test('passes the field through on the default tick layout', () {
      expect(
        const FluentCartesianChartProps().resolveHideTickOverlap(
          FluentTickLayout.defaultLayout,
        ),
        isTrue,
        reason: 'CartesianChart.tsx:220 falls through to the destructured true',
      );
    });

    test('rotation disables it', () {
      expect(
        const FluentCartesianChartProps(
          rotateXAxisLables: true,
        ).resolveHideTickOverlap(FluentTickLayout.defaultLayout),
        isFalse,
        reason: 'first arm of the ternary at CartesianChart.tsx:220',
      );
    });

    test('the auto tick layout disables it', () {
      expect(
        const FluentCartesianChartProps().resolveHideTickOverlap(
          FluentTickLayout.auto,
        ),
        isFalse,
        reason: 'second arm of the ternary at CartesianChart.tsx:220',
      );
    });

    test('an opted-out field survives the default tick layout', () {
      expect(
        const FluentCartesianChartProps(
          hideTickOverlap: false,
        ).resolveHideTickOverlap(FluentTickLayout.defaultLayout),
        isFalse,
        reason:
            'the else arm at CartesianChart.tsx:220 is the destructured value, '
            'not a hard-coded true',
      );
    });
  });

  group('the six hooks the shell charts set', () {
    test('every hook defaults to upstream absence', () {
      const props = FluentCartesianChartProps();
      expect(
        props.chartTitleForSemantics,
        isNull,
        reason:
            "`props.chartTitle || 'Chart. '` at CartesianChart.tsx:553 — absent "
            'means the generic prefix',
      );
      expect(
        props.eventLabelHeight,
        isNull,
        reason:
            'no caller ever populates eventAnnotationProps on IYAxisParams, so '
            'the reserve at utilities.ts:848 never runs',
      );
      expect(
        props.popoverBuilder,
        isNull,
        reason:
            'customizedCallout is undefined unless a chart renders one, '
            'ChartPopover.tsx:54',
      );
      expect(
        props.hitRegionGranularity,
        FluentChartHitGranularity.mark,
        reason:
            '`isCalloutForStack` defaults to false, '
            'CartesianChart.types.ts:666-670',
      );
      expect(
        props.closePopoverOnRegionExit,
        isFalse,
        reason:
            'every per-mark leave handler except the one in '
            'HorizontalBarChartWithAxis is an empty stub, e.g. '
            'VerticalBarChart.tsx:496-498',
      );
      expect(
        props.popoverAnchorsToRegion,
        isFalse,
        reason:
            'ChartPopover.tsx:23-40 anchors to a zero-size virtual element at '
            'the pointer unless a chart supplies a target',
      );
    });

    test('copyWith replaces one field and carries the rest through', () {
      const base = FluentCartesianChartProps(
        hideLegend: true,
        xAxisTitle: 'Time',
        tickPadding: 12,
      );
      final copy = base.copyWith(
        chartTitleForSemantics: 'Line chart with 2 lines. ',
      );
      expect(
        copy.chartTitleForSemantics,
        'Line chart with 2 lines. ',
        reason: 'the sentence LineChart.tsx:1843-1846 composes',
      );
      expect(
        copy.hideLegend,
        isTrue,
        reason:
            'the caller-supplied bag survives, or every chart would silently '
            'reset the props its own caller passed in',
      );
      expect(
        copy.xAxisTitle,
        'Time',
        reason: 'the same, for a nullable field that was set',
      );
      expect(
        copy.tickPadding,
        12,
        reason: 'and for the one GroupedVerticalBarChart.tsx:1006 rebrands',
      );
      expect(
        copy.eventLabelHeight,
        isNull,
        reason: 'an omitted parameter is not a null assignment',
      );
    });
  });
}
