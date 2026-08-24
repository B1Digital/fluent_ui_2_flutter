import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The HorizontalBarChart docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream's `getColorFromToken(DataVizPalette.colorN)` is
/// `FluentDataVizPalette.resolve(FluentDataVizToken.colorN)` here, and the
/// `maxWidth: 600` wrapper every story puts round the chart is a
/// `ConstrainedBox`.
const DocsPage horizontalBarChartPage = DocsPage(
  id: 'charts-horizontalbarchart',
  title: 'HorizontalBarChart',
  description:
      'A horizontal bar chart is a chart that presents categorical data '
      'with rectangular bars with lengths proportional to the values '
      'they represent. This type of chart is particularly useful when '
      'the intention is to show comparisons among various categories '
      'and the labels for those categories are long.',
  source: 'lib/pages/charts_horizontalbarchart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'Use a horizontal bar graph to compare between different '
          'values that are hierarchically equivalent. The rectangular '
          'bar length is proportional to the values they represent. '
          'There will always be a maximum data value (color) '
          'representing the total length.\n'
          'Horizontal bar chart can be of 2 types -\n'
          '- **Absolute scale** the length of the bar is proportional '
          'to the biggest value for the category.\n'
          '- **n/M scale** the length of the bar is determined by the '
          'total/target value of the specific bar. As a result, 2 '
          'adjacent bars can have different data scales and not be '
          'comparable. This aspect should be kept in mind while using '
          'this chart type. See HorizontalBarChart benchmark example to '
          'see the behavior. Each bar has a different scale - 100, 200 '
          'and 50 units.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- **Title/Label** The label for the bar. It is displayed '
          'above the bar and can represent longer texts.\n'
          '- **Bar segment** The bar segment represents the current '
          'value of the category. For n/M variant there is a '
          'placeholder segment to show the left-over values.\n'
          '- **Bar value** The value of the bar is represented on the '
          'right side. This can be absolute or percentage format. This '
          'can also be in fractional form representing current value '
          'out of total value. See the chartDataMode property to use '
          'it.\n'
          '- **Benchmark** The benchmark value is shown as an inverted '
          'triangle in the chart.\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          '- Bar graphs should be flexible to their containers. They '
          'will change widths to fit their environment.\n'
          '- Each section of the bar chart is readable via screen '
          'readers. The user can navigate through the entire bar graph '
          'by using the tab keys.\n'
          '- The chart reflows to accommodate zooming in to 400%.\n',
    ),
    ProseBlock(
      title: 'Customizing the chart',
      body:
          '- **Bar chart custom data** This property allows customizing '
          'the right-side data part of the chart. See the usage of '
          '`barChartCustomData` prop in custom callout variant.\n'
          '- **Custom hover callout** See '
          '`onRenderCalloutPerHorizontalBar` prop to customize the '
          'hover callout.\n'
          'Set the `chartDataMode` as number, fraction or percentage to '
          'specify how numerical values will be shown on the chart.\n'
          '- **Benchmark data** Set the data attribute of '
          '`IChartDataPoint` to specify the benchmark value. The '
          'benchmark value is shown as an inverted triangle in the '
          'chart.\n'
          '- **AbsoluteScale variant** The bar labels are shown by '
          'default in the absolute-scale variant. Set the `hideLabels` '
          'prop to hide them.\n',
    ),
    ProseBlock(
      title: 'Do\'s',
      body:
          '- Use horizontal bar chart if the length of labels is '
          'longer.\n'
          '- Numerical units on labels are represented through '
          'abbreviations.\n',
    ),
    ProseBlock(
      title: 'Don\'ts',
      body:
          '- Avoid having more than 20 bars in the chart.\n'
          '- The n/M variant should be used only when a value has to be '
          'compared against its target value.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-horizontalbarchart--horizontal-bar-basic',
      title: 'Horizontal Bar Basic',
      builder: _horizontalBarBasic,
    ),
    DocsSection(
      id: 'charts-horizontalbarchart--horizontal-bar-absolute-scale',
      title: 'Horizontal Bar Absolute Scale',
      builder: _horizontalBarAbsoluteScale,
    ),
    DocsSection(
      id: 'charts-horizontalbarchart--horizontal-bar-benchmark',
      title: 'Horizontal Bar Benchmark',
      builder: _horizontalBarBenchmark,
    ),
    DocsSection(
      id: 'charts-horizontalbarchart--horizontal-bar-stacked',
      title: 'Horizontal Bar Stacked',
      builder: _horizontalBarStacked,
    ),
    DocsSection(
      id: 'charts-horizontalbarchart--horizontal-bar-custom-accessibility',
      title: 'Horizontal Bar Custom Accessibility',
      builder: _horizontalBarCustomAccessibility,
    ),
    DocsSection(
      id: 'charts-horizontalbarchart--horizontal-bar-custom-callout',
      title: 'Horizontal Bar Custom Callout',
      builder: _horizontalBarCustomCallout,
    ),
    DocsSection(
      id: 'charts-horizontalbarchart--horizontal-bar-stacked-annotated-inline-legend',
      title: 'Horizontal Bar Stacked Annotated Inline Legend',
      builder: _horizontalBarStackedAnnotatedInlineLegend,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentChartData>',
      description: 'One entry per row.',
    ),
    PropRow(
      name: 'barHeight',
      type: 'double?',
      defaultValue: 'null',
      description: 'Bar height override. Null resolves to 12.',
    ),
    PropRow(
      name: 'hideTooltip',
      type: 'bool',
      defaultValue: 'false',
      description: 'Suppresses the hover popover.',
    ),
    PropRow(
      name: 'chartDataMode',
      type: 'FluentChartDataMode',
      defaultValue: 'FluentChartDataMode.byDefault',
      description: 'How the number beside a row is rendered.',
    ),
    PropRow(
      name: 'variant',
      type: 'FluentHorizontalBarChartVariant',
      defaultValue: 'FluentHorizontalBarChartVariant.partToWhole',
      description: 'Which scale the row draws against.',
    ),
    PropRow(
      name: 'hideLabels',
      type: 'bool',
      defaultValue: 'false',
      description: 'Hides the absolute-scale in-bar label.',
    ),
    PropRow(
      name: 'showTriangle',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Widens the row spacing to make room for a benchmark marker.',
    ),
    PropRow(
      name: 'showLegendForSinglePointBar',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Keeps the legend and skips the placeholder synthesis for a '
          'single-point row.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'Locale tag for number formatting.',
    ),
    PropRow(
      name: 'legendsOverflowText',
      type: 'String',
      defaultValue: "'more'",
      description: 'Label on the legend overflow control.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentHorizontalBarChartStyle?',
      defaultValue: 'null',
      description:
          'Style layered over the derived defaults and the nearest '
          'FluentHorizontalBarChartTheme.',
    ),
  ],
);

