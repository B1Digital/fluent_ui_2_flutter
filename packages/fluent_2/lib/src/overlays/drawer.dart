import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import 'drawer_style.dart';

/// Whether a drawer floats over the page or sits inside the layout.
///
/// Figma's `Drawer` set has exactly this axis, and it is the one decision that
/// changes everything else: an overlay drawer is modal, scrimmed, shadowed and
/// traps focus; an inline drawer does none of that and pushes the content
/// beside it instead.
enum FluentDrawerType {
  /// Floats over the page on a modal scrim. The default, and upstream's
  /// `OverlayDrawer`.
  overlay,

  /// Sits in the layout and takes width from its siblings. Upstream's
  /// `InlineDrawer`.
  inline,
}

/// Drawer width, and — because upstream keys the transition off it — how long
/// the drawer takes to arrive. Figma's `Size` axis plus React's `full`.
enum FluentDrawerSize {
  /// 320 wide, 250ms. The default.
  small,

  /// 592 wide, 300ms.
  medium,

  /// 940 wide, 400ms.
  large,

  /// As wide as the parent allows, 500ms.
  ///
  /// Present in `useDrawerBaseStyles.styles.ts` as `100vw` and absent from the
  /// Figma set, which ships only the three fixed widths.
  full,
}

/// Which edge the drawer is anchored to, in reading order.
///
/// Deliberately start/end rather than left/right: everything below — the
/// anchoring, the slide direction and the side the rule sits on — flips with
/// [Directionality], exactly as upstream's `getPositionTransform` flips on
/// `dir`.
enum FluentDrawerPosition {
  /// The leading edge. Left in LTR, right in RTL. The default.
  start,

  /// The trailing edge. Right in LTR, left in RTL.
  end,
}

/// Width of `FluentDrawerSize.small`, from Figma and `useDrawerBaseStyles`
/// alike.
const double fluentDrawerSmallWidth = 320;

/// Width of `FluentDrawerSize.medium`.
const double fluentDrawerMediumWidth = 592;

/// Width of `FluentDrawerSize.large`.
const double fluentDrawerLargeWidth = 940;

/// How long a drawer of [size] takes to open or close.
///
/// Transcribed from `shared/drawerMotions.ts`, which is the only place the
/// number lives:
///
/// ```ts
/// const durations = {
///   small: motionTokens.durationGentle,   // 250
///   medium: motionTokens.durationSlow,    // 300
///   large: motionTokens.durationSlower,   // 400
///   full: motionTokens.durationUltraSlow, // 500
/// };
/// ```
///
/// The same number drives the enter, the exit and the scrim fade — upstream
/// reads `durations[size]` in all three.
Duration fluentDrawerDuration(FluentDrawerSize size) => switch (size) {
  FluentDrawerSize.small => FluentDuration.gentle,
  FluentDrawerSize.medium => FluentDuration.slow,
  FluentDrawerSize.large => FluentDuration.slower,
  FluentDrawerSize.full => FluentDuration.ultraSlow,
};

/// The drawer arriving: [fluentDrawerDuration] on `curveDecelerateMid`.
///
/// Decelerating, because the panel is arriving somewhere and stopping there.
FluentMotionSpec fluentDrawerEnter(FluentDrawerSize size) => FluentMotionSpec(
  duration: fluentDrawerDuration(size),
  curve: FluentCurve.decelerateMid,
);

/// The drawer leaving: the same duration on `curveAccelerateMin`.
///
/// Symmetric in length and asymmetric in easing — upstream reverses the
/// keyframes and swaps only the curve, so a drawer leaves at the same pace it
/// arrived but speeds up on the way out.
FluentMotionSpec fluentDrawerExit(FluentDrawerSize size) => FluentMotionSpec(
  duration: fluentDrawerDuration(size),
  curve: FluentCurve.accelerateMin,
);

