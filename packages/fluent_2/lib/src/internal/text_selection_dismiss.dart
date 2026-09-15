import 'package:flutter/widgets.dart';

/// Collapses [controller]'s selection once [node] no longer holds focus.
///
/// Flutter hides a selection highlight in exactly one way: by handing
/// [EditableText] a null `selectionColor`. Blur does none of the work —
/// `EditableTextState._handleFocusChanged` leaves `controller.selection`
/// untouched, and `RenderEditable`'s highlight painter draws from
/// (range, colour) with no focus term. So a field that keeps passing a colour
/// keeps painting the highlight after the user has clicked away.
///
/// Every Fluent text control therefore gates its `selectionColor` on real
/// focus, the way `TextField` does (`material/text_field.dart:1714`) and
/// `CupertinoTextField` does (`cupertino/text_field.dart:1597`). That alone
/// settles the paint. This function is the second half of the package's
/// stricter promise: an unfocused Fluent field holds no selection at all, so
/// returning to it lands a caret rather than restoring a stale range.
///
/// Call it from the focus listener a control already owns, and only once the
/// control considers itself genuinely blurred — `FluentDatePicker` and
/// `FluentTimePicker` keep focus "inside" while their popup is open, and
/// collapsing then would clear the range out from under a live picker.
///
/// The controller belongs to the host app, so this writes as little as it can:
/// nothing at all while focused, nothing for an invalid range (a controller
/// that has never been placed reads back offset -1), and nothing for a caret
/// that is already collapsed. The surviving write lands the caret at the
/// selection's [TextSelection.extentOffset] — the moving end, where the user
/// left it.
///
/// The offset is clamped rather than trusted. [TextSelection.isValid] only
/// rules out negative offsets; it says nothing about the current text, while
/// `TextEditingController.selection`'s setter **throws** — not asserts, so in
/// release too — for an offset past `text.length`. A host that assigns
/// `controller.value` directly can leave a range longer than the text behind
/// (the `text` setter cannot: it resets the selection to -1), and blurring must
/// not turn that into a crash.
void collapseFluentSelectionOnBlur(
  FocusNode node,
  TextEditingController controller,
) {
  if (node.hasFocus) return;
  final selection = controller.selection;
  if (!selection.isValid || selection.isCollapsed) return;
  controller.selection = TextSelection.collapsed(
    offset: selection.extentOffset.clamp(0, controller.text.length),
  );
}