// #docregion charts-horizontalbarchart--horizontal-bar-basic
Widget _horizontalBarBasic(BuildContext context) {
  final List<FluentChartData> data = <FluentChartData>[
    FluentChartData(
      chartTitle: 'one',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'one',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 1543,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '10%',
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'two',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'two',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 800,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '5%',
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'three',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'three',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 8888,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '59%',
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'four',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'four',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 15888,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '106%',
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'five',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'five',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 11444,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '76%',
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'six',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'six',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 14000,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '93%',
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'seven',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'seven',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 9855,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '66%',
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'eight',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'eight',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 4250,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: '28%',
        ),
      ],
    ),
  ];

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: FluentHorizontalBarChart(
      data: data,
      chartDataMode: FluentChartDataMode.byDefault,
    ),
  );
}
// #enddocregion charts-horizontalbarchart--horizontal-bar-basic

// #docregion charts-horizontalbarchart--horizontal-bar-absolute-scale
Widget _horizontalBarAbsoluteScale(BuildContext context) =>
    const _HorizontalBarAbsoluteScale();

class _HorizontalBarAbsoluteScale extends StatefulWidget {
  const _HorizontalBarAbsoluteScale();

  @override
  State<_HorizontalBarAbsoluteScale> createState() =>
      _HorizontalBarAbsoluteScaleState();
}