/// The modal scrim fading behind an overlay drawer.
///
/// `OverlaySurfaceBackdropMotion` uses the drawer's own duration but
/// `motionTokens.curveLinear` in both directions — the scrim is a wash, not an
/// object arriving, so it has no ease.
FluentMotionSpec fluentDrawerScrimFade(FluentDrawerSize size) =>
    FluentMotionSpec(
      duration: fluentDrawerDuration(size),
      curve: FluentCurve.linear,
    );

/// Everything needed to render a drawer panel, independent of the design axes.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentDrawer] takes this
/// rather than [FluentDrawerState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentDrawerBaseState {
  /// Creates a base state.
  const FluentDrawerBaseState({
    required this.open,
    required this.position,
    required this.child,
    this.header = const <Widget>[],
    this.footer = const <Widget>[],
  });

  /// Whether the drawer is showing. Read by the widget, not by the renderer —
  /// a panel that is on screen at all is painted the same way.
  final bool open;

  /// Which edge the panel is anchored to. Read by the renderer, because it
  /// decides which side the rule sits on — that is geometry, not styling.
  final FluentDrawerPosition position;

  /// The body. Fills whatever height is left between header and footer.
  final Widget child;

  /// Header children, stacked in a column. Empty means no header.
  final List<Widget> header;

  /// Footer children, laid out in a row. Empty means no footer.
  final List<Widget> footer;
}

/// A drawer's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `type`,
/// `size` and `separator`.
@immutable
class FluentDrawerState extends FluentDrawerBaseState {
  /// Creates a resolved state.
  const FluentDrawerState({
    required super.open,
    required super.position,
    required super.child,
    required this.type,
    required this.size,
    required this.separator,
    super.header,
    super.footer,
  });

  /// Overlay or inline.
  final FluentDrawerType type;

  /// Width, and the transition length that goes with it.
  final FluentDrawerSize size;

  /// Whether an inline drawer draws its rule. Ignored for an overlay drawer,
  /// which always carries one.
  final bool separator;
}

