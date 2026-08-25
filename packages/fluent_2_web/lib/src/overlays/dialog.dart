import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../buttons/button.dart';
import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'dialog_style.dart';

/// How much of the screen a dialog claims, and how its actions stack.
///
/// Figma's `Size` axis, whose two members are named after their widths.
/// Upstream has no size prop at all: `useDialogSurfaceStyles` pins
/// `maxWidth: 600px` and switches the actions to a column below a 480px
/// viewport, which is the same two renderings arrived at from the other side.
enum FluentDialogSize {
  /// 320 wide, actions stacked full-width. Figma's `320px`.
  ///
  /// Figma's alone: upstream's `@media screen and (max-width: 480px)` rule sets
  /// `maxWidth: 100vw`, not 320 — probed at a 400x800 viewport the dialog
  /// surface measures 400 wide. Only the stacked actions are shared.
  small,

  /// 600 wide, actions in a row. Figma's `600px`, and upstream's `maxWidth`.
  /// The default.
  medium,
}

/// Whether a dialog blocks the page, and how it may be dismissed.
///
/// Not a Figma axis — the design file ships one surface — so the three members
/// and their behaviour come from `useDialog.ts` and `useDialogSurface.ts`.
enum FluentDialogModalType {
  /// Blocks the page behind a scrim, traps Tab, and closes on Escape or on a
  /// click outside. The default, matching upstream.
  modal,

  /// Blocks the page behind a scrim and traps Tab, but a click on the scrim
  /// does **not** close it — the user has to answer. Escape still does.
  alert,

  /// No scrim, no focus trap, and the page behind stays interactive. Escape
  /// closes it. Upstream's `non-modal`.
  nonModal,
}

/// The dialog surface arriving.
///
/// Transcribed from `DialogSurfaceMotion.ts`:
///
/// ```ts
/// export const DialogSurfaceMotion = createPresenceComponentVariant(Scale, {
///   outScale: 0.85,
///   easing: motionTokens.curveDecelerateMid,
///   duration: motionTokens.durationGentle,
///   exitEasing: motionTokens.curveAccelerateMin,
///   exitDuration: motionTokens.durationGentle,
/// });
/// ```
///
/// `Scale` carries `animateOpacity: true` by default, so the surface fades in
/// on the same duration and curve it grows on. Both halves are driven by this
/// one spec — see [fluentDialogOutScale] for the scale it starts from.
const FluentMotionSpec fluentDialogSurfaceEnter = FluentMotionSpec(
  duration: FluentDuration.gentle,
  curve: FluentCurve.decelerateMid,
);

/// The dialog surface leaving.
///
/// `curveAccelerateMin` over `durationGentle`, from the same variant. Unusually
/// for Fluent the exit is the *same length* as the entrance rather than
/// shorter; the variant overrides `Scale`'s default 200ms exit explicitly.
const FluentMotionSpec fluentDialogSurfaceExit = FluentMotionSpec(
  duration: FluentDuration.gentle,
  curve: FluentCurve.accelerateMin,
);

/// The scrim fading in and out.
///
/// `DialogBackdropMotion.ts` is one line — `export const DialogBackdropMotion =
/// FadeRelaxed` — and `FadeRelaxed` is `Fade` with `duration:
/// motionTokens.durationGentle`, keeping `Fade`'s default `curveEasyEase` and
/// its symmetric exit. So the scrim uses one spec in both directions.
const FluentMotionSpec fluentDialogScrim = FluentMotionSpec(
  duration: FluentDuration.gentle,
  curve: FluentCurve.easyEase,
);

/// The scale the surface enters from and exits to.
///
/// `Scale`'s default is 0.9; the dialog variant overrides it to 0.85.
const double fluentDialogOutScale = 0.85;

/// The glyph on the header's close button.
const IconData fluentDialogCloseIcon = FluentIcons.dismiss_20_regular;

