import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The AreaChart docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage areaChartPage = DocsPage(
  id: 'charts-areachart',
  title: 'AreaChart',
  description:
      'Area charts are graphical representations of data that display '
      'quantitative data points connected by lines and filled with '
      'colors to create a visual representation of trends and patterns. '
      'The area between the line and the x-axis is colored, which helps '
      'in emphasizing the cumulative total or the overall magnitude of '
      'the data. They are a slight variation of single line charts, and '
      'generally can be used interchangeably. Stacked area charts are '
      'great at communicating how multiple data series relate to the '
      'total value. It illustrates how each series compares to the '
      'other in their contributions to the total. The baseline is '
      'moving in stacked area charts, rather than sharing a common '
      'baseline in overlapping areas.',
  source: 'lib/pages/charts_areachart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'Padding on the left and right of the chart is determined by '
          'the x-axis labels - it should start and end at or close to '
          'the first and last tick mark. The minimum padding is 8px.\n'
          'Currently we support stacked area charts only.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- **Area line** An area line represents a set of values from '
          'the same data set. Each line takes on a new swatch in the '
          'data visualization library to distinguish it from others. '
          '2px wide. There is no rounding of joints to avoid data '
          'misrepresentation.\n'
          '- **Area fill** Uses the same color family as the area line, '
          'but applies a 50% opacity.\n'
          'Note: the implemented stacked area components use '
          'transparency fills, but we cannot apply transparency in the '
          'Figma guidance\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          '- Users "Enter" into the graph and can use both arrow and '
          'tab keys to navigate through.\n'
          '- The first tab stop will stop on the graph and give a '
          'description of what type of graph it is.\n'
          '- Each section of the graph is readable via screen readers. '
          'The user can navigate through the entire area plot by using '
          'Left and Right arrow keys.\n',
    ),
    ProseBlock(
      title: 'Interaction',
      body:
          'The area chart is a highly performant visual. It uses a '
          'path-based rendering mechanism to render the area component. '
          'On hovering, the nearest x datapoint is identified and the '
          'corresponding point is hovered.\n',
    ),
    ProseBlock(
      title: 'Customizing the chart',
      body:
          '- **Stacked area chart** In stacked area chart, two or more '
          'data series are stacked vertically. It helps in easy '
          'comparison across different dimensions. The callout on hover '
          'for stacked chart displays multiple values from the stack. '
          'The callout can be customized to show single values or '
          'stacked values. Refer to the props '
          '`onRenderCalloutPerDataPoint` and `onRenderCalloutPerStack` '
          'using which custom content for the callout can be defined.\n'
          '- **Custom accessibility** Area chart provides a bunch of '
          'props to enable custom accessibility messages. Use '
          '`xAxisCalloutAccessibilityData` and '
          '`callOutAccessibilityData` to configure x axis and y axis '
          'accessibility messages, respectively.\n',
    ),
    ProseBlock(
      title: 'Axis localization',
      body:
          'The chart axes support 2 ways of localization.\n'
          '1. JavaScript provided inbuilt localization for numeric and '
          'date axis. Specify the culture and `dateLocalizeOptions` for '
          'date axis to define target localization. Refer the '
          'Javascript localization guide for usage.\n'
          '2. Custom locale definition: The consumer of the library can '
          'specify a custom locale definition as supported by d3 like '
          'this. The date axis will use the date range and the '
          'multiformat specified in the definition to determine the '
          'correct labels to show in the ticks. For example - If the '
          'date range is in days, then the axis will show hourly ticks. '
          'If the date range spans across months, then the axis will '
          'show months in tick labels and so on. Specify the custom '
          'locale definition in the `timeFormatLocale` prop. Refer to '
          'the Custom Locale Date Axis example in line chart for sample '
          'usage.\n',
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
          '- Remain consistent with one chart style if there are '
          'multiple instances of it on a page rather than using area '
          'and line charts interchangeably.\n',
    ),
    ProseBlock(
      title: 'Dont\'s',
      body:
          '- Prefer line charts to plot trends.\n'
          '- No more than 9 lines on a chart; fewer are better.\n'
          '- Do not remove axis titles unless it is clear to the user '
          'what is being visualized.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-areachart--area-chart-basic',
      title: 'Area Chart Basic',
      builder: _areaChartBasic,
    ),
    DocsSection(
      id: 'charts-areachart--area-chart-custom-accessibility',
      title: 'Area Chart Custom Accessibility',
      builder: _areaChartCustomAccessibility,
    ),
    DocsSection(
      id: 'charts-areachart--area-chart-large-data',
      title: 'Area Chart Large Data',
      builder: _areaChartLargeData,
    ),
    DocsSection(
      id: 'charts-areachart--area-chart-multiple',
      title: 'Area Chart Multiple',
      builder: _areaChartMultiple,
    ),
    DocsSection(
      id: 'charts-areachart--area-chart-negative',
      title: 'Area Chart Negative',
      builder: _areaChartNegative,
    ),
    DocsSection(
      id: 'charts-areachart--area-chart-multiple-negative',
      title: 'Area Chart Multiple Negative',
      builder: _areaChartMultipleNegative,
    ),
    DocsSection(
      id: 'charts-areachart--area-chart-all-negative',
      title: 'Area Chart All Negative',
      builder: _areaChartAllNegative,
    ),
    DocsSection(
      id: 'charts-areachart--area-chart-secondary-y-axis',
      title: 'Area Chart Secondary Y Axis',
      builder: _areaChartSecondaryYAxis,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'FluentChartData',
      description:
          'The data bundle. Only lineChartData, markerRadius and chartTitle '
          'are read.',
    ),
    PropRow(
      name: 'props',
      type: 'FluentCartesianChartProps',
      defaultValue: 'FluentCartesianChartProps()',
      description: 'Shell configuration — axes, margins, titles and legend.',
    ),
    PropRow(
      name: 'mode',
      type: 'FluentAreaChartMode',
      defaultValue: 'FluentAreaChartMode.toNextY',
      description:
          'How an area layer picks its baseline: stacked, or flat on zero.',
    ),
    PropRow(
      name: 'enableGradient',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the fill fades to transparent downwards.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'BCP-47 locale for popover formatting.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentAreaChartStyle?',
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
      name: 'selectedLegends',
      type: 'List<String>?',
      defaultValue: 'null',
      description:
          "The legend titles the chart's owner has selected. Null leaves the "
          'legend row uncontrolled.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description: "The chart's single focus node.",
    ),
  ],
);

