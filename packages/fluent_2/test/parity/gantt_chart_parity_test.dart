// Pixel parity for GanttChart's grouped story, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded. GanttChartBasic lives in
// `sankey_and_gantt_parity_test.dart`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/gantt_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:flutter/widgets.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// One bar of `const data: GanttChartDataPoint[]`.
///
/// `new Date("2017-01-01")` is an ISO date-only string, which JavaScript parses
/// as UTC midnight; `new Date(new Date("2017-06-18"))` is the same instant.
/// Each legend carries one `DataVizPalette` semantic token and one gradient
/// pair, spelled once in [_complete], [_incomplete] and [_notStarted].
FluentGanttChartDataPoint _bar(
  (int, int) start,
  (int, int) end,
  String y,
  (String, FluentDataVizToken, (Color, Color)) legend,
) => FluentGanttChartDataPoint(
  x: FluentGanttSpan(
    start: DateTime.utc(2017, start.$1, start.$2),
    end: DateTime.utc(2017, end.$1, end.$2),
  ),
  y: y,
  legend: legend.$1,
  color: FluentDataVizPalette.resolve(legend.$2),
  gradient: legend.$3,
);

const _complete = (
  'Complete',
  FluentDataVizToken.success,
  (Color(0xFF0C5E0C), Color(0xFF107C10)),
);
const _incomplete = (
  'Incomplete',
  FluentDataVizToken.warning,
  (Color(0xFFDE590B), Color(0xFFF7630C)),
);
const _notStarted = (
  'Not Started',
  FluentDataVizToken.error,
  (Color(0xFFB10E1C), Color(0xFFCC2635)),
);

void main() {
  setUpAll(loadParityFonts);

  testWidgets('GanttChartGrouped', (tester) async {
    // `const data` in charts-ganttchart--gantt-chart-grouped.tsx, in source
    // order — the y axis takes its category order from it.
    final data = <FluentGanttChartDataPoint>[
      _bar((1, 1), (2, 2), 'Job-1', _complete),
      _bar((1, 17), (2, 17), 'Job-2', _complete),
      _bar((1, 14), (3, 14), 'Job-4', _complete),
      _bar((2, 15), (3, 15), 'Job-1', _incomplete),
      _bar((1, 17), (2, 17), 'Job-2', _notStarted),
      _bar((3, 10), (3, 20), 'Job-3', _notStarted),
      _bar((4, 1), (4, 20), 'Job-3', _notStarted),
      _bar((5, 18), (6, 18), 'Job-3', _notStarted),
    ];

    await expectReactParity(
      tester,
      'charts-ganttchart--gantt-chart-grouped',
      FluentGanttChart(
        data: data,
        // The sliders start at 600 x 350, the box the harness mounts at; all
        // three Switches start unchecked, so the reference was captured with
        // gradients, rounded corners and multi-select off.
        props: const FluentCartesianChartProps(showYAxisLables: true),
      ),
      // Measured 0.107% — 213 of 199,789 px, aligned, the same in every zone
      // (was 0.204% at +03:00 before useUtc reached the axis, and 0.129%
      // before the legend swatches snapped to whole device pixels). All 213
      // are nine one-column bar ends, 23-24 px each, at x 45, 84, 140, 178,
      // 184, 246, 258, 261 and 311. The left margin is the widest y label
      // plus 20 (`CartesianChart.tsx:679`): Selawik Semibold, whose digits
      // are tabular, sets every "Job-N" at 25.942 against Segoe UI Semibold's
      // widest, "Job-4", at 25.750 (Oracle B), so the plot starts 0.19 px
      // right of upstream's 45.742. The x range's right end is fixed, so a
      // bar end moves by that shift scaled by its distance from the right;
      // these nine are the ones it tips past the tolerance.
      maxMismatch: 0.11,
    );
  });
}
