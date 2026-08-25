import 'package:fluent_2/src/charts/funnel_chart_style.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The segment label's type is the trap. `useFunnelChartStyles.styles.ts`
/// defines a `text` slot at semibold, but `FunnelChart.tsx` never applies it —
/// `_renderSegmentText` at `:191-227` emits a `<text>` with no className — so
/// the label inherits `.root`, which is `fontSizeBase300` at
/// `fontWeightRegular`: 14px, weight 400.
void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('the funnel occupies four fifths of each axis', () {
    final style = resolveFluentFunnelChartStyle(theme);
    expect(
      style.funnelWidthFactor!.resolve(states),
      0.8,
      reason: 'FunnelChart.tsx:473 — funnelWidth is width * 0.8.',
    );
    expect(
      style.funnelHeightFactor!.resolve(states),
      0.8,
      reason:
          'FunnelChart.tsx:278 — funnelHeight is '
          '(height - titleHeight) * 0.8, so the bottom fifth of the box is '
          'deliberately empty.',
    );
  });

  test('the title reserves 40 whether or not there is a title', () {
    final style = resolveFluentFunnelChartStyle(theme);
    expect(
      style.titleHeightMin!.resolve(states),
      40.0,
      reason:
          'FunnelChart.tsx:465-470 — max(fontSize + 20, 40) with a title, '
          'and the literal 40 without one. The reservation is unconditional.',
    );
    expect(
      style.titlePadding!.resolve(states),
      20.0,
      reason: 'Common.styles.ts:10 — CHART_TITLE_PADDING.',
    );
    expect(
      style.titleFontFallbackSize!.resolve(states),
      13.0,
      reason: 'FunnelChart.tsx:466.',
    );
  });

  test('the intrinsic size is 350 by 500', () {
    final style = resolveFluentFunnelChartStyle(theme);
    expect(
      style.intrinsicWidth!.resolve(states),
      350.0,
      reason: 'FunnelChart.tsx:462 — props.width || 350.',
    );
    expect(
      style.intrinsicHeight!.resolve(states),
      500.0,
      reason: 'FunnelChart.tsx:463 — props.height || 500.',
    );
  });

  test('the effective minimum text width is 16, not the 24 in the signature', () {
    expect(
      resolveFluentFunnelChartStyle(theme).minTextWidth!.resolve(states),
      16.0,
      reason:
          'funnelGeometry.ts:290 defaults minTextWidth to 24, but both '
          'call sites — FunnelChart.tsx:287 and :348 — pass 16, so 24 is never '
          'used.',
    );
  });

  test('the segment label is 14px regular, not the dead semibold slot', () {
    final label = resolveFluentFunnelChartStyle(
      theme,
    ).segmentLabelTextStyle!.resolve(states)!;
    expect(
      label.fontSize,
      14.0,
      reason:
          'useFunnelChartStyles.styles.ts:26-35 — the root is '
          'fontSizeBase300.',
    );
    expect(
      label.fontWeight,
      FluentFontWeight.regular,
      reason:
          'The root is fontWeightRegular, and the semibold `text` slot is '
          'computed but applied to nothing.',
    );
  });

  test('a dimmed segment is one tenth opaque', () {
    expect(
      resolveFluentFunnelChartStyle(theme).dimmedOpacity!.resolve(states),
      0.1,
      reason: 'FunnelChart.tsx:302 and :363-364.',
    );
  });

  test('the title background is the neutral surface the svgTooltip fills', () {
    expect(
      resolveFluentFunnelChartStyle(
        theme,
      ).titleBackgroundColor!.resolve(states),
      theme.colors.neutralBackground1,
      reason:
          'useFunnelChartStyles.styles.ts:52-57 — svgTooltip fills '
          'colorNeutralBackground1 behind the title text.',
    );
  });

  test('merge, copyWith and equality are per-property', () {
    final base = resolveFluentFunnelChartStyle(theme);
    final overridden = base.merge(
      FluentFunnelChartStyle.from(dimmedOpacity: 0.5),
    );
    expect(
      overridden.dimmedOpacity!.resolve(states),
      0.5,
      reason: 'merge takes the non-null property of the argument.',
    );
    expect(
      overridden.intrinsicWidth!.resolve(states),
      350.0,
      reason: 'merge is per-property, so the untouched fields survive.',
    );
    expect(
      base.merge(null),
      base,
      reason: 'merging null is the identity, and equality is by value.',
    );
    expect(base.copyWith(), base, reason: 'an empty copyWith is the identity.');
    expect(
      base.hashCode,
      resolveFluentFunnelChartStyle(theme).hashCode,
      reason: 'two resolutions of one theme hash alike.',
    );
  });

  group('against the captured FunnelChart stories', () {
    final ids = oracleStoryIds(component: 'FunnelChart');

    test('the corpus still holds both funnel stories', () {
      expect(
        ids.length,
        2,
        reason:
            'the loops below are filtered, so a shrunken corpus must fail '
            'here rather than silently assert nothing.',
      );
    });

    for (final id in ids) {
      test('$id places and sizes the funnel group by these factors', () {
        final story = loadOracleStory(id);
        final style = resolveFluentFunnelChartStyle(theme);
        final widthFactor = style.funnelWidthFactor!.resolve(states)!;
        final heightFactor = style.funnelHeightFactor!.resolve(states)!;
        final titleHeight = style.titleHeightMin!.resolve(states)!;
        // The one <g> upstream translates: FunnelChart.tsx:481 wraps the whole
        // funnel in translate(funnelOffsetX, funnelMarginTop).
        final funnel = story.soleElement(
          'g',
          where: (e) => e.parent == -1 && e.translate != null,
        );
        expectOracleOffset(
          '$id funnel group translate',
          // FunnelChart.tsx:473-474 — funnelOffsetX = (width - width * 0.8) / 2
          // — and :471, funnelMarginTop = titleHeight, which is 40 because both
          // stories' titles render at 10px: max(10 + 20, 40).
          Offset(story.width * (1 - widthFactor) / 2, titleHeight),
          story.absoluteTranslate(funnel),
        );
        expectOracleRect(
          '$id funnel group bbox',
          Rect.fromLTWH(
            0,
            0,
            story.width * widthFactor,
            (story.height - titleHeight) * heightFactor,
          ),
          funnel.bbox!,
          tolerance: kOracleMeasuredTolerance,
        );
      });

      test('$id draws every value label at 14px regular', () {
        final story = loadOracleStory(id);
        final label = resolveFluentFunnelChartStyle(
          theme,
        ).segmentLabelTextStyle!.resolve(states)!;
        // The chart title is the only <text> outside the funnel group, and it
        // is the semibold 10px chartTitle slot, so nesting is the filter.
        final labels = story
            .byTag('text')
            .where((e) => e.parent != -1)
            .toList(growable: false);
        expect(
          labels.length,
          greaterThanOrEqualTo(4),
          reason:
              'each story draws at least four segments, so an empty filter '
              'must fail rather than pass vacuously.',
        );
        for (final e in labels) {
          expectOracleNumber(
            '$id label #${e.index} fontSize',
            label.fontSize!,
            e.fontSize,
          );
          expect(
            e.fontWeight,
            '400',
            reason:
                'the semibold `text` slot at useFunnelChartStyles.styles.ts:'
                '41-47 reaches no element — every captured label is regular.',
          );
        }
      });
    }
  });
}
