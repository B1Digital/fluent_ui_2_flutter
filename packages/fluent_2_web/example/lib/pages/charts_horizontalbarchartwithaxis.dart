import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The HorizontalBarChartWithAxis docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Every demo is
/// delimited by a `#docregion` whose id is the section id, so the "Show code"
/// panel prints exactly the code that rendered.
///
/// Upstream's `getColorFromToken(DataVizPalette.colorN)` is
/// `FluentDataVizPalette.resolve(FluentDataVizToken.colorN)` here, and the
/// `width`/`height` numbers each story feeds the React chart become a
/// [SizedBox] inside a horizontal [SingleChildScrollView], because the sliders
/// reach 1000 and the docs column is narrower than that.
const DocsPage horizontalBarChartWithAxisPage = DocsPage(
  id: 'charts-horizontalbarchartwithaxis',
  title: 'HorizontalBarChartWithAxis',
  description:
      'A horizontal bar chart is a chart that presents categorical data '
      'with rectangular bars with lengths proportional to the values '
      'they represent. This type of chart is particularly useful when '
      'the intention is to show comparisons among various categories '
      'and the labels for those categories are long. Horizontal bar '
      'chart with axis is a version of horizontal bar chart that has '
      'the x and y axis present. This chart is same as the vertical bar '
      'chart except that the bars are aligned horizontally.',
  source: 'lib/pages/charts_horizontalbarchartwithaxis.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'The default bar height is 16px. For dense data, it can be as '
          'thin as 8px high. Always consider the visual weight of the '
          'bars in relationship to the rest of the app before choosing '
          'this type of chart.\n'
          'The padding around the bar chart is a default of 8px from '
          'the x and y-axis container. This gives enough room for '
          'additional content like label values to display properly '
          'without overlapping on to the Y-axis ticks. A 2:1 spacing is '
          'maintained between all the bars in the graph so that space '
          'between two bars is always two times the bar height. This '
          'helps to ensure that the graph is not overpowering other '
          'data visualizations. For charts that display monetary '
          'values, the dollar symbol should be displayed as part of the '
          'total value. Also call out the currency in the chart title '
          'to provide additional context. Chart title can be used to '
          'communicate currency when the total labels are hidden.\n'
          'The chart can accommodate unusually long labels by shrinking '
          'the bars without distorting the visual layout.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- **Bar segment** Bar segments make up a bar chart. Standard '
          'size options are: 8px, 16px, and 24px with 16px being the '
          'default.\n'
          '- **Value labels** (Optional) - Off by default with the '
          'option to toggle on in case the data visualization needs to '
          'communicate label values to users.\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          '- Bar graphs should be flexible to their containers. They '
          'will change width and height to fit their environment.\n'
          '- Type truncation should happen when the total value exceeds '
          'one thousand including 1 decimal place for the hundreds. For '
          'example, display full value for 600, 983, or 19.53. Truncate '
          '6,000 to 6.0K, 9,801 to 9.8K, and 100,900 to 100.9K.\n'
          '- All the bars of the graph are accessible by screen readers '
          'and keyboard navigation using Up and Down arrow keys.\n',
    ),
    ProseBlock(
      title: 'Customizing the chart',
      body:
          'The chart provides an option to select a color scale based '
          'on the range of x values. Similar x values will end up '
          'having similar color. Use the colors attribute to define the '
          'color scale.\n'
          'Use `useSingleColor` to use a single color for all bars.\n'
          'See `onRenderCalloutPerHorizontalBar` prop to customize the '
          'hover callout.\n'
          'If the y data points are of string type there are 2 modes to '
          'view them\n'
          '1. truncate yaxis labels using `showYAxisLablesTooltip`\n'
          '2. shrink the x axis and display the complete labels using '
          '`expandYAxisLabels` property.\n',
    ),
    ProseBlock(
      title: 'Do\'s',
      body:
          '- Try to keep the number of bars in the chart between 3 and '
          '20 to maximize readability.\n'
          '- Use this chart if the bar labels are very long.\n',
    ),
    ProseBlock(
      title: 'Dont\'s',
      body:
          '- Don\'t keep the bar values in random order. Horizontal bar '
          'chart is most effective if the bars are sorted in either '
          'ascending or descending order.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic',
      title: 'Horizontal Bar With Axis Basic',
      builder: _horizontalBarWithAxisBasic,
    ),
    DocsSection(
      id:
          'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-string-'
          'axis-tooltip',
      title: 'Horizontal Bar With Axis String Axis Tooltip',
      builder: _horizontalBarWithAxisStringAxisTooltip,
    ),
    DocsSection(
      id: 'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-dynamic',
      title: 'Horizontal Bar With Axis Dynamic',
      builder: _horizontalBarWithAxisDynamic,
    ),
    DocsSection(
      id:
          'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-'
          'negative',
      title: 'Horizontal Bar With Axis Negative',
      builder: _horizontalBarWithAxisNegative,
    ),
    DocsSection(
      id:
          'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-'
          'category-order',
      title: 'Horizontal Bar With Axis Category Order',
      builder: _horizontalBarWithAxisCategoryOrder,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentHorizontalBarChartWithAxisDataPoint>',
      description: 'The data points, in author order.',
    ),
    PropRow(
      name: 'props',
      type: 'FluentCartesianChartProps',
      defaultValue: 'FluentCartesianChartProps()',
      description:
          'Shell configuration: axes, legend, tooltip, margins and titles.',
    ),
    PropRow(
      name: 'barHeight',
      type: 'double?',
      defaultValue: 'null',
      description: 'Explicit bar height, overriding the auto solve.',
    ),
    PropRow(
      name: 'maxBarHeight',
      type: 'double?',
      defaultValue: 'null',
      description: 'Ceiling on the auto bar height.',
    ),
    PropRow(
      name: 'colors',
      type: 'List<Color>?',
      defaultValue: 'null',
      description: 'A caller-supplied ramp.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description: 'Human title, folded into the accessible description.',
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
      name: 'yAxisPadding',
      type: 'double',
      defaultValue: '0.5',
      description: "Band padding between the chart's bars.",
    ),
    PropRow(
      name: 'roundCorners',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether bars get a 3px corner radius.',
    ),
    PropRow(
      name: 'hideLabels',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether group total labels are suppressed.',
    ),
    PropRow(
      name: 'yAxisCategoryOrder',
      type: 'FluentAxisCategoryOrder?',
      defaultValue: 'null',
      description:
          'Ordering applied to a category y axis, or null when the caller '
          'named none.',
    ),
    PropRow(
      name: 'legendSelectionMode',
      type: 'FluentChartLegendSelectionMode',
      defaultValue: 'FluentChartLegendSelectionMode.single',
      description: 'Whether the legend allows more than one selection.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentHorizontalBarChartWithAxisStyle?',
      defaultValue: 'null',
      description: 'Style override, highest precedence.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description: "The chart's single focus node.",
    ),
  ],
);

