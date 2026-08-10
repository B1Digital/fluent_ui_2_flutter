import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/annotation_layer.dart';
import 'package:fluent_2_web/src/charts/chrome/annotation_layer_style.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart';
import 'package:fluent_2_web/src/charts/model/chart_annotation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  // The markup parser is style-agnostic; only the emphasis it layers on top of
  // this base is under test.
  const base = TextStyle(fontSize: 12);
  String flatten(List<InlineSpan> spans) =>
      spans.map((span) => span.toPlainText()).join();

  group('fluentApplyOpacityToColor', () {
    test('null in, null out', () {
      expect(
        fluentApplyOpacityToColor(null, 0.8),
        isNull,
        reason:
            'useChartAnnotationLayer.styles.ts:41-43 returns undefined for a '
            'missing colour.',
      );
    });

    test('an already-translucent colour survives untouched by default', () {
      const translucent = Color(0x800078D4);
      expect(
        fluentApplyOpacityToColor(translucent, 0.8)!.toARGB32(),
        translucent.toARGB32(),
        reason:
            'useChartAnnotationLayer.styles.ts:50-55 — preserveOriginalOpacity '
            'defaults to true, and a parsed colour whose opacity is already '
            'below 1 is returned unchanged.',
      );
    });

    test('an opaque colour takes the requested opacity', () {
      expect(
        fluentApplyOpacityToColor(const Color(0xFF0078D4), 0.8)!.a,
        moreOrLessEquals(0.8, epsilon: 0.005),
        reason: 'useChartAnnotationLayer.styles.ts:57.',
      );
    });

    test('an explicit opacity overrides even a translucent colour', () {
      expect(
        fluentApplyOpacityToColor(
          const Color(0x800078D4),
          0.25,
          preserveOriginalOpacity: false,
        )!.a,
        moreOrLessEquals(0.25, epsilon: 0.005),
        reason:
            'ChartAnnotationLayer.tsx:497 passes preserveOriginalOpacity: '
            'style.opacity === undefined, so a caller who names an opacity '
            'always wins.',
      );
    });

    test('the opacity is clamped into 0..1', () {
      expect(
        fluentApplyOpacityToColor(const Color(0xFF0078D4), 5)!.a,
        1,
        reason:
            'useChartAnnotationLayer.styles.ts:57 — '
            'Math.max(0, Math.min(1, opacity)).',
      );
    });
  });

  group('annotation constants', () {
    test('match the two upstream constant blocks', () {
      expect(
        kAnnotationBackgroundOpacity,
        0.8,
        reason: 'useChartAnnotationLayer.styles.ts:27.',
      );
      expect(kConnectorStartPadding, 12, reason: ':29.');
      expect(kConnectorEndPadding, 0, reason: ':30.');
      expect(kConnectorStrokeWidth, 2, reason: ':31.');
      expect(kMinArrowSize, 6, reason: 'ChartAnnotationLayer.tsx:30.');
      expect(kMaxArrowSize, 24, reason: 'ChartAnnotationLayer.tsx:31.');
      expect(kArrowSizeScale, 0.35, reason: 'ChartAnnotationLayer.tsx:32.');
      expect(kMaxSimpleMarkupDepth, 5, reason: 'ChartAnnotationLayer.tsx:33.');
    });

    test('the padding is 4 vertical and 8 horizontal', () {
      expect(
        kAnnotationPadding,
        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        reason:
            'useChartAnnotationLayer.styles.ts:102-105 sets the four sides '
            'explicitly. The exported DEFAULT_ANNOTATION_PADDING string at :28 '
            'is never read; the class hard-codes the same numbers.',
      );
    });
  });

  group('resolveFluentChartAnnotationLayerStyle', () {
    test('the default background is neutralBackground1 at 0.8', () {
      expect(
        resolveFluentChartAnnotationLayerStyle(
          theme,
        ).backgroundColor!.resolve(<WidgetState>{})!.a,
        moreOrLessEquals(kAnnotationBackgroundOpacity, epsilon: 0.005),
        reason: 'ChartAnnotationLayer.tsx:503.',
      );
    });

    test('the connector stroke is neutralForeground1', () {
      expect(
        resolveFluentChartAnnotationLayerStyle(
          theme,
        ).connectorStrokeColor!.resolve(<WidgetState>{})!.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason: 'useChartAnnotationLayer.styles.ts:72.',
      );
    });

    test('the annotation text is caption1, as the corpus renders it', () {
      final style = resolveFluentChartAnnotationLayerStyle(
        theme,
      ).textStyle!.resolve(<WidgetState>{})!;
      final story = loadOracleStory(
        'charts-linechart--line-chart-annotations-example',
      );
      final divs = _connectorLayer(
        story,
      ).elements.where((element) => element.tag == 'DIV').toList();
      expect(
        divs.length,
        8,
        reason:
            'The story renders four annotations, each a content div inside a '
            'text div; a zero count would make the loop below vacuous.',
      );
      for (final div in divs) {
        expect(
          div.fontSize,
          style.fontSize,
          reason:
              'useChartAnnotationLayer.styles.ts:94 is caption1 — 12px on web '
              '(typography.dart:135). ${div.tag} #${div.index} of '
              '${story.id} reports ${div.fontSize}px, so the axisAnnotation '
              'slot (caption2Strong, 10px) would be wrong here.',
        );
      }
      expect(
        style.color!.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason: 'useChartAnnotationLayer.styles.ts:101.',
      );
    });
  });

  group('the corpus connector layer', () {
    final story = loadOracleStory(
      'charts-linechart--line-chart-annotations-example',
    );

    test('draws every connector at kConnectorStrokeWidth', () {
      final lines = _connectorLayer(
        story,
      ).elements.where((element) => element.tag == 'line').toList();
      expect(
        lines.length,
        2,
        reason:
            'Two of the four annotations in the story carry a connector; a '
            'zero count would make the loop below vacuous.',
      );
      for (final line in lines) {
        expectOracleNumber(
          'useChartAnnotationLayer.styles.ts:31 — the default stroke width the '
          'story does not override, on line #${line.index}',
          kConnectorStrokeWidth,
          line.strokeWidth,
        );
      }
    });

    test(
      'sizes every arrowhead inside the kMinArrowSize..kMaxArrowSize clamp',
      () {
        // ChartAnnotationLayer.tsx:690 —
        // clamp(min(w, h) * ARROW_SIZE_SCALE, MIN_ARROW_SIZE,
        //       min(MAX_ARROW_SIZE, startPadding * 1.25, distance * 0.6)).
        // The marker path is `M0 0 L s s/2 L0 s Z`, so its bbox is s square.
        final markers = _connectorLayer(story).elements
            .where((element) => element.tag == 'path' && element.d != null)
            .toList();
        expect(
          markers.length,
          2,
          reason:
              'One arrowhead marker per connector; a zero count would make the '
              'loop below vacuous.',
        );
        for (final marker in markers) {
          final size = marker.bbox!.width;
          expect(
            size,
            inInclusiveRange(kMinArrowSize, kMaxArrowSize),
            reason:
                'ChartAnnotationLayer.tsx:30-31 bound the clamp; marker '
                '#${marker.index} of ${story.id} is ${size}px.',
          );
          expectOracleNumber(
            'the arrowhead is square — `M0 0 L s s/2 L0 s Z` at '
            'marker #${marker.index}',
            size,
            marker.bbox!.height,
          );
        }
        expectOracleNumber(
          'the larger of the two hits the ceiling exactly, pinning '
          'kMaxArrowSize (ChartAnnotationLayer.tsx:31) rather than merely '
          'bounding it',
          kMaxArrowSize,
          markers.map((marker) => marker.bbox!.width).reduce(math.max),
        );
      },
    );
  });

  group('parseFluentAnnotationMarkup', () {
    test('bold and italic become styled spans', () {
      final spans = parseFluentAnnotationMarkup('a <b>bold</b> c', base);
      expect(
        flatten(spans),
        'a bold c',
        reason: 'ChartAnnotationLayer.tsx:235 renders b as strong and i as em.',
      );
      expect(
        spans.whereType<TextSpan>().any(
          (span) => span.style?.fontWeight == FontWeight.bold,
        ),
        isTrue,
        reason: 'The b tag has to actually embolden its children.',
      );
      expect(
        parseFluentAnnotationMarkup('a <i>lean</i> c', base)
            .whereType<TextSpan>()
            .any((span) => span.style?.fontStyle == FontStyle.italic),
        isTrue,
        reason: 'ChartAnnotationLayer.tsx:235 — i becomes em.',
      );
    });

    test('br becomes a newline', () {
      expect(
        flatten(parseFluentAnnotationMarkup('a<br />b', base)),
        'a\nb',
        reason:
            'ChartAnnotationLayer.tsx:232 renders br as a line break, and '
            ':216 turns it into a newline in the plain-text projection.',
      );
    });

    test('entities decode', () {
      expect(
        flatten(parseFluentAnnotationMarkup('a &amp; b &nbsp;c', base)),
        'a & b \u00a0c',
        reason:
            'ChartAnnotationLayer.tsx:48-53 decodes amp, quot, apos and nbsp; '
            ':52 maps nbsp to U+00A0, not to an ordinary space.',
      );
      expect(
        flatten(parseFluentAnnotationMarkup('&quot;&apos;', base)),
        '"\'',
        reason: 'ChartAnnotationLayer.tsx:50-51.',
      );
    });

    test('numeric references decode', () {
      expect(
        flatten(parseFluentAnnotationMarkup('&#65;&#x42;', base)),
        'AB',
        reason: 'ChartAnnotationLayer.tsx:60-73 handles decimal and hex refs.',
      );
    });

    test('a numeric chevron is re-escaped, never a raw chevron', () {
      expect(
        flatten(parseFluentAnnotationMarkup('&#60;script&#62;', base)),
        '&lt;script&gt;',
        reason:
            'ChartAnnotationLayer.tsx:67-72 re-emits a numeric reference that '
            'resolves to a chevron as &lt; or &gt; rather than as a raw "<", so '
            'the only route onward is the allowlist at :82-97, whose default '
            'arm (:95-96) rejects every name outside b, i and br. This is a '
            'security property and is reproduced exactly.',
      );
    });

    test('a numeric chevron around an allowlisted name still revives', () {
      expect(
        parseFluentAnnotationMarkup('&#60;b&#62;x&#60;/b&#62;', base)
            .whereType<TextSpan>()
            .any((span) => span.style?.fontWeight == FontWeight.bold),
        isTrue,
        reason:
            'The second pass (ChartAnnotationLayer.tsx:78-98) runs over the '
            "first pass's output, so the &lt;b&gt; that :67-72 produced is "
            'revived exactly as a literal &lt;b&gt; would be. The re-escape '
            'bounds the vocabulary; it does not forbid the three safe tags. '
            "The plan expected literal '<b>x</b>' here, which contradicts both "
            'upstream and its own neighbouring &lt;b&gt; test.',
      );
    });

    test('an escaped tag name IS revived', () {
      expect(
        parseFluentAnnotationMarkup('&lt;b&gt;x&lt;/b&gt;', base)
            .whereType<TextSpan>()
            .any((span) => span.style?.fontWeight == FontWeight.bold),
        isTrue,
        reason:
            'ChartAnnotationLayer.tsx:78-98 turns &lt;b&gt; back into a real '
            'tag — but only for the b, i and br names in that switch.',
      );
      expect(
        flatten(parseFluentAnnotationMarkup('&lt;br /&gt;', base)),
        '\n',
        reason:
            'ChartAnnotationLayer.tsx:91-94 accepts three spellings of br, '
            'including the space before the slash after :79 collapses runs of '
            'whitespace.',
      );
    });

    test('an unknown escaped tag stays literal', () {
      expect(
        flatten(parseFluentAnnotationMarkup('&lt;script&gt;', base)),
        '&lt;script&gt;',
        reason:
            'ChartAnnotationLayer.tsx:95-96 falls through to the original '
            'match for any name outside b, i and br.',
      );
    });

    test('an unsupported real tag stays literal', () {
      expect(
        flatten(parseFluentAnnotationMarkup('<u>x</u>', base)),
        '<u>x</u>',
        reason:
            'ChartAnnotationLayer.tsx:178 appends any tag outside b, i and br '
            'as text.',
      );
    });

    test('nesting past depth five is emitted literally', () {
      final deep = '${'<b>' * 6}x${'</b>' * 6}';
      expect(
        flatten(parseFluentAnnotationMarkup(deep, base)),
        contains('<b>'),
        reason:
            'ChartAnnotationLayer.tsx:163-166 emits the opening tag as text '
            'once the stack reaches MAX_SIMPLE_MARKUP_DEPTH '
            '($kMaxSimpleMarkupDepth).',
      );
      expect(
        flatten(
          parseFluentAnnotationMarkup('${'<b>' * 5}x${'</b>' * 5}', base),
        ),
        'x',
        reason:
            'Exactly kMaxSimpleMarkupDepth levels still nest: :163 compares '
            'stack.length - 1 >= MAX_SIMPLE_MARKUP_DEPTH, so the fifth opener '
            'is accepted and only the sixth is literalised.',
      );
    });

    test('an unmatched closer is literal text', () {
      expect(
        flatten(parseFluentAnnotationMarkup('a</b>b', base)),
        'a</b>b',
        reason: 'ChartAnnotationLayer.tsx:160.',
      );
    });

    test('an unclosed opener is re-serialised', () {
      expect(
        flatten(parseFluentAnnotationMarkup('a<b>b', base)),
        'a<b>b</b>',
        reason:
            'ChartAnnotationLayer.tsx:183-205 unwinds the stack and writes the '
            'element back out as literal text, including a closing tag it '
            'never saw.',
      );
      expect(
        flatten(parseFluentAnnotationMarkup('<b>a<br />b', base)),
        '<b>a<br />b</b>',
        reason:
            'ChartAnnotationLayer.tsx:114-125 — serializeSimpleMarkup writes a '
            'br child back as the literal string "<br />".',
      );
    });

    test('empty in, empty out', () {
      expect(
        parseFluentAnnotationMarkup('', base),
        isEmpty,
        reason: 'ChartAnnotationLayer.tsx:128-130.',
      );
    });
  });

  group('fluentAnnotationPlainText', () {
    test('is the default accessible label', () {
      expect(
        fluentAnnotationPlainText('<b>Peak</b><br />Q3'),
        'Peak\nQ3',
        reason:
            'ChartAnnotationLayer.tsx:210-221 and :658 — the plain-text '
            'projection is the aria-label when none is supplied.',
      );
    });
  });

  mainCoordinates();
  mainSizing();
}

