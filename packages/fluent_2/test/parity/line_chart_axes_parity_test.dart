// Pixel parity for the LineChart axis stories — negative domains, a custom
// time locale, log scales, a secondary y scale and the large-data engine —
// against the live @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded: a chart fed different data than the reference is a
// comparison of two different pictures.
//
// The capture browser ran in Europe/Istanbul (UTC+3, no DST since 2016). Two
// stories depend on it: large-data builds its x values with the local-time
// `Date.setHours`, and it and custom-locale leave `useUTC` unset, so d3's local
// `scaleTime().nice()` rounds their domains to Istanbul month boundaries —
// Oracle B's first large-data point sits 3 hours inside the domain, at 35.189
// rather than 35, which is exactly that offset. CI runs `flutter test` in UTC,
// where a local scale sits three hours off that picture, so both stories draw
// a UTC scale (`useUTC: true`) over `_istanbul` of every instant: the
// reference's own wall clock, and the same picture in every zone. A UTC
// recapture would make `_istanbul` the identity, but Chrome 153 on the live
// storybook no longer reproduces these 9.3.23 PNGs pixel for pixel even in
// Istanbul, so they were kept.
//
// Two residuals recur below and are named once here:
//   * a legend swatch after the first label paints at a fractional x (184.34
//     after "From_Legacy_to_O365"), which Chromium pixel-snaps to 184 and
//     Flutter antialiases across 184 and 198 — 28px per story;
//   * d3-format writes negatives with U+2212 MINUS SIGN, which Segoe UI has
//     and the bundled Selawik does not, so `flutter test` draws a tofu box
//     wider than the minus and part of it lands outside the label mask.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/internal/d3/time_format.dart' as d3;
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/line_chart.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

Color _palette(FluentDataVizToken token) => FluentDataVizPalette.resolve(token);

/// The capture browser's +03:00 offset (see the header).
const Duration _istanbulOffset = Duration(hours: 3);

/// The capture browser's Europe/Istanbul wall clock at the instant [utc], as a
/// UTC date. Every story date is later than 2016, Istanbul's last DST change.
DateTime _istanbul(DateTime utc) => utc.add(_istanbulOffset);

FluentLineChartDataPoint _p(DateTime x, double y) =>
    FluentLineChartDataPoint(x: x, y: y);

/// `LineChartNegative` and `LineChartAllNegative` share LineChartBasic's dates
/// and magnitudes and differ only in each y's sign, so the two stories are one
/// builder over the signs their sources spell out.
FluentChartData _signedBasicData({
  required List<int> legacySigns,
  required List<int> allSigns,
  required int singleSign,
}) {
  const legacy = <double>[
    216000,
    218123,
    217124,
    248000,
    252000,
    274000,
    260000,
    304000,
    218000,
  ];
  final legacyX = <DateTime>[
    DateTime.utc(2020, 3, 3, 0),
    DateTime.utc(2020, 3, 3, 10),
    DateTime.utc(2020, 3, 3, 11),
    DateTime.utc(2020, 3, 4),
    DateTime.utc(2020, 3, 5),
    DateTime.utc(2020, 3, 6),
    DateTime.utc(2020, 3, 7),
    DateTime.utc(2020, 3, 8),
    DateTime.utc(2020, 3, 9),
  ];
  const all = <double>[297000, 284000, 282000, 294000, 224000, 300000, 298000];
  return FluentChartData(
    chartTitle: 'Line Chart',
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'From_Legacy_to_O365',
        color: _palette(FluentDataVizToken.color3),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        data: <Object>[
          for (var i = 0; i < legacy.length; i++)
            _p(legacyX[i], legacySigns[i] * legacy[i]),
        ],
      ),
      FluentLineChartSeries(
        legend: 'All',
        color: _palette(FluentDataVizToken.color4),
        lineOptions: const FluentLineOptions(lineBorderWidth: 4),
        data: <Object>[
          for (var i = 0; i < all.length; i++)
            _p(DateTime.utc(2020, 3, 3 + i), allSigns[i] * all[i]),
        ],
      ),
      FluentLineChartSeries(
        legend: 'single point',
        color: _palette(FluentDataVizToken.color5),
        data: <Object>[_p(DateTime.utc(2020, 3, 5, 12), singleSign * 232000)],
      ),
    ],
  );
}

