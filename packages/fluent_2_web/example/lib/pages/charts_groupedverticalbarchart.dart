import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The GroupedVerticalBarChart docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Every demo is
/// delimited by a `#docregion` whose id is the section id, so the "Show code"
/// panel prints exactly the code that rendered.
const DocsPage groupedVerticalBarChartPage = DocsPage(
  id: 'charts-groupedverticalbarchart',
  title: 'GroupedVerticalBarChart',
  description:
      'A grouped vertical bar chart displays multiple series of data as '
      'a group of bars, with each bar denoting a category. The bars are '
      'grouped together side by side, with each group denoting a '
      'different series. Effectively, a grouped vertical bar chart can '
      'slice data across 2 dimensions - (1) A dimension along the x '
      'axis and (2) Groups within the first dimension. And the y-axis '
      'plots the values of each category. Each bar in a group is '
      'colored differently to differentiate among categories within the '
      'group.',
  source: 'lib/pages/charts_groupedverticalbarchart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'A stacked bar chart is used to emphasize the composition of '
          'a category and how individual components contribute to it.\n'
          'On the other hand, a grouped bar chart is used to compare '
          'distinct values across various categories or groups '
          'separately.\n'
          'Refer to Vertical Bar Chart page for common layout guidance.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          'Refer to Vertical Bar Chart page for common content '
          'guidance.\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          'Refer to Vertical Bar Chart page for common accessibility '
          'guidance.\n',
    ),
    ProseBlock(
      title: 'Customizing the chart',
      body:
          '- Use the `barwidth` prop to customize the width of each bar '
          'in the chart. When set to `undefined` or `\'default\'`, the '
          'bar width defaults to 16px, which may decrease to prevent '
          'overlap. When set to `\'auto\'`, the bar width is calculated '
          'from padding values. For a fixed bar width, specify an '
          'absolute pixel value like `40`.\n'
          '- Use the `maxBarWidth` prop to limit the width of bars to a '
          'specified number of pixels.\n'
          '- Use the `xAxisInnerPadding` and `xAxisOuterPadding` props '
          'to adjust the padding between groups and the padding before '
          'the first group and after the last group, respectively. '
          'These props accept values between 0 and 1, representing a '
          'fraction of the `step`, which is the interval between the '
          'start of a group and the start of the next group. These '
          'props are particularly relevant when using a string x-axis. '
          'By default, the inner padding is set to `2 / (2 + '
          'groupWidthInTermsOfBarWidth)`, maintaining a 2:1 spacing '
          'ratio. This default value is calculated at runtime using the '
          'formula:\n'
          'innerPadding = spaceBetweenGroups / (spaceBetweenGroups + '
          'groupWidth)\n'
          'For a more detailed explanation of how these values were '
          'derived, see [Implementing 2:1 spacing | FluentUI Charting '
          'Contrib '
          'Docsite](https://microsoft.github.io/fluentui-charting-contrib/docs/implementing-2-to-1-spacing). '
          'For additional information on padding in string axes, see '
          '[Band scales | D3 by '
          'Observable](https://d3js.org/d3-scale/band#band_paddingInner)\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-groupedverticalbarchart--grouped-vertical-bar-default',
      title: 'Grouped Vertical Bar Default',
      builder: _groupedVerticalBarDefault,
    ),
    DocsSection(
      id: 'charts-groupedverticalbarchart--grouped-vertical-bar-negative',
      title: 'Grouped Vertical Bar Negative',
      builder: _groupedVerticalBarNegative,
    ),
    DocsSection(
      id: 'charts-groupedverticalbarchart--grouped-vertical-bar-secondary-y-axis',
      title: 'Grouped Vertical Bar Secondary Y Axis',
      builder: _groupedVerticalBarSecondaryYAxis,
    ),
    DocsSection(
      id: 'charts-groupedverticalbarchart--grouped-vertical-bar-chart-line',
      title: 'Grouped Vertical Bar Chart Line',
      builder: _groupedVerticalBarChartLine,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentGroupedVerticalBarChartData>',
      defaultValue: 'const <FluentGroupedVerticalBarChartData>[]',
      description: 'The categories, in author order.',
    ),
    PropRow(
      name: 'dataV2',
      type: 'List<FluentDataSeries>?',
      defaultValue: 'null',
      description:
          'The v2 input. When non-empty it replaces data entirely and is the '
          'only way to supply line series.',
    ),
    PropRow(
      name: 'props',
      type: 'FluentCartesianChartProps',
      defaultValue: 'FluentCartesianChartProps()',
      description:
          'Shell configuration: axes, legend, tooltip, margins and titles.',
    ),
    PropRow(
      name: 'barWidth',
      type: 'Object?',
      defaultValue: 'null',
      description: "number | 'default' | 'auto'; null resolves to 16.",
    ),
    PropRow(
      name: 'maxBarWidth',
      type: 'double',
      defaultValue: '24',
      description: 'Bar width ceiling, in logical pixels.',
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
      description: 'BCP-47 locale for popover formatting.',
    ),
    PropRow(
      name: 'isCalloutForStack',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the popover lists every legend in the hovered category.',
    ),
    PropRow(
      name: 'hideLabels',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the per-legend total labels are suppressed.',
    ),
    PropRow(
      name: 'roundCorners',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether bars get a 3px corner radius.',
    ),
    PropRow(
      name: 'mode',
      type: 'String?',
      defaultValue: 'null',
      description: "'plotly' or null.",
    ),
    PropRow(
      name: 'xAxisInnerPadding',
      type: 'double?',
      defaultValue: 'null',
      description: 'Category-scale inner padding override.',
    ),
    PropRow(
      name: 'xAxisOuterPadding',
      type: 'double?',
      defaultValue: 'null',
      description: 'Category-scale outer padding override.',
    ),
    PropRow(
      name: 'xAxisCategoryOrder',
      type: 'FluentAxisCategoryOrder?',
      defaultValue: 'null',
      description:
          'Ordering applied to the category x axis, or null when the caller '
          'named none.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentGroupedVerticalBarChartStyle?',
      defaultValue: 'null',
      description: 'Style override, highest precedence.',
    ),
    PropRow(
      name: 'legendSelectionMode',
      type: 'FluentChartLegendSelectionMode',
      defaultValue: 'FluentChartLegendSelectionMode.single',
      description: 'Whether the legend allows more than one selection.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description: "The chart's single focus node.",
    ),
  ],
);

