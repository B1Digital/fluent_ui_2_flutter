import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'swatch.dart';
import 'swatch_picker_style.dart';
import 'swatch_style.dart';

/// How a picker arranges its swatches. Figma's `Layout` axis.
enum FluentSwatchPickerLayout {
  /// A single line. Upstream's `flexDirection: row`, and the `radiogroup`
  /// reading of the control.
  row,

  /// Rows that wrap at the available width. Upstream stacks caller-supplied
  /// `SwatchPickerRow`s; Figma's grid variants are eight columns of a fixed
  /// size, and both are the same thing a wrap produces without the caller
  /// having to bucket the swatches by hand.
  grid,
}

/// Gap between swatches. Figma's `Spacing` axis.
enum FluentSwatchPickerSpacing {
  /// `FluentSpacing.xs` (4). The default.
  medium,

  /// `FluentSpacing.xxs` (2).
  small,
}

/// Everything needed to lay a picker out, independent of the design axes.
///
/// [buildFluentSwatchPicker] takes this rather than
/// [FluentSwatchPickerState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentSwatchPickerBaseState {
  /// Creates a base state.
  const FluentSwatchPickerBaseState({
    required this.layout,
    required this.children,
  });

  /// Row or grid.
  final FluentSwatchPickerLayout layout;

  /// The swatches.
  final List<Widget> children;
}

/// A picker's fully resolved state, including the design axes.
@immutable
class FluentSwatchPickerState extends FluentSwatchPickerBaseState {
  /// Creates a resolved state.
  const FluentSwatchPickerState({
    required super.layout,
    required super.children,
    required this.size,
    required this.shape,
    required this.spacing,
  });

  /// The footprint pushed onto every swatch inside.
  final FluentSwatchSize size;

  /// The corner treatment pushed onto every swatch inside.
  final FluentSwatchShape shape;

  /// Gap between swatches.
  final FluentSwatchPickerSpacing spacing;
}

/// Builds the state a picker will be styled and laid out from.
///
/// The first of the three-function recomposition contract.
FluentSwatchPickerState resolveFluentSwatchPickerState({
  required List<Widget> children,
  FluentSwatchPickerLayout layout = FluentSwatchPickerLayout.row,
  FluentSwatchSize size = FluentSwatchSize.medium,
  FluentSwatchShape shape = FluentSwatchShape.square,
  FluentSwatchPickerSpacing spacing = FluentSwatchPickerSpacing.medium,
}) => FluentSwatchPickerState(
  layout: layout,
  children: children,
  size: size,
  shape: shape,
  spacing: spacing,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract.
///
/// Token sources are the Figma `SwatchPicker` component set, extracted into
/// `test/fixtures/swatch_picker.json`.
FluentSwatchPickerStyle resolveFluentSwatchPickerStyle(
  FluentSwatchPickerState state,
  FluentThemeData theme,
) => FluentSwatchPickerStyle(
  // Every one of the 14 Figma variants binds `Spacing/{Horizontal,Vertical}
  // /MNudge` on all four sides. Upstream's root is `padding: 0`; Figma wins.
  padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
    EdgeInsets.all(FluentSpacing.mNudge),
  ),
  spacing: WidgetStatePropertyAll<double?>(switch (state.spacing) {
    FluentSwatchPickerSpacing.medium => FluentSpacing.xs,
    FluentSwatchPickerSpacing.small => FluentSpacing.xxs,
  }),
);

/// Lays a picker out from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSwatchPickerBaseState] rather than [FluentSwatchPickerState] on
/// purpose: it never reads size, shape or the spacing axis — only the numbers
/// [style] resolved from them — so a consumer can supply their own style and
/// still use Fluent's layout.
Widget buildFluentSwatchPicker(
  FluentSwatchPickerBaseState state,
  FluentSwatchPickerStyle style,
  Set<WidgetState> states,
) {
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final spacing = style.spacing?.resolve(states) ?? FluentSpacing.xs;

  return Padding(
    padding: padding,
    child: switch (state.layout) {
      FluentSwatchPickerLayout.row => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: state.children,
      ),
      FluentSwatchPickerLayout.grid => Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: state.children,
      ),
    },
  );
}

