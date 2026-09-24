import 'package:flutter/widgets.dart';

/// Tells a menu's trigger whether that menu is open — the `aria-expanded`
/// upstream's `MenuTrigger` hands the element it wraps.
///
/// `FluentMenu` puts one above whatever its trigger builder returns, so a
/// control that styles its open state, like the split button's chevron half,
/// can follow the menu without the caller wiring it through. A custom trigger
/// reads it the same way:
///
/// ```dart
/// FluentMenu(
///   items: items,
///   builder: (context, toggle) => MyTrigger(
///     open: FluentMenuTriggerScope.maybeIsOpenOf(context) ?? false,
///     onPressed: toggle,
///   ),
/// )
/// ```
class FluentMenuTriggerScope extends InheritedWidget {
  /// Scopes [isOpen] to [child].
  const FluentMenuTriggerScope({
    super.key,
    required this.isOpen,
    required super.child,
  });

  /// Whether the menu this subtree triggers is open.
  final bool isOpen;

  /// The nearest menu's open state, or null outside any menu trigger.
  static bool? maybeIsOpenOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentMenuTriggerScope>()
      ?.isOpen;

  @override
  bool updateShouldNotify(FluentMenuTriggerScope oldWidget) =>
      isOpen != oldWidget.isOpen;
}
