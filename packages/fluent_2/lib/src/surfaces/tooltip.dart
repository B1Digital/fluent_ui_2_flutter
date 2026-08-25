import 'dart:async';

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import 'tooltip_style.dart';

/// How a tooltip surface is filled. Figma's `Style` axis, verbatim.
enum FluentTooltipAppearance {
  /// Neutral surface on the ambient background. The default.
  normal,

  /// Brand fill, for tooltips that carry a promotional or onboarding message.
  brand,

  /// Inverted neutral fill — dark on light, light on dark.
  inverted,
}

/// Which side of its target a tooltip sits on.
///
/// Not a Figma variant axis: the design file ships the four sides as twelve
/// hidden arrow layers inside a single component, and every one of them is
/// `visible: false` by default.
enum FluentTooltipPosition {
  /// Above the target, arrow pointing down. The default.
  above,

  /// Below the target, arrow pointing up.
  below,

  /// Before the target in reading order, arrow pointing towards it.
  before,

  /// After the target in reading order, arrow pointing towards it.
  after,
}

/// Everything needed to render a tooltip, independent of appearance.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentTooltip] takes this
/// rather than [FluentTooltipState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentTooltipBaseState {
  /// Creates a base state.
  const FluentTooltipBaseState({
    required this.position,
    required this.withArrow,
    required this.content,
  });

  /// Which side of the target the surface sits on. Read by the renderer, since
  /// it decides where the arrow goes — it is geometry, not styling.
  final FluentTooltipPosition position;

  /// Whether the pointing arrow is drawn.
  final bool withArrow;

  /// The tooltip body.
  final Widget content;
}

/// A tooltip's fully resolved state, including the design axis.
///
/// The counterpart of `FluentButtonState`: base state plus exactly
/// `appearance`.
@immutable
class FluentTooltipState extends FluentTooltipBaseState {
  /// Creates a resolved state.
  const FluentTooltipState({
    required super.position,
    required super.withArrow,
    required super.content,
    required this.appearance,
  });

  /// Fill treatment.
  final FluentTooltipAppearance appearance;
}

/// Builds the state a tooltip will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentTooltipState resolveFluentTooltipState({
  required Widget content,
  FluentTooltipAppearance appearance = FluentTooltipAppearance.normal,
  FluentTooltipPosition position = FluentTooltipPosition.above,
  bool withArrow = false,
}) => FluentTooltipState(
  appearance: appearance,
  position: position,
  withArrow: withArrow,
  content: content,
);

/// Width at which tooltip content wraps.
///
/// Figma pins `maxWidth: 240` on the component frame while leaving horizontal
/// sizing on HUG, and upstream's `useTooltipStyles` says `maxWidth: '240px'`.
/// There is no token for it in either place, so the number is transcribed.
const double _maxWidth = 240;

/// Arrow base and height.
///
/// `react-tooltip`'s `private/constants.ts` sets `arrowHeight = 6`, and
/// `createArrowHeightStyles(6)` emits a `1.414 * 6 = 8.49px` square rotated 45°
/// — a visible triangle 12 wide by 6 tall, which a live probe of
/// `components-tooltip--with-arrow` confirms (element 8.47px square, matrix
/// rotation, 11.98px bounding box). No Figma fixture captures the tooltip
/// arrow: `tooltip.json` has no `parts` at all, so the 16 x 8 this used to
/// carry — attributed to node `9014:2663` — had nothing asserting it.
const Size _arrowSize = Size(12, 6);