/// The coordinate-resolution half of the suite (`ChartAnnotationLayer.tsx`
/// `:243-394`), called from [main].
void mainCoordinates() {
  // A minimal linear scale over [0, 10] -> [0, 100] and a band scale, both
  // implementing the frozen Scale interface from internal/d3/scale.dart.
  final linear = scaleLinear()
    ..domainOf(<double>[0, 10])
    ..rangeOf(<double>[0, 100]);
  final band = scaleBand()
    ..domainOf(<Object>['a', 'b'])
    ..rangeOf(<double>[0, 100]);

  FluentChartAnnotationContext contextWith({Scale? x, Scale? y}) =>
      FluentChartAnnotationContext(
        plotRect: const Rect.fromLTWH(20, 10, 200, 100),
        chartSize: const Size(300, 200),
        isRtl: false,
        xScale: x,
        yScalePrimary: y,
      );

  group('fluentAnnotationBandOffset', () {
    test('a band scale is centred on its band', () {
      expect(
        fluentAnnotationBandOffset(band, 'a'),
        moreOrLessEquals(band('a')! + band.bandwidth / 2, epsilon: 0.001),
        reason:
            'ChartAnnotationLayer.tsx:251-253 adds bandwidth() / 2 whenever the '
            'scale exposes one.',
      );
    });

    test('a continuous scale is not shifted', () {
      expect(
        fluentAnnotationBandOffset(linear, 5),
        moreOrLessEquals(50, epsilon: 0.001),
        reason:
            'ChartAnnotationLayer.tsx:254 returns the raw position when there '
            'is no bandwidth.',
      );
    });

    test('a domain miss is null, not a guess', () {
      expect(
        fluentAnnotationBandOffset(band, 'z'),
        isNull,
        reason:
            'ChartAnnotationLayer.tsx:248-250 returns undefined for anything '
            'that is not a finite number, and ScaleBand returns null on a miss.',
      );
    });
  });

  group('resolveFluentAnnotationCoordinates', () {
    test('a data coordinate goes through the scales', () {
      final resolved = resolveFluentAnnotationCoordinates(
        const FluentChartAnnotation(
          text: 'x',
          coordinates: FluentDataCoordinate(x: 5, y: 5),
        ),
        contextWith(x: linear, y: linear),
      );
      expect(
        resolved!.anchor,
        const Offset(50, 50),
        reason: 'ChartAnnotationLayer.tsx:271-281.',
      );
    });

    test('a DateTime is scaled by its epoch milliseconds', () {
      final epoch = DateTime.utc(1970, 1, 1, 0, 0, 0, 5);
      final resolved = resolveFluentAnnotationCoordinates(
        FluentChartAnnotation(
          text: 'x',
          coordinates: FluentDataCoordinate(x: epoch, y: 5),
        ),
        contextWith(x: linear, y: linear),
      );
      expect(
        resolved!.anchor.dx,
        moreOrLessEquals(50, epsilon: 0.001),
        reason:
            'ChartAnnotationLayer.tsx:272 converts a Date with .getTime() '
            'before scaling, which is millisecondsSinceEpoch in Dart.',
      );
    });

    test('a relative coordinate is a fraction of the plot rect', () {
      final resolved = resolveFluentAnnotationCoordinates(
        const FluentChartAnnotation(
          text: 'x',
          coordinates: FluentRelativeCoordinate(x: 0.5, y: 0.25),
        ),
        contextWith(),
      );
      expect(
        resolved!.anchor,
        const Offset(20 + 200 * 0.5, 10 + 100 * 0.25),
        reason: 'ChartAnnotationLayer.tsx:298-300.',
      );
    });

    test('a pixel coordinate is an offset from the plot origin', () {
      final resolved = resolveFluentAnnotationCoordinates(
        const FluentChartAnnotation(
          text: 'x',
          coordinates: FluentPixelCoordinate(x: 5, y: 5),
        ),
        contextWith(),
      );
      expect(
        resolved!.anchor,
        const Offset(25, 15),
        reason:
            'ChartAnnotationLayer.tsx:305 — plotRect origin plus the value.',
      );
    });

    test('a mixed coordinate takes one space per axis', () {
      final resolved = resolveFluentAnnotationCoordinates(
        const FluentChartAnnotation(
          text: 'x',
          coordinates: FluentMixedCoordinate(
            xSpace: FluentCoordinateSpace.pixel,
            ySpace: FluentCoordinateSpace.relative,
            x: 5,
            y: 0.5,
          ),
        ),
        contextWith(),
      );
      expect(
        resolved!.anchor,
        const Offset(25, 60),
        reason: 'ChartAnnotationLayer.tsx:342-347.',
      );
    });

    test('a missing scale skips the annotation entirely', () {
      expect(
        resolveFluentAnnotationCoordinates(
          const FluentChartAnnotation(
            text: 'x',
            coordinates: FluentDataCoordinate(x: 5, y: 5),
          ),
          contextWith(),
        ),
        isNull,
        reason:
            'ChartAnnotationLayer.tsx:255-258 returns undefined without a '
            'scale, and :376-378 drops the whole annotation when either '
            'coordinate is undefined.',
      );
    });

    test('the layout offsets shift the point but not the anchor', () {
      final resolved = resolveFluentAnnotationCoordinates(
        const FluentChartAnnotation(
          text: 'x',
          coordinates: FluentPixelCoordinate(x: 5, y: 5),
          layout: FluentChartAnnotationLayout(offsetX: 30, offsetY: -4),
        ),
        contextWith(),
      );
      expect(
        resolved!.anchor,
        const Offset(25, 15),
        reason:
            'ChartAnnotationLayer.tsx:380 keeps the anchor at the datum; the '
            'connector is drawn to it.',
      );
      expect(
        resolved.point,
        const Offset(55, 11),
        reason: 'ChartAnnotationLayer.tsx:382-383.',
      );
    });

    test('a truthy clipToBounds clamps the POINT into the plot rect', () {
      final resolved = resolveFluentAnnotationCoordinates(
        const FluentChartAnnotation(
          text: 'x',
          coordinates: FluentPixelCoordinate(x: 5, y: 5),
          layout: FluentChartAnnotationLayout(offsetX: 500, clipToBounds: true),
        ),
        contextWith(),
      );
      expect(
        resolved!.point.dx,
        220,
        reason:
            'ChartAnnotationLayer.tsx:385-388 clamps to plotRect.x + width, '
            'which is 20 + 200.',
      );
    });

    test('a null clipToBounds leaves the point alone', () {
      final resolved = resolveFluentAnnotationCoordinates(
        const FluentChartAnnotation(
          text: 'x',
          coordinates: FluentPixelCoordinate(x: 5, y: 5),
          layout: FluentChartAnnotationLayout(offsetX: 500),
        ),
        contextWith(),
      );
      expect(
        resolved!.point.dx,
        525,
        reason:
            'ChartAnnotationLayer.tsx:385 is `if (layout?.clipToBounds)` — only '
            'truthy clamps here. The undefined case still clips the BOX at '
            ':544, which is the tri-state the contract records.',
      );
    });
  });

  group('the corpus resolves a data coordinate onto its own data points', () {
    final story = loadOracleStory(
      'charts-linechart--line-chart-annotations-example',
    );
    Offset at(OracleElement element) => story.absoluteTranslate(element);
    final texts = story.byTag('text');
    // The two axes are rebuilt from their own tick labels. `6` and `52` are
    // each unique in the svg; `0` labels both axes, so it is pinned to the row
    // (x axis) or the column (y axis) its partner sits on. Every tick is
    // translated by story.crispOffset (`d3-axis/src/axis.js:47`), so removing
    // it recovers the scale's real range.
    final xMax = texts.singleWhere((element) => element.text == '6');
    final xMin = texts.singleWhere(
      (element) => element.text == '0' && at(element).dy == at(xMax).dy,
    );
    final yMax = texts.singleWhere((element) => element.text == '52');
    final yMin = texts.singleWhere(
      (element) => element.text == '0' && at(element).dx == at(yMax).dx,
    );
    final xScale = scaleLinear()
      ..domainOf(<double>[double.parse(xMin.text!), double.parse(xMax.text!)])
      ..rangeOf(<double>[
        at(xMin).dx - story.crispOffset,
        at(xMax).dx - story.crispOffset,
      ]);
    final yScale = scaleLinear()
      ..domainOf(<double>[double.parse(yMin.text!), double.parse(yMax.text!)])
      ..rangeOf(<double>[
        at(yMin).dy - story.crispOffset,
        at(yMax).dy - story.crispOffset,
      ]);
    // The data-arm resolution must NOT add this origin — the scales already
    // emit svg coordinates. It is passed so the test would catch that mistake.
    final context = FluentChartAnnotationContext(
      plotRect: Rect.fromLTRB(
        xScale.range.first,
        yScale.range.last,
        xScale.range.last,
        yScale.range.first,
      ),
      chartSize: Size(story.width, story.height),
      isRtl: false,
      xScale: xScale,
      yScalePrimary: yScale,
    );

    /// The line's point markers: `M cx-r cy A r r 0 1 0 cx+r cy` twice, so the
    /// centre is the midpoint of the arc's own endpoints.
    List<Offset> pointCentres() => story
        .byTag('path')
        .where((element) => element.d!.contains('A0.5 0.5'))
        .map((element) {
          final numbers = svgPathNumbers(element.d!);
          return Offset((numbers[0] + numbers[7]) / 2, numbers[1]);
        })
        .toList();

    /// Every plotted datum, resolved back to a pixel through the two scales.
    List<Offset> resolvedAnchors() => pointCentres().map((centre) {
      final x = (xScale.invert(centre.dx)! as double).roundToDouble();
      final y = (yScale.invert(centre.dy)! as double).roundToDouble();
      return resolveFluentAnnotationCoordinates(
        FluentChartAnnotation(
          text: 'annotation',
          coordinates: FluentDataCoordinate(x: x, y: y),
        ),
        context,
      )!.anchor;
    }).toList();

    test('each plotted point round-trips through the data arm', () {
      final centres = pointCentres();
      expect(
        centres.length,
        7,
        reason:
            'The story plots seven points; a zero count would make the loop '
            'below vacuous.',
      );
      final circle = story.soleElement('circle');
      expectOracleOffset(
        'the highlighted last point #${circle.index} confirms the arc-midpoint '
        'centre convention',
        Offset(circle.cx!, circle.cy!),
        centres.last,
      );
      final anchors = resolvedAnchors();
      for (var i = 0; i < centres.length; i++) {
        // The inverted datum must be one of the story's integers, or the
        // forward resolution below would only be proving invert ∘ scale = id.
        final x = xScale.invert(centres[i].dx)! as double;
        final y = yScale.invert(centres[i].dy)! as double;
        expectOracleNumber(
          'point #$i x inverts to a whole datum',
          x.roundToDouble(),
          x,
        );
        expectOracleNumber(
          'point #$i y inverts to a whole datum',
          y.roundToDouble(),
          y,
        );
        expectOracleOffset(
          'ChartAnnotationLayer.tsx:271-281 — a data coordinate at '
          '(${x.round()}, ${y.round()}) resolves onto point #$i of '
          '${story.id}, with no plotRect origin (${context.plotRect.left}, '
          '${context.plotRect.top}) added',
          centres[i],
          anchors[i],
        );
      }
    });

    test('each connector runs at one of those anchors', () {
      final anchors = resolvedAnchors();
      final lines = _connectorLayer(
        story,
      ).elements.where((element) => element.tag == 'line').toList();
      expect(
        lines.length,
        2,
        reason:
            'Two of the four annotations in the story carry a connector; a '
            'zero count would make the loop below vacuous.',
      );
      for (final line in lines) {
        final start = Offset(line.x1!, line.y1!);
        final end = Offset(line.x2!, line.y2!);
        final along = end - start;
        // The connector stops short of the datum by its arrowhead trim, which
        // stage 22 owns; what stage 21 must get right is that the anchor lies
        // on the ray the connector points along.
        final hits = anchors.where((anchor) {
          final toAnchor = anchor - end;
          final perpendicular =
              (along.dx * toAnchor.dy - along.dy * toAnchor.dx).abs() /
              along.distance;
          final forwards = along.dx * toAnchor.dx + along.dy * toAnchor.dy > 0;
          return forwards && perpendicular <= kOracleGeometryTolerance;
        }).toList();
        expect(
          hits.length,
          1,
          reason:
              'ChartAnnotationLayer.tsx:380 — connector #${line.index} of '
              '${story.id} runs from the box to its datum, so exactly one '
              'resolved anchor is collinear with it and beyond its end at '
              '$end. Got ${hits.length}: $hits.',
        );
      }
    });
  });
}