class _HorizontalBarAbsoluteScaleState
    extends State<_HorizontalBarAbsoluteScale> {
  bool _hideLabels = false;

  @override
  Widget build(BuildContext context) {
    final List<FluentChartData> data = <FluentChartData>[
      FluentChartData(
        chartTitle: 'one',
        chartData: <FluentChartDataPoint>[
          FluentChartDataPoint(
            legend: 'one',
            horizontalBarChartData: const FluentHorizontalDataPoint(
              x: 1543,
              total: 15000,
            ),
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color17),
          ),
        ],
      ),
      FluentChartData(
        chartTitle: 'two',
        chartData: <FluentChartDataPoint>[
          FluentChartDataPoint(
            legend: 'two',
            horizontalBarChartData: const FluentHorizontalDataPoint(
              x: 800,
              total: 15000,
            ),
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color18),
          ),
        ],
      ),
      FluentChartData(
        chartTitle: 'three',
        chartData: <FluentChartDataPoint>[
          FluentChartDataPoint(
            legend: 'three',
            horizontalBarChartData: const FluentHorizontalDataPoint(
              x: 8888,
              total: 15000,
            ),
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color19),
          ),
        ],
      ),
      FluentChartData(
        chartTitle: 'four',
        chartData: <FluentChartDataPoint>[
          FluentChartDataPoint(
            legend: 'four',
            horizontalBarChartData: const FluentHorizontalDataPoint(
              x: 15888,
              total: 15000,
            ),
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color20),
          ),
        ],
      ),
      FluentChartData(
        chartTitle: 'five',
        chartData: <FluentChartDataPoint>[
          FluentChartDataPoint(
            legend: 'five',
            horizontalBarChartData: const FluentHorizontalDataPoint(
              x: 11444,
              total: 15000,
            ),
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color21),
          ),
        ],
      ),
      FluentChartData(
        chartTitle: 'six',
        chartData: <FluentChartDataPoint>[
          FluentChartDataPoint(
            legend: 'six',
            horizontalBarChartData: const FluentHorizontalDataPoint(
              x: 14000,
              total: 15000,
            ),
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
          ),
        ],
      ),
      FluentChartData(
        chartTitle: 'seven',
        chartData: <FluentChartDataPoint>[
          FluentChartDataPoint(
            legend: 'seven',
            horizontalBarChartData: const FluentHorizontalDataPoint(
              x: 9855,
              total: 15000,
            ),
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color23),
          ),
        ],
      ),
      FluentChartData(
        chartTitle: 'eight',
        chartData: <FluentChartDataPoint>[
          FluentChartDataPoint(
            legend: 'eight',
            horizontalBarChartData: const FluentHorizontalDataPoint(
              x: 4250,
              total: 15000,
            ),
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color24),
          ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FluentCheckbox(
          label: const Text('Hide labels'),
          checked: _hideLabels,
          onChanged: (bool? checked) =>
              setState(() => _hideLabels = checked ?? false),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FluentHorizontalBarChart(
            data: data,
            variant: FluentHorizontalBarChartVariant.absoluteScale,
            hideLabels: _hideLabels,
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-horizontalbarchart--horizontal-bar-absolute-scale

// #docregion charts-horizontalbarchart--horizontal-bar-benchmark
// `showTriangle` is a caller-supplied bool here, where upstream derives it from
// the presence of a benchmark `data` field; passing it widens the row spacing
// so the inverted triangle has somewhere to sit. Upstream's `hideRatio` array
// has no port — it is dead in this story anyway, since the reference renders
// the fraction on every row.
Widget _horizontalBarBenchmark(BuildContext context) {
  final List<FluentChartData> data = <FluentChartData>[
    FluentChartData(
      chartTitle: 'one',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'one',
          data: 50,
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 10,
            total: 100,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color25),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'two',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'two',
          data: 30,
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 30,
            total: 200,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color26),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'three',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'three',
          data: 5,
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 15,
            total: 50,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color27),
        ),
      ],
    ),
  ];

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: FluentHorizontalBarChart(
      data: data,
      chartDataMode: FluentChartDataMode.fraction,
      showTriangle: true,
    ),
  );
}
// #enddocregion charts-horizontalbarchart--horizontal-bar-benchmark

// #docregion charts-horizontalbarchart--horizontal-bar-stacked
Widget _horizontalBarStacked(BuildContext context) {
  final List<FluentChartData> data = <FluentChartData>[
    FluentChartData(
      chartTitle: 'one',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'One.One',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 1543),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        ),
        FluentChartDataPoint(
          legend: 'One.Two',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 1000),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        ),
        FluentChartDataPoint(
          legend: 'One.Three',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 547),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'two',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'Two.One',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 987),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        ),
        FluentChartDataPoint(
          legend: 'Two.Two',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 1987),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'three',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'Three.One',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 872),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        ),
        FluentChartDataPoint(
          legend: 'Three.Two',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 128),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
        ),
      ],
    ),
  ];

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: FluentHorizontalBarChart(
      data: data,
      chartDataMode: FluentChartDataMode.byDefault,
    ),
  );
}
// #enddocregion charts-horizontalbarchart--horizontal-bar-stacked

