import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentDialog` is the package's first *modal* overlay, so these tests cover
/// three things beyond token fidelity: that the surface reaches the `Overlay`
/// with the ambient `FluentTheme` intact, that focus is trapped and handed back,
/// and that the entrance honours `MediaQuery.disableAnimations` — which matters
/// more here than anywhere else, because both the surface and the scrim animate.
void main() {
  const body = Key('dialog-body');
  const trigger = Key('dialog-trigger');
  const primary = Key('dialog-primary');
  const secondary = Key('dialog-secondary');
  const tertiary = Key('dialog-tertiary');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  /// Mounts a dialog whose openness is driven by the returned notifier.
  ///
  /// Openness is controlled, so nothing here flips it: `setOpen` below is the
  /// only way in and out, which is also how a consumer would drive it.
  Future<ValueNotifier<bool>> pump(
    WidgetTester tester, {
    bool open = false,
    bool dismissible = true,
    bool showCloseButton = true,
    bool reducedMotion = false,
    FluentDialogModalType modalType = FluentDialogModalType.modal,
    FluentDialogSize size = FluentDialogSize.medium,
    List<Widget> actions = const <Widget>[],
    List<Widget> secondaryActions = const <Widget>[],
    Widget? title,
    FluentDialogStyle? style,
    FluentThemeData? theme,
    Widget Function(Widget child)? wrap,
  }) async {
    final notifier = ValueNotifier<bool>(open);
    addTearDown(notifier.dispose);

    await tester.pumpWidget(
      FluentApp(
        theme: theme ?? light(),
        builder: reducedMotion
            ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
            : null,
        home: ValueListenableBuilder<bool>(
          valueListenable: notifier,
          builder: (context, value, _) {
            final dialog = FluentDialog(
              open: value,
              onOpenChange: dismissible
                  ? (next) => notifier.value = next
                  : null,
              modalType: modalType,
              size: size,
              title: title,
              actions: actions,
              secondaryActions: secondaryActions,
              showCloseButton: showCloseButton,
              style: style,
              semanticLabel: 'Confirm',
              content: const Text('Body', key: body),
              child: FluentButton(
                key: trigger,
                autofocus: true,
                onPressed: () => notifier.value = true,
                child: const Text('Open'),
              ),
            );
            return Center(child: wrap == null ? dialog : wrap(dialog));
          },
        ),
      ),
    );
    // One frame to mount, one for the post-frame insert of an initially-open
    // dialog. A dialog that starts open has already arrived, so settle it —
    // the entrance is observed through `setOpen` instead, which does not.
    await tester.pump();
    await tester.pump();
    if (open) await tester.pumpAndSettle();
    return notifier;
  }

  /// Flips [notifier] and pumps far enough for the overlay to react, without
  /// settling — several tests need to observe a frame mid-transition.
  Future<void> setOpen(
    WidgetTester tester,
    ValueNotifier<bool> notifier, {
    required bool value,
  }) async {
    notifier.value = value;
    // The first pump rebuilds the widget and schedules the overlay mutation,
    // the second performs it.
    await tester.pump();
    await tester.pump();
  }

  /// The surface's own decorated box, found through the body rather than
  /// through `FluentDialog` — the surface lives in the overlay, not under the
  /// widget that owns it.
  Finder surface() => find
      .ancestor(of: find.byKey(body), matching: find.byType(DecoratedBox))
      .first;

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester.widget<DecoratedBox>(surface()).decoration as BoxDecoration;

  Finder scrim(FluentThemeData theme) => find.byWidgetPredicate(
    (widget) =>
        widget is ColoredBox && widget.color == theme.colors.backgroundOverlay,
  );

  double surfaceScale(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find
            .ancestor(
              of: find.byKey(body),
              matching: find.byType(ScaleTransition),
            )
            .first,
      )
      .scale
      .value;

  double surfaceOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(body),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  double scrimOpacity(WidgetTester tester, FluentThemeData theme) => tester
      .widget<FadeTransition>(
        find
            .ancestor(of: scrim(theme), matching: find.byType(FadeTransition))
            .first,
      )
      .opacity
      .value;

  Widget action(Key key, String label) =>
      FluentButton(key: key, onPressed: () {}, child: Text(label));

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('dialog');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 4);
      expect(spec.properties['Size'], <String>['600px', '320px']);
      expect(spec.properties['Layout'], <String>['Text', 'Placeholder']);
    });

    for (final entry in <FluentDialogSize, String>{
      FluentDialogSize.medium: '600px',
      FluentDialogSize.small: '320px',
    }.entries) {
      // Layout=Text vs Layout=Placeholder swaps Figma's own body filler for a
      // brand rectangle and changes nothing about the surface, so the surface
      // assertions run against Text and the Placeholder twin is checked to
      // agree below.
      final variant = spec.variant(<String, String>{
        'Size': entry.value,
        'Layout': 'Text',
      });

      testWidgets('${entry.value}: surface tokens and geometry', (
        tester,
      ) async {
        await pump(
          tester,
          open: true,
          size: entry.key,
          title: const Text('Title'),
          actions: <Widget>[action(primary, 'Take action')],
        );

        expect(
          tester.getSize(surface()).width,
          variant.size.width,
          reason: '${variant.name}: surface width',
        );

        final decoration = decorationOf(tester);
        expect(
          decoration.color,
          variant.fill,
          reason: '${variant.name}: fill (${variant.token('fills')})',
        );
        expect(
          decoration.borderRadius,
          variant.radius,
          reason: '${variant.name}: radius (${variant.token('radius')})',
        );

        final padding = tester
            .widget<Padding>(
              find
                  .descendant(of: surface(), matching: find.byType(Padding))
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr);
        expect(
          padding,
          variant.padding,
          reason: '${variant.name}: padding (${variant.token('paddingLeft')})',
        );

        // `subtitle1` Semibold on the header text in all four variants.
        // Figma binds 20/28; the published Web ramp
        // (https://fluent2.microsoft.design/typography) specifies 20/26, and
        // that is what ships — so the size is asserted against the fixture and
        // the line height against the ramp.
        final title = tester.widget<RichText>(
          find.descendant(of: surface(), matching: find.byType(RichText)).first,
        );
        expect(title.text.style!.fontSize, variant.text!.fontSize);
        expect(
          title.text.style!.height! * title.text.style!.fontSize!,
          variant.text!.fontSize == 20 ? 26 : variant.text!.lineHeight,
        );
      });

      testWidgets('${entry.value}: the Placeholder twin agrees', (
        tester,
      ) async {
        final placeholder = spec.variant(<String, String>{
          'Size': entry.value,
          'Layout': 'Placeholder',
        });
        expect(placeholder.size.width, variant.size.width);
        expect(placeholder.fill, variant.fill);
        expect(placeholder.radius, variant.radius);
        expect(placeholder.padding, variant.padding);
        expect(placeholder.token('fills'), 'Neutral/Background/1/Rest');
      });
    }

    testWidgets('the header, body and footer insets come from the parts', (
      tester,
    ) async {
      final variant = spec.variant(<String, String>{
        'Size': '600px',
        'Layout': 'Text',
      });
      final theme = light();
      final state = resolveFluentDialogState(content: const Text('Body'));
      final style = resolveFluentDialogStyle(state, theme);
      const states = <WidgetState>{};

      // The surface's own vertical rhythm, on the variant frame.
      expect(style.gap!.resolve(states), variant.gap);
      // `Spacing/Horizontal/S` between the title and the close button.
      expect(style.headerGap!.resolve(states), variant.part('Header').gap);
      // Figma's `Container for offset` exists only to carry this lead-in.
      expect(
        style.closeButtonPadding!.resolve(states)!.resolve(TextDirection.ltr),
        EdgeInsets.only(
          left: variant.part('Container for offset').padding!.left,
        ),
      );
      // `Spacing/Horizontal/XS` above the actions, on top of the surface gap.
      expect(
        style.actionsPadding!.resolve(states),
        EdgeInsets.only(top: variant.part('Footer').padding!.top),
      );
      expect(style.actionsGap!.resolve(states), variant.part('Right').gap);

      await tester.pump();
    });

    testWidgets('600px lays the actions out in a space-between row', (
      tester,
    ) async {
      await pump(
        tester,
        open: true,
        title: const Text('Title'),
        // Short labels: the test font draws every glyph as the same wide box,
        // so Figma's own strings would overflow a 552-wide footer and the row
        // positions would stop meaning anything.
        actions: <Widget>[action(primary, 'Ok'), action(secondary, 'No')],
        secondaryActions: <Widget>[action(tertiary, 'Help')],
      );

      final box = tester.getRect(surface());
      // 24 of surface padding either side, secondary group hard against the
      // start and the primary group hard against the end.
      expect(tester.getRect(find.byKey(tertiary)).left, box.left + 24);
      expect(tester.getRect(find.byKey(secondary)).right, box.right - 24);
      // Every action shares one row.
      expect(
        tester.getRect(find.byKey(tertiary)).top,
        tester.getRect(find.byKey(primary)).top,
      );
      // `Spacing/Horizontal/S` between adjacent actions.
      expect(
        tester.getRect(find.byKey(secondary)).left -
            tester.getRect(find.byKey(primary)).right,
        FluentSpacing.s,
      );
    });

    testWidgets('320px stacks the actions full width, secondary first', (
      tester,
    ) async {
      final variant = spec.variant(<String, String>{
        'Size': '320px',
        'Layout': 'Text',
      });
      await pump(
        tester,
        open: true,
        size: FluentDialogSize.small,
        title: const Text('Title'),
        actions: <Widget>[action(primary, 'Take action')],
        secondaryActions: <Widget>[action(secondary, 'Different action')],
      );

      // 320 less the 24 inset either side, which is Figma's own 272.
      final width = tester.getSize(find.byKey(primary)).width;
      expect(width, variant.part('Footer').size.width);
      expect(tester.getSize(find.byKey(secondary)).width, width);

      final secondaryRect = tester.getRect(find.byKey(secondary));
      final primaryRect = tester.getRect(find.byKey(primary));
      // Upstream's breakpoint puts `position: start` on the earlier grid row.
      expect(secondaryRect.top, lessThan(primaryRect.top));
      expect(
        primaryRect.top - secondaryRect.bottom,
        variant.part('Footer').gap,
      );
    });

    testWidgets('the close button is a subtle icon-only FluentButton', (
      tester,
    ) async {
      await pump(tester, open: true, title: const Text('Title'));

      final close = tester.widget<FluentButton>(find.byType(FluentButton).last);
      expect(close.appearance, FluentButtonAppearance.subtle);
      expect(close.size, FluentButtonSize.medium);
      expect(close.child, isNull);
      expect(close.semanticLabel, 'Close');
      expect((close.icon! as Icon).icon, fluentDialogCloseIcon);
    });
  });

  group('long content', () {
    /// Regression: the surface used to be a `Column(mainAxisSize: min)` with no
    /// height cap and no scrollable, so a body taller than the viewport was a
    /// RenderFlex overflow. Upstream caps `DialogSurface` at
    /// `maxHeight: ['100vh', '100dvh']` and gives `DialogContent`
    /// `overflowY: 'auto'` — probed on components-dialog--scrolling-long-content
    /// at 1200x800: surface 600x800, content 554x680 with scrollHeight 2158.
    testWidgets(
      'a body taller than the viewport scrolls instead of overflowing',
      (tester) async {
        const tall = Key('tall');
        await tester.pumpWidget(
          FluentApp(
            theme: light(),
            home: const FluentDialog(
              open: true,
              semanticLabel: 'Long',
              title: Text('Title'),
              actions: <Widget>[FluentButton(key: primary, child: Text('OK'))],
              content: SizedBox(height: 2000, key: tall),
              child: SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // The whole surface stays inside the 800x600 test viewport…
        final surface = tester.getRect(find.byType(FluentDialog).last);
        expect(surface.height, lessThanOrEqualTo(600));

        // …the body is the part that gave way, not the title or the actions…
        expect(tester.getSize(find.byKey(tall)).height, 2000);
        expect(find.byType(Scrollable), findsWidgets);

        // …and both ends of the frame are still on screen and in order.
        final title = tester.getRect(find.text('Title'));
        final action = tester.getRect(find.byKey(primary));
        expect(title.top, greaterThanOrEqualTo(0));
        expect(action.bottom, lessThanOrEqualTo(600));
        expect(title.bottom, lessThan(action.top));
      },
    );
  });

  group('motion', () {
    test('the specs are upstream verbatim', () {
      // DialogSurfaceMotion.ts: Scale with outScale 0.85, durationGentle both
      // ways, curveDecelerateMid in and curveAccelerateMin out.
      expect(fluentDialogSurfaceEnter.duration, FluentDuration.gentle);
      expect(fluentDialogSurfaceEnter.curve, FluentCurve.decelerateMid);
      expect(fluentDialogSurfaceExit.duration, FluentDuration.gentle);
      expect(fluentDialogSurfaceExit.curve, FluentCurve.accelerateMin);
      expect(fluentDialogOutScale, 0.85);
      // DialogBackdropMotion.ts is FadeRelaxed: Fade at durationGentle, keeping
      // Fade's default curveEasyEase and its symmetric exit.
      expect(fluentDialogScrim.duration, FluentDuration.gentle);
      expect(fluentDialogScrim.curve, FluentCurve.easyEase);
    });

    testWidgets('the surface scales up from 0.85 and fades in over 250ms', (
      tester,
    ) async {
      final theme = light();
      final open = await pump(tester, theme: theme);
      await setOpen(tester, open, value: true);

      expect(surfaceScale(tester), closeTo(fluentDialogOutScale, 0.001));
      expect(surfaceOpacity(tester), closeTo(0, 0.001));

      await tester.pump(const Duration(milliseconds: 125));
      final halfway = FluentCurve.decelerateMid.transform(0.5);
      expect(
        surfaceScale(tester),
        closeTo(
          fluentDialogOutScale + (1 - fluentDialogOutScale) * halfway,
          0.01,
        ),
      );
      expect(surfaceOpacity(tester), closeTo(halfway, 0.01));
      // The scrim runs the same length on a different curve, so the two are
      // genuinely out of step in the middle.
      expect(
        scrimOpacity(tester, theme),
        closeTo(FluentCurve.easyEase.transform(0.5), 0.01),
      );

      await tester.pump(const Duration(milliseconds: 125));
      expect(surfaceScale(tester), closeTo(1, 0.001));
      expect(surfaceOpacity(tester), closeTo(1, 0.001));
      expect(scrimOpacity(tester, theme), closeTo(1, 0.001));
    });

    testWidgets('the exit accelerates over 250ms and only then unmounts', (
      tester,
    ) async {
      final open = await pump(tester, open: true);
      await tester.pumpAndSettle();

      await setOpen(tester, open, value: false);
      // Still mounted, and on its way out rather than gone.
      expect(find.byKey(body), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 125));
      final halfway = FluentCurve.accelerateMin.transform(0.5);
      expect(
        surfaceScale(tester),
        closeTo(
          fluentDialogOutScale + (1 - fluentDialogOutScale) * halfway,
          0.01,
        ),
      );

      await tester.pump(const Duration(milliseconds: 130));
      await tester.pump();
      expect(find.byKey(body), findsNothing);
    });

    testWidgets('reduced motion jumps straight to the end state', (
      tester,
    ) async {
      final theme = light();
      final open = await pump(tester, theme: theme, reducedMotion: true);
      await setOpen(tester, open, value: true);

      // No frame of travel at all: the very first frame is the end state.
      expect(surfaceScale(tester), 1.0);
      expect(surfaceOpacity(tester), 1.0);
      expect(scrimOpacity(tester, theme), 1.0);

      await setOpen(tester, open, value: false);
      // And gone on the frame it was asked to close, with nothing left
      // scheduled.
      expect(find.byKey(body), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('theme', () {
    testWidgets('a FluentThemeOverride on the trigger reaches the surface', (
      tester,
    ) async {
      const pink = Color(0xFFFF00FF);
      await pump(
        tester,
        open: true,
        wrap: (child) => FluentThemeOverride(
          colors: const <FluentColorToken, Color>{
            FluentColorToken.neutralBackground1: pink,
          },
          child: child,
        ),
      );

      expect(decorationOf(tester).color, pink);
    });

    testWidgets('a FluentDialogTheme on the trigger reaches the surface', (
      tester,
    ) async {
      await pump(
        tester,
        open: true,
        wrap: (child) => FluentDialogTheme(
          style: FluentDialogStyle.from(borderRadius: FluentRadius.allSmall),
          child: child,
        ),
      );

      expect(decorationOf(tester).borderRadius, FluentRadius.allSmall);
    });

    testWidgets('the widget style is merged last and wins', (tester) async {
      await pump(
        tester,
        open: true,
        style: FluentDialogStyle.from(maxWidth: 400),
        wrap: (child) => FluentDialogTheme(
          style: FluentDialogStyle.from(maxWidth: 500),
          child: child,
        ),
      );

      expect(tester.getSize(surface()).width, 400);
    });

    testWidgets('an override arriving while open repaints the surface', (
      tester,
    ) async {
      // The style is resolved against the trigger's context, which is a
      // different branch from the overlay's; a theme swap has to travel.
      final open = await pump(tester, open: true);
      expect(decorationOf(tester).color, light().colors.neutralBackground1);

      final dark = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      await pump(tester, open: true, theme: dark);
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, dark.colors.neutralBackground1);
      expect(open.value, isTrue);
    });
  });

  group('high contrast', () {
    final highContrast = FluentThemeData.highContrast(
      fontPlatform: FluentFontPlatform.web,
    );

    testWidgets('the surface keeps a visible border', (tester) async {
      await pump(tester, open: true, theme: highContrast);

      final border = decorationOf(tester).border!.top;
      expect(border.width, FluentStroke.thin);
      // Figma paints no stroke at all; upstream's transparent one is what turns
      // opaque here, and without it a dialog has no outline in forced colours.
      expect(border.color, highContrast.colors.transparentStroke);
      expect(border.color.a, 1.0);
    });

    testWidgets('the scrim is a token and never transparent', (tester) async {
      await pump(tester, open: true, theme: highContrast);
      await tester.pumpAndSettle();

      expect(scrim(highContrast), findsOneWidget);
      final colour = tester.widget<ColoredBox>(scrim(highContrast)).color;
      expect(colour, highContrast.colors.backgroundOverlay);
      expect(colour.a, greaterThan(0));
      // Not Colors.transparent by any other name.
      expect(colour, isNot(const Color(0x00000000)));
    });

    testWidgets('the title stays on a foreground token', (tester) async {
      await pump(
        tester,
        open: true,
        theme: highContrast,
        title: const Text('T'),
      );

      final title = tester.widget<RichText>(
        find.descendant(of: surface(), matching: find.byType(RichText)).first,
      );
      expect(title.text.style!.color, highContrast.colors.neutralForeground1);
    });
  });

  group('modal type', () {
    testWidgets('modal and alert paint a scrim, nonModal does not', (
      tester,
    ) async {
      final theme = light();
      for (final entry in <FluentDialogModalType, bool>{
        FluentDialogModalType.modal: true,
        FluentDialogModalType.alert: true,
        FluentDialogModalType.nonModal: false,
      }.entries) {
        await pump(tester, open: true, modalType: entry.key, theme: theme);
        await tester.pumpAndSettle();
        expect(
          scrim(theme),
          entry.value ? findsOneWidget : findsNothing,
          reason: '${entry.key}',
        );
      }
    });

    testWidgets('a click on the scrim closes modal but not alert', (
      tester,
    ) async {
      final theme = light();
      final open = await pump(tester, open: true, theme: theme);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(open.value, isFalse);

      final alert = await pump(
        tester,
        open: true,
        theme: theme,
        modalType: FluentDialogModalType.alert,
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(alert.value, isTrue);
      expect(find.byKey(body), findsOneWidget);
    });
  });

  group('keyboard and focus', () {
    testWidgets('Escape closes a modal dialog and returns focus', (
      tester,
    ) async {
      final open = await pump(tester, open: false);
      final triggerNode = Focus.of(
        tester.element(find.byKey(trigger)),
        scopeOk: true,
      );
      await tester.pump();
      final before = FocusManager.instance.primaryFocus;
      expect(before, isNotNull);

      await setOpen(tester, open, value: true);
      await tester.pumpAndSettle();
      // Focus moved into the dialog, so it is no longer on the trigger.
      expect(FocusManager.instance.primaryFocus, isNot(before));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(open.value, isFalse);
      expect(find.byKey(body), findsNothing);
      expect(FocusManager.instance.primaryFocus, before);
      expect(triggerNode, isNotNull);
    });

    testWidgets('Escape closes a nonModal dialog, which never took focus', (
      tester,
    ) async {
      final open = await pump(
        tester,
        modalType: FluentDialogModalType.nonModal,
      );
      final before = FocusManager.instance.primaryFocus;

      await setOpen(tester, open, value: true);
      await tester.pumpAndSettle();
      // Nothing moved, so there is nothing to give back.
      expect(FocusManager.instance.primaryFocus, before);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(open.value, isFalse);
    });

    testWidgets('Tab is trapped inside a modal dialog', (tester) async {
      await pump(
        tester,
        open: true,
        title: const Text('Title'),
        actions: <Widget>[action(primary, 'A'), action(secondary, 'B')],
      );
      await tester.pumpAndSettle();

      // BlockSemantics is only ever added by a trapping dialog, so "is the
      // focused element inside one" is exactly "is focus still in the dialog".
      bool insideDialog() {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context == null) return false;
        var found = false;
        context.visitAncestorElements((element) {
          if (element.widget is BlockSemantics) {
            found = true;
            return false;
          }
          return true;
        });
        return found;
      }

      expect(insideDialog(), isTrue, reason: 'opening moved focus in');

      // Walk further than there are stops, so a leak is caught wherever in the
      // ring it happens — including the wrap-around back past the trigger.
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(insideDialog(), isTrue, reason: 'tab $i');
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(insideDialog(), isTrue, reason: 'shift+tab $i');
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    });

    testWidgets('a nonModal dialog does not block semantics or trap Tab', (
      tester,
    ) async {
      await pump(
        tester,
        open: true,
        modalType: FluentDialogModalType.nonModal,
        actions: <Widget>[action(primary, 'A')],
      );
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byKey(body),
          matching: find.byType(BlockSemantics),
        ),
        findsNothing,
      );
      // Focus is still on the trigger, so Tab moves on through the app rather
      // than round a ring of the dialog's own.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNotNull);
    });
  });

  group('disabled', () {
    testWidgets('a null onOpenChange disables the close button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        open: true,
        dismissible: false,
        title: const Text('Title'),
      );

      final close = tester.widget<FluentButton>(find.byType(FluentButton).last);
      expect(close.onPressed, isNull);

      // A real disabled state, not a greyed-out one: no tap action reaches the
      // semantics tree, so a screen reader cannot offer it.
      expect(
        tester.getSemantics(find.byType(FluentButton).last),
        matchesSemantics(label: 'Close', isButton: true, hasEnabledState: true),
      );
      handle.dispose();
    });

    testWidgets('a non-dismissible dialog ignores Escape and the scrim', (
      tester,
    ) async {
      final theme = light();
      await pump(tester, open: true, dismissible: false, theme: theme);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(body), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byKey(body), findsOneWidget);
    });

    testWidgets('showCloseButton false removes the affordance entirely', (
      tester,
    ) async {
      await pump(
        tester,
        open: true,
        showCloseButton: false,
        title: const Text('Title'),
      );

      // Only the trigger is left.
      expect(find.byType(FluentButton), findsOneWidget);
      expect(find.byKey(trigger), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('a modal dialog scopes and names its route', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, open: true, title: const Text('Title'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Confirm'),
        findsOneWidget,
        reason: 'the dialog names itself for assistive technology',
      );
      // scopesRoute + BlockSemantics is what stops a screen reader wandering
      // into the page behind.
      expect(
        find.ancestor(
          of: find.byKey(body),
          matching: find.byType(BlockSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the recomposition contract renders the same surface', (
      tester,
    ) async {
      // buildFluentDialog takes the BASE state, so a consumer can bring their
      // own style and keep Fluent's layout.
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Builder(
            builder: (context) {
              const base = FluentDialogBaseState(
                content: Text('Body', key: body),
                actions: <Widget>[],
                secondaryActions: <Widget>[],
                stackActions: false,
              );
              final state = resolveFluentDialogState(
                content: const Text('Body'),
              );
              return Center(
                child: buildFluentDialog(
                  base,
                  resolveFluentDialogStyle(state, FluentTheme.of(context)),
                  const <WidgetState>{},
                ),
              );
            },
          ),
        ),
      );

      expect(tester.getSize(surface()).width, 600);
      expect(decorationOf(tester).borderRadius, FluentRadius.allXLarge);
    });
  });

  group('lifecycle', () {
    // Regression: the controller and both curves used to be `late final` field
    // initialisers, so they were CONSTRUCTED on first read — and dispose() reads
    // all of them. A dialog that was never opened therefore built an
    // AnimationController(vsync: this) while unmounting, and createTicker looked
    // up TickerMode on a deactivated element.
    testWidgets('a dialog that never opened unmounts cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        FluentTheme(
          data: light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(initialEntries: <OverlayEntry>[_DialogEntry()]),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('style plumbing', () {
    test('merge is per-property and copyWith round-trips', () {
      const base = FluentDialogStyle(
        gap: WidgetStatePropertyAll<double?>(1),
        actionsGap: WidgetStatePropertyAll<double?>(2),
      );
      const over = FluentDialogStyle(gap: WidgetStatePropertyAll<double?>(9));

      final merged = base.merge(over);
      expect(merged.gap!.resolve(const <WidgetState>{}), 9);
      expect(merged.actionsGap!.resolve(const <WidgetState>{}), 2);

      expect(base.merge(null), base);
      expect(base.copyWith(), base);
      expect(base.copyWith().hashCode, base.hashCode);
      expect(
        FluentDialogStyle.from(gap: 4).gap!.resolve(const <WidgetState>{}),
        4,
      );
    });
  });
}

/// An [OverlayEntry] subclass so the never-opened dialog can be declared const
/// inside the test above.
class _DialogEntry extends OverlayEntry {
  _DialogEntry()
    : super(
        builder: (BuildContext context) => const FluentDialog(
          open: false,
          content: Text('body'),
          child: SizedBox.shrink(),
        ),
      );
}
