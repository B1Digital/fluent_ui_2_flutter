import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The VerticalBarChart docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Every demo is
/// delimited by a `#docregion` whose id is the section id, so the "Show code"
/// panel prints exactly the code that rendered.
const DocsPage verticalBarChartPage = DocsPage(
  id: 'charts-verticalbarchart',
  title: 'VerticalBarChart',
  description:
      'A vertical bar chart displays data as a series of vertical bars, '
      'with each bar representing a category and the height of the bar '
      'representing the value of that category. It is commonly used to '
      'show comparisons between categories of one or more data sets, '
      'usually over a period of time. Categories are shown on the '
      'horizontal axis, while the data values are shown along the '
      'vertical axis. They could present data over time or in '
      'relationship to a whole.',
  source: 'lib/pages/charts_verticalbarchart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'The default bar width is 16px. For dense data, it can be as '
          'thin as 8px wide. Always consider the visual weight of the '
          'bars in relationship to the rest of the app before choosing '
          'this type of chart.\n'
          'The padding around the bar chart is a default of 8px from '
          'the x and y-axis container. This gives enough room for '
          'additional content like label values to display properly '
          'without overlapping on to the X-axis ticks. A 2:1 spacing is '
          'maintained between all the bars in the graph so that space '
          'between two bars is always two times the bar width. This '
          'helps to ensure that the graph is not overpowering other '
          'data visualizations.\n'
          'For charts that display monetary values, the dollar symbol '
          'should be displayed as part of the total value. Also call '
          'out the currency in the chart title to provide additional '
          'context. Chart title can be used to communicate currency '
          'when the total labels are hidden.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- **Bar segment** Bar segments make up a bar chart. Standard '
          'size options are: 8px, 16px, and 24px with 16px being the '
          'default.\n'
          '- **Value labels** (Optional - Off by default) with the '
          'option to toggle on in case the data visualization needs to '
          'communicate label values to users.\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          'Bar graphs should be flexible to their containers. They will '
          'change widths to fit their environment. This also means that '
          'bar labels will rotate or truncate to best fit the available '
          'space in the chart (Auto adjusting labels coming soon).\n'
          'Type truncation should happen when the total value exceeds '
          'one thousand including 1 decimal place for the hundreds. For '
          'example, display full value for 600, 983, or 19.53. Truncate '
          '6,000 to 6.0K, 9,801 to 9.8K, and 100,900 to 100.9K.\n',
    ),
    ProseBlock(
      title: 'Customizing the chart',
      body:
          '- The chart provides an option to select a color scale based '
          'on the range of y values. Similar y values will end up '
          'having similar colors. Use the `colors` attribute to define '
          'the color scale.\n'
          '- Use `useSingleColor` to use a single color for all bars.\n'
          '- Use `lineLegendText` and `lineLegendColor` to specify the '
          'text and color for legends of lines in the chart.\n'
          '- The bar labels are shown by default. Set the `hideLabels` '
          'prop to hide them.\n'
          '- Use the `barWidth` prop to customize the width of each bar '
          'in the chart. When set to `undefined` or `\'default\'`, the '
          'bar width defaults to 16px, which may decrease to prevent '
          'overlap. When set to `\'auto\'`, the bar width is calculated '
          'from padding values. For a fixed bar width, specify an '
          'absolute pixel value like `40`.\n'
          '- Use the `maxBarWidth` prop to limit the width of bars to a '
          'specified number of pixels.\n'
          '- Use the `xAxisInnerPadding` and `xAxisOuterPadding` props '
          'to adjust the padding between bars and the padding before '
          'the first bar and after the last bar, respectively. These '
          'props accept values between 0 and 1, representing a fraction '
          'of the `step`, which is the interval between the start of a '
          'bar and the start of the next bar. These props are '
          'particularly relevant when using a string x-axis. By '
          'default, the inner padding is set to 2/3, maintaining a 2:1 '
          'spacing ratio. This default value is calculated using the '
          'formula:\n'
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
      body:
          '- Try to keep the number of bars in the chart between 3 and '
          '20 to maximize readability.\n',
    ),
    ProseBlock(
      title: 'Don\'ts',
      body:
          '- Don\'t use very long labels in vertical bar chart. Long '
          'labels use unnecessary space and make the chart skewed. For '
          'long labels use horizontal bar chart with axis.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-default',
      title: 'Vertical Bar Default',
      builder: _verticalBarDefault,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-custom-accessibility',
      title: 'Vertical Bar Custom Accessibility',
      builder: _verticalBarCustomAccessibility,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-date-axis',
      title: 'Vertical Bar Date Axis',
      builder: _verticalBarDateAxis,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-axis-tooltip',
      title: 'Vertical Bar Axis Tooltip',
      builder: _verticalBarAxisTooltip,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-rotate-labels',
      title: 'Vertical Bar Rotate Labels',
      builder: _verticalBarRotateLabels,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-styled',
      title: 'Vertical Bar Styled',
      builder: _verticalBarStyled,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-dynamic',
      title: 'Vertical Bar Dynamic',
      builder: _verticalBarDynamic,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-all-negative',
      title: 'Vertical Bar All Negative',
      builder: _verticalBarAllNegative,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-negative',
      title: 'Vertical Bar Negative',
      builder: _verticalBarNegative,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-chart-responsive',
      title: 'Vertical Bar Chart Responsive',
      builder: _verticalBarChartResponsive,
    ),
    DocsSection(
      id: 'charts-verticalbarchart--vertical-bar-secondary-y-axis',
      title: 'Vertical Bar Secondary Y Axis',
      builder: _verticalBarSecondaryYAxis,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentVerticalBarChartDataPoint>',
      description: 'The bars, in author order.',
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
      name: 'colors',
      type: 'List<Color>?',
      defaultValue: 'null',
      description: 'Replaces the five default palette tokens.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description: 'Human title, folded into the accessible description.',
    ),
    PropRow(
      name: 'lineLegendText',
      type: 'String?',
      defaultValue: 'null',
      description: 'Legend title for the overlaid line.',
    ),
    PropRow(
      name: 'lineLegendColor',
      type: 'Color?',
      defaultValue: 'null',
      description:
          "Overrides the line's stroke, its dots' rings and the legend swatch.",
    ),
    PropRow(
      name: 'lineOptions',
      type: 'FluentLineOptions?',
      defaultValue: 'null',
      description: 'How the overlaid line is stroked.',
    ),
    PropRow(
      name: 'useSingleColor',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether every bar takes a single colour.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'BCP-47 locale for popover formatting.',
    ),
    PropRow(
      name: 'xAxisPadding',
      type: 'double?',
      defaultValue: 'null',
      description: 'Legacy shorthand feeding both band paddings.',
    ),
    PropRow(
      name: 'hideLabels',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether bar labels are suppressed.',
    ),
    PropRow(
      name: 'xAxisInnerPadding',
      type: 'double?',
      defaultValue: 'null',
      description: 'Band inner padding override, in the range 0 to 1.',
    ),
    PropRow(
      name: 'xAxisOuterPadding',
      type: 'double?',
      defaultValue: 'null',
      description: 'Band outer padding override, in the range 0 to 1.',
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
      description: "'plotly', 'histogram' or null.",
    ),
    PropRow(
      name: 'xAxisCategoryOrder',
      type: 'FluentAxisCategoryOrder',
      defaultValue: 'FluentAxisCategoryOrder.defaultOrder',
      description: 'Ordering applied to a category x axis.',
    ),
    PropRow(
      name: 'legendSelectionMode',
      type: 'FluentChartLegendSelectionMode',
      defaultValue: 'FluentChartLegendSelectionMode.single',
      description: 'Whether the legend allows more than one selection.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentVerticalBarChartStyle?',
      defaultValue: 'null',
      description: 'Style override, highest precedence.',
    ),
  ],
);

