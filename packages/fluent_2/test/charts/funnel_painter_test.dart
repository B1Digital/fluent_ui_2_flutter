import 'dart:ui' as ui;

import 'package:fluent_2/src/charts/funnel_chart.dart';
import 'package:fluent_2/src/charts/internal/chart_colors.dart';
import 'package:fluent_2/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// Records the drawing calls the funnel painter makes, so a test can read the
/// resolved fill of every segment and the origin of every laid-out label
/// without going through a raster.
///
/// [noSuchMethod] absorbs the rest of [Canvas]; the painter calls nothing else
/// that a test here asserts on.
class _RecordingCanvas implements Canvas {
  /// The colour of every `drawPath`, in paint order.
  final List<Color> fills = <Color>[];

  /// The origin of every laid-out label, in paint order.
  final List<Offset> paragraphs = <Offset>[];

  @override
  void drawPath(Path path, Paint paint) => fills.add(paint.color);

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphs.add(offset);

  @override
  void saveLayer(Rect? bounds, Paint paint) {}

  @override
  void restore() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Adjacent trapezia share an exact edge with no stroke and no overlap
/// (`FunnelChart.tsx:229-273`). SVG composites them without a seam; Flutter's
/// antialiasing blends two half-covered edge pixels and leaves a visible
/// hairline. The painter therefore adds every fill into one `saveLayer`, and
/// the two hairline tests below are what prove the seam is gone — the second
/// one especially, because a shared edge that lands on the pixel grid never had
/// a seam to begin with.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final chartColors = FluentChartColors.of(theme);
  const fill = Color(0xFF0F6CBD);

  Future<ui.Image> raster(CustomPainter painter, Size size) async {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    return recorder.endRecording().toImage(
      size.width.ceil(),
      size.height.ceil(),
    );
  }

  FluentFunnelSegment segment(
    Rect rect, {
    double opacity = 1,
    String? label,
    Color color = fill,
  }) => FluentFunnelSegment(
    key: '${rect.top}',
    geometry: FluentFunnelSegmentGeometry(
      path: Path()..addRect(rect),
      textX: rect.center.dx,
      textY: rect.center.dy,
      availableWidth: rect.width,
    ),
    fill: color,
    opacity: opacity,
    label: label,
  );

  FluentFunnelChartPainter painterOf(
    List<FluentFunnelSegment> segments, {
    FluentThemeData? withTheme,
    TextDirection textDirection = TextDirection.ltr,
    double funnelWidth = 40,
  }) {
    final resolved = withTheme ?? theme;
    return FluentFunnelChartPainter(
      segments: segments,
      labelStyle: resolved.typography.body1,
      colors: resolved.colors,
      chartColors: FluentChartColors.of(resolved),
      textDirection: textDirection,
      funnelWidth: funnelWidth,
    );
  }

  test(
    'two same-coloured neighbours leave no hairline on their shared edge',
    () async {
      final image = await raster(
        painterOf(<FluentFunnelSegment>[
          segment(const Rect.fromLTWH(0, 0, 40, 20)),
          segment(const Rect.fromLTWH(0, 20, 40, 20)),
        ]),
        const Size(40, 40),
      );
      final data = await image.toByteData();
      for (var x = 0; x < 40; x++) {
        final offset = (19 * 40 + x) * 4;
        expect(
          data!.getUint32(offset),
          0x0F6CBDFF,
          reason:
              'The pixel row on the shared edge must be the fill colour '
              'exactly. Painting the two paths separately blends the edge and '
              'leaves a lighter line; a single saveLayer does not.',
        );
      }
    },
  );

