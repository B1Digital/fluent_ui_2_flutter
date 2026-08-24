import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Sparkline docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage sparklinePage = DocsPage(
  id: 'charts-sparkline',
  title: 'Sparkline',
  description:
      'A sparkline is a very small area chart without axes or '
      'coordinates. It is useful for quick and high-level evaluation of '
      'trends. It can be an effective solution for presenting an '
      'overview of multiple series (high cardinality of data) '
      'simultaneously while maximizing legibility. From Edward Tufte: '
      '"A sparkline is a small intense, simple, word-sized graphic with '
      'typographic resolution. Sparklines mean that graphics are no '
      'longer cartoonish special occasions with captions and boxes, but '
      'rather sparkline graphics can be anywhere a word or number is '
      'present - embedded in a sentence, table, headline, map, '
      'spreadsheet, graphic."',
  source: 'lib/pages/charts_sparkline.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'A standard sparkline component is comprised of a single area '
          'chart. The value shown to the right of the sparkline '
          'represents the latest data of the trendline. It does not '
          'represent the average value of the data plotted. Most '
          'scenarios that require sparklines typically need only green '
          'and red to show positive or negative trend, respectively. If '
          'representing a neutral trend, use `Comm Blue #0078D4`. '
          'However, the color of the sparkline can be customized to '
          'suit your product and scenario you’re designing for. You can '
          'use positive, negative, and neutral colors next to each '
          'other.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- **Line** 1px line\n'
          '- **Fill** Same color as line with opacity of 0.2\n'
          '- **Legend** Latest value to show as label after the chart.\n',
    ),
    ProseBlock(
      title: 'Do\'s',
      body:
          '- The most important value is displayed directly next to the '
          'chart.\n'
          '- Sparkline can be embedded within tables, paragraphs, lists '
          'and more.\n',
    ),
    ProseBlock(
      title: 'Don\'ts',
      body:
          '- Don’t enable a hover state. The most important value is '
          'displayed directly next to the chart.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-sparkline--sparkline-basic',
      title: 'Sparkline Basic',
      builder: _sparklineBasic,
    ),
    DocsSection(
      id: 'charts-sparkline--sparkline-dimensions',
      title: 'Sparkline Dimensions',
      description:
          'Customize Sparkline dimensions using width and height props. '
          'Default: width=80px, height=20px.',
      builder: _sparklineDimensions,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'FluentChartData',
      description: 'The chart data. Only the first line series is read.',
    ),
    PropRow(
      name: 'width',
      type: 'double',
      defaultValue: '80',
      description: 'Preferred plot width.',
    ),
    PropRow(
      name: 'height',
      type: 'double',
      defaultValue: '20',
      description: 'Preferred plot height.',
    ),
    PropRow(
      name: 'valueTextWidth',
      type: 'double',
      defaultValue: '80',
      description: 'Width of the value-text strip.',
    ),
    PropRow(
      name: 'showLegend',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to render the series legend beside the plot.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentSparklineStyle?',
      defaultValue: 'null',
      description:
          'Style layered over the derived defaults and the nearest '
          'FluentSparklineTheme.',
    ),
  ],
);

