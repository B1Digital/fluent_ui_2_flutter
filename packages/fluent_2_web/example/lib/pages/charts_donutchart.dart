import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The DonutChart docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage donutChartPage = DocsPage(
  id: 'charts-donutchart',
  title: 'DonutChart',
  description:
      'Donut charts are used to show proportion, which expresses a '
      'partial value in comparison to a total value. These types of '
      'charts are best to show percentage of individual parts in '
      'comparison to a whole, where the change over time is not '
      'important to visualize. They are circular statistical graphics '
      'divided into slices to illustrate numerical proportion.',
  source: 'lib/pages/charts_donutchart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          '- The donut chart’s behavior is simple in application. The '
          'data is ordered from largest to smallest in clockwise '
          'direction and users can single out individual segments for '
          'clarity.\n'
          '- For high cardinality scenarios where the slices are very '
          'small, they can be grouped together to form a bigger slice '
          'to improve readability.\n'
          '- The chart is centered in the available screen space. The '
          'default chart diameter is 140px and bar width is 16px. This '
          'matches the width of bars in bar charts to achieve balanced '
          'scale. The size can be adjusted with responsive chart '
          'behavior, where the size of the chart and bar diameter grows '
          'proportionally in units of 4px.\n'
          '- Always try to balance the visual weight of the bars in '
          'relationship to the rest of the app.\n'
          '- Segments are separated by a 2px gap to maximize '
          'readability. Segment labels should be always displayed for '
          'easier chart comprehension.\n'
          '- Minimum padding around the chart is 16px. It also applies '
          'to the version with labels to accommodate space for labels. '
          'There is a 2px space between the chart and the label. The '
          'label is centered in relationship to the slice it describes. '
          'That can be offset if an overlap happens between 2 labels.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- The donut chart consists of segments arranged clockwise '
          'from large to small. The total circle equates to 100% of the '
          'data. The segments can use custom formatting, but all values '
          'must add up to 100%. Tiny segments may be grouped and shown '
          'visually as \'Others\'.\n'
          '- The label string inside the donut should be concise and '
          'contain numerical information with limited or no '
          'explanation.\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          '- Users "Enter" into the graph and can use both arrowing and '
          'tabbing to navigate through.\n'
          '- The first tab stop will stop on the graph and give a '
          'description of what type of graph it is.\n'
          '- Each segment can define its own accessibility label to '
          'help the user understand the data better.\n',
    ),
    ProseBlock(
      title: 'Do\'s',
      body:
          '- For scenarios with lots of categories, consider changing '
          'the type of graph to a stacked horizontal bar chart.\n'
          '- We recommend donut charts over pie charts as they are more '
          'readable.\n',
    ),
    ProseBlock(
      title: 'Dont\'s',
      body:
          '- Don\'t overuse donuts charts. They require a lot of space '
          'on the page and using more than one next to each other '
          'dilutes the intended message.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-donutchart--donut-chart-basic',
      title: 'Donut Chart Basic',
      builder: _donutChartBasic,
    ),
    DocsSection(
      id: 'charts-donutchart--donut-chart-custom-accessibility',
      title: 'Donut Chart Custom Accessibility',
      builder: _donutChartCustomAccessibility,
    ),
    DocsSection(
      id: 'charts-donutchart--donut-chart-dynamic',
      title: 'Donut Chart Dynamic',
      builder: _donutChartDynamic,
    ),
    DocsSection(
      id: 'charts-donutchart--donut-chart-custom-callout',
      title: 'Donut Chart Custom Callout',
      description: 'Donut Chart Story.',
      builder: _donutChartCustomCallout,
    ),
    DocsSection(
      id: 'charts-donutchart--donut-chart-styled',
      title: 'Donut Chart Styled',
      builder: _donutChartStyled,
    ),
    DocsSection(
      id: 'charts-donutchart--donut-chart-responsive',
      title: 'Donut Chart Responsive',
      builder: _donutChartResponsive,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'FluentChartData',
      description: 'The chart data. Only chartData is read.',
    ),
    PropRow(
      name: 'innerRadius',
      type: 'double',
      defaultValue: '0',
      description: 'The hole\'s radius in logical pixels, not a fraction.',
    ),
    PropRow(
      name: 'hideLabels',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the per-arc value labels are suppressed.',
    ),
    PropRow(
      name: 'showLabelsInPercent',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the arc labels read as percentages of the total.',
    ),
    PropRow(
      name: 'valueInsideDonut',
      type: 'Object?',
      defaultValue: 'null',
      description:
          'The string drawn in the hole, shown only above the minimum donut '
          'radius.',
    ),
    PropRow(
      name: 'width',
      type: 'double?',
      defaultValue: 'null',
      description: 'Plot width, or null to fill the incoming constraints.',
    ),
    PropRow(
      name: 'height',
      type: 'double?',
      defaultValue: 'null',
      description: 'Plot height, or null to fill the incoming constraints.',
    ),
    PropRow(
      name: 'hideLegend',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the legend strip — and with it the title — is suppressed.',
    ),
    PropRow(
      name: 'hideTooltip',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the hover popover is suppressed.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'Locale for the centre value.',
    ),
    PropRow(
      name: 'order',
      type: 'FluentDonutOrder',
      defaultValue: 'FluentDonutOrder.byDefault',
      description: 'Legend ordering — input order, or descending by value.',
    ),
    PropRow(
      name: 'canSelectMultipleLegends',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether several legends may be selected at once.',
    ),
    PropRow(
      name: 'legendsOverflowText',
      type: 'String',
      defaultValue: "'more'",
      description: 'The word in the legend overflow trigger.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentDonutChartStyle?',
      defaultValue: 'null',
      description:
          'Style layered over the derived defaults and the nearest '
          'FluentDonutChartTheme.',
    ),
  ],
);

