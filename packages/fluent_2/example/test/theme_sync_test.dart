import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/pages.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:fluent_2_example/shell/router.dart';
import 'package:fluent_2_example/shell/rtl_scope.dart';
import 'package:fluent_2_example/shell/showroom_app.dart';
import 'package:fluent_2_example/shell/theme_variants.dart';
import 'package:fluent_2_example/shell/widgets/docs_scaffold.dart';
import 'package:fluent_2_example/shell/widgets/docs_toolbar.dart';
import 'package:fluent_2_example/shell/widgets/preview_card.dart';
import 'package:fluent_2_example/shell/widgets/toolbar_parts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mouse.dart';

/// The docs page's Theme dropdown and RTL switch drive the SAME state as the
/// shell toolbar's Theme and Direction controls, and it outlives the page.
///
/// That is upstream's behaviour: the in-page ThemePicker and DirSwitch write
/// the `storybook_fluentui-react-addon_theme` / `_dir` globals the toolbar
/// reads, both ways, and sidebar navigation keeps them (fidelity critic,
/// `misc-results.json` `sync.inpageTheme`, `sync.inpageDir`;
/// `_tbfix_fc_nav.mjs`). Every interaction is a real mouse click.
void main() {
  // The two cheapest pages that actually carry stories — a page with no
  // sections renders no docs toolbar at all.
  final List<DocsPage> withStories =
      allPages.where((DocsPage p) => p.sections.isNotEmpty).toList()..sort(
        (DocsPage a, DocsPage b) =>
            a.sections.length.compareTo(b.sections.length),
      );
  final DocsPage pageA = withStories[0];
  final DocsPage pageB = withStories[1];

  testWidgets('the page dropdown drives the shell Theme label', (
    WidgetTester tester,
  ) async {
    await _boot(tester);
    await _go(tester, pageA.id);
    expect(_shellTheme(tester), 'Theme: Web Light');

    await mouseClick(tester, find.byType(FluentDropdown<ThemeVariant>));
    // Upstream's in-page list has no "(Default)"; only the toolbar menu does.
    expect(find.text('Web Light (Default)'), findsNothing);
    await mouseClick(tester, find.text('Web Dark').last);

    expect(_stageVariant(tester), ThemeVariant.webDark);
    expect(_pageTheme(tester), ThemeVariant.webDark);
    expect(_shellTheme(tester), 'Theme: Web Dark');
  });

  testWidgets('the shell Theme menu drives the page dropdown', (
    WidgetTester tester,
  ) async {
    await _boot(tester);
    await _go(tester, pageA.id);

    await _pickOnShell(tester, 'Teams Light');

    expect(_stageVariant(tester), ThemeVariant.teamsLight);
    expect(_pageTheme(tester), ThemeVariant.teamsLight);
    expect(_shellTheme(tester), 'Theme: Teams Light');
  });

  testWidgets('the page RTL switch and the shell Direction control agree', (
    WidgetTester tester,
  ) async {
    await _boot(tester);
    await _go(tester, pageA.id);
    expect(_pageRtl(tester), isFalse);
    expect(find.text('Direction: LTR'), findsOneWidget);

    await mouseClick(tester, _rtlSwitch);
    expect(_stageDirection(tester), TextDirection.rtl);
    expect(find.text('Direction: RTL'), findsOneWidget);

    await mouseClick(tester, _control('Change Direction'));
    expect(_stageDirection(tester), TextDirection.ltr);
    expect(_pageRtl(tester), isFalse);
    expect(find.text('Direction: LTR'), findsOneWidget);

    await mouseClick(tester, _control('Change Direction'));
    expect(_stageDirection(tester), TextDirection.rtl);
    expect(_pageRtl(tester), isTrue);
  });

  testWidgets('theme and direction survive navigation, both ways', (
    WidgetTester tester,
  ) async {
    await _boot(tester);
    await _go(tester, pageA.id);
    await mouseClick(tester, find.byType(FluentDropdown<ThemeVariant>));
    await mouseClick(tester, find.text('Web Dark').last);
    await mouseClick(tester, _rtlSwitch);

    await _go(tester, pageB.id);

    expect(_stageVariant(tester), ThemeVariant.webDark);
    expect(_stageDirection(tester), TextDirection.rtl);
    expect(_pageTheme(tester), ThemeVariant.webDark);
    expect(_pageRtl(tester), isTrue);
    expect(_shellTheme(tester), 'Theme: Web Dark');
    expect(find.text('Direction: RTL'), findsOneWidget);

    await _go(tester, pageA.id);
    expect(_stageVariant(tester), ThemeVariant.webDark);
    expect(_stageDirection(tester), TextDirection.rtl);
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

final Finder _rtlSwitch = find.descendant(
  of: find.byType(DocsToolbar),
  matching: find.byType(FluentSwitch),
);

Finder _control(String tooltip) => find.byWidgetPredicate(
  (Widget w) => w is ToolbarButton && w.tooltip == tooltip,
);

Future<void> _pickOnShell(WidgetTester tester, String label) async {
  await mouseClick(tester, _control('Change Fluent theme'));
  // `.last`: the menu is an overlay entry above the page, so it comes last in
  // tree order.
  await mouseClick(tester, find.text(label).last);
}

/// The shell Theme control's "Theme: …" text.
String _shellTheme(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: _control('Change Fluent theme'),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// The docs toolbar dropdown's value.
ThemeVariant _pageTheme(WidgetTester tester) => tester
    .widget<FluentDropdown<ThemeVariant>>(
      find.byType(FluentDropdown<ThemeVariant>),
    )
    .value!;

bool _pageRtl(WidgetTester tester) =>
    tester.widget<FluentSwitch>(_rtlSwitch).checked;

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

/// The direction the page's first preview actually renders in.
TextDirection _stageDirection(WidgetTester tester) => tester
    .widget<RtlScope>(
      find
          .descendant(
            of: find.byType(PreviewCard),
            matching: find.byType(RtlScope),
          )
          .first,
    )
    .textDirection;
