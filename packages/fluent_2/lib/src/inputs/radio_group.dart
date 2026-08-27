import 'package:flutter/widgets.dart';

import 'radio.dart';

/// How the radios in a group are laid out. Figma's `Direction` axis.
enum FluentRadioGroupLayout {
  /// One radio per row. The default, and the only layout Fluent recommends for
  /// more than a handful of options.
  vertical,

  /// Radios in a row, each with its label after the indicator.
  horizontal,

  /// Radios in a row, each with its label *under* the indicator. Figma's
  /// `Horizontal stacked`; upstream's `horizontal-stacked`.
  horizontalStacked,
}

/// A Fluent 2 radio group: the mutually exclusive set a `FluentRadio` belongs
/// to.
///
/// ```dart
/// FluentRadioGroup<String>(
///   value: selected,
///   onChanged: (value) => setState(() => selected = value),
///   layout: FluentRadioGroupLayout.horizontal,
///   children: const <Widget>[
///     FluentRadio<String>(value: 'a', label: Text('Option A')),
///     FluentRadio<String>(value: 'b', label: Text('Option B')),
///   ],
/// )
/// ```
///
/// [children] is a plain widget list rather than a list of `FluentRadio`,
/// because nothing is passed down positionally: the selection reaches each
/// radio through the framework's [RadioGroup] and the presentation through
/// [FluentRadioGroupScope], both inherited — so a radio may sit at any depth,
/// wrapped in whatever layout the caller needs.
///
/// The group paints nothing. It has no style struct and no theme for the same
/// reason upstream's `useRadioGroupStyles` binds no token: its entire
/// contribution is a flex direction, and the spacing between rows is the
/// indicator margin each radio already carries.
///
/// Keyboard behaviour is the framework's [RadioGroup], which is the WAI-ARIA
/// [radio group pattern](https://www.w3.org/WAI/ARIA/apg/patterns/radio/):
/// Tab moves into the group *once*, landing on the selected radio (or the first
/// one when nothing is selected), and the arrow keys move the selection from
/// there, wrapping at both ends. Before adopting it every radio was its own tab
/// stop, which is the violation this closes.
class FluentRadioGroup<T> extends StatelessWidget {
  /// Creates a group around [children].
  const FluentRadioGroup({
    super.key,
    required this.children,
    this.value,
    this.onChanged,
    this.layout = FluentRadioGroupLayout.vertical,
    this.disabled = false,
    this.semanticLabel,
  });

  /// The radios, and anything else the caller wants to lay out among them.
  final List<Widget> children;

  /// The currently selected value, or null when nothing is selected.
  final T? value;

  /// Invoked with the newly selected value. Null disables the whole group.
  ///
  /// Takes a non-nullable `T`: a Fluent radio cannot be deselected by clicking
  /// it, so there is never a null selection to report.
  final ValueChanged<T>? onChanged;

  /// How the radios are laid out. [FluentRadioGroupLayout.horizontalStacked]
  /// also moves every label below its indicator.
  final FluentRadioGroupLayout layout;

  /// Disables every radio in the group.
  ///
  /// A real state rather than a visual treatment — see `FluentRadio`.
  final bool disabled;

  /// Announced by assistive technology as the name of the group, which is what
  /// a screen reader reads before the selected option.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final vertical = layout == FluentRadioGroupLayout.vertical;

    // Upstream's root is `display: flex; align-items: flex-start`, with the
    // column direction added for the vertical layout. Start alignment in both
    // axes, so a two-line label in one horizontal option does not push its
    // siblings' indicators down.
    final Widget content = vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );

    // The name goes on the OUTSIDE. `RadioGroup` contributes its own
    // `Semantics(container: true, role: radioGroup)` node, so a label placed
    // under it would be the inner of two nested containers and would no longer
    // be what a reader — or `WidgetTester.getSemantics` — finds for this widget.
    return Semantics(
      container: true,
      label: semanticLabel,
      child: RadioGroup<T>(
        groupValue: value,
        // `RadioGroup` reports `T?` because a toggleable `RawRadio` can clear
        // the selection. No Fluent radio is toggleable, so the null never
        // arrives; dropping it here is what keeps the public API non-nullable.
        onChanged: (selected) {
          if (selected != null) onChanged?.call(selected);
        },
        child: FluentRadioGroupScope<T>(
          disabled: disabled || onChanged == null,
          labelPosition: layout == FluentRadioGroupLayout.horizontalStacked
              ? FluentRadioLabelPosition.below
              : FluentRadioLabelPosition.after,
          child: content,
        ),
      ),
    );
  }
}
