import 'dart:ui' show Tristate;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentHamburger` has no Figma fixture. Every expectation below is
/// `useHamburger.tsx` and `useHamburgerStyles.styles.ts`, transcribed.
void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: Align(alignment: Alignment.topCenter, child: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The button's own fill box — the [DecoratedBox] wrapping the content, as
  /// distinct from the focus ring, which paints no child of its own.
  BoxDecoration fill(WidgetTester tester) =>
      tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(FluentButton),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .first
              .decoration
          as BoxDecoration;

  testWidgets('it draws the Navigation20Filled glyph', (tester) async {
    await pump(
      tester,
      FluentHamburger(onPressed: () {}, semanticLabel: 'Collapse navigation'),
    );

    expect(
      tester.widget<Icon>(find.byType(Icon)).icon,
      FluentIcons.navigation_20_filled,
      reason: 'useHamburger.tsx passes icon: <Navigation20Filled />',
    );
  });

  testWidgets('it rests on the nav surface, not on nothing', (tester) async {
    await pump(
      tester,
      FluentHamburger(onPressed: () {}, semanticLabel: 'Collapse navigation'),
    );

    expect(
      fill(tester).color?.toARGB32(),
      theme.colors.neutralBackground4.toARGB32(),
      reason:
          'useHamburgerStyles overrides the transparent appearance back to '
          'colorNeutralBackground4, so the button disappears into the nav',
    );
  });

  testWidgets('hovering moves it to the 4Hover token', (tester) async {
    await pump(
      tester,
      FluentHamburger(onPressed: () {}, semanticLabel: 'Collapse navigation'),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(FluentButton)));
    await tester.pumpAndSettle();

    expect(
      fill(tester).color?.toARGB32(),
      theme.colors.neutralBackground4Hover.toARGB32(),
      reason: 'useHamburgerStyles binds navItemTokens hover to 4Hover',
    );
  });

  testWidgets('expanded is absent unless the caller asks for it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      FluentHamburger(onPressed: () {}, semanticLabel: 'Expand navigation'),
    );

    expect(
      tester.getSemantics(find.byType(FluentButton)).flagsCollection.isExpanded,
      Tristate.none,
      reason:
          'upstream Hamburger sets no ARIA at all; NavAccessibility.md puts '
          'aria-expanded on the consumer, and only for inline navs',
    );
    handle.dispose();
  });

  testWidgets('expanded is reported when the caller passes it', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      FluentHamburger(
        onPressed: () {},
        semanticLabel: 'Collapse navigation',
        expanded: true,
      ),
    );

    expect(
      tester.getSemantics(find.byType(FluentButton)).flagsCollection.isExpanded,
      Tristate.isTrue,
      reason: 'a non-null expanded is the opt-in inline-nav contract',
    );
    handle.dispose();
  });

  testWidgets('the caller style is merged last and wins', (tester) async {
    await pump(
      tester,
      FluentHamburger(
        onPressed: () {},
        semanticLabel: 'Collapse navigation',
        style: FluentButtonStyle.from(backgroundColor: const Color(0xFF00FF00)),
      ),
    );

    expect(
      fill(tester).color?.toARGB32(),
      const Color(0xFF00FF00).toARGB32(),
      reason:
          'style is merged over the nav fill, as everywhere else in this '
          'package',
    );
  });

  testWidgets('semanticLabel reaches assistive technology', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      FluentHamburger(onPressed: () {}, semanticLabel: 'Collapse navigation'),
    );

    expect(
      find.bySemanticsLabel('Collapse navigation'),
      findsOneWidget,
      reason:
          'NavAccessibility.md: "Ensure all Hamburger icon buttons have an '
          'accessible name"',
    );
    handle.dispose();
  });
}