  test('a shared edge off the pixel grid leaves no hairline either', () async {
    // 20.4 puts the shared edge inside pixel row 20, which is where a plain
    // source-over pair blends: the first path covers 40 per cent of the row
    // over the transparent ground, the second covers the remaining 60 per cent
    // over that, and 21 per cent of the ground survives as a lighter line. A
    // funnel's edges are almost never integral, so this is the case that
    // matters.
    final image = await raster(
      painterOf(<FluentFunnelSegment>[
        segment(const Rect.fromLTWH(0, 0, 40, 20.4)),
        segment(const Rect.fromLTWH(0, 20.4, 40, 19.6)),
      ]),
      const Size(40, 40),
    );
    final data = await image.toByteData();
    for (var x = 0; x < 40; x++) {
      final pixel = data!.getUint32((20 * 40 + x) * 4);
      expect(
        pixel & 0xFF,
        0xFF,
        reason:
            'Pixel row 20 straddles the shared edge, so the two segments must '
            'cover it between them. Source-over leaves this at 194 — a quarter '
            'of the transparent ground survives as the hairline.',
      );
      for (final shift in <int>[24, 16, 8]) {
        expect(
          (pixel >> shift) & 0xFF,
          closeTo((0x0F6CBDFF >> shift) & 0xFF, 1),
          reason:
              'Channel at bit $shift of the seam pixel. Adding two coverages '
              'that sum to one reproduces the fill to within the one unit in '
              '255 that the premultiplied round trip costs.',
        );
      }
    }
  });

  test('a dimmed segment rasterises to alpha 26', () async {
    final image = await raster(
      painterOf(<FluentFunnelSegment>[
        segment(const Rect.fromLTWH(0, 0, 40, 40), opacity: 0.1),
      ]),
      const Size(40, 40),
    );
    final data = await image.toByteData();
    expect(
      data!.getUint32((20 * 40 + 20) * 4) & 0xFF,
      26,
      reason: 'FunnelChart.tsx:302 dims to 0.1, and (0.1 * 255).round() is 26.',
    );
  });

  test('the label colour flips when the fill is too dark for foreground1', () {
    expect(
      fluentContrastTextColor(const Color(0xFF0F6CBD), theme.colors).toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason:
          'utilities/colors.ts:175-182 — start from '
          'colorNeutralForeground1 and, when the contrast against the fill '
          'falls under 3, swap to colorNeutralBackground1.',
    );
  });

  test('the label colour stays foreground1 on a pale fill', () {
    expect(
      fluentContrastTextColor(const Color(0xFFEBF3FC), theme.colors).toARGB32(),
      theme.colors.neutralForeground1.toARGB32(),
      reason: 'A pale fill already clears the threshold of 3.',
    );
  });

  test('the painter exposes the paths in reverse order for hit testing', () {
    final painter = painterOf(<FluentFunnelSegment>[
      segment(const Rect.fromLTWH(0, 0, 40, 20)),
      segment(const Rect.fromLTWH(0, 20, 40, 20)),
    ]);
    expect(
      painter.segmentAt(const Offset(20, 30))?.key,
      '20.0',
      reason:
          'Hit testing walks the segments in reverse paint order so the '
          'topmost one wins, which matters where two trapezia touch.',
    );
    expect(
      painter.segmentAt(const Offset(20, 60)),
      isNull,
      reason: 'A point outside every path selects nothing.',
    );
  });

  test('every fill flattens to one system colour under high contrast', () {
    final highContrast = FluentThemeData.highContrast(
      fontPlatform: FluentFontPlatform.web,
    );
    final canvas = _RecordingCanvas();
    painterOf(<FluentFunnelSegment>[
      segment(
        const Rect.fromLTWH(0, 0, 40, 20),
        color: const Color(0xFF0F6CBD),
      ),
      segment(
        const Rect.fromLTWH(0, 20, 40, 20),
        color: const Color(0xFFE3008C),
      ),
    ], withTheme: highContrast).paint(canvas, const Size(40, 40));
    expect(
      canvas.fills.map((color) => color.toARGB32()).toList(),
      <int>[
        highContrast.colors.neutralForeground1.toARGB32(),
        highContrast.colors.neutralForeground1.toARGB32(),
      ],
      reason:
          'Spec 5.3 — upstream segments carry no forced-color-adjust, so a '
          'forced-colours browser rewrites every fill to CanvasText. Without '
          'FluentChartColors.flattenMark the forty-colour palette survives '
          'here and the funnel is invisible in high contrast.',
    );
  });

  test('a dimmed fill keeps its opacity after flattening', () {
    final canvas = _RecordingCanvas();
    painterOf(<FluentFunnelSegment>[
      segment(const Rect.fromLTWH(0, 0, 40, 40), opacity: 0.1),
    ]).paint(canvas, const Size(40, 40));
    expect(
      canvas.fills.single.a,
      closeTo(0.1, 1e-6),
      reason: 'FunnelChart.tsx:302 — the dimmed segment is drawn at 0.1.',
    );
  });