// #docregion charts-verticalbarchart--vertical-bar-default
Widget _verticalBarDefault(BuildContext context) => const _VerticalBarDefault();

class _VerticalBarDefault extends StatefulWidget {
  const _VerticalBarDefault();

  @override
  State<_VerticalBarDefault> createState() => _VerticalBarDefaultState();
}

class _VerticalBarDefaultState extends State<_VerticalBarDefault> {
  double _width = 650;
  double _height = 350;
  String? _calloutExample;
  bool _useSingleColor = false;
  bool _hideLabels = false;
  bool _showAxisTitles = false;
  bool _selectMultipleLegends = false;

  static const List<FluentVerticalBarChartDataPoint> _points =
      <FluentVerticalBarChartDataPoint>[
        FluentVerticalBarChartDataPoint(
          x: 0,
          y: 10000,
          legend: 'Oranges',
          color: Color(0xFF1E90FF), // dodgerblue
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '4%',
          lineData: FluentBarLineDatum(y: 7000, yAxisCalloutData: '3%'),
        ),
        FluentVerticalBarChartDataPoint(
          x: 10000,
          y: 50000,
          legend: 'Dogs',
          color: Color(0xFF191970), // midnightblue
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '21%',
          lineData: FluentBarLineDatum(y: 30000, yAxisCalloutData: '12%'),
        ),
        FluentVerticalBarChartDataPoint(
          x: 25000,
          y: 30000,
          legend: 'Apples',
          color: Color(0xFF00008B), // darkblue
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '12%',
          lineData: FluentBarLineDatum(y: 3000, yAxisCalloutData: '1%'),
        ),
        FluentVerticalBarChartDataPoint(
          x: 40000,
          y: 13000,
          legend: 'Bananas',
          color: Color(0xFF0000FF), // blue
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '5%',
        ),
        FluentVerticalBarChartDataPoint(
          x: 52000,
          y: 43000,
          legend: 'Giraffes',
          color: Color(0xFF483D8B), // darkslateblue
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '18%',
          lineData: FluentBarLineDatum(y: 30000, yAxisCalloutData: '12%'),
        ),
        FluentVerticalBarChartDataPoint(
          x: 68000,
          y: 30000,
          legend: 'Cats',
          color: Color(0xFF4169E1), // royalblue
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '12%',
          lineData: FluentBarLineDatum(y: 5000, yAxisCalloutData: '2%'),
        ),
        FluentVerticalBarChartDataPoint(
          x: 80000,
          y: 20000,
          legend: 'Elephants',
          color: Color(0xFF6A5ACD), // slateblue
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '8%',
          lineData: FluentBarLineDatum(y: 16000, yAxisCalloutData: '7%'),
        ),
        FluentVerticalBarChartDataPoint(
          x: 92000,
          y: 45000,
          legend: 'Monkeys',
          color: Color(0xFF4682B4), // steelblue
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '19%',
          lineData: FluentBarLineDatum(y: 40000, yAxisCalloutData: '16%'),
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
      // Upstream's radio pair swaps in `onRenderCalloutPerDataPoint`, which is
      // commented out in the story source, so neither choice changes the chart.
      // The port keeps the control and the same inert behaviour.
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _calloutExample,
          onChanged: (String value) => setState(() => _calloutExample = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'Basic Example',
              label: Text('Basic Example'),
            ),
            FluentRadio<String>(
              value: 'Custom Callout Example',
              label: Text('Custom Callout Example'),
            ),
          ],
        ),
      ),
      FluentCheckbox(
        checked: _useSingleColor,
        onChanged: (bool? value) =>
            setState(() => _useSingleColor = value ?? false),
        label: const Text('use single color(This will have only one color)'),
      ),
      FluentCheckbox(
        checked: _hideLabels,
        onChanged: (bool? value) =>
            setState(() => _hideLabels = value ?? false),
        label: const Text('Hide labels'),
      ),
      FluentSwitch(
        checked: _showAxisTitles,
        onChanged: (bool value) => setState(() => _showAxisTitles = value),
        label: Text(_showAxisTitles ? 'Show axis titles' : 'Hide axis titles'),
      ),
      FluentSwitch(
        checked: _selectMultipleLegends,
        onChanged: (bool value) =>
            setState(() => _selectMultipleLegends = value),
        label: const Text('Select Multiple Legends'),
      ),
      // The slider reaches 1000, which is wider than the docs column, so the
      // chart box scrolls rather than overflowing.
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentVerticalBarChart(
            chartTitle: 'Vertical bar chart basic example ',
            culture: 'en-us',
            data: _points,
            useSingleColor: _useSingleColor,
            hideLabels: _hideLabels,
            lineLegendText: 'just line',
            lineLegendColor: const Color(0xFFA52A2A), // brown
            lineOptions: const FluentLineOptions(lineBorderWidth: 2),
            legendSelectionMode: _selectMultipleLegends
                ? FluentChartLegendSelectionMode.multiple
                : FluentChartLegendSelectionMode.single,
            props: FluentCartesianChartProps(
              yAxisTitle: _showAxisTitles
                  ? 'Different categories of animals and fruits and their '
                        'corresponding count are shown here'
                  : null,
              xAxisTitle: _showAxisTitles
                  ? 'Values of each category are shown in the x-axis of the '
                        'vertical bar chart whose values range from zero to '
                        '100,000. The x-axis is divided into 10 equal parts, '
                        'each part representing 10,000.'
                  : null,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-verticalbarchart--vertical-bar-default

// #docregion charts-verticalbarchart--vertical-bar-custom-accessibility
Widget _verticalBarCustomAccessibility(BuildContext context) =>
    const _VerticalBarCustomAccessibility();

class _VerticalBarCustomAccessibility extends StatefulWidget {
  const _VerticalBarCustomAccessibility();

  @override
  State<_VerticalBarCustomAccessibility> createState() =>
      _VerticalBarCustomAccessibilityState();
}

class _VerticalBarCustomAccessibilityState
    extends State<_VerticalBarCustomAccessibility> {
  bool _isChecked = true;
  bool _useSingleColor = true;

  /// `callOutAccessibilityData.ariaLabel` upstream; the port spells the same
  /// slot `callOutSemantics.label`.
  List<FluentVerticalBarChartDataPoint> get _points =>
      <FluentVerticalBarChartDataPoint>[
        FluentVerticalBarChartDataPoint(
          x: 'One',
          y: 20,
          lineData: _isChecked
              ? const FluentBarLineDatum(y: 10, yAxisCalloutData: '12%')
              : null,
          callOutSemantics: FluentChartSemantics(
            label: 'Bar series 1 of 4 ${_isChecked ? 'one 12% 20' : 'one 20'}',
          ),
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Two',
          y: 48,
          lineData: _isChecked ? const FluentBarLineDatum(y: 28) : null,
          callOutSemantics: FluentChartSemantics(
            label: 'Bar series 2 of 4 ${_isChecked ? 'Two 28 48' : 'Two 48'}',
          ),
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Three',
          y: 30,
          lineData: _isChecked ? const FluentBarLineDatum(y: 4) : null,
          callOutSemantics: FluentChartSemantics(
            label:
                'Bar series 3 of 4 ${_isChecked ? 'Three 4 30' : 'Three 30'}',
          ),
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Four',
          y: 40,
          lineData: _isChecked ? const FluentBarLineDatum(y: 28) : null,
          callOutSemantics: FluentChartSemantics(
            label: 'Bar series 4 of 4 ${_isChecked ? 'Four 28 40' : 'Four 40'}',
          ),
        ),
      ];

  static const List<Color> _customColors = <Color>[
    Color(0xFF90EE90), // lightgreen
    Color(0xFF008000), // green
    Color(0xFF006400), // darkgreen
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      FluentCheckbox(
        checked: _isChecked,
        onChanged: (bool? value) => setState(() => _isChecked = value ?? false),
        label: const Text('show  line(This will draw the line)'),
      ),
      FluentCheckbox(
        checked: _useSingleColor,
        onChanged: (bool? value) =>
            setState(() => _useSingleColor = value ?? false),
        label: const Text('use single color(This will have only one color)'),
      ),
      SizedBox(
        width: 800,
        height: 400,
        child: FluentVerticalBarChart(
          chartTitle: 'Vertical bar chart custom accessibility example ',
          data: _points,
          barWidth: 20,
          useSingleColor: _useSingleColor,
          colors: _customColors,
          lineLegendColor: const Color(0xFFAE8C00), // rgb(174, 140, 0)
          props: const FluentCartesianChartProps(
            yAxisTickCount: 6,
            hideLegend: true,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-verticalbarchart--vertical-bar-custom-accessibility

// #docregion charts-verticalbarchart--vertical-bar-date-axis
Widget _verticalBarDateAxis(BuildContext context) {
  // `new Date("2018/01/01")` and friends. DateTime has no const constructor,
  // so the five dates are built once here and shared with the tick values.
  final DateTime januaryFirst2018 = DateTime(2018, 1, 1);
  final DateTime marchFirst2018 = DateTime(2018, 3, 1);
  final DateTime julyFirst2018 = DateTime(2018, 7, 1);
  final DateTime octoberFirst2018 = DateTime(2018, 10, 1);
  final DateTime januaryFirst2019 = DateTime(2019, 1, 1);

  final List<FluentVerticalBarChartDataPoint> points =
      <FluentVerticalBarChartDataPoint>[
        FluentVerticalBarChartDataPoint(
          x: januaryFirst2018,
          y: 3500,
          color: const Color(0xFF627CEF),
        ),
        FluentVerticalBarChartDataPoint(
          x: marchFirst2018,
          y: 2500,
          color: const Color(0xFFC19C00),
        ),
        FluentVerticalBarChartDataPoint(
          x: julyFirst2018,
          y: 1900,
          color: const Color(0xFFE650AF),
        ),
        FluentVerticalBarChartDataPoint(
          x: octoberFirst2018,
          y: 2800,
          color: const Color(0xFF0E7878),
        ),
        FluentVerticalBarChartDataPoint(
          x: januaryFirst2019,
          y: 3800,
          color: const Color(0xFF0E7878),
        ),
      ];

  final List<DateTime> tickValues = <DateTime>[
    januaryFirst2018,
    marchFirst2018,
    julyFirst2018,
    octoberFirst2018,
    januaryFirst2019,
  ];

  return SizedBox(
    width: 650,
    height: 350,
    child: FluentVerticalBarChart(
      chartTitle: 'Vertical bar chart Date axis example ',
      culture: 'en-us',
      data: points,
      props: FluentCartesianChartProps(
        tickValues: tickValues,
        // Upstream passes the d3-time-format string "%m/%d"; our shell takes a
        // formatter rather than a format string.
        customDateTimeFormatter: _monthDay,
        useUTC: false,
        hideLegend: true,
      ),
    ),
  );
}

String _monthDay(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.day.toString().padLeft(2, '0')}';
// #enddocregion charts-verticalbarchart--vertical-bar-date-axis

// #docregion charts-verticalbarchart--vertical-bar-axis-tooltip
Widget _verticalBarAxisTooltip(BuildContext context) =>
    const _VerticalBarAxisTooltip();

class _VerticalBarAxisTooltip extends StatefulWidget {
  const _VerticalBarAxisTooltip();

  @override
  State<_VerticalBarAxisTooltip> createState() =>
      _VerticalBarAxisTooltipState();
}

class _VerticalBarAxisTooltipState extends State<_VerticalBarAxisTooltip> {
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

  static const List<FluentVerticalBarChartDataPoint> _points =
      <FluentVerticalBarChartDataPoint>[
        FluentVerticalBarChartDataPoint(
          x: 'Simple Text',
          y: 1000,
          color: Color(0xFF1E90FF), // dodgerblue
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Showing all text here',
          y: 5000,
          color: Color(0xFF191970), // midnightblue
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Large data, showing all text by tooltip',
          y: 3000,
          color: Color(0xFF00008B), // darkblue
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Data',
          y: 2000,
          color: Color(0xFF00BFFF), // deepskyblue
        ),
      ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('width: '),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('height: '),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
          // Upstream labels this checkbox "barWidth:&nbsp;" — the entity is a
          // non-breaking space, which Dart writes as a plain trailing space.
          FluentCheckbox(
            checked: _barWidthEnabled,
            onChanged: (bool? value) =>
                setState(() => _barWidthEnabled = value ?? false),
            label: const Text('barWidth: '),
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
          const Text('maxBarWidth: '),
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
      Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          // Upstream: "xAxisInnerPadding:&nbsp;".
          FluentCheckbox(
            checked: _xAxisInnerPaddingEnabled,
            onChanged: (bool? value) =>
                setState(() => _xAxisInnerPaddingEnabled = value ?? false),
            label: const Text('xAxisInnerPadding: '),
          ),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _xAxisInnerPadding,
              max: 1,
              step: 0.01,
              onChanged: _xAxisInnerPaddingEnabled
                  ? (double value) => setState(() => _xAxisInnerPadding = value)
                  : null,
            ),
          ),
          Text(' ${_xAxisInnerPadding.toStringAsFixed(2)}'),
          // Upstream: "xAxisOuterPadding:&nbsp;".
          FluentCheckbox(
            checked: _xAxisOuterPaddingEnabled,
            onChanged: (bool? value) =>
                setState(() => _xAxisOuterPaddingEnabled = value ?? false),
            label: const Text('xAxisOuterPadding: '),
          ),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _xAxisOuterPadding,
              max: 1,
              step: 0.01,
              onChanged: _xAxisOuterPaddingEnabled
                  ? (double value) => setState(() => _xAxisOuterPadding = value)
                  : null,
            ),
          ),
          Text(' ${_xAxisOuterPadding.toStringAsFixed(2)}'),
        ],
      ),
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _selectedCallout,
          onChanged: (String value) => setState(() => _selectedCallout = value),
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
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentVerticalBarChart(
            chartTitle: 'Vertical bar chart axis tooltip example ',
            data: _points,
            barWidth: _barWidthEnabled ? _barWidth : 'auto',
            maxBarWidth: _maxBarWidth,
            xAxisInnerPadding: _xAxisInnerPaddingEnabled
                ? _xAxisInnerPadding
                : null,
            xAxisOuterPadding: _xAxisOuterPaddingEnabled
                ? _xAxisOuterPadding
                : null,
            props: FluentCartesianChartProps(
              hideLegend: true,
              showXAxisLablesTooltip: _selectedCallout == 'showTooltip',
              wrapXAxisLables: _selectedCallout == 'WrapTickValues',
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-verticalbarchart--vertical-bar-axis-tooltip

// #docregion charts-verticalbarchart--vertical-bar-rotate-labels
Widget _verticalBarRotateLabels(BuildContext context) => const SizedBox(
  width: 650,
  height: 350,
  child: FluentVerticalBarChart(
    chartTitle: 'Vertical bar chart rotated labels example ',
    data: <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 'This is a medium long label. ',
        y: 3500,
        color: Color(0xFF627CEF),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'This is a long label This is a long label',
        y: 2500,
        color: Color(0xFFC19C00),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'This label is as long as the previous one',
        y: 1900,
        color: Color(0xFFE650AF),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'A short label',
        y: 2800,
        color: Color(0xFF0E7878),
      ),
    ],
    props: FluentCartesianChartProps(hideLegend: true, rotateXAxisLables: true),
  ),
);
// #enddocregion charts-verticalbarchart--vertical-bar-rotate-labels

// #docregion charts-verticalbarchart--vertical-bar-styled
Widget _verticalBarStyled(BuildContext context) => const _VerticalBarStyled();

class _VerticalBarStyled extends StatefulWidget {
  const _VerticalBarStyled();

  @override
  State<_VerticalBarStyled> createState() => _VerticalBarStyledState();
}

class _VerticalBarStyledState extends State<_VerticalBarStyled> {
  bool _isChecked = true;
  bool _useSingleColor = true;

  List<FluentVerticalBarChartDataPoint> get _points =>
      <FluentVerticalBarChartDataPoint>[
        FluentVerticalBarChartDataPoint(
          x: 'One',
          y: 20,
          lineData: _isChecked
              ? const FluentBarLineDatum(y: 10, yAxisCalloutData: '12%')
              : null,
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Two',
          y: 48,
          lineData: _isChecked ? const FluentBarLineDatum(y: 28) : null,
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Three',
          y: 30,
          lineData: _isChecked ? const FluentBarLineDatum(y: 4) : null,
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Four',
          y: 40,
          lineData: _isChecked ? const FluentBarLineDatum(y: 28) : null,
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Five',
          y: 13,
          lineData: _isChecked
              ? const FluentBarLineDatum(y: 8, yAxisCalloutData: '45%')
              : null,
        ),
        const FluentVerticalBarChartDataPoint(x: 'Six', y: 60),
        const FluentVerticalBarChartDataPoint(x: 'Seven', y: 60),
        FluentVerticalBarChartDataPoint(
          x: 'Eight',
          y: 57,
          lineData: _isChecked ? const FluentBarLineDatum(y: 48) : null,
        ),
        const FluentVerticalBarChartDataPoint(x: 'Nine', y: 14),
        const FluentVerticalBarChartDataPoint(x: 'Ten', y: 35),
        FluentVerticalBarChartDataPoint(
          x: 'Eleven',
          y: 20,
          lineData: _isChecked ? const FluentBarLineDatum(y: 1) : null,
        ),
        FluentVerticalBarChartDataPoint(
          x: 'Twelve',
          y: 44,
          lineData: _isChecked ? const FluentBarLineDatum(y: 10) : null,
        ),
        const FluentVerticalBarChartDataPoint(x: 'Thirteen', y: 33),
      ];

  static const List<Color> _customColors = <Color>[
    Color(0xFF008000), // green
    Color(0xFF90EE90), // lightgreen
    Color(0xFF006400), // darkgreen
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      FluentCheckbox(
        checked: _isChecked,
        onChanged: (bool? value) => setState(() => _isChecked = value ?? false),
        label: const Text('show  line(This will draw the line)'),
      ),
      FluentCheckbox(
        checked: _useSingleColor,
        onChanged: (bool? value) =>
            setState(() => _useSingleColor = value ?? false),
        label: const Text('use single color(This will have only one color)'),
      ),
      SizedBox(
        width: 800,
        height: 400,
        child: FluentVerticalBarChart(
          chartTitle: 'Vertical bar chart styled example ',
          data: _points,
          barWidth: 20,
          useSingleColor: _useSingleColor,
          colors: _customColors,
          lineLegendColor: const Color(0xFFAE8C00), // rgb(174, 140, 0)
          props: const FluentCartesianChartProps(
            yAxisTickCount: 6,
            hideLegend: true,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-verticalbarchart--vertical-bar-styled

// #docregion charts-verticalbarchart--vertical-bar-dynamic
Widget _verticalBarDynamic(BuildContext context) => const _VerticalBarDynamic();

class _VerticalBarDynamic extends StatefulWidget {
  const _VerticalBarDynamic();

  @override
  State<_VerticalBarDynamic> createState() => _VerticalBarDynamicState();
}

class _VerticalBarDynamicState extends State<_VerticalBarDynamic> {
  static const String _initialXAxisType = 'number';
  static const int _initialDataSize = 5;

  static const List<List<FluentDataVizToken>> _colorSets =
      <List<FluentDataVizToken>>[
        <FluentDataVizToken>[
          FluentDataVizToken.color1,
          FluentDataVizToken.color2,
          FluentDataVizToken.color3,
        ],
        <FluentDataVizToken>[
          FluentDataVizToken.color4,
          FluentDataVizToken.color5,
          FluentDataVizToken.color6,
        ],
        <FluentDataVizToken>[
          FluentDataVizToken.color7,
          FluentDataVizToken.color8,
          FluentDataVizToken.color9,
        ],
        <FluentDataVizToken>[
          FluentDataVizToken.color10,
          FluentDataVizToken.color11,
          FluentDataVizToken.color12,
        ],
      ];

  // dart:math is outside this example's import allowlist, so the demo carries
  // a Park-Miller generator instead of Random(). It stays inside 2^53, which
  // keeps it exact on the web too.
  int _seed = DateTime.now().microsecondsSinceEpoch % 2147483646 + 1;
  int _colorIndex = 0;
  late List<FluentVerticalBarChartDataPoint> _dynamicData;
  Object? _barWidth;
  double _prevBarWidth = 16;
  double _maxBarWidth = 24;
  double _xAxisInnerPadding = 0.67;
  double _xAxisOuterPadding = 0;
  bool _xAxisInnerPaddingEnabled = false;
  bool _xAxisOuterPaddingEnabled = false;
  double _width = 650;
  double _dataSize = _initialDataSize.toDouble();
  String _xAxisType = _initialXAxisType;

  @override
  void initState() {
    super.initState();
    _dynamicData = _getData(_initialDataSize, _initialXAxisType);
  }

  int _randomInt(int max) {
    _seed = _seed * 16807 % 2147483647;
    return _seed % max;
  }

  double _randomY() => (_randomInt(90) + 1).toDouble();

  List<FluentVerticalBarChartDataPoint> _getData(
    int dataSize,
    String xAxisType,
  ) {
    final List<FluentVerticalBarChartDataPoint> data =
        <FluentVerticalBarChartDataPoint>[];
    if (xAxisType == 'string') {
      for (int i = 0; i < dataSize; i++) {
        data.add(
          FluentVerticalBarChartDataPoint(x: 'Label ${i + 1}', y: _randomY()),
        );
      }
    } else {
      final Set<int> xPoints = <int>{};
      final DateTime date = DateTime(2020);
      while (xPoints.length != dataSize) {
        final int x = _randomInt(75) + 1;
        if (xPoints.add(x)) {
          data.add(
            FluentVerticalBarChartDataPoint(
              x: xAxisType == 'date' ? date.add(Duration(days: x)) : x,
              y: _randomY(),
            ),
          );
        }
      }
    }
    return data;
  }

  List<Color> get _colors => <Color>[
    for (final FluentDataVizToken token in _colorSets[_colorIndex])
      FluentDataVizPalette.resolve(token),
  ];

  void _changeData() =>
      setState(() => _dynamicData = _getData(_dataSize.round(), _xAxisType));

  void _changeColors() =>
      setState(() => _colorIndex = (_colorIndex + 1) % _colorSets.length);

  void _onBarWidthCheckChange() => setState(() {
    if (_barWidth == null) {
      _barWidth = 'auto';
    } else if (_barWidth == 'auto') {
      _barWidth = _prevBarWidth;
    } else {
      _prevBarWidth = _barWidth! as double;
      _barWidth = null;
    }
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      Wrap(
        spacing: 30,
        runSpacing: 15,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('width: '),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          // Upstream labels this checkbox "barWidth:&nbsp;" and leaves it in
          // the mixed state while barWidth is 'auto'.
          FluentCheckbox(
            checked: _barWidth is double
                ? true
                : (_barWidth == 'auto' ? null : false),
            onChanged: (bool? _) => _onBarWidthCheckChange(),
            label: const Text('barWidth: '),
          ),
          if (_barWidth is double)
            SizedBox(
              width: 120,
              child: FluentSpinButton(
                value: _barWidth! as double,
                min: 1,
                max: 300,
                semanticLabel: 'barWidth',
                onChanged: (double? value) =>
                    setState(() => _barWidth = value ?? _barWidth),
              ),
            )
          else
            Text('$_barWidth'),
          const Text('maxBarWidth: '),
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
      Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          // Upstream: "xAxisInnerPadding:&nbsp;".
          FluentCheckbox(
            checked: _xAxisInnerPaddingEnabled,
            onChanged: _xAxisType == 'string'
                ? (bool? value) =>
                      setState(() => _xAxisInnerPaddingEnabled = value ?? false)
                : null,
            label: const Text('xAxisInnerPadding: '),
          ),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _xAxisInnerPadding,
              max: 1,
              step: 0.01,
              semanticLabel: 'Change X Axis Inner Padding',
              onChanged: _xAxisInnerPaddingEnabled
                  ? (double value) => setState(() => _xAxisInnerPadding = value)
                  : null,
            ),
          ),
          Text(' ${_xAxisInnerPadding.toStringAsFixed(2)}'),
          // Upstream: "xAxisOuterPadding:&nbsp;".
          FluentCheckbox(
            checked: _xAxisOuterPaddingEnabled,
            onChanged: _xAxisType == 'string'
                ? (bool? value) =>
                      setState(() => _xAxisOuterPaddingEnabled = value ?? false)
                : null,
            label: const Text('xAxisOuterPadding: '),
          ),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _xAxisOuterPadding,
              max: 1,
              step: 0.01,
              semanticLabel: 'Change X Axis Outer Padding',
              onChanged: _xAxisOuterPaddingEnabled
                  ? (double value) => setState(() => _xAxisOuterPadding = value)
                  : null,
            ),
          ),
          Text(' ${_xAxisOuterPadding.toStringAsFixed(2)}'),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          const Text('Data Size: '),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _dataSize,
              max: 50,
              step: 1,
              semanticLabel: 'Change Data Size',
              onChanged: (double value) => setState(() {
                _dataSize = value;
                _dynamicData = _getData(value.round(), _xAxisType);
              }),
            ),
          ),
        ],
      ),
      FluentField(
        label: const Text('X-Axis type:'),
        child: FluentRadioGroup<String>(
          value: _xAxisType,
          onChanged: (String value) => setState(() {
            _xAxisType = value;
            _dynamicData = _getData(_dataSize.round(), value);
          }),
          children: const <Widget>[
            FluentRadio<String>(value: 'number', label: Text('Number')),
            FluentRadio<String>(value: 'date', label: Text('Date')),
            FluentRadio<String>(value: 'string', label: Text('String')),
          ],
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: 350,
          child: FluentVerticalBarChart(
            chartTitle: 'Vertical bar chart dynamic example',
            data: _dynamicData,
            colors: _colors,
            barWidth: _barWidth,
            maxBarWidth: _maxBarWidth,
            xAxisInnerPadding: _xAxisInnerPaddingEnabled
                ? _xAxisInnerPadding
                : null,
            xAxisOuterPadding: _xAxisOuterPaddingEnabled
                ? _xAxisOuterPadding
                : null,
            props: const FluentCartesianChartProps(
              hideLegend: true,
              yMaxValue: 100,
            ),
          ),
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          FluentButton(
            onPressed: _changeData,
            child: const Text('Change Data'),
          ),
          FluentButton(
            onPressed: _changeColors,
            child: const Text('Change Color'),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion charts-verticalbarchart--vertical-bar-dynamic

// #docregion charts-verticalbarchart--vertical-bar-all-negative
Widget _verticalBarAllNegative(BuildContext context) =>
    const _VerticalBarAllNegative();

class _VerticalBarAllNegative extends StatefulWidget {
  const _VerticalBarAllNegative();

  @override
  State<_VerticalBarAllNegative> createState() =>
      _VerticalBarAllNegativeState();
}

class _VerticalBarAllNegativeState extends State<_VerticalBarAllNegative> {
  double _width = 650;
  double _height = 350;
  String? _calloutExample;
  bool _useSingleColor = false;
  bool _hideLabels = false;
  bool _showAxisTitles = true;
  bool _roundCorners = false;

  List<FluentVerticalBarChartDataPoint>
  get _negativePoints => <FluentVerticalBarChartDataPoint>[
    FluentVerticalBarChartDataPoint(
      x: 0,
      y: -10000,
      legend: 'Oranges',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-4%',
      lineData: const FluentBarLineDatum(y: -7000, yAxisCalloutData: '-3%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 10000,
      y: -50000,
      legend: 'Dogs',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-21%',
      lineData: const FluentBarLineDatum(y: -30000, yAxisCalloutData: '-12%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 25000,
      y: -30000,
      legend: 'Apples',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-12%',
      lineData: const FluentBarLineDatum(y: -3000, yAxisCalloutData: '-1%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 40000,
      y: -13000,
      legend: 'Bananas',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-5%',
    ),
    FluentVerticalBarChartDataPoint(
      x: 52000,
      y: -43000,
      legend: 'Giraffes',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-18%',
      lineData: const FluentBarLineDatum(y: -30000, yAxisCalloutData: '-12%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 68000,
      y: -30000,
      legend: 'Cats',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-12%',
      lineData: const FluentBarLineDatum(y: -5000, yAxisCalloutData: '-2%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 80000,
      y: -20000,
      legend: 'Elephants',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-8%',
      lineData: const FluentBarLineDatum(y: -16000, yAxisCalloutData: '-7%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 92000,
      y: -45000,
      legend: 'Monkeys',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-19%',
      lineData: const FluentBarLineDatum(y: -40000, yAxisCalloutData: '-16%'),
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      // `supportNegativeData` has no counterpart in the port: negative y values
      // are always plotted against a signed y axis.
      const SizedBox(
        width: 650,
        child: Text(
          'In this example the supportNegativeData property is enabled and all '
          'negative y points are passed to the data. As a result chart with '
          'negative y axis data is rendered.',
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
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _calloutExample,
          onChanged: (String value) => setState(() => _calloutExample = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'Basic Example',
              label: Text('Basic Example'),
            ),
            FluentRadio<String>(
              value: 'Custom Callout Example',
              label: Text('Custom Callout Example'),
            ),
          ],
        ),
      ),
      FluentCheckbox(
        checked: _useSingleColor,
        onChanged: (bool? value) =>
            setState(() => _useSingleColor = value ?? false),
        label: const Text('use single color(This will have only one color)'),
      ),
      FluentCheckbox(
        checked: _hideLabels,
        onChanged: (bool? value) =>
            setState(() => _hideLabels = value ?? false),
        label: const Text('Hide labels'),
      ),
      FluentSwitch(
        checked: _showAxisTitles,
        onChanged: (bool value) => setState(() => _showAxisTitles = value),
        label: Text(_showAxisTitles ? 'Switch Axis titles' : 'Hide axis tiles'),
      ),
      // Upstream also offers an "Enable Gradient" switch; the port has no
      // gradient fill for bars, so that one knob is left out.
      FluentSwitch(
        checked: _roundCorners,
        onChanged: (bool value) => setState(() => _roundCorners = value),
        label: Text(
          _roundCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentVerticalBarChart(
            culture: 'en-us',
            chartTitle: 'Vertical bar chart basic example ',
            data: _negativePoints,
            useSingleColor: _useSingleColor,
            lineLegendText: 'just line',
            lineLegendColor: const Color(0xFFA52A2A), // brown
            lineOptions: const FluentLineOptions(lineBorderWidth: 2),
            hideLabels: _hideLabels,
            roundCorners: _roundCorners,
            props: FluentCartesianChartProps(
              yAxisTitle: _showAxisTitles
                  ? 'Different categories of animals and fruits'
                  : null,
              xAxisTitle: _showAxisTitles ? 'Values of each category' : null,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-verticalbarchart--vertical-bar-all-negative

// #docregion charts-verticalbarchart--vertical-bar-negative
Widget _verticalBarNegative(BuildContext context) =>
    const _VerticalBarNegative();

class _VerticalBarNegative extends StatefulWidget {
  const _VerticalBarNegative();

  @override
  State<_VerticalBarNegative> createState() => _VerticalBarNegativeState();
}

class _VerticalBarNegativeState extends State<_VerticalBarNegative> {
  double _width = 650;
  double _height = 350;
  String? _calloutExample;
  bool _useSingleColor = false;
  bool _hideLabels = false;
  bool _showAxisTitles = true;
  bool _roundCorners = false;

  List<FluentVerticalBarChartDataPoint>
  get _negativePoints => <FluentVerticalBarChartDataPoint>[
    FluentVerticalBarChartDataPoint(
      x: 0,
      y: 10000,
      legend: 'Oranges',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '4%',
      lineData: const FluentBarLineDatum(y: 7000, yAxisCalloutData: '3%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 10000,
      y: -50000,
      legend: 'Dogs',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-21%',
      lineData: const FluentBarLineDatum(y: -30000, yAxisCalloutData: '-12%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 25000,
      y: 30000,
      legend: 'Apples',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '12%',
      lineData: const FluentBarLineDatum(y: 3000, yAxisCalloutData: '1%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 40000,
      y: -13000,
      legend: 'Bananas',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-5%',
    ),
    FluentVerticalBarChartDataPoint(
      x: 52000,
      y: 43000,
      legend: 'Giraffes',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '18%',
      lineData: const FluentBarLineDatum(y: 30000, yAxisCalloutData: '12%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 68000,
      y: -30000,
      legend: 'Cats',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-12%',
      lineData: const FluentBarLineDatum(y: -5000, yAxisCalloutData: '-2%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 80000,
      y: 20000,
      legend: 'Elephants',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '8%',
      lineData: const FluentBarLineDatum(y: 16000, yAxisCalloutData: '7%'),
    ),
    FluentVerticalBarChartDataPoint(
      x: 92000,
      y: -45000,
      legend: 'Monkeys',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: '-19%',
      lineData: const FluentBarLineDatum(y: -40000, yAxisCalloutData: '-16%'),
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      // `supportNegativeData` has no counterpart in the port: negative y values
      // are always plotted against a signed y axis.
      const SizedBox(
        width: 650,
        child: Text(
          'In this example the supportNegativeData property is enabled and '
          'some positive and some negative y points are passed to the data. As '
          'a result chart with negative y axis data is rendered.',
        ),
      ),
      const Text('Change Width:'),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Width',
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
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _calloutExample,
          onChanged: (String value) => setState(() => _calloutExample = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'Basic Example',
              label: Text('Basic Example'),
            ),
            FluentRadio<String>(
              value: 'Custom Callout Example',
              label: Text('Custom Callout Example'),
            ),
          ],
        ),
      ),
      FluentCheckbox(
        checked: _useSingleColor,
        onChanged: (bool? value) =>
            setState(() => _useSingleColor = value ?? false),
        label: const Text('use single color(This will have only one color)'),
      ),
      FluentCheckbox(
        checked: _hideLabels,
        onChanged: (bool? value) =>
            setState(() => _hideLabels = value ?? false),
        label: const Text('Hide labels'),
      ),
      FluentSwitch(
        checked: _showAxisTitles,
        onChanged: (bool value) => setState(() => _showAxisTitles = value),
        label: Text(
          _showAxisTitles ? 'Switch Axis titles' : 'Hide Axis titles',
        ),
      ),
      // Upstream also offers an "Enable Gradient" switch; the port has no
      // gradient fill for bars, so that one knob is left out.
      FluentSwitch(
        checked: _roundCorners,
        onChanged: (bool value) => setState(() => _roundCorners = value),
        label: Text(
          _roundCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentVerticalBarChart(
            culture: 'en-us',
            chartTitle: 'Vertical bar chart basic example ',
            data: _negativePoints,
            useSingleColor: _useSingleColor,
            lineLegendText: 'just line',
            lineLegendColor: const Color(0xFFA52A2A), // brown
            lineOptions: const FluentLineOptions(lineBorderWidth: 2),
            hideLabels: _hideLabels,
            roundCorners: _roundCorners,
            props: FluentCartesianChartProps(
              yAxisTitle: _showAxisTitles
                  ? 'Different categories of animals and fruits'
                  : null,
              xAxisTitle: _showAxisTitles ? 'Values of each category' : null,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-verticalbarchart--vertical-bar-negative

// #docregion charts-verticalbarchart--vertical-bar-chart-responsive
// Upstream wraps the chart in a `ResponsiveContainer`. A Flutter chart already
// fills the constraints it is given, so the box is all that is left of it.
Widget _verticalBarChartResponsive(BuildContext context) => const SizedBox(
  width: double.infinity,
  height: 350,
  child: FluentVerticalBarChart(
    data: <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 0,
        y: 10000,
        legend: 'Oranges',
        color: Color(0xFF637CEF),
        lineData: FluentBarLineDatum(y: 7000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 10000,
        y: 50000,
        legend: 'Dogs',
        color: Color(0xFFE3008C),
        lineData: FluentBarLineDatum(y: 30000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 25000,
        y: 30000,
        legend: 'Apples',
        color: Color(0xFF2AA0A4),
        lineData: FluentBarLineDatum(y: 3000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 40000,
        y: 13000,
        legend: 'Bananas',
        color: Color(0xFF3A96DD),
      ),
      FluentVerticalBarChartDataPoint(
        x: 52000,
        y: 43000,
        legend: 'Giraffes',
        color: Color(0xFF3C51B4),
        lineData: FluentBarLineDatum(y: 30000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 68000,
        y: 30000,
        legend: 'Cats',
        color: Color(0xFFE3008C),
        lineData: FluentBarLineDatum(y: 5000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 80000,
        y: 20000,
        legend: 'Elephants',
        color: Color(0xFF3C51B4),
        lineData: FluentBarLineDatum(y: 16000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 92000,
        y: 45000,
        legend: 'Monkeys',
        color: Color(0xFF3A96DD),
        lineData: FluentBarLineDatum(y: 40000),
      ),
    ],
    lineLegendText: 'Line',
    lineLegendColor: Color(0xFFA52A2A), // brown
    lineOptions: FluentLineOptions(lineBorderWidth: 2),
  ),
);
// #enddocregion charts-verticalbarchart--vertical-bar-chart-responsive

// #docregion charts-verticalbarchart--vertical-bar-secondary-y-axis
Widget _verticalBarSecondaryYAxis(BuildContext context) =>
    const _VerticalBarSecondaryYAxis();

class _VerticalBarSecondaryYAxis extends StatefulWidget {
  const _VerticalBarSecondaryYAxis();

  @override
  State<_VerticalBarSecondaryYAxis> createState() =>
      _VerticalBarSecondaryYAxisState();
}

class _VerticalBarSecondaryYAxisState
    extends State<_VerticalBarSecondaryYAxis> {
  double _width = 700;
  double _height = 300;

  List<FluentVerticalBarChartDataPoint>
  get _points => <FluentVerticalBarChartDataPoint>[
    FluentVerticalBarChartDataPoint(
      x: 0,
      y: 10000,
      legend: 'Oranges',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      lineData: const FluentBarLineDatum(y: 7000, useSecondaryYScale: true),
    ),
    FluentVerticalBarChartDataPoint(
      x: 10000,
      y: 50000,
      legend: 'Dogs',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      lineData: const FluentBarLineDatum(y: 30000, useSecondaryYScale: true),
    ),
    FluentVerticalBarChartDataPoint(
      x: 25000,
      y: 30000,
      legend: 'Apples',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      lineData: const FluentBarLineDatum(y: 3000, useSecondaryYScale: true),
    ),
    FluentVerticalBarChartDataPoint(
      x: 40000,
      y: 13000,
      legend: 'Bananas',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
    ),
    FluentVerticalBarChartDataPoint(
      x: 52000,
      y: 43000,
      legend: 'Giraffes',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
      lineData: const FluentBarLineDatum(y: 30000, useSecondaryYScale: true),
    ),
    FluentVerticalBarChartDataPoint(
      x: 68000,
      y: 30000,
      legend: 'Cats',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
      lineData: const FluentBarLineDatum(y: 5000, useSecondaryYScale: true),
    ),
    FluentVerticalBarChartDataPoint(
      x: 80000,
      y: 20000,
      legend: 'Elephants',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
      lineData: const FluentBarLineDatum(y: 16000, useSecondaryYScale: true),
    ),
    FluentVerticalBarChartDataPoint(
      x: 92000,
      y: 45000,
      legend: 'Monkeys',
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      lineData: const FluentBarLineDatum(y: 40000, useSecondaryYScale: true),
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
          child: FluentVerticalBarChart(
            chartTitle: 'Vertical bar chart secondary y-axis example ',
            data: _points,
            lineLegendText: 'just line',
            lineLegendColor: const Color(0xFFA52A2A), // brown
            lineOptions: const FluentLineOptions(lineBorderWidth: 2),
            props: const FluentCartesianChartProps(
              yAxisTitle: 'Values of each category',
              xAxisTitle: 'Different categories of animals and fruits',
              secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
            ),
          ),
        ),
      ),
    ],
  );
}

// #enddocregion charts-verticalbarchart--vertical-bar-secondary-y-axis