/// Everything needed to render a dialog, independent of the design axes.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentDialog] takes this
/// rather than [FluentDialogState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentDialogBaseState {
  /// Creates a base state.
  const FluentDialogBaseState({
    required this.content,
    required this.actions,
    required this.secondaryActions,
    required this.stackActions,
    this.title,
    this.closeButton,
  });

  /// The body.
  final Widget content;

  /// The primary actions, laid out at the end of the row.
  final List<Widget> actions;

  /// The secondary actions, laid out at the start of the row.
  final List<Widget> secondaryActions;

  /// Whether the actions stack into a full-width column.
  ///
  /// Read by the renderer because it is geometry rather than styling, the same
  /// call `FluentTooltipBaseState.position` makes.
  final bool stackActions;

  /// The heading, or null for a dialog with no title.
  final Widget? title;

  /// The dismiss affordance in the header, or null when there is none.
  final Widget? closeButton;
}

/// A dialog's fully resolved state, including the design axes.
@immutable
class FluentDialogState extends FluentDialogBaseState {
  /// Creates a resolved state.
  const FluentDialogState({
    required super.content,
    required super.actions,
    required super.secondaryActions,
    required super.stackActions,
    required this.size,
    required this.modalType,
    super.title,
    super.closeButton,
  });

  /// Width and action layout.
  final FluentDialogSize size;

  /// Whether the dialog blocks the page, and how it may be dismissed.
  final FluentDialogModalType modalType;
}

/// Builds the state a dialog will be styled and rendered from.
///
/// The first of the three-function recomposition contract. [size] is the only
/// input to `stackActions`, which is why the renderer never has to read it.
FluentDialogState resolveFluentDialogState({
  required Widget content,
  FluentDialogSize size = FluentDialogSize.medium,
  FluentDialogModalType modalType = FluentDialogModalType.modal,
  List<Widget> actions = const <Widget>[],
  List<Widget> secondaryActions = const <Widget>[],
  Widget? title,
  Widget? closeButton,
}) => FluentDialogState(
  content: content,
  size: size,
  modalType: modalType,
  actions: actions,
  secondaryActions: secondaryActions,
  stackActions: size == FluentDialogSize.small,
  title: title,
  closeButton: closeButton,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour — least of all the scrim, which is
/// `colorBackgroundOverlay` and not a hand-rolled black.
///
/// Token sources are the Figma `Dialog` set (`9202:9382`, four variants over
/// `Size` x `Layout`), extracted into `test/fixtures/dialog.json`. That set has
/// **no State axis** — a dialog surface has no hover, pressed or disabled
/// rendering — so every property below is a single token rather than a ramp.
///
/// Two values come from `useDialogSurfaceStyles.styles.ts` rather than Figma,
/// because the design file is silent on both:
///
/// * the **scrim**. Figma draws no backdrop at all; upstream's `backdrop` slot
///   is `position: fixed; inset: 0; background: tokens.colorBackgroundOverlay`.
/// * the **surface border**. Figma paints no stroke; upstream declares
///   `${SURFACE_BORDER_WIDTH} solid ${tokens.colorTransparentStroke}`, which is
///   invisible in light and dark and turns into the text colour in high
///   contrast. Without it a dialog would have no outline there at all, which is
///   the same call `FluentSwitch`'s checked track already makes.
FluentDialogStyle resolveFluentDialogStyle(
  FluentDialogState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  return FluentDialogStyle(
    backgroundColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    foregroundColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    // Transparent, not absent: this turns into canvasText in high contrast,
    // where it is the only thing separating the surface from the scrim.
    borderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    // `Corner-radius/Modal/Large` in Figma, `borderRadiusXLarge` upstream.
    // Both are 8.
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allXLarge,
    ),
    scrimColor: FluentStateColor.tokens(rest: c.backgroundOverlay),
    shadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow64),
    ),
    // `Spacing/Horizontal/XXL` on all four sides in Figma; `SURFACE_PADDING`
    // is the string '24px' upstream.
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.xxl),
    ),
    // `Spacing/Vertical/S` on the surface frame; `DIALOG_GAP` upstream.
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    headerGap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    // Figma wraps the close button in a `Container for offset` whose only job
    // is this 4px lead-in.
    closeButtonPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.only(start: FluentSpacing.xs),
    ),
    actionsPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(top: FluentSpacing.xs),
    ),
    actionsGap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    // 20/28 Semibold in all four variants, which is `subtitle1` — the same
    // ramp step `useDialogTitleStyles` spreads.
    titleTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.subtitle1,
    ),
    bodyTextStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    maxWidth: WidgetStatePropertyAll<double?>(switch (state.size) {
      FluentDialogSize.small => 320.0,
      FluentDialogSize.medium => 600.0,
    }),
  );
}