// #docregion charts-sparkline--sparkline-basic
Widget _sparklineBasic(BuildContext context) {
  final FluentChartData sl1 = FluentChartData(
    chartTitle: '10.21',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '19.64',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 1, y: 58.13),
          FluentLineChartDataPoint(x: 2, y: 140.98),
          FluentLineChartDataPoint(x: 3, y: 20),
          FluentLineChartDataPoint(x: 4, y: 89.7),
          FluentLineChartDataPoint(x: 5, y: 99),
          FluentLineChartDataPoint(x: 6, y: 13.28),
          FluentLineChartDataPoint(x: 7, y: 31.32),
          FluentLineChartDataPoint(x: 8, y: 10.21),
        ],
      ),
    ],
  );
  final FluentChartData sl2 = FluentChartData(
    chartTitle: '49.44',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '19.64',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 1, y: 29.13),
          FluentLineChartDataPoint(x: 2, y: 70.98),
          FluentLineChartDataPoint(x: 3, y: 60),
          FluentLineChartDataPoint(x: 4, y: 89.7),
          FluentLineChartDataPoint(x: 5, y: 19),
          FluentLineChartDataPoint(x: 6, y: 49.44),
        ],
      ),
    ],
  );
  final FluentChartData sl3 = FluentChartData(
    chartTitle: '49.44',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '19.64',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 1, y: 29.13),
          FluentLineChartDataPoint(x: 2, y: 70.98),
          FluentLineChartDataPoint(x: 3, y: 60),
          FluentLineChartDataPoint(x: 4, y: 89.7),
          FluentLineChartDataPoint(x: 5, y: 19),
          FluentLineChartDataPoint(x: 6, y: 49.44),
        ],
      ),
    ],
  );
  final FluentChartData sl4 = FluentChartData(
    chartTitle: '49.44',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '464.64',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 1, y: 29.13),
          FluentLineChartDataPoint(x: 2, y: 70.98),
          FluentLineChartDataPoint(x: 3, y: 60),
          FluentLineChartDataPoint(x: 4, y: 89.7),
          FluentLineChartDataPoint(x: 5, y: 19),
          FluentLineChartDataPoint(x: 6, y: 49.44),
        ],
      ),
    ],
  );
  final FluentChartData sl5 = FluentChartData(
    chartTitle: '49.44',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '46.49',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 1, y: 29.13),
          FluentLineChartDataPoint(x: 2, y: 70.98),
          FluentLineChartDataPoint(x: 3, y: 60),
          FluentLineChartDataPoint(x: 4, y: 89.7),
          FluentLineChartDataPoint(x: 5, y: 19),
          FluentLineChartDataPoint(x: 6, y: 49.44),
        ],
      ),
    ],
  );
  final FluentChartData sl6 = FluentChartData(
    chartTitle: '49.44',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '49.44',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 29.13),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 70.98),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 60),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 89.7),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 12), y: 19),
          FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 15), y: 49.44),
        ],
      ),
    ],
  );
  final FluentChartData sl7 = FluentChartData(
    chartTitle: '49.44',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '49.44',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 1, y: 29.13),
          FluentLineChartDataPoint(x: 2, y: 70.98),
          FluentLineChartDataPoint(x: 3, y: 60),
          FluentLineChartDataPoint(x: 4, y: 89.7),
          FluentLineChartDataPoint(x: 5, y: 19),
          FluentLineChartDataPoint(x: 6, y: 49.44),
        ],
      ),
    ],
  );
  final FluentChartData sl8 = FluentChartData(
    chartTitle: '541.44',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '541.44',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 1, y: 291.13),
          FluentLineChartDataPoint(x: 2, y: 170.98),
          FluentLineChartDataPoint(x: 3, y: 260),
          FluentLineChartDataPoint(x: 4, y: 89.7),
          FluentLineChartDataPoint(x: 5, y: 664),
          FluentLineChartDataPoint(x: 6, y: 66.44),
          FluentLineChartDataPoint(x: 7, y: 541.44),
          FluentLineChartDataPoint(x: 8, y: 32.44),
          FluentLineChartDataPoint(x: 9, y: 499.14),
          FluentLineChartDataPoint(x: 10, y: 350.48),
          FluentLineChartDataPoint(x: 11, y: 32.44),
          FluentLineChartDataPoint(x: 12, y: 400.44),
        ],
      ),
    ],
  );

  // Upstream's `<td style={{ paddingRight: 15, paddingTop: 5,
  // paddingBottom: 5 }}>` label cell, beside a cell holding the sparkline.
  TableRow row(String label, Widget sparkline) => TableRow(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 15, top: 5, bottom: 5),
        child: Text(label),
      ),
      sparkline,
    ],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // Upstream's container is `display: inline`, so the two sparklines sit
      // in the run of text. A WidgetSpan is Flutter's inline box.
      Text.rich(
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(text: 'A sparkline '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: FluentSparkline(data: sl1, showLegend: true),
            ),
            const TextSpan(
              text:
                  ' - is a very small line chart, drawn without axes or '
                  'coordinates. It presents the general shape of the '
                  'variation (like over time) in some measurement,',
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: FluentSparkline(data: sl2),
            ),
            const TextSpan(
              text:
                  ' - such as temperature or stock market price, in a simple '
                  'and highly condensed way.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text('Below table shows sparklines in one of its columns.'),
      const SizedBox(height: 16),
      Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[
          row('Row 1', FluentSparkline(data: sl1, showLegend: true)),
          row('Row 2', FluentSparkline(data: sl2, showLegend: true)),
          row('Row 3', FluentSparkline(data: sl3)),
          row('Row 4', FluentSparkline(data: sl4)),
          row('Row 5', FluentSparkline(data: sl5)),
          row('Row 6', FluentSparkline(data: sl6, showLegend: true)),
          row('Row 7', FluentSparkline(data: sl7, showLegend: true)),
          row('Row 8', FluentSparkline(data: sl8, showLegend: true)),
        ],
      ),
    ],
  );
}
// #enddocregion charts-sparkline--sparkline-basic

// #docregion charts-sparkline--sparkline-dimensions
Widget _sparklineDimensions(BuildContext context) {
  final FluentChartData sampleData = FluentChartData(
    chartTitle: '89.7',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: '89.7',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        data: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 1, y: 58.13),
          FluentLineChartDataPoint(x: 2, y: 140.98),
          FluentLineChartDataPoint(x: 3, y: 20),
          FluentLineChartDataPoint(x: 4, y: 89.7),
          FluentLineChartDataPoint(x: 5, y: 99),
          FluentLineChartDataPoint(x: 6, y: 13.28),
          FluentLineChartDataPoint(x: 7, y: 31.32),
          FluentLineChartDataPoint(x: 8, y: 89.7),
        ],
      ),
    ],
  );

  Widget row(String label, Widget sparkline) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(width: 140, child: Text(label)),
      const SizedBox(width: 15),
      sparkline,
    ],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      row(
        'Default (80x20):',
        FluentSparkline(data: sampleData, showLegend: true),
      ),
      const SizedBox(height: 20),
      row(
        'Custom width=150:',
        FluentSparkline(data: sampleData, width: 150, showLegend: true),
      ),
      const SizedBox(height: 20),
      row(
        'Custom height=40:',
        FluentSparkline(data: sampleData, height: 40, showLegend: true),
      ),
      const SizedBox(height: 20),
      row(
        'Both (200x60):',
        FluentSparkline(
          data: sampleData,
          width: 200,
          height: 60,
          showLegend: true,
        ),
      ),
    ],
  );
}

// #enddocregion charts-sparkline--sparkline-dimensions