// #docregion charts-donutchart--donut-chart-basic
Widget _donutChartBasic(BuildContext context) {
  final List<FluentChartDataPoint> points = <FluentChartDataPoint>[
    FluentChartDataPoint(
      legend: 'first',
      data: 20000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      xAxisCalloutData: '2020/04/30',
    ),
    FluentChartDataPoint(
      legend: 'second',
      data: 35000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      xAxisCalloutData: '2020/04/20',
    ),
  ];

  final FluentChartData data = FluentChartData(
    chartTitle: 'Donut chart basic example',
    chartData: points,
  );

  // Two upstream props have no Flutter counterpart and are dropped: `href`,
  // which turns the whole plot into a link, and the browser's own
  // `window.navigator.language`, whose fallback string is passed instead.
  // The chart fills its box, so the box is what sets the overall height —
  // `height` still sizes the plot inside it, exactly as upstream.
  return SizedBox(
    height: 300,
    child: FluentDonutChart(
      culture: 'en-us',
      data: data,
      innerRadius: 55,
      legendsOverflowText: 'overflow Items',
      hideLegend: false,
      height: 220,
      valueInsideDonut: 35000,
    ),
  );
}

// #enddocregion charts-donutchart--donut-chart-basic

// #docregion charts-donutchart--donut-chart-custom-accessibility
Widget _donutChartCustomAccessibility(BuildContext context) {
  final List<FluentChartDataPoint> points = <FluentChartDataPoint>[
    FluentChartDataPoint(
      legend: 'first',
      data: 20000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color16),
      xAxisCalloutData: '2020/04/30',
      callOutSemantics: const FluentChartSemantics(
        label: 'Pia chart 1 of 2 2020/04/30',
      ),
    ),
    FluentChartDataPoint(
      legend: 'second',
      data: 39000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      xAxisCalloutData: '2020/04/20',
      callOutSemantics: const FluentChartSemantics(
        label: 'Pia chart 2 of 2 2020/04/20',
      ),
    ),
  ];

  final FluentChartData data = FluentChartData(
    chartTitle: 'Donut chart custom accessibility example',
    chartData: points,
    chartTitleSemantics: const FluentChartSemantics(
      label: 'Bar chart depicting about Donut chart',
    ),
  );

  return SizedBox(
    height: 300,
    child: FluentDonutChart(
      data: data,
      innerRadius: 55,
      legendsOverflowText: 'overflow Items',
      hideLegend: false,
      height: 220,
      valueInsideDonut: 39000,
    ),
  );
}

