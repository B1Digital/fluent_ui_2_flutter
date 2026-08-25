import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// CompoundButton's page is seven stateless sections whose buttons all press
/// into an empty callback, so the knobs here are the design axes and the one
/// thing this component adds to a button: a second line. Two claims run through
/// every test below, because they are the two a screenshot cannot check — that
/// the second line is *quieter* than the first rather than merely present, and
/// that compound geometry is its own (a uniform inset that doubles as the icon
/// gap, a 40px glyph, a content-driven height) rather than the button's ramp
/// with a subtitle glued on.
void main() {
  const String page = 'components-button-compoundbutton';

  group('default', () {
    final DocsSection section = sectionOf(
      'components-button-compoundbutton--default',
    );

    testWidgets('the second line sits under the first and is quieter than it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      final Rect primary = tester.getRect(find.text('Example'));
      final Rect secondary = tester.getRect(find.text('Secondary content'));
      expect(secondary.top, greaterThanOrEqualTo(primary.bottom));
      expect(
        secondary.left,
        closeTo(primary.left, 0.5),
        reason: 'the two lines share a leading edge',
      );

      // The whole reason the component exists is that the two lines are styled
      // apart: one step of the neutral ramp and one step of the type ramp. A
      // second line that inherited the first would render as two shouted lines.
      expect(
        textStyleOf(tester, find.text('Example'))?.color,
        colors.neutralForeground1,
      );
      expect(
        textStyleOf(tester, find.text('Secondary content'))?.color,
        colors.neutralForeground2,
      );
      expect(
        textStyleOf(tester, find.text('Secondary content'))!.fontSize,
        lessThan(textStyleOf(tester, find.text('Example'))!.fontSize!),
      );
    });

    testWidgets('the glyph takes the compound slot, not the button ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // 40, where a medium FluentButton's icon is 20. This is the number that
      // makes a compound button read as a tile rather than as a tall button.
      expect(
        glyphIn(tester, find.byType(FluentCompoundButton)).width,
        FluentSize.size400,
      );
    });

    testWidgets('the button answers a real mouse and gives the fill back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      final Finder button = find.byType(FluentCompoundButton);

      expect(decorationUnder(tester, button).color, colors.neutralBackground1);

      // The callback is empty, so the fill is the only answer this button can
      // give a pointer — and the only thing that tells a user it is live.
      final TestGesture mouse = await mouseHover(tester, button);
      expect(
        decorationUnder(tester, button).color,
        colors.neutralBackground1Hover,
      );
      await mouseAway(tester, mouse);
      expect(decorationUnder(tester, button).color, colors.neutralBackground1);

      await mouseClick(tester, button);
      expect(
        decorationUnder(tester, button).color,
        colors.neutralBackground1,
        reason: 'a press that never clears paints the button pressed forever',
      );
    });

    testWidgets('Tab reaches the button and rings it; the mouse does not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder button = find.byType(FluentCompoundButton);
      expect(ringVisibility(tester), <bool>[false]);

      // Nothing on this page has state to show for a press, so the tab stop
      // and its ring are how a keyboard user knows this tile is a control at
      // all. The ring is gated on keyboard-visible focus, so a click must not
      // raise one — which is why this test needs a real mouse and a real key.
      await mouseClick(tester, button);
      expect(ringVisibility(tester), <bool>[false]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      expect(ringVisibility(tester), <bool>[true]);
    });
  });

  group('shape', () {
    final DocsSection section = sectionOf(
      'components-button-compoundbutton--shape',
    );

    testWidgets('each shape reaches the corner radius it paints', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        decorationUnder(tester, buttonWith('Rounded')).borderRadius,
        FluentRadius.allMedium,
      );
      expect(
        decorationUnder(tester, buttonWith('Circular')).borderRadius,
        FluentRadius.allCircular,
      );
      expect(
        decorationUnder(tester, buttonWith('Square')).borderRadius,
        BorderRadius.zero,
      );
    });

    testWidgets('the shape axis leaves the two-line geometry alone', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Corner treatment only: a shape that changed the height would mean the
      // compound geometry was being re-derived per shape rather than shared.
      final double rounded = tester.getSize(buttonWith('Rounded')).height;
      expect(tester.getSize(buttonWith('Circular')).height, rounded);
      expect(tester.getSize(buttonWith('Square')).height, rounded);
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf(
      'components-button-compoundbutton--appearance',
    );

    testWidgets('every appearance paints its own fill and its own border', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      expect(
        decorationUnder(tester, buttonWith('Default')).color,
        colors.neutralBackground1,
      );
      expect(
        decorationUnder(tester, buttonWith('Primary')).color,
        colors.brandBackground,
      );
      expect(
        decorationUnder(tester, buttonWith('Outline')).color,
        colors.transparentBackground,
      );
      expect(
        decorationUnder(tester, buttonWith('Subtle')).color,
        colors.subtleBackground,
      );
      expect(
        decorationUnder(tester, buttonWith('Transparent')).color,
        colors.transparentBackground,
      );

      // Three of the five share a clear fill, so the border is the whole
      // difference between outline and the two that carry none.
      expect(decorationUnder(tester, buttonWith('Default')).border, isNotNull);
      expect(decorationUnder(tester, buttonWith('Outline')).border, isNotNull);
      for (final String label in <String>['Primary', 'Subtle', 'Transparent']) {
        expect(
          decorationUnder(tester, buttonWith(label)).border,
          isNull,
          reason: '$label must paint no border',
        );
      }
    });

    testWidgets('the first line stays loud on subtle, where a plain button '
        'would go quiet', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      // The one place the compound button genuinely parts company with the
      // button: its louder line holds neutralForeground1 on every appearance,
      // while a FluentButton's label drops to neutralForeground2 on subtle and
      // transparent. Reusing the button's table would be invisible except here.
      for (final String label in <String>['Subtle', 'Transparent']) {
        expect(
          textStyleOf(tester, find.text(label))?.color,
          colors.neutralForeground1,
          reason: '$label: the first line must not drop a step',
        );
        expect(
          textStyleOf(tester, secondLineOf(label))?.color,
          colors.neutralForeground2,
          reason: '$label: the second line is the one that is quieter',
        );
      }
    });

    testWidgets('on primary both lines sit on the brand fill together', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      // The exception to the rule above: on a brand fill there is no quieter
      // neutral to drop to, so the two lines share one token. A second line
      // that stayed on neutralForeground2 here would be unreadable on brand.
      expect(
        textStyleOf(tester, find.text('Primary'))?.color,
        colors.neutralForegroundOnBrand,
      );
      expect(
        textStyleOf(tester, secondLineOf('Primary'))?.color,
        colors.neutralForegroundOnBrand,
      );
    });

    testWidgets('subtle and transparent are only told apart under a pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      expect(
        decorationUnder(tester, buttonWith('Subtle')).color,
        decorationUnder(tester, buttonWith('Transparent')).color,
      );

      TestGesture mouse = await mouseHover(tester, buttonWith('Subtle'));
      expect(
        decorationUnder(tester, buttonWith('Subtle')).color,
        colors.subtleBackgroundHover,
      );
      await mouseAway(tester, mouse);

      // Transparent keeps its clear fill in every state, so both of its lines
      // going brand is the entire hover response. Nothing reachable by
      // `tester.tap` can tell these two apart.
      mouse = await mouseHover(tester, buttonWith('Transparent'));
      expect(
        decorationUnder(tester, buttonWith('Transparent')).color,
        colors.transparentBackgroundHover,
      );
      expect(
        textStyleOf(tester, find.text('Transparent'))?.color,
        colors.neutralForeground2BrandHover,
      );
      expect(
        textStyleOf(tester, secondLineOf('Transparent'))?.color,
        colors.neutralForeground2BrandHover,
      );
      await mouseAway(tester, mouse);
      expect(
        textStyleOf(tester, find.text('Transparent'))?.color,
        colors.neutralForeground1,
      );
    });
  });

  group('icon', () {
    final DocsSection section = sectionOf(
      'components-button-compoundbutton--icon',
    );

    testWidgets('iconPosition moves the glyph across both lines', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      const String before = 'With calendar icon before contents';
      const String after = 'With calendar icon after contents';

      // The label a compound button lays out is a Column of two, so the glyph
      // has to clear the wider of the two lines rather than just the first.
      expect(
        glyphIn(tester, buttonWith(before)).right,
        lessThanOrEqualTo(tester.getRect(find.text(before)).left),
      );
      expect(
        glyphIn(tester, buttonWith(before)).right,
        lessThanOrEqualTo(tester.getRect(secondLineOf(before)).left),
      );
      expect(
        glyphIn(tester, buttonWith(after)).left,
        greaterThanOrEqualTo(tester.getRect(find.text(after)).right),
      );
    });

    testWidgets('the icon-only button names itself, but only under a pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // A compound button requires a label, so upstream's icon-only case is a
      // FluentButton.icon here — which means its name is in a tooltip and hover
      // is the only way a mouse user ever reads it.
      final Finder iconOnly = find.descendant(
        of: find.byType(FluentTooltip),
        matching: find.byType(FluentButton),
      );

      expect(find.text('With calendar icon only'), findsNothing);
      final TestGesture mouse = await mouseHover(tester, iconOnly);
      expect(find.text('With calendar icon only'), findsOneWidget);
      await mouseAway(tester, mouse);
      expect(find.text('With calendar icon only'), findsNothing);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf(
      'components-button-compoundbutton--size',
    );

    testWidgets('the size axis moves the inset, which is all it moves', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final double small = tester.getSize(buttonWith('Size: small')).height;
      final double medium = tester.getSize(buttonWith('Size: medium')).height;
      final double large = tester.getSize(buttonWith('Size: large')).height;

      // Compound geometry is deliberately not the button's 24/32/40 ramp: the
      // height is content-driven and the size knob only opens up the uniform
      // inset, 8 then 12 then 16, on both edges. So the steps are exactly twice
      // the spacing step, and a knob wired to the button ramp instead would
      // give three heights that are not.
      expect(
        medium - small,
        closeTo((FluentSpacing.m - FluentSpacing.s) * 2, 0.01),
      );
      expect(
        large - medium,
        closeTo((FluentSpacing.l - FluentSpacing.m) * 2, 0.01),
      );
    });

    testWidgets('the glyph stays 40 at every size', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Also its own: a button's glyph ramps 20/20/24 across these three sizes.
      for (final String label in <String>[
        'Size: small',
        'Size: medium',
        'Size: large',
      ]) {
        expect(
          glyphIn(tester, buttonWith(label)).width,
          FluentSize.size400,
          reason: label,
        );
      }
    });

    testWidgets('both lines keep their type ramp at every size', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // The type ramp is NOT part of this axis upstream — both lines hold
      // body1Strong over caption1 at all three sizes — so a size knob that also
      // scaled the text would be the button's ramp leaking in.
      final double? primary = textStyleOf(
        tester,
        find.text('Size: small'),
      )?.fontSize;
      expect(primary, isNotNull);
      for (final String label in <String>['Size: medium', 'Size: large']) {
        expect(
          textStyleOf(tester, find.text(label))?.fontSize,
          primary,
          reason: label,
        );
        expect(
          textStyleOf(tester, secondLineOf(label))?.fontSize,
          lessThan(primary!),
          reason: '$label: the second line stays a caption',
        );
      }
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf(
      'components-button-compoundbutton--disabled',
    );

    testWidgets('disabled is a state and not a treatment: a pointer changes '
        'nothing', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      // Both rows carry the same three labels, so the index picks the row: 0 is
      // the secondary row, 1 the primary one.
      final Finder disabled = buttonWith('Disabled state').at(0);
      final Finder enabled = buttonWith('Enabled state').at(0);

      expect(tester.widget<FluentCompoundButton>(disabled).onPressed, isNull);
      expect(
        decorationUnder(tester, disabled).color,
        colors.neutralBackgroundDisabled,
      );

      TestGesture mouse = await mouseHover(tester, disabled);
      expect(
        decorationUnder(tester, disabled).color,
        colors.neutralBackgroundDisabled,
        reason: 'a disabled button must refuse hover, not merely look grey',
      );
      await mouseAway(tester, mouse);

      // The control: the same gesture on the enabled sibling does move, so the
      // assertion above is about the disabled state and not about the pointer
      // failing to arrive.
      mouse = await mouseHover(tester, enabled);
      expect(
        decorationUnder(tester, enabled).color,
        colors.neutralBackground1Hover,
      );
      await mouseAway(tester, mouse);
    });

    testWidgets('both lines dim together', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      // The second line has its own colour table, so it has its own disabled
      // entry to get wrong: a quiet line that stayed on neutralForeground2
      // would end up LOUDER than the disabled line above it.
      expect(
        textStyleOf(tester, find.text('Disabled state').at(0))?.color,
        colors.neutralForegroundDisabled,
      );
      expect(
        textStyleOf(tester, secondLineOf('Disabled state'))?.color,
        colors.neutralForegroundDisabled,
      );
    });

    testWidgets('a disabled primary button loses its brand fill', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      expect(
        decorationUnder(tester, buttonWith('Enabled state').at(1)).color,
        colors.brandBackground,
      );
      expect(
        decorationUnder(tester, buttonWith('Disabled state').at(1)).color,
        colors.neutralBackgroundDisabled,
      );
    });
  });

  group('with long text', () {
    const String long =
        'Long text wraps after it hits the max width of the component';
    final DocsSection section = sectionOf(
      'components-button-compoundbutton--with-long-text',
    );

    testWidgets('the long label wraps at the 280 upstream sets', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // 280 exactly: the label is boxed at 280 less the medium inset on either
      // side, so the button lands on upstream's width rather than merely under
      // it. A Row hands its children unbounded width, so a label that was not
      // boxed would overflow instead of wrapping — which pumpSection's
      // clean-tree check catches from the other side.
      final Size wrapped = tester.getSize(buttonWith(long));
      expect(wrapped.width, closeTo(280, 0.01));
      expect(
        wrapped.height,
        greaterThan(tester.getSize(buttonWith('Short text')).height),
      );
      expect(
        tester.getSize(find.text(long)).width,
        closeTo(280 - FluentSpacing.m * 2, 0.01),
      );
    });

    testWidgets('the wrapped button still takes a real click', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      // The hit target is the whole tile, including the second line under a
      // label that now runs to two lines.
      final TestGesture mouse = await mouseHover(tester, secondLineOf(long));
      expect(
        decorationUnder(tester, buttonWith(long)).color,
        colors.neutralBackground1Hover,
      );
      await mouseAway(tester, mouse);
      expect(
        decorationUnder(tester, buttonWith(long)).color,
        colors.neutralBackground1,
      );
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The compound button whose louder line reads exactly [label].
Finder buttonWith(String label) =>
    find.widgetWithText(FluentCompoundButton, label);

/// The second line of the button whose louder line reads [label].
///
/// Every button on this page carries the same 'Secondary content' string, so a
/// bare `find.text` would answer for whichever one happens to come first.
Finder secondLineOf(String label) => find.descendant(
  of: buttonWith(label).first,
  matching: find.text('Secondary content'),
);

/// The rect of the glyph inside [button].
Rect glyphIn(WidgetTester tester, Finder button) => tester.getRect(
  find.descendant(of: button, matching: find.byType(Icon)).first,
);

/// Whether each focus ring in the tree is currently painted, in tree order.
///
/// The ring is a foreground painter that stays attached whether or not it draws
/// anything, so its `visible` flag — not its presence — is the answer to "can a
/// keyboard user see where they are".
List<bool> ringVisibility(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((CustomPaint paint) => paint.foregroundPainter)
    .whereType<FluentFocusRingPainter>()
    .map((FluentFocusRingPainter ring) => ring.visible)
    .toList();

/// The palette the demo actually resolved against.
///
/// Read off the tree rather than rebuilt from `FluentThemeData.light()`, so a
/// test cannot pass by agreeing with a theme the app never used.
FluentColors themeColors(WidgetTester tester) =>
    FluentTheme.of(tester.element(find.byType(DecoratedBox).first)).colors;
