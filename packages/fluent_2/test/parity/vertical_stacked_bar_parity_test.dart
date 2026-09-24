// Pixel parity for VerticalStackedBarChart, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Every number,
// colour and string is verbatim, and every interactive control is left in the
// initial state the reference was captured in. The `Default` story lives in
// `vertical_bar_parity_test.dart`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:fluent_2/src/charts/vertical_stacked_bar_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

Color _token(FluentDataVizToken token) => FluentDataVizPalette.resolve(token);

/// `${x}` for a JS number: an integral value prints without a fraction.
String _jsNumber(double x) =>
    x == x.roundToDouble() ? x.toInt().toString() : x.toString();

void main() {
  setUpAll(loadParityFonts);

  testWidgets('VerticalStackedBarAxisCategoryOrder', (tester) async {
    // `_getData(5)` draws from `Math.random()` with no seed, so the story has
    // no fixed input. The values below are recovered from the REFERENCE PNG by
    // inverting the stack geometry, not from Oracle B: Oracle B's capture of
    // this story is a different random draw (three stacks, totals 37/83/31),
    // and only the PNG is what this test compares against.
    //
    // The y ticks are −188..47 in steps of 47, so `prepareDatapoints`
    // (`utilities.ts:683-723`) ran on a span of 185 and the bar scale is
    // 295 / 235 px per unit. "Label 1" is four segments with gaps of 2
    // (`barGapMax={2}`): measured edge-to-edge at the antialiased rows they
    // are 74.60 and 99.06 px below the baseline and 23.24 and 29.36 above it,
    // which with `heightValueScale = (1.2553 * 185 - 6) / 185` is exactly
    // −61, −81, 19 and 24 (total −99, the drawn label). The positive cornflower
    // segment's bottom sits 2px off the baseline, so it is not index 0; the
    // negative one flush with the baseline is. i = 0..2 all land in "Label 1"
    // with legend index 0 — the only colour there is `getNextColor(0)` — and
    // i = 3 is the teal `getNextColor(2)` segment. Whether −81 or 19 came
    // second draws identical pixels, so the order within i = 1..2 is a guess.
    // "Label 2" is i = 4, one `getNextColor(3)` segment of 20.
    final data = <FluentVerticalStackedBarGroup>[
      FluentVerticalStackedBarGroup(
        xAxisPoint: 'Label 1',
        chartData: <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            data: -61,
            legend: 'Legend 1',
            color: FluentDataVizPalette.next(0),
          ),
          FluentStackedBarDatum(
            data: 19,
            legend: 'Legend 1',
            color: FluentDataVizPalette.next(0),
          ),
          FluentStackedBarDatum(
            data: -81,
            legend: 'Legend 1',
            color: FluentDataVizPalette.next(0),
          ),
          FluentStackedBarDatum(
            data: 24,
            legend: 'Legend 3',
            color: FluentDataVizPalette.next(2),
          ),
        ],
      ),
      FluentVerticalStackedBarGroup(
        xAxisPoint: 'Label 2',
        chartData: <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            data: 20,
            legend: 'Legend 4',
            color: FluentDataVizPalette.next(3),
          ),
        ],
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalstackedbarchart--vertical-stacked-bar-axis-category-order',
      FluentVerticalStackedBarChart(
        data: data,
        barGapMax: 2,
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
        // `xAxisCategoryOrder` starts at 'default'.
        xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        props: const FluentCartesianChartProps(
          hideLegend: true,
          hideTickOverlap: true,
          // `Math.min/max` over each stack's positive and negative sums:
          // Label 1 is 43 / −142, Label 2 is 20 / 0.
          yMinValue: -142,
          yMaxValue: 43,
        ),
      ),
      // Measured 0.064% — 144 px, all of it the y tick labels −47/−94/−141/
      // −188 and the "−99" total: d3 formats negatives with U+2212, the
      // bundled Selawik has no such glyph, and `flutter test` draws its tofu
      // box, which is wider than the minus and pokes out of the text mask.
      // Every mark, gridline and axis line matches to the pixel.
      maxMismatch: 0.07,
    );
  });

  testWidgets('VerticalStackedBarAxisTooltip', (tester) async {
    final c1 = _token(FluentDataVizToken.color1);
    final c2 = _token(FluentDataVizToken.color2);
    final c6 = _token(FluentDataVizToken.color6);
    final firstChartPoints = <FluentStackedBarDatum>[
      FluentStackedBarDatum(legend: 'Metadata1', data: 2, color: c1),
      FluentStackedBarDatum(legend: 'Metadata2', data: 0.5, color: c2),
      FluentStackedBarDatum(legend: 'Metadata3', data: 0, color: c6),
    ];
    final secondChartPoints = <FluentStackedBarDatum>[
      FluentStackedBarDatum(legend: 'Metadata1', data: 30, color: c1),
      FluentStackedBarDatum(legend: 'Metadata2', data: 3, color: c2),
      FluentStackedBarDatum(legend: 'Metadata3', data: 40, color: c6),
    ];
    final thirdChartPoints = <FluentStackedBarDatum>[
      FluentStackedBarDatum(legend: 'Metadata1', data: 10, color: c1),
      FluentStackedBarDatum(legend: 'Metadata2', data: 60, color: c2),
      FluentStackedBarDatum(legend: 'Metadata3', data: 30, color: c6),
    ];
    final data = <FluentVerticalStackedBarGroup>[
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 'Simple Data',
      ),
      FluentVerticalStackedBarGroup(
        chartData: secondChartPoints,
        xAxisPoint: 'Long text will disaply all text',
      ),
      FluentVerticalStackedBarGroup(
        chartData: thirdChartPoints,
        xAxisPoint: 'Data',
      ),
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 'Meta data',
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalstackedbarchart--vertical-stacked-bar-axis-tooltip',
      FluentVerticalStackedBarChart(
        chartTitle: 'Vertical stacked bar chart axis tooltip example',
        data: data,
        // `barWidthEnabled` starts true with `barWidth` 16; `maxBarWidth` 100;
        // both padding checkboxes start unchecked, so both are undefined;
        // `enableGradient` and `roundCorners` start false.
        barWidth: 16.0,
        maxBarWidth: 100,
        barGapMax: 2,
        props: const FluentCartesianChartProps(
          // `selectedCallout` starts at "showTooltip".
          showXAxisLablesTooltip: true,
        ),
      ),
      // Measured 0.000% — 0 of 218,995 px. No lines, no negatives, and all
      // three legend swatches sit within 0.1px of a whole pixel. Pinned at 0
      // because the floor (measured >= half the pin) admits nothing else.
      maxMismatch: 0,
    );
  });

  testWidgets('VerticalStackedBarCallout', (tester) async {
    final c1 = _token(FluentDataVizToken.color1);
    final c2 = _token(FluentDataVizToken.color2);
    final c6 = _token(FluentDataVizToken.color6);
    List<FluentStackedBarDatum> points(double a, double b, double c) =>
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(legend: 'Metadata1', data: a, color: c2),
          FluentStackedBarDatum(legend: 'Metadata2', data: b, color: c1),
          FluentStackedBarDatum(legend: 'Metadata3', data: c, color: c6),
        ];
    final firstChartPoints = points(40, 5, 15);
    final line1 = _token(FluentDataVizToken.color10);
    final line2 = _token(FluentDataVizToken.color5);
    final line3 = _token(FluentDataVizToken.color7);
    FluentStackedBarLineDatum l1(double y) =>
        FluentStackedBarLineDatum(y: y, color: line1, legend: 'line1');
    FluentStackedBarLineDatum l2(double y) =>
        FluentStackedBarLineDatum(y: y, color: line2, legend: 'line2');
    FluentStackedBarLineDatum l3(double y) =>
        FluentStackedBarLineDatum(y: y, color: line3, legend: 'line3');
    // `showLine` starts true, so every `lineData` spread is present.
    final data = <FluentVerticalStackedBarGroup>[
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 'Jan',
        lineData: <FluentStackedBarLineDatum>[l1(40)],
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(30, 3, 40),
        xAxisPoint: 'Feb',
        lineData: <FluentStackedBarLineDatum>[l1(15), l3(70)],
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(10, 60, 30),
        xAxisPoint: 'March',
        lineData: <FluentStackedBarLineDatum>[l2(65), l3(98)],
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(40, 10, 30),
        xAxisPoint: 'April',
        lineData: <FluentStackedBarLineDatum>[l1(40), l2(50), l3(65)],
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(40, 40, 40),
        xAxisPoint: 'May',
        lineData: <FluentStackedBarLineDatum>[l1(20), l2(65)],
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(40, 20, 40),
        xAxisPoint: 'June',
        lineData: <FluentStackedBarLineDatum>[l2(54), l3(87)],
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(10, 80, 20),
        xAxisPoint: 'July',
        lineData: <FluentStackedBarLineDatum>[l1(10), l3(110)],
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(50, 50, 20),
        xAxisPoint: 'August',
        lineData: <FluentStackedBarLineDatum>[l1(45), l2(87)],
      ),
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 'September',
        lineData: <FluentStackedBarLineDatum>[l1(15), l3(60)],
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalstackedbarchart--vertical-stacked-bar-callout',
      FluentVerticalStackedBarChart(
        chartTitle: 'Vertical stacked bar chart callout example',
        // `barGapMax` starts at 2 and `barWidth` at 16.
        barGapMax: 2,
        data: data,
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
        // `selectedCallout` starts at "MultiCallout".
        isCalloutForStack: true,
        allowHoverOnLegend: false,
        barWidth: 16.0,
        props: const FluentCartesianChartProps(
          yAxisTickCount: 10,
          yMaxValue: 120,
          margins: FluentChartMargins(left: 50),
        ),
      ),
      // Measured 0.059% — 125 px. 84 of them are the three line-legend
      // swatches drawn 14x4 where upstream's are 14x6: `height: 4px`
      // (`Legends.tsx:376`) is a content box and the 1px border
      // (`useLegendsStyles.styles.ts:82`) adds two rows. 16 are the line3 and
      // line2 swatches painted at x 379.23 / 445.33 where Chromium snaps the
      // div to whole pixels. The last 25 are antialiasing along the lines.
      maxMismatch: 0.07,
    );
  });

  testWidgets('VerticalStackedBarCustomAccessibility', (tester) async {
    final c1 = _token(FluentDataVizToken.color1);
    final c2 = _token(FluentDataVizToken.color2);
    final c6 = _token(FluentDataVizToken.color6);
    FluentStackedBarDatum point(
      String legend,
      double data,
      Color color,
      String yCallout,
      String ariaLabel,
    ) => FluentStackedBarDatum(
      legend: legend,
      data: data,
      color: color,
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: yCallout,
      callOutSemantics: FluentChartSemantics(label: ariaLabel),
    );
    final firstChartPoints = <FluentStackedBarDatum>[
      point(
        'Metadata1',
        40,
        c2,
        '61%',
        'Bar series 1-1 of 4, 2020/04/30 Metadata1 61%',
      ),
      point(
        'Metadata2',
        5,
        c1,
        '8%',
        'Bar series 1-2 of 4, 2020/04/30 Metadata2 8%',
      ),
      point(
        'Metadata3',
        20,
        c6,
        '31%',
        'Bar series 1-3 of 4, 2020/04/30 Metadata3 31%',
      ),
    ];
    final secondChartPoints = <FluentStackedBarDatum>[
      point(
        'Metadata1',
        30,
        c2,
        '33%',
        'Bar series 2-1 of 4, 2020/04/30 Metadata1 33%',
      ),
      point(
        'Metadata2',
        20,
        c1,
        '22%',
        'Bar series 2-2 of 4, 2020/04/30 Metadata2 22%',
      ),
      point(
        'Metadata3',
        40,
        c6,
        '45%',
        'Bar series 2-3 of 4, 2020/04/30 Metadata3 45%',
      ),
    ];
    final thirdChartPoints = <FluentStackedBarDatum>[
      point(
        'Metadata1',
        44,
        c2,
        '43%',
        'Bar series 3-1 of 4, 2020/04/30 Metadata1 43%',
      ),
      point(
        'Metadata2',
        28,
        c1,
        '27%',
        'Bar series 3-2 of 4, 2020/04/30 Metadata2 27%',
      ),
      point(
        'Metadata3',
        30,
        c6,
        '30%',
        'Bar series 3-3 of 4, 2020/04/30 Metadata3 30%',
      ),
    ];
    final supported = _token(FluentDataVizToken.color5);
    final recommended = _token(FluentDataVizToken.color2);
    // `showLine` starts true.
    final data = <FluentVerticalStackedBarGroup>[
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 0,
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 42,
            legend: 'Supported Builds',
            color: supported,
          ),
          FluentStackedBarLineDatum(
            y: 10,
            legend: 'Recommended Builds',
            color: recommended,
          ),
        ],
        stackCallOutSemantics: const FluentChartSemantics(
          label:
              'Bar stack series 1 of 3, 0 MetaDate1 61% MetaData2 8% '
              'MetaDate3 31% Recommended Builds 10 Supported Builds 42',
        ),
      ),
      FluentVerticalStackedBarGroup(
        chartData: secondChartPoints,
        xAxisPoint: 20,
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 33,
            legend: 'Supported Builds',
            color: supported,
          ),
        ],
        stackCallOutSemantics: const FluentChartSemantics(
          label:
              'Bar stack series 2 of 3, 20 MetaDate1 33% MetaData2 22% '
              'MetaDate3 45% Supported Builds 33',
        ),
      ),
      FluentVerticalStackedBarGroup(
        chartData: thirdChartPoints,
        xAxisPoint: 40,
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 60,
            legend: 'Supported Builds',
            color: supported,
          ),
          FluentStackedBarLineDatum(
            y: 20,
            legend: 'Recommended Builds',
            color: recommended,
          ),
        ],
        stackCallOutSemantics: const FluentChartSemantics(
          label:
              'Bar stack series 3 of 3, 40 MetaDate1 43% MetaData 27% '
              'MetaDate3 30% Recommended Builds 20 Supported Builds 60',
        ),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalstackedbarchart--vertical-stacked-bar-custom-accessibility',
      FluentVerticalStackedBarChart(
        chartTitle: 'Vertical stacked bar chart custom accessibility example',
        // `barGapMax` starts at 2. `legendProps.allowFocusOnLegends` only
        // changes focus order, which a still frame cannot show.
        barGapMax: 2,
        data: data,
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
      ),
      // Measured 0.067% — 144 px. 56 are the two line-legend swatches drawn
      // 4px tall against upstream's 6 (content box plus 1px border). The
      // other 88 are antialiasing along the shallow "Supported Builds" line,
      // whose centre agrees with Oracle B's to 0.1px.
      maxMismatch: 0.08,
    );
  });

  testWidgets('VerticalStackedBarDateAxis', (tester) async {
    final c8 = _token(FluentDataVizToken.color8);
    final c9 = _token(FluentDataVizToken.color9);
    final c10 = _token(FluentDataVizToken.color10);
    List<FluentStackedBarDatum> points(double a, double b, double c) =>
        <FluentStackedBarDatum>[
          FluentStackedBarDatum(legend: 'meta data 1', data: a, color: c8),
          FluentStackedBarDatum(legend: 'Meta data 2', data: b, color: c9),
          FluentStackedBarDatum(legend: 'meta Data 3', data: c, color: c10),
        ];
    final firstChartPoints = points(2, 0.5, 0);
    final secondChartPoints = points(30, 3, 40);
    final thirdChartPoints = points(10, 60, 30);
    // `new Date("2018/03/01")` is LOCAL midnight, and `useUTC={false}` keeps
    // the scale local too, so the reference is these calendar dates on the
    // capture browser's clock: Europe/Istanbul, +03:00 all year since 2016.
    // A local scale in a zone with DST stretches the months it spans, so the
    // same calendar dates go on a UTC scale (`useUTC: true` below), which
    // draws the reference's picture in every zone.
    final dates = <DateTime>[
      DateTime.utc(2018, 3),
      DateTime.utc(2018, 5),
      DateTime.utc(2018, 7),
      DateTime.utc(2018, 9),
      DateTime.utc(2018, 11),
      DateTime.utc(2019, 2),
      DateTime.utc(2019, 5),
      DateTime.utc(2019, 7),
      DateTime.utc(2019, 9),
    ];
    final chartPoints = <List<FluentStackedBarDatum>>[
      firstChartPoints,
      secondChartPoints,
      thirdChartPoints,
      firstChartPoints,
      thirdChartPoints,
      firstChartPoints,
      secondChartPoints,
      thirdChartPoints,
      firstChartPoints,
    ];
    final data = <FluentVerticalStackedBarGroup>[
      for (var i = 0; i < dates.length; i++)
        FluentVerticalStackedBarGroup(
          chartData: chartPoints[i],
          xAxisPoint: dates[i],
        ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalstackedbarchart--vertical-stacked-bar-date-axis',
      FluentVerticalStackedBarChart(
        chartTitle: 'Vertical stacked bar chart styled example',
        data: data,
        // Initial `barGapMax` 2, `barCornerRadius` 2, `barMinimumHeight` 1,
        // `selectedCallout` "MultiCallout".
        barGapMax: 2,
        barCornerRadius: 2,
        barMinimumHeight: 1,
        isCalloutForStack: true,
        onBarClick: (_) {},
        props: FluentCartesianChartProps(
          yAxisTickCount: 10,
          tickValues: dates,
          // Upstream passes `tickFormat="%m/%d"`. The port has no string
          // `tickFormat` prop for this chart (`FluentTickParams.tickFormat` is
          // only reachable through the delegate), so the same d3 specifier is
          // spelled as the formatter it produces.
          customDateTimeFormatter: (date) =>
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.day.toString().padLeft(2, '0')}',
          yMaxValue: 120,
          yAxisTickFormat: (x) => '${_jsNumber(x)} h',
          margins: const FluentChartMargins(
            bottom: 35,
            top: 10,
            left: 35,
            right: 0,
          ),
          // Upstream passes `useUTC={false}`; see `dates` above.
          useUTC: true,
        ),
      ),
      // Measured 15.248% — every stack sits at its tick instead of where
      // upstream draws it. `_getScales` (`VerticalStackedBarChart.tsx:866-879`)
      // places bars on a private time scale over [first, last date] and
      // [left + domainMargin, width - right - domainMargin] with NO `.nice()`,
      // so the capture's bars run 51..634 while its ticks run 105..607 on the
      // shell's niced axis (`utilities.ts:465-468`). The port reads the
      // shell's scale (`vertical_stacked_bar_chart.dart`, `segmentsFor`).
      // With the bars moved onto the un-niced scale in a scratch run the
      // story measured 0.000%, so this is the whole of the residual.
      maxMismatch: 15.3,
    );
  });

  testWidgets('VerticalStackedBarNegative', (tester) async {
    FluentStackedBarDatum point(
      String legend,
      double data,
      FluentDataVizToken token,
      String yCallout,
    ) => FluentStackedBarDatum(
      legend: legend,
      data: data,
      color: _token(token),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: yCallout,
    );
    final firstChartPoints = <FluentStackedBarDatum>[
      point('Metadata1', 40, FluentDataVizToken.color1, '68%'),
      point('Metadata2', 5, FluentDataVizToken.color2, '8.5%'),
      point('Metadata3', -20, FluentDataVizToken.color3, '34%'),
      point('Metadata4', 10, FluentDataVizToken.color4, '17%'),
      point('Metadata5', 23, FluentDataVizToken.color5, '39%'),
      point('Metadata6', 0.4, FluentDataVizToken.color6, '0.7%'),
      point('Metadata7', -0.5, FluentDataVizToken.color7, '0.85%'),
      point('Metadata8', -0.3, FluentDataVizToken.color8, '0.5%'),
      point('Metadata9', 0.7, FluentDataVizToken.color9, '1.2%'),
      point('Metadata10', 0.1, FluentDataVizToken.color10, '0.2%'),
    ];
    final secondChartPoints = <FluentStackedBarDatum>[
      point('Metadata1', -30, FluentDataVizToken.color1, '33%'),
      point('Metadata2', -20, FluentDataVizToken.color2, '22%'),
      point('Metadata3', -40, FluentDataVizToken.color3, '45%'),
    ];
    final thirdChartPoints = <FluentStackedBarDatum>[
      point('Metadata1', 44, FluentDataVizToken.color1, '43%'),
      point('Metadata2', 28, FluentDataVizToken.color2, '27%'),
      point('Metadata3', 30, FluentDataVizToken.color3, '30%'),
    ];
    final fourthChartPoints = <FluentStackedBarDatum>[
      point('Metadata1', 88, FluentDataVizToken.color1, '63%'),
      point('Metadata2', 22, FluentDataVizToken.color2, '16%'),
      point('Metadata3', 30, FluentDataVizToken.color3, '21%'),
    ];
    final supported = _token(FluentDataVizToken.color5);
    final recommended = _token(FluentDataVizToken.color9);
    List<FluentStackedBarLineDatum> lines(double s, [double? r]) =>
        <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: s,
            legend: 'Supported Builds',
            color: supported,
          ),
          if (r != null)
            FluentStackedBarLineDatum(
              y: r,
              legend: 'Recommended Builds',
              color: recommended,
            ),
        ];
    // `showLine` starts true.
    final data = <FluentVerticalStackedBarGroup>[
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 0,
        lineData: lines(42, 10),
      ),
      FluentVerticalStackedBarGroup(
        chartData: secondChartPoints,
        xAxisPoint: 20,
        lineData: lines(33),
      ),
      FluentVerticalStackedBarGroup(
        chartData: thirdChartPoints,
        xAxisPoint: 40,
        lineData: lines(60, 20),
      ),
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 60,
        lineData: lines(41, 10),
      ),
      FluentVerticalStackedBarGroup(
        chartData: fourthChartPoints,
        xAxisPoint: 80,
        lineData: lines(100, 70),
      ),
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 100,
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalstackedbarchart--vertical-stacked-bar-negative',
      FluentVerticalStackedBarChart(
        // `window.navigator.language` in the capture browser.
        culture: 'en-US',
        chartTitle: 'Vertical stacked bar chart basic example',
        // Initial state: `barGapMax` 2, `showLine` true, `hideLabels` false,
        // `showAxisTitles` true (so the first branch and its margins),
        // `roundCorners` false, `legendMultiSelect` false. The `svgTooltip`
        // style only paints an axis-label tooltip on hover.
        barGapMax: 2,
        data: data,
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
        props: const FluentCartesianChartProps(
          margins: FluentChartMargins(top: 20, bottom: 55, right: 40, left: 60),
          reflowMode: FluentChartReflowMode.minWidth,
          yAxisTitle: 'Variation of number of sales',
          xAxisTitle: 'Number of days',
          roundedTicks: true,
        ),
      ),
      // Measured 0.166% — 351 px. 241 are the "+7 more" overflow trigger:
      // its label is not in the manifest's text mask (the capture only masks
      // leaf elements and the MenuButton label has an icon sibling), so 195
      // px are Skia-vs-Chromium glyphs; the Selawik Semibold label runs wide,
      // pushing the chevron (22) and the right border (24) about a pixel. 67
      // are U+2212 tofu boxes (the −50/−100 ticks and the "−90" total), 14
      // the Metadata5 swatch painted at x 408.19 where Chromium snaps to 408,
      // and the last 29 antialiasing along the lines.
      maxMismatch: 0.18,
    );
  });

  testWidgets('VerticalStackedBarSecondaryYAxis', (tester) async {
    List<FluentStackedBarDatum> points(
      double a,
      double b,
      double c,
      double d,
      double e,
    ) => <FluentStackedBarDatum>[
      FluentStackedBarDatum(
        legend: 'Electronics',
        data: a,
        color: _token(FluentDataVizToken.color1),
      ),
      FluentStackedBarDatum(
        legend: 'Furniture',
        data: b,
        color: _token(FluentDataVizToken.color2),
      ),
      FluentStackedBarDatum(
        legend: 'Clothing',
        data: c,
        color: _token(FluentDataVizToken.color3),
      ),
      FluentStackedBarDatum(
        legend: 'Groceries',
        data: d,
        color: _token(FluentDataVizToken.color4),
      ),
      FluentStackedBarDatum(
        legend: 'Toys',
        data: e,
        color: _token(FluentDataVizToken.color5),
      ),
    ];
    List<FluentStackedBarLineDatum> target(double y) =>
        <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: y,
            legend: 'Sales Target',
            color: _token(FluentDataVizToken.color9),
            useSecondaryYScale: true,
          ),
        ];
    final data = <FluentVerticalStackedBarGroup>[
      FluentVerticalStackedBarGroup(
        chartData: points(120, 80, 150, 200, 90),
        xAxisPoint: 0,
        lineData: target(150),
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(140, 100, 130, 220, 110),
        xAxisPoint: 20,
        lineData: target(180),
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(160, 120, 140, 250, 100),
        xAxisPoint: 40,
        lineData: target(200),
      ),
      FluentVerticalStackedBarGroup(
        chartData: points(180, 140, 160, 300, 120),
        xAxisPoint: 60,
        lineData: target(250),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalstackedbarchart--vertical-stacked-bar-secondary-y-axis',
      FluentVerticalStackedBarChart(
        chartTitle: 'Vertical stacked bar chart secondary y-axis example',
        data: data,
        barGapMax: 2,
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
        props: const FluentCartesianChartProps(
          hideTickOverlap: true,
          yAxisTitle: 'Variation of number of sales',
          xAxisTitle: 'Number of days',
          // `secondaryYScaleOptions={{}}`.
          secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
        ),
      ),
      // Measured 0.083% — 160 px. 56 are the Furniture and Clothing swatches
      // painted at x 122.41 / 208.23 where Chromium snaps the div to whole
      // pixels, 28 the "Sales Target" line swatch drawn 4px tall against
      // upstream's 6, and 76 antialiasing along the secondary-scale line,
      // whose centre agrees with Oracle B's to 0.1px.
      maxMismatch: 0.09,
    );
  });
}