// #enddocregion charts-donutchart--donut-chart-custom-accessibility

// #docregion charts-donutchart--donut-chart-dynamic
Widget _donutChartDynamic(BuildContext context) => const _DonutChartDynamic();

class _DonutChartDynamic extends StatefulWidget {
  const _DonutChartDynamic();

  @override
  State<_DonutChartDynamic> createState() => _DonutChartDynamicState();
}

class _DonutChartDynamicState extends State<_DonutChartDynamic> {
  static const List<List<FluentDataVizToken>> _colors =
      <List<FluentDataVizToken>>[
        <FluentDataVizToken>[
          FluentDataVizToken.color3,
          FluentDataVizToken.color4,
          FluentDataVizToken.color5,
          FluentDataVizToken.color6,
          FluentDataVizToken.color7,
        ],
        <FluentDataVizToken>[
          FluentDataVizToken.color8,
          FluentDataVizToken.color9,
          FluentDataVizToken.color10,
          FluentDataVizToken.color11,
        ],
        <FluentDataVizToken>[
          FluentDataVizToken.color12,
          FluentDataVizToken.color13,
          FluentDataVizToken.color14,
          FluentDataVizToken.color15,
        ],
        <FluentDataVizToken>[
          FluentDataVizToken.color16,
          FluentDataVizToken.color17,
          FluentDataVizToken.color18,
        ],
      ];

  List<FluentChartDataPoint> _dynamicData = <FluentChartDataPoint>[
    FluentChartDataPoint(
      legend: 'first',
      data: 40,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
    ),
    FluentChartDataPoint(
      legend: 'second',
      data: 20,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
    ),
    FluentChartDataPoint(
      legend: 'third',
      data: 30,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
    ),
    FluentChartDataPoint(
      legend: 'fourth',
      data: 10,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
    ),
  ];
  bool _hideLabels = false;
  bool _showLabelsInPercent = false;
  double _innerRadius = 35;
  String _statusMessage = '';

  // `Math.random` upstream. `dart:math` is outside this example's imports, so
  // the jitter comes from the clock, stirred so that four calls in the same
  // microsecond still differ.
  int _tick = 0;

  int _random(int max) {
    _tick = (_tick * 31 + DateTime.now().microsecondsSinceEpoch) % 100003;
    return _tick % max;
  }

  double _randomY([int max = 300]) => _random(max) + 5;

  Color _randomColor(int index) => FluentDataVizPalette.resolve(
    _colors[index][_random(_colors[index].length)],
  );

