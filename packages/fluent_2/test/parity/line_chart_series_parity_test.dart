// Pixel parity for the LineChart stories beyond the basic one, against the
// live @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded: a chart fed different data than the reference is a
// comparison of two different pictures.
//
// Dates: the references were captured in a Europe/Istanbul browser (+03:00
// all year since 2016), and every date story here leaves `useUTC` unset or
// false, so upstream drew a LOCAL time scale on Istanbul's wall clock. CI runs
// `flutter test` in UTC, where a local scale sits three hours off that
// picture, and a zone with DST bends it between months. So each date story
// draws a UTC scale (`useUTC: true`) over the reference's Istanbul wall clock,
// which is the same picture in every zone: `new Date('2018/01/01')` and
// `new Date('01-01-2018')` are local midnight in Chromium, so
// `DateTime.utc(2018)`; an ISO date-only or `...Z` string is a UTC instant, so
// `_istanbul(DateTime.utc(...))`. A UTC recapture would make `_istanbul` the
// identity, but Chrome 153 on the live storybook no longer reproduces these
// 9.3.23 PNGs pixel for pixel even in Istanbul, so they were kept.
//
// `tickFormat: '%m/%d'` has no string form in the port; it is
// `customDateTimeFormatter`. Tick labels are masked, so only its effect on
// layout could matter, and an x label never moves a margin.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

String _monthDay(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.day.toString().padLeft(2, '0')}';

Color _token(FluentDataVizToken token) => FluentDataVizPalette.resolve(token);

/// The capture browser's Europe/Istanbul wall clock at the instant [utc], as a
/// UTC date (see the header). Istanbul has been +03:00 all year since 2016,
/// and every story date is later.
DateTime _istanbul(DateTime utc) => utc.add(const Duration(hours: 3));