/// Builds the state a drawer will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentDrawerState resolveFluentDrawerState({
  required Widget child,
  bool open = false,
  FluentDrawerType type = FluentDrawerType.overlay,
  FluentDrawerSize size = FluentDrawerSize.small,
  FluentDrawerPosition position = FluentDrawerPosition.start,
  bool separator = false,
  List<Widget> header = const <Widget>[],
  List<Widget> footer = const <Widget>[],
}) => FluentDrawerState(
  open: open,
  type: type,
  size: size,
  position: position,
  separator: separator,
  child: child,
  header: header,
  footer: footer,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour comes from a Fluent token selected
/// through [FluentStateColor]; nothing here computes one.
///
/// Token sources are the Figma `.Overlay drawer` (`9170:8030`) and
/// `.Inline drawer` (`9170:8046`) sets, extracted into
/// `test/fixtures/overlay_drawer.json` and `test/fixtures/inline_drawer.json`.
/// Neither set has a `State` axis — a drawer has no hover, pressed or disabled
/// rendering at all — so each token below is a single-token set rather than a
/// ramp.
///
/// Three values disagree with `microsoft/fluentui@master`, and Figma wins in
/// all three:
///
/// * **Header inset.** `useDrawerHeaderStyles` says
///   `spacingVerticalXXL spacingHorizontalXXL spacingVerticalS` — 24 / 24 / 8.
///   Figma's `Navigation base` frame says 24 top, **16** (`Horizontal/L`) end,
///   **12** (`Vertical/M`) bottom, 24 start, on all twelve variants. The end
///   inset is React's `DrawerHeaderTitle` action margin (`-spacingHorizontalS`)
///   already folded in; the bottom is a straight divergence.
/// * **Inline rule tone.** React draws `1px solid colorNeutralBackground3`;
///   Figma's rule binds `Neutral/Stroke/2/Rest`. `neutralBackground3` is
///   `#F5F5F5` in light, which is barely a line against `neutralBackground1`.
/// * **Panel fill.** Figma paints the fill on the inline variant frame and on
///   each of the overlay drawer's three slots rather than on its frame; the
///   token is `Neutral/Background/1/Rest` either way, which is what the panel
///   uses.
///
/// One value follows React over Figma, and it is the same call
/// `FluentSwitch`'s checked track makes: the **inboard rule of every drawer
/// that has no visible one**. Figma paints no stroke on the overlay frame, and
/// none on `Vertical Divider=None`; `useDrawerBaseStyles` declares
/// `borderRight: strokeWidthThin solid colorTransparentStroke` for `start` and
/// `borderLeft` for `end`, and `useDrawerBaseClassNames` applies it to inline
/// and overlay alike. The two are pixel-identical in light and dark, but
/// `transparentStroke` turns opaque in high contrast, where it is the only
/// thing separating the panel from the page behind it. (It is also a real 1px
/// of layout width, which an unseparated inline drawer used to be missing.)
FluentDrawerStyle resolveFluentDrawerStyle(
  FluentDrawerState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final overlay = state.type == FluentDrawerType.overlay;
  // Every drawer carries a thin edge on the side facing the page; only its tone
  // varies. Figma models the visible rule as a three-value `Vertical Divider`
  // axis (None / Left / Right), but the side is not free: React derives it from
  // `position`, and so does this — `Left` is a `start` drawer's own rule read
  // from the page's side. `Vertical Divider=None` drops to `transparentStroke`
  // rather than to nothing, for the reason spelled out above: `useDrawerBase`
  // gives inline and overlay alike a `strokeWidthThin solid
  // colorTransparentStroke` edge, invisible in light and dark and opaque in
  // high contrast, where it is the only thing separating panel from page.

  return FluentDrawerStyle(
    backgroundColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    foregroundColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    borderColor: FluentStateColor.tokens(
      rest: !overlay && state.separator
          ? c.neutralStroke2
          : c.transparentStroke,
    ),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    // A real alias token, never Colors.transparent: this is rgba(0,0,0,0.5) in
    // high contrast, so the scrim still dims there.
    scrimColor: FluentStateColor.tokens(rest: c.backgroundOverlay),
    // Figma binds the `Shadow 64` effect style — ambient (0,0) blur 8, key
    // (0,32) blur 64 — on all three overlay variants and nothing at all on the
    // nine inline ones. `tokens.shadow64` in `drawerMotions.ts` agrees.
    shadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      overlay ? theme.shadow(FluentElevation.shadow64) : null,
    ),
    width: WidgetStatePropertyAll<double?>(switch (state.size) {
      FluentDrawerSize.small => fluentDrawerSmallWidth,
      FluentDrawerSize.medium => fluentDrawerMediumWidth,
      FluentDrawerSize.large => fluentDrawerLargeWidth,
      FluentDrawerSize.full => double.infinity,
    }),
    headerPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.fromSTEB(
        FluentSpacing.xxl,
        FluentSpacing.xxl,
        FluentSpacing.l,
        FluentSpacing.m,
      ),
    ),
    headerGap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    // Figma's header title is 20/28 Semibold with `Typography/Font size/500`
    // and `Line height/500` bound — that is `subtitle1`, and it is what
    // upstream's DrawerHeaderTitle inherits from DialogTitle.
    headerTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.subtitle1,
    ),
    bodyPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.xxl),
    ),
    footerPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.fromLTRB(
        FluentSpacing.xxl,
        FluentSpacing.l,
        FluentSpacing.xxl,
        FluentSpacing.xxl,
      ),
    ),
    footerGap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
  );
}