/// Renders a dialog surface from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentDialogBaseState] rather than [FluentDialogState] on purpose: it never
/// reads the size or the modal type, so a consumer can supply their own style
/// and still use Fluent's layout. It renders the surface only — the scrim, the
/// focus trap and the entrance are [FluentDialog]'s concern, because all three
/// exist relative to the [Overlay] rather than to this box.
///
/// The content scrolls, so the surface has to sit in a **bounded-height**
/// parent — [FluentDialog] centres it in the overlay, which is exactly the
/// `maxHeight: 100vh` upstream pins on `DialogSurface`.
///
/// ## Motion
///
/// None here. The surface arrives and leaves through [fluentDialogSurfaceEnter]
/// and [fluentDialogSurfaceExit], which are applied by [FluentDialog] around
/// this widget — nothing inside the surface transitions, because upstream
/// declares no transition on any dialog part.
///
/// [states] is present for symmetry with the rest of the package. A dialog
/// surface is never hovered, pressed or focused as a whole, so callers normally
/// pass an empty set; `WidgetState.disabled` reaches the close button and
/// nothing else.
Widget buildFluentDialog(
  FluentDialogBaseState state,
  FluentDialogStyle style,
  Set<WidgetState> states,
) {
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final borderColor = style.borderColor?.resolve(states);
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allXLarge;
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.s;
  final headerGap = style.headerGap?.resolve(states) ?? FluentSpacing.s;
  final closePadding =
      style.closeButtonPadding?.resolve(states) ?? EdgeInsets.zero;
  final actionsPadding =
      style.actionsPadding?.resolve(states) ?? EdgeInsets.zero;
  final actionsGap = style.actionsGap?.resolve(states) ?? FluentSpacing.s;
  final titleStyle = style.titleTextStyle?.resolve(states);
  final bodyStyle = style.bodyTextStyle?.resolve(states);
  final maxWidth = style.maxWidth?.resolve(states) ?? double.infinity;

  final hasActions =
      state.actions.isNotEmpty || state.secondaryActions.isNotEmpty;

  final rows = <Widget>[
    if (state.title != null || state.closeButton != null)
      Row(
        // The close button is 32 tall against a 28 title line, and Figma lets
        // it overhang rather than centring it. Starting both keeps the glyph
        // level with the first line of a title that wraps.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: DefaultTextStyle.merge(
              style: (titleStyle ?? const TextStyle()).copyWith(
                color: foreground,
              ),
              child: state.title ?? const SizedBox.shrink(),
            ),
          ),
          if (state.closeButton != null) ...<Widget>[
            SizedBox(width: headerGap),
            Padding(padding: closePadding, child: state.closeButton!),
          ],
        ],
      ),
    // `useDialogContentStyles` is `overflowY: 'auto'` under a surface capped at
    // `maxHeight: ['100vh', '100dvh']`, so a body taller than the viewport
    // scrolls while the title and the actions stay put. `Flexible` is that cap:
    // the surface is centred in the overlay, which hands it the viewport as its
    // maximum height, and the body takes whatever the header and the actions
    // leave. Without it a long body is a RenderFlex overflow.
    Flexible(
      child: SingleChildScrollView(
        child: DefaultTextStyle.merge(
          style: (bodyStyle ?? const TextStyle()).copyWith(color: foreground),
          child: state.content,
        ),
      ),
    ),
    if (hasActions)
      Padding(padding: actionsPadding, child: _buildActions(state, actionsGap)),
  ];

  return ConstrainedBox(
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
      child: Padding(
        padding: padding,
        // stretch, so the surface takes the full `maxWidth` the way a fixed
        // block with `inset: 0; margin: auto` does, rather than hugging its
        // widest child.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: rows,
        ),
      ),
    ),
  );
}

