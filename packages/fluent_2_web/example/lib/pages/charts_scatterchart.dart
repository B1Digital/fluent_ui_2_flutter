import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The ScatterChart docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage scatterChartPage = DocsPage(
  id: 'charts-scatterchart',
  title: 'ScatterChart',
  description:
      'A scatter (or bubble) chart is used to visualize relationships '
      'between two numerical variables, with data points plotted along '
      'the x and y axes. Bubble charts extend this by using the size of '
      'the markers to represent an additional variable, providing a '
      'third dimension of data visualization.',
  source: 'lib/pages/charts_scatterchart.dart',
  prose: <ProseBlock>[
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
      title: 'Do\'s',
      body:
          '1. **Use for Correlation Analysis**:\n'
          '- Scatter charts are ideal for identifying relationships or '
          'correlations between two numerical variables (e.g., sales '
          'vs. profit).\n',
    ),
    ProseBlock(
      title: 'Don\'ts',
      body:
          '1. **Limit Data Points**:\n'
          '- Avoid overcrowding the chart with too many data points, as '
          'it can make the visualization cluttered and hard to '
          'interpret.\n'
          '2. **Use Bubble Size Wisely**:\n'
          '- In bubble charts, ensure the size of the bubbles is '
          'proportional to the third variable and does not obscure '
          'other data points.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-scatterchart--scatter-chart-default',
      title: 'Scatter Chart Default',
      builder: _scatterChartDefault,
    ),
    DocsSection(
      id: 'charts-scatterchart--scatter-chart-date',
      title: 'Scatter Chart Date',
      builder: _scatterChartDate,
    ),
    DocsSection(
      id: 'charts-scatterchart--scatter-chart-string',
      title: 'Scatter Chart String',
      builder: _scatterChartString,
    ),
    DocsSection(
      id: 'charts-scatterchart--scatter-chart-log-axis-example',
      title: 'Scatter Chart Log Axis Example',
      builder: _scatterChartLogAxisExample,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'FluentChartData',
      description:
          'The data bundle. Only scatterChartData and chartTitle are read.',
    ),
    PropRow(
      name: 'props',
      type: 'FluentCartesianChartProps',
      defaultValue: 'FluentCartesianChartProps()',
      description: 'Shell configuration shared by every cartesian chart.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'BCP-47 locale used to format popover values.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentScatterChartStyle?',
      defaultValue: 'null',
      description: 'Style override, highest precedence.',
    ),
    PropRow(
      name: 'legendSelectionMode',
      type: 'FluentChartLegendSelectionMode',
      defaultValue: 'FluentChartLegendSelectionMode.single',
      description:
          'Whether the legend allows more than one selection at a time.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description:
          "The chart's single focus node. One node roves over the markers.",
    ),
  ],
);

// #docregion charts-scatterchart--scatter-chart-default
Widget _scatterChartDefault(BuildContext context) =>
    const _ScatterChartDefault();

class _ScatterChartDefault extends StatefulWidget {
  const _ScatterChartDefault();

  @override
  State<_ScatterChartDefault> createState() => _ScatterChartDefaultState();
}

