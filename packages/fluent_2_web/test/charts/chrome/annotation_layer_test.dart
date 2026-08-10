import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/annotation_layer.dart';
import 'package:fluent_2_web/src/charts/chrome/annotation_layer_style.dart';
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
}

/// The story's `fui-chartAnnotationLayer__connectorLayer` svg — the second
/// capture, holding the connectors, the arrowhead markers and the annotation
/// `foreignObject`s. [OracleStory.primary] is the chart itself.
OracleSvg _connectorLayer(OracleStory story) => story.svgs.singleWhere(
  (svg) => svg.slot == 'fui-chartAnnotationLayer__connectorLayer',
);
