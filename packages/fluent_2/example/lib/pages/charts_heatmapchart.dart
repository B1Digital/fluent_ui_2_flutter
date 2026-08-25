import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The HeatMapChart docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage heatMapChartPage = DocsPage(
  id: 'charts-heatmapchart',
  title: 'HeatMapChart',
  description:
      'A heatmap is a 2D visualization that uses color to represent '
      'magnitude or intensity of values in the dataset. Generally, the '
      'color uses a sequential palette and corresponds to the value’s '
      'relative position within the represented ranges. This generally '
      'means larger values have darker colors.',
  source: 'lib/pages/charts_heatmapchart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'Heatmaps are flexible in nature. The chart can support a '
          'minimum 2x2 grid through a maximum of 10x10 grid. The nodes '
          'should span and reflow with the overall width and height of '
          'your composition.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          'The user has freedom to either choose a sequential palette '
          'or a range of colors that best represent the range of '
          'values. For example, AQI values of regions in a country '
          'could be represented in shades of green, orange and red '
          'based on prescribed health limits of the air quality.\n',
    ),
    ProseBlock(
      title: 'Customizing the chart',
      body:
          '#### Defining Color scale\n'
          'The color palette for a heat map chart is defined by a '
          'domain/range combination. The domain consists of values in '
          'the chart columns. It is an array of numbers. See '
          '`domainValuesForColorScale`. The range is an array '
          '`rangeValuesForColorScale` of colors in hex format. The '
          'graph creates a mapping between each value from domain to '
          'range. For all values in the domain, an equivalent '
          'interpolation is drawn in the range of color scale. For eg: '
          'if the domain is [0,500,900] and range is [green, blue, '
          'red], then [0, 500] is mapped in the range [green, blue] and '
          '[500, 900] in the range [blue, red].\n'
          '#### Data formatting\n'
          'Use the following formatters based on the type of axis.\n'
          '- For date x axis use: `xAxisDateFormatString`\n'
          '- For date y axis use: `yAxisDateFormatString`\n'
          '- For numeric x axis use: `xAxisNumberFormatString`\n'
          '- For numeric y axis use: `yAxisNumberFormatString`\n'
          '- For string x axis use: `xAxisStringFormatter`\n'
          '- For string y axis use: `yAxisStringFormatter`\n'
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
    ProseBlock(
      title: 'Do\'s',
      body: '- Use sequential or divergent color palettes.\n',
    ),
    ProseBlock(
      title: 'Don\'ts',
      body:
          '- Heatmap should not be used as a table as the color coding '
          'is tied to data intensity.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-heatmapchart--heat-map-chart-basic',
      title: 'Heat Map Chart Basic',
      builder: _heatMapChartBasic,
    ),
    DocsSection(
      id: 'charts-heatmapchart--heat-map-chart-custom-accessibility',
      title: 'Heat Map Chart Custom Accessibility',
      builder: _heatMapChartCustomAccessibility,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentHeatMapChartData>',
      description: 'One entry per legend.',
    ),
    PropRow(
      name: 'domainValuesForColorScale',
      type: 'List<double>',
      description: 'Colour-scale domain stops.',
    ),
    PropRow(
      name: 'rangeValuesForColorScale',
      type: 'List<Color>',
      description:
          'Colour-scale range stops; must be the same length as the domain.',
    ),
    PropRow(
      name: 'props',
      type: 'FluentCartesianChartProps',
      defaultValue: 'FluentCartesianChartProps()',
      description: 'Shell configuration: axes, margins, titles and popover.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Human title, folded into the accessible description. Never painted.',
    ),
    PropRow(
      name: 'xAxisDateFormatString',
      type: 'String?',
      defaultValue: 'null',
      description: "strftime pattern for a date x key — '%b/%d' by default.",
    ),
    PropRow(
      name: 'yAxisDateFormatString',
      type: 'String?',
      defaultValue: 'null',
      description: "strftime pattern for a date y key — '%b/%d' by default.",
    ),
    PropRow(
      name: 'xAxisNumberFormatString',
      type: 'String?',
      defaultValue: 'null',
      description: "d3 number format for a numeric x key — '.2~s' by default.",
    ),
    PropRow(
      name: 'yAxisNumberFormatString',
      type: 'String?',
      defaultValue: 'null',
      description: "d3 number format for a numeric y key — '.2~s' by default.",
    ),
    PropRow(
      name: 'xAxisStringFormatter',
      type: 'String Function(String)?',
      defaultValue: 'null',
      description: 'Applied to a string x key after sorting.',
    ),
    PropRow(
      name: 'yAxisStringFormatter',
      type: 'String Function(String)?',
      defaultValue: 'null',
      description: 'Applied to a string y key after sorting.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'BCP-47 locale for cell text and popover values.',
    ),
    PropRow(
      name: 'sortAlphabetically',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether category labels sort alphabetically. False keeps insertion '
          'order.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentHeatMapChartStyle?',
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

// #docregion charts-heatmapchart--heat-map-chart-basic
Widget _heatMapChartBasic(BuildContext context) => const _HeatMapChartBasic();

class _HeatMapChartBasic extends StatefulWidget {
  const _HeatMapChartBasic();

  @override
  State<_HeatMapChartBasic> createState() => _HeatMapChartBasicState();
}

class _HeatMapChartBasicState extends State<_HeatMapChartBasic> {
  double _width = 450;
  double _height = 350;

  // `p1`..`p5` are the sorted keys; the formatter attaches the label, which is
  // how upstream keeps the rows in authoring order rather than alphabetical.
  static const Map<String, String> _yPointMapping = <String, String>{
    'p1': 'Ohio',
    'p2': 'Alaska',
    'p3': 'Texas',
    'p4': 'DC',
    'p5': 'NYC',
  };
  static const List<String> _yPoint = <String>['p1', 'p2', 'p3', 'p4', 'p5'];

  // `new Date('2020-03-03')` parses to UTC midnight and d3's default formatter
  // then prints it in local time. A local DateTime prints `Mar/03` in every
  // timezone, which is what the storybook screenshot shows.
  static final List<DateTime> _xPoint = <DateTime>[
    DateTime(2020, 3, 3), // 0
    DateTime(2020, 3, 4), // 1
    DateTime(2020, 3, 5), // 2
    DateTime(2020, 3, 6), // 3
    DateTime(2020, 3, 7), // 4
    DateTime(2020, 3, 8), // 5
    DateTime(2020, 3, 9), // 6
    DateTime(2020, 3, 10), // 7
  ];

  static final List<FluentHeatMapChartData> _heatMapData =
      <FluentHeatMapChartData>[
        FluentHeatMapChartData(
          value: 100,
          legend: 'Excellent (0-200)',
          data: <FluentHeatMapChartDataPoint>[
            FluentHeatMapChartDataPoint(
              x: _xPoint[2],
              y: _yPoint[2],
              value: 46,
              rectText: 46,
              ratio: (46, 2391),
              descriptionMessage: 'air quality seems to be excellent today',
            ),
          ],
        ),
        FluentHeatMapChartData(
          value: 250,
          legend: 'Good (201-300)',
          data: <FluentHeatMapChartDataPoint>[
            FluentHeatMapChartDataPoint(
              x: _xPoint[0],
              y: _yPoint[1],
              value: 265,
              rectText: 265,
              ratio: (265, 2479),
              descriptionMessage: 'today we have good air quality in Alaska',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[1],
              y: _yPoint[0],
              value: 310,
              rectText: 310,
              ratio: (310, 2043),
              descriptionMessage: 'a sudden rise of 150 units in Ohio today',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[2],
              y: _yPoint[0],
              value: 320,
              rectText: 320,
              ratio: (320, 2043),
              descriptionMessage:
                  'air quality seems to have decreased by only 15 units from '
                  'yesterday',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[6],
              y: _yPoint[2],
              value: 300,
              rectText: 300,
              ratio: (300, 2391),
              descriptionMessage:
                  'air comes to control a little bit more than yesterday',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[0],
              y: _yPoint[3],
              value: 290,
              rectText: 290,
              ratio: (290, 2462),
              descriptionMessage:
                  '1st day in the week, DC witnesses good air quality',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[4],
              y: _yPoint[4],
              value: 280,
              rectText: 280,
              ratio: (280, 2486),
              descriptionMessage:
                  'Air quality index decreases by exactly 300 units, giving '
                  'the people of NYC good hope',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[5],
              y: _yPoint[3],
              value: 300,
              rectText: 300,
              ratio: (300, 2462),
              descriptionMessage: '60 units decreased from yesterday.',
            ),
          ],
        ),
        FluentHeatMapChartData(
          value: 350,
          legend: 'Medium (301-400)',
          data: <FluentHeatMapChartDataPoint>[
            FluentHeatMapChartDataPoint(
              x: _xPoint[1],
              y: _yPoint[1],
              value: 345,
              rectText: 345,
              ratio: (345, 2479),
              descriptionMessage:
                  'Alaska has just reported nearly 100 units hike in air '
                  'quality',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[6],
              y: _yPoint[1],
              value: 325,
              rectText: 325,
              ratio: (325, 2479),
              descriptionMessage: 'Alaska to 300',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[5],
              y: _yPoint[2],
              value: 390,
              rectText: 390,
              ratio: (390, 2391),
              descriptionMessage: 'air comes to control a little bit',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[1],
              y: _yPoint[3],
              value: 385,
              rectText: 385,
              ratio: (385, 2462),
              descriptionMessage:
                  'Washington DC witnesses a hike of nearly 100 units in air '
                  'quality',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[4],
              y: _yPoint[3],
              value: 360,
              rectText: 360,
              ratio: (360, 2462),
              descriptionMessage: 'a 200% hike in the air quality index',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[1],
              y: _yPoint[2],
              value: 400,
              rectText: 400,
              ratio: (400, 2391),
              descriptionMessage:
                  'a sudden spike in the badness of the air quality',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[3],
              y: _yPoint[0],
              value: 400,
              rectText: 400,
              ratio: (400, 2043),
              descriptionMessage:
                  'situation got worse in air quality due to industrial smoke',
            ),
          ],
        ),
        FluentHeatMapChartData(
          value: 450,
          legend: 'Danger (401-500)',
          data: <FluentHeatMapChartDataPoint>[
            FluentHeatMapChartDataPoint(
              x: _xPoint[4],
              y: _yPoint[0],
              value: 423,
              rectText: 423,
              ratio: (423, 2043),
              descriptionMessage: 'we can see an increase of 23 units',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[2],
              y: _yPoint[1],
              value: 463,
              rectText: 463,
              ratio: (463, 2479),
              descriptionMessage:
                  'day by day, situation is getting worse in Alaska',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[3],
              y: _yPoint[2],
              value: 480,
              rectText: 480,
              ratio: (480, 2391),
              descriptionMessage:
                  'same story, today also air quality decreases. a bad day in '
                  'Texas',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[2],
              y: _yPoint[3],
              value: 491,
              rectText: 491,
              ratio: (491, 2462),
              descriptionMessage:
                  'Day by day, 100 units are increasing in air quality',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[1],
              y: _yPoint[4],
              value: 433,
              rectText: 433,
              ratio: (433, 2486),
              descriptionMessage:
                  'They say good things stay for a short time, today this '
                  'saying became reality. New York has witnessed nearly 300% '
                  'bad air quality',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[5],
              y: _yPoint[4],
              value: 473,
              rectText: 473,
              ratio: (473, 2486),
              descriptionMessage:
                  'Today is the same fate as the 2nd day. still, air quality '
                  'stays above 400',
            ),
          ],
        ),
        FluentHeatMapChartData(
          value: 550,
          legend: 'Very Danger (501-600)',
          data: <FluentHeatMapChartDataPoint>[
            FluentHeatMapChartDataPoint(
              x: _xPoint[5],
              y: _yPoint[0],
              value: 600,
              rectText: 600,
              ratio: (600, 2043),
              descriptionMessage:
                  'looks like god has cursed us with poisonous air. worst air '
                  'quality index',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[5],
              y: _yPoint[1],
              value: 536,
              rectText: 536,
              ratio: (536, 2479),
              descriptionMessage:
                  'shh!, all the hopes were washed away in the rain yesterday, '
                  'with another hike of 400% in air quality',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[3],
              y: _yPoint[1],
              value: 520,
              rectText: 520,
              ratio: (520, 2479),
              descriptionMessage:
                  'Alaska planning to build air purifier to control the air '
                  'quality',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[4],
              y: _yPoint[2],
              value: 525,
              rectText: 525,
              ratio: (525, 2391),
              descriptionMessage:
                  'air worsens badly today due to farmers burning the harvest',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[6],
              y: _yPoint[3],
              value: 560,
              rectText: 560,
              ratio: (560, 2462),
              descriptionMessage:
                  'Due to industrial pollution and the burning of harvest, it '
                  'resulted in bad air quality in Washington DC',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[3],
              y: _yPoint[4],
              value: 580,
              rectText: 580,
              ratio: (580, 2486),
              descriptionMessage:
                  'Air quality index is becoming worse day by day, leaving the '
                  'people of NYC in very bad medical conditions.',
            ),
            FluentHeatMapChartDataPoint(
              x: _xPoint[6],
              y: _yPoint[4],
              value: 590,
              rectText: 590,
              ratio: (590, 2486),
              descriptionMessage:
                  'finally, the weekend ends with very bad air quality in New '
                  'York City',
            ),
          ],
        ),
      ];

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
            width: 160,
            child: FluentSlider(
              value: _width,
              min: 200,
              max: 1000,
              step: 1,
              semanticLabel: 'Change Width',
              semanticFormatter: (double value) =>
                  "current value ${value.round()}', Minimum 200 and Maximum "
                  '1000',
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
              semanticFormatter: (double value) =>
                  'ChangeHeightSlider${value.round()}',
              onChanged: (double value) => setState(() => _height = value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        'Heat map explaining the Air Quality Index',
        style: FluentTheme.of(context).typography.subtitle2,
      ),
      const SizedBox(height: 12),
      // The width slider reaches past the card, so the chart box scrolls
      // sideways rather than overflowing it.
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _width,
          height: _height,
          child: FluentHeatMapChart(
            // `window.navigator.language`, which in Flutter is the locale the
            // app resolved for this subtree.
            culture: Localizations.localeOf(context).toLanguageTag(),
            chartTitle: 'Heat map chart basic example',
            data: _heatMapData,
            yAxisStringFormatter: (String point) => _yPointMapping[point]!,
            xAxisNumberFormatString: '.7s',
            yAxisNumberFormatString: '.3s',
            domainValuesForColorScale: const <double>[0, 200, 400, 600],
            rangeValuesForColorScale: <Color>[
              FluentDataVizPalette.resolve(FluentDataVizToken.color5),
              FluentDataVizPalette.resolve(FluentDataVizToken.color6),
              FluentDataVizPalette.resolve(FluentDataVizToken.color3),
              FluentDataVizPalette.resolve(FluentDataVizToken.color10),
            ],
            props: const FluentCartesianChartProps(
              reflowMode: FluentChartReflowMode.minWidth,
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion charts-heatmapchart--heat-map-chart-basic

// #docregion charts-heatmapchart--heat-map-chart-custom-accessibility
Widget _heatMapChartCustomAccessibility(BuildContext context) =>
    const _HeatMapChartCustomAccessibility();

const List<String> _yPointA11y = <String>['CHN', 'IND', 'USA', 'IDN', 'PAK'];
const List<String> _xPointA11y = <String>[
  '1980',
  '1990',
  '2000',
  '2010',
  '2020',
];
const List<List<int>> _dataMatrix = <List<int>>[
  <int>[818315000, 981235000, 1135185000, 1262645000, 1337705000, 1411100000],
  <int>[557501301, 696828385, 870452165, 1059633675, 1240613620, 1396387127],
  <int>[205052000, 227225000, 249623000, 282162411, 309327143, 331511512],
  <int>[115228394, 148177096, 182159874, 214072421, 244016173, 271857970],
  <int>[59290872, 80624057, 115414069, 154369924, 194454498, 227196741],
];

List<FluentHeatMapChartDataPoint> _getDataPoints(
  bool Function(int value) valueFilter,
) {
  final List<FluentHeatMapChartDataPoint> dataPoints =
      <FluentHeatMapChartDataPoint>[];
  for (int ri = 0; ri < _dataMatrix.length; ri++) {
    final List<int> row = _dataMatrix[ri];
    for (int ci = 0; ci < row.length; ci++) {
      final int value = row[ci];
      if (ci > 0 && valueFilter(value)) {
        dataPoints.add(
          FluentHeatMapChartDataPoint(
            x: _xPointA11y[ci - 1],
            y: _yPointA11y[ri],
            value: value / 1e6,
            rectText: _getRectText(value),
            descriptionMessage: _getDescription(
              _xPointA11y[ci - 1],
              _yPointA11y[ri],
              value,
              row[ci - 1],
            ),
            callOutSemantics: FluentChartSemantics(
              label: _getDescription(
                _xPointA11y[ci - 1],
                _yPointA11y[ri],
                value,
                row[ci - 1],
              ),
            ),
          ),
        );
      }
    }
  }
  return dataPoints;
}

// d3's `formatPrefix('.1', value)` picks the SI prefix from the value's own
// magnitude and prints one decimal; the story then renames `k` to `K` and `G`
// to `B`. `d3-format` is not part of our public surface, so the three stops
// this data reaches are spelled out.
String _getRectText(int value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return '$value';
}

const Map<String, String> _yPointMap = <String, String>{
  'CHN': 'China',
  'IND': 'India',
  'USA': 'United States',
  'IDN': 'Indonesia',
  'PAK': 'Pakistan',
};

String _getDescription(String x, String y, int value, int prevValue) {
  final double percentageChange = ((value - prevValue) / prevValue) * 100;
  return '${_yPointMap[y]}, $x. $value, '
      '${percentageChange >= 0 ? '+' : ''}'
      '${percentageChange.toStringAsFixed(2)}%.';
}

class _HeatMapChartCustomAccessibility extends StatefulWidget {
  const _HeatMapChartCustomAccessibility();

  @override
  State<_HeatMapChartCustomAccessibility> createState() =>
      _HeatMapChartCustomAccessibilityState();
}

class _HeatMapChartCustomAccessibilityState
    extends State<_HeatMapChartCustomAccessibility> {
  double _width = 450;
  double _height = 350;

  @override
  Widget build(BuildContext context) {
    final List<FluentHeatMapChartData> heatMapData = <FluentHeatMapChartData>[
      FluentHeatMapChartData(
        value: 250,
        legend: '< 500M',
        data: _getDataPoints((int value) => value < 5e8),
      ),
      FluentHeatMapChartData(
        value: 750,
        legend: '500M - 1B',
        data: _getDataPoints((int value) => value >= 5e8 && value <= 1e9),
      ),
      FluentHeatMapChartData(
        value: 1250,
        legend: '> 1B',
        data: _getDataPoints((int value) => value > 1e9),
      ),
    ];

    return Column(
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
              width: 160,
              child: FluentSlider(
                value: _width,
                min: 200,
                max: 1000,
                step: 1,
                semanticLabel: 'Change Width',
                semanticFormatter: (double value) =>
                    "current value ${value.round()}', Minimum 200 and Maximum "
                    '1000',
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
                semanticFormatter: (double value) =>
                    "current value ${value.round()}', Minimum 200 and Maximum "
                    '1000',
                onChanged: (double value) => setState(() => _height = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Heat map showing population growth over decades',
          style: FluentTheme.of(context).typography.subtitle2,
        ),
        const SizedBox(height: 12),
        // The width slider reaches past the card, so the chart box scrolls
        // sideways rather than overflowing it.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentHeatMapChart(
              chartTitle: 'Heat map chart custom accessibility example',
              data: heatMapData,
              xAxisStringFormatter: (String point) => 'FY $point',
              domainValuesForColorScale: const <double>[0, 1500],
              rangeValuesForColorScale: <Color>[
                FluentDataVizPalette.resolve(FluentDataVizToken.color3),
                FluentDataVizPalette.resolve(FluentDataVizToken.color10),
              ],
              props: const FluentCartesianChartProps(
                reflowMode: FluentChartReflowMode.minWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// #enddocregion charts-heatmapchart--heat-map-chart-custom-accessibility