/// Renders a drawer panel from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentDrawerBaseState] rather than [FluentDrawerState] on purpose: it never
/// reads the type, the size or the separator flag, so a consumer can supply
/// their own style and still use Fluent's layout. It renders the panel only —
/// the scrim, the slide and the focus trap are `FluentDrawer`'s job, because
/// they are placement rather than painting.
///
/// The panel fills the height it is given and the body takes whatever is left
/// between header and footer, which is how both Figma (a 952-tall frame with an
/// 812-tall body) and upstream (`flex: 1` on `DrawerBody`) build it. An inline
/// drawer therefore has to sit in a bounded-height parent — a `Row`, an
/// `Expanded`, a `SizedBox`.
///
/// [states] is present for symmetry with the rest of the package. A drawer
/// panel is never hovered, pressed or focused as a whole, so callers normally
/// pass an empty set.
Widget buildFluentDrawer(
  FluentDrawerBaseState state,
  FluentDrawerStyle style,
  Set<WidgetState> states,
) {
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final borderColor = style.borderColor?.resolve(states);
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final width = style.width?.resolve(states);
  final headerPadding = style.headerPadding?.resolve(states) ?? EdgeInsets.zero;
  final headerGap = style.headerGap?.resolve(states) ?? FluentSpacing.s;
  final headerTextStyle = style.headerTextStyle?.resolve(states);
  final bodyPadding = style.bodyPadding?.resolve(states) ?? EdgeInsets.zero;
  final footerPadding = style.footerPadding?.resolve(states) ?? EdgeInsets.zero;
  final footerGap = style.footerGap?.resolve(states) ?? FluentSpacing.s;

  Widget? header;
  if (state.header.isNotEmpty) {
    header = Padding(
      padding: headerPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: headerGap,
        children: state.header,
      ),
    );
    if (headerTextStyle != null) {
      header = DefaultTextStyle.merge(style: headerTextStyle, child: header);
    }
  }

  final footer = state.footer.isEmpty
      ? null
      : Padding(
          padding: footerPadding,
          child: Row(spacing: footerGap, children: state.footer),
        );

  // The rule sits on the edge facing the page, which is the trailing edge of a
  // `start` drawer and the leading edge of an `end` one. BorderDirectional
  // resolves that against the ambient reading direction, so RTL needs no
  // second branch.
  final side = borderWidth > 0 && borderColor != null
      ? BorderSide(color: borderColor, width: borderWidth)
      : BorderSide.none;
  final border = side == BorderSide.none
      ? null
      : BorderDirectional(
          start: state.position == FluentDrawerPosition.end
              ? side
              : BorderSide.none,
          end: state.position == FluentDrawerPosition.start
              ? side
              : BorderSide.none,
        );

  Widget panel = DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      border: border,
      boxShadow: style.shadow?.resolve(states),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ?header,
        Expanded(
          child: Padding(padding: bodyPadding, child: state.child),
        ),
        ?footer,
      ],
    ),
  );

  if (foreground != null) {
    panel = IconTheme.merge(
      data: IconThemeData(color: foreground),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: panel,
      ),
    );
  }

  // `full` resolves to infinity, which means "whatever the parent offers" — no
  // SizedBox at all, so the placement decides.
  if (width != null && width.isFinite) {
    panel = SizedBox(width: width, child: panel);
  }
  return panel;
}

/// Overrides the drawer style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. An [InheritedTheme], so it survives the trip into the
/// [Overlay] an overlay drawer builds in.
class FluentDrawerTheme extends InheritedTheme {
  /// Applies [style] to every [FluentDrawer] in [child].
  const FluentDrawerTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the type and size defaults.
  final FluentDrawerStyle style;

  /// The nearest drawer style, or null.
  static FluentDrawerStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentDrawerTheme>()?.style;

