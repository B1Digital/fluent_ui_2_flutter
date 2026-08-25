import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The FunnelChart docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage funnelChartPage = DocsPage(
  id: 'charts-funnelchart',
  title: 'FunnelChart',
  description: '',
  source: 'lib/pages/charts_funnelchart.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-funnelchart--funnel-chart-basic',
      title: 'Funnel Chart Basic',
      builder: _funnelChartBasic,
    ),
    DocsSection(
      id: 'charts-funnelchart--funnel-chart-stacked',
      title: 'Funnel Chart Stacked',
      builder: _funnelChartStacked,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentFunnelDataPoint>',
      description:
          'The stages, widest first. When every entry carries subValues the '
          'chart renders stacked.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description: 'The visible title, painted above the funnel.',
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
      name: 'hideLegend',
      type: 'bool',
      defaultValue: 'false',
      description: 'Hides the legend strip, and with it the title.',
    ),
    PropRow(
      name: 'canSelectMultipleLegends',
      type: 'bool',
      defaultValue: 'false',
      description: 'Allows more than one legend to stay selected.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'The locale tag passed to formatToLocaleString.',
    ),
    PropRow(
      name: 'orientation',
      type: 'FluentFunnelOrientation',
      defaultValue: 'FluentFunnelOrientation.vertical',
      description: 'The direction the funnel\'s stages run in.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentFunnelChartStyle?',
      defaultValue: 'null',
      description:
          'The style layered over FluentFunnelChartTheme and the resolved '
          'defaults.',
    ),
  ],
);

// #docregion charts-funnelchart--funnel-chart-basic
Widget _funnelChartBasic(BuildContext context) => const _FunnelChartBasic();

class _FunnelChartBasic extends StatefulWidget {
  const _FunnelChartBasic();

  @override
  State<_FunnelChartBasic> createState() => _FunnelChartBasicState();
}

class _FunnelChartBasicState extends State<_FunnelChartBasic> {
  double _width = 600;
  double _height = 500;
  bool _hideLegend = false;
  FluentFunnelOrientation _orientation = FluentFunnelOrientation.horizontal;
  bool _legendMultiSelect = false;

  @override
  Widget build(BuildContext context) {
    final List<FluentFunnelDataPoint> basicData = <FluentFunnelDataPoint>[
      FluentFunnelDataPoint(
        stage: 'Visitors',
        value: 1000,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      ),
      FluentFunnelDataPoint(
        stage: 'Signups',
        value: 600,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      ),
      FluentFunnelDataPoint(
        stage: 'Trials',
        value: 300,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
      ),
      FluentFunnelDataPoint(
        stage: 'Customers',
        value: 250,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 12,
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
            FluentSwitch(
              checked: _hideLegend,
              label: const Text('Hide Legend'),
              onChanged: (bool value) => setState(() => _hideLegend = value),
            ),
            FluentSwitch(
              checked: _legendMultiSelect,
              label: const Text('Multiple Legend Selection'),
              onChanged: (bool value) =>
                  setState(() => _legendMultiSelect = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FluentField(
          label: const Text('Orientation'),
          child: FluentRadioGroup<FluentFunnelOrientation>(
            value: _orientation,
            onChanged: (FluentFunnelOrientation value) =>
                setState(() => _orientation = value),
            children: const <Widget>[
              FluentRadio<FluentFunnelOrientation>(
                value: FluentFunnelOrientation.horizontal,
                label: Text('Horizontal'),
              ),
              FluentRadio<FluentFunnelOrientation>(
                value: FluentFunnelOrientation.vertical,
                label: Text('Vertical'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: _width,
          height: _height,
          child: FluentFunnelChart(
            data: basicData,
            chartTitle: 'Basic Funnel Chart',
            hideLegend: _hideLegend,
            orientation: _orientation,
            canSelectMultipleLegends: _legendMultiSelect,
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-funnelchart--funnel-chart-basic

// #docregion charts-funnelchart--funnel-chart-stacked
Widget _funnelChartStacked(BuildContext context) => const _FunnelChartStacked();

class _FunnelChartStacked extends StatefulWidget {
  const _FunnelChartStacked();

  @override
  State<_FunnelChartStacked> createState() => _FunnelChartStackedState();
}

class _FunnelChartStackedState extends State<_FunnelChartStacked> {
  double _width = 600;
  double _height = 500;
  bool _hideLegend = false;
  FluentFunnelOrientation _orientation = FluentFunnelOrientation.horizontal;
  bool _legendMultiSelect = false;

  @override
  Widget build(BuildContext context) {
    final List<FluentFunnelDataPoint> stackedData = <FluentFunnelDataPoint>[
      FluentFunnelDataPoint(
        stage: 'Visit',
        subValues: <FluentFunnelSubValue>[
          FluentFunnelSubValue(
            category: 'A',
            value: 100,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          ),
          FluentFunnelSubValue(
            category: 'B',
            value: 80,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          ),
          FluentFunnelSubValue(
            category: 'C',
            value: 50,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
          ),
          FluentFunnelSubValue(
            category: 'D',
            value: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          ),
        ],
      ),
      FluentFunnelDataPoint(
        stage: 'Sign-Up',
        subValues: <FluentFunnelSubValue>[
          FluentFunnelSubValue(
            category: 'A',
            value: 60,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          ),
          FluentFunnelSubValue(
            category: 'B',
            value: 40,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          ),
          FluentFunnelSubValue(
            category: 'C',
            value: 20,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
          ),
          FluentFunnelSubValue(
            category: 'D',
            value: 10,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          ),
        ],
      ),
      FluentFunnelDataPoint(
        stage: 'Purchase',
        subValues: <FluentFunnelSubValue>[
          FluentFunnelSubValue(
            category: 'A',
            value: 30,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          ),
          FluentFunnelSubValue(
            category: 'B',
            value: 20,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          ),
          FluentFunnelSubValue(
            category: 'C',
            value: 10,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
          ),
          FluentFunnelSubValue(
            category: 'D',
            value: 5,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: 12,
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
            FluentSwitch(
              checked: _hideLegend,
              label: const Text('Hide Legend'),
              onChanged: (bool value) => setState(() => _hideLegend = value),
            ),
            FluentSwitch(
              checked: _legendMultiSelect,
              label: const Text('Multiple Legend Selection'),
              onChanged: (bool value) =>
                  setState(() => _legendMultiSelect = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FluentField(
          label: const Text('Orientation'),
          child: FluentRadioGroup<FluentFunnelOrientation>(
            value: _orientation,
            onChanged: (FluentFunnelOrientation value) =>
                setState(() => _orientation = value),
            children: const <Widget>[
              FluentRadio<FluentFunnelOrientation>(
                value: FluentFunnelOrientation.horizontal,
                label: Text('Horizontal'),
              ),
              FluentRadio<FluentFunnelOrientation>(
                value: FluentFunnelOrientation.vertical,
                label: Text('Vertical'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: _width,
          height: _height,
          child: FluentFunnelChart(
            data: stackedData,
            chartTitle: 'Stacked Funnel Chart',
            hideLegend: _hideLegend,
            orientation: _orientation,
            canSelectMultipleLegends: _legendMultiSelect,
          ),
        ),
      ],
    );
  }
}

// #enddocregion charts-funnelchart--funnel-chart-stacked
