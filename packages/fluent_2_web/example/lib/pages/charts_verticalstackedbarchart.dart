import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The VerticalStackedBarChart docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage verticalStackedBarChartPage = DocsPage(
  id: 'charts-verticalstackedbarchart',
  title: 'VerticalStackedBarChart',
  description:
      'Vertical stacked bar chart displays multiple series of data as '
      'stacked bars, with each bar representing a category. The bars '
      'are stacked on top of each other, with the height of each bar '
      'representing the value of the category of the series. Categories '
      'and their count are shown on the horizontal axis.',
  source: 'lib/pages/charts_verticalstackedbarchart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'Stacked bar charts are ideal for comparing values across two '
          'or more categories. They can easily show multiple categories '
          'on the same chart.\n'
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
          'Here are some commonly used properties to customize the bar '
          'chart.\n'
          '- `bargapmax` sets the maximum gap between bars in a stack. '
          'See the prop for more details.\n'
          '- `barCornerRadius` sets the corner radius of the bars.\n'
          '- `barMinimumHeight` provides the minimum height of a bar. '
          'Bars below this height will be displayed at this height.\n'
          '- Use `isCalloutForStack` to configure callout to be at '
          'stack level or individual datapoint level.\n'
          '- Define a custom callout rendered per datapoint using '
          '`onRenderCalloutPerDataPoint` and per stack using '
          '`onRenderCalloutPerStack`\n'
          '- Use `onBarClick` handler for callback on click of bars\n'
          '- The bar labels are shown by default. Set the `hideLabels` '
          'prop to hide them.\n'
          '- Use the `barWidth` prop to customize the width of each bar '
          'in the chart. When set to `undefined` or `\'default\'`, the '
          'bar width defaults to 16px, which may decrease to prevent '
          'overlap. When set to `\'auto\'`, the bar width is calculated '
          'from padding values. For a fixed bar width, specify an '
          'absolute pixel value like `40`.\n'
          'Use the `maxBarWidth` prop to limit the width of bars to a '
          'specified number of pixels.\n'
          'Use the `xAxisInnerPadding` and `xAxisOuterPadding` props to '
          'adjust the padding between bars and the padding before the '
          'first bar and after the last bar, respectively. These props '
          'accept values between 0 and 1, representing a fraction of '
          'the `step`, which is the interval between the start of a bar '
          'and the start of the next bar. These props are particularly '
          'relevant when using a string x-axis. By default, the inner '
          'padding is set to 2/3, maintaining a 2:1 spacing ratio. This '
          'default value is calculated using the formula:\n'
          'innerPadding = spaceBetweenBars / (spaceBetweenBars + '
          'barWidth)\n'
          'For a more detailed explanation of how these values were '
          'derived, see [Implementing 2:1 spacing | FluentUI Charting '
          'Contrib '
          'Docsite](https://microsoft.github.io/fluentui-charting-contrib/docs/implementing-2-to-1-spacing). '
          'For additional information on padding in string axes, see '
          '[Band scales | D3 by '
          'Observable](https://d3js.org/d3-scale/band#band_paddingInner)\n',
    ),
    ProseBlock(
      title: 'Creating Date Objects For Chart Data',
      body:
          'For instructions on how to create date objects to be passed '
          'as data points in the chart, see [Creating Date Objects For '
          'Chart Data | FluentUI Charting Contrib '
          'Docsite](https://microsoft.github.io/fluentui-charting-contrib/docs/creating-date-objects-for-chart-data)\n',
    ),
    ProseBlock(
      title: 'Do\'s',
      body: '- Refer to Vertical Bar Chart page for common dos.\n',
    ),
    ProseBlock(
      title: 'Don\'ts',
      body: '- Refer to Vertical Bar Chart page for common don\'ts.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-verticalstackedbarchart--vertical-stacked-bar-default',
      title: 'Vertical Stacked Bar Default',
      builder: _verticalStackedBarDefault,
    ),
    DocsSection(
      id: 'charts-verticalstackedbarchart--vertical-stacked-bar-axis-tooltip',
      title: 'Vertical Stacked Bar Axis Tooltip',
      builder: _verticalStackedBarAxisTooltip,
    ),
    DocsSection(
      id: 'charts-verticalstackedbarchart--vertical-stacked-bar-callout',
      title: 'Vertical Stacked Bar Callout',
      builder: _verticalStackedBarCallout,
    ),
    DocsSection(
      id:
          'charts-verticalstackedbarchart--vertical-stacked-bar-custom-'
          'accessibility',
      title: 'Vertical Stacked Bar Custom Accessibility',
      builder: _verticalStackedBarCustomAccessibility,
    ),
    DocsSection(
      id: 'charts-verticalstackedbarchart--vertical-stacked-bar-date-axis',
      title: 'Vertical Stacked Bar Date Axis',
      builder: _verticalStackedBarDateAxis,
    ),
    DocsSection(
      id: 'charts-verticalstackedbarchart--vertical-stacked-bar-negative',
      title: 'Vertical Stacked Bar Negative',
      builder: _verticalStackedBarNegative,
    ),
    DocsSection(
      id:
          'charts-verticalstackedbarchart--vertical-stacked-bar-secondary-y-'
          'axis',
      title: 'Vertical Stacked Bar Secondary Y Axis',
      builder: _verticalStackedBarSecondaryYAxis,
    ),
    DocsSection(
      id:
          'charts-verticalstackedbarchart--vertical-stacked-bar-axis-category-'
          'order',
      title: 'Vertical Stacked Bar Axis Category Order',
      builder: _verticalStackedBarAxisCategoryOrder,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentVerticalStackedBarGroup>',
      description: 'The stacks, in author order.',
    ),
    PropRow(
      name: 'props',
      type: 'FluentCartesianChartProps',
      defaultValue: 'FluentCartesianChartProps()',
      description: 'Shell configuration: axes, margins, titles and popover.',
    ),
    PropRow(
      name: 'barWidth',
      type: 'Object?',
      defaultValue: 'null',
      description: "A width in pixels, or 'default', or 'auto'.",
    ),
    PropRow(
      name: 'maxBarWidth',
      type: 'double',
      defaultValue: '24',
      description: 'Bar width ceiling.',
    ),
    PropRow(
      name: 'barGapMax',
      type: 'double',
      defaultValue: '0',
      description: 'Maximum gap between segments; 0 disables gaps.',
    ),
    PropRow(
      name: 'barCornerRadius',
      type: 'double',
      defaultValue: '0',
      description: 'Corner radius applied to the topmost segment.',
    ),
    PropRow(
      name: 'barMinimumHeight',
      type: 'double',
      defaultValue: '0',
      description: "Floor on a segment's height.",
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description: 'Human title, folded into the accessible description.',
    ),
    PropRow(
      name: 'isCalloutForStack',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether hover and focus address the whole stack instead of one '
          'segment.',
    ),
    PropRow(
      name: 'allowHoverOnLegend',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the legend responds to hover.',
    ),
    PropRow(
      name: 'onBarClick',
      type: 'void Function(Object data)?',
      defaultValue: 'null',
      description:
          'Called with the segment, or the whole stack when isCalloutForStack.',
    ),
    PropRow(
      name: 'hideLabels',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the stack total labels are suppressed.',
    ),
    PropRow(
      name: 'roundCorners',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether segments get a 3px corner radius.',
    ),
    PropRow(
      name: 'lineOptions',
      type: 'FluentLineOptions?',
      defaultValue: 'null',
      description:
          'The chart-level line configuration; only lineBorderWidth '
          'is read.',
    ),
    PropRow(
      name: 'xAxisInnerPadding',
      type: 'double?',
      defaultValue: 'null',
      description: 'Band inner padding override.',
    ),
    PropRow(
      name: 'xAxisOuterPadding',
      type: 'double?',
      defaultValue: 'null',
      description: 'Band outer padding override.',
    ),
    PropRow(
      name: 'xAxisCategoryOrder',
      type: 'FluentAxisCategoryOrder?',
      defaultValue: 'null',
      description: 'Ordering applied to a category x axis.',
    ),
    PropRow(
      name: 'legendSelectionMode',
      type: 'FluentChartLegendSelectionMode',
      defaultValue: 'FluentChartLegendSelectionMode.single',
      description: 'Whether the legend allows more than one selection.',
    ),
  ],
);

