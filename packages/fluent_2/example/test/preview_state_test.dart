import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/router.dart';
import 'package:fluent_2_example/shell/showroom_app.dart';
import 'package:fluent_2_example/shell/showroom_scope.dart';
import 'package:fluent_2_example/shell/widgets/docs_scaffold.dart';
import 'package:fluent_2_example/shell/widgets/preview_band.dart';
import 'package:fluent_2_example/shell/widgets/preview_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The toolbar's grid, background and outline controls and the card's zoom
/// dress the preview; they must not remount it. Upstream Storybook keeps a typed
/// value and caret through all four, and focus through the toolbar's three
/// (Chrome), because they only restyle a wrapper.
void main() {
  testWidgets('every preview stage starts on a whole pixel', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ShowroomApp());
    await tester.pumpAndSettle();
    DocsRouterScope.of(
      tester.element(find.byType(DocsScaffold)),
    ).go(DocsRoute.docs('components-spinbutton'));
    await tester.pumpAndSettle();

    // Chrome paints the stage below each 16.38px-margined h3 on a whole
    // pixel; a fractional origin smears every 1px stroke of the story.
    final List<double> tops = <double>[
      for (final Element card in find.byType(PreviewCard).evaluate())
        tester.getTopLeft(find.byWidget(card.widget)).dy,
    ];
    expect(tops.length, greaterThan(1));
    for (final double top in tops) {
      expect(top, top.roundToDouble(), reason: 'stages sit at $tops');
    }
  });

  testWidgets('grid, background, outline and zoom keep a story mounted', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ShowroomApp());
    await tester.pumpAndSettle();
    // SpinButton rather than Input: under the test font the Input page's
    // labels overflow their story widths before anything is toggled.
    DocsRouterScope.of(
      tester.element(find.byType(DocsScaffold)),
    ).go(DocsRoute.docs('components-spinbutton'));
    await tester.pumpAndSettle();

    final Finder field = find
        .descendant(
          of: find.byType(PreviewCard).first,
          matching: find.byType(EditableText),
        )
        .first;
    await _click(tester, field);
    await tester.enterText(field, '12345');
    final EditableTextState typed = tester.state(field);
    typed.userUpdateTextEditingValue(
      typed.textEditingValue.copyWith(
        selection: const TextSelection.collapsed(offset: 3),
      ),
      SelectionChangedCause.keyboard,
    );
    await tester.pump();

    // Straight through the scope the toolbar calls, not a click on it: a click
    // on a toolbar button blurs the field here, where upstream's toolbar lives
    // in another document and cannot.
    final ShowroomScope scope = ShowroomScope.of(tester.element(field));
    for (final (String name, VoidCallback toggle) in <(String, VoidCallback)>[
      ('grid', scope.onToggleGrid),
      ('outline', scope.onToggleOutlines),
      ('background', () => scope.onBackgroundChanged(PreviewBackground.dark)),
    ]) {
      toggle();
      await tester.pumpAndSettle();
      expect(tester.state(field), same(typed), reason: '$name remounted it');
      expect(typed.textEditingValue.text, '12345', reason: name);
      expect(typed.textEditingValue.selection.baseOffset, 3, reason: name);
      expect(typed.widget.focusNode.hasFocus, isTrue, reason: name);
    }

    // The card's own zoom buttons share the story's document upstream too, so
    // the click takes focus there as well, and this blurred SpinButton then
    // commits its text, clamped to the story's max. The element survives.
    await _click(
      tester,
      find.descendant(
        of: find.byType(PreviewCard).first,
        matching: find.byIcon(FluentIcons.zoom_in_20_regular),
      ),
    );
    expect(tester.state(field), same(typed), reason: 'zoom remounted it');
  });
}

/// Press, dwell, drift, release — a real mouse, not `tester.tap`.
Future<void> _click(WidgetTester tester, Finder target) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(target),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump(const Duration(milliseconds: 90));
  await gesture.moveBy(const Offset(1.5, 1.5));
  await tester.pump(const Duration(milliseconds: 10));
  await gesture.up();
  await tester.pumpAndSettle();
}