void main() {
  setUpAll(loadParityFonts);

  testWidgets('LineChartAnnotationsExample', (tester) async {
    final primaryColor = _token(FluentDataVizToken.color3);
    final experimentColor = _token(FluentDataVizToken.color6);
    const milestoneColor = Color(0xFFD83B01);

    await expectReactParity(
      tester,
      'charts-linechart--line-chart-annotations-example',
      FluentLineChart(
        // `const chartData: ChartProps`.
        data: FluentChartData(
          chartTitle: 'Weekly signups',
          lineChartData: <FluentLineChartSeries>[
            FluentLineChartSeries(
              legend: 'Signups',
              color: primaryColor,
              data: const <Object>[
                FluentLineChartDataPoint(x: 0, y: 18),
                FluentLineChartDataPoint(x: 1, y: 26),
                FluentLineChartDataPoint(x: 2, y: 31),
                FluentLineChartDataPoint(x: 3, y: 37),
                FluentLineChartDataPoint(x: 4, y: 44),
                FluentLineChartDataPoint(x: 5, y: 51),
                FluentLineChartDataPoint(x: 6, y: 47),
              ],
            ),
          ],
        ),
        props: FluentCartesianChartProps(
          // `const annotations: ChartAnnotation[]`. The text is the story's
          // HTML VERBATIM: upstream's `parseSimpleMarkup`
          // (`ChartAnnotationLayer.tsx:127-208`) understands only <b>, <i> and
          // <br>, so <div>, <strong>, <span>, <ul> and <li> are drawn as
          // literal text in the reference, and `white-space: pre-wrap`
          // (`useChartAnnotationLayer.styles.ts:107`) keeps the template
          // literal's newline and eight spaces.
          annotations: <FluentChartAnnotation>[
            FluentChartAnnotation(
              id: 'launch-html',
              text:
                  '<div><strong>Launch day</strong><br /><span '
                  'style="color:#2aa0a4">+18% conversions</span></div>',
              coordinates: const FluentDataCoordinate(x: 1, y: 26),
              layout: const FluentChartAnnotationLayout(
                align: FluentChartAnnotationAlign.start,
                verticalAlign: FluentChartAnnotationVerticalAlign.bottom,
                offsetX: 16,
                offsetY: -68,
                maxWidth: 220,
                clipToBounds: true,
              ),
              style: FluentChartAnnotationStyle(
                backgroundColor: const Color(0xFFFFFFFF),
                borderColor: primaryColor,
                borderWidth: 1,
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                fontWeight: FontWeight.w600,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.18),
                    offset: Offset(0, 12),
                    blurRadius: 24,
                  ),
                ],
              ),
              connector: FluentChartAnnotationConnector(
                strokeColor: primaryColor,
                strokeWidth: 2,
                startPadding: 24,
                endPadding: 6,
              ),
            ),
            FluentChartAnnotation(
              id: 'experiment',
              text:
                  '<div><strong>Pricing experiment</strong><br /><em>A/B '
                  'test running</em><ul><li>Variant B at 52%</li>\n'
                  '        <li>Average order ↑</li></ul></div>',
              coordinates: const FluentDataCoordinate(x: 3, y: 37),
              layout: const FluentChartAnnotationLayout(
                offsetX: 132,
                offsetY: -12,
                maxWidth: 280,
                clipToBounds: false,
              ),
              style: FluentChartAnnotationStyle(
                backgroundColor: const Color(0xFFF4F9FF),
                borderColor: experimentColor,
                borderWidth: 1,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 18,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.16),
                    offset: Offset(0, 10),
                    blurRadius: 20,
                  ),
                ],
              ),
              connector: FluentChartAnnotationConnector(
                strokeColor: experimentColor,
                strokeWidth: 2,
                startPadding: 18,
                endPadding: 4,
                dashArray: '5, 5',
              ),
            ),
            const FluentChartAnnotation(
              id: 'stretch-goal',
              text:
                  '<span>Stretch goal<br /><strong>5k signups</strong></span>',
              coordinates: FluentRelativeCoordinate(x: 0.84, y: 0.34),
              layout: FluentChartAnnotationLayout(clipToBounds: false),
              style: FluentChartAnnotationStyle(
                backgroundColor: Color.fromRGBO(216, 59, 1, 0.08),
                borderColor: milestoneColor,
                borderStyle: FluentChartAnnotationBorderStyle.dashed,
                borderWidth: 1,
                borderRadius: 8,
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                textColor: milestoneColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const FluentChartAnnotation(
              id: 'offset-info',
              text:
                  '<div><strong>Note:</strong> Values rounded to nearest '
                  'whole signup.</div>',
              coordinates: FluentPixelCoordinate(x: 24, y: 24),
              layout: FluentChartAnnotationLayout(
                align: FluentChartAnnotationAlign.start,
                verticalAlign: FluentChartAnnotationVerticalAlign.top,
                clipToBounds: false,
              ),
              style: FluentChartAnnotationStyle(
                backgroundColor: Color(0xFFFFFFFF),
                borderColor: Color(0xFFC7C7C7),
                borderWidth: 1,
                borderRadius: 6,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      // Measured 0.725% — 3,458 of 477,223 px, aligned; every red pixel is
      // in the annotation layer, and the line, axes, gridlines and legend
      // match. About 2,900 are glyphs: the corpus masks only 6 of the 13
      // annotation text runs (the other 7 sit on box fills and connectors
      // that drifted between Chrome builds, see react_png/README.md), so the
      // stretch-goal box's text and most of the experiment box's are
      // compared unmasked, and Skia and Chromium rasterise them differently
      // (Flutter also leaves a blank where upstream draws the "↑" of
      // "Average order ↑"). About 500 are the stretch-goal box's dashed
      // border: its semibold text runs wide in Selawik Semibold, so the box
      // spans x 672-919 against upstream's 674-917 and its dashes fall on
      // another phase. The last ~80 are arrowhead edges: 62 on the launch-day
      // connector's and 19 on the base of the experiment connector's.
      //
      // Was 5.216% while the port sized each box to maxWidth as a border box,
      // dropped the 1px border and the first and last half-leading, ignored
      // `borderStyle: dashed` and painted shadow16 under the translucent
      // stretch-goal fill.
      maxMismatch: 0.75,
    );
  });

  testWidgets('LineChartCustomAccessibility', (tester) async {
    // `const points` — the accessibility strings are carried for fidelity;
    // they paint nothing.
    FluentLineChartSeries series(
      String legend,
      FluentDataVizToken color,
      List<FluentLineChartDataPoint> data,
    ) => FluentLineChartSeries(
      legend: legend,
      color: _token(color),
      lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      data: data,
    );

    await expectReactParity(
      tester,
      'charts-linechart--line-chart-custom-accessibility',
      FluentLineChart(
        data: FluentChartData(
          chartTitle: 'Line Chart Custom Accessibility Example',
          lineChartData: <FluentLineChartSeries>[
            series(
              'First',
              FluentDataVizToken.color4,
              <FluentLineChartDataPoint>[
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018),
                  y: 10,
                  xAxisCalloutData: '2018/01/01',
                  yAxisCalloutText: '10%',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 2),
                  y: 30,
                  xAxisCalloutData: '2018/01/15',
                  yAxisCalloutText: '18%',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 3),
                  y: 10,
                  xAxisCalloutData: '2018/01/28',
                  yAxisCalloutText: '24%',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 4),
                  y: 30,
                  xAxisCalloutData: '2018/02/01',
                  yAxisCalloutText: '25%',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 5),
                  y: 10,
                  xAxisCalloutData: '2018/03/01',
                  yAxisCalloutText: '15%',
                ),
              ],
            ),
            series(
              'Second',
              FluentDataVizToken.color5,
              <FluentLineChartDataPoint>[
                FluentLineChartDataPoint(x: DateTime.utc(2018), y: 30),
                FluentLineChartDataPoint(x: DateTime.utc(2018, 2), y: 50),
                FluentLineChartDataPoint(x: DateTime.utc(2018, 3), y: 30),
                FluentLineChartDataPoint(x: DateTime.utc(2018, 4), y: 50),
                FluentLineChartDataPoint(x: DateTime.utc(2018, 5), y: 30),
              ],
            ),
            series(
              'Third',
              FluentDataVizToken.color6,
              <FluentLineChartDataPoint>[
                FluentLineChartDataPoint(x: DateTime.utc(2018), y: 50),
                FluentLineChartDataPoint(x: DateTime.utc(2018, 2), y: 70),
                FluentLineChartDataPoint(x: DateTime.utc(2018, 3), y: 50),
                FluentLineChartDataPoint(x: DateTime.utc(2018, 4), y: 70),
                FluentLineChartDataPoint(x: DateTime.utc(2018, 5), y: 50),
              ],
            ),
          ],
        ),
        // `legendProps.canSelectMultipleLegends`; `allowMultipleShapes`
        // starts false; `strokeWidth={4}` is DEFAULT_LINE_STROKE_SIZE.
        legendSelectionMode: FluentChartLegendSelectionMode.multiple,
        colorFillBars: <FluentColorFillBar>[
          FluentColorFillBar(
            legend: 'Time range 1',
            color: _token(FluentDataVizToken.color11),
            data: <FluentColorFillBarRange>[
              FluentColorFillBarRange(
                startX: DateTime.utc(2018, 1, 6),
                endX: DateTime.utc(2018, 1, 25),
              ),
            ],
          ),
          FluentColorFillBar(
            legend: 'Time range 2',
            color: _token(FluentDataVizToken.color10),
            applyPattern: true,
            data: <FluentColorFillBarRange>[
              FluentColorFillBarRange(
                startX: DateTime.utc(2018, 1, 18),
                endX: DateTime.utc(2018, 2, 20),
              ),
              FluentColorFillBarRange(
                startX: DateTime.utc(2018, 4, 17),
                endX: DateTime.utc(2018, 5, 10),
              ),
            ],
          ),
        ],
        props: FluentCartesianChartProps(
          customDateTimeFormatter: _monthDay,
          enableFirstRenderOptimization: true,
          // Upstream leaves `useUTC` unset; see the header's Dates note.
          useUTC: true,
          tickValues: <Object>[
            DateTime.utc(2018),
            DateTime.utc(2018, 2),
            DateTime.utc(2018, 3),
            DateTime.utc(2018, 4),
            DateTime.utc(2018, 5),
          ],
        ),
      ),
      // Measured 0.026% — 53 of 201,906 px, aligned, all line antialiasing:
      // 43 along the "Third" line's upper edge where it crosses the hatched
      // "Time Range 2" band (x 214-275), the rest single pixels on shallow
      // edges. It was 0.531% while the colour-fill bars were topped at the
      // nice'd y domain (72) instead of the data's max y (70,
      // `LineChart.tsx:1380,1404`) and the legend swatches, the striped one's
      // stripe phase included, did not match Chromium's.
      maxMismatch: 0.03,
    );
  });

  testWidgets('LineChartEvents', (tester) async {
    // d3's `format('$,')`: a dollar sign and comma-grouped integers.
    String currency(double value) {
      final digits = value.round().abs().toString();
      final grouped = StringBuffer();
      for (var i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
        grouped.write(digits[i]);
      }
      return '${value < 0 ? '-' : ''}\$$grouped';
    }

    FluentLineChartSeries series(
      String legend,
      FluentDataVizToken color,
      List<double> ys,
    ) => FluentLineChartSeries(
      legend: legend,
      color: _token(color),
      lineOptions: const FluentLineOptions(lineBorderWidth: 4),
      data: <Object>[
        for (var i = 0; i < ys.length; i++)
          FluentLineChartDataPoint(
            x: _istanbul(DateTime.utc(2020, 3, 3 + i)),
            y: ys[i],
          ),
      ],
    );

    FluentEventAnnotation event(int n, int day) => FluentEventAnnotation(
      event: 'event $n',
      date: _istanbul(DateTime.utc(2020, 3, day)),
    );

    await expectReactParity(
      tester,
      'charts-linechart--line-chart-events',
      FluentLineChart(
        data: FluentChartData(
          chartTitle: 'Line Chart',
          lineChartData: <FluentLineChartSeries>[
            series('From_Legacy_to_O365', FluentDataVizToken.color8, <double>[
              297,
              284,
              282,
              294,
              294,
              300,
              298,
            ]),
            series('All', FluentDataVizToken.color10, <double>[
              292,
              287,
              287,
              292,
              287,
              297,
              292,
            ]),
          ],
        ),
        eventAnnotations: <FluentEventAnnotation>[
          event(1, 4),
          event(2, 4),
          event(3, 4),
          event(4, 6),
          event(5, 8),
        ],
        eventAnnotationMergedLabel: (count) => '$count events',
        // `eventAnnotationProps.labelHeight: 18` (`LineChart.tsx:180-181`).
        // `labelWidth: 50` has no port surface: `FluentLineChart` never
        // forwards a width to `FluentEventAnnotationLayer`, which keeps its
        // default 105.
        style: FluentLineChartStyle.from(eventLabelHeight: 18),
        props: FluentCartesianChartProps(
          yMinValue: 282,
          yMaxValue: 301,
          yAxisTickFormat: currency,
          customDateTimeFormatter: _monthDay,
          enableFirstRenderOptimization: true,
          // Upstream leaves `useUTC` unset; see the header's Dates note.
          useUTC: true,
          tickValues: <Object>[
            for (var day = 3; day <= 9; day++)
              _istanbul(DateTime.utc(2020, 3, day)),
          ],
        ),
      ),
      // Measured 0.019% — 37 of 199,188 px, aligned, all antialiasing on the
      // 4px lines' edges: 21 under the green line's shallow 03/04-03/05
      // segment and 16 along the gold line's steep climb to 03/08.
      maxMismatch: 0.02,
    );
  });

  testWidgets('LineChartGaps', (tester) async {
    await expectReactParity(
      tester,
      'charts-linechart--line-chart-gaps',
      FluentLineChart(
        data: FluentChartData(
          chartTitle: 'Line Chart',
          lineChartData: <FluentLineChartSeries>[
            FluentLineChartSeries(
              legend: 'Confidence Level',
              legendShape: FluentChartLegendShape.dottedLine,
              hideInactiveDots: true,
              lineOptions: const FluentLineOptions(
                strokeDasharray: '5',
                strokeLinecap: StrokeCap.butt,
                strokeWidth: 2,
                lineBorderWidth: 4,
              ),
              color: _token(FluentDataVizToken.color11),
              data: <Object>[
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 3)),
                  y: 250000,
                  hideCallout: true,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 10)),
                  y: 250000,
                  hideCallout: true,
                ),
              ],
            ),
            FluentLineChartSeries(
              legend: 'Normal Data',
              gaps: const <FluentLineChartGap>[
                FluentLineChartGap(startIndex: 3, endIndex: 4),
                FluentLineChartGap(startIndex: 6, endIndex: 7),
                FluentLineChartGap(startIndex: 1, endIndex: 2),
              ],
              hideInactiveDots: true,
              lineOptions: const FluentLineOptions(lineBorderWidth: 4),
              color: _token(FluentDataVizToken.color12),
              data: <Object>[
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 3)),
                  y: 216000,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 3, 10, 30)),
                  y: 218123,
                  hideCallout: true,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 3, 11)),
                  y: 219000,
                  hideCallout: true,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 4)),
                  y: 248000,
                  hideCallout: true,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 5)),
                  y: 252000,
                  hideCallout: true,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 6)),
                  y: 274000,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 7)),
                  y: 260000,
                  hideCallout: true,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 8)),
                  y: 300000,
                  hideCallout: true,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 8, 12)),
                  y: 218000,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 9)),
                  y: 218000,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 10)),
                  y: 269000,
                ),
              ],
            ),
            FluentLineChartSeries(
              legend: 'Low Confidence Data*',
              legendShape: FluentChartLegendShape.dottedLine,
              hideInactiveDots: true,
              lineOptions: const FluentLineOptions(
                strokeDasharray: '2',
                strokeDashoffset: -1,
                strokeLinecap: StrokeCap.butt,
                lineBorderWidth: 4,
              ),
              gaps: const <FluentLineChartGap>[
                FluentLineChartGap(startIndex: 3, endIndex: 4),
                FluentLineChartGap(startIndex: 1, endIndex: 2),
              ],
              color: _token(FluentDataVizToken.color13),
              data: <Object>[
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 3, 10, 30)),
                  y: 218123,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 3, 11)),
                  y: 219000,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 4)),
                  y: 248000,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 5)),
                  y: 252000,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 7)),
                  y: 260000,
                ),
                FluentLineChartDataPoint(
                  x: _istanbul(DateTime.utc(2020, 3, 8)),
                  y: 300000,
                ),
              ],
            ),
            FluentLineChartSeries(
              legend: 'Green Data',
              lineOptions: const FluentLineOptions(lineBorderWidth: 4),
              color: _token(FluentDataVizToken.success),
              data: <Object>[
                for (final (i, y) in <double>[
                  297000,
                  284000,
                  282000,
                  294000,
                  224000,
                  300000,
                  298000,
                  299000,
                ].indexed)
                  FluentLineChartDataPoint(
                    x: _istanbul(DateTime.utc(2020, 3, 3 + i)),
                    y: y,
                  ),
              ],
            ),
          ],
        ),
        // `getCalloutDescriptionMessage` only feeds the hover callout.
        props: const FluentCartesianChartProps(
          yMinValue: 150000,
          yMaxValue: 400000,
          enableFirstRenderOptimization: true,
          margins: FluentChartMargins(left: 35, top: 20, bottom: 35, right: 20),
          // Upstream leaves `useUTC` unset; see the header's Dates note.
          useUTC: true,
        ),
      ),
      // Measured 0.006% — 16 of 266,853 px, aligned, all antialiasing on the
      // green line's lower edge where it steepens beside the dotted segment
      // (x 445-468). It was 0.156% while the port ignored
      // `lineOptions.strokeDashoffset` (-1), which `LineChart.tsx:1285`
      // applies to every segment, so the 'Low Confidence Data*' dots and the
      // dotted legend swatch sat a pixel off.
      maxMismatch: 0.008,
    );
  });

  testWidgets('LineChartMultiple', (tester) async {
    // Every series plots the same six local-midnight months; only the y
    // values change, and each row is upstream's.
    FluentLineChartSeries series(String legend, double base) =>
        FluentLineChartSeries(
          legend: legend,
          lineOptions: const FluentLineOptions(lineBorderWidth: 4),
          data: <Object>[
            for (var i = 0; i < 6; i++)
              FluentLineChartDataPoint(
                x: DateTime.utc(2018, i + 1),
                y: base + (i.isOdd ? 20 : 0),
              ),
          ],
        );

    await expectReactParity(
      tester,
      'charts-linechart--line-chart-multiple',
      FluentLineChart(
        data: FluentChartData(
          chartTitle: 'Line Chart',
          lineChartData: <FluentLineChartSeries>[
            series('First', 10),
            series('Second', 30),
            series('Third', 50),
            series('Fourth', 70),
            series('Fifth', 90),
            series('Sixth', 110),
            series('Seventh', 130),
            series('Eight', 150),
            series('Ninth', 170),
            series('Tenth', 190),
            series('Eleventh', 210),
            series('Tweleth', 230),
          ],
        ),
        legendSelectionMode: FluentChartLegendSelectionMode.multiple,
        colorFillBars: <FluentColorFillBar>[
          FluentColorFillBar(
            legend: 'Time range 1',
            color: _token(FluentDataVizToken.color19),
            data: <FluentColorFillBarRange>[
              FluentColorFillBarRange(
                startX: DateTime.utc(2018, 1, 6),
                endX: DateTime.utc(2018, 1, 25),
              ),
            ],
          ),
          FluentColorFillBar(
            legend: 'Time range 2',
            color: _token(FluentDataVizToken.color20),
            applyPattern: true,
            data: <FluentColorFillBarRange>[
              FluentColorFillBarRange(
                startX: DateTime.utc(2018, 1, 18),
                endX: DateTime.utc(2018, 2, 20),
              ),
              FluentColorFillBarRange(
                startX: DateTime.utc(2018, 4, 17),
                endX: DateTime.utc(2018, 5, 10),
              ),
            ],
          ),
        ],
        props: FluentCartesianChartProps(
          customDateTimeFormatter: _monthDay,
          enableFirstRenderOptimization: true,
          // Upstream passes `useUTC={false}`; see the header's Dates note.
          useUTC: true,
          hideTickOverlap: true,
          tickValues: <Object>[
            for (var month = 1; month <= 7; month++) DateTime.utc(2018, month),
          ],
        ),
      ),
      // Measured 0.250% — 499 of 199,230 px, aligned:
      //   * 355 antialiasing on the lines' shallow edges, nearly all in two
      //     strips at x 182-234 and 468-529, just after the 02/01 and 05/01
      //     vertices;
      //   * 21 hatch stripe ends along the plot's top edge;
      //   * 56 the "Sixth" and "Eight" legend swatches, one column off: they
      //     snap to device pixels as Chromium's do, but the labels before them
      //     measure a fraction of a pixel differently in Selawik and Segoe UI,
      //     so the fractional x rounds the other way;
      //   * 67 the "+6 more" overflow button, a column wider than upstream's
      //     (its Selawik Semibold label runs wide): 48 on its right border and
      //     19 on its chevron.
      // It was 0.498% while the colour-fill bars were topped at the nice'd
      // domain (252) instead of the data max (250), the swatches were
      // unsnapped and the button's text was unmasked.
      maxMismatch: 0.26,
    );
  });

  testWidgets('LineChartStyled', (tester) async {
    await expectReactParity(
      tester,
      'charts-linechart--line-chart-styled',
      FluentLineChart(
        data: FluentChartData(
          chartTitle: 'Line Chart',
          lineChartData: <FluentLineChartSeries>[
            FluentLineChartSeries(
              legend: 'first legend',
              lineOptions: const FluentLineOptions(lineBorderWidth: 4),
              color: _token(FluentDataVizToken.color10),
              data: <Object>[
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 1, 6),
                  y: 10,
                  xAxisCalloutData: 'Appointment 1',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 1, 16),
                  y: 18,
                  xAxisCalloutData: 'Appointment 2',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 1, 20),
                  y: 24,
                  xAxisCalloutData: 'Appointment 3',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 1, 24),
                  y: 35,
                  xAxisCalloutData: 'Appointment 4',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 1, 26),
                  y: 35,
                  xAxisCalloutData: 'Appointment 5',
                ),
                FluentLineChartDataPoint(
                  x: DateTime.utc(2018, 1, 29),
                  y: 90,
                  xAxisCalloutData: 'Appointment 6',
                ),
              ],
            ),
          ],
        ),
        props: FluentCartesianChartProps(
          yMaxValue: 90,
          showXAxisLablesTooltip: true,
          customDateTimeFormatter: _monthDay,
          enableFirstRenderOptimization: true,
          // Upstream leaves `useUTC` unset; see the header's Dates note.
          useUTC: true,
          // ISO date-only strings: UTC midnight.
          tickValues: <Object>[
            _istanbul(DateTime.utc(2018)),
            _istanbul(DateTime.utc(2018, 2, 9)),
          ],
        ),
      ),
      // Measured 0.041% — 84 of 206,686 px, aligned, all antialiasing on the
      // 4px line: 79 along its shallow first segment (x 171-241) and 5 at a
      // round join.
      maxMismatch: 0.05,
    );
  });
}