// #docregion charts-groupedverticalbarchart--grouped-vertical-bar-default
Widget _groupedVerticalBarDefault(BuildContext context) =>
    const _GroupedVerticalBarDefault();

class _GroupedVerticalBarDefault extends StatefulWidget {
  const _GroupedVerticalBarDefault();

  @override
  State<_GroupedVerticalBarDefault> createState() =>
      _GroupedVerticalBarDefaultState();
}

class _GroupedVerticalBarDefaultState
    extends State<_GroupedVerticalBarDefault> {
  double _width = 650;
  double _height = 350;
  bool _hideLabels = false;

  /// `getColorFromToken(DataVizPalette.colorN)` upstream. The palette resolves
  /// at runtime, so the list is `final` rather than `const`.
  static final List<FluentGroupedVerticalBarChartData>
  _data = <FluentGroupedVerticalBarChartData>[
    FluentGroupedVerticalBarChartData(
      name: 'Jan - Mar',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: 33000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          legend: '2022',
          xAxisCalloutData: '2022/04/30',
          yAxisCalloutData: '29%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jan - Mar 1 of 4, Bar series 1 of 2 2022, x value 2022/04/30, y value 29%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: 44000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          legend: '2023',
          xAxisCalloutData: '2023/04/30',
          yAxisCalloutData: '44%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jan - Mar 1 of 4, Bar series 2 of 2 2023, x value 2023/04/30, y value 44%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series3',
          data: 54000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          legend: '2024',
          xAxisCalloutData: '2024/04/30',
          yAxisCalloutData: '44%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jan - Mar 1 of 4, Bar series 3 of 4 2022, x value 2024/04/30, y value 44%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series4',
          data: 24000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          legend: '2021',
          xAxisCalloutData: '2021/04/30',
          yAxisCalloutData: '44%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jan - Mar 1 of 4, Bar series 4 of 4 2021, x value 2021/04/30, y value 44%',
          ),
        ),
      ],
    ),
    FluentGroupedVerticalBarChartData(
      name: 'Apr - Jun',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: 33000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          legend: '2022',
          xAxisCalloutData: '2022/05/30',
          yAxisCalloutData: '29%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Apr - Jun 2 of 4, Bar series 1 of 2 2022, x value 2022/05/30, y value 29%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: 3000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          legend: '2023',
          xAxisCalloutData: '2023/05/30',
          yAxisCalloutData: '3%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Apr - Jun 2 of 4, Bar series 2 of 2 2023, x value 2023/05/30, y value 3%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series3',
          data: 9000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          legend: '2024',
          xAxisCalloutData: '2024/05/30',
          yAxisCalloutData: '3%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Apr - Jun 2 of 4, Bar series 3 of 4 2024, x value 2024/05/30, y value 3%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series4',
          data: 12000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          legend: '2021',
          xAxisCalloutData: '2021/05/30',
          yAxisCalloutData: '3%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Apr - Jun 2 of 4, Bar series 4 of 4 2021, x value 2021/05/30, y value 3%',
          ),
        ),
      ],
    ),
    FluentGroupedVerticalBarChartData(
      name: 'Jul - Sep',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: 14000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          legend: '2022',
          xAxisCalloutData: '2022/06/30',
          yAxisCalloutData: '13%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jul - Sep 3 of 4, Bar series 1 of 2 2022, x value 2022/06/30, y value 13%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: 50000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          legend: '2023',
          xAxisCalloutData: '2023/06/30',
          yAxisCalloutData: '50%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jul - Sep 3 of 4, Bar series 2 of 2 2023, x value 2023/06/30, y value 50%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series3',
          data: 60000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          legend: '2024',
          xAxisCalloutData: '2024/06/30',
          yAxisCalloutData: '50%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jul - Sep 3 of 4, Bar series 3 of 4 2024, x value 2024/06/30, y value 50%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series4',
          data: 10000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          legend: '2021',
          xAxisCalloutData: '2021/06/30',
          yAxisCalloutData: '50%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jul - Sep 3 of 4, Bar series 4 of 4 2021, x value 2021/06/30, y value 50%',
          ),
        ),
      ],
    ),
    FluentGroupedVerticalBarChartData(
      name: 'Oct - Dec',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: 33000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          legend: '2022',
          xAxisCalloutData: '2022/07/30',
          yAxisCalloutData: '29%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Oct - Dec 4 of 4, Bar series 1 of 2 2022, x value 2022/07/30, y value 29%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: 3000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          legend: '2023',
          xAxisCalloutData: '2023/07/30',
          yAxisCalloutData: '3%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Oct - Dec 4 of 4, Bar series 2 of 2 2023, x value 2023/07/30, y value 3%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series3',
          data: 6000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          legend: '2024',
          xAxisCalloutData: '2024/07/30',
          yAxisCalloutData: '3%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Oct - Dec 4 of 4, Bar series 3 of 4 2024, x value 2024/07/30, y value 3%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series4',
          data: 15000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          legend: '2021',
          xAxisCalloutData: '2021/07/30',
          yAxisCalloutData: '3%',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Oct - Dec 4 of 4, Bar series 4 of 4 2021, x value 2021/07/30, y value 3%',
          ),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      const SizedBox(
        width: 650,
        child: Text(
          'In this example the xAxisCalloutData property overrides the x value '
          'that is shown on the callout. So instead of a numeric value, the '
          'callout will show the date that is passed in the xAxisCalloutData '
          'property.',
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Width',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Height',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      FluentCheckbox(
        checked: _hideLabels,
        onChanged: (bool? value) =>
            setState(() => _hideLabels = value ?? false),
        label: const Text('Hide labels'),
      ),
      // The slider reaches 1000, which is wider than the docs column, so the
      // chart box scrolls rather than overflowing.
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentGroupedVerticalBarChart(
            // `window.navigator.language` upstream; a Flutter example has no
            // navigator, so the demo names the locale the storybook runs in.
            culture: 'en-us',
            chartTitle: 'Grouped Vertical Bar chart basic example',
            data: _data,
            hideLabels: _hideLabels,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-groupedverticalbarchart--grouped-vertical-bar-default

// #docregion charts-groupedverticalbarchart--grouped-vertical-bar-negative
Widget _groupedVerticalBarNegative(BuildContext context) =>
    const _GroupedVerticalBarNegative();

class _GroupedVerticalBarNegative extends StatefulWidget {
  const _GroupedVerticalBarNegative();

  @override
  State<_GroupedVerticalBarNegative> createState() =>
      _GroupedVerticalBarNegativeState();
}

class _GroupedVerticalBarNegativeState
    extends State<_GroupedVerticalBarNegative> {
  double _width = 700;
  double _height = 400;
  double _barWidth = 16;
  String _selectedCallout = 'singleCallout';
  bool _hideLabels = false;
  bool _roundCorners = false;
  bool _selectMultipleLegends = false;

  static final List<FluentGroupedVerticalBarChartData>
  _data = <FluentGroupedVerticalBarChartData>[
    FluentGroupedVerticalBarChartData(
      name: 'Jan - Mar',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: 33000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          legend: '2022',
          xAxisCalloutData: '2022/04/30',
          yAxisCalloutData: '33000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jan - Mar 1 of 4, Bar series 1 of 2 2022, x value 2022/04/30, y value 29%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: -44000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          legend: '2023',
          xAxisCalloutData: '2023/04/30',
          yAxisCalloutData: '-44000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jan - Mar 1 of 4, Bar series 2 of 2 2023, x value 2023/04/30, y value 44%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series3',
          data: -54000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          legend: '2024',
          xAxisCalloutData: '2024/04/30',
          yAxisCalloutData: '-54000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jan - Mar 1 of 4, Bar series 3 of 4 2022, x value 2024/04/30, y value 44%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series4',
          data: 24000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          legend: '2021',
          xAxisCalloutData: '2021/04/30',
          yAxisCalloutData: '24000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jan - Mar 1 of 4, Bar series 4 of 4 2021, x value 2021/04/30, y value 44%',
          ),
        ),
      ],
    ),
    FluentGroupedVerticalBarChartData(
      name: 'Apr - Jun',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: 33000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          legend: '2022',
          xAxisCalloutData: '2022/05/30',
          yAxisCalloutData: '33000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Apr - Jun 2 of 4, Bar series 1 of 2 2022, x value 2022/05/30, y value 29%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: -3000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          legend: '2023',
          xAxisCalloutData: '2023/05/30',
          yAxisCalloutData: '-3000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Apr - Jun 2 of 4, Bar series 2 of 2 2023, x value 2023/05/30, y value 3%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series3',
          data: 9000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          legend: '2024',
          xAxisCalloutData: '2024/05/30',
          yAxisCalloutData: '9000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Apr - Jun 2 of 4, Bar series 3 of 4 2024, x value 2024/05/30, y value 3%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series4',
          data: -12000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          legend: '2021',
          xAxisCalloutData: '2021/05/30',
          yAxisCalloutData: '-12000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Apr - Jun 2 of 4, Bar series 4 of 4 2021, x value 2021/05/30, y value 3%',
          ),
        ),
      ],
    ),
    FluentGroupedVerticalBarChartData(
      name: 'Jul - Sep',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: 14000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          legend: '2022',
          xAxisCalloutData: '2022/06/30',
          yAxisCalloutData: '14000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jul - Sep 3 of 4, Bar series 1 of 2 2022, x value 2022/06/30, y value 13%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: 50000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          legend: '2023',
          xAxisCalloutData: '2023/06/30',
          yAxisCalloutData: '50000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jul - Sep 3 of 4, Bar series 2 of 2 2023, x value 2023/06/30, y value 50%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series3',
          data: -60000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          legend: '2024',
          xAxisCalloutData: '2024/06/30',
          yAxisCalloutData: '-60000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jul - Sep 3 of 4, Bar series 3 of 4 2024, x value 2024/06/30, y value 50%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series4',
          data: -10000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          legend: '2021',
          xAxisCalloutData: '2021/06/30',
          yAxisCalloutData: '-10000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Jul - Sep 3 of 4, Bar series 4 of 4 2021, x value 2021/06/30, y value 50%',
          ),
        ),
      ],
    ),
    FluentGroupedVerticalBarChartData(
      name: 'Oct - Dec',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: -33000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          legend: '2022',
          xAxisCalloutData: '2022/07/30',
          yAxisCalloutData: '-33000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Oct - Dec 4 of 4, Bar series 1 of 2 2022, x value 2022/07/30, y value 29%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: 3000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          legend: '2023',
          xAxisCalloutData: '2023/07/30',
          yAxisCalloutData: '3000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Oct - Dec 4 of 4, Bar series 2 of 2 2023, x value 2023/07/30, y value 3%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series3',
          data: -6000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          legend: '2024',
          xAxisCalloutData: '2024/07/30',
          yAxisCalloutData: '-6000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Oct - Dec 4 of 4, Bar series 3 of 4 2024, x value 2024/07/30, y value 3%',
          ),
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series4',
          data: -15000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          legend: '2021',
          xAxisCalloutData: '2021/07/30',
          yAxisCalloutData: '-15000',
          callOutSemantics: const FluentChartSemantics(
            label:
                'Group Oct - Dec 4 of 4, Bar series 4 of 4 2021, x value 2021/07/30, y value 3%',
          ),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      const SizedBox(
        width: 700,
        child: Text(
          'In this example the xAxisCalloutData property overrides the x value '
          'that is shown on the callout. So instead of a numeric value, the '
          'callout will show the date that is passed in the xAxisCalloutData '
          'property.',
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Width',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Height',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          const Text('Change Barwidth:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _barWidth,
              min: 1,
              max: 50,
              step: 1,
              semanticFormatter: (double value) =>
                  'ChangeBarwidthslider${value.round()}',
              onChanged: (double value) => setState(() => _barWidth = value),
            ),
          ),
          Text('${_barWidth.round()}'),
        ],
      ),
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _selectedCallout,
          onChanged: (String value) => setState(() => _selectedCallout = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'singleCallout',
              label: Text('Single Callout'),
            ),
            FluentRadio<String>(
              value: 'stackedCallout',
              label: Text('Stacked callout'),
            ),
          ],
        ),
      ),
      FluentCheckbox(
        checked: _hideLabels,
        onChanged: (bool? value) =>
            setState(() => _hideLabels = value ?? false),
        label: const Text('Hide labels'),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          FluentSwitch(
            checked: _roundCorners,
            onChanged: (bool value) => setState(() => _roundCorners = value),
            label: Text(
              _roundCorners ? 'Rounded corners ON' : 'Rounded corners OFF',
            ),
          ),
          FluentSwitch(
            checked: _selectMultipleLegends,
            onChanged: (bool value) =>
                setState(() => _selectMultipleLegends = value),
            label: Text(
              _selectMultipleLegends
                  ? 'legendmultiselect ON'
                  : 'legendmultiselect OFF',
            ),
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentGroupedVerticalBarChart(
            // `window.navigator.language` upstream.
            culture: 'en-us',
            chartTitle: 'Grouped Vertical Bar chart basic example',
            data: _data,
            // Upstream compares against 'StackCallout' while its own radios
            // carry 'singleCallout' and 'stackedCallout', so neither choice
            // ever turns the stack callout on. The port keeps the control and
            // the same inert comparison.
            isCalloutForStack: _selectedCallout == 'StackCallout',
            barWidth: _barWidth,
            hideLabels: _hideLabels,
            roundCorners: _roundCorners,
            legendSelectionMode: _selectMultipleLegends
                ? FluentChartLegendSelectionMode.multiple
                : FluentChartLegendSelectionMode.single,
            props: const FluentCartesianChartProps(
              reflowMode: FluentChartReflowMode.minWidth,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-groupedverticalbarchart--grouped-vertical-bar-negative

// #docregion charts-groupedverticalbarchart--grouped-vertical-bar-secondary-y-axis
Widget _groupedVerticalBarSecondaryYAxis(BuildContext context) =>
    const _GroupedVerticalBarSecondaryYAxis();

class _GroupedVerticalBarSecondaryYAxis extends StatefulWidget {
  const _GroupedVerticalBarSecondaryYAxis();

  @override
  State<_GroupedVerticalBarSecondaryYAxis> createState() =>
      _GroupedVerticalBarSecondaryYAxisState();
}

class _GroupedVerticalBarSecondaryYAxisState
    extends State<_GroupedVerticalBarSecondaryYAxis> {
  double _width = 700;
  double _height = 300;

  static final List<FluentGroupedVerticalBarChartData> _data =
      <FluentGroupedVerticalBarChartData>[
        FluentGroupedVerticalBarChartData(
          name: 'Jan - Mar',
          series: <FluentGroupedBarSeriesPoint>[
            FluentGroupedBarSeriesPoint(
              key: 'series1',
              data: 24000,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
              legend: '2021',
            ),
            FluentGroupedBarSeriesPoint(
              key: 'series2',
              data: 54000,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
              legend: '2022',
              useSecondaryYScale: true,
            ),
          ],
        ),
        FluentGroupedVerticalBarChartData(
          name: 'Apr - Jun',
          series: <FluentGroupedBarSeriesPoint>[
            FluentGroupedBarSeriesPoint(
              key: 'series1',
              data: 12000,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
              legend: '2021',
            ),
            FluentGroupedBarSeriesPoint(
              key: 'series2',
              data: 9000,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
              legend: '2022',
              useSecondaryYScale: true,
            ),
          ],
        ),
        FluentGroupedVerticalBarChartData(
          name: 'Jul - Sep',
          series: <FluentGroupedBarSeriesPoint>[
            FluentGroupedBarSeriesPoint(
              key: 'series1',
              data: 10000,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
              legend: '2021',
            ),
            FluentGroupedBarSeriesPoint(
              key: 'series2',
              data: 60000,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
              legend: '2022',
              useSecondaryYScale: true,
            ),
          ],
        ),
        FluentGroupedVerticalBarChartData(
          name: 'Oct - Dec',
          series: <FluentGroupedBarSeriesPoint>[
            FluentGroupedBarSeriesPoint(
              key: 'series1',
              data: 15000,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
              legend: '2021',
            ),
            FluentGroupedBarSeriesPoint(
              key: 'series2',
              data: 6000,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
              legend: '2022',
              useSecondaryYScale: true,
            ),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Width',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Height',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentGroupedVerticalBarChart(
            chartTitle: 'Grouped Vertical Bar chart secondary y-axis example',
            data: _data,
            barWidth: 16,
            props: const FluentCartesianChartProps(
              hideTickOverlap: true,
              secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-groupedverticalbarchart--grouped-vertical-bar-secondary-y-axis

// #docregion charts-groupedverticalbarchart--grouped-vertical-bar-chart-line
Widget _groupedVerticalBarChartLine(BuildContext context) =>
    const _GroupedVerticalBarChartLine();

class _GroupedVerticalBarChartLine extends StatefulWidget {
  const _GroupedVerticalBarChartLine();

  @override
  State<_GroupedVerticalBarChartLine> createState() =>
      _GroupedVerticalBarChartLineState();
}

class _GroupedVerticalBarChartLineState
    extends State<_GroupedVerticalBarChartLine> {
  double _width = 700;
  double _height = 400;
  String _calloutVariant = 'SingleCallout';
  bool _selectMultipleLegends = false;

  /// `GroupedVerticalBarChartProps['dataV2']` upstream: four bar series and two
  /// line series over the same four categories.
  static final List<FluentDataSeries> _chartData = <FluentDataSeries>[
    FluentBarSeries(
      legend: '2022',
      data: const <FluentDataPointV2>[
        FluentDataPointV2(x: 'Jan - Mar', y: 33000),
        FluentDataPointV2(x: 'Apr - Jun', y: 33000),
        FluentDataPointV2(x: 'Jul - Sep', y: 14000),
        FluentDataPointV2(x: 'Oct - Dec', y: -33000),
      ],
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
    ),
    FluentBarSeries(
      legend: '2023',
      data: const <FluentDataPointV2>[
        FluentDataPointV2(x: 'Jan - Mar', y: -44000),
        FluentDataPointV2(x: 'Apr - Jun', y: -3000),
        FluentDataPointV2(x: 'Jul - Sep', y: 50000),
        FluentDataPointV2(x: 'Oct - Dec', y: 3000),
      ],
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
    ),
    FluentBarSeries(
      legend: '2024',
      data: const <FluentDataPointV2>[
        FluentDataPointV2(x: 'Jan - Mar', y: -54000),
        FluentDataPointV2(x: 'Apr - Jun', y: 9000),
        FluentDataPointV2(x: 'Jul - Sep', y: -60000),
        FluentDataPointV2(x: 'Oct - Dec', y: -6000),
      ],
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
    ),
    FluentBarSeries(
      legend: '2021',
      data: const <FluentDataPointV2>[
        FluentDataPointV2(x: 'Jan - Mar', y: 24000),
        FluentDataPointV2(x: 'Apr - Jun', y: -12000),
        FluentDataPointV2(x: 'Jul - Sep', y: -10000),
        FluentDataPointV2(x: 'Oct - Dec', y: -15000),
      ],
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
    ),
    FluentLineSeries(
      legend: 'From_Legacy_to_O365',
      data: const <FluentDataPointV2>[
        FluentDataPointV2(x: 'Jan - Mar', y: -21600),
        FluentDataPointV2(x: 'Apr - Jun', y: 21812),
        FluentDataPointV2(x: 'Jul - Sep', y: -21712),
        FluentDataPointV2(x: 'Oct - Dec', y: 24800),
      ],
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      lineOptions: const FluentLineOptions(lineBorderWidth: 2),
    ),
    FluentLineSeries(
      legend: 'All',
      data: const <FluentDataPointV2>[
        FluentDataPointV2(x: 'Jan - Mar', y: 29700),
        FluentDataPointV2(x: 'Apr - Jun', y: -28400),
        FluentDataPointV2(x: 'Jul - Sep', y: 28200),
        FluentDataPointV2(x: 'Oct - Dec', y: -29400),
      ],
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      lineOptions: const FluentLineOptions(lineBorderWidth: 2),
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('Change width:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Width',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change height:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Height',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      FluentField(
        label: const Text('Pick a callout variant:'),
        child: FluentRadioGroup<String>(
          value: _calloutVariant,
          layout: FluentRadioGroupLayout.horizontal,
          onChanged: (String value) => setState(() => _calloutVariant = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'SingleCallout',
              label: Text('Single Callout'),
            ),
            FluentRadio<String>(
              value: 'StackCallout',
              label: Text('Stack Callout'),
            ),
          ],
        ),
      ),
      FluentField(
        label: const Text('Select multiple legends:'),
        child: FluentSwitch(
          checked: _selectMultipleLegends,
          onChanged: (bool value) =>
              setState(() => _selectMultipleLegends = value),
          label: Text(_selectMultipleLegends ? 'ON' : 'OFF'),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentGroupedVerticalBarChart(
            chartTitle: 'Grouped Vertical Bar chart line example',
            dataV2: _chartData,
            isCalloutForStack: _calloutVariant == 'StackCallout',
            legendSelectionMode: _selectMultipleLegends
                ? FluentChartLegendSelectionMode.multiple
                : FluentChartLegendSelectionMode.single,
            props: const FluentCartesianChartProps(
              reflowMode: FluentChartReflowMode.minWidth,
            ),
          ),
        ),
      ),
    ],
  );
}

// #enddocregion charts-groupedverticalbarchart--grouped-vertical-bar-chart-line