  void _changeData() {
    setState(() {
      _dynamicData = <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'first',
          data: _randomY(),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        ),
        FluentChartDataPoint(
          legend: 'second',
          data: _randomY(),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        ),
        FluentChartDataPoint(
          legend: 'third',
          data: _randomY(),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        ),
        FluentChartDataPoint(
          legend: 'fourth',
          data: _randomY(),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        ),
      ];
      _statusMessage = 'Donut chart data changed';
    });
  }

  void _changeColors() {
    setState(() {
      _dynamicData = <FluentChartDataPoint>[
        FluentChartDataPoint(legend: 'first', data: 40, color: _randomColor(0)),
        FluentChartDataPoint(
          legend: 'second',
          data: 20,
          color: _randomColor(1),
        ),
        FluentChartDataPoint(legend: 'third', data: 30, color: _randomColor(2)),
        FluentChartDataPoint(
          legend: 'fourth',
          data: 10,
          color: _randomColor(3),
        ),
      ];
      _statusMessage = 'Donut chart colors changed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final FluentChartData data = FluentChartData(
      chartTitle: 'Donut chart dynamic example',
      chartData: _dynamicData,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FluentCheckbox(
          // A Row lays its label out unbounded, so the box that lets this
          // sentence wrap has to be the label's own.
          label: const SizedBox(
            width: 600,
            child: Text(
              'Hide labels (Note: The inner radius is changed along with this '
              'to keep the arc width same)',
            ),
          ),
          checked: _hideLabels,
          onChanged: (bool? checked) => setState(() {
            _hideLabels = checked ?? false;
            _innerRadius = _hideLabels ? 55 : 35;
          }),
        ),
        const SizedBox(height: 10),
        FluentCheckbox(
          label: const Text('Show labels in percentage format'),
          checked: _showLabelsInPercent,
          onChanged: (bool? checked) =>
              setState(() => _showLabelsInPercent = checked ?? false),
        ),
        SizedBox(
          height: 330,
          child: FluentDonutChart(
            data: data,
            innerRadius: _innerRadius,
            hideLabels: _hideLabels,
            showLabelsInPercent: _showLabelsInPercent,
            height: 248,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FluentButton(
              onPressed: _changeData,
              child: const Text('Change data'),
            ),
            const SizedBox(width: 8),
            FluentButton(
              onPressed: _changeColors,
              child: const Text('Change colors'),
            ),
          ],
        ),
        // Upstream parks the same sentence in a visually hidden `aria-live`
        // paragraph; a live region with no visible child is how Flutter spells
        // that.
        Semantics(
          liveRegion: true,
          label: _statusMessage,
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// #enddocregion charts-donutchart--donut-chart-dynamic

// #docregion charts-donutchart--donut-chart-custom-callout
Widget _donutChartCustomCallout(BuildContext context) =>
    const _DonutChartCustomCallout();

class _DonutChartCustomCallout extends StatefulWidget {
  const _DonutChartCustomCallout();

  @override
  State<_DonutChartCustomCallout> createState() =>
      _DonutChartCustomCalloutState();
}

class _DonutChartCustomCalloutState extends State<_DonutChartCustomCallout> {
  bool _useCustomPopover = false;

  @override
  Widget build(BuildContext context) {
    final List<FluentChartDataPoint> points = <FluentChartDataPoint>[
      FluentChartDataPoint(
        legend: 'first',
        data: 20000,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
        xAxisCalloutData: '2020/04/30',
        callOutSemantics: const FluentChartSemantics(
          label: 'Custom XVal Custom Legend 20000h',
        ),
      ),
      FluentChartDataPoint(
        legend: 'second',
        data: 39000,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        xAxisCalloutData: '2020/04/20',
        callOutSemantics: const FluentChartSemantics(
          label: 'Custom XVal Custom Legend 39000h',
        ),
      ),
    ];

    final FluentChartData data = FluentChartData(
      chartTitle: 'Donut chart custom callout example',
      chartData: points,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FluentSwitch(
          label: const Text('User Popover Override'),
          checked: _useCustomPopover,
          onChanged: (bool checked) =>
              setState(() => _useCustomPopover = checked),
        ),
        // Upstream swaps the hover popover through `calloutPropsPerDataPoint`
        // and `onRenderCalloutPerDataPoint`. FluentDonutChart owns its popover
        // and exposes neither hook, so the switch is live and the popover it
        // would replace stays the built-in one.
        SizedBox(
          height: 300,
          child: FluentDonutChart(
            data: data,
            innerRadius: 55,
            legendsOverflowText: 'overflow Items',
            hideLegend: false,
            height: 220,
            valueInsideDonut: 39000,
          ),
        ),
      ],
    );
  }
}

// #enddocregion charts-donutchart--donut-chart-custom-callout

// #docregion charts-donutchart--donut-chart-styled
/// The height the styled frame occupies, which the ellipse below is solved on.
const double _styledFrameHeight = 320;

Widget _donutChartStyled(BuildContext context) {
  final List<FluentChartDataPoint> points = <FluentChartDataPoint>[
    FluentChartDataPoint(
      legend: 'first',
      data: 20000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      xAxisCalloutData: '2020/04/30',
    ),
    FluentChartDataPoint(
      legend: 'second',
      data: 39000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      xAxisCalloutData: '2020/04/20',
    ),
  ];

  final FluentChartData data = FluentChartData(
    chartTitle: 'Donut chart styled example',
    chartData: points,
  );

  // Upstream's `makeStyles` rule is a 2px border, `border-radius: 50%`, 10px of
  // padding and a filled background. On a box wider than it is tall that radius
  // is an ellipse, which Flutter spells with explicit radii — `BoxShape.circle`
  // would inscribe a circle on the shorter side instead.
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => Container(
      height: _styledFrameHeight,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FluentDataVizPalette.resolve(FluentDataVizToken.disabled),
        border: Border.all(
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
          width: 2,
        ),
        borderRadius: BorderRadius.all(
          Radius.elliptical(constraints.maxWidth / 2, _styledFrameHeight / 2),
        ),
      ),
      child: FluentDonutChart(
        culture: 'en-us',
        data: data,
        innerRadius: 55,
        legendsOverflowText: 'overflow Items',
        hideLegend: false,
        height: 220,
        valueInsideDonut: 39000,
      ),
    ),
  );
}

// #enddocregion charts-donutchart--donut-chart-styled

// #docregion charts-donutchart--donut-chart-responsive
Widget _donutChartResponsive(BuildContext context) {
  final List<FluentChartDataPoint> points = <FluentChartDataPoint>[
    FluentChartDataPoint(
      legend: 'first',
      data: 20000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      xAxisCalloutData: '2020/04/30',
    ),
    FluentChartDataPoint(
      legend: 'second',
      data: 39000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      xAxisCalloutData: '2020/04/20',
    ),
    FluentChartDataPoint(
      legend: 'third',
      data: 12000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      xAxisCalloutData: '2020/04/20',
    ),
    FluentChartDataPoint(
      legend: 'fourth',
      data: 2000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
      xAxisCalloutData: '2020/04/20',
    ),
    FluentChartDataPoint(
      legend: 'fifth',
      data: 5000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      xAxisCalloutData: '2020/04/20',
    ),
    FluentChartDataPoint(
      legend: 'sixth',
      data: 6000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      xAxisCalloutData: '2020/04/20',
    ),
    FluentChartDataPoint(
      legend: 'seventh',
      data: 7000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
      xAxisCalloutData: '2020/04/20',
    ),
    FluentChartDataPoint(
      legend: 'eighth',
      data: 8000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
      xAxisCalloutData: '2020/04/20',
    ),
    FluentChartDataPoint(
      legend: 'ninth',
      data: 9000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
      xAxisCalloutData: '2020/04/20',
    ),
    FluentChartDataPoint(
      legend: 'tenth',
      data: 10000,
      color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
      xAxisCalloutData: '2020/04/20',
    ),
  ];

  final FluentChartData data = FluentChartData(
    chartTitle: 'Donut chart basic example',
    chartData: points,
  );

  // Upstream wraps this in a `ResponsiveContainer`. FluentDonutChart already
  // fills whatever box it is given whenever `width` and `height` are omitted,
  // so the container is just the box: the plot tracks the width it is handed.
  return SizedBox(
    height: 350,
    child: FluentDonutChart(
      data: data,
      innerRadius: 55,
      valueInsideDonut: 39000,
    ),
  );
}

// #enddocregion charts-donutchart--donut-chart-responsive
