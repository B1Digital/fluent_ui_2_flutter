import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Link's page has no knobs: seven sections, each a single link in a different
/// configuration. What every one of them claims is an *ink* — a colour and an
/// underline that answer to hover, to press, to focus, or to being disabled —
/// and none of that reaches the widget tree: `FluentLink` colours its label
/// through an inherited `DefaultTextStyle`, so the rendered paragraph is the
/// only place the answer lives. Every test below reads that paragraph, and the
/// pointer that drives it is a real mouse, because hover is the whole axis and
/// `tester.tap` synthesises none of it.
void main() {
  const String page = 'components-link';

  group('default', () {
    final DocsSection section = sectionOf('components-link--default');

    testWidgets('a real mouse underlines the link and lets it go again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder label = find.text('This is a link');
      final FluentColors colors = colorsOf(tester);
      expect(
        decorationOf(tester, label),
        TextDecoration.none,
        reason: 'a standalone link is only underlined while interacted with',
      );
      expect(inkOf(tester, label), colors.brandForegroundLink);

      final TestGesture mouse = await mouseHover(tester, label);
      expect(
        decorationOf(tester, label),
        TextDecoration.underline,
        reason:
            'hover is the affordance — a link that never underlines is '
            'indistinguishable from coloured prose',
      );
      expect(inkOf(tester, label), colors.brandForegroundLinkHover);

      await mouseAway(tester, mouse);
      expect(decorationOf(tester, label), TextDecoration.none);
      expect(
        inkOf(tester, label),
        colors.brandForegroundLink,
        reason: 'the resting ink must come back when the pointer leaves',
      );
    });

    testWidgets('a real mouse click leaves the link at rest', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder label = find.text('This is a link');

      await mouseClick(tester, label);
      // A press that is never released — an interaction controller that misses
      // the pointer-up or the pointer-remove — leaves the link stuck in its
      // pressed ink, which no synthetic tap can catch because it synthesises
      // neither hover nor removal.
      expect(inkOf(tester, label), colorsOf(tester).brandForegroundLink);
      expect(decorationOf(tester, label), TextDecoration.none);
    });
  });

  group('appearance', () {
    testWidgets('subtle takes the neutral link ink, not the brand one', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-link--appearance'));

      final Finder label = find.text('Subtle link');
      final FluentColors colors = colorsOf(tester);
      expect(
        inkOf(tester, label),
        colors.neutralForeground2Link,
        reason:
            'the appearance axis is the only thing this section shows; a '
            'subtle link painted in brand ink shows nothing at all',
      );
      expect(inkOf(tester, label), isNot(colors.brandForegroundLink));

      final TestGesture mouse = await mouseHover(tester, label);
      expect(inkOf(tester, label), colors.neutralForeground2LinkHover);
      expect(decorationOf(tester, label), TextDecoration.underline);
      await mouseAway(tester, mouse);
      expect(inkOf(tester, label), colors.neutralForeground2Link);
    });
  });

  group('inline', () {
    final DocsSection section = sectionOf('components-link--inline');

    testWidgets('the inline link is underlined at rest and stays on the line', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder label = find.text('inline link');
      expect(
        decorationOf(tester, label),
        TextDecoration.underline,
        reason:
            'inline is exactly "underlined without being touched" — colour '
            'alone cannot separate a link from the prose around it',
      );

      // The link travels as a WidgetSpan, so the failure mode is a link that
      // renders as its own block and pushes the sentence onto a second line.
      final Rect prose = tester.getRect(
        find.textContaining('used alongside other text'),
      );
      final Rect link = tester.getRect(label);
      expect(
        prose.height,
        lessThan(2 * link.height),
        reason: 'the sentence must still be one line',
      );
      expect(prose.contains(link.center), isTrue);
    });

    testWidgets('hover recolours the inline link and gives the ink back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder label = find.text('inline link');
      final FluentColors colors = colorsOf(tester);

      final TestGesture mouse = await mouseHover(tester, label);
      expect(inkOf(tester, label), colors.brandForegroundLinkHover);
      // Already underlined at rest, so the underline cannot be the hover
      // signal here — the recolour has to be, and it has to come back.
      expect(decorationOf(tester, label), TextDecoration.underline);
      await mouseAway(tester, mouse);
      expect(inkOf(tester, label), colors.brandForegroundLink);
      expect(decorationOf(tester, label), TextDecoration.underline);
    });
  });

  group('disabled', () {
    testWidgets('a disabled link takes the disabled ink and ignores a mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-link--disabled'));

      final Finder label = find.text('Disabled link');
      final FluentColors colors = colorsOf(tester);
      expect(inkOf(tester, label), colors.neutralForegroundDisabled);

      final TestGesture mouse = await mouseHover(tester, label);
      // The section's whole claim: a null `onPressed` stops the link
      // *reporting* hover, rather than merely repainting it grey. A link that
      // still lights up under the pointer is advertising an action it will
      // never take.
      expect(
        decorationOf(tester, label),
        TextDecoration.none,
        reason: 'a disabled link must not underline under the pointer',
      );
      expect(inkOf(tester, label), colors.neutralForegroundDisabled);
      await mouseAway(tester, mouse);
    });
  });

  group('disabled focusable', () {
    testWidgets('the wrapper keeps the disabled link in the tab order', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-link--disabled-focusable'),
      );

      final Finder label = find.text('Disabled but still focusable');
      // Anchored on the FluentLink element, not on its label: the link's own
      // FocusableActionDetector sits *below* the widget and is disabled, so a
      // lookup from the label would find the node that refuses focus rather
      // than the wrapper that is the entire point of the section. Without that
      // wrapper the tab order skips the control and a keyboard user never
      // learns it is there.
      final FocusNode? node = Focus.maybeOf(
        tester.element(find.byType(FluentLink)),
      );
      expect(node, isNotNull, reason: 'the demo lost its Focus wrapper');
      expect(node!.canRequestFocus, isTrue);

      node.requestFocus();
      await settle(tester);
      expect(node.hasFocus, isTrue);

      final FluentColors colors = colorsOf(tester);
      expect(inkOf(tester, label), colors.neutralForegroundDisabled);
      // Focus on a *live* link doubles the underline and recolours it to the
      // focus stroke. This one is disabled, so it must keep its resting inline
      // rule: a focus indicator on a control that cannot be activated is a lie.
      expect(decorationOf(tester, label), TextDecoration.underline);
      expect(
        textStyleOf(tester, label)?.decorationStyle,
        TextDecorationStyle.solid,
      );
      expect(
        textStyleOf(tester, label)?.decorationColor,
        isNot(colors.strokeFocus2),
      );
    });
  });

  group('as button', () {
    testWidgets('the link is live and survives a real click', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-link--as-button'));

      final Finder label = find.text('Render as a button');
      final FluentColors colors = colorsOf(tester);
      expect(
        inkOf(tester, label),
        colors.brandForegroundLink,
        reason: 'a link with an onPressed must not render as disabled',
      );
      expect(inkOf(tester, label), isNot(colors.neutralForegroundDisabled));

      await mouseClick(tester, label);
      expect(decorationOf(tester, label), TextDecoration.none);
    });
  });

  group('as span', () {
    testWidgets('the long link wraps inside its 200px box', (
      WidgetTester tester,
    ) async {
      // loose: the demo's own SizedBox(width: 200) is the subject here, and a
      // scroll view would hand it a TIGHT 1600 that clamps the 200 straight
      // back up — measuring the opposite of what the page renders.
      await pumpSection(
        tester,
        sectionOf('components-link--as-span'),
        loose: true,
      );

      final Finder link = find.byType(FluentLink);
      final Rect box = tester.getRect(link);
      expect(box.width, lessThanOrEqualTo(200));
      // Upstream's point: the link's own content rewraps rather than leaving
      // the paragraph as one unbreakable inline-block that overruns its box.
      expect(
        box.height,
        greaterThan(48),
        reason: 'a link this long inside 200px has to take more than two lines',
      );
      expect(
        decorationOf(
          tester,
          find.descendant(of: link, matching: find.byType(Text)),
        ),
        TextDecoration.underline,
        reason: 'the span demo passes inline: true',
      );
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, loose: true);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The colour the label matched by [text] actually rendered in.
Color? inkOf(WidgetTester tester, Finder text) =>
    textStyleOf(tester, text)?.color;

/// The underline the label matched by [text] actually rendered with.
TextDecoration? decorationOf(WidgetTester tester, Finder text) =>
    textStyleOf(tester, text)?.decoration;

/// The palette the mounted section resolved against.
FluentColors colorsOf(WidgetTester tester) =>
    FluentTheme.of(tester.element(find.byType(FluentLink).first)).colors;