/// The story's `fui-chartAnnotationLayer__connectorLayer` svg — the second
/// capture, holding the connectors, the arrowhead markers and the annotation
/// `foreignObject`s. [OracleStory.primary] is the chart itself.
OracleSvg _connectorLayer(OracleStory story) => story.svgs.singleWhere(
  (svg) => svg.slot == 'fui-chartAnnotationLayer__connectorLayer',
);

/// The sizing-and-clamping half of the suite
/// (`ChartAnnotationLayer.tsx:532-559`), called from [main].
void mainSizing() {
  const context = FluentChartAnnotationContext(
    plotRect: Rect.fromLTWH(20, 10, 200, 100),
    chartSize: Size(300, 200),
    isRtl: false,
  );

  FluentAnnotationBox layout(
    Offset point, {
    FluentChartAnnotationLayout? layoutProps,
    Size measured = const Size(40, 20),
  }) => fluentLayoutAnnotationBox(
    resolved: FluentResolvedAnnotationPosition(anchor: point, point: point),
    measured: measured,
    layout: layoutProps,
    context: context,
  );

  group('fluentLayoutAnnotationBox', () {
    test('the default alignment centres the box on the point', () {
      expect(
        layout(const Offset(100, 50)).rect,
        const Rect.fromLTWH(100 - 20, 50 - 10, 40, 20),
        reason:
            'ChartAnnotationLayer.tsx:26-27 default to center and middle, and '
            ':538-539 turn those into -width/2 and -height/2.',
      );
    });

    test('start and top leave the point at the corner', () {
      expect(
        layout(
          const Offset(100, 50),
          layoutProps: const FluentChartAnnotationLayout(
            align: FluentChartAnnotationAlign.start,
            verticalAlign: FluentChartAnnotationVerticalAlign.top,
          ),
        ).rect.topLeft,
        const Offset(100, 50),
        reason: 'ChartAnnotationLayer.tsx:538-539, the zero arms.',
      );
    });

    test('end and bottom put the point at the far corner', () {
      expect(
        layout(
          const Offset(100, 50),
          layoutProps: const FluentChartAnnotationLayout(
            align: FluentChartAnnotationAlign.end,
            verticalAlign: FluentChartAnnotationVerticalAlign.bottom,
          ),
        ).rect.bottomRight,
        const Offset(100, 50),
        reason: 'ChartAnnotationLayer.tsx:538-539, the full-size arms.',
      );
    });

    test('a null clipToBounds still clamps the BOX to the plot rect', () {
      expect(
        layout(const Offset(215, 50)).rect.right,
        context.plotRect.right,
        reason:
            'ChartAnnotationLayer.tsx:544 is `layout?.clipToBounds !== false`, '
            'so undefined selects the plot rect as the clamping viewport even '
            'though :385 left the point alone. That asymmetry is the whole '
            'reason clipToBounds is a tri-state.',
      );
    });

    test('an explicit false widens the viewport to the whole chart', () {
      expect(
        layout(
          const Offset(215, 50),
          layoutProps: const FluentChartAnnotationLayout(clipToBounds: false),
        ).rect.right,
        moreOrLessEquals(215 + 20, epsilon: 0.001),
        reason:
            'ChartAnnotationLayer.tsx:547-548 switches to the svgRect, which is '
            '300 wide here, so a box ending at 235 needs no clamping at all.',
      );
    });

    test('a box wider than the viewport is pinned to its origin', () {
      expect(
        layout(const Offset(100, 50), measured: const Size(400, 20)).rect.left,
        context.plotRect.left,
        reason:
            'ChartAnnotationLayer.tsx:553 clamps against '
            'Math.max(viewportX, maxTopLeftX), so a negative maximum collapses '
            'onto the origin rather than inverting the clamp.',
      );
    });

    test('the display point tracks the clamped box', () {
      final box = layout(const Offset(215, 50));
      expect(
        box.displayPoint,
        box.rect.center,
        reason:
            'ChartAnnotationLayer.tsx:556-559 recovers the display point by '
            'undoing the alignment offset, which for the default centre '
            'alignment is the rect centre. The connector starts there, not at '
            'the unclamped point.',
      );
    });

    test('a size of zero is floored at one', () {
      expect(
        layout(const Offset(100, 50), measured: Size.zero).rect.size,
        const Size(1, 1),
        reason:
            'ChartAnnotationLayer.tsx:535-536 wrap both dimensions in '
            'Math.max(..., 1).',
      );
    });
  });

  group('the corpus keeps every annotation box inside the plot rect', () {
    final story = loadOracleStory(
      'charts-linechart--line-chart-annotations-example',
    );
    // The plot rect is the two axes' ranges, recovered from their tick labels
    // exactly as the coordinate group above does: the x axis is translated to
    // y 445 and the y axis to x 40, both carrying story.crispOffset
    // (`d3-axis/src/axis.js:47`).
    final texts = story.byTag('text');
    Offset at(OracleElement element) => story.absoluteTranslate(element);
    final xMax = texts.singleWhere((element) => element.text == '6');
    final xMin = texts.singleWhere(
      (element) => element.text == '0' && at(element).dy == at(xMax).dy,
    );
    final yMax = texts.singleWhere((element) => element.text == '52');
    final yMin = texts.singleWhere(
      (element) => element.text == '0' && at(element).dx == at(yMax).dx,
    );
    final plotRect = Rect.fromLTRB(
      at(xMin).dx - story.crispOffset,
      at(yMax).dy - story.crispOffset,
      at(xMax).dx - story.crispOffset,
      at(yMin).dy - story.crispOffset,
    );
    final context = FluentChartAnnotationContext(
      plotRect: plotRect,
      chartSize: Size(story.width, story.height),
      isRtl: false,
    );
    // The `foreignObject` per annotation is the box upstream painted; x/y are
    // its top-left in svg coordinates (`ChartAnnotationLayer.tsx:636-641`).
    final captured = _connectorLayer(
      story,
    ).elements.where((element) => element.tag == 'foreignObject').toList();

    test('the four captured boxes fit the viewport a null flag selects', () {
      expect(
        captured.length,
        4,
        reason:
            'The story declares four annotations; a zero count would make the '
            'loops below vacuous.',
      );
      for (final box in captured) {
        final rect = Rect.fromLTWH(box.x!, box.y!, box.width!, box.height!);
        expect(
          plotRect.contains(rect.topLeft) &&
              plotRect.contains(rect.bottomRight),
          isTrue,
          reason:
              'ChartAnnotationLayer.tsx:544-554 — box #${box.index} of '
              '${story.id} at $rect is inside the plot rect $plotRect, so the '
              'clamp had nothing to do and the captured rect is the pure '
              'alignment result.',
        );
        expectOracleRect(
          'ChartAnnotationLayer.tsx:538-539 — the default centre/middle arms '
          'put box #${box.index} of ${story.id} back where it was captured, '
          'unmoved by the :550-554 clamp',
          rect,
          fluentLayoutAnnotationBox(
            resolved: FluentResolvedAnnotationPosition(
              anchor: rect.center,
              point: rect.center,
            ),
            measured: rect.size,
            layout: null,
            context: context,
          ).rect,
        );
      }
    });

    test(
      'pushing a captured box off the right edge pins it to the plot rect',
      () {
        for (final box in captured) {
          final size = Size(box.width!, box.height!);
          expect(
            fluentLayoutAnnotationBox(
              resolved: FluentResolvedAnnotationPosition(
                anchor: Offset(plotRect.right + 1000, plotRect.center.dy),
                point: Offset(plotRect.right + 1000, plotRect.center.dy),
              ),
              measured: size,
              layout: null,
              context: context,
            ).rect.right,
            moreOrLessEquals(plotRect.right, epsilon: kOracleGeometryTolerance),
            reason:
                'ChartAnnotationLayer.tsx:550-553 — box #${box.index} of '
                '${story.id} is ${size.width} wide, narrower than the '
                '${plotRect.width}-wide plot rect, so a point off the right edge '
                'clamps its top-left to viewportX + viewportWidth - width.',
          );
        }
      },
    );
  });
}
