// The margin solve is five steps in a fixed order and the order is the whole
// behaviour: the right-to-left swap happens at step 4, *before* the caller's
// override at step 5, which is why a caller-supplied margin is physical rather
// than directional (`CartesianChart.tsx:661-668`).
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentChartMargins solve(
    FluentCartesianChartProps props, {
    double startFromX = 0,
    bool isRtl = false,
  }) => FluentCartesianMarginSolver.solve(
    props: props,
    startFromX: startFromX,
    isRtl: isRtl,
  );

  void expectMargins(
    FluentChartMargins actual, {
    required double top,
    required double bottom,
    required double left,
    required double right,
    required String reason,
  }) {
    expect(actual.top, top, reason: 'top: $reason');
    expect(actual.bottom, bottom, reason: 'bottom: $reason');
    expect(actual.left, left, reason: 'left: $reason');
    expect(actual.right, right, reason: 'right: $reason');
  }

  test('plain left-to-right chart with no titles', () {
    expectMargins(
      solve(const FluentCartesianChartProps()),
      top: 20,
      bottom: 35,
      left: 40,
      right: 20,
      reason:
          '_getDefaultMargins, CartesianChart.tsx:671-682 — bottom is '
          'DEFAULT_MARGIN_WITH_TICKS - 5',
    );
  });

  test('a secondary y-scale widens the right margin to 40', () {
    expectMargins(
      solve(
        const FluentCartesianChartProps(
          secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
        ),
      ),
      top: 20,
      bottom: 35,
      left: 40,
      right: 40,
      reason: 'CartesianChart.tsx:680',
    );
  });

  test('an x title adds 20 to bottom and a y title adds 24 to left', () {
    expectMargins(
      solve(
        const FluentCartesianChartProps(
          xAxisTitle: 'Time',
          yAxisTitle: 'Value',
        ),
      ),
      top: 20,
      bottom: 55,
      left: 64,
      right: 20,
      reason: '_applyTitleMargins, CartesianChart.tsx:684-696',
    );
  });

  test('an empty-string title is treated as absent', () {
    expectMargins(
      solve(const FluentCartesianChartProps(xAxisTitle: '', yAxisTitle: '')),
      top: 20,
      bottom: 35,
      left: 40,
      right: 20,
      reason:
          "the `!== undefined && !== ''` guards at CartesianChart.tsx:686,689",
    );
  });

  test('an x annotation grows TOP, not bottom, using the x-title constant', () {
    expectMargins(
      solve(
        const FluentCartesianChartProps(
          xAxisAnnotation: 'note',
          yAxisAnnotation: 'note',
        ),
      ),
      top: 40,
      bottom: 35,
      left: 40,
      right: 44,
      reason: '_applyAnnotationMargins, CartesianChart.tsx:698-711',
    );
  });

  test('a secondary y title suppresses the y annotation margin', () {
    expectMargins(
      solve(
        const FluentCartesianChartProps(
          yAxisAnnotation: 'note',
          secondaryYAxisTitle: 'Secondary',
        ),
      ),
      top: 20,
      bottom: 35,
      left: 40,
      right: 44,
      reason:
          'the title already added 24; the annotation arm is gated off at '
          'CartesianChart.tsx:703-707, so right is 20 + 24 and not 20 + 48',
    );
  });

  test('startFromX widens the left margin by 20 once it clears 40', () {
    expectMargins(
      solve(
        const FluentCartesianChartProps(showYAxisLables: true),
        startFromX: 63,
      ),
      top: 20,
      bottom: 35,
      left: 83,
      right: 20,
      reason: 'max(40, startFromX + 20), CartesianChart.tsx:679',
    );
    expect(
      solve(
        const FluentCartesianChartProps(showYAxisLables: true),
        startFromX: 5,
      ).left,
      40,
      reason: 'the max clamps a short label back to DEFAULT_MARGIN_WITH_TICKS',
    );
  });

  test('right-to-left swaps left and right but leaves top and bottom', () {
    expectMargins(
      solve(const FluentCartesianChartProps(), isRtl: true),
      top: 20,
      bottom: 35,
      left: 20,
      right: 40,
      reason: '_swapRtlMargins, CartesianChart.tsx:713-719',
    );
  });

  test('the caller override runs after the swap and is therefore physical', () {
    final margins = solve(
      const FluentCartesianChartProps(margins: FluentChartMargins(left: 100)),
      isRtl: true,
    );
    expectMargins(
      margins,
      top: 20,
      bottom: 35,
      left: 100,
      right: 40,
      reason:
          'the spread at CartesianChart.tsx:665-668 lands on the already-swapped '
          'value, so 100 stays on the physical left even in RTL',
    );
  });

  test('a partial override leaves the computed sides alone', () {
    expectMargins(
      solve(
        const FluentCartesianChartProps(
          xAxisTitle: 'Time',
          margins: FluentChartMargins(top: 4),
        ),
      ),
      top: 4,
      bottom: 55,
      left: 40,
      right: 20,
      reason: 'mergeOverride takes only the non-null fields of the override',
    );
  });
}