// #docregion charts-areachart--area-chart-basic
Widget _areaChartBasic(BuildContext context) => const _AreaChartBasic();

class _AreaChartBasic extends StatefulWidget {
  const _AreaChartBasic();

  @override
  State<_AreaChartBasic> createState() => _AreaChartBasicState();
}

class _AreaChartBasicState extends State<_AreaChartBasic> {
  double _width = 700;
  double _height = 300;
  String _example = 'basicExample';
  bool _showAxisTitles = true;
  bool _legendMultiSelect = false;
  bool _changeChartMode = false;

  static const List<FluentLineChartDataPoint> _chart1Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(
          x: 20,
          y: 7000,
          xAxisCalloutData: '2018/01/01',
          yAxisCalloutText: '35%',
        ),
        FluentLineChartDataPoint(
          x: 25,
          y: 9000,
          xAxisCalloutData: '2018/01/15',
          yAxisCalloutText: '45%',
        ),
        FluentLineChartDataPoint(
          x: 30,
          y: 13000,
          xAxisCalloutData: '2018/01/28',
          yAxisCalloutText: '65%',
        ),
        FluentLineChartDataPoint(
          x: 35,
          y: 15000,
          xAxisCalloutData: '2018/02/01',
          yAxisCalloutText: '75%',
        ),
        FluentLineChartDataPoint(
          x: 40,
          y: 11000,
          xAxisCalloutData: '2018/03/01',
          yAxisCalloutText: '55%',
        ),
        FluentLineChartDataPoint(
          x: 45,
          y: 8760,
          xAxisCalloutData: '2018/03/15',
          yAxisCalloutText: '43%',
        ),
        FluentLineChartDataPoint(
          x: 50,
          y: 3500,
          xAxisCalloutData: '2018/03/28',
          yAxisCalloutText: '18%',
        ),
        FluentLineChartDataPoint(
          x: 55,
          y: 20000,
          xAxisCalloutData: '2018/04/04',
          yAxisCalloutText: '100%',
        ),
        FluentLineChartDataPoint(
          x: 60,
          y: 17000,
          xAxisCalloutData: '2018/04/15',
          yAxisCalloutText: '85%',
        ),
        FluentLineChartDataPoint(
          x: 65,
          y: 1000,
          xAxisCalloutData: '2018/05/05',
          yAxisCalloutText: '5%',
        ),
        FluentLineChartDataPoint(
          x: 70,
          y: 12000,
          xAxisCalloutData: '2018/06/01',
          yAxisCalloutText: '60%',
        ),
        FluentLineChartDataPoint(
          x: 75,
          y: 6876,
          xAxisCalloutData: '2018/01/15',
          yAxisCalloutText: '34%',
        ),
        FluentLineChartDataPoint(
          x: 80,
          y: 12000,
          xAxisCalloutData: '2018/04/30',
          yAxisCalloutText: '60%',
        ),
        FluentLineChartDataPoint(
          x: 85,
          y: 7000,
          xAxisCalloutData: '2018/05/04',
          yAxisCalloutText: '35%',
        ),
        FluentLineChartDataPoint(
          x: 90,
          y: 10000,
          xAxisCalloutData: '2018/06/01',
          yAxisCalloutText: '50%',
        ),
      ];

  static List<FluentLineChartDataPoint> _shifted(double offset) =>
      <FluentLineChartDataPoint>[
        for (final FluentLineChartDataPoint point in _chart1Points)
          FluentLineChartDataPoint(
            x: point.x,
            y: point.y + offset,
            xAxisCalloutData: point.xAxisCalloutData,
            yAxisCalloutText: point.yAxisCalloutText,
          ),
      ];

  static final FluentChartData _chartData = FluentChartData(
    chartTitle: 'Area chart basic example',
    lineChartData: <FluentLineChartSeries>[
      const FluentLineChartSeries(legend: 'legend1', data: _chart1Points),
      FluentLineChartSeries(legend: 'legend2', data: _shifted(5000)),
      FluentLineChartSeries(legend: 'legend3', data: _shifted(7000)),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      // Upstream's RadioGroup handler re-sets the flag it already holds, so
      // neither option changes what renders. Kept as a live selection, and the
      // chart below is the basic example either way.
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _example,
          onChanged: (String value) => setState(() => _example = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'basicExample',
              label: Text('Basic Example'),
            ),
            FluentRadio<String>(
              value: 'calloutExample',
              label: Text('Custom Callout Example'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      FluentSwitch(
        checked: _showAxisTitles,
        label: Text(_showAxisTitles ? 'Show Axis titles' : 'Hide axis titles'),
        onChanged: (bool value) => setState(() => _showAxisTitles = value),
      ),
      const SizedBox(height: 10),
      FluentSwitch(
        checked: _legendMultiSelect,
        label: Text(
          _legendMultiSelect
              ? 'Select multiple legends ON'
              : 'Select multiple legends OFF',
        ),
        onChanged: (bool value) => setState(() => _legendMultiSelect = value),
      ),
      const SizedBox(height: 10),
      FluentSwitch(
        checked: _changeChartMode,
        label: Text(
          _changeChartMode
              ? 'Change chart mode to toZeroY ON'
              : 'Change chart mode to toZeroY OFF',
        ),
        onChanged: (bool value) => setState(() => _changeChartMode = value),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: _width,
        height: _height,
        child: FluentAreaChart(
          data: _chartData,
          mode: _changeChartMode
              ? FluentAreaChartMode.toZeroY
              : FluentAreaChartMode.toNextY,
          legendSelectionMode: _legendMultiSelect
              ? FluentChartLegendSelectionMode.multiple
              : FluentChartLegendSelectionMode.single,
          props: FluentCartesianChartProps(
            yAxisTitle: _showAxisTitles
                ? 'Variation of stock market prices'
                : null,
            xAxisTitle: _showAxisTitles ? 'Number of days' : null,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-areachart--area-chart-basic

// #docregion charts-areachart--area-chart-custom-accessibility
Widget _areaChartCustomAccessibility(BuildContext context) =>
    const _AreaChartCustomAccessibility();

class _AreaChartCustomAccessibility extends StatefulWidget {
  const _AreaChartCustomAccessibility();

  @override
  State<_AreaChartCustomAccessibility> createState() =>
      _AreaChartCustomAccessibilityState();
}

class _AreaChartCustomAccessibilityState
    extends State<_AreaChartCustomAccessibility> {
  double _width = 700;
  double _height = 300;

  /// `d3.format('$,')` — the `$` prefix with thousands grouping.
  static String _dollars(double value) =>
      '${value < 0 ? '-' : ''}\$${value.abs().round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',')}';

  static const List<FluentLineChartDataPoint> _chart1Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(
          x: 20,
          y: 9,
          xAxisCalloutSemantics: FluentChartSemantics(label: 'x-Axis 20'),
          callOutSemantics: FluentChartSemantics(
            label: r'Point 1 of 5 in First series. X value 20 Y value $9',
          ),
        ),
        FluentLineChartDataPoint(
          x: 40,
          y: 20,
          xAxisCalloutSemantics: FluentChartSemantics(label: 'x-Axis 40'),
          callOutSemantics: FluentChartSemantics(
            label: r'Point 2 of 5 in First series. X value 40 Y value $20',
          ),
        ),
        FluentLineChartDataPoint(
          x: 55,
          y: 27,
          xAxisCalloutSemantics: FluentChartSemantics(label: 'x-Axis 55'),
          callOutSemantics: FluentChartSemantics(
            label: r'Point 3 of 5 in First series. X value 55 Y value $27',
          ),
        ),
        FluentLineChartDataPoint(
          x: 60,
          y: 37,
          xAxisCalloutSemantics: FluentChartSemantics(label: 'x-Axis 60'),
          callOutSemantics: FluentChartSemantics(
            label: r'Point 4 of 5 in First series. X value 60 Y value $37',
          ),
        ),
        FluentLineChartDataPoint(
          x: 65,
          y: 51,
          xAxisCalloutSemantics: FluentChartSemantics(label: 'x-Axis 65'),
          callOutSemantics: FluentChartSemantics(
            label: r'Point 5 of 5 in First series. X value 65 Y value $51',
          ),
        ),
      ];

  static const List<FluentLineChartDataPoint>
  _chart2Points = <FluentLineChartDataPoint>[
    FluentLineChartDataPoint(
      x: 20,
      y: 21,
      callOutSemantics: FluentChartSemantics(
        label:
            r'First of 5 points in Second series. X coordinate is 20 and Y coordinate is $21',
      ),
    ),
    FluentLineChartDataPoint(
      x: 40,
      y: 25,
      callOutSemantics: FluentChartSemantics(
        label:
            r'Second of 5 points in Second series. X coordinate is 40 and Y coordinate is $25',
      ),
    ),
    FluentLineChartDataPoint(
      x: 55,
      y: 23,
      callOutSemantics: FluentChartSemantics(
        label:
            r'Third of 5 points in Second series. X coordinate is 55 and Y coordinate is $23',
      ),
    ),
    FluentLineChartDataPoint(
      x: 60,
      y: 7,
      callOutSemantics: FluentChartSemantics(
        label:
            r'Fourth of 5 points in Second series. X coordinate is 60 and Y coordinate is $7',
      ),
    ),
    FluentLineChartDataPoint(
      x: 65,
      y: 55,
      callOutSemantics: FluentChartSemantics(
        label:
            r'Fifth of 5 points in Second series. X coordinate is 65 and Y coordinate is $55',
      ),
    ),
  ];

  static const List<FluentLineChartDataPoint>
  _chart3Points = <FluentLineChartDataPoint>[
    FluentLineChartDataPoint(
      x: 20,
      y: 30,
      callOutSemantics: FluentChartSemantics(
        label:
            r'First of 5 points in Third series. X coordinate is 20 and Y coordinate is $30',
      ),
    ),
    FluentLineChartDataPoint(
      x: 40,
      y: 35,
      callOutSemantics: FluentChartSemantics(
        label:
            r'Second of 5 points in Third series. X coordinate is 40 and Y coordinate is $35',
      ),
    ),
    FluentLineChartDataPoint(
      x: 55,
      y: 33,
      callOutSemantics: FluentChartSemantics(
        label:
            r'Third of 5 points in Third series. X coordinate is 55 and Y coordinate is $33',
      ),
    ),
    FluentLineChartDataPoint(
      x: 60,
      y: 40,
      callOutSemantics: FluentChartSemantics(
        label:
            r'Fourth of 5 points in Third series. X coordinate is 60 and Y coordinate is $40',
      ),
    ),
    FluentLineChartDataPoint(
      x: 65,
      y: 10,
      callOutSemantics: FluentChartSemantics(
        label:
            r'Fifth of 5 points in Third series. X coordinate is 65 and Y coordinate is $10',
      ),
    ),
  ];

  static final FluentChartData _chartData = FluentChartData(
    chartTitle: 'Area chart Custom Accessibility example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'First',
        data: _chart1Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
      ),
      FluentLineChartSeries(
        legend: 'Second',
        data: _chart2Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
      ),
      FluentLineChartSeries(
        legend: 'Third',
        data: _chart3Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: _width,
        height: _height,
        child: FluentAreaChart(
          data: _chartData,
          props: const FluentCartesianChartProps(yAxisTickFormat: _dollars),
        ),
      ),
    ],
  );
}
// #enddocregion charts-areachart--area-chart-custom-accessibility

// #docregion charts-areachart--area-chart-large-data
Widget _areaChartLargeData(BuildContext context) => const _AreaChartLargeData();

class _AreaChartLargeData extends StatefulWidget {
  const _AreaChartLargeData();

  @override
  State<_AreaChartLargeData> createState() => _AreaChartLargeDataState();
}

class _AreaChartLargeDataState extends State<_AreaChartLargeData> {
  double _width = 700;
  double _height = 300;

  static const List<FluentLineChartDataPoint> _chart1Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 9),
        FluentLineChartDataPoint(x: 25, y: 14),
        FluentLineChartDataPoint(x: 30, y: 14),
        FluentLineChartDataPoint(x: 35, y: 23),
        FluentLineChartDataPoint(x: 40, y: 20),
        FluentLineChartDataPoint(x: 45, y: 31),
        FluentLineChartDataPoint(x: 50, y: 29),
        FluentLineChartDataPoint(x: 55, y: 27),
        FluentLineChartDataPoint(x: 60, y: 37),
        FluentLineChartDataPoint(x: 65, y: 51),
      ];

  static const List<FluentLineChartDataPoint> _chart2Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 21),
        FluentLineChartDataPoint(x: 25, y: 25),
        FluentLineChartDataPoint(x: 30, y: 10),
        FluentLineChartDataPoint(x: 35, y: 10),
        FluentLineChartDataPoint(x: 40, y: 14),
        FluentLineChartDataPoint(x: 45, y: 18),
        FluentLineChartDataPoint(x: 50, y: 9),
        FluentLineChartDataPoint(x: 55, y: 23),
        FluentLineChartDataPoint(x: 60, y: 7),
        FluentLineChartDataPoint(x: 65, y: 55),
      ];

  static const List<FluentLineChartDataPoint> _chart3Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 30),
        FluentLineChartDataPoint(x: 25, y: 35),
        FluentLineChartDataPoint(x: 30, y: 33),
        FluentLineChartDataPoint(x: 35, y: 40),
        FluentLineChartDataPoint(x: 40, y: 10),
        FluentLineChartDataPoint(x: 45, y: 40),
        FluentLineChartDataPoint(x: 50, y: 34),
        FluentLineChartDataPoint(x: 55, y: 40),
        FluentLineChartDataPoint(x: 60, y: 60),
        FluentLineChartDataPoint(x: 65, y: 40),
      ];

  static final FluentChartData _chartData = FluentChartData(
    chartTitle: 'Area chart large data example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'legend1',
        data: _chart1Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
      ),
      FluentLineChartSeries(
        legend: 'legend2',
        data: _chart2Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
      ),
      FluentLineChartSeries(
        legend: 'legend3',
        data: _chart3Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      // Upstream's `optimizeLargeData` selects a downsampling path that
      // `LineChart.tsx:1945` never reaches, so this port has no such flag and
      // the series are drawn in full.
      SizedBox(
        width: _width,
        height: _height,
        child: FluentAreaChart(data: _chartData),
      ),
    ],
  );
}
// #enddocregion charts-areachart--area-chart-large-data

