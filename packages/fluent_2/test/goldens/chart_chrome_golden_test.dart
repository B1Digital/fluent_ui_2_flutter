import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One image per theme, holding four cells in this order:
///
/// 1. legend — three rows, the middle one selected, one striped swatch
/// 2. legend — the same three rows with nothing selected, so none is dimmed
/// 3. popover — single-value with a ratio and a description
/// 4. popover — stacked, three series, one with a subcount breakdown
/// 5. annotation layer — one plain box, one with a connector and an arrowhead
///
/// Cell 2 is not in the plan's four-row layout and is here because cell 1 alone
/// cannot show what the plan's own review step asks for. Selection is
/// [FluentChartLegendSelectionMode.single], so with `beta` selected the striped
/// `gamma` row is dimmed, and a dimmed stripe is painted in
/// `dimmedSwatchColor` — the background — which is invisible by construction.
/// Only an unselected strip renders the diagonal stripes at all.
///
/// The high-contrast image is the load-bearing one: the legend deliberately
/// keeps its palette colours there while every series mark flattens to a system
/// colour (`Legends.tsx:382`, design spec §5.3), so a regression that "fixed"
/// that asymmetry shows up as three flat swatches.
void main() {
  goldenGridTest(
    'chart_chrome',
    () => goldenGrid(<Widget>[
      const SizedBox(
        width: 560,
        child: FluentChartLegend(
          legends: <FluentChartLegendItem>[
            FluentChartLegendItem(title: 'alpha', color: Color(0xFF0078D4)),
            FluentChartLegendItem(title: 'beta', color: Color(0xFF107C10)),
            FluentChartLegendItem(
              title: 'gamma',
              color: Color(0xFFD13438),
              stripePattern: true,
            ),
          ],
          defaultSelectedLegends: <String>['beta'],
        ),
      ),
      const SizedBox(
        width: 560,
        child: FluentChartLegend(
          legends: <FluentChartLegendItem>[
            FluentChartLegendItem(title: 'alpha', color: Color(0xFF0078D4)),
            FluentChartLegendItem(title: 'beta', color: Color(0xFF107C10)),
            FluentChartLegendItem(
              title: 'gamma',
              color: Color(0xFFD13438),
              stripePattern: true,
            ),
          ],
        ),
      ),
      const SizedBox(
        width: 560,
        height: 160,
        child: FluentChartPopover(
          anchor: Offset(8, 8),
          data: FluentChartPopoverData(
            xValue: 'January',
            legend: 'alpha',
            yValue: '42',
            color: Color(0xFF0078D4),
            ratio: (42, 100),
            descriptionMessage: 'Year to date',
          ),
        ),
      ),
      const SizedBox(
        width: 560,
        height: 200,
        child: FluentChartPopover(
          anchor: Offset(8, 8),
          data: FluentChartPopoverData(
            isCalloutForStack: true,
            xValue: 'January',
            yValues: <FluentYValueHover>[
              FluentYValueHover(
                legend: 'alpha',
                y: 12,
                index: 0,
                color: Color(0xFF0078D4),
              ),
              FluentYValueHover(
                legend: 'beta',
                y: 8,
                index: 1,
                color: Color(0xFF107C10),
              ),
              FluentYValueHover(
                legend: 'gamma',
                y: 3,
                index: 2,
                color: Color(0xFFD13438),
                yAxisCalloutBreakdown: <String, double>{'north': 2, 'south': 1},
              ),
            ],
          ),
        ),
      ),
      const SizedBox(
        width: 560,
        height: 180,
        child: FluentChartAnnotationLayer(
          annotations: <FluentChartAnnotation>[
            FluentChartAnnotation(
              text: '<b>Peak</b><br />Q3',
              coordinates: FluentPixelCoordinate(x: 120, y: 60),
            ),
            FluentChartAnnotation(
              text: 'Dip',
              coordinates: FluentPixelCoordinate(x: 380, y: 140),
              layout: FluentChartAnnotationLayout(offsetY: -70),
              connector: FluentChartAnnotationConnector(),
            ),
          ],
          context: FluentChartAnnotationContext(
            plotRect: Rect.fromLTWH(0, 0, 560, 180),
            chartSize: Size(560, 180),
            isRtl: false,
          ),
        ),
      ),
    ], columns: 1),
  );
}