/// How long the pointer must dwell before the tooltip appears, and how long it
/// must be gone before it disappears.
///
/// `useTooltipBase.tsx` states `showDelay = 250, hideDelay = 250`, and a live
/// probe needs a >250ms dwell after `page.hover` before `[role=tooltip]` has a
/// rect. Figma has no timing layer, so React is the only authority here.
///
/// Keyboard focus and blur bypass this — upstream passes `delay: 0` on blur,
/// and a tooltip that lagged a quarter second behind the focus ring would read
/// as a bug rather than as patience.
const Duration _hoverDelay = Duration(milliseconds: 250);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every colour comes from a Fluent token selected
/// through [FluentStateColor]; nothing here computes one.
///
/// Token sources are the Figma `Tooltip` component set, extracted into
/// `test/fixtures/tooltip.json` and asserted variant-by-variant in the tests.
FluentTooltipStyle resolveFluentTooltipStyle(
  FluentTooltipState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // A tooltip has no interactive states at all — Figma ships one Rest variant
  // per style and no Hover, Pressed or Disabled counterpart — so each of these
  // is a single-token set rather than a ramp.
  final (background, foreground, border) = switch (state.appearance) {
    FluentTooltipAppearance.normal => (
      c.neutralBackground1,
      c.neutralForeground1,
      // Transparent, not absent: this turns into canvasText in high contrast,
      // which is the only thing separating the surface from the page there.
      c.transparentStroke,
    ),
    FluentTooltipAppearance.brand => (
      c.brandBackground,
      c.neutralForegroundOnBrand,
      c.brandStroke1,
    ),
    FluentTooltipAppearance.inverted => (
      c.neutralBackgroundInverted,
      c.neutralForegroundInverted,
      c.transparentStroke,
    ),
  };

  return FluentTooltipStyle(
    backgroundColor: FluentStateColor.tokens(rest: background),
    foregroundColor: FluentStateColor.tokens(rest: foreground),
    borderColor: FluentStateColor.tokens(rest: border),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.caption1),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(
        horizontal: FluentSpacing.m,
        vertical: FluentSpacing.sNudge,
      ),
    ),
    maxWidth: const WidgetStatePropertyAll<double?>(_maxWidth),
    arrowSize: const WidgetStatePropertyAll<Size?>(_arrowSize),
    // `useTooltipBase` states `offset: 4` and then, with an arrow, replaces it
    // with `mergeArrowOffset(4, arrowHeight)` = 10 — the base gap is kept and
    // the arrow's own height is added to it, so the tip stops short of the
    // target rather than touching it. A live probe of
    // `components-tooltip--with-arrow` reads 10 between trigger and surface.
    // Here the arrow is a sibling in the Column, so it contributes its own 6
    // and this stays the flat 4 either way. Figma cannot state a positioning
    // offset at all — its arrow layers are drawn flush at the surface edge,
    // which is a frame, not a rule.
    offset: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
    shadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow8),
    ),
  );
}

/// Renders a tooltip from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentTooltipBaseState] rather than [FluentTooltipState] on purpose: it
/// never reads the appearance, so a consumer can supply their own style and
/// still use Fluent's rendering.
///
/// [states] is present for symmetry with the rest of the package. A tooltip
/// surface is never hovered, pressed or focused — it is shown *because* its
/// target was — so callers normally pass an empty set.
Widget buildFluentTooltip(
  FluentTooltipBaseState state,
  FluentTooltipStyle style,
  Set<WidgetState> states,
) {
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final borderColor = style.borderColor?.resolve(states);
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final maxWidth = style.maxWidth?.resolve(states) ?? double.infinity;
  final arrowSize = style.arrowSize?.resolve(states) ?? _arrowSize;

  var content = state.content;
  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

  final surface = ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: style.shadow?.resolve(states),
      ),
      child: Padding(padding: padding, child: content),
    ),
  );

  if (!state.withArrow) return surface;

  // Figma leaves the arrow unstroked and unshadowed even where the surface has
  // both, so it is a bare filled triangle.
  final vertical =
      state.position == FluentTooltipPosition.above ||
      state.position == FluentTooltipPosition.below;
  final arrow = CustomPaint(
    size: vertical ? arrowSize : Size(arrowSize.height, arrowSize.width),
    painter: FluentTooltipArrowPainter(
      color: background ?? const Color(0x00000000),
      position: state.position,
    ),
  );

  return switch (state.position) {
    FluentTooltipPosition.above => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[surface, arrow],
    ),
    FluentTooltipPosition.below => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[arrow, surface],
    ),
    FluentTooltipPosition.before => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[surface, arrow],
    ),
    FluentTooltipPosition.after => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[arrow, surface],
    ),
  };
}

/// Paints the tooltip's pointing arrow.
///
/// A [CustomPainter] rather than a rotated box: the shape is three points and a
/// fill, and Figma stores it as a single vector path per direction rather than
/// as one path plus a transform.
///
/// Every input is a public field so tests can assert the tone and direction
/// directly instead of diffing pixels.
class FluentTooltipArrowPainter extends CustomPainter {
  /// Creates a painter for the given fill and direction.
  const FluentTooltipArrowPainter({
    required this.color,
    required this.position,
  });

  /// The arrow fill — always the surface's own background token.
  final Color color;

  /// Which side of the target the surface is on. The arrow points the other
  /// way, towards the target.
  final FluentTooltipPosition position;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    switch (position) {
      case FluentTooltipPosition.above:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height);
      case FluentTooltipPosition.below:
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height);
      case FluentTooltipPosition.before:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height);
      case FluentTooltipPosition.after:
        path
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(FluentTooltipArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.position != position;
}

/// Overrides the tooltip style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentTooltipTheme extends InheritedTheme {
  /// Applies [style] to every [FluentTooltip] in [child].
  const FluentTooltipTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance defaults.
  final FluentTooltipStyle style;

  /// The nearest tooltip style, or null.
  static FluentTooltipStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentTooltipTheme>()?.style;

  @override
  bool updateShouldNotify(FluentTooltipTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTooltipTheme(style: style, child: child);
}