  @override
  bool updateShouldNotify(FluentDrawerTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDrawerTheme(style: style, child: child);
}

/// A Fluent 2 drawer.
///
/// ```dart
/// FluentDrawer(
///   open: showing,
///   onDismiss: () => setState(() => showing = false),
///   header: <Widget>[const Text('Settings')],
///   footer: <Widget>[FluentButton(onPressed: save, child: const Text('Save'))],
///   child: const SettingsList(),
/// )
/// ```
///
/// ## Two components in one
///
/// [type] is not a visual variant. An overlay drawer builds into the [Overlay],
/// floats over the page on a modal scrim, casts `shadow64`, traps Tab and
/// returns focus to whatever had it when it closes. An inline drawer builds in
/// place, is not modal, takes width from its siblings and traps nothing. The
/// widget renders **nothing at its own position** when [type] is
/// `FluentDrawerType.overlay` — the panel lives in the overlay.
///
/// ## No disabled state
///
/// None of the four Figma drawer sets has a `State` axis, and upstream has no
/// `disabled` prop, so there is no disabled rendering to port. [open] is the
/// real state: a closed drawer is not in the tree at all — no panel, no scrim
/// intercepting pointers, no focus scope — rather than being greyed out.
///
/// ## Motion
///
/// Size-keyed, which is unusual enough to be worth stating: 250ms at
/// [FluentDrawerSize.small] through 500ms at [FluentDrawerSize.full], entering
/// on `curveDecelerateMid` and leaving on `curveAccelerateMin`, with the scrim
/// fading over the same duration on `curveLinear`. See [fluentDrawerEnter],
/// [fluentDrawerExit] and [fluentDrawerScrimFade].
///
/// Under [MediaQuery.disableAnimationsOf] the drawer jumps straight to the end
/// state and schedules no frames at all.
///
/// ## Keyboard
///
/// Escape dismisses an overlay drawer through [DismissIntent]. Tab and
/// Shift+Tab cycle within the panel and cannot reach the page behind it. On
/// close, focus returns to whatever held it when the drawer opened.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentDrawerTheme] restyles a subtree; and [resolveFluentDrawerState],
/// [resolveFluentDrawerStyle] and [buildFluentDrawer] are public so any one of
/// them can be replaced without forking this widget.
class FluentDrawer extends StatefulWidget {
  /// Creates a drawer around [child].
  const FluentDrawer({
    super.key,
    required this.child,
    this.open = false,
    this.onDismiss,
    this.type = FluentDrawerType.overlay,
    this.size = FluentDrawerSize.small,
    this.position = FluentDrawerPosition.start,
    this.header = const <Widget>[],
    this.footer = const <Widget>[],
    this.separator = false,
    this.style,
    this.semanticLabel,
  });

  /// The body of the drawer.
  final Widget child;

  /// Whether the drawer is showing. Changing it runs the transition.
  ///
  /// Defaults to false, matching upstream's `useDrawerDefaultProps`.
  final bool open;

  /// Invoked when the user asks to close: Escape, or a tap on the scrim.
  ///
  /// The drawer does not close itself — [open] is the caller's state, exactly
  /// as upstream's `onOpenChange` leaves it.
  final VoidCallback? onDismiss;

  /// Overlay or inline.
  final FluentDrawerType type;

  /// Width, and the transition length that goes with it.
  final FluentDrawerSize size;

  /// Which edge the drawer is anchored to, in reading order.
  final FluentDrawerPosition position;

  /// Header children, stacked in a column. Empty means no header.
  final List<Widget> header;

  /// Footer children, laid out in a row. Empty means no footer.
  final List<Widget> footer;

  /// Whether an inline drawer draws the rule between itself and the page.
  ///
  /// Ignored when [type] is `FluentDrawerType.overlay`, which always carries
  /// one.
  final bool separator;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDrawerStyle? style;

  /// Announced by assistive technology as the name of the drawer.
  final String? semanticLabel;

