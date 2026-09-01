import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/services.dart';
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

/// Moves the roving focus inside a [FluentSwatchPicker].
///
/// Public so an app can rebind the arrow keys — or bind more of them — without
/// forking [FluentSwatchPicker].
class FluentSwatchPickerMoveIntent extends Intent {
  /// Creates an intent to move the roving focus by [delta] in the travelled
  /// direction: negative towards the start of the child list, positive towards
  /// the end.
  const FluentSwatchPickerMoveIntent(
    this.delta, {
    this.vertical = false,
    this.toEdge = false,
  });

  /// Which way to travel. Negative walks towards the first swatch. In an RTL
  /// subtree the horizontal arrows are swapped before this is dispatched, so
  /// `1` always means "towards the end of the child list".
  final int delta;

  /// Whether the key was a vertical arrow. In a grid that means "move by one
  /// row"; in a row layout it is another step along the line, which is what
  /// upstream's `axis: 'both'` does.
  final bool vertical;

  /// Jump to the end of the run named by [delta] rather than stepping. This is
  /// Home and End — the run is the whole picker in a row layout and the
  /// current row in a grid.
  final bool toEdge;
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
///
/// ## Keyboard: one tab stop, arrows inside
///
/// A swatch declares `inMutuallyExclusiveGroup`, so assistive technology reads
/// the picker as a radio-like composite — and WAI-ARIA requires a composite to
/// be **one** tab stop with the arrows moving inside it. Upstream says the same
/// thing in code: `useSwatchPicker_unstable` (`react-swatch-picker`) wraps the
/// root in
/// `useArrowNavigationGroup({circular: true, axis: isGrid ? 'grid-linear' :
/// 'both', memorizeCurrent: true})`.
///
/// Transcribed from that call and Tabster's `Mover._moveFocus`, which is what
/// implements it:
///
/// * **Row layout** (`axis: 'both'`) — all four arrows step one swatch along
///   the child list and wrap around at both ends.
/// * **Grid layout** (`axis: 'grid-linear'`) — Left and Right step one swatch
///   *linearly*, crossing the row boundary and wrapping at the ends, which is
///   exactly what `grid-linear` adds over plain `grid`. Up and Down move by a
///   row and do **not** wrap: Tabster's cyclic fallback lives only on the
///   horizontal branch, and a grid is a plane.
/// * **Home and End** jump to the first and last swatch — of the whole picker
///   in a row layout, of the current row in a grid.
///
/// The arrows move focus only; they never select. Space and Enter select,
/// through the focused swatch's own `onPressed`. `memorizeCurrent: true` is the
/// roving index being remembered, so Tabbing away and back returns to the
/// swatch you left, and a swatch that has nothing focusable — a disabled one —
/// is stepped over rather than landed on.
class FluentSwatchPicker extends StatefulWidget {
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
  State<FluentSwatchPicker> createState() => _FluentSwatchPickerState();
}

class _FluentSwatchPickerState extends State<FluentSwatchPicker> {
  /// One node per child, wrapping it. None of these can take focus itself; they
  /// exist so the picker can find the swatch's own focusable descendant, read
  /// where it landed, and gate its subtree out of the Tab order.
  final List<FocusNode> _wrappers = <FocusNode>[];

  /// The swatch that currently owns the picker's single tab stop.
  int _active = 0;

  bool get _isGrid => widget.layout == FluentSwatchPickerLayout.grid;

  @override
  void initState() {
    super.initState();
    _syncWrappers();
    // The focus tree does not exist until the first build, so "is swatch 0
    // actually focusable" cannot be answered before then.
    WidgetsBinding.instance.addPostFrameCallback((_) => _settleActive());
  }

  @override
  void didUpdateWidget(FluentSwatchPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) _syncWrappers();
    // Not gated on the length: disabling the swatch that holds the tab stop
    // leaves the list exactly as long and the picker with zero tab stops. The
    // settle is cheap and idempotent.
    WidgetsBinding.instance.addPostFrameCallback((_) => _settleActive());
  }