/// A Fluent 2 tooltip.
///
/// ```dart
/// FluentTooltip(
///   content: const Text('Save the document'),
///   child: FluentButton.icon(
///     icon: const Icon(FluentIcons.save_20_regular),
///     semanticLabel: 'Save',
///     onPressed: () {},
///   ),
/// )
/// ```
///
/// Appears on pointer hover and on keyboard-visible focus. Hover is delayed
/// 250ms each way, matching `useTooltipBase`'s `showDelay`/`hideDelay`; focus
/// and blur are immediate, because a tooltip trailing a quarter second behind
/// the focus ring reads as a fault. [enabled] is a real state rather than a
/// visual treatment: a disabled tooltip is never inserted into the [Overlay] at
/// all, and one that is already showing when it is disabled is torn down at
/// once, without waiting out the delay.
///
/// ## No motion
///
/// Upstream ships no transition for the tooltip on master, and its old slide
/// path is explicitly deprecated, so this appears and disappears on the frame
/// the trigger changes. That is not an omission waiting to be polished with a
/// fade — see the note on `FluentMotionSpec`. It also makes the component
/// trivially correct under reduced motion: there is no animation to shorten.
///
/// ## Positioning
///
/// The surface is placed by an [OverlayEntry] anchored with
/// [CompositedTransformFollower], so it escapes any ancestor clip or overflow
/// and follows the trigger as it moves. `FluentTheme` is an [InheritedTheme],
/// and the themes between this widget and the overlay are captured on the way
/// in, so tokens resolve against the trigger's theme rather than the app root's.
///
/// Customisation follows the same three rungs as the rest of the package.
/// [style] is merged last and wins; [FluentTooltipTheme] restyles a subtree; and
/// [resolveFluentTooltipState], [resolveFluentTooltipStyle] and
/// [buildFluentTooltip] are public so any one of them can be replaced without
/// forking this widget.
class FluentTooltip extends StatefulWidget {
  /// Wraps [child] with a tooltip showing [content].
  const FluentTooltip({
    super.key,
    required this.child,
    required this.content,
    this.appearance = FluentTooltipAppearance.normal,
    this.position = FluentTooltipPosition.above,
    this.withArrow = false,
    this.enabled = true,
    this.style,
    this.semanticLabel,
  });

  /// The trigger. Hovering or keyboard-focusing it shows the tooltip.
  final Widget child;

  /// The tooltip body. Wraps at 240 logical pixels.
  final Widget content;

  /// Fill treatment.
  final FluentTooltipAppearance appearance;

  /// Which side of [child] the surface sits on.
  final FluentTooltipPosition position;

  /// Whether to draw the pointing arrow.
  ///
  /// Defaults to false, matching both React and the Figma file, where all
  /// twelve arrow layers ship hidden.
  final bool withArrow;

  /// Whether the tooltip may appear at all.
  ///
  /// False is a real state, not a greyed-out one: nothing reaches the
  /// [Overlay], and a visible tooltip is removed.
  final bool enabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentTooltipStyle? style;

  /// Announced by assistive technology alongside the trigger.
  ///
  /// Separate from [content] because [content] is a widget and a screen reader
  /// needs a string. A tooltip that only exists visually is invisible to
  /// assistive technology, so pass this whenever [content] carries meaning the
  /// trigger does not already announce.
  final String? semanticLabel;

  @override
  State<FluentTooltip> createState() => _FluentTooltipState();
}