  @override
  State<FluentDrawer> createState() => _FluentDrawerState();
}

class _FluentDrawerState extends State<FluentDrawer>
    with SingleTickerProviderStateMixin {
  /// A drawer panel has no interaction states; see `resolveFluentDrawerStyle`.
  static const Set<WidgetState> _states = <WidgetState>{};

  // Built in initState, not as a `late final` initialiser: a lazy one would
  // not run until the first _show(), by which time `widget.open` is already
  // true and the controller would be born at its end value with nothing left
  // to animate.
  late final AnimationController _controller;
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'FluentDrawer');

  OverlayEntry? _entry;
  FocusNode? _restore;
  bool _started = false;
  bool _reducedMotion = false;

  late FluentThemeData _theme;
  FluentDrawerStyle? _themeStyle;

  bool get _isOverlay => widget.type == FluentDrawerType.overlay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: widget.open ? 1 : 0,
      duration: fluentDrawerDuration(widget.size),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than in the overlay's builder: the overlay sits
    // outside this subtree, so a FluentThemeOverride or FluentDrawerTheme
    // wrapping this widget would otherwise be invisible to it.
    _theme = FluentTheme.of(context);
    _themeStyle = FluentDrawerTheme.maybeOf(context);
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    // Also covers reduced motion being switched on mid-transition: whatever is
    // in flight lands on this frame rather than finishing at full length.
    _applyReducedMotion();

