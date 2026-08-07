import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// Pinned against the five Figma fixtures extracted from the `Nav` page
/// (`8995:5`): `nav_node` (`NavNode - medium`, 15 variants), `nav_node_small`
/// (`NavNode - small`, 15), `nav_sub_item` (`NavSubItem`, 6), `nav_app_item`
/// (`App item - medium`, 3) and `nav_app_item_small` (`App item - small`, 3).
///
/// Figma's rows are 260 wide with placeholder labels, so every test pins the
/// width and asserts height and insets rather than the hug-content width.
void main() {
  const navWidth = 260.0;

  final node = loadSpec('nav_node');
  final nodeSmall = loadSpec('nav_node_small');
  final subItem = loadSpec('nav_sub_item');
  final appItem = loadSpec('nav_app_item');
  final appItemSmall = loadSpec('nav_app_item_small');

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    bool reducedMotion = false,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      FluentApp(
        theme:
            theme ??
            FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        builder: (context, inner) => Directionality(
          textDirection: textDirection,
          child: reducedMotion
              ? MediaQuery(
                  data: const MediaQueryData(disableAnimations: true),
                  child: inner!,
                )
              : inner!,
        ),
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: navWidth, child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Every [DecoratedBox] under [of], in tree order.
  Iterable<DecoratedBox> boxes(WidgetTester tester, Finder of) =>
      tester.widgetList<DecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      );

  /// The inner `Button` box — the one wrapping the row's content.
  BoxDecoration surface(WidgetTester tester, Finder of) =>
      boxes(tester, of).firstWhere((b) => b.child is ConstrainedBox).decoration
          as BoxDecoration;

  /// The selection indicator, or null when the row is not painting one.
  BoxDecoration? indicator(WidgetTester tester, Finder of) {
    for (final box in boxes(tester, of)) {
      if (box.child == null) return box.decoration as BoxDecoration;
    }
    return null;
  }

  Finder surfaceFinder(Finder of) =>
      find.descendant(of: of, matching: find.byType(ConstrainedBox)).first;

  EdgeInsets outerPadding(WidgetTester tester, Finder of) => tester
      .widget<Padding>(
        find.descendant(of: of, matching: find.byType(Padding)).first,
      )
      .padding
      .resolve(TextDirection.ltr);

  EdgeInsets innerPadding(WidgetTester tester, Finder of) => tester
      .widget<Padding>(
        find
            .descendant(of: surfaceFinder(of), matching: find.byType(Padding))
            .first,
      )
      .padding
      .resolve(TextDirection.ltr);

  /// The style the *label* painted with.
  ///
  /// Scoped to the label's own [Text] rather than to the row: an icon is a
  /// glyph in a RichText too, and its "font size" is the icon size, so the
  /// first RichText under a row with a leading icon is 20, never 14.
  TextStyle labelStyle(WidgetTester tester, String label) =>
      resolvedTextStyleOf(tester, of: find.text(label));

  /// Asserts one row against its Figma variant: the outer frame's height and
  /// padding, then the inner `Button` part's size, padding, radius and fill,
  /// then the label ramp.
  ///
  /// [height] is passed in rather than read off the variant, and it is the one
  /// number here the fixture no longer owns. `resolveFluentNavItemStyle` now
  /// takes its row heights from `@fluentui/react-nav` 9.4.3, not from Figma —
  /// see the policy note on that function for why the port reversed. Everything
  /// else this helper checks is still the fixture's.
  ///
  /// Every call site states its own number so the two authorities stay legible
  /// side by side: a call passing `variant.size.height` is a row where React and
  /// Figma happen to agree *as rendered*, and a call passing a literal is one
  /// where they do not.
  ///
  /// [buttonPadding] is the same escape hatch for the inner `Button` frame's
  /// insets, and only the category kind needs it. That row is the one whose
  /// height is *made* of its vertical padding rather than floored by the
  /// `height` literal, so taking React's height there means taking React's
  /// padding — the two are the same number twice. Leave it null and the
  /// fixture's own insets are asserted, which is still every other kind.
  void expectRow(
    WidgetTester tester,
    Finder of,
    SpecVariant variant, {
    required String label,
    required double height,
    EdgeInsets? buttonPadding,
    bool radius = true,
  }) {
    final size = tester.getSize(of);
    expect(size.height, height, reason: '${variant.name}: height');
    expect(
      outerPadding(tester, of),
      variant.padding,
      reason: '${variant.name}: outer padding',
    );

    final button = variant.part('Button');
    final surfaceSize = tester.getSize(surfaceFinder(of));
    // The outer padding is horizontal on every kind, so the Button box is
    // exactly as tall as the row — asserted against the same number rather than
    // the fixture's, for the same reason.
    expect(
      surfaceSize.height,
      height,
      reason: '${variant.name}: Button height',
    );
    expect(
      surfaceSize.width,
      button.size.width,
      reason: '${variant.name}: Button width',
    );
    expect(
      innerPadding(tester, of),
      buttonPadding ?? button.padding,
      reason: '${variant.name}: Button padding',
    );
    final decoration = surface(tester, of);
    if (radius) {
      expect(
        decoration.borderRadius?.resolve(TextDirection.ltr),
        button.radius,
        reason: '${variant.name}: Button radius',
      );
    }
    expect(
      decoration.color?.toARGB32(),
      button.fill?.toARGB32(),
      reason: '${variant.name}: Button fill (${button.token('fills')})',
    );

    final text = variant.text!;
    final style = labelStyle(tester, label);
    expect(style.fontSize, text.fontSize, reason: '${variant.name}: fontSize');
    expect(
      style.height! * style.fontSize!,
      text.lineHeight,
      reason: '${variant.name}: lineHeight',
    );
  }

  /// Drives the row into [state], which is one of Figma's three.
  Future<void> enter(WidgetTester tester, Finder of, String state) async {
    if (state == 'Rest') return;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(of));
    await tester.pumpAndSettle();
    if (state == 'Pressed') {
      await gesture.down(tester.getCenter(of));
      await tester.pumpAndSettle();
      addTearDown(() async => gesture.up());
    }
  }

  Widget nav({
    required List<Widget> children,
    FluentNavSize size = FluentNavSize.medium,
    Object? selected,
    Set<Object> open = const <Object>{},
    String? semanticLabel,
  }) => FluentNav(
    size: size,
    selectedValue: selected,
    openCategories: open,
    semanticLabel: semanticLabel,
    children: children,
  );

  group('nav_node — medium', () {
    for (final selected in <bool>[true, false]) {
      for (final state in <String>['Rest', 'Hover', 'Pressed']) {
        testWidgets('category Selected=$selected State=$state', (tester) async {
          final variant = node.variant(<String, String>{
            'Group': 'True',
            'Selected': '$selected'.replaceRange(0, 1, selected ? 'T' : 'F'),
            'State': state,
            'Open': 'False',
            'Secondary actions': 'False',
          });
          await pump(
            tester,
            nav(
              selected: selected ? 'cat' : null,
              children: const <Widget>[
                FluentNavCategory(
                  value: 'cat',
                  icon: Icon(FluentIcons.folder_20_regular),
                  child: Text('Group'),
                  children: <Widget>[
                    FluentNavSubItem(value: 'sub', child: Text('Sub')),
                  ],
                ),
              ],
            ),
          );
          final finder = find.byType(FluentNavCategory);
          await enter(tester, finder, state);
          // 32, from `useNavCategoryItemStyles.styles.ts`.
          //
          // This was pinned at 40 until 2026-08-07, with a comment explaining
          // why: the height literal is only a `minimumSize` FLOOR, and Figma's
          // `Vertical/MNudge` (10) padding around a 20 line already measured
          // 40, so the floor never bound and the React number sat inert. The
          // padding now moves with it — `Vertical/SNudge` (6), so
          // 20 + 2x6 = 32 — and the row finally measures what the style asks.
          //
          // Evidence the two must move together: changing the height alone
          // failed ZERO tests; adding the padding change failed 17 goldens and
          // 11 assertions here.
          expectRow(
            tester,
            finder,
            variant,
            label: 'Group',
            height: 32,
            // The same 32, stated the other way round — this IS the height.
            // Only the vertical arms move (Figma drew 10/10, React's
            // `Vertical/SNudge` is 6); left 10 and right 8 are horizontal, so
            // both authorities still agree and both stay the fixture's.
            buttonPadding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          );
        });
      }
    }

    for (final selected in <bool>[true, false]) {
      for (final state in <String>['Rest', 'Hover', 'Pressed']) {
        // `Secondary actions` and `Selected` are not independent in this set:
        // Figma only drew the unselected leaf without actions in Rest.
        final actions = selected || state != 'Rest' ? 'True' : 'False';
        testWidgets('item Selected=$selected State=$state', (tester) async {
          final variant = node.variant(<String, String>{
            'Group': 'False',
            'Selected': selected ? 'True' : 'False',
            'State': state,
            'Open': 'False',
            'Secondary actions': actions,
          });
          await pump(
            tester,
            nav(
              selected: selected ? 'home' : null,
              children: <Widget>[
                FluentNavItem(
                  value: 'home',
                  icon: const Icon(FluentIcons.home_20_regular),
                  secondaryActions: actions == 'True'
                      ? <Widget>[
                          FluentButton.icon(
                            icon: const Icon(
                              FluentIcons.more_horizontal_20_regular,
                            ),
                            semanticLabel: 'More',
                            size: FluentButtonSize.small,
                            appearance: FluentButtonAppearance.transparent,
                            onPressed: () {},
                          ),
                        ]
                      : const <Widget>[],
                  child: const Text('Home'),
                ),
              ],
            ),
          );
          final finder = find.byType(FluentNavItem);
          await enter(tester, finder, state);
          // 40 in Figma, 32 in React (`useNavItemStyles.styles.ts`). A leaf
          // carries no vertical padding, so the floor is the whole height and
          // the reversal lands: this row really did shrink by 8.
          expectRow(tester, finder, variant, label: 'Home', height: 32);
        });
      }
    }

    testWidgets('Open=True stacks ten sub-items under the header', (
      tester,
    ) async {
      await pump(
        tester,
        nav(
          open: const <Object>{'cat'},
          children: <Widget>[
            FluentNavCategory(
              value: 'cat',
              icon: const Icon(FluentIcons.folder_20_regular),
              child: const Text('Group'),
              children: <Widget>[
                for (var i = 0; i < 10; i++)
                  FluentNavSubItem(value: 'sub$i', child: Text('Sub $i')),
              ],
            ),
          ],
        ),
      );
      // No longer read off the fixture — it was `variant.size.height` from
      // `Group=True, Open=True, State=Rest`, whose frame is 380 because Figma
      // drew the header 40 high. The header is 32 now and nothing else in the
      // stack moved: a medium sub-item was already 32 at both authorities.
      //
      //   32 header + 2 gap + 10 x 32 sub-item + 9 x 2 between = 372
      //
      // The gap is `FluentSpacing.xxs`, which is Figma's own 2.
      expect(
        tester.getSize(find.byType(FluentNavCategory)).height,
        372,
        reason: 'header 32 + 2 gap + ten 32-high rows with 2 between them',
      );
      expect(find.byType(FluentNavSubItem), findsNWidgets(10));
    });
  });

  group('nav_node_small — the size axis', () {
    for (final group in <String>['True', 'False']) {
      // Was "rows are 32 high" for both, and briefly 32/28 while the category
      // still carried Figma's `Vertical/SNudge` (6) around a 20 line. Both
      // arms are 28 now: the leaf off React's floor, the category off React's
      // `Vertical/XS` (4), 20 + 2x4 = 28. One number again, the other one.
      testWidgets('Group=$group', (tester) async {
        final variant = nodeSmall.variant(<String, String>{
          'Group': group,
          'Selected': 'False',
          'State': 'Rest',
          'Open': 'False',
          'Secondary actions': 'False',
        });
        await pump(
          tester,
          nav(
            size: FluentNavSize.small,
            children: <Widget>[
              if (group == 'True')
                const FluentNavCategory(
                  value: 'cat',
                  icon: Icon(FluentIcons.folder_20_regular),
                  child: Text('Group'),
                  children: <Widget>[],
                )
              else
                const FluentNavItem(
                  value: 'home',
                  icon: Icon(FluentIcons.home_20_regular),
                  child: Text('Home'),
                ),
            ],
          ),
        );
        final finder = group == 'True'
            ? find.byType(FluentNavCategory)
            : find.byType(FluentNavItem);
        expectRow(
          tester,
          finder,
          variant,
          label: group == 'True' ? 'Group' : 'Home',
          height: 28,
          // Only the category's insets left the fixture, and only vertically:
          // Figma drew 6/6, React's small arm is 4, and 20 + 2x4 is the 28
          // above. The leaf has no vertical padding to disagree about.
          buttonPadding: group == 'True'
              ? const EdgeInsets.fromLTRB(10, 4, 8, 4)
              : null,
        );
      });
    }

    // No longer read off the fixture. Figma's small `Open=True, Hover` frame is
    // 372 — a 32 header, the 2 gap, and ten 32-high sub-items with 2 between
    // them. (Its `Rest` sibling is 338, the same stack with the header missing;
    // that frame lost its header in Figma, which is why Hover was the one
    // asserted.) React's small sub-item is 28 and its small category is 28 too,
    // so every row in the stack is now the same height:
    //
    //   28 header + 2 gap + 10 x 28 sub-item + 9 x 2 between = 328
    //
    // The header moved with the rest this time. It sat at 32 for one commit,
    // while the height literal said 28 and Figma's `Vertical/SNudge` (6) padding
    // still decided the row — a floor cannot shrink content that already clears
    // it. `Vertical/XS` (4) is what makes the 28 real.
    testWidgets('the open group stacks under a 28-high header', (tester) async {
      await pump(
        tester,
        nav(
          size: FluentNavSize.small,
          open: const <Object>{'cat'},
          children: <Widget>[
            FluentNavCategory(
              value: 'cat',
              child: const Text('Group'),
              children: <Widget>[
                for (var i = 0; i < 10; i++)
                  FluentNavSubItem(value: 'sub$i', child: Text('Sub $i')),
              ],
            ),
          ],
        ),
      );
      expect(
        tester.getSize(find.byType(FluentNavCategory)).height,
        328,
        reason: '28 header + 2 gap + ten 28-high rows with 2 between them',
      );
    });
  });

  group('nav_sub_item', () {
    for (final selected in <bool>[false, true]) {
      for (final state in <String>['Rest', 'Hover', 'Pressed']) {
        final actions = state == 'Rest' ? 'False' : 'True';
        testWidgets('Selected=$selected State=$state', (tester) async {
          final variant = subItem.variant(<String, String>{
            'Selected': selected ? 'True' : 'False',
            'State': state,
            'Secondary actions': actions,
          });
          await pump(
            tester,
            nav(
              selected: selected ? 'sub' : null,
              open: const <Object>{'cat'},
              children: <Widget>[
                FluentNavCategory(
                  value: 'cat',
                  child: const Text('Group'),
                  children: <Widget>[
                    FluentNavSubItem(
                      value: 'sub',
                      secondaryActions: actions == 'True'
                          ? <Widget>[
                              FluentButton.icon(
                                icon: const Icon(
                                  FluentIcons.more_horizontal_20_regular,
                                ),
                                semanticLabel: 'More',
                                size: FluentButtonSize.small,
                                appearance: FluentButtonAppearance.transparent,
                                onPressed: () {},
                              ),
                            ]
                          : const <Widget>[],
                      child: const Text('Sub'),
                    ),
                  ],
                ),
              ],
            ),
          );
          final finder = find.byType(FluentNavSubItem);
          await enter(tester, finder, state);
          expectRow(
            tester,
            finder,
            variant,
            label: 'Sub',
            // Figma and React agree at medium — both 32 — so the reversal is
            // invisible in this set. It shows at small, where React drops to 28
            // and this arm used to have no `small` branch at all; that is
            // covered by the open-group total above.
            height: 32,
            // The two `State=Rest` sub-item variants carry `Corner radius/None`
            // where all four Hover and Pressed ones carry `Corner radius/40`
            // (4) — and every NavNode variant, Rest included, carries 4. Four
            // of six plus the whole sibling set win; a rest row that squared
            // its corners and rounded them on hover would be a bug, not a spec.
            radius: state != 'Rest',
          );
        });
      }
    }

    testWidgets('is indented 46 so its label lines up with the category', (
      tester,
    ) async {
      final variant = subItem.variant(<String, String>{
        'Selected': 'False',
        'State': 'Rest',
        'Secondary actions': 'False',
      });
      expect(variant.part('Button').padding!.left, 46);
    });
  });

  group('nav_app_item', () {
    // Figma's Rest variant carries stale insets — `Vertical/M` (12) and a
    // `Horizontal/SNudge` (6) gap where Hover and Pressed both say
    // `Vertical/S` (8) and `Horizontal/S` (8). Two variants out of three win,
    // and the frame is 48 either way, so only Rest's fill and height are
    // asserted here.
    //
    // React's app item is 38 at both densities and `resolveFluentNavItemStyle`
    // now asks for that, but 38 is a floor and these variants overshoot it on
    // content: Figma's `Vertical/S` (8) twice around a 32 icon is 48 exactly.
    // The heights below are therefore still Figma's, and they are literals now
    // rather than `variant.size.height` so that reading them does not imply the
    // fixture is the authority.
    for (final state in <String>['Hover', 'Pressed']) {
      testWidgets('medium State=$state', (tester) async {
        final variant = appItem.variant(<String, String>{'State': state});
        await pump(
          tester,
          nav(
            children: <Widget>[
              FluentNavAppItem(
                icon: const Icon(FluentIcons.person_circle_32_regular),
                onPressed: () {},
                child: const Text('Contoso'),
              ),
            ],
          ),
        );
        final finder = find.byType(FluentNavAppItem);
        await enter(tester, finder, state);
        expect(tester.getSize(finder).height, 48);
        expect(innerPadding(tester, finder), variant.padding);
        expect(
          surface(tester, finder).color?.toARGB32(),
          variant.fill?.toARGB32(),
        );
        final style = labelStyle(tester, 'Contoso');
        expect(style.fontSize, variant.text!.fontSize);
        expect(style.height! * style.fontSize!, variant.text!.lineHeight);
      });
    }

    // The one app-item case where the React height actually binds, and the only
    // one in the file that changed: with no icon the content is a 22 line
    // between two `Vertical/S` (8) insets — 38 on its own — so the floor is
    // what sets the height, and the floor is now React's 38 instead of Figma's
    // 48. Figma has no icon-less app item variant to disagree with; its 48 is
    // measured with the 32 avatar in place.
    testWidgets('medium Rest paints the rest fill at 38 high with no icon', (
      tester,
    ) async {
      final variant = appItem.variant(<String, String>{'State': 'Rest'});
      await pump(
        tester,
        nav(
          children: <Widget>[
            FluentNavAppItem(onPressed: () {}, child: const Text('Contoso')),
          ],
        ),
      );
      final finder = find.byType(FluentNavAppItem);
      expect(tester.getSize(finder).height, 38);
      expect(
        surface(tester, finder).color?.toARGB32(),
        variant.fill?.toARGB32(),
      );
    });

    testWidgets('without onPressed it is static, not disabled', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        nav(children: const <Widget>[FluentNavAppItem(child: Text('Contoso'))]),
        theme: theme,
      );
      final finder = find.byType(FluentNavAppItem);
      expect(
        surface(tester, finder).color,
        theme.colors.neutralBackground4,
        reason: 'AppItemStatic paints the rest fill, not the disabled one',
      );
      expect(
        labelStyle(tester, 'Contoso').color,
        theme.colors.neutralForeground1,
      );
      expect(
        find.descendant(of: finder, matching: find.byType(FluentInteractive)),
        findsNothing,
        reason: 'nothing to invoke means nothing to focus or hover',
      );
    });

    // Still 40, not React's 38, for the same reason as medium: `Vertical/S` (8)
    // twice around the 24 icon is 40 on content alone, over the floor.
    testWidgets('small is 40 high on the same ramp', (tester) async {
      final variant = appItemSmall.variant(<String, String>{'State': 'Hover'});
      await pump(
        tester,
        nav(
          size: FluentNavSize.small,
          children: <Widget>[
            FluentNavAppItem(
              icon: const Icon(FluentIcons.person_circle_24_regular),
              onPressed: () {},
              child: const Text('Contoso'),
            ),
          ],
        ),
      );
      final finder = find.byType(FluentNavAppItem);
      await enter(tester, finder, 'Hover');
      expect(tester.getSize(finder).height, 40);
      expect(innerPadding(tester, finder), variant.padding);
      expect(
        surface(tester, finder).color?.toARGB32(),
        variant.fill?.toARGB32(),
      );
    });
  });

  group('selection indicator', () {
    testWidgets('paints the compound brand token only while selected', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final variant = node.variant(<String, String>{
        'Group': 'False',
        'Selected': 'True',
        'State': 'Rest',
        'Open': 'False',
        'Secondary actions': 'True',
      });
      final part = variant.part('Rectangle 3469503');

      await pump(
        tester,
        nav(
          selected: 'home',
          children: const <Widget>[
            FluentNavItem(value: 'home', child: Text('Home')),
            FluentNavItem(value: 'away', child: Text('Away')),
          ],
        ),
        theme: theme,
      );

      final selectedRow = find.byType(FluentNavItem).first;
      final other = find.byType(FluentNavItem).last;
      expect(
        indicator(tester, selectedRow)!.color,
        theme.colors.compoundBrandForeground1,
      );
      expect(
        indicator(tester, selectedRow)!.color!.toARGB32(),
        part.fill!.toARGB32(),
      );
      expect(
        indicator(tester, other)!.color!.a,
        0,
        reason:
            'an unselected row is the fade keyframe at its transparent end — '
            'a literal zero alpha, not a Fluent transparent token, which '
            'would turn opaque in high contrast',
      );
      expect(
        tester.getSize(selectedRow).width,
        tester.getSize(other).width,
        reason: 'the indicator column is reserved on every row',
      );
    });

    testWidgets('the indicator fades up rather than appearing', (tester) async {
      Widget tree(Object selected) => FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: navWidth,
            child: nav(
              selected: selected,
              children: const <Widget>[
                FluentNavItem(value: 'home', child: Text('Home')),
                FluentNavItem(value: 'away', child: Text('Away')),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(tree('home'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(tree('away'));

      // Half way into the 100ms ramp both bars must be mid-flight: the
      // incoming one climbing, the outgoing one falling.
      await tester.pump(const Duration(milliseconds: 50));
      final incoming = indicator(tester, find.byType(FluentNavItem).last)!;
      final outgoing = indicator(tester, find.byType(FluentNavItem).first)!;
      expect(incoming.color!.a, greaterThan(0));
      expect(incoming.color!.a, lessThan(1));
      expect(outgoing.color!.a, greaterThan(0));
      expect(outgoing.color!.a, lessThan(1));

      await tester.pumpAndSettle();
      expect(indicator(tester, find.byType(FluentNavItem).last)!.color!.a, 1);
      expect(indicator(tester, find.byType(FluentNavItem).first)!.color!.a, 0);
    });

    testWidgets('reduced motion lands the indicator on the first frame', (
      tester,
    ) async {
      await pump(
        tester,
        nav(
          selected: 'home',
          children: const <Widget>[
            FluentNavItem(value: 'home', child: Text('Home')),
          ],
        ),
        reducedMotion: true,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(indicator(tester, find.byType(FluentNavItem))!.color!.a, 1);
    });
  });

  /// [NEW API], not a Figma variant: React's `useIconStyles` crossfades a
  /// selected row's icon to the filled glyph over `durationFaster`. Flutter
  /// cannot derive the filled variant from the regular one, so the slot is
  /// opt-in and null has to mean "exactly as before".
  group('selected icon', () {
    const regular = FluentIcons.home_20_regular;
    const filled = FluentIcons.home_20_filled;

    /// The opacity the crossfade is holding [icon] at.
    double opacityOf(WidgetTester tester, IconData icon) => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byIcon(icon),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    Widget tree({required Object? selected, Widget? selectedIcon}) => nav(
      selected: selected,
      children: <Widget>[
        FluentNavItem(
          value: 'home',
          icon: const Icon(regular),
          selectedIcon: selectedIcon,
          child: const Text('Home'),
        ),
      ],
    );

    testWidgets('null leaves the row exactly as it was', (tester) async {
      await pump(tester, tree(selected: 'home'));

      expect(find.byIcon(regular), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FluentNavItem),
          matching: find.byType(Opacity),
        ),
        findsNothing,
        reason: 'no crossfade is built at all when there is nothing to fade to',
      );
    });

    testWidgets('a selected row shows the filled glyph, and swaps back', (
      tester,
    ) async {
      await pump(
        tester,
        tree(selected: null, selectedIcon: const Icon(filled)),
      );
      expect(opacityOf(tester, regular), 1);
      expect(opacityOf(tester, filled), 0);

      await pump(
        tester,
        tree(selected: 'home', selectedIcon: const Icon(filled)),
      );
      expect(opacityOf(tester, regular), 0);
      expect(opacityOf(tester, filled), 1);

      await pump(
        tester,
        tree(selected: null, selectedIcon: const Icon(filled)),
      );
      expect(
        opacityOf(tester, regular),
        1,
        reason: 'deselecting fades back to the regular glyph',
      );
      expect(opacityOf(tester, filled), 0);
    });

    testWidgets('the glyphs crossfade rather than swap', (tester) async {
      Widget app(Object? selected) => FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: navWidth,
            child: tree(selected: selected, selectedIcon: const Icon(filled)),
          ),
        ),
      );

      await tester.pumpWidget(app(null));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app('home'));

      // Half way into the 100ms ramp both glyphs are on screen at once.
      await tester.pump(const Duration(milliseconds: 50));
      expect(opacityOf(tester, regular), greaterThan(0));
      expect(opacityOf(tester, regular), lessThan(1));
      expect(opacityOf(tester, filled), greaterThan(0));
      expect(opacityOf(tester, filled), lessThan(1));

      await tester.pumpAndSettle();
      expect(opacityOf(tester, filled), 1);
    });

    testWidgets('reduced motion lands the swap on the first frame', (
      tester,
    ) async {
      await pump(
        tester,
        tree(selected: 'home', selectedIcon: const Icon(filled)),
        reducedMotion: true,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(opacityOf(tester, filled), 1);
      expect(opacityOf(tester, regular), 0);
    });
  });

  group('composition', () {
    testWidgets('the divider is a real FluentDivider', (tester) async {
      await pump(
        tester,
        nav(
          children: const <Widget>[
            FluentNavItem(value: 'a', child: Text('A')),
            FluentNavDivider(),
            FluentNavItem(value: 'b', child: Text('B')),
          ],
        ),
      );
      expect(find.byType(FluentDivider), findsOneWidget);
    });

    testWidgets('secondary actions are real FluentButtons', (tester) async {
      await pump(
        tester,
        nav(
          children: <Widget>[
            FluentNavItem(
              value: 'a',
              secondaryActions: <Widget>[
                FluentButton.icon(
                  icon: const Icon(FluentIcons.more_horizontal_20_regular),
                  semanticLabel: 'More',
                  size: FluentButtonSize.small,
                  appearance: FluentButtonAppearance.transparent,
                  onPressed: () {},
                ),
              ],
              child: const Text('A'),
            ),
          ],
        ),
      );
      expect(find.byType(FluentButton), findsOneWidget);
    });

    testWidgets('the focus ring is drawn INSIDE the row, not around it', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        nav(
          children: const <Widget>[FluentNavItem(value: 'a', child: Text('A'))],
        ),
        theme: theme,
      );
      final row = find.byType(FluentNavItem);

      Border? ring() => boxes(tester, row)
          .where((b) => b.position == DecorationPosition.foreground)
          .map((b) => (b.decoration as BoxDecoration).border)
          .whereType<Border>()
          .firstOrNull;

      expect(ring(), isNull, reason: 'no ring until focus is keyboard-visible');
      final size = tester.getSize(row);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // React's nav row pulls its ring inward: `sharedNavStyles.styles.ts`
      // gives `&:focus-visible` `outline: strokeWidthThick solid
      // colorStrokeFocus2` with `outlineOffset: calc(strokeWidthThick * -1)`,
      // so the band sits at -2…0 on the row's own radius. An outward ring would
      // also bleed into the 2px gap between rows, which upstream's never does.
      expect(ring()?.top.color, theme.colors.strokeFocus2);
      expect(ring()?.top.width, FluentStroke.thick);
      expect(ring()?.top.strokeAlign, BorderSide.strokeAlignInside);
      expect(
        tester.getSize(row),
        size,
        reason: 'a foreground border consumes no layout',
      );
    });
  });

  group('motion', () {
    testWidgets('the surface fades over durationFaster', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        nav(
          children: const <Widget>[FluentNavItem(value: 'a', child: Text('A'))],
        ),
        theme: theme,
      );
      final finder = find.byType(FluentNavItem);
      expect(surface(tester, finder).color, theme.colors.neutralBackground4);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(finder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        surface(tester, finder).color,
        isNot(theme.colors.neutralBackground4Hover),
        reason: 'halfway through the 100ms fade, not there yet',
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        surface(tester, finder).color,
        theme.colors.neutralBackground4Hover,
      );
    });

    testWidgets('the chevron rotates half a turn over durationFast', (
      tester,
    ) async {
      var open = <Object>{};
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: navWidth,
              child: StatefulBuilder(
                builder: (context, setState) => FluentNav(
                  openCategories: open,
                  onOpenChange: (next) => setState(() => open = next),
                  children: const <Widget>[
                    FluentNavCategory(
                      value: 'cat',
                      child: Text('Group'),
                      children: <Widget>[
                        FluentNavSubItem(value: 'sub', child: Text('Sub')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      /// cos(angle) off the chevron's rotation matrix: 1 collapsed, -1 open.
      double cosAngle() => tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byType(FluentNavCategory),
              matching: find.byType(Transform),
            ),
          )
          .first
          .transform
          .getRotation()
          .getRow(0)
          .x;

      expect(cosAngle(), moreOrLessEquals(1), reason: 'collapsed is 0 degrees');

      await tester.tap(find.text('Group'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(
        cosAngle(),
        lessThan(0.99),
        reason: 'halfway through the 150ms rotation',
      );
      expect(cosAngle(), greaterThan(-0.99), reason: 'and not there yet');

      await tester.pumpAndSettle();
      expect(
        cosAngle(),
        moreOrLessEquals(-1),
        reason: 'open is half a turn — upstream Rotate inAngle: 180',
      );
    });

    testWidgets('reduced motion snaps the chevron to its target', (
      tester,
    ) async {
      var open = <Object>{};
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: navWidth,
              child: StatefulBuilder(
                builder: (context, setState) => FluentNav(
                  openCategories: open,
                  onOpenChange: (next) => setState(() => open = next),
                  children: const <Widget>[
                    FluentNavCategory(
                      value: 'cat',
                      child: Text('Group'),
                      children: <Widget>[
                        FluentNavSubItem(value: 'sub', child: Text('Sub')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group'));
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widgetList<Transform>(
              find.descendant(
                of: find.byType(FluentNavCategory),
                matching: find.byType(Transform),
              ),
            )
            .first
            .transform
            .getRotation()
            .getRow(0)
            .x,
        moreOrLessEquals(-1),
        reason: 'no tween: the chevron is already open on the next frame',
      );
      expect(
        tester.getSize(find.byType(FluentNavCategory)).height,
        // Medium: a 32 header (React's category padding, 20 + 2x6), the 2 gap,
        // and one 32-high sub-item. Was 40 + 2 + 32 while the header still
        // carried Figma's 10s.
        32 + 2 + 32,
        reason: 'and the group is already at full height',
      );
    });

    testWidgets('the chevron transition is 150ms, not the accordion 200', (
      tester,
    ) async {
      expect(fluentNavExpandIconMotion.duration, FluentDuration.fast);
      expect(fluentNavExpandIconMotion.curve, FluentCurve.easyEase);
      expect(fluentNavSurfaceMotion.duration, FluentDuration.faster);
      expect(
        fluentNavSurfaceMotion.curve,
        FluentCurve.linear,
        reason: 'sharedNavStyles uses curveLinear where Button uses easyEase',
      );
    });

    testWidgets('the group collapses over durationNormal and unmounts', (
      tester,
    ) async {
      // A NEW set each time, never the same instance mutated in place: the
      // scope compares open sets with setEquals, and an aliased set can never
      // differ from itself.
      var open = <Object>{};
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: navWidth,
              child: StatefulBuilder(
                builder: (context, setState) => FluentNav(
                  openCategories: open,
                  onOpenChange: (next) => setState(() => open = next),
                  children: const <Widget>[
                    FluentNavCategory(
                      value: 'cat',
                      child: Text('Group'),
                      children: <Widget>[
                        FluentNavSubItem(value: 'sub', child: Text('Sub')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(FluentNavSubItem),
        findsNothing,
        reason: 'unmountOnExit — a closed group is not built',
      );

      await tester.tap(find.text('Group'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getSize(find.byType(FluentNavCategory)).height;
      await tester.pumpAndSettle();
      final settled = tester.getSize(find.byType(FluentNavCategory)).height;
      expect(mid, lessThan(settled));
      // Same stack, same 32 header + 2 gap + 32 sub-item. The collapse extent
      // is derived from this, so it moved with the header.
      expect(settled, 32 + 2 + 32);
    });

    testWidgets('reduced motion lands on the target frame', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        nav(
          children: const <Widget>[FluentNavItem(value: 'a', child: Text('A'))],
        ),
        theme: theme,
        reducedMotion: true,
      );
      final finder = find.byType(FluentNavItem);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(finder));
      await tester.pump();
      expect(
        surface(tester, finder).color,
        theme.colors.neutralBackground4Hover,
        reason: 'one frame, no tween',
      );
    });
  });

  group('keyboard', () {
    testWidgets('Down moves focus to the next row', (tester) async {
      final first = FocusNode(debugLabel: 'first');
      addTearDown(first.dispose);
      await pump(
        tester,
        nav(
          children: <Widget>[
            FluentNavItem(
              value: 'a',
              focusNode: first,
              autofocus: true,
              child: const Text('A'),
            ),
            const FluentNavItem(value: 'b', child: Text('B')),
          ],
        ),
      );
      expect(first.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(first.hasFocus, isFalse);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<FluentNavItem>()
            ?.value,
        'b',
        reason: 'Down moves to the next row, not merely away from this one',
      );
    });

    testWidgets('Enter selects the focused row', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      Object? picked;
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: navWidth,
              child: FluentNav(
                onSelect: (value) => picked = value,
                children: <Widget>[
                  FluentNavItem(
                    value: 'a',
                    focusNode: focus,
                    autofocus: true,
                    child: const Text('A'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, 'a');
    });

    testWidgets('Right expands and Left collapses a category', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      // A NEW set each time, never the same instance mutated in place: the
      // scope compares open sets with setEquals, and an aliased set can never
      // differ from itself.
      var open = <Object>{};
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: navWidth,
              child: StatefulBuilder(
                builder: (context, setState) => FluentNav(
                  openCategories: open,
                  onOpenChange: (next) => setState(() => open = next),
                  children: <Widget>[
                    FluentNavCategory(
                      value: 'cat',
                      focusNode: focus,
                      autofocus: true,
                      child: const Text('Group'),
                      children: const <Widget>[
                        FluentNavSubItem(value: 'sub', child: Text('Sub')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(open, <Object>{'cat'});
      expect(find.byType(FluentNavSubItem), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(open, isEmpty);
      expect(find.byType(FluentNavSubItem), findsNothing);
    });

    testWidgets('the two arrows swap in a right-to-left nav', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      // A NEW set each time, never the same instance mutated in place: the
      // scope compares open sets with setEquals, and an aliased set can never
      // differ from itself.
      var open = <Object>{};
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: navWidth,
              child: StatefulBuilder(
                builder: (context, setState) => FluentNav(
                  openCategories: open,
                  onOpenChange: (next) => setState(() => open = next),
                  children: <Widget>[
                    FluentNavCategory(
                      value: 'cat',
                      focusNode: focus,
                      autofocus: true,
                      child: const Text('Group'),
                      children: const <Widget>[
                        FluentNavSubItem(value: 'sub', child: Text('Sub')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(open, <Object>{'cat'});
    });
  });

  group('keyboard — roving', () {
    // A node per row, because tapping a nav row does NOT focus it —
    // FluentInteractive drives selection off a bare GestureDetector — so every
    // arrow test seeds focus the way a caller would, through the row's own
    // node. That path is also the one the gate has to leave working.
    late Map<String, FocusNode> nodes;

    setUp(() {
      nodes = <String, FocusNode>{
        for (final value in <String>['a', 'b', 'c'])
          value: FocusNode(debugLabel: value),
      };
    });

    tearDown(() {
      for (final node in nodes.values) {
        node.dispose();
      }
    });

    Widget nav({bool tabbable = false}) => FluentNav(
      tabbable: tabbable,
      children: <Widget>[
        for (final value in <String>['a', 'b', 'c'])
          FluentNavItem(
            value: value,
            focusNode: nodes[value],
            child: Text(value.toUpperCase()),
          ),
      ],
    );

    Future<void> focusRow(WidgetTester tester, String value) async {
      nodes[value]!.requestFocus();
      await tester.pumpAndSettle();
    }

    /// What Tab can actually reach inside the nav.
    ///
    /// Read off the focus tree rather than counted off the gates: a gate is
    /// only a proxy for a tab stop, and `traversalDescendants` is the same set
    /// the traversal policy itself walks.
    int tabStops(WidgetTester tester) => Focus.of(
      tester.element(find.byType(FluentNavItem).first),
    ).traversalDescendants.length;

    String? focusedValue() =>
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<FluentNavItem>()
                ?.value
            as String?;

    testWidgets('the whole nav is one tab stop', (tester) async {
      await pump(tester, nav());

      expect(
        tabStops(tester),
        1,
        reason:
            'useNav.ts hardcodes tabbable: false, and tabster then leaves '
            'exactly one element of the Mover in the tab order',
      );
    });

    testWidgets('tabbable: true restores a stop per row', (tester) async {
      await pump(tester, nav(tabbable: true));

      expect(
        tabStops(tester),
        3,
        reason:
            'NavDrawer.types.ts: "Setting this to true enables tab AND arrow '
            'navigation"',
      );
    });

    testWidgets('the stop follows the arrows, and stays a single stop', (
      tester,
    ) async {
      await pump(tester, nav());
      await focusRow(tester, 'a');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(focusedValue(), 'b');
      expect(
        tabStops(tester),
        1,
        reason:
            'the stop moved with the arrow rather than being added to: a '
            'roving tabindex is one stop at every moment, not one more each '
            'time focus lands',
      );
    });

    testWidgets('Down wraps from the last row to the first', (tester) async {
      await pump(tester, nav());
      await focusRow(tester, 'c');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(
        focusedValue(),
        'a',
        reason:
            'useNavDrawerBody.ts passes circular: true, so the Mover cycles '
            'rather than stopping at the boundary',
      );
    });

    testWidgets('Up wraps from the first row to the last', (tester) async {
      await pump(tester, nav());
      await focusRow(tester, 'a');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(focusedValue(), 'c', reason: 'circular: true is symmetric');
    });

    testWidgets('Home and End reach the ends without wrapping', (tester) async {
      await pump(tester, nav());
      await focusRow(tester, 'b');

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      expect(
        focusedValue(),
        'c',
        reason: 'End is absolute — tabster does not consult isCyclic for it',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      expect(focusedValue(), 'a', reason: 'Home is absolute too');

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      expect(
        focusedValue(),
        'a',
        reason: 'and absolute means idempotent, never a wrap to the far end',
      );
    });

    testWidgets('a disabled row is skipped by the arrows', (tester) async {
      await pump(
        tester,
        FluentNav(
          children: <Widget>[
            FluentNavItem(
              value: 'a',
              focusNode: nodes['a'],
              child: const Text('A'),
            ),
            const FluentNavItem(value: 'b', enabled: false, child: Text('B')),
            const FluentNavItem(value: 'c', child: Text('C')),
          ],
        ),
      );
      await focusRow(tester, 'a');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(
        focusedValue(),
        'c',
        reason:
            'a disabled row has no focusable descendant, so it is skipped '
            'structurally rather than by being told to skip',
      );
    });

    testWidgets('a section header and a divider are not arrow targets', (
      tester,
    ) async {
      await pump(
        tester,
        FluentNav(
          children: <Widget>[
            const FluentNavSectionHeader(child: Text('Group')),
            FluentNavItem(
              value: 'a',
              focusNode: nodes['a'],
              child: const Text('A'),
            ),
            const FluentNavDivider(),
            const FluentNavItem(value: 'b', child: Text('B')),
          ],
        ),
      );
      await focusRow(tester, 'a');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(
        focusedValue(),
        'b',
        reason: 'neither goes through _FluentNavRow, so neither has a gate',
      );
    });

    testWidgets('End with a closed trailing category lands on the header', (
      tester,
    ) async {
      await pump(
        tester,
        FluentNav(
          children: <Widget>[
            FluentNavItem(
              value: 'a',
              focusNode: nodes['a'],
              child: const Text('A'),
            ),
            const FluentNavCategory(
              value: 'cat',
              child: Text('Reports'),
              children: <Widget>[
                FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
              ],
            ),
          ],
        ),
      );
      await focusRow(tester, 'a');

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      expect(
        find.text('Weekly'),
        findsNothing,
        reason: 'a closed category does not build its sub-items at all',
      );
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<FluentNavCategory>(),
        isNotNull,
        reason:
            'the row list is derived live from the focus tree, so an unbuilt '
            'sub-item is not a candidate',
      );
    });

    testWidgets('a nav whose only row is disabled has no tab stop', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentNav(
          children: <Widget>[
            FluentNavItem(value: 'a', enabled: false, child: Text('A')),
          ],
        ),
      );

      expect(
        tabStops(tester),
        0,
        reason:
            'zero focusable rows means zero tab stops, not one forced onto an '
            'unfocusable row',
      );
    });

    testWidgets('an explicit requestFocus still works on a gated row', (
      tester,
    ) async {
      await pump(tester, nav());
      await focusRow(tester, 'c');

      expect(
        focusedValue(),
        'c',
        reason:
            'the gate hides a row from TRAVERSAL only; the framework promises '
            'a skipped node may still be focused explicitly, which is what '
            "keeps autofocus: and a caller's own node working",
      );
      expect(
        tabStops(tester),
        1,
        reason: 'and the stop follows it, so Tab re-enters where focus left',
      );
    });

    testWidgets('focus survives the category holding it closing', (
      tester,
    ) async {
      final weekly = FocusNode(debugLabel: 'weekly');
      addTearDown(weekly.dispose);
      var open = <Object>{'cat'};
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: navWidth,
              child: StatefulBuilder(
                builder: (context, setState) => FluentNav(
                  openCategories: open,
                  onOpenChange: (next) => setState(() => open = next),
                  children: <Widget>[
                    const FluentNavItem(value: 'a', child: Text('A')),
                    FluentNavCategory(
                      value: 'cat',
                      child: const Text('Reports'),
                      children: <Widget>[
                        FluentNavSubItem(
                          value: 'weekly',
                          focusNode: weekly,
                          child: const Text('Weekly'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      weekly.requestFocus();
      await tester.pumpAndSettle();

      // Close the category from its header, with focus still on the sub-item.
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      expect(
        find.text('Weekly'),
        findsNothing,
        reason: 'a closed category unmounts its sub-items',
      );
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<FluentNav>(),
        isNotNull,
        reason:
            'there is no FocusScope inside the nav, so without a rescue the '
            'disposed node hands focus to the route and it leaves the nav '
            'entirely',
      );
    });
  });

  group('disabled', () {
    testWidgets('is a real state, not a paint', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      var taps = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await pump(
        tester,
        nav(
          children: <Widget>[
            FluentNavItem(
              value: 'a',
              enabled: false,
              focusNode: focus,
              onPressed: () => taps++,
              child: const Text('A'),
            ),
          ],
        ),
        theme: theme,
      );
      final finder = find.byType(FluentNavItem);
      expect(
        surface(tester, finder).color,
        theme.colors.neutralBackgroundDisabled,
      );
      expect(
        labelStyle(tester, 'A').color,
        theme.colors.neutralForegroundDisabled,
      );

      await tester.tap(finder, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);

      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isFalse, reason: 'a disabled row refuses focus');

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(finder));
      await tester.pumpAndSettle();
      expect(
        surface(tester, finder).color,
        theme.colors.neutralBackgroundDisabled,
        reason: 'a disabled row does not report hover',
      );
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the row', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralForeground2: magenta},
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: navWidth,
                child: nav(
                  children: const <Widget>[
                    FluentNavItem(value: 'a', child: Text('A')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(labelStyle(tester, 'A').color, magenta);
    });

    testWidgets('FluentNavItemTheme restyles a subtree', (tester) async {
      const teal = Color(0xFF006D6D);
      await pump(
        tester,
        FluentNavItemTheme(
          style: FluentNavItemStyle.from(backgroundColor: teal),
          child: nav(
            children: const <Widget>[
              FluentNavItem(value: 'a', child: Text('A')),
            ],
          ),
        ),
      );
      expect(surface(tester, find.byType(FluentNavItem)).color, teal);
    });

    testWidgets('the widget style wins over the subtree theme', (tester) async {
      const teal = Color(0xFF006D6D);
      const plum = Color(0xFF77004D);
      await pump(
        tester,
        FluentNavItemTheme(
          style: FluentNavItemStyle.from(backgroundColor: teal),
          child: nav(
            children: <Widget>[
              FluentNavItem(
                value: 'a',
                style: FluentNavItemStyle.from(backgroundColor: plum),
                child: const Text('A'),
              ),
            ],
          ),
        ),
      );
      expect(surface(tester, find.byType(FluentNavItem)).color, plum);
    });

    testWidgets('high contrast leaves no foreground on its own background', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        nav(
          selected: 'a',
          open: const <Object>{'cat'},
          children: <Widget>[
            FluentNavAppItem(onPressed: () {}, child: const Text('Contoso')),
            const FluentNavItem(
              value: 'a',
              icon: Icon(FluentIcons.home_20_regular),
              child: Text('A'),
            ),
            const FluentNavCategory(
              value: 'cat',
              icon: Icon(FluentIcons.folder_20_regular),
              child: Text('Group'),
              children: <Widget>[
                FluentNavSubItem(value: 'sub', child: Text('Sub')),
              ],
            ),
          ],
        ),
        theme: theme,
      );

      const rows = <String, String>{
        'Contoso': 'app item',
        'A': 'item',
        'Group': 'category',
        'Sub': 'sub-item',
      };
      for (final entry in rows.entries) {
        final finder = find.ancestor(
          of: find.text(entry.key),
          matching: find.byType(FluentInteractive),
        );
        final background = surface(tester, finder).color!;
        final foreground = labelStyle(tester, entry.key).color!;
        expect(
          background.a,
          1.0,
          reason: 'the ${entry.value} background must be opaque',
        );
        expect(
          foreground.toARGB32(),
          isNot(background.toARGB32()),
          reason: 'the ${entry.value} paints its label into its own surface',
        );
      }

      final indicatorColor = indicator(
        tester,
        find.byType(FluentNavItem),
      )!.color!;
      expect(
        indicatorColor.toARGB32(),
        isNot(surface(tester, find.byType(FluentNavItem)).color!.toARGB32()),
        reason: 'the selection indicator must read against the row it marks',
      );
    });
  });

  group('theming — per kind', () {
    testWidgets('a category slot reaches headers and leaves items alone', (
      tester,
    ) async {
      await pump(
        tester,
        FluentNavItemTheme(
          categoryStyle: FluentNavItemStyle.from(
            backgroundColor: const Color(0xFF00FF00),
          ),
          child: const FluentNav(
            defaultOpenCategories: <Object>{'cat'},
            children: <Widget>[
              FluentNavItem(value: 'home', child: Text('Home')),
              FluentNavCategory(
                value: 'cat',
                child: Text('Reports'),
                children: <Widget>[
                  FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
                ],
              ),
            ],
          ),
        ),
      );

      expect(
        surface(tester, find.byType(FluentNavCategory)).color?.toARGB32(),
        const Color(0xFF00FF00).toARGB32(),
        reason: 'categoryStyle applies to FluentNavItemKind.category',
      );
      expect(
        surface(tester, find.byType(FluentNavItem)).color?.toARGB32(),
        isNot(const Color(0xFF00FF00).toARGB32()),
        reason:
            'React styles the two kinds through separate hooks, which is the '
            'whole point of the slots',
      );
    });

    testWidgets('the catch-all style still reaches every kind', (tester) async {
      await pump(
        tester,
        FluentNavItemTheme(
          style: FluentNavItemStyle.from(
            backgroundColor: const Color(0xFF00FF00),
          ),
          child: const FluentNav(
            defaultOpenCategories: <Object>{'cat'},
            children: <Widget>[
              FluentNavItem(value: 'home', child: Text('Home')),
              FluentNavCategory(
                value: 'cat',
                child: Text('Reports'),
                children: <Widget>[
                  FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
                ],
              ),
            ],
          ),
        ),
      );

      for (final finder in <Finder>[
        find.byType(FluentNavItem),
        find.byType(FluentNavCategory),
        find.byType(FluentNavSubItem),
      ]) {
        expect(
          surface(tester, finder).color?.toARGB32(),
          const Color(0xFF00FF00).toARGB32(),
          reason:
              'dropping `required` from style must not change what style '
              'means — it is still the catch-all for every kind',
        );
      }
    });

    testWidgets('the kind slot wins over the catch-all, per property', (
      tester,
    ) async {
      await pump(
        tester,
        FluentNavItemTheme(
          style: FluentNavItemStyle.from(
            backgroundColor: const Color(0xFF00FF00),
            borderRadius: BorderRadius.circular(12),
          ),
          categoryStyle: FluentNavItemStyle.from(
            backgroundColor: const Color(0xFF0000FF),
          ),
          child: const FluentNav(
            children: <Widget>[
              FluentNavCategory(
                value: 'cat',
                child: Text('Reports'),
                children: <Widget>[
                  FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
                ],
              ),
            ],
          ),
        ),
      );

      final decoration = surface(tester, find.byType(FluentNavCategory));
      expect(
        decoration.color?.toARGB32(),
        const Color(0xFF0000FF).toARGB32(),
        reason: 'the kind slot is merged above the catch-all',
      );
      expect(
        decoration.borderRadius,
        BorderRadius.circular(12),
        reason:
            'merging is per-property: overriding only the fill must keep the '
            "catch-all's radius",
      );
    });

    testWidgets("the widget's own style still wins over both", (tester) async {
      await pump(
        tester,
        FluentNavItemTheme(
          style: FluentNavItemStyle.from(
            backgroundColor: const Color(0xFF00FF00),
          ),
          categoryStyle: FluentNavItemStyle.from(
            backgroundColor: const Color(0xFF0000FF),
          ),
          child: FluentNav(
            children: <Widget>[
              FluentNavCategory(
                value: 'cat',
                style: FluentNavItemStyle.from(
                  backgroundColor: const Color(0xFFFF0000),
                ),
                children: const <Widget>[
                  FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
                ],
                child: const Text('Reports'),
              ),
            ],
          ),
        ),
      );

      expect(
        surface(tester, find.byType(FluentNavCategory)).color?.toARGB32(),
        const Color(0xFFFF0000).toARGB32(),
        reason:
            'resolution order is defaults, catch-all, kind slot, then the '
            "caller's own style",
      );
    });

    testWidgets('wrap carries the kind slots across a route boundary', (
      tester,
    ) async {
      await pump(tester, const SizedBox.shrink());

      const theme = FluentNavItemTheme(
        categoryStyle: FluentNavItemStyle(),
        child: SizedBox.shrink(),
      );
      final wrapped =
          theme.wrap(
                tester.element(find.byType(FluentApp)),
                const SizedBox.shrink(),
              )
              as FluentNavItemTheme;

      expect(
        wrapped.categoryStyle,
        theme.categoryStyle,
        reason:
            'InheritedTheme.wrap exists so a theme survives re-parenting; a '
            'wrap that forgets a field drops it silently',
      );
    });
  });

  group('semantics', () {
    testWidgets('rows announce as buttons with selection and expansion', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        nav(
          semanticLabel: 'Main',
          selected: 'a',
          children: const <Widget>[
            FluentNavItem(value: 'a', child: Text('A')),
            FluentNavCategory(
              value: 'cat',
              child: Text('Group'),
              children: <Widget>[
                FluentNavSubItem(value: 'sub', child: Text('Sub')),
              ],
            ),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.text('A')),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          isSelected: true,
          hasEnabledState: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label: 'A',
        ),
      );
      expect(
        tester.getSemantics(find.text('Group')),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasSelectedState: true,
          hasExpandedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label: 'Group',
        ),
      );
      handle.dispose();
    });
  });
}
