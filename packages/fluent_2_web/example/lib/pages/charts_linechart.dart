import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The LineChart docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage lineChartPage = DocsPage(
  id: 'charts-linechart',
  title: 'LineChart',
  description:
      'A line chart is a visual representation of data that shows the '
      'relationship between two variables, often used to show trends '
      'over a period of time or number line. Line charts plot data at '
      'regular intervals connected by lines. Multi-line charts enable '
      'comparison between multiple series over the same x domain. Time '
      'intervals are traditionally mapped to the horizontal axis. Data '
      'values are mapped to the vertical axis.',
  source: 'lib/pages/charts_linechart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'Padding on the left and right of the chart is determined by '
          'the x-axis labels - it should start and end at or nearly at '
          'the first and last tick mark. The minimum padding is 8px.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- **Line** A line represents a set of values from the same '
          'data set. Each line takes on a new swatch in the data '
          'visualization library to distinguish it from others. 2px '
          'wide with rounded endpoints; no rounding of joints to avoid '
          'data misrepresentation. 6px border behind line with rounded '
          'endpoints that match background color to improve legibility '
          'and readability when two or more lines cross each other.\n'
          '- **Pinpoints** Optional: Pinpoints are built into each line '
          'component and can be toggled on to reveal a unique shape to '
          'remove reliance on colors as sole identifier of data set. '
          'Size: 8px. Off by default with the option to toggle it on.\n',
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
      title: 'Customizing the chart',
      body:
          'Use a line graph to visualize data sets over a period of '
          'time for an individual or group of items. The number of '
          'lines (data sets) depend on the attributes selected during '
          'the report creation.\n'
          'The line graph thickness will vary depending on the number '
          'of data sets and data increments.\n'
          '#### Event annotations\n'
          'Event annotations are used to highlight events and annotate '
          'them using messages. Annotations are represented by vertical '
          'line markers to mark the date and callouts to represent the '
          'message. Events can be added by using `eventAnnotationProps` '
          'prop. Each event contains a `date`, `event message` and '
          'event details callout callback `onRenderCard`\n'
          '#### Gaps\n'
          'A line chart can have gaps/breaks in between. This is to '
          'represent missing data. The gaps can also be replaced with '
          'dashed or dotted lines for specific scenarios, say to '
          'represent low confidence predictions for a time series '
          'forecast graph. Gaps can be added by using `gaps` prop. A '
          'gap is denoted by `startIndex` and `endIndex` datapoints in '
          'the line. A line will be drawn till the `startIndex` and '
          'skipped for `endIndex - startIndex` number of datapoints. A '
          'line can have as many gaps as possible.\n'
          '#### Line border\n'
          'Each line in the chart can contain a 2 px border for better '
          'highlighting of the line when there are multiple items in '
          'the chart. The border will have color of the background '
          'theme. Lines will be highlighted in order of their '
          'appearance in legends. Line border is a highly suggested '
          'style that you should apply to make multiple lines more '
          'distinguishable from each other. Use `lineBorderWidth` prop '
          'present inside `lineOptions` to enable it.\n'
          '#### Lines with large dataset\n'
          'We use a path-based rendering technique to show datasets '
          'with large number of points (greater than 1k). Using this '
          'technique datasets with over 10k points can be rendered with '
          'high performance. Enable this rendering method by setting '
          'the `optimizeLargeData` prop to true. Refer to the '
          '[performance '
          'section](https://github.com/microsoft/fluentui/blob/master/packages/charts/react-charting/README.md#performance) '
          'to know more about our performance benchmarks.\n'
          '#### Custom accessibility\n'
          'Line chart provides a bunch of props to enable custom '
          'accessibility messages. Use `xAxisCalloutAccessibilityData` '
          'and `callOutAccessibilityData` to configure x axis and y '
          'axis accessibility messages, respectively.\n'
          '#### Axis localization\n'
          'The chart axes support 2 ways of localization.\n'
          '1. JavaScript provided inbuilt localization for numeric and '
          'date axis. Specify the culture and `dateLocalizeOptions` for '
          'date axis to define target localization. Refer the '
          '[Javascript localization '
          'guide](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toLocaleDateString) '
          'for usage.\n'
          '2. Custom locale definition: The consumer of the library can '
          'specify a custom locale definition as supported by d3 [like '
          'this](https://github.com/d3/d3-time-format/blob/main/locale/en-US.json). '
          'The date axis will use the date range and the multiformat '
          'specified in the definition to determine the correct labels '
          'to show in the ticks. For example - If the date range is in '
          'days, then the axis will show hourly ticks. If the date '
          'range spans across months, then the axis will show months in '
          'tick labels and so on. Specify the custom locale definition '
          'in the `timeFormatLocale` prop. Refer to the Custom Locale '
          'Date Axis example in line chart for sample usage.\n',
    ),
    ProseBlock(
      title: 'Creating Date Objects For Chart Data',
      body:
          'For instructions on how to create date objects to be passed '
          'as data points in the chart, see [Creating Date Objects For '
          'Chart Data | FluentUI Charting Contrib '
          'Docsite](https://microsoft.github.io/fluentui-charting-contrib/docs/creating-date-objects-for-chart-data)\n',
    ),
    ProseBlock(title: 'Do\'s', body: '- Use line chart to portray trends.\n'),
    ProseBlock(
      title: 'Don\'ts',
      body:
          '- Don\'t use curved lines to represent data as it may show '
          'the data incorrectly.\n'
          '- While multiple lines on a line chart can provide some '
          'additional information and clarity, too many lines can make '
          'the chart difficult to read. Don\'t use for more than 9 data '
          'points. Too many lines make it hard to read.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-linechart--line-chart-basic',
      title: 'Line Chart Basic',
      builder: _lineChartBasic,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-custom-accessibility',
      title: 'Line Chart Custom Accessibility',
      builder: _lineChartCustomAccessibility,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-multiple',
      title: 'Line Chart Multiple',
      builder: _lineChartMultiple,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-styled',
      title: 'Line Chart Styled',
      builder: _lineChartStyled,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-custom-locale-date-axis',
      title: 'Line Chart Custom Locale Date Axis',
      builder: _lineChartCustomLocaleDateAxis,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-events',
      title: 'Line Chart Events',
      builder: _lineChartEvents,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-gaps',
      title: 'Line Chart Gaps',
      builder: _lineChartGaps,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-large-data',
      title: 'Line Chart Large Data',
      builder: _lineChartLargeData,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-negative',
      title: 'Line Chart Negative',
      builder: _lineChartNegative,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-all-negative',
      title: 'Line Chart All Negative',
      builder: _lineChartAllNegative,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-secondary-y-axis',
      title: 'Line Chart Secondary Y Axis',
      builder: _lineChartSecondaryYAxis,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-log-axis-example',
      title: 'Line Chart Log Axis Example',
      builder: _lineChartLogAxisExample,
    ),
    DocsSection(
      id: 'charts-linechart--line-chart-annotations-example',
      title: 'Line Chart Annotations Example',
      builder: _lineChartAnnotationsExample,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'FluentChartData',
      description:
          'The data bundle. Only lineChartData and chartTitle are read.',
    ),
    PropRow(
      name: 'props',
      type: 'FluentCartesianChartProps',
      defaultValue: 'FluentCartesianChartProps()',
      description:
          'Shell configuration: axes, bounds, margins, titles and tick values.',
    ),
    PropRow(
      name: 'eventAnnotations',
      type: 'List<FluentEventAnnotation>',
      defaultValue: '[]',
      description:
          'Dated rules drawn across the plot with a label band above it.',
    ),
    PropRow(
      name: 'eventAnnotationMergedLabel',
      type: 'String Function(int count)?',
      defaultValue: 'null',
      description: 'Label used when several annotations collapse into one.',
    ),
    PropRow(
      name: 'colorFillBars',
      type: 'List<FluentColorFillBar>',
      defaultValue: '[]',
      description: 'Shaded x ranges drawn behind the lines.',
    ),
    PropRow(
      name: 'allowMultipleShapesForPoints',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether points cycle through the eight marker shapes, and the first '
          'and last point of every series stay visible.',
    ),
    PropRow(
      name: 'optimizeLargeData',
      type: 'bool',
      defaultValue: 'false',
      description: 'Forces the single-path engine.',
    ),
    PropRow(
      name: 'isCalloutForStack',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the popover lists every series at the hovered x.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'BCP-47 locale for popover formatting.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentLineChartStyle?',
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

// #docregion charts-linechart--line-chart-basic
Widget _lineChartBasic(BuildContext context) => const _LineChartBasic();

class _LineChartBasic extends StatefulWidget {
  const _LineChartBasic();

  @override
  State<_LineChartBasic> createState() => _LineChartBasicState();
}

class _LineChartBasicState extends State<_LineChartBasic> {
  double _width = 700;
  double _height = 300;
  bool _allowMultipleShapes = false;
  bool _showAxisTitles = true;
  bool _useUtc = true;
  String _selectedCallout = 'MultiCallout';

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart Basic Example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3),
            y: 216000,
            onDataPointClick: () => debugPrint('click on 217000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 10),
            y: 218123,
            onDataPointClick: () => debugPrint('click on 217123'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 11),
            y: 217124,
            onDataPointClick: () => debugPrint('click on 217124'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 4),
            y: 248000,
            onDataPointClick: () => debugPrint('click on 248000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 5),
            y: 252000,
            onDataPointClick: () => debugPrint('click on 252000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 6),
            y: 274000,
            onDataPointClick: () => debugPrint('click on 274000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 7),
            y: 260000,
            onDataPointClick: () => debugPrint('click on 260000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 8),
            y: 304000,
            onDataPointClick: () => debugPrint('click on 300000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 9),
            y: 218000,
            onDataPointClick: () => debugPrint('click on 218000'),
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        onLineClick: () => debugPrint('From_Legacy_to_O365'),
      ),
      FluentLineChartSeries(
        legend: 'All',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 297000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 284000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 282000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 294000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 224000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 300000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 298000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      ),
      FluentLineChartSeries(
        legend: 'single point',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5, 12), y: 232000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
      const SizedBox(height: 12),
      FluentSwitch(
        checked: _allowMultipleShapes,
        label: Text(
          _allowMultipleShapes
              ? 'Enabled multiple shapes for each line'
              : 'Disabled multiple shapes for each line',
        ),
        onChanged: (bool value) => setState(() => _allowMultipleShapes = value),
      ),
      const SizedBox(height: 10),
      FluentSwitch(
        checked: _showAxisTitles,
        label: Text(_showAxisTitles ? 'Show axis titles' : 'Hide axis titles'),
        onChanged: (bool value) => setState(() => _showAxisTitles = value),
      ),
      const SizedBox(height: 10),
      FluentCheckbox(
        checked: _useUtc,
        label: const Text('Use UTC time'),
        onChanged: (bool? value) => setState(() => _useUtc = value ?? false),
      ),
      const SizedBox(height: 10),
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
              value: 'MultiCallout',
              label: Text('Stack Callout'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            // Upstream reads `window.navigator.language` and falls back to
            // 'en-us'; a Flutter demo has no navigator, so the fallback stands.
            culture: 'en-us',
            allowMultipleShapesForPoints: _allowMultipleShapes,
            isCalloutForStack: _selectedCallout == 'MultiCallout',
            props: FluentCartesianChartProps(
              yMinValue: 200,
              yMaxValue: 301,
              xAxisTickCount: 10,
              useUTC: _useUtc,
              yAxisTitle: _showAxisTitles
                  ? 'Different categories of mail flow each of which are '
                        'categorized into different categories'
                  : null,
              xAxisTitle: _showAxisTitles ? 'Values of each category' : null,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-basic

// #docregion charts-linechart--line-chart-custom-accessibility
Widget _lineChartCustomAccessibility(BuildContext context) =>
    const _LineChartCustomAccessibility();

class _LineChartCustomAccessibility extends StatefulWidget {
  const _LineChartCustomAccessibility();

  @override
  State<_LineChartCustomAccessibility> createState() =>
      _LineChartCustomAccessibilityState();
}

class _LineChartCustomAccessibilityState
    extends State<_LineChartCustomAccessibility> {
  double _width = 700;
  double _height = 300;
  bool _allowMultipleShapes = false;

  void _onLegendClick(List<String> selectedLegend) {
    if (selectedLegend.isNotEmpty) {
      debugPrint('Selected legend - ${selectedLegend.join(', ')}');
    }
  }

  // Upstream's `tickFormat="%m/%d"`. Our props bag takes a formatter callback
  // rather than a d3 format string.
  static String _monthDay(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart Custom Accessibility Example',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'First',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime(2018),
            y: 10,
            xAxisCalloutData: '2018/01/01',
            yAxisCalloutText: '10%',
            xAxisCalloutSemantics: const FluentChartSemantics(
              label: 'x-Axis 2018/01/01',
            ),
            callOutSemantics: const FluentChartSemantics(
              label: 'Line series 1 of 5 Point 1 First 10%',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 2),
            y: 30,
            xAxisCalloutData: '2018/01/15',
            yAxisCalloutText: '18%',
            xAxisCalloutSemantics: const FluentChartSemantics(
              label: 'x-Axis 2018/01/15',
            ),
            callOutSemantics: const FluentChartSemantics(
              label: 'Line series 2 of 5 Point 1 First 18%',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 3),
            y: 10,
            xAxisCalloutData: '2018/01/28',
            yAxisCalloutText: '24%',
            xAxisCalloutSemantics: const FluentChartSemantics(
              label: 'x-Axis 2018/01/28',
            ),
            callOutSemantics: const FluentChartSemantics(
              label: 'Line series 3 of 5 Point 1 First 24%',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 4),
            y: 30,
            xAxisCalloutData: '2018/02/01',
            yAxisCalloutText: '25%',
            xAxisCalloutSemantics: const FluentChartSemantics(
              label: 'x-Axis 2018/02/01',
            ),
            callOutSemantics: const FluentChartSemantics(
              label: 'Line series 4 of 5 Point 1 First 25%',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 5),
            y: 10,
            xAxisCalloutData: '2018/03/01',
            yAxisCalloutText: '15%',
            xAxisCalloutSemantics: const FluentChartSemantics(
              label: 'x-Axis 2018/03/01',
            ),
            callOutSemantics: const FluentChartSemantics(
              label: 'Line series 5 of 5 Point 1 First 15%',
            ),
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        lineOptions: const FluentLineOptions(
          strokeWidth: 4,
          lineBorderWidth: 4,
        ),
        onLegendClick: _onLegendClick,
      ),
      FluentLineChartSeries(
        legend: 'Second',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime(2018),
            y: 30,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 2 Second 30',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 2),
            y: 50,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 2 Second 50',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 3),
            y: 30,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 2 Second 30',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 4),
            y: 50,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 2 Second 50',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 5),
            y: 30,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 2 Second 30',
            ),
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
        lineOptions: const FluentLineOptions(
          strokeWidth: 4,
          lineBorderWidth: 4,
        ),
        onLegendClick: _onLegendClick,
      ),
      FluentLineChartSeries(
        legend: 'Third',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime(2018),
            y: 50,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 3 Third 50',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 2),
            y: 70,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 3 Third 70',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 3),
            y: 50,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 3 Third 50',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 4),
            y: 70,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 3 Third 70',
            ),
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 5),
            y: 50,
            callOutSemantics: const FluentChartSemantics(
              label: 'Point 3 Third 50',
            ),
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        lineOptions: const FluentLineOptions(
          strokeWidth: 4,
          lineBorderWidth: 4,
        ),
        onLegendClick: _onLegendClick,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
      const SizedBox(height: 12),
      FluentSwitch(
        checked: _allowMultipleShapes,
        label: Text(
          _allowMultipleShapes
              ? 'Enabled multiple shapes for each line'
              : 'Disabled multiple shapes for each line',
        ),
        onChanged: (bool value) => setState(() => _allowMultipleShapes = value),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            allowMultipleShapesForPoints: _allowMultipleShapes,
            // `legendProps.canSelectMultipleLegends`. `allowFocusOnLegends` has
            // no counterpart: our legend rows are always focusable.
            legendSelectionMode: FluentChartLegendSelectionMode.multiple,
            colorFillBars: <FluentColorFillBar>[
              FluentColorFillBar(
                legend: 'Time range 1',
                color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
                data: <FluentColorFillBarRange>[
                  FluentColorFillBarRange(
                    startX: DateTime(2018, 1, 6),
                    endX: DateTime(2018, 1, 25),
                  ),
                ],
              ),
              FluentColorFillBar(
                legend: 'Time range 2',
                color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
                applyPattern: true,
                data: <FluentColorFillBarRange>[
                  FluentColorFillBarRange(
                    startX: DateTime(2018, 1, 18),
                    endX: DateTime(2018, 2, 20),
                  ),
                  FluentColorFillBarRange(
                    startX: DateTime(2018, 4, 17),
                    endX: DateTime(2018, 5, 10),
                  ),
                ],
              ),
            ],
            props: FluentCartesianChartProps(
              customDateTimeFormatter: _monthDay,
              // Passing tick values is optional, for more control.
              // If you do not pass them the line chart will render them for you
              // based on D3's standard.
              tickValues: <Object>[
                DateTime(2018),
                DateTime(2018, 2),
                DateTime(2018, 3),
                DateTime(2018, 4),
                DateTime(2018, 5),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-custom-accessibility

// #docregion charts-linechart--line-chart-multiple
Widget _lineChartMultiple(BuildContext context) => const _LineChartMultiple();

class _LineChartMultiple extends StatefulWidget {
  const _LineChartMultiple();

  @override
  State<_LineChartMultiple> createState() => _LineChartMultipleState();
}

class _LineChartMultipleState extends State<_LineChartMultiple> {
  double _width = 700;
  double _height = 300;
  bool _allowMultipleShapes = false;

  void _onLegendClick(List<String> selectedLegend) {
    if (selectedLegend.isNotEmpty) {
      debugPrint('Selected legend - ${selectedLegend.join(', ')}');
    }
  }

  static String _monthDay(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';

  // Every series but the first plots the same six months, so only the y values
  // change. The numbers are upstream's, one row per series.
  FluentLineChartSeries _series(String legend, List<double> ys) =>
      FluentLineChartSeries(
        legend: legend,
        data: <FluentLineChartDataPoint>[
          for (var i = 0; i < ys.length; i++)
            FluentLineChartDataPoint(x: DateTime(2018, i + 1), y: ys[i]),
        ],
        lineOptions: const FluentLineOptions(
          strokeWidth: 4,
          lineBorderWidth: 4,
        ),
        onLegendClick: _onLegendClick,
      );

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'First',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime(2018),
            y: 10,
            xAxisCalloutData: '2018/01/01',
            yAxisCalloutText: '10%',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 2),
            y: 30,
            xAxisCalloutData: '2018/02/01',
            yAxisCalloutText: '18%',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 3),
            y: 10,
            xAxisCalloutData: '2018/03/01',
            yAxisCalloutText: '24%',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 4),
            y: 30,
            xAxisCalloutData: '2018/04/01',
            yAxisCalloutText: '25%',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 5),
            y: 10,
            xAxisCalloutData: '2018/05/01',
            yAxisCalloutText: '15%',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 6),
            y: 30,
            xAxisCalloutData: '2018/06/01',
            yAxisCalloutText: '30%',
          ),
        ],
        lineOptions: const FluentLineOptions(
          strokeWidth: 4,
          lineBorderWidth: 4,
        ),
        onLegendClick: _onLegendClick,
      ),
      _series('Second', <double>[30, 50, 30, 50, 30, 50]),
      _series('Third', <double>[50, 70, 50, 70, 50, 70]),
      _series('Fourth', <double>[70, 90, 70, 90, 70, 90]),
      _series('Fifth', <double>[90, 110, 90, 110, 90, 110]),
      _series('Sixth', <double>[110, 130, 110, 130, 110, 130]),
      _series('Seventh', <double>[130, 150, 130, 150, 130, 150]),
      _series('Eight', <double>[150, 170, 150, 170, 150, 170]),
      _series('Ninth', <double>[170, 190, 170, 190, 170, 190]),
      _series('Tenth', <double>[190, 210, 190, 210, 190, 210]),
      _series('Eleventh', <double>[210, 230, 210, 230, 210, 230]),
      _series('Tweleth', <double>[230, 250, 230, 250, 230, 250]),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
          FluentSwitch(
            checked: _allowMultipleShapes,
            label: Text(
              _allowMultipleShapes
                  ? 'Enabled multiple shapes for each line'
                  : 'Disabled multiple shapes for each line',
            ),
            onChanged: (bool value) =>
                setState(() => _allowMultipleShapes = value),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            allowMultipleShapesForPoints: _allowMultipleShapes,
            legendSelectionMode: FluentChartLegendSelectionMode.multiple,
            colorFillBars: <FluentColorFillBar>[
              FluentColorFillBar(
                legend: 'Time range 1',
                color: FluentDataVizPalette.resolve(FluentDataVizToken.color19),
                data: <FluentColorFillBarRange>[
                  FluentColorFillBarRange(
                    startX: DateTime(2018, 1, 6),
                    endX: DateTime(2018, 1, 25),
                  ),
                ],
              ),
              FluentColorFillBar(
                legend: 'Time range 2',
                color: FluentDataVizPalette.resolve(FluentDataVizToken.color20),
                applyPattern: true,
                data: <FluentColorFillBarRange>[
                  FluentColorFillBarRange(
                    startX: DateTime(2018, 1, 18),
                    endX: DateTime(2018, 2, 20),
                  ),
                  FluentColorFillBarRange(
                    startX: DateTime(2018, 4, 17),
                    endX: DateTime(2018, 5, 10),
                  ),
                ],
              ),
            ],
            props: FluentCartesianChartProps(
              customDateTimeFormatter: _monthDay,
              useUTC: false,
              // Passing tick values is optional, for more control.
              // If you do not pass them the line chart will render them for you
              // based on D3's standard.
              tickValues: <Object>[
                DateTime(2018),
                DateTime(2018, 2),
                DateTime(2018, 3),
                DateTime(2018, 4),
                DateTime(2018, 5),
                DateTime(2018, 6),
                DateTime(2018, 7),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-multiple

// #docregion charts-linechart--line-chart-styled
Widget _lineChartStyled(BuildContext context) => const _LineChartStyled();

class _LineChartStyled extends StatefulWidget {
  const _LineChartStyled();

  @override
  State<_LineChartStyled> createState() => _LineChartStyledState();
}

class _LineChartStyledState extends State<_LineChartStyled> {
  double _width = 700;
  double _height = 300;

  static String _monthDay(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'first legend',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime(2018, 1, 6),
            y: 10,
            xAxisCalloutData: 'Appointment 1',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 1, 16),
            y: 18,
            xAxisCalloutData: 'Appointment 2',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 1, 20),
            y: 24,
            xAxisCalloutData: 'Appointment 3',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 1, 24),
            y: 35,
            xAxisCalloutData: 'Appointment 4',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 1, 26),
            y: 35,
            xAxisCalloutData: 'Appointment 5',
          ),
          FluentLineChartDataPoint(
            x: DateTime(2018, 1, 29),
            y: 90,
            xAxisCalloutData: 'Appointment 6',
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        lineOptions: const FluentLineOptions(
          strokeWidth: 4,
          lineBorderWidth: 4,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            props: FluentCartesianChartProps(
              yMaxValue: 90,
              showXAxisLablesTooltip: true,
              customDateTimeFormatter: _monthDay,
              tickValues: <Object>[
                DateTime.utc(2018),
                DateTime.utc(2018, 2, 9),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-styled

// #docregion charts-linechart--line-chart-custom-locale-date-axis
Widget _lineChartCustomLocaleDateAxis(BuildContext context) =>
    const _LineChartCustomLocaleDateAxis();

class _LineChartCustomLocaleDateAxis extends StatefulWidget {
  const _LineChartCustomLocaleDateAxis();

  @override
  State<_LineChartCustomLocaleDateAxis> createState() =>
      _LineChartCustomLocaleDateAxisState();
}

class _LineChartCustomLocaleDateAxisState
    extends State<_LineChartCustomLocaleDateAxis> {
  double _width = 700;
  double _height = 300;
  bool _allowMultipleShapes = false;

  // Upstream feeds d3-time-format's it-IT definition to `timeFormatLocale`.
  // That prop takes `d3.TimeLocaleDefinition`, which lives under
  // `src/charts/internal/d3/` and is deliberately not exported, so the same
  // Italian axis is produced with `customDateTimeFormatter` and the locale's
  // own abbreviated month names.
  static const List<String> _itShortMonths = <String>[
    'gen',
    'feb',
    'mar',
    'apr',
    'mag',
    'giu',
    'lug',
    'ago',
    'set',
    'ott',
    'nov',
    'dic',
  ];

  static String _itMonthYear(DateTime date) =>
      '${_itShortMonths[date.month - 1]} ${date.year}';

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3),
            y: 216000,
            onDataPointClick: () => debugPrint('click on 217000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 4, 3, 10),
            y: 218123,
            onDataPointClick: () => debugPrint('click on 217123'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 5, 5, 11),
            y: 217124,
            onDataPointClick: () => debugPrint('click on 217124'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 7, 14),
            y: 248000,
            onDataPointClick: () => debugPrint('click on 248000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 11, 15),
            y: 252000,
            onDataPointClick: () => debugPrint('click on 252000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 12, 6),
            y: 274000,
            onDataPointClick: () => debugPrint('click on 274000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2021, 1, 7),
            y: 260000,
            onDataPointClick: () => debugPrint('click on 260000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2021, 2, 14),
            y: 304000,
            onDataPointClick: () => debugPrint('click on 300000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2021, 3, 9),
            y: 218000,
            onDataPointClick: () => debugPrint('click on 218000'),
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        onLineClick: () => debugPrint('From_Legacy_to_O365'),
      ),
      FluentLineChartSeries(
        legend: 'All',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 297000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 4, 4), y: 284000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 5, 5), y: 282000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 6, 6), y: 294000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 9, 16), y: 224000),
          FluentLineChartDataPoint(x: DateTime.utc(2021, 2, 8), y: 300000),
          FluentLineChartDataPoint(x: DateTime.utc(2021, 3, 9), y: 298000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
          FluentSwitch(
            checked: _allowMultipleShapes,
            label: Text(
              _allowMultipleShapes
                  ? 'Enabled multiple shapes for each line'
                  : 'Disbaled multiple shapes for each line',
            ),
            onChanged: (bool value) =>
                setState(() => _allowMultipleShapes = value),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          // Upstream also passes `culture="rs-ss"`, a placeholder locale. Our
          // popover formats dates through package:intl, which throws for a
          // locale whose data was never initialised, so the culture is left at
          // the default and the Italian axis comes from the formatter below.
          child: FluentLineChart(
            data: _data,
            allowMultipleShapesForPoints: _allowMultipleShapes,
            props: const FluentCartesianChartProps(
              yMinValue: 200,
              yMaxValue: 301,
              xAxisTickCount: 10,
              margins: FluentChartMargins(
                left: 35,
                top: 20,
                bottom: 35,
                right: 20,
              ),
              customDateTimeFormatter: _itMonthYear,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-custom-locale-date-axis

// #docregion charts-linechart--line-chart-events
Widget _lineChartEvents(BuildContext context) => const _LineChartEvents();

class _LineChartEvents extends StatefulWidget {
  const _LineChartEvents();

  @override
  State<_LineChartEvents> createState() => _LineChartEventsState();
}

class _LineChartEventsState extends State<_LineChartEvents> {
  double _width = 700;
  double _height = 300;
  bool _allowMultipleShapes = false;

  static String _monthDay(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';

  /// d3's `format('$,')` — a dollar sign and comma-grouped thousands.
  static String _currency(double value) {
    final digits = value.round().abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}\$$grouped';
  }

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 297),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 284),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 282),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 294),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 294),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 300),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 298),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      ),
      FluentLineChartSeries(
        legend: 'All',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 292),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 287),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 287),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 292),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 287),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 297),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 292),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
          FluentSwitch(
            checked: _allowMultipleShapes,
            label: Text(
              _allowMultipleShapes
                  ? 'Enabled multiple shapes for each line'
                  : 'Disabled multiple shapes for each line',
            ),
            onChanged: (bool value) =>
                setState(() => _allowMultipleShapes = value),
          ),
        ],
      ),
      const SizedBox(height: 10),
      // Upstream pairs this label with an `<input type="color" id="color-select">`
      // whose value is never read — `customEventAnnotationColor` is a `const
      // undefined`, so both the rule colour and the label colour stay at their
      // theme defaults. FluentLineChart exposes no annotation-colour prop
      // either, so the label stands alone rather than driving a dead control.
      const FluentLabel(child: Text('Use Custom Color for Event Annotation')),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            allowMultipleShapesForPoints: _allowMultipleShapes,
            eventAnnotationMergedLabel: (int count) => '$count events',
            eventAnnotations: <FluentEventAnnotation>[
              FluentEventAnnotation(
                event: 'event 1',
                date: DateTime.utc(2020, 3, 4),
                cardBuilder: (BuildContext context) =>
                    const Text('event 1 message'),
              ),
              FluentEventAnnotation(
                event: 'event 2',
                date: DateTime.utc(2020, 3, 4),
                cardBuilder: (BuildContext context) =>
                    const Text('event 2 message'),
              ),
              FluentEventAnnotation(
                event: 'event 3',
                date: DateTime.utc(2020, 3, 4),
                cardBuilder: (BuildContext context) =>
                    const Text('event 3 message'),
              ),
              FluentEventAnnotation(
                event: 'event 4',
                date: DateTime.utc(2020, 3, 6),
                cardBuilder: (BuildContext context) =>
                    const Text('event 4 message'),
              ),
              FluentEventAnnotation(
                event: 'event 5',
                date: DateTime.utc(2020, 3, 8),
                cardBuilder: (BuildContext context) =>
                    const Text('event 5 message'),
              ),
            ],
            props: FluentCartesianChartProps(
              yMinValue: 282,
              yMaxValue: 301,
              yAxisTickFormat: _currency,
              customDateTimeFormatter: _monthDay,
              tickValues: <Object>[
                DateTime.utc(2020, 3, 3),
                DateTime.utc(2020, 3, 4),
                DateTime.utc(2020, 3, 5),
                DateTime.utc(2020, 3, 6),
                DateTime.utc(2020, 3, 7),
                DateTime.utc(2020, 3, 8),
                DateTime.utc(2020, 3, 9),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-events

// #docregion charts-linechart--line-chart-gaps
Widget _lineChartGaps(BuildContext context) => const _LineChartGaps();

class _LineChartGaps extends StatefulWidget {
  const _LineChartGaps();

  @override
  State<_LineChartGaps> createState() => _LineChartGapsState();
}

class _LineChartGapsState extends State<_LineChartGaps> {
  double _width = 700;
  double _height = 400;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'Confidence Level',
        legendShape: FluentChartLegendShape.dottedLine,
        hideInactiveDots: true,
        lineOptions: const FluentLineOptions(
          strokeDasharray: '5',
          strokeLinecap: StrokeCap.butt,
          strokeWidth: 2,
          lineBorderWidth: 4,
        ),
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3),
            y: 250000,
            hideCallout: true,
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 10),
            y: 250000,
            hideCallout: true,
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
      ),
      FluentLineChartSeries(
        legend: 'Normal Data',
        gaps: const <FluentLineChartGap>[
          FluentLineChartGap(startIndex: 3, endIndex: 4),
          FluentLineChartGap(startIndex: 6, endIndex: 7),
          FluentLineChartGap(startIndex: 1, endIndex: 2),
        ],
        hideInactiveDots: true,
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 216000),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 10, 30),
            y: 218123,
            hideCallout: true,
          ),
          // gap here
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 11),
            y: 219000,
            hideCallout: true,
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 4),
            y: 248000,
            hideCallout: true,
          ),
          // gap here
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 5),
            y: 252000,
            hideCallout: true,
          ),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 274000),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 7),
            y: 260000,
            hideCallout: true,
          ),
          // gap here
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 8),
            y: 300000,
            hideCallout: true,
          ),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8, 12), y: 218000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 218000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 10), y: 269000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
      ),
      FluentLineChartSeries(
        legend: 'Low Confidence Data*',
        legendShape: FluentChartLegendShape.dottedLine,
        hideInactiveDots: true,
        lineOptions: const FluentLineOptions(
          strokeDasharray: '2',
          strokeDashoffset: -1,
          strokeLinecap: StrokeCap.butt,
          lineBorderWidth: 4,
        ),
        gaps: const <FluentLineChartGap>[
          FluentLineChartGap(startIndex: 3, endIndex: 4),
          FluentLineChartGap(startIndex: 1, endIndex: 2),
        ],
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 10, 30),
            y: 218123,
          ),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3, 11), y: 219000),
          // gap here
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 248000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 252000),
          // gap here
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 260000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 300000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
      ),
      FluentLineChartSeries(
        legend: 'Green Data',
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 297000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 284000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 282000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 294000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 224000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 300000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 298000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 10), y: 299000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.success),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 500,
              max: 1500,
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
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          // Upstream's `getCalloutDescriptionMessage` appends
          // '* This data was below our confidence threshold.' to the callout
          // when the hovered stack contains 'Low Confidence Data*'. Our popover
          // takes a whole-body builder rather than a description hook, so the
          // note is dropped rather than faked.
          child: FluentLineChart(
            data: _data,
            props: const FluentCartesianChartProps(
              yMinValue: 150000,
              yMaxValue: 400000,
              margins: FluentChartMargins(
                left: 35,
                top: 20,
                bottom: 35,
                right: 20,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-gaps

// #docregion charts-linechart--line-chart-large-data
Widget _lineChartLargeData(BuildContext context) => const _LineChartLargeData();

class _LineChartLargeData extends StatefulWidget {
  const _LineChartLargeData();

  @override
  State<_LineChartLargeData> createState() => _LineChartLargeDataState();
}

class _LineChartLargeDataState extends State<_LineChartLargeData> {
  double _width = 700;
  double _height = 300;
  bool _allowMultipleShapes = false;

  static final DateTime _startDate = DateTime.utc(2020, 3);

  static List<FluentLineChartDataPoint> _getData() =>
      <FluentLineChartDataPoint>[
        for (var i = 0; i < 10000; i++)
          FluentLineChartDataPoint(
            x: _startDate.add(Duration(hours: i)),
            y: 500000,
          ),
      ];

  static List<FluentLineChartDataPoint> _getData2() =>
      <FluentLineChartDataPoint>[
        for (var i = 1000; i < 9000; i++)
          FluentLineChartDataPoint(
            x: _startDate.add(Duration(hours: i)),
            y: _getY(i),
          ),
      ];

  static double _getY(int i) {
    final newN = i % 1000;
    return newN < 500
        ? (newN * newN).toDouble()
        : (1000000 - newN * newN).toDouble();
  }

  // Built once rather than on every slider frame: 18000 points is a lot to
  // rebuild while dragging.
  late final FluentChartData _data = FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        data: _getData(),
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        onLineClick: () => debugPrint('From_Legacy_to_O365'),
        hideInactiveDots: true,
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      ),
      FluentLineChartSeries(
        legend: 'All',
        data: _getData2(),
        color: FluentDataVizPalette.resolve(FluentDataVizToken.success),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      ),
      FluentLineChartSeries(
        legend: 'single point',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 282000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
          FluentSwitch(
            checked: _allowMultipleShapes,
            label: Text(
              _allowMultipleShapes
                  ? 'Enabled multiple shapes for each line'
                  : 'Disabled multiple shapes for each line',
            ),
            onChanged: (bool value) =>
                setState(() => _allowMultipleShapes = value),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            culture: 'en-us',
            allowMultipleShapesForPoints: _allowMultipleShapes,
            optimizeLargeData: true,
            props: const FluentCartesianChartProps(
              yMinValue: 200,
              yMaxValue: 301,
              margins: FluentChartMargins(
                left: 35,
                top: 20,
                bottom: 35,
                right: 20,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-large-data

// #docregion charts-linechart--line-chart-negative
Widget _lineChartNegative(BuildContext context) => const _LineChartNegative();

class _LineChartNegative extends StatefulWidget {
  const _LineChartNegative();

  @override
  State<_LineChartNegative> createState() => _LineChartNegativeState();
}

class _LineChartNegativeState extends State<_LineChartNegative> {
  double _width = 700;
  double _height = 300;
  bool _allowMultipleShapes = false;
  bool _showAxisTitles = true;
  bool _useUtc = true;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3),
            y: -216000,
            onDataPointClick: () => debugPrint('click on 217000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 10),
            y: 218123,
            onDataPointClick: () => debugPrint('click on 217123'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 11),
            y: -217124,
            onDataPointClick: () => debugPrint('click on 217124'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 4),
            y: 248000,
            onDataPointClick: () => debugPrint('click on 248000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 5),
            y: -252000,
            onDataPointClick: () => debugPrint('click on 252000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 6),
            y: 274000,
            onDataPointClick: () => debugPrint('click on 274000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 7),
            y: -260000,
            onDataPointClick: () => debugPrint('click on 260000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 8),
            y: 304000,
            onDataPointClick: () => debugPrint('click on 300000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 9),
            y: -218000,
            onDataPointClick: () => debugPrint('click on 218000'),
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        onLineClick: () => debugPrint('From_Legacy_to_O365'),
      ),
      FluentLineChartSeries(
        legend: 'All',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 297000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: -284000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 282000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: -294000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 224000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: -300000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 298000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      ),
      FluentLineChartSeries(
        legend: 'single point',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5, 12), y: 232000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
          FluentSwitch(
            checked: _allowMultipleShapes,
            label: Text(
              _allowMultipleShapes
                  ? 'Enabled multiple shapes for each line On'
                  : 'Enabled multiple shapes for each line Off',
            ),
            onChanged: (bool value) =>
                setState(() => _allowMultipleShapes = value),
          ),
        ],
      ),
      const SizedBox(height: 10),
      FluentSwitch(
        checked: _showAxisTitles,
        label: Text(_showAxisTitles ? 'Show Axis titles' : 'Hide Axis titles'),
        onChanged: (bool value) => setState(() => _showAxisTitles = value),
      ),
      const SizedBox(height: 20),
      FluentCheckbox(
        checked: _useUtc,
        label: const Text('Use UTC time'),
        onChanged: (bool? value) => setState(() => _useUtc = value ?? false),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            culture: 'en-us',
            allowMultipleShapesForPoints: _allowMultipleShapes,
            props: FluentCartesianChartProps(
              yMinValue: 200,
              yMaxValue: 301,
              xAxisTickCount: 10,
              useUTC: _useUtc,
              yAxisTitle: _showAxisTitles
                  ? 'Different categories of mail flow'
                  : null,
              xAxisTitle: _showAxisTitles ? 'Values of each category' : null,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-negative

// #docregion charts-linechart--line-chart-all-negative
Widget _lineChartAllNegative(BuildContext context) =>
    const _LineChartAllNegative();

class _LineChartAllNegative extends StatefulWidget {
  const _LineChartAllNegative();

  @override
  State<_LineChartAllNegative> createState() => _LineChartAllNegativeState();
}

class _LineChartAllNegativeState extends State<_LineChartAllNegative> {
  double _width = 700;
  double _height = 300;
  bool _allowMultipleShapes = false;
  bool _showAxisTitles = true;
  bool _useUtc = true;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3),
            y: -216000,
            onDataPointClick: () => debugPrint('click on 217000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 10),
            y: -218123,
            onDataPointClick: () => debugPrint('click on 217123'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 3, 11),
            y: -217124,
            onDataPointClick: () => debugPrint('click on 217124'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 4),
            y: -248000,
            onDataPointClick: () => debugPrint('click on 248000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 5),
            y: -252000,
            onDataPointClick: () => debugPrint('click on 252000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 6),
            y: -274000,
            onDataPointClick: () => debugPrint('click on 274000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 7),
            y: -260000,
            onDataPointClick: () => debugPrint('click on 260000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 8),
            y: -304000,
            onDataPointClick: () => debugPrint('click on 300000'),
          ),
          FluentLineChartDataPoint(
            x: DateTime.utc(2020, 3, 9),
            y: -218000,
            onDataPointClick: () => debugPrint('click on 218000'),
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        onLineClick: () => debugPrint('From_Legacy_to_O365'),
      ),
      FluentLineChartSeries(
        legend: 'All',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: -297000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: -284000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: -282000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: -294000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: -224000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: -300000),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: -298000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      ),
      FluentLineChartSeries(
        legend: 'single point',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5, 12), y: -232000),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
          FluentSwitch(
            checked: _allowMultipleShapes,
            label: Text(
              _allowMultipleShapes
                  ? 'Enabled multiple shapes for each line On'
                  : 'Enabled multiple shapes for each line Off',
            ),
            onChanged: (bool value) =>
                setState(() => _allowMultipleShapes = value),
          ),
        ],
      ),
      const SizedBox(height: 10),
      FluentSwitch(
        checked: _showAxisTitles,
        label: Text(_showAxisTitles ? 'Show Axis titles' : 'Hide Axis titles'),
        onChanged: (bool value) => setState(() => _showAxisTitles = value),
      ),
      const SizedBox(height: 20),
      FluentCheckbox(
        checked: _useUtc,
        label: const Text('Use UTC time'),
        onChanged: (bool? value) => setState(() => _useUtc = value ?? false),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            culture: 'en-us',
            allowMultipleShapesForPoints: _allowMultipleShapes,
            props: FluentCartesianChartProps(
              yMinValue: 200,
              yMaxValue: 301,
              xAxisTickCount: 10,
              useUTC: _useUtc,
              yAxisTitle: _showAxisTitles
                  ? 'Different categories of mail flow'
                  : null,
              xAxisTitle: _showAxisTitles ? 'Values of each category' : null,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-all-negative

// #docregion charts-linechart--line-chart-secondary-y-axis
Widget _lineChartSecondaryYAxis(BuildContext context) =>
    const _LineChartSecondaryYAxis();

class _LineChartSecondaryYAxis extends StatefulWidget {
  const _LineChartSecondaryYAxis();

  @override
  State<_LineChartSecondaryYAxis> createState() =>
      _LineChartSecondaryYAxisState();
}

class _LineChartSecondaryYAxisState extends State<_LineChartSecondaryYAxis> {
  double _width = 700;
  double _height = 300;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 216),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3, 10), y: 218),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3, 11), y: 217),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 248),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: -252),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 274),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: -260),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 304),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 218),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      ),
      FluentLineChartSeries(
        legend: 'All',
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 297),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 284),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 282),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: -294),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 224),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: -300),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 298),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        useSecondaryYScale: true,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            props: const FluentCartesianChartProps(
              useUTC: true,
              secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-secondary-y-axis

// #docregion charts-linechart--line-chart-log-axis-example
Widget _lineChartLogAxisExample(BuildContext context) =>
    const _LineChartLogAxisExample();

class _LineChartLogAxisExample extends StatefulWidget {
  const _LineChartLogAxisExample();

  @override
  State<_LineChartLogAxisExample> createState() =>
      _LineChartLogAxisExampleState();
}

class _LineChartLogAxisExampleState extends State<_LineChartLogAxisExample> {
  double _width = 700;
  double _height = 300;
  String _xScaleType = 'log';
  String _yScaleType = 'log';

  static FluentAxisScaleType _scale(String value) =>
      value == 'log' ? FluentAxisScaleType.log : FluentAxisScaleType.auto;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'Series 1',
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 0, y: 8),
          FluentLineChartDataPoint(x: 1, y: 7),
          FluentLineChartDataPoint(x: 2, y: 6),
          FluentLineChartDataPoint(x: 3, y: 5),
          FluentLineChartDataPoint(x: 4, y: 4),
          FluentLineChartDataPoint(x: 5, y: 3),
          FluentLineChartDataPoint(x: 6, y: 2),
          FluentLineChartDataPoint(x: 7, y: 1),
          FluentLineChartDataPoint(x: 8, y: 0),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      ),
      FluentLineChartSeries(
        legend: 'Series 2',
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 0, y: 0),
          FluentLineChartDataPoint(x: 1, y: 1),
          FluentLineChartDataPoint(x: 2, y: 2),
          FluentLineChartDataPoint(x: 3, y: 3),
          FluentLineChartDataPoint(x: 4, y: 4),
          FluentLineChartDataPoint(x: 5, y: 5),
          FluentLineChartDataPoint(x: 6, y: 6),
          FluentLineChartDataPoint(x: 7, y: 7),
          FluentLineChartDataPoint(x: 8, y: 8),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.warning),
      ),
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
          Row(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 8),
              Text('${_width.round()}'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
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
              const SizedBox(width: 8),
              Text('${_height.round()}'),
            ],
          ),
        ],
      ),
      const SizedBox(height: 15),
      Wrap(
        spacing: 30,
        runSpacing: 15,
        children: <Widget>[
          FluentField(
            label: const Text('xScaleType'),
            child: FluentRadioGroup<String>(
              value: _xScaleType,
              onChanged: (String value) => setState(() => _xScaleType = value),
              children: const <Widget>[
                FluentRadio<String>(value: 'default', label: Text('default')),
                FluentRadio<String>(value: 'log', label: Text('log')),
              ],
            ),
          ),
          FluentField(
            label: const Text('yScaleType'),
            child: FluentRadioGroup<String>(
              value: _yScaleType,
              onChanged: (String value) => setState(() => _yScaleType = value),
              children: const <Widget>[
                FluentRadio<String>(value: 'default', label: Text('default')),
                FluentRadio<String>(value: 'log', label: Text('log')),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _data,
            props: FluentCartesianChartProps(
              xScaleType: _scale(_xScaleType),
              yScaleType: _scale(_yScaleType),
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-linechart--line-chart-log-axis-example

// #docregion charts-linechart--line-chart-annotations-example
Widget _lineChartAnnotationsExample(BuildContext context) =>
    const _LineChartAnnotationsExample();

class _LineChartAnnotationsExample extends StatefulWidget {
  const _LineChartAnnotationsExample();

  @override
  State<_LineChartAnnotationsExample> createState() =>
      _LineChartAnnotationsExampleState();
}

class _LineChartAnnotationsExampleState
    extends State<_LineChartAnnotationsExample> {
  double _width = 960;
  double _height = 520;

  static final Color _primaryColor = FluentDataVizPalette.resolve(
    FluentDataVizToken.color3,
  );
  static final Color _experimentColor = FluentDataVizPalette.resolve(
    FluentDataVizToken.color6,
  );
  static const Color _milestoneColor = Color(0xFFD83B01);

  FluentChartData get _chartData => FluentChartData(
    chartTitle: 'Weekly signups',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'Signups',
        color: _primaryColor,
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 0, y: 18),
          FluentLineChartDataPoint(x: 1, y: 26),
          FluentLineChartDataPoint(x: 2, y: 31),
          FluentLineChartDataPoint(x: 3, y: 37),
          FluentLineChartDataPoint(x: 4, y: 44),
          FluentLineChartDataPoint(x: 5, y: 51),
          FluentLineChartDataPoint(x: 6, y: 47),
        ],
      ),
    ],
  );

  // Upstream writes each annotation as an HTML fragment. Our annotation layer
  // understands only <b>, <i> and <br />, so <div>, <strong>, <span> and the
  // <ul>/<li> list become emphasis and line breaks; the words are unchanged.
  List<FluentChartAnnotation> get _annotations => <FluentChartAnnotation>[
    FluentChartAnnotation(
      id: 'launch-html',
      text: '<b>Launch day</b><br />+18% conversions',
      coordinates: const FluentDataCoordinate(x: 1, y: 26),
      layout: const FluentChartAnnotationLayout(
        align: FluentChartAnnotationAlign.start,
        verticalAlign: FluentChartAnnotationVerticalAlign.bottom,
        offsetX: 16,
        offsetY: -68,
        maxWidth: 220,
        clipToBounds: true,
      ),
      style: FluentChartAnnotationStyle(
        backgroundColor: const Color(0xFFFFFFFF),
        borderColor: _primaryColor,
        borderWidth: 1,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        fontWeight: FontWeight.w600,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.18),
            offset: Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      connector: FluentChartAnnotationConnector(
        strokeColor: _primaryColor,
        strokeWidth: 2,
        startPadding: 24,
        endPadding: 6,
      ),
    ),
    FluentChartAnnotation(
      id: 'experiment',
      text:
          '<b>Pricing experiment</b><br /><i>A/B test running</i><br />'
          'Variant B at 52%<br />Average order ↑',
      coordinates: const FluentDataCoordinate(x: 3, y: 37),
      layout: const FluentChartAnnotationLayout(
        offsetX: 132,
        offsetY: -12,
        maxWidth: 280,
        clipToBounds: false,
      ),
      style: FluentChartAnnotationStyle(
        backgroundColor: const Color(0xFFF4F9FF),
        borderColor: _experimentColor,
        borderWidth: 1,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.16),
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      connector: FluentChartAnnotationConnector(
        strokeColor: _experimentColor,
        strokeWidth: 2,
        startPadding: 18,
        endPadding: 4,
        dashArray: '5, 5',
      ),
    ),
    const FluentChartAnnotation(
      id: 'stretch-goal',
      text: 'Stretch goal<br /><b>5k signups</b>',
      coordinates: FluentRelativeCoordinate(x: 0.84, y: 0.34),
      layout: FluentChartAnnotationLayout(clipToBounds: false),
      style: FluentChartAnnotationStyle(
        backgroundColor: Color.fromRGBO(216, 59, 1, 0.08),
        borderColor: _milestoneColor,
        borderStyle: FluentChartAnnotationBorderStyle.dashed,
        borderWidth: 1,
        borderRadius: 8,
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        textColor: _milestoneColor,
        fontWeight: FontWeight.w600,
      ),
    ),
    const FluentChartAnnotation(
      id: 'offset-info',
      text: '<b>Note:</b> Values rounded to nearest whole signup.',
      coordinates: FluentPixelCoordinate(x: 24, y: 24),
      layout: FluentChartAnnotationLayout(
        align: FluentChartAnnotationAlign.start,
        verticalAlign: FluentChartAnnotationVerticalAlign.top,
        clipToBounds: false,
      ),
      style: FluentChartAnnotationStyle(
        backgroundColor: Color(0xFFFFFFFF),
        borderColor: Color(0xFFC7C7C7),
        borderWidth: 1,
        borderRadius: 6,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        fontSize: 12,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 15,
        runSpacing: 15,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('Change Width:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1500,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          Text('${_width.round()}'),
          const Text('Change Height:'),
          SizedBox(
            width: 120,
            child: FluentSlider(
              value: _height,
              min: 200,
              max: 1500,
              semanticLabel: 'Change Height',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
          Text('${_height.round()}'),
        ],
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentLineChart(
            data: _chartData,
            props: FluentCartesianChartProps(annotations: _annotations),
          ),
        ),
      ),
    ],
  );
}

// #enddocregion charts-linechart--line-chart-annotations-example
