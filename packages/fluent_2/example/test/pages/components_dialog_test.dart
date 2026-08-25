import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Dialog's eighteen sections are mostly one decision each — modal or not,
/// dismissible or not, close button or none, actions in a row or a column — so
/// most of these tests are about *which dismissal paths work*, which is the
/// only thing a dialog can get catastrophically wrong.
///
/// Three sections carry real knobs: Backdrop Appearance has a radio group in a
/// drawer, Actions gates its primary button behind a checkbox, and Motion
/// Custom has three sliders and a switch. Each of those gets its own test that
/// asserts the demo moved, not just the control.
void main() {
  const String page = 'components-dialog';

  /// The dialog's exit runs on `durationGentle`, and the entry is only removed
  /// once the controller reaches zero — so a bare `settle` leaves a closing
  /// dialog still in the tree and a test would read the wrong answer.
  Future<void> settleDialog(WidgetTester tester) async {
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
  }

  group('default', () {
    final DocsSection section = sectionOf('components-dialog--default');

    testWidgets('the trigger opens the dialog with its title and actions', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Dialog title'), findsNothing);

      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);
      expect(find.text('Dialog title'), findsOneWidget);
      expect(find.text('Do Something'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(
        find.byIcon(fluentDialogCloseIcon),
        findsOneWidget,
        reason: 'showCloseButton defaults to true, which is Figma over React',
      );
      // A modal dialog is centred in the viewport, not anchored to its trigger:
      // the surface has no spatial relationship to the button that opened it.
      expect(
        tester.getRect(dialogSurface).center.dx,
        closeTo(tester.view.physicalSize.width / 2, 1),
      );
    });

    testWidgets(
      'every dismissal path closes it: action, header, Escape, scrim',
      (WidgetTester tester) async {
        await pumpSection(tester, section);

        Future<void> reopen() async {
          await tapAndSettle(tester, find.text('Open dialog'));
          await settleDialog(tester);
          expect(find.text('Dialog title'), findsOneWidget);
        }

        await reopen();
        await tapAndSettle(tester, find.text('Close'));
        await settleDialog(tester);
        expect(find.text('Dialog title'), findsNothing, reason: 'Close action');

        await reopen();
        await tapAndSettle(tester, find.byIcon(fluentDialogCloseIcon));
        await settleDialog(tester);
        expect(
          find.text('Dialog title'),
          findsNothing,
          reason: 'header button',
        );

        await reopen();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settleDialog(tester);
        expect(find.text('Dialog title'), findsNothing, reason: 'Escape');

        await reopen();
        // The corner of the viewport: the surface is centred, so this is scrim.
        await tester.tapAt(const Offset(40, 1360));
        await settleDialog(tester);
        expect(find.text('Dialog title'), findsNothing, reason: 'scrim press');
      },
    );

    testWidgets('the trigger commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await mouseClick(tester, find.text('Open dialog'));
      await settleDialog(tester);
      expect(find.text('Dialog title'), findsOneWidget);
    });
  });

  group('non modal', () {
    testWidgets('no scrim is drawn and an outside press leaves it open', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--non-modal'));
      await tapAndSettle(tester, find.text('Open non-modal dialog'));
      await settleDialog(tester);

      expect(
        scrims(tester),
        isEmpty,
        reason:
            'a non-modal dialog paints no backdrop at all, which is what '
            'leaves the page behind interactive',
      );
      expect(
        find.text('Open non-modal dialog'),
        findsOneWidget,
        reason: 'the trigger stays reachable behind a non-modal dialog',
      );

      await tester.tapAt(const Offset(1500, 1360));
      await settleDialog(tester);
      expect(
        find.text('Non-modal dialog title'),
        findsOneWidget,
        reason: 'there is no backdrop to click, so nothing dismisses it',
      );

      // A non-modal dialog never takes focus — that is what leaves the page
      // behind usable — so Escape reaches it only through the copy of `Actions`
      // bound around the trigger, which needs the trigger focused. The
      // section's own description names the same caveat.
      await focusOn(
        tester,
        find.widgetWithText(FluentButton, 'Open non-modal dialog'),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDialog(tester);
      expect(
        find.text('Non-modal dialog title'),
        findsNothing,
        reason: 'Escape still closes a non-modal dialog',
      );
    });
  });

  group('alert', () {
    testWidgets('the scrim is drawn but refuses to dismiss; Escape does not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--alert'));
      await tapAndSettle(tester, find.text('Open Alert dialog'));
      await settleDialog(tester);
      expect(
        scrims(tester),
        hasLength(1),
        reason: 'alert still blocks the page behind a backdrop',
      );

      await tester.tapAt(const Offset(40, 1360));
      await settleDialog(tester);
      expect(
        find.text('Alert dialog title'),
        findsOneWidget,
        reason:
            'the whole point of alert: the backdrop does not answer for '
            'the user',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDialog(tester);
      expect(find.text('Alert dialog title'), findsNothing);
    });
  });

  group('backdrop appearance', () {
    testWidgets('the radio group swaps the dialog backdrop', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-dialog--backdrop-appearance'),
      );
      await tapAndSettle(tester, find.text('Open Drawer'));
      await tester.pump(const Duration(milliseconds: 600));

      // Default first. The drawer contributes a dimmed scrim of its own, so
      // "the dialog's backdrop" is the second one, and both being opaque is
      // exactly the stacked-dim the section is about.
      await tapAndSettle(tester, find.text('Open Dialog'));
      await settleDialog(tester);
      expect(scrims(tester), hasLength(2));
      expect(
        scrims(tester).where((Color c) => c.a == 0),
        isEmpty,
        reason: 'with no appearance chosen both layers dim',
      );

      await tapAndSettle(tester, find.text('Close'));
      await settleDialog(tester);

      // The page's primary knob, so this one is driven with a pointer.
      await mouseClick(tester, find.text('Transparent'));
      expect(
        tester
            .widget<FluentRadioGroup<String>>(
              find.byType(FluentRadioGroup<String>),
            )
            .value,
        'transparent',
      );
      await tapAndSettle(tester, find.text('Open Dialog'));
      await settleDialog(tester);
      expect(
        scrims(tester).where((Color c) => c.a == 0),
        hasLength(1),
        reason:
            'transparent has to clear the dialog\'s own backdrop, leaving '
            'only the drawer\'s: ${scrims(tester)}',
      );

      // Round trip.
      await tapAndSettle(tester, find.text('Close'));
      await settleDialog(tester);
      await tapAndSettle(tester, find.text('Dimmed'));
      await tapAndSettle(tester, find.text('Open Dialog'));
      await settleDialog(tester);
      expect(
        scrims(tester).where((Color c) => c.a == 0),
        isEmpty,
        reason: 'dimmed has to put the backdrop back',
      );
    });
  });

  group('scrolling long content', () {
    testWidgets('the body scrolls while the title and actions stay put', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-dialog--scrolling-long-content'),
      );
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);

      final ScrollableState body = tester.state<ScrollableState>(dialogBody);
      expect(
        body.position.maxScrollExtent,
        greaterThan(0),
        reason: 'ten paragraphs must overflow the viewport-capped surface',
      );

      final double titleBefore = tester.getRect(find.text('Dialog title')).top;
      final double actionsBefore = tester.getRect(find.text('Close')).top;
      final double paragraphBefore = tester
          .getRect(find.textContaining('Lorem ipsum').first)
          .top;

      await tester.drag(dialogBody, const Offset(0, -300));
      await settle(tester);
      expectClean(tester, 'scrolling the dialog body');

      expect(
        tester.getRect(find.textContaining('Lorem ipsum').first).top,
        lessThan(paragraphBefore),
        reason: 'the body has to move',
      );
      expect(
        tester.getRect(find.text('Dialog title')).top,
        titleBefore,
        reason: 'the title is outside the scrolling region',
      );
      expect(
        tester.getRect(find.text('Close')).top,
        actionsBefore,
        reason: 'so are the actions',
      );
    });
  });

  group('keep rendered in the dom', () {
    final DocsSection section = sectionOf(
      'components-dialog--keep-rendered-in-the-dom',
    );

    testWidgets('the body scrolls', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);

      final double before = tester
          .getRect(find.textContaining('Lorem ipsum').first)
          .top;
      await wheelOver(tester, dialogBody, 300);
      expect(
        tester.getRect(find.textContaining('Lorem ipsum').first).top,
        lessThan(before),
        reason:
            'eight paragraphs have to be reachable before "preserved '
            'between opens" means anything',
      );
    });

    testWidgets('reopening restores the scroll position', (
      WidgetTester tester,
    ) async {
      // The section's own promise, verbatim: "the scroll position will be
      // preserved when reopening the dialog". Upstream keeps the node mounted;
      // the port keeps a ScrollController instead, and this asserts the two
      // arrangements come to the same thing from the user's side — which is
      // the only reason the section exists.
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);

      await wheelOver(tester, dialogBody, 400);
      final double scrolled = tester
          .getRect(find.textContaining('Lorem ipsum').first)
          .top;

      await tapAndSettle(tester, find.text('Close'));
      await settleDialog(tester);
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);

      expect(
        tester.getRect(find.textContaining('Lorem ipsum').first).top,
        closeTo(scrolled, 1),
        reason:
            'a reopened dialog must show the same place in the body it was '
            'left at',
      );
    });
  });

  group('actions', () {
    testWidgets('Delete stays disabled until the checkbox is ticked', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--actions'));
      await tapAndSettle(tester, find.text('Open campaign dialog'));
      await settleDialog(tester);

      FluentButton delete() => tester.widget<FluentButton>(
        find.widgetWithText(FluentButton, 'Delete'),
      );
      expect(
        delete().onPressed,
        isNull,
        reason: 'an irreversible action starts unavailable',
      );

      // The section's only knob, so it is clicked rather than tapped.
      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(
        tester.widget<FluentCheckbox>(find.byType(FluentCheckbox)).checked,
        isTrue,
      );
      expect(
        delete().onPressed,
        isNotNull,
        reason: 'ticking the confirmation must arm Delete',
      );

      // Round trip: unticking has to disarm it again.
      await tapAndSettle(tester, find.byType(FluentCheckbox));
      expect(delete().onPressed, isNull);

      await tapAndSettle(tester, find.text('Cancel'));
      await settleDialog(tester);
      expect(find.text('Delete this campaign?'), findsNothing);
    });
  });

  group('fluid actions', () {
    testWidgets('the small size stacks the actions into a column', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--default'));
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);
      expect(
        tester.getRect(find.text('Do Something')).top,
        tester.getRect(find.text('Close')).top,
        reason: 'the default size lays its actions out in a row',
      );

      await pumpSection(tester, sectionOf('components-dialog--fluid-actions'));
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);

      final List<double> tops = <double>[
        tester.getRect(find.text('Do Something')).top,
        tester.getRect(find.text('Something Else').at(0)).top,
        tester.getRect(find.text('Something Else').at(1)).top,
        tester.getRect(find.text('Close')).top,
      ];
      expect(
        tops.toSet(),
        hasLength(4),
        reason: 'fluid stacks all four actions, so no two share a row: $tops',
      );
      for (int i = 1; i < tops.length; i++) {
        expect(tops[i], greaterThan(tops[i - 1]));
      }
      // The surface keeps the medium width; only the action layout changed.
      expect(tester.getRect(dialogSurface).width, closeTo(600, 1));
    });
  });

  group('no focusable element', () {
    testWidgets('neither dialog draws a close button, and Escape still works', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-dialog--no-focusable-element',
      );
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Open modal dialog'));
      await settleDialog(tester);
      expect(
        find.byIcon(fluentDialogCloseIcon),
        findsNothing,
        reason:
            'showCloseButton is off, which is what leaves the dialog with '
            'nothing focusable at all',
      );
      expect(find.text('✅ Escape key works'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDialog(tester);
      expect(find.text('✅ Escape key works'), findsNothing);

      await tapAndSettle(tester, find.text('Open non-modal dialog'));
      await settleDialog(tester);
      expect(find.byIcon(fluentDialogCloseIcon), findsNothing);
      // The non-modal half traps nothing, so Escape has to come from the
      // trigger — see the Non Modal group for why.
      await focusOn(
        tester,
        find.widgetWithText(FluentButton, 'Open non-modal dialog'),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDialog(tester);
      expect(find.text('✅ Escape key works'), findsNothing);
    });
  });

  group('controlling open and close', () {
    testWidgets('the dialog reopens after being closed', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-dialog--controlling-open-and-close',
      );
      await pumpSection(tester, section);
      for (int i = 0; i < 2; i++) {
        await tapAndSettle(tester, find.text('Open dialog'));
        await settleDialog(tester);
        expect(find.text('Dialog title'), findsOneWidget, reason: 'open $i');
        await tapAndSettle(tester, find.text('Close'));
        await settleDialog(tester);
        expect(find.text('Dialog title'), findsNothing, reason: 'close $i');
      }
    });
  });

  group('change focus', () {
    testWidgets('focus lands on the second action, not the first', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--change-focus'));
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);

      expect(
        focusIsInside(tester, find.widgetWithText(FluentButton, 'Close')),
        isTrue,
        reason: 'autofocus on the second action is the whole section',
      );
      expect(
        focusIsInside(
          tester,
          find.widgetWithText(FluentButton, 'Do Something'),
        ),
        isFalse,
        reason: 'and the first action is what it has to be taken away from',
      );
      expect(find.text('Third Action'), findsOneWidget);
    });
  });

  group('trigger outside dialog', () {
    testWidgets('a dialog with no trigger of its own opens from beside it', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-dialog--trigger-outside-dialog'),
      );
      final Finder opener = find.widgetWithText(FluentButton, 'Open Dialog');
      // Focused first, because focus return can only give back what something
      // was holding: the section's claim is that FluentDialog records the
      // primary focus on open, and a tap alone never puts it on the button.
      await focusOn(tester, opener);
      await tapAndSettle(tester, find.text('Open Dialog'));
      await settleDialog(tester);
      expect(find.text('Dialog title'), findsOneWidget);
      expect(
        focusIsInside(tester, opener),
        isFalse,
        reason: 'a modal dialog takes focus off the page behind it',
      );

      await tapAndSettle(tester, find.text('Close'));
      await settleDialog(tester);
      expect(
        focusIsInside(tester, opener),
        isTrue,
        reason:
            'focus return is the dialog\'s job even when `child` is an '
            'empty box',
      );
    });
  });

  group('custom trigger', () {
    testWidgets('a caller-supplied widget opens the dialog', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--custom-trigger'));
      await tapAndSettle(tester, find.text('Custom Trigger'));
      await settleDialog(tester);
      expect(find.text('Dialog title'), findsOneWidget);
      expect(find.text('Custom Trigger'), findsOneWidget);
    });
  });

  group('with form', () {
    testWidgets('the fields take text and Submit closes the dialog', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--with-form'));
      await tapAndSettle(tester, find.text('Open formulary dialog'));
      await settleDialog(tester);

      final Finder fields = find.byType(FluentInput);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), 'someone@example.com');
      await tester.enterText(fields.at(1), 'hunter2');
      await settle(tester);
      expectClean(tester, 'typing into the form');
      expect(editedText(tester, fields.at(0)), 'someone@example.com');
      expect(
        editedText(tester, fields.at(1)),
        'hunter2',
        reason: 'obscureText hides the glyphs, not the value',
      );

      await tapAndSettle(tester, find.text('Submit'));
      await settleDialog(tester);
      expect(
        find.text('Dialog title'),
        findsNothing,
        reason: 'the primary action submits, which here means closing',
      );
    });
  });

  group('title custom action', () {
    testWidgets('the header button carries the custom name and closes', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-dialog--title-custom-action'),
      );
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);
      expect(
        find.bySemanticsLabel('close'),
        findsOneWidget,
        reason:
            'closeButtonSemanticLabel is upstream\'s aria-label="close", '
            'lower case and all',
      );

      await tapAndSettle(tester, find.byIcon(fluentDialogCloseIcon));
      await settleDialog(tester);
      expect(find.text('Dialog title'), findsNothing);
    });
  });

  group('title no action', () {
    testWidgets('no close button is drawn, and the action still closes it', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-dialog--title-no-action'),
      );
      await tapAndSettle(tester, find.text('Open non-modal dialog'));
      await settleDialog(tester);
      expect(
        find.byIcon(fluentDialogCloseIcon),
        findsNothing,
        reason: 'showCloseButton: false is upstream\'s action={null}',
      );

      await tapAndSettle(tester, find.text('Close'));
      await settleDialog(tester);
      expect(
        find.text('Non-modal dialog title without an action'),
        findsNothing,
      );
    });
  });

  group('confirmation', () {
    testWidgets('focus goes straight to the confirming action', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--confirmation'));
      await tapAndSettle(tester, find.text('Delete file'));
      await settleDialog(tester);

      // Two widgets read "Delete file" here — the trigger and the primary
      // action — and only the one inside the dialog may hold focus.
      expect(find.text('Delete file'), findsNWidgets(2));
      expect(
        focusIsInside(
          tester,
          find.widgetWithText(FluentButton, 'Delete file').last,
        ),
        isTrue,
        reason:
            'a confirmation sends focus to the action, which is what makes '
            'it a confirmation rather than a short dialog',
      );
      expect(
        focusIsInside(tester, find.widgetWithText(FluentButton, 'Cancel')),
        isFalse,
      );

      await tapAndSettle(tester, find.text('Delete file').last);
      await settleDialog(tester);
      expect(find.text('Delete file'), findsOneWidget);
    });
  });

  group('motion custom', () {
    testWidgets('each motion control moves its own readout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-dialog--motion-custom'));
      final Finder sliders = find.byType(FluentSlider);
      expect(sliders, findsNWidgets(3));

      // Surface duration, outScale and backdrop duration in declaration order.
      const List<String> readouts = <String>[
        'Surface duration',
        'Surface outScale',
        'Backdrop duration',
      ];
      for (int i = 0; i < readouts.length; i++) {
        final double before = tester.widget<FluentSlider>(sliders.at(i)).value;
        final String label = readoutText(tester, readouts[i]);

        // Pressed three quarters along the rail, which is a value change for
        // every one of the three whatever it started at.
        final Rect rail = tester.getRect(sliders.at(i));
        await mouseClickAt(
          tester,
          Offset(rail.left + rail.width * 0.75, rail.center.dy),
          what: readouts[i],
        );

        expect(
          tester.widget<FluentSlider>(sliders.at(i)).value,
          isNot(before),
          reason: '${readouts[i]}: the slider did not move',
        );
        expect(
          readoutText(tester, readouts[i]),
          isNot(label),
          reason: '${readouts[i]}: the slider moved but its label did not',
        );
      }

      final Finder animateOpacity = find.byType(FluentSwitch);
      expect(
        tester.widget<FluentSwitch>(animateOpacity).checked,
        isTrue,
        reason: 'Scale carries animateOpacity by default',
      );
      await tapAndSettle(tester, animateOpacity);
      expect(tester.widget<FluentSwitch>(animateOpacity).checked, isFalse);
      await tapAndSettle(tester, animateOpacity);
      expect(tester.widget<FluentSwitch>(animateOpacity).checked, isTrue);

      // And the dialog under the controls still opens.
      await tapAndSettle(tester, find.text('Open Dialog'));
      await settleDialog(tester);
      expect(find.text('Dialog with custom motion params'), findsOneWidget);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });

    testWidgets('every section unmounts with its overlay open', (
      WidgetTester tester,
    ) async {
      // The half that matters. FluentDialog builds an AnimationController, two
      // CurvedAnimations, a FocusScopeNode and an OverlayEntry, and disposes
      // all five — a lifecycle bug in any of them only shows up on the way out
      // of a dialog that was actually opened.
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await tapAndSettle(
          tester,
          find.byType(FluentButton).first,
          what: '${section.id} first button',
        );
        await settleDialog(tester);
        await expectCleanTeardown(tester, '${section.id} while open');
      }
    });

    testWidgets('a dialog closed mid-exit still tears down cleanly', (
      WidgetTester tester,
    ) async {
      // The exit is a reverse animation that removes the entry on completion,
      // so unmounting halfway through it is the one moment the entry, the
      // controller and the widget can disagree about who is alive.
      await pumpSection(tester, sectionOf('components-dialog--default'));
      await tapAndSettle(tester, find.text('Open dialog'));
      await settleDialog(tester);
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await expectCleanTeardown(tester, 'a dialog mid-exit');
    });
  });
}