// #docregion charts-areachart--area-chart-multiple
Widget _areaChartMultiple(BuildContext context) => const _AreaChartMultiple();

class _AreaChartMultiple extends StatefulWidget {
  const _AreaChartMultiple();

  @override
  State<_AreaChartMultiple> createState() => _AreaChartMultipleState();
}

class _AreaChartMultipleState extends State<_AreaChartMultiple> {
  double _width = 700;
  double _height = 300;

  /// `d3.format('$,')` — the `$` prefix with thousands grouping.
  static String _dollars(double value) =>
      '${value < 0 ? '-' : ''}\$${value.abs().round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',')}';

  static const List<FluentLineChartDataPoint> _chart1Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 9),
        FluentLineChartDataPoint(x: 25, y: 14),
        FluentLineChartDataPoint(x: 30, y: 14),
        FluentLineChartDataPoint(x: 35, y: 23),
        FluentLineChartDataPoint(x: 40, y: 20),
        FluentLineChartDataPoint(x: 45, y: 31),
        FluentLineChartDataPoint(x: 50, y: 29),
        FluentLineChartDataPoint(x: 55, y: 27),
        FluentLineChartDataPoint(x: 60, y: 37),
        FluentLineChartDataPoint(x: 65, y: 51),
      ];

  static const List<FluentLineChartDataPoint> _chart2Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 21),
        FluentLineChartDataPoint(x: 25, y: 25),
        FluentLineChartDataPoint(x: 30, y: 10),
        FluentLineChartDataPoint(x: 35, y: 10),
        FluentLineChartDataPoint(x: 40, y: 14),
        FluentLineChartDataPoint(x: 45, y: 18),
        FluentLineChartDataPoint(x: 50, y: 9),
        FluentLineChartDataPoint(x: 55, y: 23),
        FluentLineChartDataPoint(x: 60, y: 7),
        FluentLineChartDataPoint(x: 65, y: 55),
      ];

  static const List<FluentLineChartDataPoint> _chart3Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 30),
        FluentLineChartDataPoint(x: 25, y: 35),
        FluentLineChartDataPoint(x: 30, y: 33),
        FluentLineChartDataPoint(x: 35, y: 40),
        FluentLineChartDataPoint(x: 40, y: 10),
        FluentLineChartDataPoint(x: 45, y: 40),
        FluentLineChartDataPoint(x: 50, y: 34),
        FluentLineChartDataPoint(x: 55, y: 40),
        FluentLineChartDataPoint(x: 60, y: 60),
        FluentLineChartDataPoint(x: 65, y: 40),
      ];

  static final FluentChartData _chartData = FluentChartData(
    chartTitle: 'Area chart multiple example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'legend1',
        data: _chart1Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
      ),
      FluentLineChartSeries(
        legend: 'legend2',
        data: _chart2Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      ),
      FluentLineChartSeries(
        legend: 'legend3',
        data: _chart3Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: _width,
        height: _height,
        child: FluentAreaChart(
          data: _chartData,
          props: const FluentCartesianChartProps(yAxisTickFormat: _dollars),
        ),
      ),
    ],
  );
}
// #enddocregion charts-areachart--area-chart-multiple