/// The footer: one row with a start and an end group, or one stretched column.
///
/// Stacked, the secondary group comes first — upstream's breakpoint rules put
/// `position: start` on grid row 3 and `position: end` on row 4. Figma cannot
/// settle it: its `Left` group is hidden in all four variants.
Widget _buildActions(FluentDialogBaseState state, double gap) {
  if (state.stackActions) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: <Widget>[...state.secondaryActions, ...state.actions],
    );
  }
  return Row(
    mainAxisAlignment: state.secondaryActions.isEmpty
        ? MainAxisAlignment.end
        : MainAxisAlignment.spaceBetween,
    children: <Widget>[
      if (state.secondaryActions.isNotEmpty)
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: state.secondaryActions,
        ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: state.actions,
      ),
    ],
  );
}

/// Overrides the dialog style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. An [InheritedTheme], so it survives the trip into the
/// [Overlay] along with `FluentTheme`.
class FluentDialogTheme extends InheritedTheme {
  /// Applies [style] to every [FluentDialog] in [child].
  const FluentDialogTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size defaults.
  final FluentDialogStyle style;

  /// The nearest dialog style, or null.
  static FluentDialogStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentDialogTheme>()?.style;

  @override
  bool updateShouldNotify(FluentDialogTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDialogTheme(style: style, child: child);
}

/// A Fluent 2 dialog.
///
/// ```dart
/// FluentDialog(
///   open: open,
///   onOpenChange: (value) => setState(() => open = value),
///   title: const Text('Delete this file?'),
///   content: const Text('This cannot be undone.'),
///   actions: <Widget>[
///     FluentButton(
///       appearance: FluentButtonAppearance.primary,
///       onPressed: delete,
///       child: const Text('Delete'),
///     ),
///   ],
///   child: FluentButton(
///     onPressed: () => setState(() => open = true),
///     child: const Text('Delete'),
///   ),
/// )
/// ```
///
/// [child] is the trigger and stays where you put it; the surface is mounted
/// into the [Overlay] while [open] is true. Openness is **controlled** — this
/// widget never flips it on its own. Every dismissal path calls
/// [onOpenChange] with false and waits to be told.
///
/// Pass `onOpenChange: null` to make the dialog non-dismissible. That is a real
/// state, not a visual treatment: the close button becomes a genuinely disabled
/// [FluentButton], Escape does nothing, and a click on the scrim does nothing.
///
/// ## Positioning, and why there is no [CompositedTransformFollower]
///
/// A dialog is not anchored to its trigger. Upstream's surface is
/// `position: fixed; inset: 0; margin: auto`, which centres it in the viewport,
/// so linking it to the trigger's layer would move it with a button it has no
/// spatial relationship to. The surface is a centred [Overlay] child instead.
///
/// `FluentTheme` is an [InheritedTheme], and the themes between this widget and
/// the overlay are captured on the way in, so a `FluentThemeOverride` or a
/// [FluentDialogTheme] wrapping the trigger still reaches the surface.
///
/// ## Focus and keyboard
///
/// | | `modal` | `alert` | `nonModal` |
/// |---|---|---|---|
/// | Scrim | yes | yes | no |
/// | Click outside closes | yes | no | n/a |
/// | Tab trapped | yes | yes | no |
/// | Escape closes | yes | yes | yes |
///
/// A trapping dialog takes focus on open and hands it back to whatever held it
/// before, on close. A `nonModal` one never moves focus, so there is nothing to
/// return.
///
/// ## Motion
///
/// The surface scales from [fluentDialogOutScale] and fades in over
/// [fluentDialogSurfaceEnter], leaving over [fluentDialogSurfaceExit]; the
/// scrim fades on [fluentDialogScrim]. Under
/// [MediaQuery.disableAnimationsOf] every one of those jumps straight to its
/// end state — the dialog still appears and still disappears, it just does not
/// travel.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentDialogTheme] restyles a subtree; and [resolveFluentDialogState],
/// [resolveFluentDialogStyle] and [buildFluentDialog] are public so any one of
/// them can be replaced without forking this widget.
class FluentDialog extends StatefulWidget {
  /// Creates a dialog over [child].
  const FluentDialog({
    super.key,
    required this.child,
    required this.content,
    required this.open,
    this.onOpenChange,
    this.title,
    this.actions = const <Widget>[],
    this.secondaryActions = const <Widget>[],
    this.showCloseButton = true,
    this.modalType = FluentDialogModalType.modal,
    this.size = FluentDialogSize.medium,
    this.style,
    this.semanticLabel,
    this.closeButtonSemanticLabel,
  });

