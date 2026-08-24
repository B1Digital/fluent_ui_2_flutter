import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The GanttChart docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream's `DataVizPalette.colorN` is
/// `FluentDataVizPalette.resolve(FluentDataVizToken.colorN)` here, and
/// `new Date("2009-01-01")` — an ISO date string, which JavaScript parses as
/// UTC — is `DateTime.utc(2009, 1, 1)`.
const DocsPage ganttChartPage = DocsPage(
  id: 'charts-ganttchart',
  title: 'GanttChart',
  description: '',
  source: 'lib/pages/charts_ganttchart.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-ganttchart--gantt-chart-basic',
      title: 'Gantt Chart Basic',
      builder: _ganttChartBasic,
    ),
    DocsSection(
      id: 'charts-ganttchart--gantt-chart-grouped',
      title: 'Gantt Chart Grouped',
      builder: _ganttChartGrouped,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentGanttChartDataPoint>',
      description: 'The spans, in author order.',
    ),
    PropRow(
      name: 'props',
      type: 'FluentCartesianChartProps',
      defaultValue: 'FluentCartesianChartProps()',
      description: 'Shell configuration: axes, legend, margins, tooltips.',
    ),
    PropRow(
      name: 'barHeight',
      type: 'double?',
      defaultValue: 'null',
      description: 'Explicit bar height, overriding the auto solve.',
    ),
    PropRow(
      name: 'maxBarHeight',
      type: 'double',
      defaultValue: '24',
      description: 'Bar height ceiling.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description: 'Human title, folded into the accessible description.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'BCP-47 locale for date formatting.',
    ),
    PropRow(
      name: 'yAxisPadding',
      type: 'double',
      defaultValue: '0.5',
      description: 'Band padding between rows, as a fraction of the step.',
    ),
    PropRow(
      name: 'enableGradient',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether each legend paints a left-to-right gradient.',
    ),
    PropRow(
      name: 'roundCorners',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether bars get a 3px corner radius.',
    ),
    PropRow(
      name: 'useUtc',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether dates are formatted in UTC.',
    ),
    PropRow(
      name: 'yAxisCategoryOrder',
      type: 'FluentAxisCategoryOrder?',
      defaultValue: 'null',
      description: 'Ordering applied to a category y axis.',
    ),
    PropRow(
      name: 'popoverBuilder',
      type: 'WidgetBuilder?',
      defaultValue: 'null',
      description: 'Replaces the popover body.',
    ),
    PropRow(
      name: 'legendSelectionMode',
      type: 'FluentChartLegendSelectionMode',
      defaultValue: 'FluentChartLegendSelectionMode.single',
      description: 'Whether the legend allows more than one selection.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentGanttChartStyle?',
      defaultValue: 'null',
      description:
          'Style layered over the derived defaults and the nearest '
          'FluentGanttChartTheme.',
    ),
  ],
);

// #docregion charts-ganttchart--gantt-chart-basic
Widget _ganttChartBasic(BuildContext context) => const _GanttChartBasic();

class _GanttChartBasic extends StatefulWidget {
  const _GanttChartBasic();

  @override
  State<_GanttChartBasic> createState() => _GanttChartBasicState();
}

class _GanttChartBasicState extends State<_GanttChartBasic> {
  double _width = 600;
  double _height = 350;
  bool _enableGradient = false;
  bool _roundedCorners = false;

