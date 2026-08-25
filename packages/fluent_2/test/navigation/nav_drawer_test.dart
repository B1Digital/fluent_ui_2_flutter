import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentNavDrawer` has no Figma fixture. Every expectation below comes from
/// `useNavDrawerStyles.styles.ts`, `useNavDrawerBodyStyles.styles.ts`,
/// `useNavDrawerHeaderStyles.styles.ts` and `navItemTokens.defaultDrawerWidth`.
void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: SizedBox(height: 600, child: Row(children: <Widget>[child])),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget drawer({
    FluentDrawerSize? size,
    FluentDrawerStyle? style,
    List<Widget> header = const <Widget>[],
  }) => FluentNavDrawer(
    open: true,
    type: FluentDrawerType.inline,
    size: size,
    style: style,
    header: header,
    child: const FluentNav(
      children: <Widget>[FluentNavItem(value: 'home', child: Text('Home'))],
    ),
  );

  /// The panel's own width, not the nav's. The preset's 10/4 body gutters sit
  /// inside the panel, so a `FluentNav` always measures 14 narrower than the
  /// drawer that carries it — the width tokens below describe the panel.
  double panelWidth(WidgetTester tester) =>
      tester.getSize(find.byType(FluentNavDrawer)).width;

  testWidgets('an unsized nav drawer is 260 wide', (tester) async {
    await pump(tester, drawer());

    expect(
      panelWidth(tester),
      fluentNavDrawerWidth,
      reason:
          'navItemTokens.defaultDrawerWidth is 260, and upstream applies it '
          'only when size is unset (!size && styles.defaultWidth)',
    );
  });

  testWidgets('a passed size wins over the 260 default', (tester) async {
    await pump(tester, drawer(size: FluentDrawerSize.medium));

    expect(
      panelWidth(tester),
      fluentDrawerMediumWidth,
      reason:
          'upstream: 260 applies only when size is unset. Pass one and the '
          "drawer's own width table wins",
    );
  });

  testWidgets('the panel paints the nav surface, not Background1', (
    tester,
  ) async {
    await pump(tester, drawer());

    final decoration =
        tester
                .widgetList<DecoratedBox>(find.byType(DecoratedBox))
                .first
                .decoration
            as BoxDecoration;

    expect(
      decoration.color?.toARGB32(),
      theme.colors.neutralBackground4.toARGB32(),
      reason:
          'useNavDrawerStyles overrides the drawer root to '
          'colorNeutralBackground4. FluentDrawer defaults to Background1, '
          'which would not match the rows inside it in any theme',
    );
  });

  testWidgets('the body carries the 10/4 gutters', (tester) async {
    await pump(tester, drawer());

    final padding = tester
        .widget<Padding>(
          find
              .ancestor(
                of: find.byType(FluentNav),
                matching: find.byType(Padding),
              )
              .first,
        )
        .padding
        .resolve(TextDirection.ltr);

    expect(
      padding,
      const EdgeInsets.fromLTRB(10, 0, 4, 0),
      reason:
          'useNavDrawerBodyStyles: padding 0 spacingHorizontalXS 0 '
          'spacingHorizontalMNudge — 4 inline-end, 10 inline-start',
    );
  });

  testWidgets('the nav still emits its own 2px row gap', (tester) async {
    await pump(tester, drawer());

    expect(
      tester
          .widget<Column>(
            find
                .descendant(
                  of: find.byType(FluentNav),
                  matching: find.byType(Column),
                )
                .first,
          )
          .spacing,
      FluentSpacing.xxs,
      reason:
          'FluentNav already emits rowGap; a NavDrawerBody widget applying it '
          'again is exactly why this package does not ship one',
    );
  });

  testWidgets('the caller style is merged last and wins', (tester) async {
    await pump(tester, drawer(style: FluentDrawerStyle.from(width: 400)));

    expect(
      panelWidth(tester),
      400,
      reason: 'style is merged above the nav preset, as everywhere else',
    );
  });

  testWidgets('a FluentDrawerTheme overrides the nav preset', (tester) async {
    await tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: SizedBox(
          height: 600,
          child: Row(
            children: <Widget>[
              FluentDrawerTheme(
                style: FluentDrawerStyle.from(width: 320),
                child: drawer(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      panelWidth(tester),
      320,
      reason:
          'the preset must sit BELOW an ambient FluentDrawerTheme, which is '
          'why FluentNavDrawer looks the theme up itself and re-merges it',
    );
  });
}
