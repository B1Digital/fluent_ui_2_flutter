import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/router.dart';
import 'package:fluent_2_example/shell/rtl_scope.dart';
import 'package:fluent_2_example/shell/showroom_app.dart';
import 'package:fluent_2_example/shell/theme_variants.dart';
import 'package:fluent_2_example/shell/widgets/docs_scaffold.dart';
import 'package:fluent_2_example/shell/widgets/preview_band.dart';
import 'package:fluent_2_example/shell/widgets/preview_card.dart';
import 'package:fluent_2_example/shell/widgets/sidebar.dart';
import 'package:fluent_2_example/shell/widgets/story_outlines.dart';
import 'package:fluent_2_example/shell/widgets/toolbar_parts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mouse.dart';

/// The docs bar against Storybook 9.1.17's, control by control, in the real
/// [ShowroomApp].
///
/// Upstream's docs set, left to right (live `docsTools`): Grid, Background,
/// Outline, Theme, Direction, Strict mode, and Full screen against the right
/// edge — no viewport control and no separator, plus "Show sidebar" and a
/// separator first while the sidebar is hidden. Every press is a real mouse
/// click and every hover a real mouse pointer: the bar sits at y=0, where a
/// synthesised still touch has hidden dead controls before.
void main() {
  const String grid = 'Apply a grid to the preview';
  const String background = 'Change the background of the preview';
  const String outline = 'Apply outlines to the preview';
  const String theme = 'Change Fluent theme';
  const String direction = 'Change Direction';
  const String strict = 'Toggle React Strict mode';
  // flutter_test's default platform is Android, so the key reads "alt F".
  const String goFull = 'Go full screen [alt F]';
  const String exitFull = 'Exit full screen [alt F]';

  group('tooltips', () {
    testWidgets('every control shows its tooltip inside the window, under '
        'the bar', (WidgetTester tester) async {
      await _boot(tester);
      for (final String tooltip in <String>[
        grid,
        background,
        outline,
        theme,
        direction,
        strict,
        goFull,
      ]) {
        _expectInsideBelowBar(await _tooltipRect(tester, tooltip), tooltip);
      }
    });

    testWidgets('in full screen too: Show sidebar hard against the left '
        'edge, Exit full screen against the right', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      await mouseClick(tester, _control(goFull));
      expect(tester.getRect(_control('Show sidebar')).left, 10);
      for (final String tooltip in <String>['Show sidebar', exitFull]) {
        _expectInsideBelowBar(await _tooltipRect(tester, tooltip), tooltip);
      }
    });
  });

  group('the docs set', () {
    testWidgets('Grid, Background, Outline, Theme, Direction, Strict, then '
        'Full screen at the far right; no viewport, no separator', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      final List<double> lefts = <double>[
        for (final String t in <String>[
          grid,
          background,
          outline,
          theme,
          direction,
          strict,
          goFull,
        ])
          tester.getRect(_control(t)).left,
      ];
      expect(lefts, orderedEquals(List<double>.of(lefts)..sort()));
      // 10px bar inset from the window's right edge.
      expect(tester.getRect(_control(goFull)).right, 1600 - 10);
      expect(_control('Change the size of the preview'), findsNothing);
      expect(find.byType(ToolbarSeparator), findsNothing);
      expect(_control('Show sidebar'), findsNothing);
    });
  });

  group('Grid', () {
    testWidgets('toggles the grid on every band and is active while on', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      expect(
        _bands(tester).map((PreviewBand b) => b.grid),
        everyElement(false),
      );
      expect(_button(tester, grid).active, isFalse);

      await mouseClick(tester, _control(grid));
      expect(_bands(tester).map((PreviewBand b) => b.grid), everyElement(true));
      expect(_button(tester, grid).active, isTrue);

      await mouseClick(tester, _control(grid));
      expect(
        _bands(tester).map((PreviewBand b) => b.grid),
        everyElement(false),
      );
      expect(_button(tester, grid).active, isFalse);
    });
  });

  group('F1: a bar tooltip hides on press, like a native title tooltip', () {
    testWidgets('a quick click inside the show delay opens the menu but '
        'keeps the tooltip hidden', (WidgetTester tester) async {
      await _boot(tester);
      final TestGesture press = await tester.startGesture(
        tester.getCenter(_control(background)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await press.up();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('light'), findsOneWidget, reason: 'the menu opened');
      expect(
        find.text(background),
        findsNothing,
        reason: 'the tooltip stayed hidden',
      );
      await press.removePointer();
    });

    testWidgets('a press while the tooltip is visible hides it until the '
        'pointer leaves and returns', (WidgetTester tester) async {
      await _boot(tester);
      final TestGesture mouse = await mouseHover(tester, _control(background));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.text(background),
        findsOneWidget,
        reason: 'visible before the press',
      );

      await mouse.down(tester.getCenter(_control(background)));
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('light'), findsOneWidget, reason: 'the menu opened');
      expect(
        find.text(background),
        findsNothing,
        reason: 'the tooltip hid on press',
      );

      await mouse.moveTo(const Offset(0, 0));
      await tester.pump();
      await mouse.moveTo(tester.getCenter(_control(background)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.text(background),
        findsOneWidget,
        reason: 'shows again after leave + re-enter',
      );
      await mouse.removePointer();
    });
  });

  group('Background', () {
    testWidgets('none by default; light and dark; Reset first only while '
        'set; Reset clears the grid too', (WidgetTester tester) async {
      await _boot(tester);
      expect(
        _bands(tester).map((PreviewBand b) => b.background),
        everyElement(isNull),
      );
      expect(_button(tester, background).active, isFalse);

      await mouseClick(tester, _control(background));
      expect(find.text('Reset background'), findsNothing);
      expect(_topsOf(tester, <String>['light', 'dark']), _ascending);
      for (final PreviewBackground b in PreviewBackground.values) {
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Icon &&
                w.icon == FluentIcons.circle_20_filled &&
                w.color == b.color,
          ),
          findsOneWidget,
          reason: '${b.label} swatch',
        );
      }

      await mouseClick(tester, find.text('dark'));
      expect(find.text('light'), findsNothing, reason: 'closes on a pick');
      expect(
        _bands(tester).map((PreviewBand b) => b.background),
        everyElement(PreviewBackground.dark),
      );
      expect(_button(tester, background).active, isTrue);

      await mouseClick(tester, _control(grid));
      await mouseClick(tester, _control(background));
      expect(
        _topsOf(tester, <String>['Reset background', 'light', 'dark']),
        _ascending,
      );
      final Text chosen = tester.widget<Text>(find.text('dark'));
      expect(chosen.style?.color, ToolbarColors.active);
      expect(chosen.style?.fontWeight, FontWeight.w700);
      expect(tester.widget<Text>(find.text('light')).style, isNull);

      await mouseClick(tester, find.text('Reset background'));
      expect(
        _bands(tester).map((PreviewBand b) => b.background),
        everyElement(isNull),
      );
      // Upstream's Reset writes `backgrounds: undefined`, grid included.
      expect(
        _bands(tester).map((PreviewBand b) => b.grid),
        everyElement(false),
      );
      expect(_button(tester, background).active, isFalse);
      expect(_button(tester, grid).active, isFalse);
    });
  });

  group('Outline', () {
    testWidgets('outlines every story from its nb2 wrapper down, and is '
        'active while on', (WidgetTester tester) async {
      await _boot(tester);
      expect(
        tester
            .widgetList<StoryOutlines>(find.byType(StoryOutlines))
            .map((StoryOutlines o) => o.enabled),
        everyElement(false),
      );

      await mouseClick(tester, _control(outline));
      final List<StoryOutlines> outlines = tester
          .widgetList<StoryOutlines>(find.byType(StoryOutlines))
          .toList();
      expect(outlines, hasLength(find.byType(PreviewCard).evaluate().length));
      expect(outlines.map((StoryOutlines o) => o.enabled), everyElement(true));
      expect(_button(tester, outline).active, isTrue);
      // The wrapper is the first box under the outliner, so it gets the blue
      // ring upstream's `.sb-story div` rule gives it.
      final Widget wrapper = outlines.first.child;
      expect(wrapper, isA<ColoredBox>());
      expect((wrapper as ColoredBox).color, const Color(0xFFFAFAFA));
      expect(
        find.descendant(
          of: find.byIcon(FluentIcons.square_hint_20_regular),
          matching: find.byType(RichText),
        ),
        findsOneWidget,
      );
    });
  });

  group('the preview band', () {
    testWidgets('38px around the story on every side, the action row flush '
        'with its bottom, 31px in from its right', (WidgetTester tester) async {
      await _boot(tester);
      final Finder card = find.byType(PreviewCard).first;
      final Rect band = tester.getRect(
        find.descendant(of: card, matching: find.byType(PreviewBand)),
      );
      final Rect story = tester.getRect(
        find.descendant(of: card, matching: find.byType(StoryOutlines)),
      );
      expect(story.left - band.left, 38);
      expect(story.top - band.top, 38);
      expect(band.right - story.right, 38);
      expect(band.bottom - story.bottom, 38);

      final Rect showCode = tester.getRect(
        find
            .ancestor(
              of: find.descendant(of: card, matching: find.text('Show code')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(showCode.height, 29);
      expect(showCode.bottom, band.bottom);
      expect(band.right - showCode.right, 31);
    });
  });

  group('Theme', () {
    testWidgets('arrow then "Theme: …"; upstream seven with "(Default)"; '
        'active off Web Light', (WidgetTester tester) async {
      await _boot(tester);
      expect(
        find.descendant(
          of: _control(theme),
          matching: find.byIcon(FluentIcons.arrow_down_20_regular),
        ),
        findsOneWidget,
      );
      expect(find.text('Theme: Web Light'), findsOneWidget);
      // Upstream: a 14px arrow, the button's 6px gap, then the label span's
      // `margin-left: 5px` — the text starts 11px after the icon.
      expect(
        tester.getRect(find.text('Theme: Web Light')).left -
            tester
                .getRect(
                  find.descendant(
                    of: _control(theme),
                    matching: find.byType(Icon),
                  ),
                )
                .right,
        11,
      );
      expect(_button(tester, theme).active, isFalse);

      await mouseClick(tester, _control(theme));
      const List<String> rows = <String>[
        'Web Light (Default)',
        'Web Dark',
        'Teams Light',
        'Teams Dark',
        'Teams Light V2.1',
        'Teams Dark V2.1',
        'Teams High Contrast',
      ];
      expect(_topsOf(tester, rows), _ascending);
      expect(find.text('Office Light'), findsNothing);
      final Text chosen = tester.widget<Text>(find.text(rows.first));
      expect(chosen.style?.color, ToolbarColors.active);
      expect(chosen.style?.fontWeight, FontWeight.w700);

      await mouseClick(tester, find.text('Teams Dark'));
      expect(find.text('Theme: Teams Dark'), findsOneWidget);
      expect(_button(tester, theme).active, isTrue);
      expect(
        _stageBrand(tester),
        ThemeVariant.teamsDark.data.colors.brandBackground,
      );
    });
  });

  group('Direction', () {
    testWidgets('one click toggles LTR and RTL, opens no menu, never active', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      expect(find.text('Direction: LTR'), findsOneWidget);
      expect(
        find.ancestor(
          of: _control(direction),
          matching: find.byType(FluentMenu),
        ),
        findsNothing,
      );

      await mouseClick(tester, _control(direction));
      expect(find.text('Direction: RTL'), findsOneWidget);
      expect(_stageDirection(tester), TextDirection.rtl);
      // Only the docs toolbar's static "RTL" caption: no menu row appeared.
      expect(find.text('RTL'), findsOneWidget);
      expect(_button(tester, direction).active, isFalse);

      await mouseClick(tester, _control(direction));
      expect(find.text('Direction: LTR'), findsOneWidget);
      expect(_stageDirection(tester), TextDirection.ltr);
    });

    testWidgets('the value is a monospace span', (WidgetTester tester) async {
      await _boot(tester);
      final Text label = tester.widget<Text>(find.text('Direction: LTR'));
      final InlineSpan value = (label.textSpan! as TextSpan).children!.single;
      expect(value.toPlainText(), 'LTR');
      expect(value.style?.fontFamily, 'Cascadia Code');
      expect(value.style?.fontFamilyFallback, <String>[
        'Menlo',
        'Courier New',
        'Courier',
        'monospace',
      ]);
      expect(value.style?.letterSpacing, -0.6);
    });
  });

  group('Strict mode', () {
    testWidgets('closed padlock always, lit while on, remounts every story '
        'and leaves it interactive', (WidgetTester tester) async {
      await _boot(tester);
      final Finder toggle = find.descendant(
        of: find.byType(PreviewCard).first,
        matching: find.byType(FluentSwitch),
      );
      bool checked() => tester.widget<FluentSwitch>(toggle).checked;
      final Finder padlock = find.descendant(
        of: _control(strict),
        matching: find.byIcon(FluentIcons.lock_closed_20_regular),
      );

      expect(padlock, findsOneWidget);
      expect(_button(tester, strict).active, isFalse);
      await mouseClick(tester, toggle);
      expect(checked(), isTrue);

      await mouseClick(tester, _control(strict));
      expect(checked(), isFalse, reason: 'the story remounted');
      expect(_button(tester, strict).active, isTrue);
      expect(padlock, findsOneWidget);

      await mouseClick(tester, toggle);
      expect(checked(), isTrue, reason: 'nothing blocks the pointer');

      await mouseClick(tester, _control(strict));
      expect(checked(), isFalse);
      expect(_button(tester, strict).active, isFalse);
      expect(padlock, findsOneWidget);
    });
  });

  group('Full screen', () {
    testWidgets('hides the sidebar, adds Show sidebar, and Show sidebar '
        'brings both back', (WidgetTester tester) async {
      await _boot(tester);
      final State<PreviewCard> card = tester.state(
        find.byType(PreviewCard).first,
      );
      expect(find.byType(Sidebar), findsOneWidget);
      expect(
        tester
            .widget<FluentButton>(
              find.descendant(
                of: _control(goFull),
                matching: find.byType(FluentButton),
              ),
            )
            .semanticLabel,
        'Go full screen',
      );
      expect(
        find.descendant(
          of: _control(goFull),
          matching: find.byIcon(FluentIcons.arrow_maximize_20_regular),
        ),
        findsOneWidget,
      );

      await mouseClick(tester, _control(goFull));
      expect(find.byType(Sidebar), findsNothing);
      expect(_control('Show sidebar'), findsOneWidget);
      expect(find.byType(ToolbarSeparator), findsOneWidget);
      expect(
        tester.getRect(_control('Show sidebar')).left,
        lessThan(tester.getRect(_control(grid)).left),
      );
      expect(_control(exitFull), findsOneWidget);
      expect(_button(tester, exitFull).active, isFalse);
      expect(
        find.descendant(
          of: _control(exitFull),
          matching: find.byIcon(FluentIcons.dismiss_circle_20_regular),
        ),
        findsOneWidget,
      );
      // Full screen is only the hidden sidebar now: the page is not rebuilt.
      expect(tester.state(find.byType(PreviewCard).first), same(card));

      await mouseClick(tester, _control('Show sidebar'));
      expect(find.byType(Sidebar), findsOneWidget);
      expect(_control('Show sidebar'), findsNothing);
      expect(_control(goFull), findsOneWidget);
    });

    testWidgets('names the key the macOS way on macOS', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      expect(_control('Go full screen [⌥ F]'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });
}

/// A page whose first story is stateful: a Switch that starts off.
const String _page = 'components-switch';

Future<void> _boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const ShowroomApp());
  // FluentApp renders SizedBox.shrink() until its web-font future resolves.
  await tester.pumpAndSettle();
  DocsRouterScope.of(
    tester.element(find.byType(DocsScaffold)),
  ).go(const DocsRoute.docs(_page));
  await tester.pumpAndSettle();
}

/// The bar control whose tooltip is [tooltip]. A menu control builds its
/// trigger as a [ToolbarButton] with the same tooltip.
Finder _control(String tooltip) => find.byWidgetPredicate(
  (Widget w) => w is ToolbarButton && w.tooltip == tooltip,
);

ToolbarButton _button(WidgetTester tester, String tooltip) =>
    tester.widget<ToolbarButton>(_control(tooltip));

List<PreviewBand> _bands(WidgetTester tester) =>
    tester.widgetList<PreviewBand>(find.byType(PreviewBand)).toList();

/// Hovers the control past the 250ms show delay and returns where its
/// tooltip text landed, then moves the mouse away and lets it close.
Future<Rect> _tooltipRect(WidgetTester tester, String tooltip) async {
  final TestGesture mouse = await mouseHover(tester, _control(tooltip));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  expect(find.text(tooltip), findsOneWidget, reason: '"$tooltip" shows');
  final Rect rect = tester.getRect(find.text(tooltip));
  await mouse.removePointer();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  return rect;
}

void _expectInsideBelowBar(Rect rect, String tooltip) {
  expect(rect.top, greaterThanOrEqualTo(40), reason: '"$tooltip" top');
  expect(rect.left, greaterThanOrEqualTo(0), reason: '"$tooltip" left');
  expect(rect.right, lessThanOrEqualTo(1600), reason: '"$tooltip" right');
  expect(rect.bottom, lessThanOrEqualTo(1200), reason: '"$tooltip" bottom');
}

/// The top edge of each label, in the order given.
List<double> _topsOf(WidgetTester tester, List<String> labels) => <double>[
  for (final String label in labels) tester.getRect(find.text(label)).top,
];

/// Strictly increasing, i.e. the rows are in the order listed.
final Matcher _ascending = predicate<List<double>>((List<double> tops) {
  for (int i = 1; i < tops.length; i++) {
    if (tops[i] <= tops[i - 1]) {
      return false;
    }
  }
  return true;
}, 'rows in the listed order');

Color _stageBrand(WidgetTester tester) => tester
    .widget<FluentTheme>(
      find
          .descendant(
            of: find.byType(PreviewCard).first,
            matching: find.byType(FluentTheme),
          )
          .first,
    )
    .data
    .colors
    .brandBackground;

TextDirection _stageDirection(WidgetTester tester) => tester
    .widget<RtlScope>(
      find
          .descendant(
            of: find.byType(PreviewCard).first,
            matching: find.byType(RtlScope),
          )
          .first,
    )
    .textDirection;