  @override
  void dispose() {
    for (final node in _wrappers) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncWrappers() {
    while (_wrappers.length < widget.children.length) {
      _wrappers.add(
        FocusNode(debugLabel: 'FluentSwatchPicker swatch ${_wrappers.length}'),
      );
    }
    while (_wrappers.length > widget.children.length) {
      _wrappers.removeLast().dispose();
    }
    if (_active >= widget.children.length) _active = 0;
  }

  /// The child's own focusable node — a `FluentSwatch`'s, normally.
  ///
  /// Null for a disabled swatch, which refuses focus outright, and null for
  /// anything else a caller drops in that holds no focusable descendant. That
  /// is what makes both skippable without the picker having to be told which is
  /// which.
  FocusNode? _focusable(int index) {
    if (index < 0 || index >= _wrappers.length) return null;
    for (final node in _wrappers[index].descendants) {
      if (node.canRequestFocus) return node;
    }
    return null;
  }

  /// Where child [index] is on screen, or null before it has been laid out.
  Rect? _rect(int index) {
    if (index < 0 || index >= _wrappers.length) return null;
    final node = _wrappers[index];
    return node.context == null ? null : node.rect;
  }

  /// The first focusable child at or after [from], walking by [delta] and
  /// wrapping around. Null when no child can take focus at all.
  int? _seek(int from, int delta) {
    final count = widget.children.length;
    if (count == 0) return null;
    for (var step = 0; step < count; step++) {
      final index = (from + delta * step) % count;
      if (_focusable(index) != null) return index;
    }
    return null;
  }

  /// The focusable child one row away in the direction of [delta].
  ///
  /// Tabster picks the candidate with the largest horizontal overlap with the
  /// one you are leaving and falls back to the nearest by distance
  /// (`Mover._moveFocus`, the `else if (isGrid)` branch). A picker's cells are
  /// all one size and a `Wrap` puts them on a fixed pitch, so widest overlap
  /// then nearest row is the same answer for the same reason, in a tenth of the
  /// code.
  ///
  /// ponytail: no cyclic fallback, because Tabster has none on this axis —
  /// Up from the first row and Down from the last stay put.
  int? _seekRow(int delta) {
    final origin = _rect(_active);
    if (origin == null) return null;
    int? best;
    var bestOverlap = double.negativeInfinity;
    var bestGap = double.infinity;
    for (var i = 0; i < widget.children.length; i++) {
      if (i == _active || _focusable(i) == null) continue;
      final rect = _rect(i);
      if (rect == null) continue;
      // Tabster's own guard: only candidates wholly past the row being left.
      if (delta > 0 ? rect.top < origin.bottom : rect.bottom > origin.top) {
        continue;
      }
      final overlap =
          math.min(origin.right, rect.right) - math.max(origin.left, rect.left);
      final gap = (rect.top - origin.top).abs();
      if (overlap > bestOverlap || (overlap == bestOverlap && gap < bestGap)) {
        best = i;
        bestOverlap = overlap;
        bestGap = gap;
      }
    }
    return best;
  }

  /// Home and End: the first ([delta] negative) or last focusable child of the
  /// run — the whole picker in a row layout, the current row in a grid.
  int? _seekEdge(int delta) {
    final origin = _isGrid ? _rect(_active) : null;
    int? found;
    for (var i = 0; i < widget.children.length; i++) {
      if (_focusable(i) == null) continue;
      if (origin != null) {
        final rect = _rect(i);
        // Any vertical overlap means the same run, which holds however a Wrap
        // aligns its children within one.
        if (rect == null ||
            rect.top >= origin.bottom ||
            rect.bottom <= origin.top) {
          continue;
        }
      }
      if (delta < 0) return i;
      found = i;
    }
    return found;
  }

  /// Parks the tab stop on a swatch that can actually receive it.
  ///
  /// Without this, a picker whose active swatch has just been disabled would
  /// have zero tab stops instead of one — permanently unreachable by Tab.
  void _settleActive() {
    if (!mounted) return;
    if (_focusable(_active) == null) {
      final target = _seek(_active, 1);
      if (target != null && target != _active) setState(() => _active = target);
    }
    _unlatch(_active);
  }

  /// Clears the `skipTraversal` the active swatch latched onto its own node
  /// while its gate was shut.
  ///
  /// Re-parking the index is not enough on its own. `Focus.skipTraversal` falls
  /// back to `focusNode.skipTraversal` when the widget passes none
  /// (`focus_scope.dart:298` at 3.41.0), and *that* getter is derived: it
  /// reports true while any ancestor has `descendantsAreTraversable: false`
  /// (`focus_manager.dart:489`). A swatch is built on `FluentInteractive`, so
  /// on `FocusableActionDetector`, which passes none — so the first shut gate
  /// makes `_FocusState._initNode` write the derived true back onto the
  /// swatch's own node as a hard flag, and the swatch then stays out of the Tab
  /// order for good, gate or no gate. One assignment per settle undoes it, and
  /// the swatch's next build writes the cleared value straight back, so it
  /// sticks. `_FluentToolbarState._unlatch` is the same fix for the same
  /// framework behaviour.
  ///
  /// Called from [_settleActive] — mount, and any rebuild from above — and from
  /// [_handleFocusChange], because the arrow keys and a click never go through
  /// `didUpdateWidget` and would otherwise leave the swatch you moved *to*
  /// latched shut.
  void _unlatch(int index) => _focusable(index)?.skipTraversal = false;

  void _moveTo(int? target) {
    if (target == null || target == _active) return;
    _focusable(target)?.requestFocus();
    setState(() => _active = target);
  }

  void _handle(FluentSwatchPickerMoveIntent intent) {
    if (intent.toEdge) {
      _moveTo(_seekEdge(intent.delta));
      return;
    }
    // A row layout is `axis: 'both'` upstream: the vertical arrows walk the
    // same line. Only a grid has rows to move between.
    if (intent.vertical && _isGrid) {
      _moveTo(_seekRow(intent.delta));
      return;
    }
    _moveTo(_seek(_active + intent.delta, intent.delta));
  }

  /// Keeps the roving index on whichever swatch the user actually reached, so a
  /// click and an arrow press leave the picker in the same state.
  void _handleFocusChange(int index, {required bool hasFocus}) {
    if (!hasFocus || !mounted) return;
    if (_active != index) setState(() => _active = index);
    _unlatch(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    // Arrow keys are physical; the child list is logical. In an RTL subtree the
    // two disagree, and it is the arrows that must bend — Tabster swaps the
    // same pair on `ctx.rtl` before it moves anything.
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final wrapped = <Widget>[
      for (var i = 0; i < widget.children.length; i++)
        Focus(
          focusNode: _wrappers[i],
          // A handle, not a stop: it never takes focus itself, and it hides its
          // subtree from Tab unless it holds the roving index. That — one
          // traversable subtree at a time — is what a roving tabindex *is*.
          canRequestFocus: false,
          skipTraversal: true,
          descendantsAreTraversable: i == _active,
          // The handle has nothing to announce, and the picker is
          // `explicitChildNodes`, so leaving the semantics out keeps the tree
          // exactly the shape the swatches make it.
          includeSemantics: false,
          onFocusChange: (value) => _handleFocusChange(i, hasFocus: value),
          child: widget.children[i],
        ),
    ];

    final state = resolveFluentSwatchPickerState(
      children: wrapped,
      layout: widget.layout,
      size: widget.size,
      shape: widget.shape,
      spacing: widget.spacing,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentSwatchPickerStyle(
      state,
      theme,
    ).merge(FluentSwatchPickerTheme.maybeOf(context)).merge(widget.style);

    // The size and shape the children inherit are exactly the ones a swatch
    // would have resolved for itself, so this reuses the swatch resolver
    // rather than restating the ramp. Only the geometry is passed on: colours
    // stay each swatch's own business.
    final swatch = resolveFluentSwatchStyle(
      resolveFluentSwatchState(size: widget.size, shape: widget.shape),
      theme,
    );

    return Semantics(
      label: widget.semanticLabel,
      container: true,
      explicitChildNodes: true,
      child: FluentSwatchTheme(
        style: FluentSwatchStyle(
          size: swatch.size,
          iconSize: swatch.iconSize,
          borderRadius: swatch.borderRadius,
        ),
        child: Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            const SingleActivator(LogicalKeyboardKey.arrowRight):
                FluentSwatchPickerMoveIntent(rtl ? -1 : 1),
            const SingleActivator(LogicalKeyboardKey.arrowLeft):
                FluentSwatchPickerMoveIntent(rtl ? 1 : -1),
            const SingleActivator(LogicalKeyboardKey.arrowDown):
                const FluentSwatchPickerMoveIntent(1, vertical: true),
            const SingleActivator(LogicalKeyboardKey.arrowUp):
                const FluentSwatchPickerMoveIntent(-1, vertical: true),
            const SingleActivator(LogicalKeyboardKey.home):
                const FluentSwatchPickerMoveIntent(-1, toEdge: true),
            const SingleActivator(LogicalKeyboardKey.end):
                const FluentSwatchPickerMoveIntent(1, toEdge: true),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              FluentSwatchPickerMoveIntent:
                  CallbackAction<FluentSwatchPickerMoveIntent>(
                    onInvoke: (intent) {
                      _handle(intent);
                      return null;
                    },
                  ),
            },
            child: buildFluentSwatchPicker(
              state,
              resolved,
              const <WidgetState>{},
            ),
          ),
        ),
      ),
    );
  }
}
