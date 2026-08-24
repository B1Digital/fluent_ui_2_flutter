import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The GaugeChart docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage gaugeChartPage = DocsPage(
  id: 'charts-gaugechart',
  title: 'GaugeChart',
  description:
      'A radial gauge chart uses a circular arc to show how a single '
      'value progresses toward a goal or a Key Performance Indicator '
      '(KPI). The gauge line (or needle) represents the goal or target '
      'value. The shading represents progress toward the goal. The '
      'value inside the arc represents the progress value. There are '
      'two types of gauge charts: Speedometer and rating meter. The '
      'speedometer measures a numerical value against a whole, like '
      'storage capacity. The needle is an optional component. The color '
      'of the segment representing the value being measured can be '
      'customized by product teams to suit certain scenarios or to '
      'align with branding colors. The rating meter shows status of the '
      'current value within a few predefined ranges or segments. The '
      'needle is a required component here. The segment sizes and '
      'colors can be customized by the product team to suit their '
      'needs.',
  source: 'lib/pages/charts_gaugechart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'The library recommends a few size width and height options '
          'for charts. Product teams must consider the complexity of '
          'the data to decide what size should be used in '
          'implementation. There are 6 size options for the gauge, '
          'ranging from very small to very large. The default size is '
          'medium, with a diameter of 140px and default bar width of '
          '16px. All have a margin of 16px on all sides.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- **Bar** This is the arc representing the semi-circle.\n'
          '- **Min and max values** Used to represent minimum and '
          'maximum values for the data being measured. These can either '
          'be an absolute value or a percentage.\n'
          '- **Data segment** This represents the current value as a '
          'part of the whole scale. For rating meter, it shows the '
          'relative scale of each segment.\n'
          '- **Current value indicator / needle** Used to show user’s '
          'position on the semi-circular graph.\n'
          '- **Chart value** This can be a number out of another (part '
          'to whole) or represented as a percentage.\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          '- Users \'Enter\' into the graph and can use both arrowing '
          'and tabbing to navigate through.\n'
          '- The first tab stop will stop on the graph and give a '
          'description of what type of graph it is.\n'
          '- Each section of the graph is readable via a screen reader.\n',
    ),
    ProseBlock(
      title: 'Customizing the chart',
      body:
          '- `width` and `height`: These props determine the diameter '
          'of the gauge. If not provided, a default diameter of 140px '
          'is used.\n'
          'chartTitle: Use this prop to render a title above the gauge.\n'
          '- `chartValue`: This required prop controls the rotation of '
          'the needle. If the chart value is less than the minimum, the '
          'needle points to the min value. Similarly, if it exceeds the '
          'maximum, the needle points to the max value.\n'
          '- `segments`: Use this required prop to divide the gauge '
          'into colored sections. The segments can have fixed sizes or '
          'vary with the chart value to create a sweeping effect. '
          'Negative segment sizes are treated as 0.\n'
          '- `minValue`: Use this prop if the minimum value of the '
          'gauge is different from 0.\n'
          '- `maxValue`: Use this prop to render a placeholder segment '
          'when the desired range for the gauge is more than the sum of '
          'all segments. If the maxValue is less than the sum of all '
          'segments, this property is ignored.\n'
          '- `sublabel`: Use this prop to render additional text below '
          'the chart value.\n'
          '- `hideMinMax`: Set this prop to true to hide the min and '
          'max labels of the gauge.\n'
          '- `chartValueFormat`: This prop controls how the chart value '
          'is displayed. Set it to one of the following options:\n'
          '- A custom formatter function that returns a string '
          'representing the chart value.\n'
          '- `fraction`: Renders the chart value as a fraction.\n'
          '- `percentage`: Renders the chart value as a percentage. '
          'This is the default format.\n'
          'Note: If the min value is non-zero and no formatter function '
          'is provided, the chart value will be rendered as a number.\n'
          '- `variant`: This prop determines the presentation style of '
          'the gauge chart. Set it to one of the following options:\n'
          '- `single-segment`: This variant helps represent a single '
          'metric or key performance indicator (KPI) within a '
          'predefined range or target. In this variant, the segment '
          'sizes are rendered as percentages.\n'
          '- `multiple-segments`: This is the default variant that '
          'helps display the distribution of a single variable across '
          'different thresholds or categories. In this variant, the '
          'segment sizes are rendered as ranges.\n',
    ),
    ProseBlock(
      title: 'Do\'s',
      body:
          '- Display min and max values to the left and the right if '
          'you’re showing a percentage within the gauge.\n',
    ),
    ProseBlock(
      title: 'Don\'ts',
      body:
          '- Don’t add min and mix if you’re already representing the '
          'part to whole ratio within the gauge because it’s redundant.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-gaugechart--gauge-chart-basic',
      title: 'Gauge Chart Basic',
      builder: _gaugeChartBasic,
    ),
    DocsSection(
      id: 'charts-gaugechart--gauge-chart-single-segment',
      title: 'Gauge Chart Single Segment',
      builder: _gaugeChartSingleSegment,
    ),
    DocsSection(
      id: 'charts-gaugechart--gauge-chart-responsive',
      title: 'Gauge Chart Responsive',
      builder: _gaugeChartResponsive,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'chartValue',
      type: 'double',
      description:
          'Where the needle points, in the same units as the segments.',
    ),
    PropRow(
      name: 'segments',
      type: 'List<FluentGaugeChartSegment>',
      description: 'The segments, in sweep order from the minimum.',
    ),
    PropRow(
      name: 'minValue',
      type: 'double',
      defaultValue: '0',
      description: 'The value at the left end of the arc.',
    ),
    PropRow(
      name: 'maxValue',
      type: 'double?',
      defaultValue: 'null',
      description:
          'The value at the right end. When it exceeds the segment total an '
          'Unknown filler segment covers the difference.',
    ),
    PropRow(
      name: 'width',
      type: 'double?',
      defaultValue: 'null',
      description: 'An explicit width, overriding the incoming constraints.',
    ),
    PropRow(
      name: 'height',
      type: 'double?',
      defaultValue: 'null',
      description: 'An explicit height, overriding the incoming constraints.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description: 'The visible title, painted above the arc.',
    ),
    PropRow(
      name: 'sublabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'A caption below the chart value.',
    ),
    PropRow(
      name: 'hideMinMax',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Hides both limit labels, which also shrinks the side margins to the '
          'bare gauge margin.',
    ),
    PropRow(
      name: 'chartValueFormat',
      type: 'Object?',
      defaultValue: 'null',
      description:
          'Either a FluentGaugeValueFormat or a String Function(double swept, '
          'double span).',
    ),
    PropRow(
      name: 'hideLegend',
      type: 'bool',
      defaultValue: 'false',
      description: 'Hides the legend strip and reclaims its height.',
    ),
    PropRow(
      name: 'hideTooltip',
      type: 'bool',
      defaultValue: 'false',
      description: 'Suppresses the popover entirely.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'The locale tag used to format popover text.',
    ),
    PropRow(
      name: 'variant',
      type: 'FluentGaugeChartVariant',
      defaultValue: 'FluentGaugeChartVariant.multipleSegments',
      description: 'Chooses the segment-label form.',
    ),
    PropRow(
      name: 'roundCorners',
      type: 'bool',
      defaultValue: 'false',
      description: 'Rounds the arc ends.',
    ),
    PropRow(
      name: 'canSelectMultipleLegends',
      type: 'bool',
      defaultValue: 'false',
      description: 'Allows more than one legend to stay selected.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentGaugeChartStyle?',
      defaultValue: 'null',
      description:
          'The style layered over FluentGaugeChartTheme and the resolved '
          'defaults.',
    ),
  ],
);

