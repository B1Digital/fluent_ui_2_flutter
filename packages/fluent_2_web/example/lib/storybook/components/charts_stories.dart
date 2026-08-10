import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// Stories for the shared chart chrome.
///
/// Chart stories proper land per chart at stages 8 to 11; this file exists now
/// so the chrome is reachable in the gallery before any chart is. A getter, not
/// a function, because `all_stories.dart` spreads every sibling as
/// `...xStories`.
List<Story> get chartsStories => [
  Story(
    name: 'Charts/FluentChartLegend',
    description:
        'The legend strip: a swatch and a title-cased label per series, with '
        'selection and hover highlighting.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Selection',
          children: [
            FluentChartLegend(
              legends: const [
                FluentChartLegendItem(
                  title: 'first series',
                  color: Color(0xFF0078D4),
                ),
                FluentChartLegendItem(
                  title: 'second series',
                  color: Color(0xFF107C10),
                ),
                FluentChartLegendItem(
                  title: 'third series',
                  color: Color(0xFFD13438),
                  stripePattern: true,
                ),
              ],
              selectionMode: FluentChartLegendSelectionMode.multiple,
              onChange: (selected, current) {},
            ),
          ],
        ),
        DemoRail(
          title: 'Shapes',
          children: [
            FluentChartLegend(
              legends: [
                for (final shape in FluentChartLegendShape.values)
                  FluentChartLegendItem(
                    title: shape.name,
                    color: const Color(0xFF0078D4),
                    shape: shape,
                  ),
              ],
              enabledWrapLines: true,
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentChartPopover',
    description:
        'The hover callout a chart shows for the datum under the cursor.',
    builder: (context) => DemoColumn(
      children: const [
        DemoRail(
          title: 'Single value',
          children: [
            SizedBox(
              width: 320,
              height: 200,
              child: FluentChartPopover(
                anchor: Offset(8, 8),
                data: FluentChartPopoverData(
                  xValue: 'January',
                  legend: 'first series',
                  yValue: '42',
                  color: Color(0xFF0078D4),
                  descriptionMessage: 'Year to date',
                ),
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Stacked',
          children: [
            SizedBox(
              width: 420,
              height: 220,
              child: FluentChartPopover(
                anchor: Offset(8, 8),
                data: FluentChartPopoverData(
                  isCalloutForStack: true,
                  xValue: 'January',
                  yValues: [
                    FluentYValueHover(
                      legend: 'first series',
                      y: 12,
                      index: 0,
                      color: Color(0xFF0078D4),
                    ),
                    FluentYValueHover(
                      legend: 'second series',
                      y: 8,
                      index: 1,
                      color: Color(0xFF107C10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentChartAnnotationLayer',
    description:
        'Free-standing callout boxes placed against chart coordinates, '
        'optionally joined to their datum by a connector.',
    builder: (context) => const SizedBox(
      width: 400,
      height: 240,
      child: FluentChartAnnotationLayer(
        annotations: [
          FluentChartAnnotation(
            text: '<b>Peak</b><br />Q3 2026',
            coordinates: FluentPixelCoordinate(x: 200, y: 80),
            layout: FluentChartAnnotationLayout(offsetY: -60),
            connector: FluentChartAnnotationConnector(),
          ),
        ],
        context: FluentChartAnnotationContext(
          plotRect: Rect.fromLTWH(0, 0, 400, 240),
          chartSize: Size(400, 240),
          isRtl: false,
        ),
      ),
    ),
  ),
];
