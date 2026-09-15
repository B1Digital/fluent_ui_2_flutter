import 'package:fluent_2/src/internal/text_selection_dismiss.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The write side of "an unfocused Fluent field holds no selection".
///
/// The widget-level behaviour lives in `test/inputs/selection_dismissal_test.dart`;
/// this pins the guards, which are what keep the helper from writing to a
/// caller-owned controller more often than it has to.
void main() {
  late TextEditingController controller;
  late FocusNode node;

  setUp(() {
    controller = TextEditingController(text: 'hello world');
    node = FocusNode();
  });
  tearDown(() {
    controller.dispose();
    node.dispose();
  });

  /// Focus has to be real for the guard to mean anything — a detached node
  /// reports `hasFocus == false` whatever you do to it, so the focused case is
  /// pumped into a tree.
  Future<void> withFocus(WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Focus(focusNode: node, autofocus: true, child: const SizedBox()),
      ),
    );
    await tester.pump();
    expect(node.hasFocus, isTrue, reason: 'the fixture failed to take focus');
  }

  testWidgets('collapses a live range to the moving end', (tester) async {
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 7);

    collapseFluentSelectionOnBlur(node, controller);

    expect(controller.selection.isCollapsed, isTrue);
    expect(
      controller.selection.extentOffset,
      7,
      reason: 'the caret belongs where the drag ended, not where it began',
    );
    expect(controller.text, 'hello world', reason: 'the text must not move');
  });

  testWidgets('collapses a backwards range to the moving end', (tester) async {
    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 2);

    collapseFluentSelectionOnBlur(node, controller);

    expect(controller.selection.extentOffset, 2);
  });

  testWidgets('leaves a focused field alone', (tester) async {
    await withFocus(tester);
    const range = TextSelection(baseOffset: 2, extentOffset: 7);
    controller.selection = range;

    collapseFluentSelectionOnBlur(node, controller);

    expect(
      controller.selection,
      range,
      reason: 'dismissal is a blur event, not a selection-change event',
    );
  });

  testWidgets('writes nothing when there is no range to clear', (tester) async {
    controller.selection = const TextSelection.collapsed(offset: 4);
    var notified = 0;
    controller.addListener(() => notified++);

    collapseFluentSelectionOnBlur(node, controller);

    expect(controller.selection.extentOffset, 4);
    expect(
      notified,
      0,
      reason:
          'the controller belongs to the host app — a no-op blur must not wake '
          'its listeners',
    );
  });

  testWidgets('writes nothing for a never-placed selection', (tester) async {
    // What a fresh controller reads back. `TextSelection.isValid` is false here,
    // and collapsing to -1 would throw.
    expect(controller.selection.extentOffset, -1);
    var notified = 0;
    controller.addListener(() => notified++);

    collapseFluentSelectionOnBlur(node, controller);

    expect(notified, 0);
    expect(controller.selection.extentOffset, -1);
  });

  testWidgets('collapsing an empty field is safe', (tester) async {
    controller.text = '';
    controller.selection = const TextSelection.collapsed(offset: 0);

    collapseFluentSelectionOnBlur(node, controller);

    expect(controller.selection.extentOffset, 0);
  });

  // The offset is also clamped to `controller.text.length`. That branch has no
  // test on purpose: `TextEditingValue` asserts `range.end <= text.length`
  // (`services/text_input.dart:1182`), so a debug build cannot construct an
  // out-of-range selection to feed it. The clamp is there for release, where
  // that assert is stripped and `TextEditingController.selection`'s setter
  // still `throw`s — a real throw, not an assert — for an offset past the text.
}