// #docregion charts-gaugechart--gauge-chart-basic
Widget _gaugeChartBasic(BuildContext context) => const _GaugeChartBasic();

class _GaugeChartBasic extends StatefulWidget {
  const _GaugeChartBasic();

  @override
  State<_GaugeChartBasic> createState() => _GaugeChartBasicState();
}

class _GaugeChartBasicState extends State<_GaugeChartBasic> {
  double _width = 252;
  double _height = 128;
  double _chartValue = 50;
  bool _hideMinMax = false;
  bool _enableGradient = false;
  bool _roundedCorners = false;
  bool _legendMultiSelect = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 20,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Width:'),
              SizedBox(
                width: 160,
                child: FluentSlider(
                  value: _width,
                  min: 0,
                  max: 1000,
                  step: 1,
                  semanticLabel: 'Change Width',
                  onChanged: (double value) => setState(() => _width = value),
                ),
              ),
              Text('${_width.round()}'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Height:'),
              SizedBox(
                width: 160,
                child: FluentSlider(
                  value: _height,
                  min: 0,
                  max: 1000,
                  step: 1,
                  semanticLabel: 'Change Height',
                  onChanged: (double value) => setState(() => _height = value),
                ),
              ),
              Text('${_height.round()}'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Current value:'),
              SizedBox(
                width: 160,
                child: FluentSlider(
                  value: _chartValue,
                  min: 0,
                  max: 100,
                  step: 1,
                  semanticLabel: 'Change Current Value',
                  onChanged: (double value) =>
                      setState(() => _chartValue = value),
                ),
              ),
              Text('${_chartValue.round()}'),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      FluentCheckbox(
        label: const Text('Hide min and max values'),
        checked: _hideMinMax,
        onChanged: (bool? checked) =>
            setState(() => _hideMinMax = checked ?? false),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: <Widget>[
          // `enableGradient` has no counterpart on `FluentGaugeChart`: our port
          // paints flat segment fills. The switch stays so the section keeps
          // upstream's control set, and it drives nothing.
          FluentSwitch(
            checked: _enableGradient,
            label: Text(
              _enableGradient ? 'Enable Gradient' : 'Disable Gradient',
            ),
            onChanged: (bool value) => setState(() => _enableGradient = value),
          ),
          FluentSwitch(
            checked: _roundedCorners,
            label: Text(
              _roundedCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
            ),
            onChanged: (bool value) => setState(() => _roundedCorners = value),
          ),
          FluentSwitch(
            checked: _legendMultiSelect,
            label: Text(
              _legendMultiSelect
                  ? 'legendMultiSelect ON'
                  : 'legendMultiSelect OFF',
            ),
            onChanged: (bool value) =>
                setState(() => _legendMultiSelect = value),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // The chart's own Column needs a bounded box, so the width and height
      // ride on a SizedBox rather than on the widget's own props — same result,
      // since the two would be the same number.
      SizedBox(
        width: _width,
        height: _height,
        child: FluentGaugeChart(
          segments: <FluentGaugeChartSegment>[
            FluentGaugeChartSegment(
              size: 33,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.success),
              legend: 'Low Risk',
            ),
            FluentGaugeChartSegment(
              size: 34,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.warning),
              legend: 'Medium Risk',
            ),
            FluentGaugeChartSegment(
              size: 33,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.error),
              legend: 'High Risk',
            ),
          ],
          chartValue: _chartValue,
          hideMinMax: _hideMinMax,
          variant: FluentGaugeChartVariant.multipleSegments,
          roundCorners: _roundedCorners,
          canSelectMultipleLegends: _legendMultiSelect,
        ),
      ),
    ],
  );
}
// #enddocregion charts-gaugechart--gauge-chart-basic

