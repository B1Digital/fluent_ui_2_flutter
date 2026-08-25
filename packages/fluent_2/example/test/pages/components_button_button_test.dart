import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Button's page is a gallery: eight sections, seven of them walls of buttons
/// whose `onPressed` is a no-op. So the knobs here are the design axes
/// themselves — shape, appearance, size, iconPosition, disabled — and every
/// test below reads what the button PAINTED rather than what it was handed. An
/// axis that resolves correctly and never reaches the surface looks identical
/// from the outside to one that works, which is exactly the defect a
/// mount-only test cannot see. Loading is the one demo with a state machine,
/// and it takes the press-driven tests.
void main() {
  const String page = 'components-button-button';

  group('default', () {
    final DocsSection section = sectionOf('components-button-button--default');

    testWidgets('the button answers a real mouse with the hover fill and gives '
        'it back on the way out', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      final Finder button = find.byType(FluentButton);

      expect(decorationUnder(tester, button).color, colors.neutralBackground1);

      // The demo's callback is empty, so the fill is the only response this
      // button can make to a pointer — and it is the response a user reads as
      // "this is clickable" before they ever click.
      final TestGesture mouse = await mouseHover(tester, button);
      expect(
        decorationUnder(tester, button).color,
        colors.neutralBackground1Hover,
      );

      await mouseAway(tester, mouse);
      expect(decorationUnder(tester, button).color, colors.neutralBackground1);
    });

    testWidgets('a whole mouse click leaves nothing stuck', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      await mouseClick(tester, find.byType(FluentButton));
      // A press state that is never cleared paints the button pressed forever,
      // which a test that only checks "the callback fired" would never notice.
      expect(
        decorationUnder(tester, find.byType(FluentButton)).color,
        colors.neutralBackground1,
      );
    });

    testWidgets('focus arrives with a ring for the keyboard and without one '
        'for the mouse', (WidgetTester tester) async {
      await pumpSection(tester, section);
      expect(ringVisibility(tester), <bool>[false]);

      await mouseClick(tester, find.byType(FluentButton));
      // Fluent raises the ring for keyboard-visible focus only. A click that
      // left one behind is the "focus ring follows my mouse" bug that
      // upstream's keyborg gate — and our FluentInputModality — exist to
      // prevent, and no synthetic tap can catch it because a synthetic tap
      // never sets the modality either way.
      expect(ringVisibility(tester), <bool>[false]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      expect(
        ringVisibility(tester),
        <bool>[true],
        reason: 'a keyboard user must be able to see where they are',
      );
    });
  });

  group('shape', () {
    final DocsSection section = sectionOf('components-button-button--shape');

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

    testWidgets('the shape axis moves the corners and nothing else', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Shape is a corner treatment upstream, so a shape that also changed the
      // height would be a size knob wearing the wrong name.
      final double rounded = tester.getSize(buttonWith('Rounded')).height;
      expect(tester.getSize(buttonWith('Circular')).height, rounded);
      expect(tester.getSize(buttonWith('Square')).height, rounded);
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf(
      'components-button-button--appearance',
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

      // Only secondary and outline are bordered. Three of these five have the
      // same clear fill, so a border that leaked through would be the whole
      // difference between them.
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

    testWidgets('subtle and transparent are only told apart under a pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      // At rest the two are the same clear fill — that is upstream's design,
      // which makes hover the ONLY place this half of the appearance axis is
      // observable at all. A synthetic tap never gets here.
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
      expect(
        decorationUnder(tester, buttonWith('Subtle')).color,
        colors.subtleBackground,
      );

      mouse = await mouseHover(tester, buttonWith('Transparent'));
      expect(
        decorationUnder(tester, buttonWith('Transparent')).color,
        colors.transparentBackgroundHover,
      );
      // Transparent has no fill to change, so its label is the whole of its
      // hover response: it is the one appearance whose text goes brand.
      expect(
        textStyleOf(tester, find.text('Transparent'))?.color,
        colors.neutralForeground2BrandHover,
      );
      await mouseAway(tester, mouse);
      expect(
        textStyleOf(tester, find.text('Transparent'))?.color,
        colors.neutralForeground2,
      );
    });
  });

  group('icon', () {
    final DocsSection section = sectionOf('components-button-button--icon');

    testWidgets('iconPosition moves the glyph across the label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      const String before = 'With calendar icon before contents';
      const String after = 'With calendar icon after contents';

      expect(
        glyphIn(tester, buttonWith(before)).right,
        lessThanOrEqualTo(tester.getRect(find.text(before)).left),
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
      final Finder iconOnly = find.descendant(
        of: find.byType(FluentTooltip),
        matching: find.byType(FluentButton),
      );

      // The label of an icon-only button lives in its tooltip, so hover is the
      // only way a sighted mouse user ever learns what it does. `tester.tap`
      // synthesises no enter event and would report this working while the
      // tooltip never appeared.
      expect(find.text('With calendar icon only'), findsNothing);
      final TestGesture mouse = await mouseHover(tester, iconOnly);
      expect(find.text('With calendar icon only'), findsOneWidget);

      await mouseAway(tester, mouse);
      expect(find.text('With calendar icon only'), findsNothing);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-button-button--size');

    testWidgets('the size axis reaches both the box and the type ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final double small = tester.getSize(buttonWith('Small')).height;
      final double medium = tester.getSize(buttonWith('Medium')).height;
      final double large = tester.getSize(buttonWith('Large')).height;

      // Floors, not equalities: 24/32/40 is the minimum height each size
      // declares, and the label's line box is free to push past it. It does at
      // Medium here — the test binding reports Android, whose body ramp is
      // 16/24 against web's 14/20 — so pinning the web numbers would be
      // asserting against a font this app never resolved.
      expect(small, greaterThanOrEqualTo(24));
      expect(medium, greaterThanOrEqualTo(32));
      expect(large, greaterThanOrEqualTo(40));
      expect(small, lessThan(medium));
      expect(medium, lessThan(large));

      // And the type moved with the box. A size axis wired only to the height
      // gives three boxes of caption text, which is the half-done version of
      // this knob and looks right in a screenshot.
      final double? smallType = textStyleOf(
        tester,
        find.text('Small'),
      )?.fontSize;
      final double? mediumType = textStyleOf(
        tester,
        find.text('Medium'),
      )?.fontSize;
      final double? largeType = textStyleOf(
        tester,
        find.text('Large'),
      )?.fontSize;
      expect(smallType, isNotNull);
      expect(smallType, lessThan(mediumType!));
      expect(mediumType, lessThan(largeType!));
    });

    testWidgets('the large glyph is 24 where the other two sizes take 20', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // The one number Figma models as an instance rather than a token, and the
      // reason a Large icon-and-label button reaches 40 on 8px of padding.
      expect(
        glyphIn(tester, buttonWith('Small with calendar icon')).width,
        FluentSize.size200,
      );
      expect(
        glyphIn(tester, buttonWith('Medium with calendar icon')).width,
        FluentSize.size200,
      );
      expect(
        glyphIn(tester, buttonWith('Large with calendar icon')).width,
        FluentSize.size240,
      );
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-button-button--disabled');

    testWidgets('disabled is a state and not a treatment: a pointer changes '
        'nothing', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);
      // Both rows carry the same three labels, so the index picks the row: 0 is
      // the secondary row, 1 the primary one.
      final Finder disabled = buttonWith('Disabled state').at(0);
      final Finder enabled = buttonWith('Enabled state').at(0);

      expect(tester.widget<FluentButton>(disabled).onPressed, isNull);
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

    testWidgets('a disabled primary button loses its brand fill', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      expect(
        decorationUnder(tester, buttonWith('Enabled state').at(1)).color,
        colors.brandBackground,
      );
      // Disabled resolves to the neutral disabled token on every appearance —
      // a primary button that stayed brand while disabled would read as the
      // one action on the page a user should take.
      expect(
        decorationUnder(tester, buttonWith('Disabled state').at(1)).color,
        colors.neutralBackgroundDisabled,
      );
    });

    testWidgets('only the disabled focusable buttons keep a stop in the tab '
        'order', (WidgetTester tester) async {
      await pumpSection(tester, section);
      // The section's own claim. Our disabled state refuses focus outright, so
      // the `Focus` the page wraps the third button in is the whole of
      // upstream's disabledFocusable: without it that button would vanish from
      // the tab order and a screen reader would never reach it.
      expect(tabStopLabels(tester), <String>[
        'Enabled state',
        'Disabled focusable state',
        'Enabled state',
        'Disabled focusable state',
      ]);
    });
  });

  group('loading', () {
    final DocsSection section = sectionOf('components-button-button--loading');

    testWidgets('a real mouse click starts the load, and the button reads as '
        'busy rather than switched off', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final FluentColors colors = themeColors(tester);

      await mouseClick(tester, buttonWith('Start loading'));
      expect(find.text('Loading'), findsOneWidget);
      expect(
        find.byType(FluentSpinner),
        findsOneWidget,
        reason: 'the spinner is the icon slot the loading phase fills',
      );
      expect(
        tester.widget<FluentButton>(buttonWith('Loading')).onPressed,
        isNull,
      );
      // The demo's own claim: it stops responding but keeps its resting
      // colours. The disabled fill here would be the bug.
      expect(
        decorationUnder(tester, buttonWith('Loading')).color,
        colors.neutralBackground1,
      );

      // Drains the demo's five-second delay. Left pending it would fail the
      // test on teardown, and the loaded phase would never be reached.
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(find.text('Loaded'), findsOneWidget);
      expect(find.byType(FluentSpinner), findsNothing);
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: buttonWith('Loaded'),
                matching: find.byType(Icon),
              ),
            )
            .icon,
        FluentIcons.checkmark_20_filled,
      );
    });

    testWidgets('reset takes the button back to where it started', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final String initial = textSnapshot(tester);

      await tapAndSettle(tester, buttonWith('Start loading'));
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(find.text('Loaded'), findsOneWidget);

      await tapAndSettle(tester, buttonWith('Reset loading state'));
      expect(textSnapshot(tester), initial);
      expect(
        tester.widget<FluentButton>(buttonWith('Start loading')).onPressed,
        isNotNull,
        reason: 'reset must hand the button back, not just relabel it',
      );
    });

    testWidgets('resetting mid-flight cancels the pending load', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, buttonWith('Start loading'));
      await tester.pump(const Duration(seconds: 2));
      await tapAndSettle(tester, buttonWith('Reset loading state'));
      expect(find.text('Start loading'), findsOneWidget);

      // The run counter is what makes this a cancellation rather than a
      // relabel: past the original deadline the abandoned delay must not drag
      // the button into Loaded behind the user's back.
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(find.text('Loaded'), findsNothing);
      expect(find.text('Start loading'), findsOneWidget);
    });

    testWidgets('Enter starts the load, as the props table promises', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // "Invoked on tap and on Space or Enter" is a claim on this page's props
      // table, and this demo is the only one on it where a keyboard press has
      // anything to show for itself. The first Tab lands on the first button.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('Loading'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(find.text('Loaded'), findsOneWidget);
    });

    testWidgets('unmounting mid-load is clean', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, buttonWith('Start loading'));
      await expectCleanTeardown(tester, section.id);
      // The delay outlives the widget, so the `mounted` guard is the only thing
      // standing between it and a setState on a dead State.
      await tester.pump(const Duration(seconds: 6));
      expectClean(tester, 'the load completing after unmount');
    });
  });

  group('with long text', () {
    const String long =
        'Long text wraps after it hits the max width of the component';
    final DocsSection section = sectionOf(
      'components-button-button--with-long-text',
    );

    testWidgets('the long label wraps inside the 280 the demo gives it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Size wrapped = tester.getSize(buttonWith(long));
      expect(wrapped.width, lessThanOrEqualTo(280));
      // Two lines, not one that ran past its box: the medium ramp is 32 high,
      // so a taller button is one whose label actually wrapped. Without the
      // Flexible the Row would hand the label unbounded width and it would
      // overflow instead — which pumpSection's clean-tree check also catches.
      expect(
        wrapped.height,
        greaterThan(tester.getSize(buttonWith('Short text')).height),
      );
      expect(
        tester.getSize(find.text(long)).width,
        lessThanOrEqualTo(280 - FluentSpacing.m * 2),
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

/// The button whose label reads exactly [label].
Finder buttonWith(String label) => find.widgetWithText(FluentButton, label);

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

/// The label of each tab stop inside the demo, in traversal order.
///
/// A stop that encloses more than one label is a scope — the route's, the
/// app's — rather than a control, so it is not a stop on any button and is
/// dropped.
List<String> tabStopLabels(WidgetTester tester) => tester
    .binding
    .focusManager
    .rootScope
    .traversalDescendants
    .map((FocusNode node) => node.context)
    .nonNulls
    .map(
      (BuildContext context) => find.descendant(
        of: find.byWidget(context.widget),
        matching: find.byType(Text),
      ),
    )
    .where((Finder labels) => labels.evaluate().length == 1)
    .map((Finder label) => tester.widget<Text>(label).data ?? '')
    .toList();