// #docregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic
Widget _horizontalBarWithAxisBasic(BuildContext context) =>
    const _HorizontalBarWithAxisBasic();

class _HorizontalBarWithAxisBasic extends StatefulWidget {
  const _HorizontalBarWithAxisBasic();

  @override
  State<_HorizontalBarWithAxisBasic> createState() =>
      _HorizontalBarWithAxisBasicState();
}

class _HorizontalBarWithAxisBasicState
    extends State<_HorizontalBarWithAxisBasic> {
  static final List<FluentHorizontalBarChartWithAxisDataPoint> _points =
      <FluentHorizontalBarChartWithAxisDataPoint>[
        FluentHorizontalBarChartWithAxisDataPoint(
          x: 10000,
          y: 5000,
          legend: 'Oranges',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          yAxisCalloutData: '2020/04/30',
          xAxisCalloutData: '10%',
        ),
        FluentHorizontalBarChartWithAxisDataPoint(
          x: 20000,
          y: 50000,
          legend: 'Dogs',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          yAxisCalloutData: '2020/04/30',
          xAxisCalloutData: '20%',
        ),
        FluentHorizontalBarChartWithAxisDataPoint(
          x: 25000,
          y: 30000,
          legend: 'Apples',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          yAxisCalloutData: '2020/04/30',
          xAxisCalloutData: '37%',
        ),
        FluentHorizontalBarChartWithAxisDataPoint(
          x: 40000,
          y: 13000,
          legend: 'Bananas',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          yAxisCalloutData: '2020/04/30',
          xAxisCalloutData: '88%',
        ),
      ];

  double _width = 650;
  double _height = 350;
  String? _calloutExample;
  bool _useSingleColor = false;
  bool _enableGradient = false;
  bool _roundCorners = false;
  bool _selectMultipleLegends = false;

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
      // Upstream's radio pair would swap in `onRenderCalloutPerHorizontalBar`,
      // but the story's handler only flips a boolean nothing reads, so neither
      // choice changes the chart. The port keeps the control and the same
      // inert behaviour.
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
      Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          // `enableGradient` has no counterpart on the Flutter chart, which
          // fills every bar flat. The switch stays so the story's controls are
          // complete, and it is honestly inert.
          FluentSwitch(
            checked: _enableGradient,
            onChanged: (bool value) => setState(() => _enableGradient = value),
            label: Text(
              _enableGradient ? 'Enable Gradient ON' : 'Enable Gradient OFF',
            ),
          ),
          FluentSwitch(
            checked: _roundCorners,
            onChanged: (bool value) => setState(() => _roundCorners = value),
            label: Text(
              _roundCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
            ),
          ),
          FluentSwitch(
            checked: _selectMultipleLegends,
            onChanged: (bool value) =>
                setState(() => _selectMultipleLegends = value),
            label: Text(
              _selectMultipleLegends
                  ? 'Select multiple legends ON'
                  : 'Select multiple legends OFF',
            ),
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentHorizontalBarChartWithAxis(
            culture: 'en-us',
            chartTitle: 'Horizontal bar chart basic example ',
            data: _points,
            useSingleColor: _useSingleColor,
            roundCorners: _roundCorners,
            legendSelectionMode: _selectMultipleLegends
                ? FluentChartLegendSelectionMode.multiple
                : FluentChartLegendSelectionMode.single,
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic

// #docregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-string-axis-tooltip
Widget _horizontalBarWithAxisStringAxisTooltip(BuildContext context) =>
    const _HorizontalBarWithAxisStringAxisTooltip();

class _HorizontalBarWithAxisStringAxisTooltip extends StatefulWidget {
  const _HorizontalBarWithAxisStringAxisTooltip();

  @override
  State<_HorizontalBarWithAxisStringAxisTooltip> createState() =>
      _HorizontalBarWithAxisStringAxisTooltipState();
}

class _HorizontalBarWithAxisStringAxisTooltipState
    extends State<_HorizontalBarWithAxisStringAxisTooltip> {
  static final List<FluentHorizontalBarChartWithAxisDataPoint> _points =
      <FluentHorizontalBarChartWithAxisDataPoint>[
        FluentHorizontalBarChartWithAxisDataPoint(
          y: 'String One',
          x: 1000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        ),
        FluentHorizontalBarChartWithAxisDataPoint(
          y: 'String Two',
          x: 5000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        ),
        FluentHorizontalBarChartWithAxisDataPoint(
          y: 'String Three',
          x: 3000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        ),
        FluentHorizontalBarChartWithAxisDataPoint(
          y: 'String Four',
          x: 2000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        ),
      ];

  String _selectedCallout = 'showTooltip';
  bool _enableGradient = false;
  bool _roundCorners = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _selectedCallout,
          onChanged: (String value) => setState(() => _selectedCallout = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'expandYAxisLabels',
              label: Text('Expand Y Axis Ticks'),
            ),
            FluentRadio<String>(
              value: 'showTooltip',
              label: Text('Show Tooltip at Y Axis Ticks'),
            ),
          ],
        ),
      ),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          // `enableGradient` has no counterpart on the Flutter chart, which
          // fills every bar flat. The switch stays so the story's controls are
          // complete, and it is honestly inert.
          FluentSwitch(
            checked: _enableGradient,
            onChanged: (bool value) => setState(() => _enableGradient = value),
            label: Text(
              _enableGradient ? 'Enable Gradient ON' : 'Enable Gradient OFF',
            ),
          ),
          FluentSwitch(
            checked: _roundCorners,
            onChanged: (bool value) => setState(() => _roundCorners = value),
            label: Text(
              _roundCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
            ),
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 650,
          height: 350,
          child: FluentHorizontalBarChartWithAxis(
            chartTitle: 'Horizontal bar chart axis tooltip example ',
            data: _points,
            roundCorners: _roundCorners,
            props: FluentCartesianChartProps(
              hideLegend: true,
              showYAxisLablesTooltip: _selectedCallout == 'showTooltip',
              showYAxisLables: _selectedCallout == 'expandYAxisLabels',
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-string-axis-tooltip

// #docregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-dynamic
Widget _horizontalBarWithAxisDynamic(BuildContext context) =>
    const _HorizontalBarWithAxisDynamic();

class _HorizontalBarWithAxisDynamic extends StatefulWidget {
  const _HorizontalBarWithAxisDynamic();

  @override
  State<_HorizontalBarWithAxisDynamic> createState() =>
      _HorizontalBarWithAxisDynamicState();
}

class _HorizontalBarWithAxisDynamicState
    extends State<_HorizontalBarWithAxisDynamic> {
  static const String _initialYAxisType = 'number';
  static const int _initialDataSize = 5;

  static final List<Color> _colors = <Color>[
    FluentDataVizPalette.resolve(FluentDataVizToken.color1),
    FluentDataVizPalette.resolve(FluentDataVizToken.color2),
    FluentDataVizPalette.resolve(FluentDataVizToken.color3),
  ];

  // `dart:math` is outside this example's import budget, so upstream's
  // `Math.random()` becomes a MINSTD generator. Its multiplier keeps every
  // product under 2^53, which is what makes it safe on the web where a Dart
  // `int` is a double. Deterministic, which suits a docs page anyway.
  int _seed = 42;

  double _random() {
    _seed = _seed * 16807 % 2147483647;
    return _seed / 2147483647;
  }

  late List<FluentHorizontalBarChartWithAxisDataPoint> _dynamicData = _getData(
    _initialDataSize,
    _initialYAxisType,
  );
  double _width = 650;
  double _dataSize = _initialDataSize.toDouble();
  String _yAxisType = _initialYAxisType;
  bool _roundCorners = false;
  double _yAxisPadding = 0;
  bool _yAxisPaddingEnabled = false;
  String _statusMessage = '';

  double _randomX() => (_random() * 90).floorToDouble() + 1;

  List<FluentHorizontalBarChartWithAxisDataPoint> _getData(
    int dataSize,
    String yAxisType,
  ) {
    final List<FluentHorizontalBarChartWithAxisDataPoint> data =
        <FluentHorizontalBarChartWithAxisDataPoint>[];
    if (yAxisType == 'string') {
      for (int i = 0; i < dataSize; i++) {
        data.add(
          FluentHorizontalBarChartWithAxisDataPoint(
            x: _randomX(),
            y: 'Label ${i + 1}',
            legend: 'Label ${i + 1}',
            color: _colors[i % _colors.length],
          ),
        );
      }
    } else {
      final Set<int> yPoints = <int>{};
      while (yPoints.length != dataSize) {
        final int y = (_random() * 75).floor() + 1;
        if (yPoints.add(y)) {
          data.add(
            FluentHorizontalBarChartWithAxisDataPoint(
              x: _randomX(),
              y: y,
              legend: 'Label ${yPoints.length}',
              color: _colors[y % _colors.length],
            ),
          );
        }
      }
    }
    return data;
  }

  void _changeData() => setState(() {
    _dynamicData = _getData(_dataSize.round(), _yAxisType);
    _statusMessage = 'Horizontal bar chart with Axis data changed';
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: <Widget>[
      Wrap(
        spacing: 30,
        runSpacing: 15,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('width: '),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              semanticLabel: 'Change Width',
              onChanged: (double value) => setState(() => _width = value),
            ),
          ),
          const Text('Data Size: '),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _dataSize,
              max: 50,
              step: 1,
              semanticLabel: 'Change Data Size',
              onChanged: (double value) => setState(() {
                _dataSize = value;
                _dynamicData = _getData(value.round(), _yAxisType);
              }),
            ),
          ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          // Upstream labels this checkbox "yAxisPadding:&nbsp;".
          FluentCheckbox(
            checked: _yAxisPaddingEnabled,
            onChanged: _yAxisType == 'string'
                ? (bool? value) =>
                      setState(() => _yAxisPaddingEnabled = value ?? false)
                : null,
            label: const Text('yAxisPadding: '),
          ),
          SizedBox(
            width: 160,
            child: FluentSlider(
              value: _yAxisPadding,
              max: 1,
              step: 0.1,
              semanticLabel: 'yAxisPadding',
              onChanged: _yAxisPaddingEnabled
                  ? (double value) => setState(() => _yAxisPadding = value)
                  : null,
            ),
          ),
          Text(_yAxisPadding.toStringAsFixed(1)),
        ],
      ),
      Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('X-Axis type:'),
              FluentField(
                label: const Text('Pick one'),
                child: FluentRadioGroup<String>(
                  value: _yAxisType,
                  onChanged: (String value) => setState(() {
                    _yAxisType = value;
                    _dynamicData = _getData(_dataSize.round(), value);
                  }),
                  children: const <Widget>[
                    FluentRadio<String>(value: 'number', label: Text('Number')),
                    FluentRadio<String>(value: 'string', label: Text('String')),
                  ],
                ),
              ),
            ],
          ),
          FluentSwitch(
            checked: _roundCorners,
            onChanged: (bool value) => setState(() => _roundCorners = value),
            label: Text(
              _roundCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
            ),
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: 350,
          child: FluentHorizontalBarChartWithAxis(
            chartTitle: 'Horizontal bar chart dynamic example',
            data: _dynamicData,
            colors: _colors,
            roundCorners: _roundCorners,
            // Upstream passes `undefined` while the checkbox is clear, which
            // lands on the same 0.5 this default carries.
            yAxisPadding: _yAxisPaddingEnabled ? _yAxisPadding : 0.5,
            props: const FluentCartesianChartProps(hideLegend: true),
          ),
        ),
      ),
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
// #enddocregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-dynamic

// #docregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-negative
Widget _horizontalBarWithAxisNegative(BuildContext context) =>
    const _HorizontalBarWithAxisNegative();

class _HorizontalBarWithAxisNegative extends StatefulWidget {
  const _HorizontalBarWithAxisNegative();

  @override
  State<_HorizontalBarWithAxisNegative> createState() =>
      _HorizontalBarWithAxisNegativeState();
}

class _HorizontalBarWithAxisNegativeState
    extends State<_HorizontalBarWithAxisNegative> {
  static const List<String> _categories = <String>['A', 'B', 'C', 'D', 'E'];
  static const List<String> _series = <String>[
    'Series 1',
    'Series 2',
    'Series 3',
    'Series 4',
  ];

  static final List<Color> _colors = <Color>[
    FluentDataVizPalette.resolve(FluentDataVizToken.color1),
    FluentDataVizPalette.resolve(FluentDataVizToken.color2),
    FluentDataVizPalette.resolve(FluentDataVizToken.color3),
    FluentDataVizPalette.resolve(FluentDataVizToken.color4),
  ];

  static const List<double> _negativeData1 = <double>[-10, -20, -30, -40, -50];
  static const List<double> _positiveData1 = <double>[10, 20, 30, 40, 50];
  static const List<double> _positiveData2 = <double>[20, 30, 40, 50, 60];
  static const List<double> _negativeData2 = <double>[-20, -30, -40, -50, -60];
  static const List<double> _positiveData3 = <double>[30, 40, 50, 60, 70];
  static const List<double> _negativeData3 = <double>[-30, -40, -50, -60, -70];
  static const List<double> _positiveData4 = <double>[40, 50, 60, 70, 80];
  static const List<double> _negativeData4 = <double>[-40, -50, -60, -70, -80];

  static List<FluentHorizontalBarChartWithAxisDataPoint> _seriesPoints(
    List<double> values,
    int seriesIndex,
  ) => <FluentHorizontalBarChartWithAxisDataPoint>[
    for (int i = 0; i < _categories.length; i++)
      FluentHorizontalBarChartWithAxisDataPoint(
        x: values[i],
        y: _categories[i],
        legend: _series[seriesIndex],
        color: _colors[seriesIndex],
        yAxisCalloutData: '2020/04/30',
        xAxisCalloutData: '10%',
      ),
  ];

  static final List<FluentHorizontalBarChartWithAxisDataPoint> _points =
      <FluentHorizontalBarChartWithAxisDataPoint>[
        ..._seriesPoints(_positiveData1, 0),
        ..._seriesPoints(_negativeData1, 0),
        ..._seriesPoints(_positiveData2, 1),
        ..._seriesPoints(_negativeData2, 1),
        ..._seriesPoints(_positiveData3, 2),
        ..._seriesPoints(_negativeData3, 2),
        ..._seriesPoints(_positiveData4, 3),
        ..._seriesPoints(_negativeData4, 3),
      ];

  String _selectedCallout = 'showTooltip';
  bool _enableGradient = false;
  bool _roundCorners = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: <Widget>[
      FluentField(
        label: const Text('Pick one'),
        child: FluentRadioGroup<String>(
          value: _selectedCallout,
          onChanged: (String value) => setState(() => _selectedCallout = value),
          children: const <Widget>[
            FluentRadio<String>(
              value: 'expandYAxisLabels',
              label: Text('Expand Y Axis Ticks'),
            ),
            FluentRadio<String>(
              value: 'showTooltip',
              label: Text('Show Tooltip at Y Axis Ticks'),
            ),
          ],
        ),
      ),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          // `enableGradient` has no counterpart on the Flutter chart, which
          // fills every bar flat. The switch stays so the story's controls are
          // complete, and it is honestly inert.
          FluentSwitch(
            checked: _enableGradient,
            onChanged: (bool value) => setState(() => _enableGradient = value),
            label: Text(
              _enableGradient ? 'Enable Gradient ON' : 'Enable Gradient OFF',
            ),
          ),
          FluentSwitch(
            checked: _roundCorners,
            onChanged: (bool value) => setState(() => _roundCorners = value),
            label: Text(
              _roundCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
            ),
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 650,
          height: 350,
          child: FluentHorizontalBarChartWithAxis(
            chartTitle: 'Horizontal bar chart axis tooltip example ',
            data: _points,
            roundCorners: _roundCorners,
            props: FluentCartesianChartProps(
              hideLegend: true,
              showYAxisLablesTooltip: _selectedCallout == 'showTooltip',
              showYAxisLables: _selectedCallout == 'expandYAxisLabels',
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-negative

// #docregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-category-order
Widget _horizontalBarWithAxisCategoryOrder(BuildContext context) =>
    const _HorizontalBarWithAxisCategoryOrder();

class _HorizontalBarWithAxisCategoryOrder extends StatefulWidget {
  const _HorizontalBarWithAxisCategoryOrder();

  @override
  State<_HorizontalBarWithAxisCategoryOrder> createState() =>
      _HorizontalBarWithAxisCategoryOrderState();
}

class _HorizontalBarWithAxisCategoryOrderState
    extends State<_HorizontalBarWithAxisCategoryOrder> {
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

  static final List<Color> _colors = <Color>[
    FluentDataVizPalette.resolve(FluentDataVizToken.color1),
    FluentDataVizPalette.resolve(FluentDataVizToken.color2),
    FluentDataVizPalette.resolve(FluentDataVizToken.color3),
    FluentDataVizPalette.resolve(FluentDataVizToken.color4),
    FluentDataVizPalette.resolve(FluentDataVizToken.color5),
  ];

  // `dart:math` is outside this example's import budget, so upstream's
  // `Math.random()` becomes a MINSTD generator. Its multiplier keeps every
  // product under 2^53, which is what makes it safe on the web where a Dart
  // `int` is a double. "Change data" advances the stream exactly as upstream's
  // button does.
  int _seed = 42;

  double _random() {
    _seed = _seed * 16807 % 2147483647;
    return _seed / 2147483647;
  }

  late List<FluentHorizontalBarChartWithAxisDataPoint> _dynamicData = _getData(
    _initialDataSize,
  );
  double _width = 650;
  double _height = 350;
  double _dataSize = _initialDataSize.toDouble();
  String _yAxisCategoryOrder = 'default';
  String _statusMessage = '';

  List<FluentHorizontalBarChartWithAxisDataPoint> _getData(int dataSize) {
    final List<FluentHorizontalBarChartWithAxisDataPoint> data =
        <FluentHorizontalBarChartWithAxisDataPoint>[];
    for (int i = 0; i < dataSize; i++) {
      final double x = (_random() * 200).floorToDouble() - 100;
      final int yIdx = (_random() * i).floor();
      final int legendIdx = (_random() * i).floor();
      data.add(
        FluentHorizontalBarChartWithAxisDataPoint(
          x: x,
          y: 'Label ${yIdx + 1}',
          legend: 'Legend ${legendIdx + 1}',
          color: _colors[legendIdx % _colors.length],
        ),
      );
    }
    return data;
  }

  void _changeData() => setState(() {
    _dynamicData = _getData(_dataSize.round());
    _statusMessage = 'Horizontal bar chart with Axis data changed';
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
    spacing: 8,
    children: <Widget>[
      Text(label),
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
      Text('${value.round()}'),
    ],
  );

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
          _slider(
            'Width: ',
            'Change Width',
            _width,
            200,
            1000,
            (double value) => setState(() => _width = value),
          ),
          _slider(
            'Height: ',
            'Change Height',
            _height,
            200,
            1000,
            (double value) => setState(() => _height = value),
          ),
          _slider(
            'Data Size: ',
            'Change Data Size',
            _dataSize,
            0,
            50,
            (double value) => setState(() {
              _dataSize = value;
              _dynamicData = _getData(value.round());
            }),
          ),
          FluentField(
            label: const Text('yAxisCategoryOrder:'),
            child: SizedBox(
              width: 220,
              child: FluentDropdown<String>(
                value: _yAxisCategoryOrder,
                options: <FluentDropdownOption<String>>[
                  for (final String option in _axisCategoryOrderOptions)
                    FluentDropdownOption<String>(
                      value: option,
                      label: Text(option),
                    ),
                ],
                onChanged: (String value) =>
                    setState(() => _yAxisCategoryOrder = value),
              ),
            ),
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentHorizontalBarChartWithAxis(
            data: _dynamicData,
            colors: _colors,
            yAxisCategoryOrder: FluentAxisCategoryOrder.parse(
              _yAxisCategoryOrder,
            ),
            props: const FluentCartesianChartProps(
              hideLegend: true,
              showYAxisLables: true,
            ),
          ),
        ),
      ),
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

// #enddocregion charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-category-order
