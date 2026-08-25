import 'package:fluent_2/fluent_2.dart';
// The six `src/charts/cartesian/**` barrel lines are not in
// `lib/fluent_2.dart` yet — that file is owned by the integration tasks —
// so this test deep-imports the shell exactly as
// `test/charts/cartesian/support/stub_cartesian_delegate.dart` already does.
import 'package:flutter/widgets.dart';

import '../charts/cartesian/support/stub_cartesian_delegate.dart';
import '../support/golden.dart';

/// Row 1: the plain shell, the shell with both axis titles, and the shell with
/// a legend row.
/// Row 2: right-to-left, a categorical x axis, and an x axis whose labels are
/// rotated.
///
/// The shell paints axes, gridlines and titles; the stub delegate paints one
/// flat rectangle over the plot, so a cell that changes shows a moved axis, a
/// moved title or a resolved-token regression rather than series noise.
void main() {
  Widget cell({
    FluentCartesianChartProps props = const FluentCartesianChartProps(
      hideLegend: true,
    ),
    StubCartesianDelegate? delegate,
    TextDirection direction = TextDirection.ltr,
  }) => Directionality(
    textDirection: direction,
    child: SizedBox(
      // 260x180 is a cell size, not a ported constant: three of them plus the
      // 16px grid gaps fit the 1000x600 surface below with room for the legend
      // row in cell 3.
      width: 260,
      height: 180,
      child: FluentCartesianChart(
        delegate: delegate ?? StubCartesianDelegate(),
        props: props,
        legends: const <FluentChartLegendItem>[
          // The Fluent brand primary, so the legend swatch is a fixed colour
          // rather than a palette index that could be renumbered.
          FluentChartLegendItem(title: 'Series 0', color: Color(0xFF0078D4)),
        ],
      ),
    ),
  );

  goldenGridTest(
    'cartesian_chart',
    () => goldenGrid(<Widget>[
      cell(),
      cell(
        props: const FluentCartesianChartProps(
          hideLegend: true,
          xAxisTitle: 'Time',
          yAxisTitle: 'Value',
        ),
      ),
      cell(props: const FluentCartesianChartProps()),
      cell(direction: TextDirection.rtl),
      cell(
        delegate: StubCartesianDelegate(
          xAxisType: FluentChartAxisType.category,
        ),
      ),
      cell(
        props: const FluentCartesianChartProps(
          hideLegend: true,
          rotateXAxisLables: true,
        ),
        delegate: StubCartesianDelegate(
          xAxisType: FluentChartAxisType.category,
          categories: const <String>['January', 'February', 'March'],
        ),
      ),
    ], columns: 3),
    surfaceSize: const Size(1000, 600),
  );
}