// #docregion charts-areachart--area-chart-negative
Widget _areaChartNegative(BuildContext context) => const _AreaChartNegative();

class _AreaChartNegative extends StatefulWidget {
  const _AreaChartNegative();

  @override
  State<_AreaChartNegative> createState() => _AreaChartNegativeState();
}

class _AreaChartNegativeState extends State<_AreaChartNegative> {
  double _width = 700;
  double _height = 300;
  String _example = 'basicExample';
  bool _showAxisTitles = true;

  static const List<FluentLineChartDataPoint> _chart1Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(
          x: 20,
          y: 7000,
          xAxisCalloutData: '2018/01/01',
          yAxisCalloutText: '35%',
        ),
        FluentLineChartDataPoint(
          x: 25,
          y: -9000,
          xAxisCalloutData: '2018/01/15',
          yAxisCalloutText: '-45%',
        ),
        FluentLineChartDataPoint(
          x: 30,
          y: 13000,
          xAxisCalloutData: '2018/01/28',
          yAxisCalloutText: '65%',
        ),
        FluentLineChartDataPoint(
          x: 35,
          y: -15000,
          xAxisCalloutData: '2018/02/01',
          yAxisCalloutText: '-75%',
        ),
        FluentLineChartDataPoint(
          x: 40,
          y: 11000,
          xAxisCalloutData: '2018/03/01',
          yAxisCalloutText: '55%',
        ),
        FluentLineChartDataPoint(
          x: 45,
          y: -8760,
          xAxisCalloutData: '2018/03/15',
          yAxisCalloutText: '-43%',
        ),
        FluentLineChartDataPoint(
          x: 50,
          y: 3500,
          xAxisCalloutData: '2018/03/28',
          yAxisCalloutText: '18%',
        ),
        FluentLineChartDataPoint(
          x: 55,
          y: -20000,
          xAxisCalloutData: '2018/04/04',
          yAxisCalloutText: '-100%',
        ),
        FluentLineChartDataPoint(
          x: 60,
          y: 17000,
          xAxisCalloutData: '2018/04/15',
          yAxisCalloutText: '85%',
        ),
        FluentLineChartDataPoint(
          x: 65,
          y: -1000,
          xAxisCalloutData: '2018/05/05',
          yAxisCalloutText: '-5%',
        ),
        FluentLineChartDataPoint(
          x: 70,
          y: 12000,
          xAxisCalloutData: '2018/06/01',
          yAxisCalloutText: '60%',
        ),
        FluentLineChartDataPoint(
          x: 75,
          y: -6876,
          xAxisCalloutData: '2018/01/15',
          yAxisCalloutText: '-34%',
        ),
        FluentLineChartDataPoint(
          x: 80,
          y: 12000,
          xAxisCalloutData: '2018/04/30',
          yAxisCalloutText: '60%',
        ),
        FluentLineChartDataPoint(
          x: 85,
          y: -7000,
          xAxisCalloutData: '2018/05/04',
          yAxisCalloutText: '-35%',
        ),
        FluentLineChartDataPoint(
          x: 90,
          y: 10000,
          xAxisCalloutData: '2018/06/01',
          yAxisCalloutText: '50%',
        ),
      ];

  static const FluentChartData _chartData = FluentChartData(
    chartTitle: 'Area chart Negative y example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(legend: 'legend1', data: _chart1Points),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      // Upstream's RadioGroup handler flips a flag nothing reads, so neither
      // option changes what renders. Kept as a live selection.
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _example,
          onChanged: (String value) => setState(() => _example = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'basicExample',
              label: Text('Basic Example'),
            ),
            FluentRadio<String>(
              value: 'calloutExample',
              label: Text('Custom Callout Example'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      FluentSwitch(
        checked: _showAxisTitles,
        label: Text(
          _showAxisTitles ? 'Switch Axis titles' : 'Hide Axis titles',
        ),
        onChanged: (bool value) => setState(() => _showAxisTitles = value),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: _width,
        height: _height,
        child: FluentAreaChart(
          data: _chartData,
          props: FluentCartesianChartProps(
            yAxisTitle: _showAxisTitles
                ? 'Variation of stock market prices'
                : null,
            xAxisTitle: _showAxisTitles ? 'Number of days' : null,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-areachart--area-chart-negative

// #docregion charts-areachart--area-chart-multiple-negative
Widget _areaChartMultipleNegative(BuildContext context) =>
    const _AreaChartMultipleNegative();

class _AreaChartMultipleNegative extends StatefulWidget {
  const _AreaChartMultipleNegative();

  @override
  State<_AreaChartMultipleNegative> createState() =>
      _AreaChartMultipleNegativeState();
}

class _AreaChartMultipleNegativeState
    extends State<_AreaChartMultipleNegative> {
  double _width = 700;
  double _height = 300;

  /// `d3.format('$,')` — the `$` prefix with thousands grouping.
  static String _dollars(double value) =>
      '${value < 0 ? '-' : ''}\$${value.abs().round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',')}';

  static const List<FluentLineChartDataPoint> _chart1Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: -9),
        FluentLineChartDataPoint(x: 25, y: 14),
        FluentLineChartDataPoint(x: 30, y: -14),
        FluentLineChartDataPoint(x: 35, y: 23),
        FluentLineChartDataPoint(x: 40, y: -20),
        FluentLineChartDataPoint(x: 45, y: 31),
        FluentLineChartDataPoint(x: 50, y: -29),
        FluentLineChartDataPoint(x: 55, y: 27),
        FluentLineChartDataPoint(x: 60, y: -37),
        FluentLineChartDataPoint(x: 65, y: 51),
      ];

  static const List<FluentLineChartDataPoint> _chart2Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 21),
        FluentLineChartDataPoint(x: 25, y: -25),
        FluentLineChartDataPoint(x: 30, y: 10),
        FluentLineChartDataPoint(x: 35, y: -10),
        FluentLineChartDataPoint(x: 40, y: 14),
        FluentLineChartDataPoint(x: 45, y: -18),
        FluentLineChartDataPoint(x: 50, y: 9),
        FluentLineChartDataPoint(x: 55, y: -23),
        FluentLineChartDataPoint(x: 60, y: 7),
        FluentLineChartDataPoint(x: 65, y: -55),
      ];

  static const List<FluentLineChartDataPoint> _chart3Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 30),
        FluentLineChartDataPoint(x: 25, y: 35),
        FluentLineChartDataPoint(x: 30, y: -33),
        FluentLineChartDataPoint(x: 35, y: 40),
        FluentLineChartDataPoint(x: 40, y: 10),
        FluentLineChartDataPoint(x: 45, y: -40),
        FluentLineChartDataPoint(x: 50, y: 34),
        FluentLineChartDataPoint(x: 55, y: 40),
        FluentLineChartDataPoint(x: 60, y: -60),
        FluentLineChartDataPoint(x: 65, y: 40),
      ];

  static final FluentChartData _chartData = FluentChartData(
    chartTitle: 'Area chart multiple negative y example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'legend1',
        data: _chart1Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
      ),
      FluentLineChartSeries(
        legend: 'legend2',
        data: _chart2Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      ),
      FluentLineChartSeries(
        legend: 'legend3',
        data: _chart3Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: _width,
        height: _height,
        child: FluentAreaChart(
          data: _chartData,
          props: const FluentCartesianChartProps(yAxisTickFormat: _dollars),
        ),
      ),
    ],
  );
}
// #enddocregion charts-areachart--area-chart-multiple-negative