    if (!_started) {
      _started = true;
      if (widget.open) _deferOrRun(_show);
      return;
    }
    _deferOrRun(() => _entry?.markNeedsBuild());
  }

  @override
  void didUpdateWidget(FluentDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type) {
      _deferOrRun(() {
        _removeEntry();
        if (widget.open) {
          _show();
        } else {
          _controller.value = 0;
        }
      });
      return;
    }
    if (widget.open != oldWidget.open) {
      _deferOrRun(widget.open ? _show : _dismiss);
      return;
    }
    _deferOrRun(() => _entry?.markNeedsBuild());
  }

  @override
  void dispose() {
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    _controller.dispose();
    _scope.dispose();
    super.dispose();
  }

  /// Runs [action] now, unless a build is in flight.
  ///
  /// Inserting, removing or invalidating an [OverlayEntry] is a `setState` on
  /// the [Overlay], which sits in a different branch of the tree and has
  /// usually been built by the time this widget rebuilds.
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

  void _applyReducedMotion() {
    if (!_reducedMotion || !_controller.isAnimating) return;
    _controller.value = widget.open ? 1 : 0;
  }

  void _show() {
    if (_isOverlay && _entry == null) {
      final overlay = Overlay.of(context, debugRequiredFor: widget);
      _restore = FocusManager.instance.primaryFocus;
      // FluentTheme is an InheritedTheme, so this carries it — and any other
      // InheritedTheme between here and the overlay, FluentDrawerTheme
      // included — across the boundary.
      final captured = InheritedTheme.capture(
        from: context,
        to: overlay.context,
      );
      _entry = OverlayEntry(builder: (_) => captured.wrap(_buildPanel()));
      overlay.insert(_entry!);
    }
    final spec = fluentDrawerEnter(widget.size);
    if (_reducedMotion) {
      _controller
        ..duration = spec.duration
        ..value = 1;
    } else {
      _controller.animateTo(1, duration: spec.duration, curve: spec.curve);
    }
    if (!_isOverlay) {
      setState(() {});
      return;
    }
    // The scope's subtree only exists once the overlay has built, so focus is
    // taken on the next frame rather than this one.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.open && _entry != null) _scope.requestFocus();
    });
  }

  void _dismiss() {
    final spec = fluentDrawerExit(widget.size);
    if (_reducedMotion) {
      _controller
        ..duration = spec.duration
        ..value = 0;
      _finishClose();
      return;
    }
    _controller
        .animateBack(0, duration: spec.duration, curve: spec.curve)
        .whenCompleteOrCancel(() {
          if (mounted && !widget.open && _controller.value == 0) {
            _finishClose();
          }
        });
  }

  void _finishClose() {
    _removeEntry();
    final node = _restore;
    _restore = null;
    // context is null once the trigger has left the tree, and asking a
    // detached node for focus throws.
    if (node != null && node.context != null) node.requestFocus();
    if (mounted) setState(() {});
  }

  void _removeEntry() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry
      ..remove()
      ..dispose();
  }

  FluentDrawerState _state() => resolveFluentDrawerState(
    open: widget.open,
    type: widget.type,
    size: widget.size,
    position: widget.position,
    separator: widget.separator,
    child: widget.child,
    header: widget.header,
    footer: widget.footer,
  );

  // Lowest to highest: defaults, subtree theme, then the caller's own style.
  FluentDrawerStyle _resolvedStyle(FluentDrawerState state) =>
      resolveFluentDrawerStyle(
        state,
        _theme,
      ).merge(_themeStyle).merge(widget.style);

  /// The scrim, the slide and the focus trap — everything an overlay drawer
  /// needs on top of the panel itself.
  Widget _buildPanel() {
    final state = _state();
    final style = _resolvedStyle(state);
    final scrim = style.scrimColor?.resolve(_states);
    final panel = buildFluentDrawer(state, style, _states);

    // Read from *this* widget's context, not the overlay's: Directionality is
    // not an InheritedTheme, so InheritedTheme.capture does not carry it, and
    // an RTL subtree would otherwise open its drawer on the wrong edge.
    final direction = Directionality.of(context);
    final leading = widget.position == FluentDrawerPosition.start;
    final full = widget.size == FluentDrawerSize.full;
    // Offscreen is towards the edge the drawer lives on, which flips with the
    // reading direction — upstream's getPositionTransform, in one expression.
    final sign = leading == (direction == TextDirection.ltr) ? -1.0 : 1.0;

    return Directionality(
      textDirection: direction,
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: widget.semanticLabel != null,
        label: widget.semanticLabel,
        // Actions sits ABOVE the FocusScope on purpose: a shortcut is
        // dispatched from the primary focus outwards, and while the scope
        // itself holds focus its own context is above anything nested inside
        // it — an Actions below the scope would never be found.
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                widget.onDismiss?.call();
                return null;
              },
            ),
          },
          child: FocusScope(
            node: _scope,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Opacity(
                        opacity: t,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onDismiss,
                          child: ColoredBox(
                            color: scrim ?? const Color(0x00000000),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      bottom: 0,
                      start: leading || full ? 0 : null,
                      end: !leading || full ? 0 : null,
                      child: FractionalTranslation(
                        translation: Offset(sign * (1 - t), 0),
                        // Opacity carries the shadow with it, which is what
                        // upstream's keyframes do explicitly — they tween
                        // boxShadow from transparent up to shadow64.
                        child: Opacity(opacity: t, child: panel),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // An overlay drawer paints nothing where it is written; the panel is in
    // the Overlay.
    if (_isOverlay) return const SizedBox.shrink();

    final state = _state();
    final style = _resolvedStyle(state);
    final panel = buildFluentDrawer(state, style, _states);
    final leading = widget.position == FluentDrawerPosition.start;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Closed and settled: nothing is built at all, which is upstream's
        // `unmountOnClose` default and keeps a closed drawer out of the
        // traversal and semantics trees.
        if (t == 0 && !widget.open) return const SizedBox.shrink();
        return Semantics(
          container: true,
          // Same boundary the overlay branch declares: without it this
          // annotation is not a stop, so every header and footer control
          // merges its own label upwards and the panel alone is announced.
          explicitChildNodes: true,
          label: widget.semanticLabel,
          child: ClipRect(
            // Pinning the far edge and clipping the near one is the same
            // reading as upstream's translate-plus-width-to-zero exit, and
            // AlignmentDirectional flips it for RTL.
            child: Align(
              alignment: leading
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              widthFactor: t,
              child: Opacity(opacity: t, child: panel),
            ),
          ),
        );
      },
    );
  }
}
