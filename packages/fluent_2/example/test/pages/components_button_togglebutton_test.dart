import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// fluent_2 ships no toggle button, so this page composes one out of
/// `FluentButton` by re-resolving the button's own style with
/// `WidgetState.selected` folded in. That makes checked-ness a *colour* and
/// nothing else on six of the nine sections: there is no `checked` property on
/// the rendered widget to read, so a suite that asserted on the demo's own
/// state would pass on a toggle nobody can see toggling. Every test below reads
/// the painted surface, the painted border and the resolved label colour
/// instead — the three places the selected token can land — and requires the
/// triple to move on a press and to come back on the next one.
void main() {
  const String page = 'components-button-togglebutton';

  group('default', () {
    final DocsSection section = sectionOf(
      'components-button-togglebutton--default',
    );

    testWidgets('a real mouse click checks the button, and the check outlives '
        'the pointer', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      final Finder button = find.byType(FluentButton);

      expect(decorationUnder(tester, button).color, colors.neutralBackground1);

      await mouseClick(tester, button);
      // mouseClick leaves the pointer off the target, which is the whole point
      // here: hover outranks selected in Fluent's token precedence, so a
      // checked button reads as merely hovered until the mouse moves away. If
      // the check did not survive that, clicking would look like nothing
      // happened the moment the user's hand left.
      expect(
        decorationUnder(tester, button).color,
        colors.neutralBackground1Selected,
      );

      await mouseClick(tester, button);
      expect(decorationUnder(tester, button).color, colors.neutralBackground1);
    });

    testWidgets('the checked border is the selected token, not the resting '
        'one', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      final Finder button = find.byType(FluentButton);

      expect(
        decorationUnder(tester, button).border?.top.color,
        colors.neutralStroke1,
      );
      await tapAndSettle(tester, button, what: 'the toggle button');
      // Folding `selected` into the live state set has to reach every colour
      // the style carries. A checked button that kept its resting border is the
      // signature of a style that was pinned rather than re-resolved.
      expect(
        decorationUnder(tester, button).border?.top.color,
        colors.neutralStroke1Selected,
      );
    });

    testWidgets('Space checks the focused toggle', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      final Finder button = find.byType(FluentButton);

      // A toggle button is the one control on this page a keyboard user has to
      // be able to work: it holds state, so being unable to flip it is not a
      // missing convenience but a missing control.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settle(tester);
      expect(
        decorationUnder(tester, button).color,
        colors.neutralBackground1Selected,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settle(tester);
      expect(decorationUnder(tester, button).color, colors.neutralBackground1);
    });
  });

  group('shape', () {
    final DocsSection section = sectionOf(
      'components-button-togglebutton--shape',
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

    testWidgets('checking a button keeps its shape', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // The checked style re-resolves three colours and must not disturb the
      // geometry it was merged over: a circular toggle that squared off when
      // checked would be a merge that dropped the radius.
      await tapAndSettle(tester, buttonWith('Circular'));
      expect(
        decorationUnder(tester, buttonWith('Circular')).borderRadius,
        FluentRadius.allCircular,
      );
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf(
      'components-button-togglebutton--appearance',
    );

    testWidgets('checking swaps the regular glyph for the filled one', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // checkedIcon stands in for upstream's bundleIcon. On transparent and
      // outline the fill barely moves, so on those two the glyph is most of
      // what tells a user the button is on.
      for (final String label in appearances) {
        expect(
          glyphOf(tester, buttonWith(label)),
          FluentIcons.calendar_month_20_regular,
          reason: '$label starts unchecked',
        );
        await tapAndSettle(tester, buttonWith(label));
        expect(
          glyphOf(tester, buttonWith(label)),
          FluentIcons.calendar_month_20_filled,
          reason: '$label must fill its glyph when checked',
        );
        await tapAndSettle(tester, buttonWith(label));
        expect(
          glyphOf(tester, buttonWith(label)),
          FluentIcons.calendar_month_20_regular,
          reason: '$label must give the regular glyph back',
        );
      }
    });

    testWidgets('a real mouse drives the primary toggle too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      expect(
        decorationUnder(tester, buttonWith('Primary')).color,
        colors.brandBackground,
      );
      await mouseClick(tester, buttonWith('Primary'));
      expect(
        decorationUnder(tester, buttonWith('Primary')).color,
        colors.brandBackgroundSelected,
      );
      expect(
        glyphOf(tester, buttonWith('Primary')),
        FluentIcons.calendar_month_20_filled,
      );
    });
  });

  group('accessible appearance', () {
    final DocsSection section = sectionOf(
      'components-button-togglebutton--accessible-appearance',
    );

    testWidgets('every appearance shows its checked state without an icon to '
        'lean on', (WidgetTester tester) async {
      await pumpSection(tester, section);

      // This section is the Appearance one with the glyphs taken away, which
      // is exactly the case its description is about: "for when the icon is
      // not used to differentiate checked vs. unchecked states". So each of
      // the five has to carry the whole signal in its colours — an appearance
      // whose checked fill, border and label all match its resting ones is a
      // toggle that cannot be seen to toggle.
      for (final String label in appearances) {
        final ToggleSignature resting = signatureOf(tester, label);
        await tapAndSettle(tester, buttonWith(label));
        expect(
          signatureOf(tester, label),
          isNot(resting),
          reason: '$label paints nothing different when checked',
        );

        await tapAndSettle(tester, buttonWith(label));
        expect(
          signatureOf(tester, label),
          resting,
          reason: '$label did not come back when unchecked',
        );
      }
    });

    testWidgets('one toggle checking does not check its neighbours', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<ToggleSignature> before = appearances
          .map((String label) => signatureOf(tester, label))
          .toList();

      await mouseClick(tester, buttonWith('Subtle'));

      // Each button owns its own checked state. Sharing one would be invisible
      // in a demo where every button starts unchecked and only one is pressed
      // — until a user pressed a second one.
      for (int i = 0; i < appearances.length; i++) {
        final String label = appearances[i];
        final Matcher matcher = label == 'Subtle'
            ? isNot(before[i])
            : equals(before[i]);
        expect(signatureOf(tester, label), matcher, reason: label);
      }
    });
  });

  group('icon', () {
    final DocsSection section = sectionOf(
      'components-button-togglebutton--icon',
    );

    testWidgets('iconPosition moves the glyph across the label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      const String before = 'With calendar icon before contents';
      const String after = 'With calendar icon after contents';

      expect(
        glyphRect(tester, buttonWith(before)).right,
        lessThanOrEqualTo(tester.getRect(find.text(before)).left),
      );
      expect(
        glyphRect(tester, buttonWith(after)).left,
        greaterThanOrEqualTo(tester.getRect(find.text(after)).right),
      );
    });

    testWidgets('the icon-only toggle names itself under a pointer and still '
        'checks', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder iconOnly = find.descendant(
        of: find.byType(FluentTooltip),
        matching: find.byType(FluentButton),
      );

      // With no label, this button's name lives in a tooltip and its state
      // lives in its glyph — neither of which a synthetic tap can reach or
      // read.
      expect(find.text('With calendar icon only'), findsNothing);
      final TestGesture mouse = await mouseHover(tester, iconOnly);
      expect(find.text('With calendar icon only'), findsOneWidget);
      await mouseAway(tester, mouse);
      expect(find.text('With calendar icon only'), findsNothing);

      await mouseClick(tester, iconOnly);
      expect(glyphOf(tester, iconOnly), FluentIcons.calendar_month_20_filled);
      // The tooltip's own 250ms show and hide timers are started by the click's
      // enter and exit; leaving one pending would fail this test on teardown
      // rather than on its subject.
      await tester.pump(const Duration(milliseconds: 300));
      await settle(tester);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf(
      'components-button-togglebutton--size',
    );

    testWidgets('the size axis reaches both the box and the type ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final double small = tester.getSize(buttonWith('Size: small')).height;
      final double medium = tester.getSize(buttonWith('Size: medium')).height;
      final double large = tester.getSize(buttonWith('Size: large')).height;

      // Floors rather than equalities: 24/32/40 is the minimum each size
      // declares and the label's line box may push past it, which it does at
      // Medium under the test binding's Android type ramp.
      expect(small, greaterThanOrEqualTo(24));
      expect(small, lessThan(medium));
      expect(medium, lessThan(large));

      final double? smallType = textStyleOf(
        tester,
        find.text('Size: small'),
      )?.fontSize;
      final double? largeType = textStyleOf(
        tester,
        find.text('Size: large'),
      )?.fontSize;
      expect(smallType, isNotNull);
      expect(smallType, lessThan(largeType!));
    });

    testWidgets('a checked toggle keeps its size', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final double before = tester.getSize(buttonWith('Size: large')).height;

      await tapAndSettle(tester, buttonWith('Size: large'));
      // The checked style is merged over the resolved one, so it must not drop
      // the size ramp's minimumSize on the way through.
      expect(tester.getSize(buttonWith('Size: large')).height, before);
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf(
      'components-button-togglebutton--disabled',
    );

    testWidgets('a disabled toggle refuses both the press and the pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      // Both rows carry the same three labels, so the index picks the row: 0 is
      // the secondary row, 1 the primary one.
      final Finder disabled = buttonWith('Disabled state').at(0);

      expect(tester.widget<FluentButton>(disabled).onPressed, isNull);
      expect(
        decorationUnder(tester, disabled).color,
        colors.neutralBackgroundDisabled,
      );

      await mouseClick(tester, disabled);
      expect(
        decorationUnder(tester, disabled).color,
        colors.neutralBackgroundDisabled,
        reason: 'a disabled toggle must not check itself when clicked',
      );

      final TestGesture mouse = await mouseHover(tester, disabled);
      expect(
        decorationUnder(tester, disabled).color,
        colors.neutralBackgroundDisabled,
        reason: 'nor light up under a pointer',
      );
      await mouseAway(tester, mouse);
    });

    testWidgets('the enabled toggle in the same row still works', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      final Finder enabled = buttonWith('Enabled state').at(0);

      // The control for the test above: the same gesture on the enabled
      // sibling does move, so "nothing happened" there is about the disabled
      // state and not about the click missing.
      await mouseClick(tester, enabled);
      expect(
        decorationUnder(tester, enabled).color,
        colors.neutralBackground1Selected,
      );
    });

    testWidgets('a disabled primary toggle loses its brand fill', (
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

  group('checked', () {
    final DocsSection section = sectionOf(
      'components-button-togglebutton--checked',
    );

    testWidgets('the controlled pair starts on opposite sides', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      expect(
        decorationUnder(tester, buttonWith('Controlled checked state')).color,
        colors.neutralBackground1Selected,
      );
      expect(
        decorationUnder(tester, buttonWith('Controlled unchecked state')).color,
        colors.neutralBackground1,
      );
    });

    testWidgets('a controlled toggle does not move when pressed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The section's own claim: with a checked value given, the button is
      // controlled and only changes when that value does. The internal flag
      // still flips on a press, so a button that read its own flag first would
      // pass every other test on this page and fail exactly here.
      for (final String label in <String>[
        'Controlled checked state',
        'Controlled unchecked state',
      ]) {
        final ToggleSignature before = signatureOf(tester, label);
        await mouseClick(tester, buttonWith(label));
        expect(signatureOf(tester, label), before, reason: label);
        await tapAndSettle(tester, buttonWith(label));
        expect(signatureOf(tester, label), before, reason: '$label, twice');
      }
    });
  });

  group('with long text', () {
    const String long =
        'Long text wraps after it hits the max width of the component';
    final DocsSection section = sectionOf(
      'components-button-togglebutton--with-long-text',
    );

    testWidgets('the long label wraps inside the 280 the demo gives it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Size wrapped = tester.getSize(buttonWith(long));
      expect(wrapped.width, lessThanOrEqualTo(280));
      // Two lines rather than one that ran past its box. Without the Flexible
      // the Row would hand the label unbounded width and it would overflow —
      // which pumpSection's clean-tree check catches from the other side.
      expect(
        wrapped.height,
        greaterThan(tester.getSize(buttonWith('Short text')).height),
      );
    });

    testWidgets('the wrapped toggle still checks', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      // A label in a Flexible is a hit target the size of the whole button, not
      // of one line of text — worth proving, since the wrap is the one thing
      // this section changes about the button.
      await mouseClick(tester, buttonWith(long));
      expect(
        decorationUnder(tester, buttonWith(long)).color,
        colors.neutralBackground1Selected,
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

/// The five appearance labels, in the order both appearance sections list them.
const List<String> appearances = <String>[
  'Default',
  'Primary',
  'Outline',
  'Subtle',
  'Transparent',
];

/// Everything a toggle button can say about being checked.
typedef ToggleSignature = ({Color? fill, BorderSide? border, Color? label});

/// The toggle button whose label reads exactly [label].
Finder buttonWith(String label) => find.widgetWithText(FluentButton, label);

/// What the button labelled [label] currently paints.
///
/// Which of the three colours carries the checked state depends on the
/// appearance — transparent has no fill to change and says it in its label,
/// outline says it in its border — so the honest question is whether the triple
/// moved, not whether any named one of them did.
ToggleSignature signatureOf(WidgetTester tester, String label) {
  final BoxDecoration surface = decorationUnder(tester, buttonWith(label));
  return (
    fill: surface.color,
    border: surface.border?.top,
    label: textStyleOf(tester, find.text(label))?.color,
  );
}

/// The glyph [button] currently renders.
IconData glyphOf(WidgetTester tester, Finder button) => tester
    .widget<Icon>(
      find.descendant(of: button, matching: find.byType(Icon)).first,
    )
    .icon!;

/// The rect of the glyph inside [button].
Rect glyphRect(WidgetTester tester, Finder button) => tester.getRect(
  find.descendant(of: button, matching: find.byType(Icon)).first,
);

/// The palette the demo actually resolved against.
///
/// Read off the tree rather than rebuilt from `FluentThemeData.light()`, so a
/// test cannot pass by agreeing with a theme the app never used.
FluentColors themeColors(WidgetTester tester) =>
    FluentTheme.of(tester.element(find.byType(DecoratedBox).first)).colors;