// #docregion charts-horizontalbarchart--horizontal-bar-custom-accessibility
// Upstream's `chartTitleAccessibilityData`, `chartDataAccessibilityData` and
// `callOutAccessibilityData` are `{ ariaLabel }` bags; here they are
// `FluentChartSemantics(label: ...)`, which is the same string on the same
// three slots.
Widget _horizontalBarCustomAccessibility(BuildContext context) {
  final List<FluentChartData> data = <FluentChartData>[
    FluentChartData(
      chartTitle: 'one',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about one',
      ),
      chartDataSemantics: const FluentChartSemantics(
        label: 'Data 1543 of 15000',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'one',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 1543,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
          xAxisCalloutData: '2021/06/10',
          yAxisCalloutData: '10%',
          callOutSemantics: const FluentChartSemantics(
            label: 'Bar series 1 of chart one 2021/06/10 10%',
          ),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'two',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about two',
      ),
      chartDataSemantics: const FluentChartSemantics(
        label: 'Data 800 of 15000',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'two',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 800,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
          xAxisCalloutData: '2021/06/11',
          yAxisCalloutData: '5%',
          callOutSemantics: const FluentChartSemantics(
            label: 'Bar series 1 of chart two 2021/06/11 5%',
          ),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'three',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about three',
      ),
      chartDataSemantics: const FluentChartSemantics(
        label: 'Data 8888 of 15000',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'three',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 8888,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
          xAxisCalloutData: '2021/06/12',
          yAxisCalloutData: '59%',
          callOutSemantics: const FluentChartSemantics(
            label: 'Bar series 1 of chart three 2021/06/12 59%',
          ),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'four',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about four',
      ),
      chartDataSemantics: const FluentChartSemantics(
        label: 'Data 15888 of 15000',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'four',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 15888,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
          xAxisCalloutData: '2021/06/13',
          yAxisCalloutData: '105%',
          callOutSemantics: const FluentChartSemantics(
            label: 'Bar series 1 of chart four 2021/06/13 105%',
          ),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'five',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about five',
      ),
      chartDataSemantics: const FluentChartSemantics(
        label: 'Data 11444 of 15000',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'five',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 11444,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
          xAxisCalloutData: '2021/06/14',
          yAxisCalloutData: '76%',
          callOutSemantics: const FluentChartSemantics(
            label: 'Bar series 1 of chart five 2021/06/14 76%',
          ),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'six',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about six',
      ),
      chartDataSemantics: const FluentChartSemantics(
        label: 'Data 14000 of 15000',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'six',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 14000,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color14),
          xAxisCalloutData: '2021/06/15',
          yAxisCalloutData: '93%',
          callOutSemantics: const FluentChartSemantics(
            label: 'Bar series 1 of chart six 2021/06/15 93%',
          ),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'seven',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about seven',
      ),
      chartDataSemantics: const FluentChartSemantics(
        label: 'Data 9855 of 15000',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'seven',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 9855,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color15),
          xAxisCalloutData: '2021/06/16',
          yAxisCalloutData: '65%',
          callOutSemantics: const FluentChartSemantics(
            label: 'Bar series 1 of chart seven 2021/06/16 65%',
          ),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'eight',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about eight',
      ),
      chartDataSemantics: const FluentChartSemantics(
        label: 'Data 4250 of 15000',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'eight',
          horizontalBarChartData: const FluentHorizontalDataPoint(
            x: 4250,
            total: 15000,
          ),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color16),
          xAxisCalloutData: '2021/06/17',
          yAxisCalloutData: '28%',
          callOutSemantics: const FluentChartSemantics(
            label: 'Bar series 1 of chart eight 2021/06/17 28%',
          ),
        ),
      ],
    ),
  ];

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: FluentHorizontalBarChart(data: data),
  );
}
// #enddocregion charts-horizontalbarchart--horizontal-bar-custom-accessibility

// #docregion charts-horizontalbarchart--horizontal-bar-custom-callout
// `FluentHorizontalBarChart` renders its own popover and takes neither
// `calloutPropsPerDataPoint` nor `onRenderCalloutPerHorizontalBar`, so the
// override is expressed through the two per-point fields the popover does
// read: `xAxisCalloutData` becomes 'Custom XVal' and `yAxisCalloutData` gains
// the ' h' suffix. Upstream's third line, 'Custom Legend', has no slot in our
// popover, which shows one label and one value.
Widget _horizontalBarCustomCallout(BuildContext context) =>
    const _HorizontalBarCustomCallout();

class _HorizontalBarCustomCallout extends StatefulWidget {
  const _HorizontalBarCustomCallout();

  @override
  State<_HorizontalBarCustomCallout> createState() =>
      _HorizontalBarCustomCalloutState();
}