// #docregion charts-verticalstackedbarchart--vertical-stacked-bar-default
Widget _verticalStackedBarDefault(BuildContext context) =>
    const _VerticalStackedBarDefault();

class _VerticalStackedBarDefault extends StatefulWidget {
  const _VerticalStackedBarDefault();

  @override
  State<_VerticalStackedBarDefault> createState() =>
      _VerticalStackedBarDefaultState();
}

class _VerticalStackedBarDefaultState
    extends State<_VerticalStackedBarDefault> {
  double _width = 650;
  double _height = 350;
  bool _showLine = true;
  double _barGapMax = 2;
  bool _hideLabels = false;
  bool _showAxisTitles = true;
  bool _roundCorners = false;
  bool _legendMultiSelect = false;

  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label),
      const SizedBox(width: 8),
      SizedBox(
        width: 160,
        child: FluentSlider(
          value: value,
          min: min,
          max: max,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final List<FluentStackedBarDatum> firstChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 40,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '40%',
          ),
          // CSS `darkblue`, the one colour upstream spells as a literal.
          const FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 5,
            color: Color(0xFF00008B),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '5%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 20,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '20%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata4',
            data: 10,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '10%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata5',
            data: 23,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '23%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata6',
            data: 0.4,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.4%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata7',
            data: 0.5,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.5%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata8',
            data: 0.3,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.3%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata9',
            data: 0.7,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.7%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata10',
            data: 0.1,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.1%',
          ),
        ];

    final List<FluentStackedBarDatum> secondChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '33%',
          ),
          const FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 20,
            color: Color(0xFF00008B),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '22%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 40,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '45%',
          ),
        ];

    final List<FluentStackedBarDatum> thirdChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 44,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '43%',
          ),
          const FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 28,
            color: Color(0xFF00008B),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '27%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '30%',
          ),
        ];

    final List<FluentStackedBarDatum> fourthChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 88,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '63%',
          ),
          const FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 22,
            color: Color(0xFF00008B),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '16%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '21%',
          ),
        ];

    List<FluentStackedBarLineDatum>? lines(
      List<(double, String, FluentDataVizToken)> points,
    ) => _showLine
        ? <FluentStackedBarLineDatum>[
            for (final (double y, String legend, FluentDataVizToken token)
                in points)
              FluentStackedBarLineDatum(
                y: y,
                legend: legend,
                color: FluentDataVizPalette.resolve(token),
              ),
          ]
        : null;

    final List<FluentVerticalStackedBarGroup> data =
        <FluentVerticalStackedBarGroup>[
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 0,
            lineData: lines(<(double, String, FluentDataVizToken)>[
              (42, 'Supported Builds', FluentDataVizToken.color2),
              (10, 'Recommended Builds', FluentDataVizToken.color17),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: secondChartPoints,
            xAxisPoint: 20,
            lineData: lines(<(double, String, FluentDataVizToken)>[
              (33, 'Supported Builds', FluentDataVizToken.color2),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: thirdChartPoints,
            xAxisPoint: 40,
            lineData: lines(<(double, String, FluentDataVizToken)>[
              (60, 'Supported Builds', FluentDataVizToken.color2),
              (20, 'Recommended Builds', FluentDataVizToken.color17),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 60,
            lineData: lines(<(double, String, FluentDataVizToken)>[
              (41, 'Supported Builds', FluentDataVizToken.color2),
              (10, 'Recommended Builds', FluentDataVizToken.color17),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: fourthChartPoints,
            xAxisPoint: 80,
            lineData: lines(<(double, String, FluentDataVizToken)>[
              (100, 'Supported Builds', FluentDataVizToken.color2),
              (70, 'Recommended Builds', FluentDataVizToken.color17),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 100,
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _slider(
              'Change Width:',
              'Change Width',
              _width,
              200,
              1000,
              (double value) => setState(() => _width = value),
            ),
            _slider(
              'Change Height:',
              'Change Height',
              _height,
              200,
              1000,
              (double value) => setState(() => _height = value),
            ),
            _slider(
              'BarGapMax:',
              'Change Bar Gap Max',
              _barGapMax,
              0,
              10,
              (double value) => setState(() => _barGapMax = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FluentCheckbox(
          checked: _showLine,
          label: const Text('show the lines (hide or show the lines)'),
          onChanged: (bool? value) =>
              setState(() => _showLine = value ?? false),
        ),
        const SizedBox(height: 20),
        FluentCheckbox(
          checked: _hideLabels,
          label: const Text('Hide labels'),
          onChanged: (bool? value) =>
              setState(() => _hideLabels = value ?? false),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FluentSwitch(
              checked: _showAxisTitles,
              label: Text(
                _showAxisTitles ? 'Show axis titles' : 'Hide axis titles',
              ),
              onChanged: (bool value) =>
                  setState(() => _showAxisTitles = value),
            ),
            FluentSwitch(
              checked: _roundCorners,
              label: Text(
                _roundCorners ? 'Rounded corners ON' : 'Rounded corners OFF',
              ),
              onChanged: (bool value) => setState(() => _roundCorners = value),
            ),
            FluentSwitch(
              checked: _legendMultiSelect,
              label: Text(
                _legendMultiSelect
                    ? 'legendmultiselect ON'
                    : 'legendmultiselect OFF',
              ),
              onChanged: (bool value) =>
                  setState(() => _legendMultiSelect = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // The width slider reaches past the card, so the chart box scrolls
        // sideways rather than overflowing it.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentVerticalStackedBarChart(
              chartTitle: 'Vertical stacked bar chart basic example',
              barGapMax: _barGapMax,
              data: data,
              hideLabels: _hideLabels,
              roundCorners: _roundCorners,
              lineOptions: const FluentLineOptions(lineBorderWidth: 2),
              legendSelectionMode: _legendMultiSelect
                  ? FluentChartLegendSelectionMode.multiple
                  : FluentChartLegendSelectionMode.single,
              props: FluentCartesianChartProps(
                margins: _showAxisTitles
                    ? const FluentChartMargins(
                        top: 20,
                        bottom: 55,
                        right: 40,
                        left: 60,
                      )
                    : const FluentChartMargins(
                        top: 20,
                        bottom: 35,
                        right: 20,
                        left: 40,
                      ),
                yAxisTitle: _showAxisTitles
                    ? 'Variation of number of sales'
                    : null,
                xAxisTitle: _showAxisTitles ? 'Number of days' : null,
                roundedTicks: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-verticalstackedbarchart--vertical-stacked-bar-default

// #docregion charts-verticalstackedbarchart--vertical-stacked-bar-axis-tooltip
Widget _verticalStackedBarAxisTooltip(BuildContext context) =>
    const _VerticalStackedBarAxisTooltip();

class _VerticalStackedBarAxisTooltip extends StatefulWidget {
  const _VerticalStackedBarAxisTooltip();

  @override
  State<_VerticalStackedBarAxisTooltip> createState() =>
      _VerticalStackedBarAxisTooltipState();
}

class _VerticalStackedBarAxisTooltipState
    extends State<_VerticalStackedBarAxisTooltip> {
  String _selectedCallout = 'showTooltip';
  bool _barWidthEnabled = true;
  bool _xAxisInnerPaddingEnabled = false;
  bool _xAxisOuterPaddingEnabled = false;
  double _barWidth = 16;
  double _maxBarWidth = 100;
  double _xAxisInnerPadding = 0.67;
  double _xAxisOuterPadding = 0;
  double _width = 650;
  double _height = 350;
  bool _enableGradient = false;
  bool _roundCorners = false;

  Widget _slider(
    String semanticLabel,
    double value,
    double min,
    double max,
    double step,
    ValueChanged<double>? onChanged,
  ) => SizedBox(
    width: 160,
    child: FluentSlider(
      value: value,
      min: min,
      max: max,
      step: step,
      semanticLabel: semanticLabel,
      onChanged: onChanged,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<FluentStackedBarDatum> firstChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 2,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 0.5,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 0,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          ),
        ];

    final List<FluentStackedBarDatum> secondChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 3,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 40,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          ),
        ];

    final List<FluentStackedBarDatum> thirdChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 10,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 60,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          ),
        ];

    final List<FluentVerticalStackedBarGroup> data =
        <FluentVerticalStackedBarGroup>[
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 'Simple Data',
          ),
          FluentVerticalStackedBarGroup(
            chartData: secondChartPoints,
            xAxisPoint: 'Long text will disaply all text',
          ),
          FluentVerticalStackedBarGroup(
            chartData: thirdChartPoints,
            xAxisPoint: 'Data',
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 'Meta data',
          ),
        ];

    const double barGapMax = 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 30,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('width:'),
                const SizedBox(width: 8),
                _slider(
                  'Change Width',
                  _width,
                  200,
                  1000,
                  1,
                  (double value) => setState(() => _width = value),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('height:'),
                const SizedBox(width: 8),
                _slider(
                  'Change Height',
                  _height,
                  200,
                  1000,
                  1,
                  (double value) => setState(() => _height = value),
                ),
              ],
            ),
            // Upstream's control labels carry a trailing `&nbsp;` —
            // `barWidth:&nbsp;`, `xAxisInnerPadding:&nbsp;` and
            // `xAxisOuterPadding:&nbsp;` — which is HTML for a non-breaking
            // space. Flutter has no entity syntax, so each is written with a
            // real U+00A0 below.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FluentCheckbox(
                  checked: _barWidthEnabled,
                  label: const Text('barWidth:\u00A0'),
                  onChanged: (bool? value) =>
                      setState(() => _barWidthEnabled = value ?? false),
                ),
                if (_barWidthEnabled)
                  SizedBox(
                    width: 120,
                    child: FluentSpinButton(
                      value: _barWidth,
                      min: 1,
                      max: 300,
                      semanticLabel: 'barWidth',
                      onChanged: (double? value) =>
                          setState(() => _barWidth = value ?? _barWidth),
                    ),
                  )
                else
                  const Text("'auto'"),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('maxBarWidth:\u00A0'),
                SizedBox(
                  width: 120,
                  child: FluentSpinButton(
                    value: _maxBarWidth,
                    min: 1,
                    max: 300,
                    semanticLabel: 'maxBarWidth',
                    onChanged: (double? value) =>
                        setState(() => _maxBarWidth = value ?? _maxBarWidth),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FluentCheckbox(
                  checked: _xAxisInnerPaddingEnabled,
                  label: const Text('xAxisInnerPadding:\u00A0'),
                  onChanged: (bool? value) => setState(
                    () => _xAxisInnerPaddingEnabled = value ?? false,
                  ),
                ),
                _slider(
                  'Change X Axis Inner Padding',
                  _xAxisInnerPadding,
                  0,
                  1,
                  0.01,
                  _xAxisInnerPaddingEnabled
                      ? (double value) =>
                            setState(() => _xAxisInnerPadding = value)
                      : null,
                ),
                Text('\u00A0$_xAxisInnerPadding'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FluentCheckbox(
                  checked: _xAxisOuterPaddingEnabled,
                  label: const Text('xAxisOuterPadding:\u00A0'),
                  onChanged: (bool? value) => setState(
                    () => _xAxisOuterPaddingEnabled = value ?? false,
                  ),
                ),
                _slider(
                  'Change X Axis Outer Padding',
                  _xAxisOuterPadding,
                  0,
                  1,
                  0.01,
                  _xAxisOuterPaddingEnabled
                      ? (double value) =>
                            setState(() => _xAxisOuterPadding = value)
                      : null,
                ),
                Text('\u00A0$_xAxisOuterPadding'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FluentField(
              label: const Text('Pick one'),
              child: FluentRadioGroup<String>(
                value: _selectedCallout,
                onChanged: (String value) =>
                    setState(() => _selectedCallout = value),
                children: const <Widget>[
                  FluentRadio<String>(
                    value: 'WrapTickValues',
                    label: Text('Wrap X Axis Ticks'),
                  ),
                  FluentRadio<String>(
                    value: 'showTooltip',
                    label: Text('Show Tooltip at X Axis Ticks'),
                  ),
                ],
              ),
            ),
            // `enableGradient` has no counterpart on
            // `FluentVerticalStackedBarChart`: our port paints flat segment
            // fills. The switch stays so the section keeps upstream's control
            // set, and it drives nothing.
            FluentSwitch(
              checked: _enableGradient,
              label: Text(
                _enableGradient ? 'Enable Gradient' : 'Disable Gradient',
              ),
              onChanged: (bool value) =>
                  setState(() => _enableGradient = value),
            ),
            FluentSwitch(
              checked: _roundCorners,
              label: Text(
                _roundCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
              ),
              onChanged: (bool value) => setState(() => _roundCorners = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentVerticalStackedBarChart(
              chartTitle: 'Vertical stacked bar chart axis tooltip example',
              data: data,
              barWidth: _barWidthEnabled ? _barWidth : 'auto',
              maxBarWidth: _maxBarWidth,
              xAxisInnerPadding: _xAxisInnerPaddingEnabled
                  ? _xAxisInnerPadding
                  : null,
              xAxisOuterPadding: _xAxisOuterPaddingEnabled
                  ? _xAxisOuterPadding
                  : null,
              roundCorners: _roundCorners,
              barGapMax: barGapMax,
              props: FluentCartesianChartProps(
                showXAxisLablesTooltip: _selectedCallout == 'showTooltip',
                wrapXAxisLables: _selectedCallout == 'WrapTickValues',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-verticalstackedbarchart--vertical-stacked-bar-axis-tooltip

// #docregion charts-verticalstackedbarchart--vertical-stacked-bar-callout
Widget _verticalStackedBarCallout(BuildContext context) =>
    const _VerticalStackedBarCallout();

class _VerticalStackedBarCallout extends StatefulWidget {
  const _VerticalStackedBarCallout();

  @override
  State<_VerticalStackedBarCallout> createState() =>
      _VerticalStackedBarCalloutState();
}

class _VerticalStackedBarCalloutState
    extends State<_VerticalStackedBarCallout> {
  double _width = 650;
  double _height = 350;
  double _barGapMax = 2;
  bool _showLine = true;
  String _selectedCallout = 'MultiCallout';
  double _barWidth = 16;

  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label),
      const SizedBox(width: 8),
      SizedBox(
        width: 160,
        child: FluentSlider(
          value: value,
          min: min,
          max: max,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ),
    ],
  );

  List<FluentStackedBarDatum> _points(double m1, double m2, double m3) =>
      <FluentStackedBarDatum>[
        FluentStackedBarDatum(
          legend: 'Metadata1',
          data: m1,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        ),
        FluentStackedBarDatum(
          legend: 'Metadata2',
          data: m2,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        ),
        FluentStackedBarDatum(
          legend: 'Metadata3',
          data: m3,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        ),
      ];

  List<FluentStackedBarLineDatum>? _lines(
    List<(double, FluentDataVizToken, String)> points,
  ) => _showLine
      ? <FluentStackedBarLineDatum>[
          for (final (double y, FluentDataVizToken token, String legend)
              in points)
            FluentStackedBarLineDatum(
              y: y,
              color: FluentDataVizPalette.resolve(token),
              legend: legend,
            ),
        ]
      : null;

  @override
  Widget build(BuildContext context) {
    final List<FluentStackedBarDatum> firstChartPoints = _points(40, 5, 15);
    final List<FluentStackedBarDatum> secondChartPoints = _points(30, 3, 40);
    final List<FluentStackedBarDatum> thirdChartPoints = _points(10, 60, 30);
    final List<FluentStackedBarDatum> fourthChartPoints = _points(40, 10, 30);
    final List<FluentStackedBarDatum> fifthChartPoints = _points(40, 40, 40);
    final List<FluentStackedBarDatum> sixthChartPoints = _points(40, 20, 40);
    final List<FluentStackedBarDatum> seventhChartPoints = _points(10, 80, 20);
    final List<FluentStackedBarDatum> eightChartPoints = _points(50, 50, 20);

    final List<FluentVerticalStackedBarGroup> data =
        <FluentVerticalStackedBarGroup>[
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 'Jan',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (40, FluentDataVizToken.color10, 'line1'),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: secondChartPoints,
            xAxisPoint: 'Feb',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (15, FluentDataVizToken.color10, 'line1'),
              (70, FluentDataVizToken.color7, 'line3'),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: thirdChartPoints,
            xAxisPoint: 'March',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (65, FluentDataVizToken.color5, 'line2'),
              (98, FluentDataVizToken.color7, 'line3'),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: fourthChartPoints,
            xAxisPoint: 'April',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (40, FluentDataVizToken.color10, 'line1'),
              (50, FluentDataVizToken.color5, 'line2'),
              (65, FluentDataVizToken.color7, 'line3'),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: fifthChartPoints,
            xAxisPoint: 'May',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (20, FluentDataVizToken.color10, 'line1'),
              (65, FluentDataVizToken.color5, 'line2'),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: sixthChartPoints,
            xAxisPoint: 'June',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (54, FluentDataVizToken.color5, 'line2'),
              (87, FluentDataVizToken.color7, 'line3'),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: seventhChartPoints,
            xAxisPoint: 'July',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (10, FluentDataVizToken.color10, 'line1'),
              (110, FluentDataVizToken.color7, 'line3'),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: eightChartPoints,
            xAxisPoint: 'August',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (45, FluentDataVizToken.color10, 'line1'),
              (87, FluentDataVizToken.color5, 'line2'),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 'September',
            lineData: _lines(<(double, FluentDataVizToken, String)>[
              (15, FluentDataVizToken.color10, 'line1'),
              (60, FluentDataVizToken.color7, 'line3'),
            ]),
          ),
        ];

    final bool isCustomCallout =
        _selectedCallout == 'singleCustomCallout' ||
        _selectedCallout == 'MultiCustomCallout';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _slider(
              'Change Width:',
              'Change Width',
              _width,
              200,
              1000,
              (double value) => setState(() => _width = value),
            ),
            _slider(
              'Change Height:',
              'Change Height',
              _height,
              200,
              1000,
              (double value) => setState(() => _height = value),
            ),
            _slider(
              'BarGapMax:',
              'Change Bar Gap Max',
              _barGapMax,
              0,
              10,
              (double value) => setState(() => _barGapMax = value),
            ),
            _slider(
              'BarWidth:',
              'Change Bar Width',
              _barWidth,
              1,
              50,
              (double value) => setState(() => _barWidth = value),
            ),
            Text('${_barWidth.round()}'),
          ],
        ),
        const SizedBox(height: 12),
        FluentField(
          label: const Text('Pick one'),
          child: FluentRadioGroup<String>(
            value: _selectedCallout,
            onChanged: (String value) =>
                setState(() => _selectedCallout = value),
            children: const <Widget>[
              FluentRadio<String>(
                value: 'singleCallout',
                label: Text("Single callout (won't work if lines are present)"),
              ),
              FluentRadio<String>(
                value: 'MultiCallout',
                label: Text('Stack callout'),
              ),
              FluentRadio<String>(
                value: 'singleCustomCallout',
                label: Text(
                  "single callout with custom content (won't work if lines are "
                  'present)',
                ),
              ),
              FluentRadio<String>(
                value: 'MultiCustomCallout',
                label: Text('stack callout with custom content'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FluentCheckbox(
          checked: _showLine,
          label: const Text('show the lines (hide or show the lines)'),
          onChanged: (bool? value) =>
              setState(() => _showLine = value ?? false),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentVerticalStackedBarChart(
              chartTitle: 'Vertical stacked bar chart callout example',
              barGapMax: _barGapMax,
              data: data,
              lineOptions: const FluentLineOptions(lineBorderWidth: 2),
              isCalloutForStack:
                  _selectedCallout == 'MultiCallout' ||
                  _selectedCallout == 'MultiCustomCallout',
              allowHoverOnLegend: false,
              barWidth: _barWidth,
              props: FluentCartesianChartProps(
                yAxisTickCount: 10,
                yMaxValue: 120,
                margins: const FluentChartMargins(left: 50),
                // Upstream's `onRenderCalloutPerDataPoint` and
                // `onRenderCalloutPerStack` are handed the hovered datum and
                // dump it as JSON. `popoverBuilder` is a bare `WidgetBuilder`
                // with no datum argument, so the custom body is static.
                popoverBuilder: isCustomCallout
                    ? (BuildContext context) => const Text('Custom callout')
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-verticalstackedbarchart--vertical-stacked-bar-callout

// #docregion charts-verticalstackedbarchart--vertical-stacked-bar-custom-accessibility
Widget _verticalStackedBarCustomAccessibility(BuildContext context) =>
    const _VerticalStackedBarCustomAccessibility();

class _VerticalStackedBarCustomAccessibility extends StatefulWidget {
  const _VerticalStackedBarCustomAccessibility();

  @override
  State<_VerticalStackedBarCustomAccessibility> createState() =>
      _VerticalStackedBarCustomAccessibilityState();
}

class _VerticalStackedBarCustomAccessibilityState
    extends State<_VerticalStackedBarCustomAccessibility> {
  double _width = 650;
  double _height = 350;
  bool _showLine = true;
  double _barGapMax = 2;

  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label),
      const SizedBox(width: 8),
      SizedBox(
        width: 160,
        child: FluentSlider(
          value: value,
          min: min,
          max: max,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ),
    ],
  );

  List<FluentStackedBarLineDatum>? _lines(
    List<(double, String, FluentDataVizToken)> points,
  ) => _showLine
      ? <FluentStackedBarLineDatum>[
          for (final (double y, String legend, FluentDataVizToken token)
              in points)
            FluentStackedBarLineDatum(
              y: y,
              legend: legend,
              color: FluentDataVizPalette.resolve(token),
            ),
        ]
      : null;

  @override
  Widget build(BuildContext context) {
    final List<FluentStackedBarDatum> firstChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 40,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '61%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 1-1 of 4, 2020/04/30 Metadata1 61%',
            ),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 5,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '8%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 1-2 of 4, 2020/04/30 Metadata2 8%',
            ),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 20,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '31%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 1-3 of 4, 2020/04/30 Metadata3 31%',
            ),
          ),
        ];

    final List<FluentStackedBarDatum> secondChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '33%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 2-1 of 4, 2020/04/30 Metadata1 33%',
            ),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 20,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '22%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 2-2 of 4, 2020/04/30 Metadata2 22%',
            ),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 40,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '45%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 2-3 of 4, 2020/04/30 Metadata3 45%',
            ),
          ),
        ];

    final List<FluentStackedBarDatum> thirdChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 44,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '43%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 3-1 of 4, 2020/04/30 Metadata1 43%',
            ),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 28,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '27%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 3-2 of 4, 2020/04/30 Metadata2 27%',
            ),
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '30%',
            callOutSemantics: const FluentChartSemantics(
              label: 'Bar series 3-3 of 4, 2020/04/30 Metadata3 30%',
            ),
          ),
        ];

    final List<FluentVerticalStackedBarGroup> data =
        <FluentVerticalStackedBarGroup>[
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 0,
            lineData: _lines(<(double, String, FluentDataVizToken)>[
              (42, 'Supported Builds', FluentDataVizToken.color5),
              (10, 'Recommended Builds', FluentDataVizToken.color2),
            ]),
            stackCallOutSemantics: const FluentChartSemantics(
              label:
                  'Bar stack series 1 of 3, 0 MetaDate1 61% MetaData2 8% '
                  'MetaDate3 31% Recommended Builds 10 Supported Builds 42',
            ),
          ),
          FluentVerticalStackedBarGroup(
            chartData: secondChartPoints,
            xAxisPoint: 20,
            lineData: _lines(<(double, String, FluentDataVizToken)>[
              (33, 'Supported Builds', FluentDataVizToken.color5),
            ]),
            stackCallOutSemantics: const FluentChartSemantics(
              label:
                  'Bar stack series 2 of 3, 20 MetaDate1 33% MetaData2 22% '
                  'MetaDate3 45% Supported Builds 33',
            ),
          ),
          FluentVerticalStackedBarGroup(
            chartData: thirdChartPoints,
            xAxisPoint: 40,
            lineData: _lines(<(double, String, FluentDataVizToken)>[
              (60, 'Supported Builds', FluentDataVizToken.color5),
              (20, 'Recommended Builds', FluentDataVizToken.color2),
            ]),
            stackCallOutSemantics: const FluentChartSemantics(
              label:
                  'Bar stack series 3 of 3, 40 MetaDate1 43% MetaData 27% '
                  'MetaDate3 30% Recommended Builds 20 Supported Builds 60',
            ),
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _slider(
              'Change Width:',
              'Change Width',
              _width,
              200,
              1000,
              (double value) => setState(() => _width = value),
            ),
            _slider(
              'Change Height:',
              'Change Height',
              _height,
              200,
              1000,
              (double value) => setState(() => _height = value),
            ),
            _slider(
              'BarGapMax:',
              'Change Bar Gap Max',
              _barGapMax,
              0,
              10,
              (double value) => setState(() => _barGapMax = value),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FluentCheckbox(
          checked: _showLine,
          label: const Text('show the lines (hide or show the lines)'),
          onChanged: (bool? value) =>
              setState(() => _showLine = value ?? false),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentVerticalStackedBarChart(
              chartTitle:
                  'Vertical stacked bar chart custom accessibility example',
              barGapMax: _barGapMax,
              data: data,
              lineOptions: const FluentLineOptions(lineBorderWidth: 2),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-verticalstackedbarchart--vertical-stacked-bar-custom-accessibility

// #docregion charts-verticalstackedbarchart--vertical-stacked-bar-date-axis
Widget _verticalStackedBarDateAxis(BuildContext context) =>
    const _VerticalStackedBarDateAxis();

class _VerticalStackedBarDateAxis extends StatefulWidget {
  const _VerticalStackedBarDateAxis();

  @override
  State<_VerticalStackedBarDateAxis> createState() =>
      _VerticalStackedBarDateAxisState();
}

class _VerticalStackedBarDateAxisState
    extends State<_VerticalStackedBarDateAxis> {
  double _width = 650;
  double _height = 350;
  double _barGapMax = 2;
  double _barCornerRadius = 2;
  double _barMinimumHeight = 1;
  String _selectedCallout = 'MultiCallout';

  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label),
      const SizedBox(width: 8),
      SizedBox(
        width: 160,
        child: FluentSlider(
          value: value,
          min: min,
          max: max,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ),
    ],
  );

  List<FluentStackedBarDatum> _points(double one, double two, double three) =>
      <FluentStackedBarDatum>[
        FluentStackedBarDatum(
          legend: 'meta data 1',
          data: one,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
        ),
        FluentStackedBarDatum(
          legend: 'Meta data 2',
          data: two,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
        ),
        FluentStackedBarDatum(
          legend: 'meta Data 3',
          data: three,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final List<FluentStackedBarDatum> firstChartPoints = _points(2, 0.5, 0);
    final List<FluentStackedBarDatum> secondChartPoints = _points(30, 3, 40);
    final List<FluentStackedBarDatum> thirdChartPoints = _points(10, 60, 30);

    final List<FluentVerticalStackedBarGroup> data =
        <FluentVerticalStackedBarGroup>[
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: DateTime(2018, 3),
          ),
          FluentVerticalStackedBarGroup(
            chartData: secondChartPoints,
            xAxisPoint: DateTime(2018, 5),
          ),
          FluentVerticalStackedBarGroup(
            chartData: thirdChartPoints,
            xAxisPoint: DateTime(2018, 7),
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: DateTime(2018, 9),
          ),
          FluentVerticalStackedBarGroup(
            chartData: thirdChartPoints,
            xAxisPoint: DateTime(2018, 11),
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: DateTime(2019, 2),
          ),
          FluentVerticalStackedBarGroup(
            chartData: secondChartPoints,
            xAxisPoint: DateTime(2019, 5),
          ),
          FluentVerticalStackedBarGroup(
            chartData: thirdChartPoints,
            xAxisPoint: DateTime(2019, 7),
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: DateTime(2019, 9),
          ),
        ];

    final List<Object> tickValues = <Object>[
      DateTime(2018, 3),
      DateTime(2018, 5),
      DateTime(2018, 7),
      DateTime(2018, 9),
      DateTime(2018, 11),
      DateTime(2019, 2),
      DateTime(2019, 5),
      DateTime(2019, 7),
      DateTime(2019, 9),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _slider(
              'Width:',
              'Change Width',
              _width,
              200,
              1000,
              (double value) => setState(() => _width = value),
            ),
            _slider(
              'Height:',
              'Change Height',
              _height,
              200,
              1000,
              (double value) => setState(() => _height = value),
            ),
            _slider(
              'BarGapMax:',
              'Change Bar Gap Max',
              _barGapMax,
              0,
              10,
              (double value) => setState(() => _barGapMax = value),
            ),
            _slider(
              'BarCornerRadius:',
              'Change Bar Corner Radius',
              _barCornerRadius,
              0,
              10,
              (double value) => setState(() => _barCornerRadius = value),
            ),
            _slider(
              'BarMinimumHeight:',
              'Change Bar Minimum Height',
              _barMinimumHeight,
              0,
              10,
              (double value) => setState(() => _barMinimumHeight = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FluentField(
          label: const Text('Pick one'),
          child: FluentRadioGroup<String>(
            value: _selectedCallout,
            onChanged: (String value) =>
                setState(() => _selectedCallout = value),
            children: const <Widget>[
              FluentRadio<String>(
                value: 'singleCallout',
                label: Text('Single callout'),
              ),
              FluentRadio<String>(
                value: 'MultiCallout',
                label: Text('Stack callout'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          container: true,
          label: 'Example chart with metadata per month',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _width,
              height: _height,
              child: FluentVerticalStackedBarChart(
                chartTitle: 'Vertical stacked bar chart styled example',
                data: data,
                barGapMax: _barGapMax,
                barCornerRadius: _barCornerRadius,
                barMinimumHeight: _barMinimumHeight,
                isCalloutForStack: _selectedCallout == 'MultiCallout',
                onBarClick: (Object clickData) =>
                    debugPrint('clicked $clickData'),
                props: FluentCartesianChartProps(
                  yAxisTickCount: 10,
                  tickValues: tickValues,
                  // Upstream passes the d3 time format `'%m/%d'`; our port takes
                  // a formatter callback instead of a format string.
                  customDateTimeFormatter: (DateTime date) =>
                      '${date.month.toString().padLeft(2, '0')}/'
                      '${date.day.toString().padLeft(2, '0')}',
                  yMaxValue: 120,
                  yAxisTickFormat: (double x) => '${x.toStringAsFixed(0)} h',
                  margins: const FluentChartMargins(
                    bottom: 35,
                    top: 10,
                    left: 35,
                    right: 0,
                  ),
                  useUTC: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-verticalstackedbarchart--vertical-stacked-bar-date-axis

// #docregion charts-verticalstackedbarchart--vertical-stacked-bar-negative
Widget _verticalStackedBarNegative(BuildContext context) =>
    const _VerticalStackedBarNegative();

class _VerticalStackedBarNegative extends StatefulWidget {
  const _VerticalStackedBarNegative();

  @override
  State<_VerticalStackedBarNegative> createState() =>
      _VerticalStackedBarNegativeState();
}

class _VerticalStackedBarNegativeState
    extends State<_VerticalStackedBarNegative> {
  double _width = 650;
  double _height = 350;
  double _barGapMax = 2;
  bool _showLine = true;
  bool _hideLabels = false;
  bool _showAxisTitles = true;
  bool _roundCorners = false;
  bool _legendMultiSelect = false;

  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label),
      const SizedBox(width: 8),
      SizedBox(
        width: 160,
        child: FluentSlider(
          value: value,
          min: min,
          max: max,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ),
    ],
  );

  List<FluentStackedBarLineDatum>? _lines(
    List<(double, String, FluentDataVizToken)> points,
  ) => _showLine
      ? <FluentStackedBarLineDatum>[
          for (final (double y, String legend, FluentDataVizToken token)
              in points)
            FluentStackedBarLineDatum(
              y: y,
              legend: legend,
              color: FluentDataVizPalette.resolve(token),
            ),
        ]
      : null;

  @override
  Widget build(BuildContext context) {
    final List<FluentStackedBarDatum> firstChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 40,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '68%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 5,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '8.5%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: -20,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '34%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata4',
            data: 10,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '17%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata5',
            data: 23,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '39%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata6',
            data: 0.4,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.7%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata7',
            data: -0.5,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.85%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata8',
            data: -0.3,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.5%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata9',
            data: 0.7,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '1.2%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata10',
            data: 0.1,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '0.2%',
          ),
        ];

    final List<FluentStackedBarDatum> secondChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: -30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '33%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: -20,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '22%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: -40,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '45%',
          ),
        ];

    final List<FluentStackedBarDatum> thirdChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 44,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '43%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 28,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '27%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '30%',
          ),
        ];

    final List<FluentStackedBarDatum> fourthChartPoints =
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            legend: 'Metadata1',
            data: 88,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '63%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata2',
            data: 22,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '16%',
          ),
          FluentStackedBarDatum(
            legend: 'Metadata3',
            data: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            xAxisCalloutData: '2020/04/30',
            yAxisCalloutData: '21%',
          ),
        ];

    final List<FluentVerticalStackedBarGroup> data =
        <FluentVerticalStackedBarGroup>[
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 0,
            lineData: _lines(<(double, String, FluentDataVizToken)>[
              (42, 'Supported Builds', FluentDataVizToken.color5),
              (10, 'Recommended Builds', FluentDataVizToken.color9),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: secondChartPoints,
            xAxisPoint: 20,
            lineData: _lines(<(double, String, FluentDataVizToken)>[
              (33, 'Supported Builds', FluentDataVizToken.color5),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: thirdChartPoints,
            xAxisPoint: 40,
            lineData: _lines(<(double, String, FluentDataVizToken)>[
              (60, 'Supported Builds', FluentDataVizToken.color5),
              (20, 'Recommended Builds', FluentDataVizToken.color9),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 60,
            lineData: _lines(<(double, String, FluentDataVizToken)>[
              (41, 'Supported Builds', FluentDataVizToken.color5),
              (10, 'Recommended Builds', FluentDataVizToken.color9),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: fourthChartPoints,
            xAxisPoint: 80,
            lineData: _lines(<(double, String, FluentDataVizToken)>[
              (100, 'Supported Builds', FluentDataVizToken.color5),
              (70, 'Recommended Builds', FluentDataVizToken.color9),
            ]),
          ),
          FluentVerticalStackedBarGroup(
            chartData: firstChartPoints,
            xAxisPoint: 100,
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _slider(
              'Change Width:',
              'Change Width',
              _width,
              200,
              1000,
              (double value) => setState(() => _width = value),
            ),
            _slider(
              'Change Height:',
              'Change Height',
              _height,
              200,
              1000,
              (double value) => setState(() => _height = value),
            ),
            _slider(
              'BarGapMax:',
              'Change Bar Gap Max',
              _barGapMax,
              0,
              10,
              (double value) => setState(() => _barGapMax = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FluentCheckbox(
          checked: _showLine,
          label: const Text('show the lines (hide or show the lines)'),
          onChanged: (bool? value) =>
              setState(() => _showLine = value ?? false),
        ),
        const SizedBox(height: 20),
        FluentCheckbox(
          checked: _hideLabels,
          label: const Text('Hide labels'),
          onChanged: (bool? value) =>
              setState(() => _hideLabels = value ?? false),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FluentSwitch(
              checked: _showAxisTitles,
              label: Text(
                _showAxisTitles ? 'Show axis titles' : 'Hide axis titles',
              ),
              onChanged: (bool value) =>
                  setState(() => _showAxisTitles = value),
            ),
            FluentSwitch(
              checked: _roundCorners,
              label: Text(
                _roundCorners ? 'Rounded corners ON' : 'Rounded corners OFF',
              ),
              onChanged: (bool value) => setState(() => _roundCorners = value),
            ),
            FluentSwitch(
              checked: _legendMultiSelect,
              label: Text(
                _legendMultiSelect
                    ? 'legendmultiselect ON'
                    : 'legendmultiselect OFF',
              ),
              onChanged: (bool value) =>
                  setState(() => _legendMultiSelect = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentVerticalStackedBarChart(
              chartTitle: 'Vertical stacked bar chart basic example',
              barGapMax: _barGapMax,
              data: data,
              hideLabels: _hideLabels,
              roundCorners: _roundCorners,
              lineOptions: const FluentLineOptions(lineBorderWidth: 2),
              legendSelectionMode: _legendMultiSelect
                  ? FluentChartLegendSelectionMode.multiple
                  : FluentChartLegendSelectionMode.single,
              props: FluentCartesianChartProps(
                margins: _showAxisTitles
                    ? const FluentChartMargins(
                        top: 20,
                        bottom: 55,
                        right: 40,
                        left: 60,
                      )
                    : const FluentChartMargins(
                        top: 20,
                        bottom: 35,
                        right: 20,
                        left: 40,
                      ),
                reflowMode: FluentChartReflowMode.minWidth,
                yAxisTitle: _showAxisTitles
                    ? 'Variation of number of sales'
                    : null,
                xAxisTitle: _showAxisTitles ? 'Number of days' : null,
                roundedTicks: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-verticalstackedbarchart--vertical-stacked-bar-negative

// #docregion charts-verticalstackedbarchart--vertical-stacked-bar-secondary-y-axis
Widget _verticalStackedBarSecondaryYAxis(BuildContext context) =>
    const _VerticalStackedBarSecondaryYAxis();

class _VerticalStackedBarSecondaryYAxis extends StatefulWidget {
  const _VerticalStackedBarSecondaryYAxis();

  @override
  State<_VerticalStackedBarSecondaryYAxis> createState() =>
      _VerticalStackedBarSecondaryYAxisState();
}

class _VerticalStackedBarSecondaryYAxisState
    extends State<_VerticalStackedBarSecondaryYAxis> {
  double _width = 700;
  double _height = 300;

  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    ValueChanged<double> onChanged,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label),
      const SizedBox(width: 8),
      SizedBox(
        width: 160,
        child: FluentSlider(
          value: value,
          min: 200,
          max: 1000,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ),
    ],
  );

  List<FluentStackedBarDatum> _points(
    double electronics,
    double furniture,
    double clothing,
    double groceries,
    double toys,
  ) => <FluentStackedBarDatum>[
    FluentStackedBarDatum(
      legend: 'Electronics',
      data: electronics,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
    ),
    FluentStackedBarDatum(
      legend: 'Furniture',
      data: furniture,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
    ),
    FluentStackedBarDatum(
      legend: 'Clothing',
      data: clothing,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
    ),
    FluentStackedBarDatum(
      legend: 'Groceries',
      data: groceries,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
    ),
    FluentStackedBarDatum(
      legend: 'Toys',
      data: toys,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
    ),
  ];

  List<FluentStackedBarLineDatum> _salesTarget(double y) =>
      <FluentStackedBarLineDatum>[
        FluentStackedBarLineDatum(
          y: y,
          legend: 'Sales Target',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
          useSecondaryYScale: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final List<FluentVerticalStackedBarGroup> data =
        <FluentVerticalStackedBarGroup>[
          FluentVerticalStackedBarGroup(
            chartData: _points(120, 80, 150, 200, 90),
            xAxisPoint: 0,
            lineData: _salesTarget(150),
          ),
          FluentVerticalStackedBarGroup(
            chartData: _points(140, 100, 130, 220, 110),
            xAxisPoint: 20,
            lineData: _salesTarget(180),
          ),
          FluentVerticalStackedBarGroup(
            chartData: _points(160, 120, 140, 250, 100),
            xAxisPoint: 40,
            lineData: _salesTarget(200),
          ),
          FluentVerticalStackedBarGroup(
            chartData: _points(180, 140, 160, 300, 120),
            xAxisPoint: 60,
            lineData: _salesTarget(250),
          ),
        ];

    const double barGapMax = 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _slider(
              'Change Width:',
              'Change Width',
              _width,
              (double value) => setState(() => _width = value),
            ),
            _slider(
              'Change Height:',
              'Change Height',
              _height,
              (double value) => setState(() => _height = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentVerticalStackedBarChart(
              chartTitle: 'Vertical stacked bar chart secondary y-axis example',
              data: data,
              barGapMax: barGapMax,
              lineOptions: const FluentLineOptions(lineBorderWidth: 2),
              props: const FluentCartesianChartProps(
                yAxisTitle: 'Variation of number of sales',
                xAxisTitle: 'Number of days',
                secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-verticalstackedbarchart--vertical-stacked-bar-secondary-y-axis

// #docregion charts-verticalstackedbarchart--vertical-stacked-bar-axis-category-order
Widget _verticalStackedBarAxisCategoryOrder(BuildContext context) =>
    const _VerticalStackedBarAxisCategoryOrder();

class _VerticalStackedBarAxisCategoryOrder extends StatefulWidget {
  const _VerticalStackedBarAxisCategoryOrder();

  @override
  State<_VerticalStackedBarAxisCategoryOrder> createState() =>
      _VerticalStackedBarAxisCategoryOrderState();
}

/// The generated data set, and the y bounds it needs.
class _CategoryOrderData {
  const _CategoryOrderData(this.data, this.yMinValue, this.yMaxValue);

  final List<FluentVerticalStackedBarGroup> data;
  final double yMinValue;
  final double yMaxValue;
}

class _VerticalStackedBarAxisCategoryOrderState
    extends State<_VerticalStackedBarAxisCategoryOrder> {
  static const List<String> _axisCategoryOrderOptions = <String>[
    'default',
    'data',
    'category ascending',
    'category descending',
    'total ascending',
    'total descending',
    'min ascending',
    'min descending',
    'max ascending',
    'max descending',
    'sum ascending',
    'sum descending',
    'mean ascending',
    'mean descending',
    'median ascending',
    'median descending',
  ];

  static const int _initialDataSize = 5;

  // `dart:math` is outside this example's import budget, so upstream's
  // `Math.random()` becomes a MINSTD generator. Its multiplier keeps every
  // product under 2^53, which is what makes it safe on the web where a Dart
  // `int` is a double. Deterministic, which suits a docs page anyway; "Change
  // data" advances the stream exactly as upstream's button does.
  int _seed = 42;

  double _random() {
    _seed = (_seed * 16807) % 2147483647;
    return _seed / 2147483647;
  }

  late _CategoryOrderData _current = _getData(_initialDataSize);
  double _width = 650;
  double _height = 350;
  double _dataSize = _initialDataSize.toDouble();
  String _xAxisCategoryOrder = 'default';
  String _statusMessage = '';

  _CategoryOrderData _getData(int dataSize) {
    final Map<String, List<FluentStackedBarDatum>> mapXToDataPoints =
        <String, List<FluentStackedBarDatum>>{};
    for (int i = 0; i < dataSize; i++) {
      final double data = (_random() * 200).floorToDouble() - 100;
      final String xAxisPoint = 'Label ${(_random() * i).floor() + 1}';
      final int legendIdx = (_random() * i).floor();
      mapXToDataPoints
          .putIfAbsent(xAxisPoint, () => <FluentStackedBarDatum>[])
          .add(
            FluentStackedBarDatum(
              data: data,
              legend: 'Legend ${legendIdx + 1}',
              color: FluentDataVizPalette.next(legendIdx),
            ),
          );
    }

    final List<FluentVerticalStackedBarGroup> data =
        <FluentVerticalStackedBarGroup>[
          for (final MapEntry<String, List<FluentStackedBarDatum>> entry
              in mapXToDataPoints.entries)
            FluentVerticalStackedBarGroup(
              xAxisPoint: entry.key,
              chartData: entry.value,
            ),
        ];

    final List<double> values = <double>[];
    for (final FluentVerticalStackedBarGroup point in data) {
      double positiveSum = 0;
      double negativeSum = 0;
      for (final FluentStackedBarDatum bar in point.chartData) {
        final double value = bar.data as double;
        if (value >= 0) {
          positiveSum += value;
        } else {
          negativeSum += value;
        }
      }
      values
        ..add(positiveSum)
        ..add(negativeSum);
    }

    // Upstream's `Math.min(...[])` is Infinity on an empty set; a data size of
    // zero draws nothing either way, so zero stands in for it here.
    double lowest = values.isEmpty ? 0 : values.first;
    double highest = values.isEmpty ? 0 : values.first;
    for (final double value in values) {
      if (value < lowest) lowest = value;
      if (value > highest) highest = value;
    }

    return _CategoryOrderData(data, lowest, highest);
  }

  void _changeData() => setState(() {
    _current = _getData(_dataSize.round());
    _statusMessage = 'Vertical stacked bar chart with Axis data changed';
  });

  Widget _slider(
    String label,
    String semanticLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label),
      const SizedBox(width: 8),
      SizedBox(
        width: 160,
        child: FluentSlider(
          value: value,
          min: min,
          max: max,
          step: 1,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ),
      const SizedBox(width: 8),
      Text('${value.round()}'),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 30,
        runSpacing: 15,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _slider(
            'Width:',
            'Change Width',
            _width,
            200,
            1000,
            (double value) => setState(() => _width = value),
          ),
          _slider(
            'Height:',
            'Change Height',
            _height,
            200,
            1000,
            (double value) => setState(() => _height = value),
          ),
          _slider(
            'Data Size:',
            'Change Data Size',
            _dataSize,
            0,
            50,
            (double value) => setState(() {
              _dataSize = value;
              _current = _getData(value.round());
            }),
          ),
          FluentField(
            label: const Text('xAxisCategoryOrder:'),
            child: SizedBox(
              width: 220,
              child: FluentDropdown<String>(
                value: _xAxisCategoryOrder,
                options: <FluentDropdownOption<String>>[
                  for (final String option in _axisCategoryOrderOptions)
                    FluentDropdownOption<String>(
                      value: option,
                      label: Text(option),
                    ),
                ],
                onChanged: (String value) =>
                    setState(() => _xAxisCategoryOrder = value),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentVerticalStackedBarChart(
            data: _current.data,
            barGapMax: 2,
            lineOptions: const FluentLineOptions(lineBorderWidth: 2),
            xAxisCategoryOrder: FluentAxisCategoryOrder.parse(
              _xAxisCategoryOrder,
            ),
            props: FluentCartesianChartProps(
              hideLegend: true,
              yMinValue: _current.yMinValue,
              yMaxValue: _current.yMaxValue,
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      FluentButton(onPressed: _changeData, child: const Text('Change data')),
      // Upstream keeps the status text visually hidden and announces it through
      // an `aria-live` region; `Semantics.liveRegion` is the same contract
      // without the clip rectangle.
      Semantics(
        liveRegion: true,
        label: _statusMessage,
        child: const SizedBox.shrink(),
      ),
    ],
  );
}

// #enddocregion charts-verticalstackedbarchart--vertical-stacked-bar-axis-category-order