  test('the label colour is the contrast colour at the segment opacity', () {
    final painter = painterOf(<FluentFunnelSegment>[
      segment(const Rect.fromLTWH(0, 0, 40, 40), opacity: 0.1, label: '1000'),
    ]);
    final colour = painter.labelColorFor(painter.segments.single);
    expect(
      colour.withValues(alpha: 1).toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason:
          'FunnelChart.tsx:253 passes the segment fill to getContrastTextColor, '
          'and 0xFF0F6CBD is too dark for colorNeutralForeground1.',
    );
    expect(
      colour.a,
      closeTo(0.1, 1e-6),
      reason:
          'FunnelChart.tsx:216 puts the same `opacity` on the <text> as on the '
          '<path>, so a dimmed segment dims its label with it.',
    );
  });

  test('the label baseline is alphabetic, as the capture proves', () {
    final story = loadOracleStory('charts-funnelchart--funnel-chart-basic');
    // The chart title is the only other <text>, at 10px (`Common.styles.ts`).
    final labels = story
        .byTag('text')
        .where((element) => element.fontSize == 14)
        .toList();
    expect(
      labels.length,
      4,
      reason:
          'FunnelChartBasic labels all four stages; a different count means '
          'the filter below stopped selecting the segment labels.',
    );
    for (final label in labels) {
      expect(
        label.dominantBaseline,
        'auto',
        reason:
            'FunnelChart.tsx:215 sets alignment-baseline="middle", which no '
            'browser honours on a <text> element — only dominant-baseline is — '
            'so the capture resolves to the default alphabetic baseline.',
      );
      final bbox = label.bbox!;
      expect(
        label.y! - bbox.top,
        greaterThan(bbox.height / 2),
        reason:
            'The `y` attribute sits below the glyph box centre, which is what '
            'a baseline does and what a centred box would not.',
      );
    }

    // The second stage's label, in the funnel's own coordinate space.
    final label = labels[1];
    final style = theme.typography.body1;
    final metrics = FluentChartTextMeasurer().measure(label.text!, style);
    expect(
      metrics.descent,
      greaterThan(0),
      reason:
          'Without a descent the alphabetic baseline and the box centre '
          'coincide and this test could not tell them apart.',
    );
    final canvas = _RecordingCanvas();
    FluentFunnelChartPainter(
      segments: <FluentFunnelSegment>[
        FluentFunnelSegment(
          key: '1',
          geometry: FluentFunnelSegmentGeometry(
            path: Path()..addRect(const Rect.fromLTWH(0, 0, 480, 368)),
            textX: label.x!,
            textY: label.y!,
            availableWidth: 96,
          ),
          fill: fill,
          opacity: 1,
          label: label.text,
        ),
      ],
      labelStyle: style,
      colors: theme.colors,
      chartColors: chartColors,
      textDirection: TextDirection.ltr,
      funnelWidth: 480,
    ).paint(canvas, const Size(480, 368));
    expect(
      canvas.paragraphs.single.dy + metrics.ascent,
      closeTo(label.y!, kOracleGeometryTolerance),
      reason:
          'The captured `y` is a baseline, so the label origin must sit an '
          'ascent above it. Centring the line box instead would put it at '
          '${label.y! - metrics.height / 2} rather than '
          '${label.y! - metrics.ascent}.',
    );
    expect(
      canvas.paragraphs.single.dx + metrics.width / 2,
      closeTo(label.x!, kOracleGeometryTolerance),
      reason:
          'FunnelChart.tsx:214 anchors the label with text-anchor="middle".',
    );
  });

  test('right-to-left mirrors the label anchor and nothing else', () {
    final canvas = _RecordingCanvas();
    final style = theme.typography.body1;
    final metrics = FluentChartTextMeasurer().measure('600', style);
    painterOf(<FluentFunnelSegment>[
      segment(const Rect.fromLTWH(0, 0, 40, 40), label: '600'),
    ], textDirection: TextDirection.rtl).paint(canvas, const Size(40, 40));
    expect(
      canvas.paragraphs.single.dx + metrics.width / 2,
      closeTo(20, kOracleGeometryTolerance),
      reason:
          'FunnelChart.tsx:210 mirrors the anchor to funnelWidth - x, which is '
          '40 - 20 here. The glyphs themselves are never mirrored: upstream '
          'un-mirrors them with the nested scale(-1,1) at :224.',
    );
  });
}