// #docregion charts-gaugechart--gauge-chart-single-segment
Widget _gaugeChartSingleSegment(BuildContext context) =>
    const _GaugeChartSingleSegment();

class _GaugeChartSingleSegment extends StatefulWidget {
  const _GaugeChartSingleSegment();

  @override
  State<_GaugeChartSingleSegment> createState() =>
      _GaugeChartSingleSegmentState();
}

class _GaugeChartSingleSegmentState extends State<_GaugeChartSingleSegment> {
  double _width = 252;
  double _height = 173;
  double _chartValue = 50;
  bool _enableGradient = false;
  bool _roundedCorners = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 20,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Width:'),
              SizedBox(
                width: 160,
                child: FluentSlider(
                  value: _width,
                  min: 0,
                  max: 1000,
                  step: 1,
                  semanticLabel: 'Change Width',
                  onChanged: (double value) => setState(() => _width = value),
                ),
              ),
              Text('${_width.round()}'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Height:'),
              SizedBox(
                width: 160,
                child: FluentSlider(
                  value: _height,
                  min: 0,
                  max: 1000,
                  step: 1,
                  semanticLabel: 'Change Height',
                  onChanged: (double value) => setState(() => _height = value),
                ),
              ),
              Text('${_height.round()}'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Current value:'),
              SizedBox(
                width: 160,
                child: FluentSlider(
                  value: _chartValue,
                  min: 0,
                  max: 100,
                  step: 1,
                  semanticLabel: 'Change Current Value',
                  onChanged: (double value) =>
                      setState(() => _chartValue = value),
                ),
              ),
              Text('${_chartValue.round()}'),
            ],
          ),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: <Widget>[
          // `enableGradient` has no counterpart on `FluentGaugeChart`: our port
          // paints flat segment fills. The switch stays so the section keeps
          // upstream's control set, and it drives nothing.
          FluentSwitch(
            checked: _enableGradient,
            label: Text(
              _enableGradient ? 'Enable Gradient' : 'Disable Gradient',
            ),
            onChanged: (bool value) => setState(() => _enableGradient = value),
          ),
          FluentSwitch(
            checked: _roundedCorners,
            label: Text(
              _roundedCorners ? 'Rounded Corners ON' : 'Rounded Corners OFF',
            ),
            onChanged: (bool value) => setState(() => _roundedCorners = value),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // The chart's own Column needs a bounded box, so the width and height
      // ride on a SizedBox rather than on the widget's own props — same result,
      // since the two would be the same number.
      SizedBox(
        width: _width,
        height: _height,
        child: FluentGaugeChart(
          segments: <FluentGaugeChartSegment>[
            FluentGaugeChartSegment(size: _chartValue, legend: 'Used'),
            FluentGaugeChartSegment(
              size: 100 - _chartValue,
              color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
              legend: 'Available',
            ),
          ],
          chartValue: _chartValue,
          chartTitle: 'Storage capacity',
          sublabel: 'used',
          chartValueFormat: FluentGaugeValueFormat.fraction,
          variant: FluentGaugeChartVariant.singleSegment,
          roundCorners: _roundedCorners,
        ),
      ),
    ],
  );
}
// #enddocregion charts-gaugechart--gauge-chart-single-segment

// #docregion charts-gaugechart--gauge-chart-responsive
// Upstream wraps this in a `ResponsiveContainer`. FluentGaugeChart already
// fills whatever box it is given whenever `width` and `height` are omitted, so
// the container is just the box: the gauge tracks the width it is handed.
Widget _gaugeChartResponsive(BuildContext context) => SizedBox(
  height: 128,
  child: FluentGaugeChart(
    segments: <FluentGaugeChartSegment>[
      FluentGaugeChartSegment(
        size: 33,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.success),
        legend: 'Low Risk',
      ),
      FluentGaugeChartSegment(
        size: 34,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.warning),
        legend: 'Medium Risk',
      ),
      FluentGaugeChartSegment(
        size: 33,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.error),
        legend: 'High Risk',
      ),
    ],
    chartValue: 75,
    variant: FluentGaugeChartVariant.multipleSegments,
  ),
);
// #enddocregion charts-gaugechart--gauge-chart-responsive