class _FluentTooltipState extends State<FluentTooltip> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  late FluentThemeData _theme;
  FluentTooltipStyle? _themeStyle;

  Timer? _pending;

  bool _hovered = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    FluentInputModality.keyboard.addListener(_handleModalityChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than in the overlay's builder: the overlay sits
    // outside this subtree, so a FluentThemeOverride or FluentTooltipTheme
    // wrapping the trigger would otherwise be invisible to it.
    _theme = FluentTheme.of(context);
    _themeStyle = FluentTooltipTheme.maybeOf(context);
    _deferOrRun(_repaint);
  }

  @override
  void didUpdateWidget(FluentTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _deferOrRun(() {
      _repaint();
      // Immediate: `enabled` going false must tear the surface down now, not a
      // quarter second from now.
      _syncNow();
    });
  }

  @override
  void dispose() {
    FluentInputModality.keyboard.removeListener(_handleModalityChange);
    _pending?.cancel();
    _hide();
    super.dispose();
  }

  // Keyboard-visible focus. `useTooltipBase.tsx:212` gates focus-open on
  // `useIsNavigatingWithKeyboard()`, the keyborg flag, and [FluentInputModality]
  // is that flag: focus arriving by pointer must not raise a tooltip any more
  // than it raises a focus ring. The listener is what makes a mid-flight flip
  // count — Tab off a mouse click, focus has not moved but the tip is now due.
  void _handleModalityChange() => _syncNow();

  void _handleFocusChange(bool value) {
    _focused = value;
    _syncNow();
  }

  void _handleHover({required bool value}) {
    _hovered = value;
    _syncDelayed();
  }

  bool get _shouldShow =>
      widget.enabled &&
      (_hovered || (_focused && FluentInputModality.keyboard.value));

  /// Applies [_shouldShow] on this frame, cancelling any pending hover change.
  void _syncNow() {
    _pending?.cancel();
    _pending = null;
    _shouldShow ? _show() : _hide();
  }

  /// Applies [_shouldShow] after [_hoverDelay].
  ///
  /// The timer is the whole mechanism: pointing at a control on the way to
  /// somewhere else must not flash a tooltip, and crossing a one-pixel gap
  /// between two hover targets must not flicker it. Re-entering before the
  /// hide lands cancels it, and the state is re-read when the timer fires
  /// rather than captured now, so an enter/leave/enter burst settles once.
  void _syncDelayed() {
    if (_shouldShow == (_entry != null)) {
      _pending?.cancel();
      _pending = null;
      return;
    }
    if (_pending != null) return;
    _pending = Timer(_hoverDelay, () {
      _pending = null;
      if (mounted) _shouldShow ? _show() : _hide();
    });
  }

  void _repaint() => _entry?.markNeedsBuild();

  /// Runs [action] now, unless a build is in flight.
  ///
  /// Inserting, removing or invalidating an [OverlayEntry] is a `setState` on
  /// the [Overlay], which sits in a different branch of the tree and has
  /// already been built by the time this widget rebuilds. Doing it from
  /// [didUpdateWidget] or [didChangeDependencies] would therefore assert. Hover
  /// and focus changes never arrive during a build, so they take the direct
  /// path — focus on the very next frame, hover once [_hoverDelay] has run.
  void _deferOrRun(VoidCallback action) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });
      return;
    }
    action();
  }

  void _show() {
    if (_entry != null) return;
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // FluentTheme is an InheritedTheme, so this carries it — and any other
    // InheritedTheme between here and the overlay — across the boundary.
    // ponytail: captured once, at show time. The resolved style is refreshed on
    // every dependency change, so a theme swap mid-hover still repaints; only a
    // theme read by `content` itself would go stale.
    final captured = InheritedTheme.capture(from: context, to: overlay.context);
    _entry = OverlayEntry(builder: (_) => captured.wrap(_buildFollower()));
    overlay.insert(_entry!);
  }

  void _hide() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry
      ..remove()
      ..dispose();
  }

  Widget _buildFollower() {
    final state = resolveFluentTooltipState(
      appearance: widget.appearance,
      position: widget.position,
      withArrow: widget.withArrow,
      content: widget.content,
    );
    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final style = resolveFluentTooltipStyle(
      state,
      _theme,
    ).merge(_themeStyle).merge(widget.style);

    const states = <WidgetState>{};
    final offset = style.offset?.resolve(states) ?? FluentSpacing.none;
    final (target, follower, shift) = switch (widget.position) {
      FluentTooltipPosition.above => (
        Alignment.topCenter,
        Alignment.bottomCenter,
        Offset(0, -offset),
      ),
      FluentTooltipPosition.below => (
        Alignment.bottomCenter,
        Alignment.topCenter,
        Offset(0, offset),
      ),
      FluentTooltipPosition.before => (
        Alignment.centerLeft,
        Alignment.centerRight,
        Offset(-offset, 0),
      ),
      FluentTooltipPosition.after => (
        Alignment.centerRight,
        Alignment.centerLeft,
        Offset(offset, 0),
      ),
    };

    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: target,
        followerAnchor: follower,
        offset: shift,
        // A tooltip that swallowed pointer events would flicker: the surface
        // can overlap its own trigger, and stealing the hover would hide it.
        child: IgnorePointer(child: buildFluentTooltip(state, style, states)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // canRequestFocus: false keeps this out of the traversal order — the
    // trigger already has a focus node, and a second stop would mean two Tab
    // presses to reach it. hasFocus still reports a focused descendant.
    Widget result = CompositedTransformTarget(
      link: _link,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: _handleFocusChange,
        child: MouseRegion(
          onEnter: (_) => _handleHover(value: true),
          onExit: (_) => _handleHover(value: false),
          child: widget.child,
        ),
      ),
    );

    final label = widget.semanticLabel;
    if (label != null) {
      // container: true so the tooltip lands on a node of its own rather than
      // merging into whatever boundary happens to enclose the trigger.
      result = Semantics(container: true, tooltip: label, child: result);
    }
    return result;
  }
}