class _HorizontalBarCustomCalloutState
    extends State<_HorizontalBarCustomCallout> {
  bool _useCustomPopover = false;

  FluentChartData _row(
    String title,
    double x,
    FluentDataVizToken token,
    String yAxisCalloutData,
  ) => FluentChartData(
    chartTitle: title,
    chartData: <FluentChartDataPoint>[
      FluentChartDataPoint(
        legend: title,
        horizontalBarChartData: FluentHorizontalDataPoint(x: x, total: 15000),
        color: FluentDataVizPalette.resolve(token),
        xAxisCalloutData: _useCustomPopover ? 'Custom XVal' : '2020/04/30',
        yAxisCalloutData: _useCustomPopover
            ? '$yAxisCalloutData h'
            : yAxisCalloutData,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final List<FluentChartData> data = <FluentChartData>[
      _row('one', 1543, FluentDataVizToken.color28, '1.5K'),
      _row('two', 800, FluentDataVizToken.color29, '800'),
      _row('three', 8888, FluentDataVizToken.color30, '8.8K'),
      _row('four', 15888, FluentDataVizToken.color31, '16K'),
      _row('five', 11444, FluentDataVizToken.color32, '11K'),
      _row('six', 14000, FluentDataVizToken.color33, '14K'),
      _row('seven', 9855, FluentDataVizToken.color34, '9.9K'),
      _row('eight', 4250, FluentDataVizToken.color35, '4.3K'),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentSwitch(
              label: const Text('User Popover Override'),
              checked: _useCustomPopover,
              onChanged: (bool value) =>
                  setState(() => _useCustomPopover = value),
            ),
          ),
          FluentHorizontalBarChart(data: data),
        ],
      ),
    );
  }
}
// #enddocregion charts-horizontalbarchart--horizontal-bar-custom-callout

// #docregion charts-horizontalbarchart--horizontal-bar-stacked-annotated-inline-legend
// `FluentHorizontalBarChart` builds its legend strip from `data` and takes no
// `legendProps`, so upstream's per-legend `legendAnnotation` cannot hang off a
// legend row here. The annotations render as their own row beneath each
// chart's legend, with the same value badge and the same cursor-click toggle
// over the same names.
Widget _horizontalBarStackedAnnotatedInlineLegend(BuildContext context) {
  const List<List<List<String>>> annotationMeta = <List<List<String>>>[
    <List<String>>[
      <String>['Person 1', 'Person 2'],
    ],
    <List<String>>[
      <String>['Person 1', 'Person 20'],
      <String>['Person 30', 'Person 40'],
    ],
  ];

  final List<FluentChartData> dataTemplate = <FluentChartData>[
    FluentChartData(
      chartTitle: 'one',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'One.One',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 100),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        ),
      ],
    ),
    FluentChartData(
      chartTitle: 'two',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'Two.One',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 66),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        ),
        FluentChartDataPoint(
          legend: 'Two.Two',
          horizontalBarChartData: const FluentHorizontalDataPoint(x: 33),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color20),
        ),
      ],
    ),
  ];

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int group = 0; group < dataTemplate.length; group++) ...<Widget>[
          FluentHorizontalBarChart(
            data: <FluentChartData>[dataTemplate[group]],
            hideTooltip: true,
            chartDataMode: FluentChartDataMode.hidden,
            showLegendForSinglePointBar: true,
          ),
          Wrap(
            spacing: 16,
            children: <Widget>[
              for (
                int item = 0;
                item < dataTemplate[group].chartData!.length;
                item++
              )
                _AnnotationPopover(
                  names: annotationMeta[group][item],
                  value: dataTemplate[group]
                      .chartData![item]
                      .horizontalBarChartData!
                      .x,
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _AnnotationPopover extends StatefulWidget {
  const _AnnotationPopover({required this.names, this.value});

  final List<String> names;
  final double? value;

  @override
  State<_AnnotationPopover> createState() => _AnnotationPopoverState();
}

class _AnnotationPopoverState extends State<_AnnotationPopover> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: <Widget>[
      if (widget.value != null) Text('${widget.value!.toInt()}%'),
      Semantics(
        button: true,
        label: 'Show annotation',
        child: GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Icon(
            _isExpanded
                ? FluentIcons.cursor_click_20_regular
                : FluentIcons.cursor_click_20_filled,
            size: 16,
          ),
        ),
      ),
      if (_isExpanded)
        for (final String name in widget.names) Text(name),
    ],
  );
}

// #enddocregion charts-horizontalbarchart--horizontal-bar-stacked-annotated-inline-legend