  /// The trigger. Stays in the tree whether the dialog is open or not.
  ///
  /// Pass `const SizedBox.shrink()` for a dialog opened from somewhere else.
  final Widget child;

  /// The body.
  ///
  /// Figma's `Body` frame spaces multiple paragraphs by 6; that gap belongs to
  /// whatever you put here, since this is one slot rather than a list.
  final Widget content;

  /// Whether the dialog is showing. Controlled — see [onOpenChange].
  final bool open;

  /// Invoked with false when the user asks to close.
  ///
  /// Null makes the dialog non-dismissible, which disables the close button and
  /// inerts Escape and the scrim.
  final ValueChanged<bool>? onOpenChange;

  /// The heading. Rendered in `subtitle1`.
  final Widget? title;

  /// The primary actions, at the end of the footer row.
  final List<Widget> actions;

  /// The secondary actions, at the start of the footer row.
  final List<Widget> secondaryActions;

  /// Whether the header carries a close button.
  ///
  /// True by default, which is Figma: all four variants draw a subtle icon
  /// button in the header. Upstream renders one by default only for
  /// `non-modal`, and this is the divergence Figma wins.
  final bool showCloseButton;

  /// Whether the dialog blocks the page, and how it may be dismissed.
  final FluentDialogModalType modalType;

  /// Width and action layout.
  final FluentDialogSize size;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDialogStyle? style;

  /// Announced by assistive technology as the dialog's name.
  final String? semanticLabel;

  /// Announced for the header's close button, which has no text of its own.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? closeButtonSemanticLabel;

