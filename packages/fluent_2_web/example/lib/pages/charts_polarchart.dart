import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The PolarChart docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage polarChartPage = DocsPage(
  id: 'charts-polarchart',
  title: 'PolarChart',
  description: '',
  source: 'lib/pages/charts_polarchart.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-polarchart--polar-chart-basic',
      title: 'Polar Chart Basic',
      builder: _polarChartBasic,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'List<FluentPolarSeries>',
      description: 'The series to draw, discriminated by their runtime type.',
    ),
    PropRow(
      name: 'width',
      type: 'double?',
      defaultValue: 'null',
      description:
          'Hard width override. Null means the chart takes its '
          'constraint.',
    ),
    PropRow(
      name: 'height',
      type: 'double?',
      defaultValue: 'null',
      description:
          'Hard height override, applied before the legend strip is '
          'subtracted.',
    ),
    PropRow(
      name: 'margins',
      type: 'FluentChartMargins',
      defaultValue: 'FluentChartMargins()',
      description: 'Per-side overrides of kPolarDefaultMargins.',
    ),
    PropRow(
      name: 'hideLegend',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the legend strip is omitted.',
    ),
    PropRow(
      name: 'hideTooltip',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the hover popover is suppressed.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description: 'Accessible title. Upstream never draws it.',
    ),
    PropRow(
      name: 'hole',
      type: 'double',
      defaultValue: '0',
      description: 'Hole radius as a fraction of the outer radius.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentPolarShape',
      defaultValue: 'FluentPolarShape.circle',
      description: 'Whether the grid rings are circles or polygons.',
    ),
    PropRow(
      name: 'direction',
      type: 'FluentPolarDirection',
      defaultValue: 'FluentPolarDirection.counterclockwise',
      description: 'Sweep direction of the angular axis.',
    ),
    PropRow(
      name: 'radialAxis',
      type: 'FluentPolarAxisConfig?',
      defaultValue: 'null',
      description: 'Radial axis configuration.',
    ),
    PropRow(
      name: 'angularAxis',
      type: 'FluentPolarAxisConfig?',
      defaultValue: 'null',
      description: 'Angular axis configuration.',
    ),
    PropRow(
      name: 'angularUnit',
      type: 'FluentPolarAngularUnit',
      defaultValue: 'FluentPolarAngularUnit.degrees',
      description: 'Unit the angular tick labels are formatted in.',
    ),
    PropRow(
      name: 'culture',
      type: 'String?',
      defaultValue: 'null',
      description: 'BCP 47 locale used by the number and date formatters.',
    ),
    PropRow(
      name: 'useUtc',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether dates are interpreted and formatted in UTC.',
    ),
    PropRow(
      name: 'canSelectMultipleLegends',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether more than one legend may be selected at once.',
    ),
    PropRow(
      name: 'selectedLegends',
      type: 'List<String>?',
      defaultValue: 'null',
      description: 'Controlled legend selection.',
    ),
    PropRow(
      name: 'onLegendChange',
      type: 'void Function(List<String>)?',
      defaultValue: 'null',
      description: 'Called with the new selection when a legend is toggled.',
    ),
    PropRow(
      name: 'controller',
      type: 'FluentChartController?',
      defaultValue: 'null',
      description: 'Imperative handle exposing toImage.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentPolarChartStyle?',
      defaultValue: 'null',
      description: "Style override, layered over the theme's.",
    ),
  ],
);

// #docregion charts-polarchart--polar-chart-basic
Widget _polarChartBasic(BuildContext context) => const _PolarChartBasic();

class _PolarChartBasic extends StatefulWidget {
  const _PolarChartBasic();

  @override
  State<_PolarChartBasic> createState() => _PolarChartBasicState();
}

class _PolarChartBasicState extends State<_PolarChartBasic> {
  static const List<FluentPolarSeries> _data = <FluentPolarSeries>[
    FluentAreaPolarSeries(
      legend: 'Mike',
      color: Color(0xFF8884D8),
      data: <FluentPolarDataPoint>[
        FluentPolarDataPoint(r: 120, theta: 'Math'),
        FluentPolarDataPoint(r: 98, theta: 'Chinese'),
        FluentPolarDataPoint(r: 86, theta: 'English'),
        FluentPolarDataPoint(r: 99, theta: 'Geography'),
        FluentPolarDataPoint(r: 85, theta: 'Physics'),
        FluentPolarDataPoint(r: 65, theta: 'History'),
      ],
    ),
    FluentAreaPolarSeries(
      legend: 'Lily',
      color: Color(0xFF82CA9D),
      data: <FluentPolarDataPoint>[
        FluentPolarDataPoint(r: 110, theta: 'Math'),
        FluentPolarDataPoint(r: 130, theta: 'Chinese'),
        FluentPolarDataPoint(r: 130, theta: 'English'),
        FluentPolarDataPoint(r: 100, theta: 'Geography'),
        FluentPolarDataPoint(r: 90, theta: 'Physics'),
        FluentPolarDataPoint(r: 85, theta: 'History'),
      ],
    ),
  ];

  double _width = 600;
  double _height = 350;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Wrap(
        spacing: 20,
        runSpacing: 20,
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
        ],
      ),
      const SizedBox(height: 10),
      FluentPolarChart(
        data: _data,
        // Upstream's sliders start at 0, which a `<div>` shrugs off. Here the
        // legend strip is subtracted from the height before the plot is sized,
        // so a box under that strip would ask for a negative size — hence the
        // floor. The sliders still run the full 0..1000 upstream gives them.
        width: _width < 40 ? 40 : _width,
        height: _height < 40 ? 40 : _height,
        shape: FluentPolarShape.polygon,
        direction: FluentPolarDirection.clockwise,
      ),
    ],
  );
}

// #enddocregion charts-polarchart--polar-chart-basic