// #docregion charts-areachart--area-chart-all-negative
Widget _areaChartAllNegative(BuildContext context) =>
    const _AreaChartAllNegative();

class _AreaChartAllNegative extends StatefulWidget {
  const _AreaChartAllNegative();

  @override
  State<_AreaChartAllNegative> createState() => _AreaChartAllNegativeState();
}

class _AreaChartAllNegativeState extends State<_AreaChartAllNegative> {
  double _width = 700;
  double _height = 300;

  /// `d3.format('$,')` — the `$` prefix with thousands grouping.
  static String _dollars(double value) =>
      '${value < 0 ? '-' : ''}\$${value.abs().round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',')}';

  static const List<FluentLineChartDataPoint> _chart1Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: -9),
        FluentLineChartDataPoint(x: 25, y: -14),
        FluentLineChartDataPoint(x: 30, y: -14),
        FluentLineChartDataPoint(x: 35, y: -23),
        FluentLineChartDataPoint(x: 40, y: -20),
        FluentLineChartDataPoint(x: 45, y: -31),
        FluentLineChartDataPoint(x: 50, y: -29),
        FluentLineChartDataPoint(x: 55, y: -27),
        FluentLineChartDataPoint(x: 60, y: -37),
        FluentLineChartDataPoint(x: 65, y: -51),
      ];

  static const List<FluentLineChartDataPoint> _chart2Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: -21),
        FluentLineChartDataPoint(x: 25, y: -25),
        FluentLineChartDataPoint(x: 30, y: -10),
        FluentLineChartDataPoint(x: 35, y: -10),
        FluentLineChartDataPoint(x: 40, y: -14),
        FluentLineChartDataPoint(x: 45, y: -18),
        FluentLineChartDataPoint(x: 50, y: -9),
        FluentLineChartDataPoint(x: 55, y: -23),
        FluentLineChartDataPoint(x: 60, y: -7),
        FluentLineChartDataPoint(x: 65, y: -55),
      ];

  static const List<FluentLineChartDataPoint> _chart3Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: -30),
        FluentLineChartDataPoint(x: 25, y: -35),
        FluentLineChartDataPoint(x: 30, y: -33),
        FluentLineChartDataPoint(x: 35, y: -40),
        FluentLineChartDataPoint(x: 40, y: -10),
        FluentLineChartDataPoint(x: 45, y: -40),
        FluentLineChartDataPoint(x: 50, y: -34),
        FluentLineChartDataPoint(x: 55, y: -40),
        FluentLineChartDataPoint(x: 60, y: -60),
        FluentLineChartDataPoint(x: 65, y: -40),
      ];

  static final FluentChartData _chartData = FluentChartData(
    chartTitle: 'Area chart multiple all negative y example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'legend1',
        data: _chart1Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
      ),
      FluentLineChartSeries(
        legend: 'legend2',
        data: _chart2Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      ),
      FluentLineChartSeries(
        legend: 'legend3',
        data: _chart3Points,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: _width,
        height: _height,
        child: FluentAreaChart(
          data: _chartData,
          props: const FluentCartesianChartProps(
            yMinValue: -200,
            yAxisTickFormat: _dollars,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-areachart--area-chart-all-negative

// #docregion charts-areachart--area-chart-secondary-y-axis
Widget _areaChartSecondaryYAxis(BuildContext context) =>
    const _AreaChartSecondaryYAxis();

class _AreaChartSecondaryYAxis extends StatefulWidget {
  const _AreaChartSecondaryYAxis();

  @override
  State<_AreaChartSecondaryYAxis> createState() =>
      _AreaChartSecondaryYAxisState();
}

class _AreaChartSecondaryYAxisState extends State<_AreaChartSecondaryYAxis> {
  double _width = 700;
  double _height = 300;

  static const List<FluentLineChartDataPoint> _chart1Points =
      <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 20, y: 7000),
        FluentLineChartDataPoint(x: 25, y: 9000),
        FluentLineChartDataPoint(x: 30, y: 13000),
        FluentLineChartDataPoint(x: 35, y: 15000),
        FluentLineChartDataPoint(x: 40, y: 11000),
        FluentLineChartDataPoint(x: 45, y: 8760),
        FluentLineChartDataPoint(x: 50, y: 3500),
        FluentLineChartDataPoint(x: 55, y: 20000),
        FluentLineChartDataPoint(x: 60, y: 17000),
        FluentLineChartDataPoint(x: 65, y: 1000),
        FluentLineChartDataPoint(x: 70, y: 12000),
        FluentLineChartDataPoint(x: 75, y: 6876),
        FluentLineChartDataPoint(x: 80, y: 12000),
        FluentLineChartDataPoint(x: 85, y: 7000),
        FluentLineChartDataPoint(x: 90, y: 10000),
      ];

  // Upstream offsets the second series by `Math.floor(Math.random() * 10000)`.
  // `dart:math` is outside this example's import budget and a docs demo that
  // redraws differently on every hot reload is not one you can compare against
  // a screenshot, so the offset is a fixed cycle over the same 0..10000 range.
  static final List<FluentLineChartDataPoint> _chart2Points =
      <FluentLineChartDataPoint>[
        for (int index = 0; index < _chart1Points.length; index++)
          FluentLineChartDataPoint(
            x: _chart1Points[index].x,
            y: _chart1Points[index].y + (index * 3137) % 10000,
          ),
      ];

  static final FluentChartData _chartData = FluentChartData(
    chartTitle: 'Area chart secondary y-axis example',
    lineChartData: <FluentLineChartSeries>[
      const FluentLineChartSeries(legend: 'legend1', data: _chart1Points),
      FluentLineChartSeries(
        legend: 'legend2',
        data: _chart2Points,
        useSecondaryYScale: true,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Change Height:'),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: _width,
        height: _height,
        child: FluentAreaChart(
          data: _chartData,
          props: const FluentCartesianChartProps(
            hideTickOverlap: true,
            yAxisTitle: 'Variation of stock market prices',
            xAxisTitle: 'Number of days',
            secondaryYAxisTitle: 'Variation of stock market prices 2',
            secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
          ),
        ),
      ),
    ],
  );
}

// #enddocregion charts-areachart--area-chart-secondary-y-axis