  @override
  State<FluentDialog> createState() => _FluentDialogState();
}

class _FluentDialogState extends State<FluentDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: fluentDialogSurfaceEnter.duration,
    reverseDuration: fluentDialogSurfaceExit.duration,
  );

  late final CurvedAnimation _surfaceCurve = CurvedAnimation(
    parent: _controller,
    curve: fluentDialogSurfaceEnter.curve,
    reverseCurve: fluentDialogSurfaceExit.curve,
  );

  late final CurvedAnimation _scrimCurve = CurvedAnimation(
    parent: _controller,
    curve: fluentDialogScrim.curve,
    reverseCurve: fluentDialogScrim.curve,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: fluentDialogOutScale,
    end: 1,
  ).animate(_surfaceCurve);

  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'FluentDialog');

  OverlayEntry? _entry;
  FocusNode? _restore;
  bool _reducedMotion = false;

  late FluentThemeData _theme;
  FluentDialogStyle? _themeStyle;

  bool get _dismissible => widget.onOpenChange != null;

  bool get _traps => widget.modalType != FluentDialogModalType.nonModal;

  bool get _open => _entry != null;

  @override
  void initState() {
    super.initState();
    if (widget.open) {
      // Never from initState directly: inserting an OverlayEntry is a setState
      // on the Overlay, which is in a different branch and is mid-build.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.open) _show();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than in the overlay's builder: the overlay sits
    // outside this subtree, so a FluentThemeOverride or FluentDialogTheme
    // wrapping the trigger would otherwise be invisible to it.
    _theme = FluentTheme.of(context);
    _themeStyle = FluentDialogTheme.maybeOf(context);
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _applyReducedMotion();
    _deferOrRun(_repaint);
  }

  @override
  void didUpdateWidget(FluentDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      _deferOrRun(widget.open ? _show : _hide);
    } else {
      _deferOrRun(_repaint);
    }
  }

  @override
  void dispose() {
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    _scrimCurve.dispose();
    _surfaceCurve.dispose();
    _controller.dispose();
    _scope.dispose();
    super.dispose();
  }

  /// Clamps the controller when animations are switched off.
  ///
  /// Also covers reduced motion arriving mid-flight: whatever is in the air
  /// lands on this frame rather than finishing at full length. The durations
  /// are zeroed as well as the value, so anything reading the controller sees
  /// the truth rather than a 250ms claim it will not honour.
  void _applyReducedMotion() {
    if (!_reducedMotion) return;
    _controller
      ..duration = Duration.zero
      ..reverseDuration = Duration.zero;
    if (_controller.isAnimating) {
      _controller.value = _controller.status == AnimationStatus.reverse
          ? _controller.lowerBound
          : _controller.upperBound;
      if (!_open) return;
      if (_controller.value == _controller.lowerBound) _remove();
    }
  }

  /// Runs [action] now, unless a build is in flight.
  ///
  /// Inserting, removing or invalidating an [OverlayEntry] is a `setState` on
  /// the [Overlay], which sits in a different branch of the tree and has
  /// already been built by the time this widget rebuilds.
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

  void _repaint() => _entry?.markNeedsBuild();

  void _show() {
    if (_entry == null) {
      final overlay = Overlay.of(context, debugRequiredFor: widget);
      // FluentTheme is an InheritedTheme, so this carries it — and any other
      // InheritedTheme between here and the overlay, FluentDialogTheme
      // included — across the boundary.
      final captured = InheritedTheme.capture(
        from: context,
        to: overlay.context,
      );
      if (_traps) _restore = FocusManager.instance.primaryFocus;
      _entry = OverlayEntry(builder: (_) => captured.wrap(_buildOverlay()));
      overlay.insert(_entry!);
      if (_traps) {
        // Not `autofocus` on the FocusScope: autofocus only fires when the
        // ENCLOSING scope has nothing focused, and the trigger that opened the
        // dialog is exactly that something. Asking once the entry has been
        // built is what actually moves focus off the page and into the dialog.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && _open && _traps) _scope.requestFocus();
        });
      }
    }
    if (_reducedMotion) {
      // FadeTransition and ScaleTransition listen to the controller
      // themselves, so the entry does not need rebuilding for this to land.
      _controller.value = _controller.upperBound;
      return;
    }
    _controller.forward();
  }

  void _hide() {
    if (_entry == null) return;
    if (_reducedMotion) {
      _controller.value = _controller.lowerBound;
      _remove();
      return;
    }
    _controller.reverse().whenCompleteOrCancel(() {
      // Cancelled rather than finished when the dialog was re-opened mid-exit;
      // the entry has to survive that.
      if (mounted && _controller.status == AnimationStatus.dismissed) _remove();
    });
  }

  void _remove() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry
      ..remove()
      ..dispose();
    final restore = _restore;
    _restore = null;
    // context is null once the trigger has left the tree, and asking a
    // detached node for focus throws.
    if (restore != null && restore.context != null) restore.requestFocus();
  }

  void _requestClose() {
    if (!_dismissible) return;
    widget.onOpenChange!(false);
  }

  FluentDialogState _state() => resolveFluentDialogState(
    content: widget.content,
    size: widget.size,
    modalType: widget.modalType,
    actions: widget.actions,
    secondaryActions: widget.secondaryActions,
    title: widget.title,
    closeButton: widget.showCloseButton
        ? FluentButton.icon(
            icon: const Icon(fluentDialogCloseIcon),
            semanticLabel:
                widget.closeButtonSemanticLabel ?? fluentL10n(context).close,
            appearance: FluentButtonAppearance.subtle,
            onPressed: _dismissible ? _requestClose : null,
          )
        : null,
  );

  Widget _buildOverlay() {
    final state = _state();
    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final style = resolveFluentDialogStyle(
      state,
      _theme,
    ).merge(_themeStyle).merge(widget.style);

    // A dialog surface has no interaction states of its own. `disabled` is
    // carried so a consumer's style can react to a non-dismissible dialog; the
    // close button reaches its own disabled tokens through FluentButton.
    final states = <WidgetState>{if (!_dismissible) WidgetState.disabled};

    final scrim = style.scrimColor?.resolve(states);

    final surface = FadeTransition(
      opacity: _surfaceCurve,
      child: ScaleTransition(
        scale: _scale,
        child: buildFluentDialog(state, style, states),
      ),
    );

    Widget content = Stack(
      children: <Widget>[
        if (_traps && scrim != null)
          Positioned.fill(
            child: FadeTransition(
              opacity: _scrimCurve,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Alert renders the scrim but refuses to be dismissed by it:
                // upstream only calls requestOpenChange on backdropClick when
                // modalType is exactly 'modal'.
                onTap:
                    widget.modalType == FluentDialogModalType.modal &&
                        _dismissible
                    ? _requestClose
                    : null,
                // A real token, never Colors.transparent: colorBackgroundOverlay
                // stays a defined colour in high contrast.
                child: ColoredBox(color: scrim),
              ),
            ),
          ),
        // Not Positioned.fill'd around a barrier: with no scrim the page behind
        // must stay clickable, and a Center hit-tests only its child.
        Positioned.fill(child: Center(child: surface)),
      ],
    );

    if (_traps) {
      // The scope holds focus, so Tab and Shift+Tab walk only its own
      // descendants — which is what "trapped" means to the traversal policy.
      content = BlockSemantics(
        child: FocusScope(node: _scope, child: content),
      );
    }

    // Outside the FocusScope, not inside it. An Action is found by walking
    // *up* from the focused node's context, and the focused node here is the
    // scope itself — an Actions under it would never be reached, and Escape
    // would silently do nothing.
    content = Actions(
      actions: <Type, Action<Intent>>{
        DismissIntent: _DismissDialogAction(this),
      },
      child: content,
    );

    return Semantics(
      scopesRoute: _traps,
      namesRoute: _traps && widget.semanticLabel != null,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bound around the trigger as well as around the surface: a nonModal dialog
    // never takes focus, so Escape has to reach this copy to close it.
    return Actions(
      actions: <Type, Action<Intent>>{
        DismissIntent: _DismissDialogAction(this),
      },
      child: widget.child,
    );
  }
}

/// Closes the dialog on Escape, and only while there is one to close.
class _DismissDialogAction extends Action<DismissIntent> {
  _DismissDialogAction(this.state);

  final _FluentDialogState state;

  @override
  bool isEnabled(DismissIntent intent) => state._open && state._dismissible;

  @override
  Object? invoke(DismissIntent intent) {
    state._requestClose();
    return null;
  }
}
