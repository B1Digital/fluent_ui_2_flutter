import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentNavSectionHeader` has no Figma fixture — upstream ships it only as
/// `useNavSectionHeaderStyles.styles.ts`, whose whole root rule is three
/// declarations. Every expectation below is that file, transcribed.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 260, child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  EdgeInsets paddingOf(WidgetTester tester) => tester
      .widget<Padding>(
        find
            .ancestor(
              of: find.text('Workspaces'),
              matching: find.byType(Padding),
            )
            .last,
      )
      .padding
      .resolve(TextDirection.ltr);

  testWidgets('insets are marginInlineStart 10 and marginBlock 8', (
    tester,
  ) async {
    await pump(tester, const FluentNavSectionHeader(child: Text('Workspaces')));

    expect(
      paddingOf(tester),
      const EdgeInsets.fromLTRB(10, 8, 0, 8),
      reason:
          'useNavSectionHeaderStyles: marginInlineStart 10px, marginBlock 8px, '
          'and no inline-end margin at all',
    );
  });

  testWidgets('the label is on the caption1Strong ramp', (tester) async {
    await pump(tester, const FluentNavSectionHeader(child: Text('Workspaces')));

    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final style = tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Workspaces'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style;

    expect(
      style.fontSize,
      theme.typography.caption1Strong.fontSize,
      reason:
          'useNavSectionHeaderStyles spreads typographyStyles.caption1Strong',
    );
    expect(
      style.fontWeight,
      theme.typography.caption1Strong.fontWeight,
      reason:
          'caption1Strong is semibold, which is what separates a section '
          'header from a nav row label',
    );
  });

  testWidgets('it reports as a level 3 heading', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const FluentNavSectionHeader(child: Text('Workspaces')));

    expect(
      tester.getSemantics(find.text('Workspaces')).headingLevel,
      3,
      reason:
          'upstream hardcodes <h3> in useNavSectionHeader.ts; Flutter has no '
          'heading SemanticsRole, so headingLevel carries it',
    );
    handle.dispose();
  });

  testWidgets('it renders outside a FluentNav without throwing', (
    tester,
  ) async {
    await pump(tester, const FluentNavSectionHeader(child: Text('Workspaces')));

    expect(
      tester.takeException(),
      isNull,
      reason:
          'unlike the row widgets this never reads _FluentNavScope — it is '
          'only a label, and is useful in any nav-shaped list',
    );
  });

  testWidgets('it is not a focus target', (tester) async {
    await pump(
      tester,
      const FluentNav(
        children: <Widget>[
          FluentNavSectionHeader(child: Text('Workspaces')),
          FluentNavItem(value: 'home', child: Text('Home')),
        ],
      ),
    );

    expect(
      find.descendant(
        of: find.byType(FluentNavSectionHeader),
        matching: find.byType(Focus),
      ),
      findsNothing,
      reason: 'a section header takes no focus — upstream renders a bare h3',
    );
  });
}
