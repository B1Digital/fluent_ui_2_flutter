import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Toast's twenty sections are all imperative: every one of them is a button
/// that has to put a surface into an overlay, and most carry a knob that has to
/// change what lands there. So these tests press the button and then read the
/// *overlay* — a demo whose radio moves and whose toast does not is the exact
/// failure this page is most exposed to, because the toast is built in a
/// closure that runs long after the knob was turned.
void main() {
  const String page = 'components-toast';

  group('default', () {
    final DocsSection section = sectionOf('components-toast--default');

    testWidgets('the button raises a toast with every slot filled', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentToast), findsNothing);

      await tapAndSettle(tester, find.text('Make toast'));

      expect(find.byType(FluentToast), findsOneWidget);
      expect(find.text('Email sent'), findsOneWidget);
      expect(find.text('This is a toast body'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Action'), findsNWidgets(2));
      // type: action puts the link in the end slot, which means no dismiss
      // button — a toast rendering both would be wearing two end slots.
      expect(find.byIcon(FluentIcons.dismiss_20_regular), findsNothing);
    });

    testWidgets('the toast takes itself down after the default timeout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Make toast'));

      await tester.pump(const Duration(milliseconds: 2000));
      expect(
        find.byType(FluentToast),
        findsOneWidget,
        reason: 'the countdown is 3000ms; the toast cannot be gone at 2200',
      );

      await waitOut(tester, fluentToastTimeout);
      expect(
        find.byType(FluentToast),
        findsNothing,
        reason: 'an un-dismissed toast must expire on its own',
      );
    });

    testWidgets('the button raises a toast under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Make toast'));
      expect(
        find.byType(FluentToast),
        findsOneWidget,
        reason: 'a mouse press must reach the button, not the page under it',
      );
    });
  });

  group('intent', () {
    final DocsSection section = sectionOf('components-toast--intent');

    testWidgets('the intent radio picks the glyph the toast is built with', (
      WidgetTester tester,
    ) async {
      // One intent per mount, and a real teardown between them. Two reasons,
      // both about the demo rather than the toast: `pumpWidget` with the same
      // widget tree UPDATES the existing elements, so the demo's controller and
      // its queued toasts survive what looks like a remount; and every toast on
      // this section is built from a closure over `_intentValue`, so a toast
      // left over from the previous intent re-titles itself when the radio
      // moves and there are suddenly two toasts claiming the same intent.
      const Map<String, IconData> glyphs = <String, IconData>{
        'success': FluentIcons.checkmark_circle_20_filled,
        'info': FluentIcons.info_20_regular,
        'warning': FluentIcons.warning_20_filled,
        'error': FluentIcons.error_circle_20_filled,
      };

      for (final MapEntry<String, IconData> intent in glyphs.entries) {
        await expectCleanTeardown(tester, 'the previous intent');
        await pumpSection(tester, section);
        await tapAndSettle(tester, find.text(intent.key), what: intent.key);
        await tapAndSettle(tester, find.text('Make toast'));

        expect(
          find.text('Toast intent: ${intent.key}'),
          findsOneWidget,
          reason: '${intent.key}: the radio did not reach the toast title',
        );
        expect(
          find.descendant(
            of: find.byType(FluentToast),
            matching: find.byIcon(intent.value),
          ),
          findsOneWidget,
          reason: '${intent.key}: the radio did not reach the toast glyph',
        );
      }
    });

    testWidgets('the two custom media slots replace the glyph outright', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('progress (custom media slot)'));
      await tapAndSettle(tester, find.text('Make toast'));

      expect(find.text('Progress toast'), findsOneWidget);
      // Not pumpAndSettle anywhere near this: the spinner turns forever.
      expect(
        find.descendant(
          of: find.byType(FluentToast),
          matching: find.byType(FluentSpinner),
        ),
        findsOneWidget,
      );

      await tapAndSettle(tester, find.text('avatar (custom media slot)'));
      await tapAndSettle(tester, find.text('Make toast'));
      expect(find.text('Avatar toast'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FluentToast),
          matching: find.byType(FluentAvatar),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the intent radio commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('warning'));
      expect(
        tester
            .widget<FluentRadioGroup<String>>(
              find.byType(FluentRadioGroup<String>),
            )
            .value,
        'warning',
        reason: 'a mouse press on a radio row must commit, not just light it',
      );
    });
  });

  group('inverted appearance', () {
    testWidgets('the toast wears the static surface tokens', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-toast--inverted-appearance'),
      );
      final FluentColors colors = FluentTheme.of(
        tester.element(find.byType(FluentButton)),
      ).colors;

      await tapAndSettle(tester, find.text('Make toast'));
      // The inverted look is the whole section: a style that never reached the
      // builder would leave a normal toast reading "Email sent".
      expect(
        fillOf(tester, find.byType(FluentToast))?.color,
        colors.neutralBackgroundStatic,
      );
    });
  });

  group('default toast options', () {
    final DocsSection section = sectionOf(
      'components-toast--default-toast-options',
    );

    testWidgets('the configured position and timeout both apply', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Make toast'));

      final Rect overlay = tester.getRect(find.byType(Overlay).first);
      final Rect toast = tester.getRect(find.byType(FluentToast));
      expect(
        toast.center.dy,
        lessThan(overlay.center.dy),
        reason: 'topEnd must put the toast in the top half',
      );
      expect(
        overlay.right - toast.right,
        closeTo(FluentSpacing.xl, 0.5),
        reason: 'topEnd must pin it to the trailing edge, one offset in',
      );

      // 1000ms, not the 3000ms default: the section exists to show that the
      // options travel with the dispatch.
      expect(find.byType(FluentToast), findsOneWidget);
      await waitOut(tester, const Duration(milliseconds: 1000));
      expect(find.byType(FluentToast), findsNothing);
    });
  });

  group('custom timeout', () {
    final DocsSection section = sectionOf('components-toast--custom-timeout');

    testWidgets('the spin button reaches the title and the clock', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        stepper(FluentSpinButtonStepperDirection.increase),
      );
      expect(
        tester.widget<FluentSpinButton>(find.byType(FluentSpinButton)).value,
        1500,
        reason: 'the step is 500ms',
      );

      await tapAndSettle(tester, find.text('Make toast'));
      expect(
        find.text('Custom timeout 1500ms'),
        findsOneWidget,
        reason: 'the knob has to reach the toast that is built after it moved',
      );

      // The number in the title is not the claim — the clock is. At 1200ms a
      // toast still running the old 1000ms default would already be gone.
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(FluentToast), findsOneWidget);
      await waitOut(tester, const Duration(milliseconds: 600));
      expect(find.byType(FluentToast), findsNothing);
    });

    testWidgets('a negative timeout never expires, and its action dismisses', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // 1000 down to -500, which is upstream's "negative timeout" and this
      // port's Duration.zero.
      for (int i = 0; i < 3; i++) {
        await tapAndSettle(
          tester,
          stepper(FluentSpinButtonStepperDirection.decrease),
        );
      }
      expect(
        tester.widget<FluentSpinButton>(find.byType(FluentSpinButton)).value,
        -500,
      );

      await tapAndSettle(tester, find.text('Make toast'));
      expect(find.text('Dismiss manually'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await settle(tester);
      expect(
        find.byType(FluentToast),
        findsOneWidget,
        reason: 'a never-expiring toast must survive six seconds of clock',
      );

      await tapAndSettle(tester, find.text('Dismiss'), what: 'the action link');
      await settleExit(tester);
      expect(
        find.byType(FluentToast),
        findsNothing,
        reason: 'the only way down for this toast is its own action',
      );
    });
  });

  group('dismiss toast with action', () {
    testWidgets('the action link takes its own toast down', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-toast--dismiss-toast-with-action'),
      );

      await tapAndSettle(tester, find.text('Make toast'));
      expect(find.text('Dismiss me'), findsOneWidget);

      await tapAndSettle(tester, find.text('Dismiss'), what: 'the action link');
      await settleExit(tester);
      expect(find.byType(FluentToast), findsNothing);
    });
  });

  group('toast positions', () {
    final DocsSection section = sectionOf('components-toast--toast-positions');

    testWidgets('the position radio moves where the toast lands', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect overlay = tester.getRect(find.byType(Overlay).first);

      await tapAndSettle(tester, find.text('Make toast'));
      final Rect top = tester.getRect(find.byType(FluentToast));
      expect(top.center.dy, lessThan(overlay.center.dy));
      expect(
        top.center.dx,
        closeTo(overlay.center.dx, 1),
        reason: 'top is a centred position',
      );

      // A fresh mount per position: the demo keeps its controller across a
      // pumpWidget of the same tree, and a leftover toast would be measured
      // instead of the new one.
      await expectCleanTeardown(tester, 'the top dispatch');
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('bottom-start'));
      await tapAndSettle(tester, find.text('Make toast'));

      final Rect bottomStart = tester.getRect(find.byType(FluentToast));
      expect(
        bottomStart.center.dy,
        greaterThan(overlay.center.dy),
        reason: 'the radio did not reach the dispatch',
      );
      expect(
        bottomStart.left - overlay.left,
        closeTo(FluentSpacing.xl, 0.5),
        reason: 'a start-anchored stack sits one horizontal offset in',
      );
    });

    testWidgets('a standing toast keeps the position it was dispatched with', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, find.text('Make toast'));
      final Rect dispatched = tester.getRect(find.byType(FluentToast));
      expect(find.text('This toast is top'), findsOneWidget);

      await tapAndSettle(tester, find.text('bottom-end'));
      // The entry captured its position at dispatch, so the surface correctly
      // stays where it was raised...
      expect(
        tester.getRect(find.byType(FluentToast)),
        dispatched,
        reason: 'moving the radio must not move a toast that is already up',
      );
      // ...and its own label has to keep saying so. A toast pinned to the top
      // of the page reading "This toast is bottom-end" is the page telling the
      // reader something the page itself is disproving.
      expect(
        find.text('This toast is top'),
        findsOneWidget,
        reason:
            'the title states the position this toast was dispatched to, '
            'which the radio cannot retroactively change',
      );
    });
  });

  group('offset', () {
    final DocsSection section = sectionOf('components-toast--offset');

    testWidgets('both spin buttons move the toast that is already up', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect overlay = tester.getRect(find.byType(Overlay).first);

      await tapAndSettle(tester, find.text('Make toast'));
      Rect toast() => tester.getRect(find.byType(FluentToast));
      // The defaults the section ships: 20 horizontal, 16 vertical, bottom-end.
      expect(overlay.right - toast().right, closeTo(20, 0.5));
      expect(overlay.bottom - toast().bottom, closeTo(16, 0.5));

      // Pressed frame by frame rather than through `tapAndSettle`: nine
      // settles would spend three seconds of clock, and the toast being
      // measured only lives for three.
      await press(
        tester,
        stepper(
          FluentSpinButtonStepperDirection.increase,
          within: fieldOf('Vertical offset'),
        ),
        times: 4,
      );
      expect(
        overlay.bottom - toast().bottom,
        closeTo(20, 0.5),
        reason:
            'the offset lives on the toaster, so a live toast must move '
            'with it',
      );

      await press(
        tester,
        stepper(
          FluentSpinButtonStepperDirection.decrease,
          within: fieldOf('Horizontal offset'),
        ),
        times: 5,
      );
      expect(overlay.right - toast().right, closeTo(15, 0.5));

      await tapAndSettle(tester, find.text('Make toast'));
      // Both of them: the offset is a property of the toaster rather than of a
      // dispatch, so the toast raised before the knobs moved is drawn at the
      // new inset too and its title says so truthfully.
      expect(
        find.text('Offset: 15, 20'),
        findsNWidgets(2),
        reason: 'the two knobs must also reach the title of the next toast',
      );
    });

    testWidgets('the position radio anchors the offset to another corner', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect overlay = tester.getRect(find.byType(Overlay).first);

      await tapAndSettle(tester, find.text('top-start'));
      await tapAndSettle(tester, find.text('Make toast'));

      // The same two numbers, measured from the opposite corner: an offset
      // applied to one fixed edge would leave this toast 20 from the right.
      final Rect toast = tester.getRect(find.byType(FluentToast));
      expect(toast.left - overlay.left, closeTo(20, 0.5));
      expect(toast.top - overlay.top, greaterThanOrEqualTo(16));
      expect(toast.center.dy, lessThan(overlay.center.dy));
    });
  });

  group('dismiss toast', () {
    testWidgets('the button turns into its own dismiss control', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--dismiss-toast'));

      await tapAndSettle(tester, find.text('Make toast'));
      expect(find.text('This is a toast'), findsOneWidget);
      expect(
        find.text('Dismiss toast'),
        findsOneWidget,
        reason: 'the demo reads its own queue, so the button has to relabel',
      );

      await tapAndSettle(tester, find.text('Dismiss toast'));
      await settleExit(tester);
      expect(find.byType(FluentToast), findsNothing);
      expect(
        find.text('Make toast'),
        findsOneWidget,
        reason: 'the label must round-trip once the toast has unmounted',
      );
    });
  });

  group('update toast', () {
    testWidgets('updating replaces the toast in place', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--update-toast'));

      await tapAndSettle(tester, find.text('Make toast'));
      expect(find.text('This toast never closes'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await settle(tester);
      expect(
        find.text('This toast never closes'),
        findsOneWidget,
        reason: 'a Duration.zero timeout must not expire',
      );

      await tapAndSettle(tester, find.text('Update toast'));
      expect(find.text('This toast never closes'), findsNothing);
      expect(find.text('This toast will close soon'), findsOneWidget);
      expect(
        find.byType(FluentToast),
        findsOneWidget,
        reason:
            'an update keeps the toast\'s slot rather than stacking a '
            'second one',
      );

      // The update carries a 2000ms timeout with it, so the replaced toast now
      // has a clock where it had none.
      await waitOut(tester, const Duration(milliseconds: 2000));
      expect(find.byType(FluentToast), findsNothing);
      expect(find.text('Make toast'), findsOneWidget);
    });
  });

  group('progress toast', () {
    testWidgets('the bar ticks down and dismisses the toast when it lands', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--progress-toast'));

      await tapAndSettle(tester, find.text('Make toast'));
      expect(find.text('Downloading file'), findsOneWidget);
      double progress() => tester
          .widget<FluentProgressBar>(find.byType(FluentProgressBar))
          .value!;
      expect(progress(), closeTo(1, 0.15));
      expect(
        tester.widget<FluentButton>(find.byType(FluentButton).first).onPressed,
        isNull,
        reason: 'the demo disables its trigger while its toast is up',
      );

      await tester.pump(const Duration(milliseconds: 1000));
      expect(
        progress(),
        lessThan(0.6),
        reason:
            'the bar has to tick on its own — the point of the section is '
            'that the toast is not re-dispatched to move it',
      );

      // 2000ms total run, then the toast dismisses itself from the bar's own
      // onEnd rather than from a timeout.
      await tester.pump(const Duration(milliseconds: 1200));
      await settleExit(tester);
      expect(find.byType(FluentToast), findsNothing);
      expect(
        tester.widget<FluentButton>(find.byType(FluentButton).first).onPressed,
        isNotNull,
      );
    });
  });

  group('dismiss all', () {
    testWidgets('one press clears the whole stack', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--dismiss-all'));

      for (int i = 1; i <= 3; i++) {
        await tapAndSettle(tester, find.text('Make toast'));
        expect(find.byType(FluentToast), findsNWidgets(i));
      }

      await tapAndSettle(tester, find.text('Dismiss all toasts'));
      await settleExit(tester);
      expect(find.byType(FluentToast), findsNothing);
    });
  });

  group('pause and play', () {
    testWidgets('pausing holds the toast up and playing lets it expire', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--pause-and-play'));

      await tapAndSettle(tester, find.text('Make toast'));
      await tester.pump(const Duration(milliseconds: 1000));

      await tapAndSettle(tester, find.text('Pause toast'));
      expect(
        find.text('Play toast'),
        findsOneWidget,
        reason: 'the control has to say what it will do next',
      );
      await tester.pump(const Duration(seconds: 6));
      await settle(tester);
      expect(
        find.byType(FluentToast),
        findsOneWidget,
        reason: 'a paused toast must outlive twice its own timeout',
      );

      await tapAndSettle(tester, find.text('Play toast'));
      await waitOut(tester, fluentToastTimeout);
      expect(
        find.byType(FluentToast),
        findsNothing,
        reason: 'playing must restart the clock it paused',
      );
      expect(find.text('Make toast'), findsOneWidget);
    });
  });

  group('pause on hover', () {
    testWidgets('a resting pointer holds the countdown, leaving resumes it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--pause-on-hover'));

      await tapAndSettle(tester, find.text('Make toast'));
      expect(find.text('Hover me!'), findsOneWidget);

      // The section's entire claim, and one no synthetic tap can reach: the
      // pointer has to actually be inside the surface.
      final TestGesture mouse = await mouseHover(
        tester,
        find.byType(FluentToast),
        dwell: const Duration(seconds: 6),
      );
      expect(
        find.byType(FluentToast),
        findsOneWidget,
        reason: 'the countdown must stop while the pointer rests on the toast',
      );

      await mouseAway(tester, mouse);
      await waitOut(tester, fluentToastTimeout);
      expect(
        find.byType(FluentToast),
        findsNothing,
        reason: 'the countdown must resume once the pointer leaves',
      );
    });
  });

  group('pause on window blur', () {
    testWidgets('the toast appears and expires on its own clock', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-toast--pause-on-window-blur'),
      );

      await tapAndSettle(tester, find.text('Make toast'));
      expect(find.text('Click on another window!'), findsOneWidget);

      // There is no window-blur pause in this port — the page says so — so the
      // observable contract here is the plain countdown.
      await waitOut(tester, fluentToastTimeout);
      expect(find.byType(FluentToast), findsNothing);
    });
  });

  group('toast lifecycle', () {
    testWidgets('the log records visible, dismissed and unmounted', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--toast-lifecycle'));
      expect(find.textContaining('visible'), findsNothing);

      await tapAndSettle(tester, find.text('Make toast'));
      expect(
        find.textContaining('visible'),
        findsOneWidget,
        reason: 'raising a toast must log its first stage',
      );

      await waitOut(tester, const Duration(milliseconds: 1000));
      expect(
        find.textContaining('dismissed'),
        findsOneWidget,
        reason: 'the expiry stage is invisible unless the queue reports it',
      );
      expect(find.textContaining('unmounted'), findsOneWidget);

      await tapAndSettle(tester, find.text('Clear log'));
      expect(find.textContaining('visible'), findsNothing);
      expect(find.textContaining('unmounted'), findsNothing);
    });
  });

  group('multiple toasters', () {
    testWidgets('the radio chooses which toaster answers', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-toast--multiple-toasters'),
      );

      await tapAndSettle(tester, find.text('Make toast'));
      final Rect first = toastRect(tester, 'First toaster');

      // The radio labels carry the same two strings as the toast titles, so
      // every assertion here has to be scoped to the overlay surface.
      await tapAndSettle(
        tester,
        find.text('Second toaster').first,
        what: 'the second toaster radio',
      );
      await tapAndSettle(tester, find.text('Make toast'));
      final Rect second = toastRect(tester, 'Second toaster');

      expect(
        second.center.dy,
        lessThan(first.center.dy),
        reason:
            'the second toaster is dispatched topEnd, the first bottomEnd '
            '— a single shared queue would stack them together',
      );
      expect(
        find.descendant(
          of: find.byType(FluentToast),
          matching: find.text('First toaster'),
        ),
        findsOneWidget,
        reason: 'the first toaster\'s toast must still be up',
      );
    });
  });

  group('toaster limit', () {
    testWidgets('the limit knob caps how many toasts stay up', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--toaster-limit'));

      for (int i = 0; i < 5; i++) {
        await tapAndSettle(tester, find.text('Make toast'));
      }
      await settleExit(tester);
      expect(
        find.byType(FluentToast),
        findsNWidgets(3),
        reason: 'five dispatches under a limit of three must leave three',
      );

      for (int i = 0; i < 2; i++) {
        await tapAndSettle(
          tester,
          stepper(FluentSpinButtonStepperDirection.decrease),
        );
      }
      expect(
        tester.widget<FluentSpinButton>(find.byType(FluentSpinButton)).value,
        1,
      );

      await tapAndSettle(tester, find.text('Make toast'));
      await settleExit(tester);
      expect(
        find.byType(FluentToast),
        findsOneWidget,
        reason: 'lowering the limit has to take effect on the next dispatch',
      );
    });
  });

  group('focus keyboard shortcut', () {
    testWidgets('the focus button reaches the most recent toast', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-toast--focus-keyboard-shortcut'),
      );

      await tapAndSettle(tester, find.text('Make toast'));
      await tapAndSettle(tester, find.text('Focus most recent toast'));
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Toast',
        reason: 'the section exists to move focus onto the toast',
      );

      // Escape on the focused toast is the affordance the section leans on
      // once focus has arrived there.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleExit(tester);
      expect(find.byType(FluentToast), findsNothing);
    });
  });

  group('inline', () {
    testWidgets('the toast lands inside the section\'s own box', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toast--inline'));

      // Two overlays: the app's and the one Overlay.wrap gives the box. The
      // nested one is deeper, so it comes second in tree order.
      expect(find.byType(Overlay), findsNWidgets(2));
      final Rect box = tester.getRect(find.byType(Overlay).last);
      expect(box.size, const Size(500, 500));

      await tapAndSettle(tester, find.text('Make toast'));
      final Rect toast = tester.getRect(find.byType(FluentToast));

      // "Positioned relative to the closest positioned ancestor": a toast that
      // went to the app's overlay would sit at the page edge instead.
      expect(
        box.contains(toast.topLeft),
        isTrue,
        reason: 'toast $toast escaped $box',
      );
      expect(box.contains(toast.bottomRight - const Offset(1, 1)), isTrue);
      expect(
        toast.center.dx,
        closeTo(box.center.dx, 1),
        reason: 'the dispatch asks for the bottom-centre of its own overlay',
      );
    });
  });

  group('every section', () {
    testWidgets('raises a toast when its button is pressed', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await tapAndSettle(
          tester,
          find.text('Make toast'),
          what: '${section.id} Make toast',
        );
        expect(
          find.byType(FluentToast),
          findsAtLeastNWidgets(1),
          reason: '${section.id}: pressing Make toast raised nothing',
        );
        await expectCleanTeardown(tester, '${section.id} with a toast up');
      }
    });

    testWidgets('unmounts without throwing', (WidgetTester tester) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// Runs the clock past a toast's [timeout] and its exit motion.
///
/// The countdown is a ticker on the scheduler's clock rather than a timer, so
/// it only advances while frames are being pumped — and `pumpAndSettle` would
/// sit through the whole timeout of every toast on the page rather than
/// returning.
Future<void> waitOut(WidgetTester tester, Duration timeout) async {
  await tester.pump(timeout);
  await settleExit(tester);
}

/// Runs a dismissed toast's exit motion out, however it was dismissed.
///
/// Three frames, not one: the first carries the queue change that starts the
/// exit, the second is where the motion's ticker anchors its clock, and only
/// the third can be 600ms later. A single `pump(exitDuration)` looks like it
/// waits and actually advances the motion by nothing at all.
Future<void> settleExit(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(fluentToastExitDuration);
  await settle(tester);
}

/// The rect of the toast surface titled [title].
Rect toastRect(WidgetTester tester, String title) => tester.getRect(
  find.ancestor(of: find.text(title), matching: find.byType(FluentToast)).first,
);

/// One half of a spin button's stepper column, optionally scoped to one field.
///
/// A page carrying two spin buttons — Offset has a horizontal and a vertical —
/// needs the field's own label to tell them apart, since the steppers
/// themselves are identical and unlabelled.
Finder stepper(FluentSpinButtonStepperDirection direction, {Finder? within}) {
  final Finder half = find.byWidgetPredicate(
    (Widget widget) =>
        widget is FluentSpinButtonStepper && widget.direction == direction,
  );
  return within == null ? half : find.descendant(of: within, matching: half);
}

/// The field whose label reads [label].
Finder fieldOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(FluentField));

/// Presses [finder] [times] over, one frame each.
///
/// The clock is the constraint on this page: every settle spends 200ms of a
/// toast's 3000ms life, so a knob that needs nine presses cannot be driven with
/// [tapAndSettle] while the toast it moves is still up.
Future<void> press(
  WidgetTester tester,
  Finder finder, {
  required int times,
}) async {
  for (int i = 0; i < times; i++) {
    await tester.tap(finder.first);
    await tester.pump();
  }
  // One more frame than presses. A toaster cannot rebuild its overlay entry
  // from `didUpdateWidget` — that is a setState on an Overlay in another branch
  // of the tree, already built this frame — so it defers to a post-frame
  // callback and the surface catches up on the frame after the knob moved.
  await tester.pump();
  expectClean(tester, 'pressing ${finder.describeMatch(Plurality.one)}');
}
