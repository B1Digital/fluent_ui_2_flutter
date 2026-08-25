import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web_example/pages.dart';
import 'package:fluent_2_web_example/shell/catalog.dart';
import 'package:fluent_2_web_example/shell/router.dart';
import 'package:fluent_2_web_example/shell/showroom_app.dart';
import 'package:fluent_2_web_example/shell/theme_variants.dart';
import 'package:fluent_2_web_example/shell/widgets/docs_scaffold.dart';
import 'package:fluent_2_web_example/shell/widgets/preview_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The docs toolbar's Theme dropdown is a *page* override.
///
/// It used to write the shell's global variant — one tap on a page moved the
/// toolbar at the top of the window and followed the reader to every page
/// after. These three tests pin the three properties that stopped being true:
/// the override reaches the page's previews, it does not reach the shell, and
/// it does not outlive the page.
void main() {
  // The two cheapest pages that actually carry stories — a page with no
  // sections renders no toolbar at all, and a page with thirty renders slowly
  // for no extra coverage.
  final List<DocsPage> withStories =
      allPages.where((DocsPage p) => p.sections.isNotEmpty).toList()..sort(
        (DocsPage a, DocsPage b) =>
            a.sections.length.compareTo(b.sections.length),
      );
  final DocsPage pageA = withStories[0];
  final DocsPage pageB = withStories[1];

  testWidgets('the page dropdown themes the page but not the shell', (
    WidgetTester tester,
  ) async {
    await _boot(tester);
    await _go(tester, pageA.id);

    expect(_stageVariant(tester), ThemeVariant.webLight);
    expect(_shellLabel(tester), 'Theme: Web Light');

    await _pickOnPage(tester, 'Web Dark');

    expect(_stageVariant(tester), ThemeVariant.webDark);
    expect(_pageLabel(tester), 'Web Dark');
    // The whole point: the bar at the top of the window did not move.
    expect(_shellLabel(tester), 'Theme: Web Light');
  });

  testWidgets('the override does not survive navigation', (
    WidgetTester tester,
  ) async {
    await _boot(tester);
    await _go(tester, pageA.id);
    await _pickOnPage(tester, 'Web Dark');
    expect(_stageVariant(tester), ThemeVariant.webDark);

    await _go(tester, pageB.id);

    expect(_stageVariant(tester), ThemeVariant.webLight);
    expect(_pageLabel(tester), 'Web Light');

    // And going back does not resurrect it either — the state was disposed,
    // not stashed.
    await _go(tester, pageA.id);
    expect(_stageVariant(tester), ThemeVariant.webLight);
  });

  testWidgets('the shell Theme menu outranks an active page override', (
    WidgetTester tester,
  ) async {
    await _boot(tester);
    await _go(tester, pageA.id);
    await _pickOnPage(tester, 'Web Dark');
    expect(_stageVariant(tester), ThemeVariant.webDark);

    await _pickOnShell(tester, 'Teams Light');

    expect(_stageVariant(tester), ThemeVariant.teamsLight);
    expect(_pageLabel(tester), 'Teams Light');
    expect(_shellLabel(tester), 'Theme: Teams Light');
  });
}

Future<void> _boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const ShowroomApp());
  // FluentApp renders SizedBox.shrink() until its web-font future resolves, so
  // a bare pump() would assert against an empty tree.
  await tester.pumpAndSettle();
}

/// Navigates the way the sidebar does, without hunting for its row.
Future<void> _go(WidgetTester tester, String pageId) async {
  DocsRouterScope.of(
    tester.element(find.byType(DocsScaffold)),
  ).go(DocsRoute.docs(pageId));
  await tester.pumpAndSettle();
}

/// The theme the page's first preview actually renders in.
ThemeVariant _stageVariant(WidgetTester tester) {
  final FluentThemeData data = tester
      .widget<FluentTheme>(
        find
            .descendant(
              of: find.byType(PreviewCard),
              matching: find.byType(FluentTheme),
            )
            .first,
      )
      .data;
  // Compare rendered colours rather than identity: `variant.data` builds a new
  // FluentThemeData on every read, by design.
  return ThemeVariant.values.firstWhere(
    (ThemeVariant v) =>
        v.data.colors.neutralBackground1 == data.colors.neutralBackground1 &&
        v.data.colors.brandBackground == data.colors.brandBackground,
  );
}

/// The docs toolbar dropdown's trigger text.
String _pageLabel(WidgetTester tester) => tester
    .widget<FluentDropdown<ThemeVariant>>(
      find.byType(FluentDropdown<ThemeVariant>),
    )
    .value!
    .label;

/// The shell toolbar's "Theme: …" button text.
String _shellLabel(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((Text t) => t.data)
    .whereType<String>()
    .firstWhere((String s) => s.startsWith('Theme: '));

Future<void> _pickOnPage(WidgetTester tester, String label) async {
  await tester.tap(find.byType(FluentDropdown<ThemeVariant>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _pickOnShell(WidgetTester tester, String label) async {
  await tester.tap(find.text(_shellLabel(tester)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}
