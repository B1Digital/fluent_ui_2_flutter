import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/annotation_layer_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

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
}

/// The story's `fui-chartAnnotationLayer__connectorLayer` svg — the second
/// capture, holding the connectors, the arrowhead markers and the annotation
/// `foreignObject`s. [OracleStory.primary] is the chart itself.
OracleSvg _connectorLayer(OracleStory story) => story.svgs.singleWhere(
  (svg) => svg.slot == 'fui-chartAnnotationLayer__connectorLayer',
);