/// The props LineChartNegative and LineChartAllNegative pass, with the story's
/// initial state: `showAxisTitles` and `useUTC` start true.
const FluentCartesianChartProps _negativeProps = FluentCartesianChartProps(
  yMinValue: 200,
  yMaxValue: 301,
  xAxisTickCount: 10,
  useUTC: true,
  yAxisTitle: 'Different categories of mail flow',
  xAxisTitle: 'Values of each category',
);

/// `d3-time-format/locale/it-IT.json` at the 3.0.0 the storybook bundles
/// (`crawlers/fluentui-react-charts/node_modules/d3-time-format`).
const d3.TimeLocaleDefinition _itIT = d3.TimeLocaleDefinition(
  dateTime: '%A %e %B %Y, %X',
  date: '%d/%m/%Y',
  time: '%H:%M:%S',
  periods: <String>['AM', 'PM'],
  days: <String>[
    'Domenica',
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
  ],
  shortDays: <String>['Dom', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'],
  months: <String>[
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ],
  shortMonths: <String>[
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic',
  ],
);

void main() {
  setUpAll(loadParityFonts);

  testWidgets('LineChartAllNegative', (tester) async {
    await expectReactParity(
      tester,
      'charts-linechart--line-chart-all-negative',
      FluentLineChart(
        data: _signedBasicData(
          legacySigns: const <int>[-1, -1, -1, -1, -1, -1, -1, -1, -1],
          allSigns: const <int>[-1, -1, -1, -1, -1, -1, -1],
          singleSign: -1,
        ),
        props: _negativeProps,
        // `window.navigator.language` in the capture browser.
        culture: 'en-US',
      ),
      // Measured 0.026% — 28px: the "All" legend swatch at x 184.34, which
      // Chromium snaps to 184 and Flutter paints fractionally (see the header);
      // 22px: the U+2212 tofu of "−304.3k" poking out of its label mask.
      maxMismatch: 0.03,
    );
  });

  testWidgets('LineChartNegative', (tester) async {
    await expectReactParity(
      tester,
      'charts-linechart--line-chart-negative',
      FluentLineChart(
        data: _signedBasicData(
          legacySigns: const <int>[-1, 1, -1, 1, -1, 1, -1, 1, -1],
          allSigns: const <int>[1, -1, 1, -1, 1, -1, 1],
          singleSign: 1,
        ),
        props: _negativeProps,
        culture: 'en-US',
      ),
      // Measured 0.071% — 99px: the U+2212 tofu of "−151k" and "−302k", wider
      // than the minus and so outside the reference's label mask; 28px: the
      // fractional "All" legend swatch; 4px Selawik-600 fringe; 5px AA where
      // the two lines cross.
      maxMismatch: 0.08,
    );
  });

  testWidgets('LineChartCustomLocaleDateAxis', (tester) async {
    final data = FluentChartData(
      chartTitle: 'Line Chart',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'From_Legacy_to_O365',
          color: _palette(FluentDataVizToken.color1),
          lineOptions: const FluentLineOptions(lineBorderWidth: 4),
          data: <Object>[
            _p(_istanbul(DateTime.utc(2020, 3, 3)), 216000),
            _p(_istanbul(DateTime.utc(2020, 4, 3, 10)), 218123),
            _p(_istanbul(DateTime.utc(2020, 5, 5, 11)), 217124),
            _p(_istanbul(DateTime.utc(2020, 7, 14)), 248000),
            _p(_istanbul(DateTime.utc(2020, 11, 15)), 252000),
            _p(_istanbul(DateTime.utc(2020, 12, 6)), 274000),
            _p(_istanbul(DateTime.utc(2021, 1, 7)), 260000),
            _p(_istanbul(DateTime.utc(2021, 2, 14)), 304000),
            _p(_istanbul(DateTime.utc(2021, 3, 9)), 218000),
          ],
        ),
        FluentLineChartSeries(
          legend: 'All',
          color: _palette(FluentDataVizToken.color2),
          lineOptions: const FluentLineOptions(lineBorderWidth: 4),
          data: <Object>[
            _p(_istanbul(DateTime.utc(2020, 3, 3)), 297000),
            _p(_istanbul(DateTime.utc(2020, 4, 4)), 284000),
            _p(_istanbul(DateTime.utc(2020, 5, 5)), 282000),
            _p(_istanbul(DateTime.utc(2020, 6, 6)), 294000),
            _p(_istanbul(DateTime.utc(2020, 9, 16)), 224000),
            _p(_istanbul(DateTime.utc(2021, 2, 8)), 300000),
            _p(_istanbul(DateTime.utc(2021, 3, 9)), 298000),
          ],
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-linechart--line-chart-custom-locale-date-axis',
      FluentLineChart(
        data: data,
        // Upstream passes `culture={"rs-ss"}`, a well-formed tag no runtime
        // has data for. ECMA-402's `toLocaleString` (`formatter.ts:95`) falls
        // back to the default locale for it, and so does the port's
        // `formatDateToLocaleString` (`tick_format.dart`, `_resolveCulture`).
        // It reaches only the popover text, never a pixel of this still
        // render; passing it proves the chart builds and hit-tests with it.
        culture: 'rs-ss',
        props: const FluentCartesianChartProps(
          yMinValue: 200,
          yMaxValue: 301,
          xAxisTickCount: 10,
          margins: FluentChartMargins(left: 35, top: 20, bottom: 35, right: 20),
          timeFormatLocale: _itIT,
          // Upstream leaves `useUTC` unset; see the header.
          useUTC: true,
        ),
      ),
      // Measured 0.022% — 28px: the fractional "All" legend swatch; the rest
      // is antialiasing where the 4px lines join at the first point.
      maxMismatch: 0.03,
    );
  });

  testWidgets('LineChartLogAxisExample', (tester) async {
    // `xScaleType` and `yScaleType` both start at 'log'.
    final data = FluentChartData(
      chartTitle: 'Line Chart',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'Series 1',
          color: _palette(FluentDataVizToken.color1),
          data: <Object>[
            for (var i = 0; i <= 8; i++)
              FluentLineChartDataPoint(x: i, y: (8 - i).toDouble()),
          ],
        ),
        FluentLineChartSeries(
          legend: 'Series 2',
          color: _palette(FluentDataVizToken.warning),
          data: <Object>[
            for (var i = 0; i <= 8; i++)
              FluentLineChartDataPoint(x: i, y: i.toDouble()),
          ],
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-linechart--line-chart-log-axis-example',
      FluentLineChart(
        data: data,
        props: const FluentCartesianChartProps(
          hideTickOverlap: true,
          xScaleType: FluentAxisScaleType.log,
          yScaleType: FluentAxisScaleType.log,
        ),
      ),
      // Measured 0.026% — 16px: the fractional "Series 2" legend swatch; the
      // rest is antialiasing along the two diagonals near their markers.
      maxMismatch: 0.03,
    );
  });

  testWidgets('LineChartSecondaryYAxis', (tester) async {
    final data = FluentChartData(
      chartTitle: 'Line Chart',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'From_Legacy_to_O365',
          color: _palette(FluentDataVizToken.color3),
          data: <Object>[
            _p(DateTime.utc(2020, 3, 3), 216),
            _p(DateTime.utc(2020, 3, 3, 10), 218),
            _p(DateTime.utc(2020, 3, 3, 11), 217),
            _p(DateTime.utc(2020, 3, 4), 248),
            _p(DateTime.utc(2020, 3, 5), -252),
            _p(DateTime.utc(2020, 3, 6), 274),
            _p(DateTime.utc(2020, 3, 7), -260),
            _p(DateTime.utc(2020, 3, 8), 304),
            _p(DateTime.utc(2020, 3, 9), 218),
          ],
        ),
        FluentLineChartSeries(
          legend: 'All',
          color: _palette(FluentDataVizToken.color4),
          useSecondaryYScale: true,
          data: <Object>[
            _p(DateTime.utc(2020, 3, 3), 297),
            _p(DateTime.utc(2020, 3, 4), 284),
            _p(DateTime.utc(2020, 3, 5), 282),
            _p(DateTime.utc(2020, 3, 6), -294),
            _p(DateTime.utc(2020, 3, 7), 224),
            _p(DateTime.utc(2020, 3, 8), -300),
            _p(DateTime.utc(2020, 3, 9), 298),
          ],
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-linechart--line-chart-secondary-y-axis',
      FluentLineChart(
        data: data,
        props: const FluentCartesianChartProps(
          useUTC: true,
          hideTickOverlap: true,
          // `secondaryYScaleOptions={{}}`.
          secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
        ),
      ),
      // Measured 0.068% — 103px: the U+2212 tofu of "−141", "−282" (left)
      // and "−150", "−300" (right, start-anchored, so it pushes the trailing
      // digit out of the mask); 28px: the fractional "All" legend swatch; 2px
      // Selawik-600 fringe.
      maxMismatch: 0.08,
    );
  });

  testWidgets('LineChartLargeData', (tester) async {
    // `new Date(startdate).setHours(startdate.getHours() + i)` returns epoch
    // MILLISECONDS, not a Date, so the first two series carry numeric x. The
    // axis is still a date axis because `getXAxisType` (`utilities.ts:1330`)
    // reads the LAST series — "single point", whose x is a Date. In the
    // capture's zone (UTC+3, no DST) the setHours arithmetic is exactly
    // `start + i` hours.
    const start = 1583020800000; // Date.parse('2020-03-01T00:00:00.000Z')
    const hour = 3600000;
    // `start` on the capture's wall clock; see the header.
    final from = start + _istanbulOffset.inMilliseconds;
    double getY(int i) {
      final n = i % 1000;
      return n < 500 ? (n * n).toDouble() : (1000000 - n * n).toDouble();
    }

    final data = FluentChartData(
      chartTitle: 'Line Chart',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'From_Legacy_to_O365',
          color: _palette(FluentDataVizToken.color1),
          hideInactiveDots: true,
          lineOptions: const FluentLineOptions(lineBorderWidth: 4),
          data: <Object>[
            for (var i = 0; i < 10000; i++)
              FluentLineChartDataPoint(x: from + i * hour, y: 500000),
          ],
        ),
        FluentLineChartSeries(
          legend: 'All',
          color: _palette(FluentDataVizToken.success),
          lineOptions: const FluentLineOptions(lineBorderWidth: 4),
          data: <Object>[
            for (var i = 1000; i < 9000; i++)
              FluentLineChartDataPoint(x: from + i * hour, y: getY(i)),
          ],
        ),
        FluentLineChartSeries(
          legend: 'single point',
          color: _palette(FluentDataVizToken.color10),
          data: <Object>[_p(_istanbul(DateTime.utc(2020, 3, 5)), 282000)],
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-linechart--line-chart-large-data',
      FluentLineChart(
        data: data,
        culture: 'en-US',
        optimizeLargeData: true,
        props: const FluentCartesianChartProps(
          yMinValue: 200,
          yMaxValue: 301,
          margins: FluentChartMargins(left: 35, top: 20, bottom: 35, right: 20),
          // Upstream leaves `useUTC` unset; see the header.
          useUTC: true,
        ),
      ),
      // Measured 9.688% — all of it a port defect: `d3.min`/`d3.max`
      // (`internal/d3/array_stats.dart:6-17`) refuse to compare a num with a
      // DateTime where JS compares both by `valueOf`, and the date domain
      // (`axis/domain_range.dart:444-452`) then drops every numeric extent, so
      // the domain collapses to the one Date — every line is drawn at a single
      // x under a lone "02 AM" tick. Re-typed as `DateTime` x the same story
      // measures 0.014%, so re-pin to that once mixed x is coerced.
      maxMismatch: 9.7,
    );
  });
}