  List<FluentGanttChartDataPoint> get _data => <FluentGanttChartDataPoint>[
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2009, 1, 1),
        end: DateTime.utc(2009, 2, 28),
      ),
      y: 'Job A',
      legend: 'Alex',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      gradient: const (Color(0xFF4760D5), Color(0xFF637CEF)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2009, 3, 5),
        end: DateTime.utc(2009, 4, 15),
      ),
      y: 'Job B',
      legend: 'Alex',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      gradient: const (Color(0xFF4760D5), Color(0xFF637CEF)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2009, 2, 20),
        end: DateTime.utc(2009, 5, 30),
      ),
      y: 'Job C',
      legend: 'Max',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      gradient: const (Color(0xFFE61C99), Color(0xFFEE5FB7)),
    ),
  ];

  /// The `<label>` + `<input type="range">` + `<span>` trio upstream repeats
  /// for width and height.
  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    ValueChanged<double> onChanged,
  ) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label),
        const SizedBox(height: 4),
        FluentSlider(
          value: value,
          min: 0,
          max: 1000,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text('${value.round()}'),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 20,
        runSpacing: 20,
        children: <Widget>[
          _slider(
            'Width:',
            'Change Width',
            _width,
            (double value) => setState(() => _width = value),
          ),
          _slider(
            'Height:',
            'Change Height',
            _height,
            (double value) => setState(() => _height = value),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 20,
        runSpacing: 20,
        children: <Widget>[
          FluentSwitch(
            checked: _enableGradient,
            label: const Text('Enable Gradient'),
            onChanged: (bool value) => setState(() => _enableGradient = value),
          ),
          FluentSwitch(
            checked: _roundedCorners,
            label: const Text('Rounded Corners'),
            onChanged: (bool value) => setState(() => _roundedCorners = value),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: _width,
        height: _height,
        child: FluentGanttChart(
          data: _data,
          props: const FluentCartesianChartProps(showYAxisLables: true),
          enableGradient: _enableGradient,
          roundCorners: _roundedCorners,
        ),
      ),
    ],
  );
}
// #enddocregion charts-ganttchart--gantt-chart-basic

// #docregion charts-ganttchart--gantt-chart-grouped
Widget _ganttChartGrouped(BuildContext context) => const _GanttChartGrouped();

class _GanttChartGrouped extends StatefulWidget {
  const _GanttChartGrouped();

  @override
  State<_GanttChartGrouped> createState() => _GanttChartGroupedState();
}

class _GanttChartGroupedState extends State<_GanttChartGrouped> {
  double _width = 600;
  double _height = 350;
  bool _enableGradient = false;
  bool _roundedCorners = false;
  bool _legendMultiSelect = false;

  List<FluentGanttChartDataPoint> get _data => <FluentGanttChartDataPoint>[
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2017, 1, 1),
        end: DateTime.utc(2017, 2, 2),
      ),
      y: 'Job-1',
      legend: 'Complete',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.success),
      gradient: const (Color(0xFF0C5E0C), Color(0xFF107C10)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2017, 1, 17),
        end: DateTime.utc(2017, 2, 17),
      ),
      y: 'Job-2',
      legend: 'Complete',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.success),
      gradient: const (Color(0xFF0C5E0C), Color(0xFF107C10)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2017, 1, 14),
        end: DateTime.utc(2017, 3, 14),
      ),
      y: 'Job-4',
      legend: 'Complete',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.success),
      gradient: const (Color(0xFF0C5E0C), Color(0xFF107C10)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2017, 2, 15),
        end: DateTime.utc(2017, 3, 15),
      ),
      y: 'Job-1',
      legend: 'Incomplete',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.warning),
      gradient: const (Color(0xFFDE590B), Color(0xFFF7630C)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2017, 1, 17),
        end: DateTime.utc(2017, 2, 17),
      ),
      y: 'Job-2',
      legend: 'Not Started',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.error),
      gradient: const (Color(0xFFB10E1C), Color(0xFFCC2635)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2017, 3, 10),
        end: DateTime.utc(2017, 3, 20),
      ),
      y: 'Job-3',
      legend: 'Not Started',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.error),
      gradient: const (Color(0xFFB10E1C), Color(0xFFCC2635)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2017, 4, 1),
        end: DateTime.utc(2017, 4, 20),
      ),
      y: 'Job-3',
      legend: 'Not Started',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.error),
      gradient: const (Color(0xFFB10E1C), Color(0xFFCC2635)),
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(
        start: DateTime.utc(2017, 5, 18),
        end: DateTime.utc(2017, 6, 18),
      ),
      y: 'Job-3',
      legend: 'Not Started',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.error),
      gradient: const (Color(0xFFB10E1C), Color(0xFFCC2635)),
    ),
  ];

  /// The `<label>` + `<input type="range">` + `<span>` trio upstream repeats
  /// for width and height.
  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    ValueChanged<double> onChanged,
  ) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label),
        const SizedBox(height: 4),
        FluentSlider(
          value: value,
          min: 0,
          max: 1000,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text('${value.round()}'),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 20,
          runSpacing: 20,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _slider(
              'Width:',
              'Change Width',
              _width,
              (double value) => setState(() => _width = value),
            ),
            _slider(
              'Height:',
              'Change Height',
              _height,
              (double value) => setState(() => _height = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FluentSwitch(
              checked: _enableGradient,
              label: const Text('Enable Gradient'),
              onChanged: (bool value) =>
                  setState(() => _enableGradient = value),
            ),
            FluentSwitch(
              checked: _roundedCorners,
              label: const Text('Rounded Corners'),
              onChanged: (bool value) =>
                  setState(() => _roundedCorners = value),
            ),
            FluentSwitch(
              checked: _legendMultiSelect,
              label: const Text('Select Multiple Legends'),
              onChanged: (bool value) =>
                  setState(() => _legendMultiSelect = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: _width,
          height: _height,
          child: FluentGanttChart(
            data: _data,
            props: const FluentCartesianChartProps(showYAxisLables: true),
            enableGradient: _enableGradient,
            roundCorners: _roundedCorners,
            // `legendProps.canSelectMultipleLegends` is a top-level enum here.
            legendSelectionMode: _legendMultiSelect
                ? FluentChartLegendSelectionMode.multiple
                : FluentChartLegendSelectionMode.single,
          ),
        ),
      ],
    ),
  );
}

// #enddocregion charts-ganttchart--gantt-chart-grouped
