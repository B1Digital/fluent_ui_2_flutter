import 'dart:ui' show Tristate;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentToast` is the surface half of the toast: the numbers, the tokens and
/// the slots. The queue, the positioning, the timer and the entrance motion are
/// `FluentToaster`, and are covered in `toaster_test.dart`.
///
/// Three things about the fixture are worth knowing before reading these.
///
/// The Figma `Toast` (`9116:16062`, page `8934:22`) is a **loose component with
/// no variants at all**. Both of its axes are component-scoped variable
/// collections whose modes the consumer pins on an instance — `Toast status`
/// with seven modes and `Toast type` with three — so the fixture holds a single
/// row named for the two pinned defaults, and the axes live in the `aliases`
/// block.
///
/// Those aliases are **booleans**, not colour tokens: each mode toggles the
/// visibility of one layer inside the 20-square status slot. The tokens that
/// matter therefore sit on the glyph vectors *inside* the hidden layers, which
/// the extractor's traversal deliberately skips. They were read read-only off
/// those vectors and are transcribed into `intentTokens` below, exactly the way
/// `message_bar_test.dart` transcribes its own glyph row.
///
/// And the intent moves **only the glyph**. Unlike a message bar, a toast keeps
/// `Neutral/Background/1/Rest` and `Neutral/Foreground/1/Rest` in every one of
/// the seven statuses — which is asserted here rather than assumed, because it
/// is the first thing somebody porting from `FluentMessageBar` would "fix".
void main() {
  const toastKey = Key('toast');
  const actionKey = Key('action');

  final spec = loadSpec('toast');
  final variant = spec.variant(const <String, String>{
    'Status': 'Informational',
    'Type': 'Dismiss',
  });

  /// The `Toast status` collection, mode by mode: the token bound to the glyph
  /// vector inside each mode's layer, with the Figma node it was read from.
  ///
  /// Figma's `Icon`, `Spinner` and `Avatar` modes all collapse onto
  /// [FluentToastIntent.custom] — they differ only in which widget is dropped
  /// into the slot, and `Icon`'s vector (`I9116:16070;9454:65`) is the one that
  /// states the tint the other two inherit.
  const intentTokens = <FluentToastIntent, String>{
    FluentToastIntent.info: 'Neutral/Foreground/3/Rest',
    FluentToastIntent.success: 'Status/Success/Foreground/1/Rest',
    FluentToastIntent.warning: 'Status/Warning/Foreground/1/Rest',
    // The finding StatusIndicator taught us and MessageBar confirmed, now a
    // third time: the axis value is Error and the token family is DANGER.
    FluentToastIntent.error: 'Status/Danger/Foreground/1/Rest',
    FluentToastIntent.custom: 'Neutral/Foreground/2/Rest',
  };

  /// The light-theme hex Figma resolves each of those to, straight off the
  /// vectors. Pins core's status ramp as well as the widget's selection.
  const intentLightFills = <FluentToastIntent, Color>{
    FluentToastIntent.info: Color(0xFF616161),
    FluentToastIntent.success: Color(0xFF0E700E),
    FluentToastIntent.warning: Color(0xFFBC4B09),
    FluentToastIntent.error: Color(0xFFB10E1C),
    FluentToastIntent.custom: Color(0xFF424242),
  };

  /// The Dart getter each Figma token name resolves to, for [theme].
  Color tokenOf(FluentThemeData theme, String figma) => switch (figma) {
    'Neutral/Foreground/2/Rest' => theme.colors.neutralForeground2,
    'Neutral/Foreground/3/Rest' => theme.colors.neutralForeground3,
    'Status/Success/Foreground/1/Rest' => theme.colors.statusSuccessForeground1,
    'Status/Warning/Foreground/1/Rest' => theme.colors.statusWarningForeground1,
    'Status/Danger/Foreground/1/Rest' => theme.colors.statusDangerForeground1,
    _ => throw StateError('no Dart getter mapped for $figma'),
  };

  final themes = <String, FluentThemeData>{
    'light': FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
    'dark': FluentThemeData.dark(fontPlatform: FluentFontPlatform.web),
    'high contrast': FluentThemeData.highContrast(
      fontPlatform: FluentFontPlatform.web,
    ),
  };

  Future<void> pump(
    WidgetTester tester,
    Widget toast, {
    FluentThemeData? theme,
    double width = 292,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(
        child: SizedBox(width: width, child: toast),
      ),
    ),
  );

  /// The surface's own decoration — the first `DecoratedBox` under the toast.
  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(FluentToast),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .first
              .decoration
          as BoxDecoration;

  /// The colour the ambient `IconTheme` resolves to at [glyph]'s own element,
  /// which is the value that actually reaches the rasteriser.
  Color? glyphColorOf(WidgetTester tester, IconData glyph) =>
      IconTheme.of(tester.element(find.byIcon(glyph))).color;

  group('Figma fidelity', () {
    testWidgets('${variant.name} matches the extracted spec', (tester) async {
      // `showIcon: false` for the harness only. `expectSpec` reads the FIRST
      // RichText under the finder and an `Icon` renders as one, so the status
      // glyph would be compared against the title's ramp. The glyph changes no
      // number the fixture states — it is a 20 box in a 20-high row — which the
      // next test pins directly.
      await pump(
        tester,
        FluentToast(
          title: const Text('Toast'),
          showIcon: false,
          onDismiss: () {},
        ),
      );
      expectSpec(tester, find.byType(FluentToast), variant);
    });

    testWidgets('the glyph changes none of the frame\'s numbers', (
      tester,
    ) async {
      await pump(
        tester,
        FluentToast(title: const Text('Toast'), onDismiss: () {}),
      );
      final withGlyph = tester.getSize(find.byType(FluentToast));
      expect(withGlyph, variant.size);
      expect(
        tester.getSize(find.byIcon(FluentIcons.info_20_regular)),
        const Size(20, 20),
      );
    });

    test('the fixture states the geometry the resolver reproduces', () {
      // The variant frame itself: 292 x 44, a 12 inset all round, Modal/Medium
      // corners and no stroke at all.
      expect(variant.size, const Size(292, 44));
      expect(variant.padding, const EdgeInsets.all(FluentSpacing.m));
      expect(variant.radius, FluentRadius.allMedium);
      expect(variant.token('fills'), 'Neutral/Background/1/Rest');
      expect(variant.token('paddingLeft'), 'Spacing/Horizontal/M');
      expect(variant.token('radius'), 'Corner-radius/Modal/Medium');
      // Figma paints NO stroke. The resolver deliberately keeps React's
      // transparent one — see the note on resolveFluentToastStyle.
      expect(variant.strokeWidth, 0);
      expect(variant.stroke, isNull);

      // The two gaps the header is built from.
      expect(variant.part('Toast header').gap, FluentSpacing.m);
      expect(
        variant.part('Toast header').token('itemSpacing'),
        'Spacing/Horizontal/M',
      );
      expect(variant.part('Status content').gap, FluentSpacing.s);
      expect(
        variant.part('Status content').token('itemSpacing'),
        'Spacing/Horizontal/S',
      );

      // The status slot is a 20 square, not React's 16.
      expect(variant.part('Icon').size, const Size(20, 20));
      // The dismiss glyph is 12 inside a 20 box.
      expect(variant.part('Dismiss').size, const Size(20, 20));
      expect(variant.part('Shape').size, const Size(12, 12));
      expect(variant.part('Shape').token('fills'), 'Neutral/Foreground/1/Rest');

      // The title is body1Strong stated as bound ramp tokens.
      final text = variant.part('Primary information').text!;
      expect(text.fontSize, 14);
      expect(text.lineHeight, 20);
      expect(text.tokens['fontStyle'], <String>['Typography/Weight/Semibold']);
      expect(text.tokens['fills'], <String>['Neutral/Foreground/1/Rest']);
    });

    testWidgets('the body indents to the title, not to the glyph', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentToast(
          key: toastKey,
          title: Text('Title'),
          body: Text('Body'),
        ),
      );
      // Figma pins `Toast body` at a 28 left inset, which is the 20 glyph box
      // plus the 8 media gap. The body's left edge must therefore line up with
      // the title's, not with the surface's.
      expect(
        tester.getTopLeft(find.text('Body')).dx,
        tester.getTopLeft(find.text('Title')).dx,
      );
      final style = resolveFluentToastStyle(
        resolveFluentToastState(title: const Text('Title')),
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      expect(style.bodyIndent?.resolve(const <WidgetState>{}), 28);
    });

    testWidgets('no glyph removes the indent as well as the gap', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentToast(
          title: Text('Title'),
          body: Text('Body'),
          showIcon: false,
        ),
      );
      expect(find.byIcon(FluentIcons.info_20_regular), findsNothing);
      expect(
        tester.getTopLeft(find.text('Body')).dx,
        tester.getTopLeft(find.text('Title')).dx,
      );
    });
  });

  group('Toast status — all seven Figma modes', () {
    for (final entry in intentTokens.entries) {
      final intent = entry.key;
      final token = entry.value;

      for (final theme in themes.entries) {
        testWidgets('${intent.name} glyph is $token in ${theme.key}', (
          tester,
        ) async {
          // `custom` has no glyph of its own — Figma's Icon/Spinner/Avatar modes
          // are exactly "your widget in the status slot" — so it supplies one.
          const custom = FluentIcons.circle_20_filled;
          final glyph = intent.glyph ?? custom;
          await pump(
            tester,
            FluentToast(
              intent: intent,
              icon: intent == FluentToastIntent.custom
                  ? const Icon(custom)
                  : null,
              title: const Text('Toast'),
            ),
            theme: theme.value,
          );
          expect(
            glyphColorOf(tester, glyph),
            tokenOf(theme.value, token),
            reason: '${intent.name} must select $token',
          );
        });
      }

      testWidgets('${intent.name} glyph resolves to Figma\'s light hex', (
        tester,
      ) async {
        const custom = FluentIcons.circle_20_filled;
        final glyph = intent.glyph ?? custom;
        await pump(
          tester,
          FluentToast(
            intent: intent,
            icon: intent == FluentToastIntent.custom
                ? const Icon(custom)
                : null,
            title: const Text('Toast'),
          ),
        );
        expect(glyphColorOf(tester, glyph), intentLightFills[intent]);
      });

      testWidgets('${intent.name} leaves the surface neutral', (tester) async {
        final theme = FluentThemeData.light(
          fontPlatform: FluentFontPlatform.web,
        );
        await pump(
          tester,
          FluentToast(
            intent: intent,
            icon: const Icon(FluentIcons.circle_20_filled),
            title: const Text('Toast'),
          ),
          theme: theme,
        );
        // The single largest difference between this and FluentMessageBar: an
        // intent tints the GLYPH and nothing else. All 7 Figma modes share one
        // container fill.
        expect(decorationOf(tester).color, theme.colors.neutralBackground1);
        // Scoped to the title's own text: an Icon renders as a RichText too,
        // and that one is SUPPOSED to move with the intent.
        expect(
          resolvedTextStyleOf(tester, of: find.text('Toast')).color,
          theme.colors.neutralForeground1,
        );
      });
    }

    testWidgets('the default glyphs are the four Fluent status icons', (
      tester,
    ) async {
      const expected = <FluentToastIntent, IconData>{
        FluentToastIntent.info: FluentIcons.info_20_regular,
        FluentToastIntent.success: FluentIcons.checkmark_circle_20_filled,
        FluentToastIntent.warning: FluentIcons.warning_20_filled,
        FluentToastIntent.error: FluentIcons.error_circle_20_filled,
      };
      for (final entry in expected.entries) {
        await pump(
          tester,
          FluentToast(intent: entry.key, title: const Text('Toast')),
        );
        expect(find.byIcon(entry.value), findsOneWidget);
      }
      // `custom` alone has none, which is what makes `icon` mandatory for it.
      expect(FluentToastIntent.custom.glyph, isNull);
    });

    test('only error and warning are assertive', () {
      expect(FluentToastIntent.error.assertive, isTrue);
      expect(FluentToastIntent.warning.assertive, isTrue);
      expect(FluentToastIntent.info.assertive, isFalse);
      expect(FluentToastIntent.success.assertive, isFalse);
      expect(FluentToastIntent.custom.assertive, isFalse);
    });
  });

  group('Toast type — all three Figma modes', () {
    testWidgets('dismiss puts a 20-square dismiss button in the end slot', (
      tester,
    ) async {
      var dismissed = 0;
      await pump(
        tester,
        FluentToast(title: const Text('Toast'), onDismiss: () => dismissed++),
      );
      final button = find.byType(FluentButton);
      expect(button, findsOneWidget);
      expect(tester.getSize(button), const Size(20, 20));
      await tester.tap(button);
      expect(dismissed, 1);
    });

    testWidgets('timestamp puts a caption1 label in the end slot', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        const FluentToast(
          title: Text('Toast'),
          type: FluentToastType.timestamp,
          timestamp: Text('12:04 PM'),
        ),
        theme: theme,
      );
      expect(find.byType(FluentButton), findsNothing);
      final style = resolvedTextStyleOf(tester, of: find.text('12:04 PM'));
      // Figma's `00:00 PM` node: 12/16 regular on Neutral/Foreground/1/Rest.
      expect(style.fontSize, 12);
      expect(style.height! * style.fontSize!, 16);
      expect(style.color, theme.colors.neutralForeground1);
    });

    testWidgets('action puts the caller\'s own affordance in the end slot', (
      tester,
    ) async {
      await pump(
        tester,
        FluentToast(
          title: const Text('Toast'),
          type: FluentToastType.action,
          action: FluentLink(
            key: actionKey,
            onPressed: () {},
            child: const Text('Undo'),
          ),
        ),
      );
      expect(find.byKey(actionKey), findsOneWidget);
      expect(find.byType(FluentButton), findsNothing);
    });

    testWidgets('a type only renders its own slot', (tester) async {
      // The three modes are mutually exclusive in Figma — one 20-square end
      // container — so supplying all three must still render exactly one.
      await pump(
        tester,
        FluentToast(
          title: const Text('Toast'),
          type: FluentToastType.timestamp,
          onDismiss: () {},
          timestamp: const Text('12:04 PM'),
          action: FluentLink(
            key: actionKey,
            onPressed: () {},
            child: const Text('Undo'),
          ),
        ),
      );
      expect(find.text('12:04 PM'), findsOneWidget);
      expect(find.byType(FluentButton), findsNothing);
      expect(find.byKey(actionKey), findsNothing);
    });
  });

  group('high contrast', () {
    testWidgets('the surface keeps a visible border', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        FluentToast(title: const Text('Toast'), onDismiss: () {}),
        theme: theme,
      );
      final border = decorationOf(tester).border! as Border;
      // Figma paints no stroke at all; React's `1px solid colorTransparentStroke`
      // is kept precisely because the token stops being transparent here. Without
      // it a neutralBackground1 toast on a neutralBackground1 page is invisible.
      expect(border.top.color, theme.colors.transparentStroke);
      expect(
        border.top.color.a,
        1.0,
        reason: 'must be opaque in high contrast',
      );
      expect(border.top.width, FluentStroke.thin);
    });

    testWidgets('the border is the token in every theme, not a hardcoded '
        'transparent', (tester) async {
      // `transparentStroke` is invisible in light and dark and OPAQUE in high
      // contrast. Selecting the token rather than `Colors.transparent` is the
      // whole difference: the literal would stay invisible in all three.
      final opacity = <String, double>{};
      for (final theme in themes.entries) {
        await pump(
          tester,
          const FluentToast(title: Text('Toast')),
          theme: theme.value,
        );
        final border = decorationOf(tester).border! as Border;
        expect(border.top.color, theme.value.colors.transparentStroke);
        expect(border.top.width, FluentStroke.thin);
        opacity[theme.key] = border.top.color.a;
      }
      expect(opacity['light'], 0.0);
      expect(opacity['dark'], 0.0);
      expect(opacity['high contrast'], 1.0);
    });

    testWidgets('there is no scrim to be transparent', (tester) async {
      // A toast is not modal. Nothing is painted behind it, so there is no
      // scrim that could be hardcoded to Colors.transparent — the assertion is
      // that the surface is the ONLY decorated box the toast contributes.
      await pump(
        tester,
        const FluentToast(title: Text('Toast')),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FluentToast),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(boxes, hasLength(1));
    });
  });

  group('disabled is a real state', () {
    testWidgets('no onDismiss renders no dismiss button at all', (
      tester,
    ) async {
      // Not a greyed-out one: the Figma `Toast type` axis has no disabled mode,
      // so the affordance is either there or it is not.
      await pump(tester, const FluentToast(title: Text('Toast')));
      expect(find.byType(FluentButton), findsNothing);
    });

    testWidgets('a disabled footer action reports no tap action', (
      tester,
    ) async {
      const disabled = Key('disabled');
      await pump(
        tester,
        const FluentToast(
          title: Text('Toast'),
          footer: <Widget>[FluentButton(key: disabled, child: Text('Retry'))],
        ),
      );
      final node = tester.getSemantics(find.byKey(disabled));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      // An attached onTap would put a tap ACTION in the tree and a screen
      // reader would announce the disabled button as activatable.
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    });

    testWidgets('an enabled footer action still fires', (tester) async {
      var pressed = 0;
      await pump(
        tester,
        FluentToast(
          title: const Text('Toast'),
          footer: <Widget>[
            FluentButton(
              onPressed: () => pressed++,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      await tester.tap(find.byType(FluentButton));
      expect(pressed, 1);
    });
  });

  group('semantics', () {
    testWidgets('the toast is a live region', (tester) async {
      await pump(tester, const FluentToast(title: Text('Toast')));
      expect(
        tester
            .getSemantics(find.byType(FluentToast))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
    });

    testWidgets('liveRegion: false silences it', (tester) async {
      await pump(
        tester,
        const FluentToast(title: Text('Toast'), liveRegion: false),
      );
      expect(
        tester
            .getSemantics(find.byType(FluentToast))
            .flagsCollection
            .isLiveRegion,
        isFalse,
      );
    });

    testWidgets('the dismiss button announces a label of its own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentToast(
          title: const Text('Toast'),
          onDismiss: () {},
          dismissSemanticLabel: 'Close notification',
        ),
      );
      final node = tester.getSemantics(find.byType(FluentButton));
      expect(node.label, contains('Close notification'));
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });

  group('customisation', () {
    testWidgets('the widget style is merged last and wins', (tester) async {
      const cyan = Color(0xFF00B7C3);
      await pump(
        tester,
        FluentToast(
          title: const Text('Toast'),
          style: FluentToastStyle.from(backgroundColor: cyan),
        ),
      );
      expect(decorationOf(tester).color, cyan);
    });

    testWidgets('a subtree FluentToastTheme restyles, and the widget still '
        'wins over it', (tester) async {
      const themed = Color(0xFF6264A7);
      const own = Color(0xFF00B7C3);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: FluentToastTheme(
              style: FluentToastStyle.from(backgroundColor: themed),
              child: const SizedBox(
                width: 292,
                child: FluentToast(title: Text('Toast')),
              ),
            ),
          ),
        ),
      );
      expect(decorationOf(tester).color, themed);

      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: FluentToastTheme(
              style: FluentToastStyle.from(backgroundColor: themed),
              child: SizedBox(
                width: 292,
                child: FluentToast(
                  title: const Text('Toast'),
                  style: FluentToastStyle.from(backgroundColor: own),
                ),
              ),
            ),
          ),
        ),
      );
      expect(decorationOf(tester).color, own);
    });

    test('merge is per-property, not wholesale', () {
      final base = FluentToastStyle.from(
        backgroundColor: const Color(0xFF111111),
        iconColor: const Color(0xFF222222),
      );
      final merged = base.merge(
        FluentToastStyle.from(backgroundColor: const Color(0xFF333333)),
      );
      const states = <WidgetState>{};
      expect(merged.backgroundColor?.resolve(states), const Color(0xFF333333));
      expect(merged.iconColor?.resolve(states), const Color(0xFF222222));
    });

    test('copyWith replaces only what it is given', () {
      final base = FluentToastStyle.from(width: 292, stackGap: 16);
      final copy = base.copyWith(
        width: const WidgetStatePropertyAll<double?>(400),
      );
      const states = <WidgetState>{};
      expect(copy.width?.resolve(states), 400);
      expect(copy.stackGap?.resolve(states), 16);
    });

    test('equal styles are equal, and hash together', () {
      final a = FluentToastStyle.from(backgroundColor: const Color(0xFF111111));
      final b = FluentToastStyle.from(backgroundColor: const Color(0xFF111111));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('recomposition contract', () {
    test(
      'resolveFluentToastState picks the glyph, and showIcon suppresses it',
      () {
        expect(
          resolveFluentToastState(title: const Text('t')).icon,
          isA<Icon>().having(
            (i) => i.icon,
            'icon',
            FluentIcons.info_20_regular,
          ),
        );
        expect(
          resolveFluentToastState(title: const Text('t'), showIcon: false).icon,
          isNull,
        );
        expect(
          resolveFluentToastState(
            title: const Text('t'),
            intent: FluentToastIntent.custom,
          ).icon,
          isNull,
          reason: 'custom has no glyph of its own',
        );
      },
    );

    testWidgets('buildFluentToast takes the BASE state and renders without '
        'reading the axes', (tester) async {
      // The whole point of the three-function split: a caller can hand it a
      // base state and a style of their own and still get Fluent's layout.
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: SizedBox(
              width: 292,
              child: Builder(
                builder: (context) => buildFluentToast(
                  const FluentToastBaseState(title: Text('Bare')),
                  FluentToastStyle.from(
                    backgroundColor: magenta,
                    padding: const EdgeInsets.all(FluentSpacing.m),
                  ),
                  const <WidgetState>{},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Bare'), findsOneWidget);
      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      expect((box.decoration as BoxDecoration).color, magenta);
    });
  });
}