/// The dialog surface itself.
///
/// The only [DecoratedBox] in the tree carrying `shadow64`; it lives in the
/// [Overlay], so it cannot be reached as a descendant of `FluentDialog`.
final Finder dialogSurface = find.byWidgetPredicate((Widget widget) {
  if (widget is! DecoratedBox) return false;
  final Decoration decoration = widget.decoration;
  return decoration is BoxDecoration &&
      (decoration.boxShadow?.isNotEmpty ?? false);
}, description: 'the dialog surface');

/// Every backdrop currently painted, in tree order.
///
/// A scrim is the one [ColoredBox] a dialog or a drawer contributes, and its
/// alpha is the whole of "dimmed" versus "transparent" — a distinction no
/// widget property carries, since both are the same slot with a different
/// token in it.
List<Color> scrims(WidgetTester tester) => tester
    .widgetList<ColoredBox>(find.byType(ColoredBox))
    .map((ColoredBox box) => box.color)
    .toList();

/// The scrolling viewport the dialog wraps its body in.
///
/// `buildFluentDialog` puts the content inside a `Flexible`
/// `SingleChildScrollView` under a viewport-height cap, so this is the outer of
/// the two on the Keep Rendered section and the only one on the others —
/// `.first` picks it either way.
final Finder dialogBody = find
    .descendant(of: dialogSurface, matching: find.byType(Scrollable))
    .first;

/// The full text of the field label that starts with [prefix].
String readoutText(WidgetTester tester, String prefix) =>
    tester.widget<Text>(find.textContaining(prefix)).data!;

/// Turns a mouse wheel [delta] logical pixels over [finder].
///
/// Not `tester.drag`: the Keep Rendered body nests a second
/// `SingleChildScrollView` inside the dialog's own, and a nested `Scrollable`
/// wins the drag arena — so a drag is swallowed by the inner viewport, which
/// has nothing to scroll, while a wheel event reaches the outer one that does.
/// A wheel is also what a browser sends, which makes it the honest gesture for
/// "the user scrolled the dialog".
Future<void> wheelOver(WidgetTester tester, Finder finder, double delta) async {
  final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
  final Offset at = tester.getCenter(finder.first);
  tester.binding.handlePointerEvent(pointer.hover(at));
  tester.binding.handlePointerEvent(pointer.scroll(Offset(0, delta)));
  await settle(tester);
  expectClean(tester, 'scrolling ${finder.describeMatch(Plurality.one)}');
}