class _ScatterChartDefaultState extends State<_ScatterChartDefault> {
  double _width = 650;
  double _height = 350;
  bool _selectMultipleLegends = false;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Project Revenue and Transactions Over Time',
    scatterChartData: <FluentScatterChartSeries>[
      FluentScatterChartSeries(
        legend: 'Phase 1',
        data: const <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: 10,
            y: 50000,
            markerSize: 12, // Number of transactions
          ),
          FluentScatterChartDataPoint(x: 20, y: 75000, markerSize: 15),
          FluentScatterChartDataPoint(x: 30, y: 90000, markerSize: 18),
          FluentScatterChartDataPoint(x: 40, y: 120000, markerSize: 22),
          FluentScatterChartDataPoint(x: 50, y: 150000, markerSize: 25),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      ),
      FluentScatterChartSeries(
        legend: 'Phase 2',
        data: const <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(x: 60, y: 180000, markerSize: 28),
          FluentScatterChartDataPoint(x: 70, y: 200000, markerSize: 30),
          FluentScatterChartDataPoint(x: 80, y: 220000, markerSize: 32),
          FluentScatterChartDataPoint(x: 90, y: 250000, markerSize: 35),
          FluentScatterChartDataPoint(x: 100, y: 300000, markerSize: 40),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
      ),
      FluentScatterChartSeries(
        legend: 'Milestone',
        data: const <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: 75,
            y: 250000,
            markerSize: 50, // Large number of transactions
          ),
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
      const Text('Scatter chart numeric x example.'),
      const SizedBox(height: 8),
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
      const SizedBox(height: 10),
      FluentSwitch(
        checked: _selectMultipleLegends,
        label: const Text('Select Multiple Legends'),
        onChanged: (bool value) =>
            setState(() => _selectMultipleLegends = value),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentScatterChart(
            data: _data,
            // Upstream reads `window.navigator.language`; a Flutter demo has no
            // navigator, so the library's own fallback locale stands in.
            culture: 'en-us',
            legendSelectionMode: _selectMultipleLegends
                ? FluentChartLegendSelectionMode.multiple
                : FluentChartLegendSelectionMode.single,
            props: const FluentCartesianChartProps(
              xAxisTitle: 'Days since project start',
              yAxisTitle: 'Revenue in dollars',
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-scatterchart--scatter-chart-default

// #docregion charts-scatterchart--scatter-chart-date
Widget _scatterChartDate(BuildContext context) => const _ScatterChartDate();

class _ScatterChartDate extends StatefulWidget {
  const _ScatterChartDate();

  @override
  State<_ScatterChartDate> createState() => _ScatterChartDateState();
}

class _ScatterChartDateState extends State<_ScatterChartDate> {
  double _width = 650;
  double _height = 350;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Website Traffic and Sales Performance',
    scatterChartData: <FluentScatterChartSeries>[
      FluentScatterChartSeries(
        legend: 'Website Traffic',
        data: <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 1),
            y: 5000, // Number of visitors
            markerSize: 15, // Number of transactions
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 2),
            y: 7000,
            markerSize: 20,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 3),
            y: 6500,
            markerSize: 18,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 4),
            y: 8000,
            markerSize: 25,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 5),
            y: 9000,
            markerSize: 30,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 6),
            y: 8500,
            markerSize: 28,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 7),
            y: 9500,
            markerSize: 35,
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      ),
      FluentScatterChartSeries(
        legend: 'Sales Performance',
        data: <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 1),
            y: 2000, // Revenue in dollars
            markerSize: 10, // Number of transactions
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 2),
            y: 3000,
            markerSize: 15,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 3),
            y: 2500,
            markerSize: 12,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 4),
            y: 4000,
            markerSize: 20,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 5),
            y: 4500,
            markerSize: 22,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 6),
            y: 4200,
            markerSize: 18,
          ),
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 7),
            y: 5000,
            markerSize: 25,
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
      ),
      FluentScatterChartSeries(
        legend: 'Promotional Campaign',
        data: <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: DateTime.utc(2023, 3, 5, 12),
            y: 6000, // Revenue spike due to promotion
            markerSize: 40, // Number of transactions
          ),
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
      const Text('Scatter chart date x example.'),
      const SizedBox(height: 8),
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
          child: FluentScatterChart(
            data: _data,
            // Upstream reads `window.navigator.language`; a Flutter demo has no
            // navigator, so the library's own fallback locale stands in.
            culture: 'en-us',
            props: const FluentCartesianChartProps(
              xAxisTitle: 'Date',
              yAxisTitle: 'Number of visitors',
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-scatterchart--scatter-chart-date

// #docregion charts-scatterchart--scatter-chart-string
Widget _scatterChartString(BuildContext context) => const _ScatterChartString();

class _ScatterChartString extends StatefulWidget {
  const _ScatterChartString();

  @override
  State<_ScatterChartString> createState() => _ScatterChartStringState();
}

class _ScatterChartStringState extends State<_ScatterChartString> {
  double _width = 650;
  double _height = 350;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Sales Performance by Category',
    scatterChartData: <FluentScatterChartSeries>[
      FluentScatterChartSeries(
        legend: 'Region 1',
        data: const <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: 'Electronics',
            y: 50000, // Revenue in dollars
            markerSize: 25, // Units sold
          ),
          FluentScatterChartDataPoint(x: 'Furniture', y: 30000, markerSize: 20),
          FluentScatterChartDataPoint(x: 'Clothing', y: 20000, markerSize: 15),
          FluentScatterChartDataPoint(x: 'Toys', y: 15000, markerSize: 10),
          FluentScatterChartDataPoint(x: 'Books', y: 10000, markerSize: 8),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      ),
      FluentScatterChartSeries(
        legend: 'Region 2',
        data: const <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: 'Electronics',
            y: 60000,
            markerSize: 30,
          ),
          FluentScatterChartDataPoint(x: 'Furniture', y: 25000, markerSize: 18),
          FluentScatterChartDataPoint(x: 'Clothing', y: 22000, markerSize: 16),
          FluentScatterChartDataPoint(x: 'Toys', y: 12000, markerSize: 12),
          FluentScatterChartDataPoint(x: 'Books', y: 8000, markerSize: 6),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const Text('Scatter chart string x example.'),
      const SizedBox(height: 8),
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
          child: FluentScatterChart(
            data: _data,
            // Upstream reads `window.navigator.language`; a Flutter demo has no
            // navigator, so the library's own fallback locale stands in.
            culture: 'en-us',
            props: const FluentCartesianChartProps(
              xAxisTitle: 'Product Category',
              yAxisTitle: 'Revenue in dollars',
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-scatterchart--scatter-chart-string

// #docregion charts-scatterchart--scatter-chart-log-axis-example
Widget _scatterChartLogAxisExample(BuildContext context) =>
    const _ScatterChartLogAxisExample();

class _ScatterChartLogAxisExample extends StatefulWidget {
  const _ScatterChartLogAxisExample();

  @override
  State<_ScatterChartLogAxisExample> createState() =>
      _ScatterChartLogAxisExampleState();
}

class _ScatterChartLogAxisExampleState
    extends State<_ScatterChartLogAxisExample> {
  double _width = 700;
  double _height = 300;
  String _xScaleType = 'log';
  String _yScaleType = 'log';

  static FluentAxisScaleType _scale(String value) =>
      value == 'log' ? FluentAxisScaleType.log : FluentAxisScaleType.auto;

  FluentChartData get _data => FluentChartData(
    chartTitle: 'Scatter Chart',
    scatterChartData: <FluentScatterChartSeries>[
      FluentScatterChartSeries(
        legend: 'Trace 1',
        legendShape: FluentChartLegendShape.circle,
        data: const <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: 1.2589254117941673,
            y: 2.4236435587418756,
            markerSize: 7,
          ),
          FluentScatterChartDataPoint(
            x: 2.39095514427051,
            y: 3.209069828287282,
            markerSize: 8,
          ),
          FluentScatterChartDataPoint(
            x: 4.540909610972476,
            y: 6.700279261114452,
            markerSize: 13,
          ),
          FluentScatterChartDataPoint(
            x: 8.624109968952766,
            y: 15.657933357041166,
            markerSize: 6,
          ),
          FluentScatterChartDataPoint(
            x: 16.378937069540648,
            y: 26.410125335101004,
            markerSize: 8,
          ),
          FluentScatterChartDataPoint(
            x: 31.10692935198609,
            y: 21.628233443544943,
            markerSize: 8,
          ),
          FluentScatterChartDataPoint(
            x: 59.078379115879464,
            y: 71.08357068207286,
            markerSize: 8,
          ),
          FluentScatterChartDataPoint(
            x: 112.20184543019641,
            y: 95.45928375106901,
            markerSize: 12,
          ),
          FluentScatterChartDataPoint(
            x: 213.09410153667977,
            y: 175.17899348200768,
            markerSize: 5,
          ),
          FluentScatterChartDataPoint(
            x: 404.70899507597613,
            y: 367.05817591616454,
            markerSize: 6,
          ),
          FluentScatterChartDataPoint(
            x: 768.6246100397738,
            y: 616.3133732775369,
            markerSize: 14,
          ),
          FluentScatterChartDataPoint(
            x: 1459.7743028861687,
            y: 1533.9498528438594,
            markerSize: 14,
          ),
          FluentScatterChartDataPoint(
            x: 2772.4079967417756,
            y: 2371.497871143982,
            markerSize: 5,
          ),
          FluentScatterChartDataPoint(
            x: 5265.366081044865,
            y: 3617.6579249480537,
            markerSize: 9,
          ),
          FluentScatterChartDataPoint(
            x: 10000,
            y: 7149.749744738273,
            markerSize: 12,
          ),
        ],
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      ),
      FluentScatterChartSeries(
        legend: 'Trace 2',
        legendShape: FluentChartLegendShape.circle,
        data: const <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(
            x: 3.1622776601683795,
            y: 2.1949926582336188,
            markerSize: 13,
          ),
          FluentScatterChartDataPoint(
            x: 6.1054022965853285,
            y: 4.772119103737707,
            markerSize: 16,
          ),
          FluentScatterChartDataPoint(
            x: 11.787686347935873,
            y: 5.594480133444149,
            markerSize: 17,
          ),
          FluentScatterChartDataPoint(
            x: 22.758459260747887,
            y: 22.975394675590913,
            markerSize: 21,
          ),
          FluentScatterChartDataPoint(
            x: 43.939705607607905,
            y: 14.632760823223153,
            markerSize: 24,
          ),
          FluentScatterChartDataPoint(
            x: 84.83428982440716,
            y: 49.97794497098575,
            markerSize: 12,
          ),
          FluentScatterChartDataPoint(
            x: 163.78937069540646,
            y: 88.37494969641493,
            markerSize: 21,
          ),
          FluentScatterChartDataPoint(
            x: 316.22776601683796,
            y: 259.59923251477073,
            markerSize: 10,
          ),
          FluentScatterChartDataPoint(
            x: 610.5402296585327,
            y: 486.6059651967493,
            markerSize: 24,
          ),
          FluentScatterChartDataPoint(
            x: 1178.7686347935867,
            y: 671.2364692543704,
            markerSize: 13,
          ),
          FluentScatterChartDataPoint(
            x: 2275.8459260747863,
            y: 1356.3898150565117,
            markerSize: 15,
          ),
          FluentScatterChartDataPoint(
            x: 4393.97056076079,
            y: 1697.3956575634736,
            markerSize: 22,
          ),
          FluentScatterChartDataPoint(
            x: 8483.428982440717,
            y: 1782.902150290326,
            markerSize: 19,
          ),
          FluentScatterChartDataPoint(
            x: 16378.937069540612,
            y: 7474.040318615067,
            markerSize: 20,
          ),
          FluentScatterChartDataPoint(
            x: 31622.776601683792,
            y: 16592.321174954774,
            markerSize: 14,
          ),
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
          child: FluentScatterChart(
            data: _data,
            props: FluentCartesianChartProps(
              hideTickOverlap: true,
              xScaleType: _scale(_xScaleType),
              yScaleType: _scale(_yScaleType),
            ),
          ),
        ),
      ),
    ],
  );
}

// #enddocregion charts-scatterchart--scatter-chart-log-axis-example