/// Overrides the picker style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then
/// the widget's own `style`.
class FluentSwatchPickerTheme extends InheritedTheme {
  /// Applies [style] to every `FluentSwatchPicker` in [child].
  const FluentSwatchPickerTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size and spacing defaults.
  final FluentSwatchPickerStyle style;

  /// The nearest picker style, or null.
  static FluentSwatchPickerStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentSwatchPickerTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentSwatchPickerTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSwatchPickerTheme(style: style, child: child);
}

/// A Fluent 2 swatch picker: a row or grid of [FluentSwatch]es.
///
/// ```dart
/// FluentSwatchPicker(
///   layout: FluentSwatchPickerLayout.grid,
///   size: FluentSwatchSize.large,
///   semanticLabel: 'Highlight colour',
///   children: <Widget>[
///     for (final swatch in palette)
///       FluentSwatch(
///         color: swatch.color,
///         semanticLabel: swatch.name,
///         selected: swatch.id == selectedId,
///         onPressed: () => setState(() => selectedId = swatch.id),
///       ),
///   ],
/// )
/// ```
///
/// ## Selection lives with the caller
///
/// Upstream threads the chosen value through a React context. Here each
/// [FluentSwatch] takes its own `selected` and `onPressed`, so the value is an
/// ordinary piece of your state and the picker stays a layout. That is one
/// fewer generic, one fewer controller, and it composes with anything that
/// already holds the value.
///
/// ## Size and shape come from here
///
/// [size] and [shape] are installed as a `FluentSwatchTheme` over the
/// children, which is the *middle* rung of the style order — so they beat a
/// child's own `size` and `shape` arguments. This is deliberate: a picker
/// whose cells disagreed on size would not lay out. To make one swatch differ,
/// pass it a `style`, which is the top rung.
class FluentSwatchPicker extends StatelessWidget {
  /// Creates a picker over [children].
  const FluentSwatchPicker({
    super.key,
    required this.children,
    required this.semanticLabel,
    this.layout = FluentSwatchPickerLayout.row,
    this.size = FluentSwatchSize.medium,
    this.shape = FluentSwatchShape.square,
    this.spacing = FluentSwatchPickerSpacing.medium,
    this.style,
  });

  /// The swatches.
  final List<Widget> children;

  /// Announced by assistive technology as the group's name.
  final String semanticLabel;

  /// Row or grid.
  final FluentSwatchPickerLayout layout;

  /// The footprint every swatch inside takes.
  final FluentSwatchSize size;

  /// The corner treatment every swatch inside takes.
  final FluentSwatchShape shape;

  /// Gap between swatches.
  final FluentSwatchPickerSpacing spacing;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSwatchPickerStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final state = resolveFluentSwatchPickerState(
      children: children,
      layout: layout,
      size: size,
      shape: shape,
      spacing: spacing,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentSwatchPickerStyle(
      state,
      theme,
    ).merge(FluentSwatchPickerTheme.maybeOf(context)).merge(style);

    // The size and shape the children inherit are exactly the ones a swatch
    // would have resolved for itself, so this reuses the swatch resolver
    // rather than restating the ramp. Only the geometry is passed on: colours
    // stay each swatch's own business.
    final swatch = resolveFluentSwatchStyle(
      resolveFluentSwatchState(size: size, shape: shape),
      theme,
    );

    return Semantics(
      label: semanticLabel,
      container: true,
      explicitChildNodes: true,
      child: FluentSwatchTheme(
        style: FluentSwatchStyle(
          size: swatch.size,
          iconSize: swatch.iconSize,
          borderRadius: swatch.borderRadius,
        ),
        child: buildFluentSwatchPicker(state, resolved, const <WidgetState>{}),
      ),
    );
  }
}
