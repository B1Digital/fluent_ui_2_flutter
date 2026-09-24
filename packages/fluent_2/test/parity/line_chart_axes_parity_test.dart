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
// Two residuals these stories used to share are gone: the legend swatch after
// "From_Legacy_to_O365" (x 184.34) now snaps to device pixels as Chromium's
// does, where it cost 28px a story, and `loadParityFonts` gives U+2212 MINUS
// SIGN a real fallback glyph, where `flutter test` drew a tofu box that stuck
// out of every negative label's mask.
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
      // Measured 0.000% — not one of 190,723 unmasked pixels differs. It was
      // 0.026%: the fractional "All" swatch and the U+2212 tofu of "−304.3k"
      // (see the header).
      maxMismatch: 0,
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
      // Measured 0.005% — 9 of 191,539 px, aligned: 5 are antialiasing where
      // the two lines cross at x 215-225, and 4 are the left fringe of the
      // "151k" tick's leading "1", which Selawik's tabular digits set a pixel
      // left of its mask. It was 0.071% with the U+2212 tofu of "−151k" and
      // "−302k" and the fractional "All" swatch (see the header).
      maxMismatch: 0.005,
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
      // Measured 0.008% — 16 of 201,528 px, aligned, all antialiasing on the
      // 4px lines' edges: 14 along a shallow stretch of the magenta "All"
      // line (x 205-214) and two single pixels. It was 0.022% with the
      // fractional "All" legend swatch (see the header).
      maxMismatch: 0.01,
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
      // Measured 0.018% — 37 of 206,258 px, aligned, all antialiasing along
      // the two shallow diagonals: 24 on the orange one at x 449-472 and 13
      // on both lines near x 186-217. It was 0.026% with
      // the fractional "Series 2" legend swatch.
      maxMismatch: 0.02,
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
      // Measured 0.001% — 2 of 195,855 px, aligned: the left fringe of the
      // "141" tick's leading "1", which Selawik's tabular digits set a pixel
      // left of its mask. It was 0.068% with the U+2212 tofu of "−141",
      // "−282", "−150" and "−300" and the fractional "All" swatch (see the
      // header).
      maxMismatch: 0.002,
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
      // Measured 0.000% — not one of 200,611 unmasked pixels differs. It was
      // 9.688% while `d3.min`/`d3.max` refused to compare the numeric x with
      // the Date one and the date domain dropped every numeric extent, which
      // drew every line at a single x under a lone "02 AM" tick. Mixed number
      // and Date x values now compare by `valueOf`, as JS does, and the
      // fractional "All" swatch is gone too (see the header).
      maxMismatch: 0,
    );
  });
}
