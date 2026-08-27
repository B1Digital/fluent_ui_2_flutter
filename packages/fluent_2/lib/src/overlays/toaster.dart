import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/defer.dart';
import '../internal/focus_ring.dart';
import '../internal/input_modality.dart';
import 'toast.dart';
import 'toast_style.dart';

/// The toast container's height expanding on entrance.
///
/// Transcribed from `CollapseDelayed` in
/// `react-motion-components-preview/library/src/components/Collapse/Collapse.ts`,
/// which is what `renderToastContainer.tsx` wraps every toast in:
///
/// ```ts
/// export const CollapseDelayed = createPresenceComponentVariant(Collapse, {
///   sizeDuration: motionTokens.durationNormal,        // 200ms
///   opacityDuration: motionTokens.durationSlower,     // 400ms
///   staggerDelay: motionTokens.durationNormal,        // 200ms
///   exitSizeDuration: motionTokens.durationNormal,    // 200ms
///   exitOpacityDuration: motionTokens.durationSlower, // 400ms
///   exitStaggerDelay: motionTokens.durationSlower,    // 400ms
///   easing: motionTokens.curveEasyEase,
///   exitEasing: motionTokens.curveEasyEase,
/// });
/// ```
///
/// Note the easing is `curveEasyEase`, not the plain `Collapse`'s
/// `curveEasyEaseMax` — the variant overrides it — which is why this does not
/// reuse `FluentMotionSpec.collapse`.
const FluentMotionSpec fluentToastSizeEnter = FluentMotionSpec(
  duration: FluentDuration.normal,
  curve: FluentCurve.easyEase,
);

/// The toast container fading in, which **starts** once the height has finished
/// expanding — `staggerDelay` is `durationNormal`, exactly the size duration.
const FluentMotionSpec fluentToastFadeEnter = FluentMotionSpec(
  duration: FluentDuration.slower,
  curve: FluentCurve.easyEase,
);

/// How long the fade waits before starting on entrance.
const Duration fluentToastEnterStagger = FluentDuration.normal;

/// The toast container fading out, which starts immediately on exit.
const FluentMotionSpec fluentToastFadeExit = FluentMotionSpec(
  duration: FluentDuration.slower,
  curve: FluentCurve.easyEase,
);

/// The toast container's height collapsing, which **starts** once the fade has
/// finished — `exitStaggerDelay` is `durationSlower`, exactly the fade
/// duration.
const FluentMotionSpec fluentToastSizeExit = FluentMotionSpec(
  duration: FluentDuration.normal,
  curve: FluentCurve.easyEase,
);

/// How long the collapse waits before starting on exit.
const Duration fluentToastExitStagger = FluentDuration.slower;

/// Wall-clock length of the whole entrance: the fade's 200ms delay plus its
/// 400ms run. The size expansion finishes inside that window.
const Duration fluentToastEnterDuration = Duration(milliseconds: 600);

/// Wall-clock length of the whole exit: the collapse's 400ms delay plus its
/// 200ms run. The fade finishes exactly as the collapse begins.
const Duration fluentToastExitDuration = Duration(milliseconds: 600);

/// How long a toast stays up before dismissing itself.
///
/// `createToaster.ts` says `timeout: 3000`.
const Duration fluentToastTimeout = Duration(milliseconds: 3000);

/// Where a stack of toasts is anchored. Upstream's `TOAST_POSITIONS`, verbatim.
enum FluentToastPosition {
  /// Top leading corner. Upstream `top-start`.
  topStart,

  /// Top centre. Upstream `top`.
  top,

  /// Top trailing corner. Upstream `top-end`.
  topEnd,

  /// Bottom leading corner. Upstream `bottom-start`.
  bottomStart,

  /// Bottom centre. Upstream `bottom`.
  bottom,

  /// Bottom trailing corner. Upstream `bottom-end`. The default.
  bottomEnd;

  /// Whether this anchors to the top edge rather than the bottom.
  bool get isTop =>
      this == FluentToastPosition.topStart ||
      this == FluentToastPosition.top ||
      this == FluentToastPosition.topEnd;

  /// Whether this is horizontally centred rather than cornered.
  bool get isCentred =>
      this == FluentToastPosition.top || this == FluentToastPosition.bottom;

  /// Whether this anchors to the leading edge in reading order.
  bool get isStart =>
      this == FluentToastPosition.topStart ||
      this == FluentToastPosition.bottomStart;
}

/// Builds one toast's content. [id] is the handle the toast needs to dismiss
/// itself — `onDismiss: () => controller.dismiss(id)`.
typedef FluentToastBuilder = Widget Function(BuildContext context, Object id);

/// One toast in a [FluentToastController]'s queue.
///
/// Immutable: dismissing replaces the entry with a copy whose [visible] is
/// false, and the entry is dropped only once its exit motion has finished.
@immutable
class FluentToastEntry {
  /// Creates an entry. Prefer [FluentToastController.show], which allocates the
  /// id and captures the focus to return to.
  const FluentToastEntry({
    required this.id,
    required this.builder,
    required this.position,
    required this.timeout,
    required this.pauseOnHover,
    this.visible = true,
    this.trigger,
  });

  /// Uniquely identifies this toast. Pass it to
  /// [FluentToastController.dismiss].
  final Object id;

  /// Builds the toast's content.
  final FluentToastBuilder builder;

  /// Which corner this toast stacks in.
  final FluentToastPosition position;

  /// How long before it dismisses itself. [Duration.zero] never auto-dismisses.
  final Duration timeout;

  /// Whether the timeout stops while a pointer is over the toast.
  final bool pauseOnHover;

  /// False once dismissal has been requested — the toast is running its exit
  /// motion and will be removed when that finishes.
  final bool visible;

  /// What had keyboard focus when this toast was raised, so focus can be handed
  /// back if the toast took it.
  final FocusNode? trigger;

  /// This entry with [visible] set to false.
  FluentToastEntry get dismissed => FluentToastEntry(
    id: id,
    builder: builder,
    position: position,
    timeout: timeout,
    pauseOnHover: pauseOnHover,
    visible: false,
    trigger: trigger,
  );
}

/// Enqueues and dismisses toasts for a [FluentToaster].
///
/// ```dart
/// final controller = FluentToastController();
/// // ...
/// controller.show(
///   (context, id) => FluentToast(
///     intent: FluentToastIntent.success,
///     title: const Text('Mail sent'),
///     onDismiss: () => controller.dismiss(id),
///   ),
/// );
/// ```
///
/// A plain [ChangeNotifier] the app owns, rather than an ambient event bus:
/// upstream keys its bus by `toasterId` precisely because the DOM gives it no
/// other way to reach a specific toaster, and Flutter does. Hold one per
/// toaster and pass it in.
///
/// Dispose it with the state that owns it.
class FluentToastController extends ChangeNotifier {
  final List<FluentToastEntry> _entries = <FluentToastEntry>[];
  int _serial = 0;

  /// Every queued toast, oldest first. Includes toasts that are dismissing.
  List<FluentToastEntry> get entries =>
      List<FluentToastEntry>.unmodifiable(_entries);

  /// Enqueues a toast and returns its id.
  ///
  /// [timeout] of [Duration.zero] keeps the toast up until it is dismissed.
  ///
  /// [pauseOnHover] defaults to **true**, where upstream's `createToaster.ts`
  /// defaults it to `false`. That is a deliberate divergence: a notification
  /// that expires while the pointer is resting on it is unreadable, and the
  /// only reason it is off upstream is that the DOM cannot see hover through a
  /// portal that sets `pointer-events: none`.
  ///
  /// Passing an [id] that is already queued replaces that toast in place,
  /// keeping its slot in the stack — upstream's `updateToast`.
  Object show(
    FluentToastBuilder builder, {
    Object? id,
    FluentToastPosition position = FluentToastPosition.bottomEnd,
    Duration timeout = fluentToastTimeout,
    bool pauseOnHover = true,
  }) {
    final key = id ?? 'fluent-toast-${_serial++}';
    final entry = FluentToastEntry(
      id: key,
      builder: builder,
      position: position,
      timeout: timeout,
      pauseOnHover: pauseOnHover,
      // Captured here rather than when the toast takes focus: `show` runs from
      // the trigger's own callback, so this IS the trigger. By the time a toast
      // has focus, the node that had it is no longer `primaryFocus`.
      trigger: FocusManager.instance.primaryFocus,
    );
    final existing = _indexOf(key);
    if (existing >= 0) {
      _entries[existing] = entry;
    } else {
      _entries.add(entry);
    }
    notifyListeners();
    return key;
  }

  /// Starts the exit motion for the toast with [id]. A no-op if it is unknown
  /// or already dismissing.
  void dismiss(Object id) {
    final index = _indexOf(id);
    if (index < 0 || !_entries[index].visible) return;
    _entries[index] = _entries[index].dismissed;
    notifyListeners();
  }

  /// Starts the exit motion for every visible toast.
  void dismissAll() {
    var changed = false;
    for (var i = 0; i < _entries.length; i++) {
      if (!_entries[i].visible) continue;
      _entries[i] = _entries[i].dismissed;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Drops a toast whose exit motion has finished.
  ///
  /// Called by [FluentToaster] once the collapse completes; prefer [dismiss],
  /// which animates.
  void remove(Object id) {
    final index = _indexOf(id);
    if (index < 0) return;
    _entries.removeAt(index);
    notifyListeners();
  }

  int _indexOf(Object id) {
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].id == id) return i;
    }
    return -1;
  }
}

/// Renders a [FluentToastController]'s toasts into the nearest [Overlay].
///
/// ```dart
/// FluentApp(
///   builder: (context, child) =>
///       FluentToaster(controller: controller, child: child!),
///   home: const Home(),
/// )
/// ```
///
/// [child] is returned unchanged; the toasts go into the [Overlay] above it, so
/// they escape every ancestor clip and paint over the whole app.
///
/// ## The theme crosses the overlay boundary
///
/// `FluentTheme` and [FluentToastTheme] are both [InheritedTheme]s, and
/// `InheritedTheme.capture` is taken from **this widget's** context on the way
/// into the overlay. A `FluentThemeOverride` or a [FluentToastTheme] wrapping
/// the toaster therefore reaches the toasts, even though the overlay builds in
/// a different branch of the tree. Resolving inside the overlay's own builder
/// would silently pick up the app root's theme instead, which is the single
/// most likely thing to be quietly wrong about an overlay component.
///
/// ## Focus
///
/// A toast is **not modal**: it does not take focus when it appears, does not
/// trap Tab, and lays no scrim. Upstream is the same — `useToasterStyles` sets
/// `pointer-events: none` on the container and reaches toasts through an
/// explicit keyboard shortcut — and a notification that stole focus mid-typing
/// would be a bug rather than a feature.
///
/// What it does do:
///
/// * each toast is a real tab stop with a Fluent focus ring;
/// * Escape dismisses the focused toast;
/// * dismissing a toast that **holds** focus hands focus back to whatever had
///   it when the toast was raised, which is normally the button that raised it.
///
/// ## Motion
///
/// Every toast enters and leaves on upstream's `CollapseDelayed` — see
/// [fluentToastSizeEnter]. Under `MediaQuery.disableAnimationsOf` nothing runs:
/// an entering toast is at full height and full opacity on its first frame, and
/// a dismissed one is gone on the frame it is dismissed.
///
/// The auto-dismiss countdown is a ticker rather than a timer, which is how
/// hover can pause and *resume* it instead of restarting it — upstream flips a
/// CSS `animation-play-state` for the same reason. Two consequences worth
/// knowing: the countdown is **not** shortened by reduced motion, because it is
/// a clock and not a transition; and `WidgetTester.pumpAndSettle` on a toaster
/// holding a timed toast will run that clock out rather than returning early.
class FluentToaster extends StatefulWidget {
  /// Renders [controller]'s toasts over [child].
  const FluentToaster({
    super.key,
    required this.controller,
    required this.child,
    this.style,
    this.offset = const EdgeInsets.symmetric(
      horizontal: FluentSpacing.xl,
      vertical: FluentSpacing.l,
    ),
  });

  /// The queue to render.
  final FluentToastController controller;

  /// The app below the toasts. Returned unchanged.
  final Widget child;

  /// Overrides layered over the theme defaults for every toast this toaster
  /// renders. Applied as a [FluentToastTheme], so an individual toast's own
  /// `style` still wins.
  final FluentToastStyle? style;

  /// Inset from the edges of the overlay.
  ///
  /// `getPositionStyles.ts` defaults to `horizontal: 20, vertical: 16`, with
  /// the horizontal component ignored for the two centred positions.
  final EdgeInsets offset;

  @override
  State<FluentToaster> createState() => _FluentToasterState();
}

class _FluentToasterState extends State<FluentToaster> {
  OverlayEntry? _entry;
  CapturedThemes? _captured;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captured from THIS context, so a FluentThemeOverride or FluentToastTheme
    // wrapping the toaster survives the trip into the Overlay. Re-captured on
    // every dependency change, so a theme swap repaints live toasts.
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    _captured = InheritedTheme.capture(from: context, to: overlay.context);
    deferOrRun(_sync);
  }

  @override
  void didUpdateWidget(FluentToaster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      widget.controller.addListener(_handleChange);
    }
    deferOrRun(_sync);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    super.dispose();
  }

  void _handleChange() => deferOrRun(_sync);

  void _sync() {
    if (!mounted) return;
    if (widget.controller.entries.isEmpty) {
      _entry
        ?..remove()
        ..dispose();
      _entry = null;
      return;
    }
    if (_entry == null) {
      _entry = OverlayEntry(builder: (_) => _captured!.wrap(_buildStacks()));
      Overlay.of(context, debugRequiredFor: widget).insert(_entry!);
      return;
    }
    _entry!.markNeedsBuild();
  }

  void _handleExitDone(Object id) =>
      deferOrRun(() => widget.controller.remove(id));

  Widget _buildStacks() {
    final entries = widget.controller.entries;
    final stacks = <Widget>[
      for (final position in FluentToastPosition.values)
        if (entries.any((e) => e.position == position))
          _buildStack(
            position,
            entries.where((e) => e.position == position).toList(),
          ),
    ];

    Widget content = Stack(children: stacks);
    final style = widget.style;
    if (style != null) {
      content = FluentToastTheme(style: style, child: content);
    }
    // Directionality is NOT an InheritedTheme, so the capture at :383 leaves it
    // behind and the entry builds under the Overlay's own direction — the
    // `PositionedDirectional` in `_buildStack` would then pin an RTL app's
    // toasts to the LTR corner, and every toast's own content would read LTR.
    // Read from *this* widget's context, not the overlay's, exactly as
    // `drawer.dart:755` does for its panel.
    return Directionality(
      textDirection: Directionality.of(context),
      child: content,
    );
  }

  Widget _buildStack(
    FluentToastPosition position,
    List<FluentToastEntry> entries,
  ) {
    // Insertion order, top to bottom, in every position. A bottom-anchored
    // Positioned pins its bottom edge, so appending grows the block upward and
    // the newest toast is the one nearest that edge — which is what the browser
    // does with `position: fixed; bottom: 16`.
    //
    // CrossAxisAlignment.center rather than stretch: only one horizontal edge is
    // pinned for a cornered stack, so the column is laid out with an unbounded
    // width and a stretching child would have nothing finite to stretch to. Each
    // toast carries its own fixed width instead.
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final entry in entries)
          _FluentToastContainer(
            key: ValueKey<Object>(entry.id),
            entry: entry,
            onDismiss: widget.controller.dismiss,
            onExitDone: _handleExitDone,
          ),
      ],
    );

    final vertical = widget.offset.top;
    final top = position.isTop ? vertical : null;
    final bottom = position.isTop ? null : vertical;

    if (position.isCentred) {
      return Positioned(
        top: top,
        bottom: bottom,
        left: 0,
        right: 0,
        child: Center(child: column),
      );
    }
    // Directional, so `start` and `end` follow reading order and an RTL app
    // puts its toasts in the mirrored corner.
    return PositionedDirectional(
      top: top,
      bottom: bottom,
      start: position.isStart ? widget.offset.left : null,
      end: position.isStart ? null : widget.offset.left,
      child: column,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One toast's box: the stack gap, the entrance and exit motion, the
/// auto-dismiss timer, the focus stop and the Escape binding.
class _FluentToastContainer extends StatefulWidget {
  const _FluentToastContainer({
    super.key,
    required this.entry,
    required this.onDismiss,
    required this.onExitDone,
  });

  final FluentToastEntry entry;
  final ValueChanged<Object> onDismiss;
  final ValueChanged<Object> onExitDone;

  @override
  State<_FluentToastContainer> createState() => _FluentToastContainerState();
}

class _FluentToastContainerState extends State<_FluentToastContainer>
    with TickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: fluentToastEnterDuration,
  );

  /// The auto-dismiss countdown, run as a ticker rather than a timer.
  ///
  /// This is upstream's own model: `ToastContainer` renders a `timer` element
  /// whose CSS animation ends the toast, and hover flips its
  /// `animation-play-state` — so pausing **resumes** where it stopped rather
  /// than restarting. An `AnimationController` gives exactly that for free, and
  /// unlike a `Timer` plus a `Stopwatch` it runs on the scheduler's clock, so
  /// it is faked in widget tests along with everything else.
  ///
  /// It is deliberately **not** clamped by `MediaQuery.disableAnimations`: this
  /// is a clock, not a transition, and shortening it would make every toast
  /// vanish instantly for the users least able to read it quickly.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: fluentToastTimeout,
  );

  final FocusNode _focusNode = FocusNode(debugLabel: 'FluentToast');

  bool _exiting = false;
  bool _reducedMotion = false;
  bool _focusVisible = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _motion.addStatusListener(_handleMotionStatus);
    _clock.addStatusListener(_handleClockStatus);
    FluentInputModality.keyboard.addListener(_handleModalityChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      // Jump to the end state rather than running. This also covers reduced
      // motion being switched on mid-flight: whatever is in the air lands on
      // this frame instead of finishing at full length.
      _motion
        ..duration = Duration.zero
        ..value = _motion.upperBound;
      if (_exiting) _finishExit();
    } else if (!_exiting && _motion.status == AnimationStatus.dismissed) {
      _motion.forward();
    }
    _syncClock();
  }

  @override
  void didUpdateWidget(_FluentToastContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.entry.visible && !_exiting) {
      _startExit();
      return;
    }
    if (widget.entry.timeout != oldWidget.entry.timeout ||
        widget.entry.pauseOnHover != oldWidget.entry.pauseOnHover) {
      _syncClock();
    }
  }

  @override
  void dispose() {
    FluentInputModality.keyboard.removeListener(_handleModalityChange);
    _clock
      ..removeStatusListener(_handleClockStatus)
      ..dispose();
    _motion
      ..removeStatusListener(_handleMotionStatus)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---- timeout ------------------------------------------------------------

  /// Starts, pauses or stops the countdown to match the current state.
  ///
  /// `AnimationController.forward` from a partial value runs only the remaining
  /// fraction of its duration, which is what makes a pause a pause rather than
  /// a reset: a toast held at 2.9s of 3s still has 100ms left when the pointer
  /// leaves.
  void _syncClock() {
    final timeout = widget.entry.timeout;
    if (_exiting || timeout <= Duration.zero) {
      _clock.stop();
      return;
    }
    _clock.duration = timeout;
    if (_hovered && widget.entry.pauseOnHover) {
      _clock.stop();
      return;
    }
    if (!_clock.isAnimating && _clock.status != AnimationStatus.completed) {
      _clock.forward();
    }
  }

  void _handleClockStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_exiting) {
      widget.onDismiss(widget.entry.id);
    }
  }

  void _handleHover({required bool value}) {
    _hovered = value;
    _syncClock();
  }

  // ---- focus --------------------------------------------------------------

  // The ring is keyboard-visible focus, not bare focus: [FluentInputModality]
  // is the keyborg flag `react-tabster` ANDs against, and unlike
  // `FocusHighlightMode` it tells a mouse click apart from a key press. The
  // listener covers the flip that arrives while focus stays put.
  void _handleModalityChange() => _setFocusVisible(
    _focusNode.hasFocus && FluentInputModality.keyboard.value,
  );

  void _handleFocusChange({required bool value}) =>
      _setFocusVisible(value && FluentInputModality.keyboard.value);

  void _setFocusVisible(bool value) {
    if (!mounted || value == _focusVisible) return;
    setState(() => _focusVisible = value);
  }

  // ---- motion -------------------------------------------------------------

  void _startExit() {
    _exiting = true;
    _clock.stop();
    if (_reducedMotion) {
      _finishExit();
      return;
    }
    _motion
      ..duration = fluentToastExitDuration
      ..forward(from: 0);
  }

  void _handleMotionStatus(AnimationStatus status) {
    if (_exiting && status == AnimationStatus.completed) _finishExit();
  }

  /// Hands focus back to the trigger, then drops the toast.
  void _finishExit() {
    // `context != null` before requesting: a toast routinely outlives whatever
    // opened it, and requesting focus on a detached node is a silent no-op that
    // also keeps the unmounted widget's node alive for the toast's lifetime.
    // The other three overlays guard the same way.
    final trigger = widget.entry.trigger;
    if (_focusNode.hasFocus &&
        trigger != null &&
        trigger.context != null &&
        trigger.canRequestFocus) {
      trigger.requestFocus();
    }
    widget.onExitDone(widget.entry.id);
  }

  // ---- CollapseDelayed ----------------------------------------------------

  /// `curveEasyEase` applied over the sub-interval `[begin, end]` of the run.
  static double _stage(double t, double begin, double end) {
    final progress = (t - begin) / (end - begin);
    return FluentCurve.easyEase.transform(
      progress < 0
          ? 0
          : progress > 1
          ? 1
          : progress,
    );
  }

  static final double _enterSizeEnd =
      fluentToastSizeEnter.duration.inMilliseconds /
      fluentToastEnterDuration.inMilliseconds;
  static final double _enterFadeBegin =
      fluentToastEnterStagger.inMilliseconds /
      fluentToastEnterDuration.inMilliseconds;
  static final double _exitFadeEnd =
      fluentToastFadeExit.duration.inMilliseconds /
      fluentToastExitDuration.inMilliseconds;
  static final double _exitSizeBegin =
      fluentToastExitStagger.inMilliseconds /
      fluentToastExitDuration.inMilliseconds;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    widget.onDismiss(widget.entry.id);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: the container needs three numbers off the style — the stack
    // gap, the surface width and the radius the focus ring follows — so it
    // resolves the intent-independent defaults against a throwaway state rather
    // than duplicating them as constants that could drift from the toast's.
    final style = resolveFluentToastStyle(
      resolveFluentToastState(title: const SizedBox.shrink()),
      FluentTheme.of(context),
    ).merge(FluentToastTheme.maybeOf(context));
    const states = <WidgetState>{};
    final gap = style.stackGap?.resolve(states) ?? FluentSpacing.l;
    final width = style.width?.resolve(states) ?? 292;
    final radius =
        style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;

    // Built outside the AnimatedBuilder: the toast itself does not depend on
    // the animation value, so an identical widget instance short-circuits its
    // own rebuild on every one of the 600ms worth of frames.
    final toast = Padding(
      // The gap belongs INSIDE the collapsing box, so a leaving toast takes its
      // whitespace with it — upstream's `whitespaceAtom` animates the margin
      // alongside the height rather than leaving a hole behind.
      padding: EdgeInsets.only(top: gap),
      child: FluentFocusRing(
        visible: _focusVisible,
        borderRadius: radius,
        child: MouseRegion(
          onEnter: (_) => _handleHover(value: true),
          onExit: (_) => _handleHover(value: false),
          child: Builder(
            builder: (context) =>
                widget.entry.builder(context, widget.entry.id),
          ),
        ),
      ),
    );

    return SizedBox(
      // Fixed here rather than on the toast, so the collapsing Align below has
      // a bounded width to work against inside an unbounded column.
      width: width,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (value) => _handleFocusChange(value: value),
        // Escape dismisses the focused toast, and only the focused one — an
        // Escape with focus elsewhere still reaches whatever an ancestor does
        // with it.
        onKeyEvent: _handleKey,
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, child) {
            final t = _motion.value;
            final (size, opacity) = _exiting
                ? (
                    1 - _stage(t, _exitSizeBegin, 1),
                    1 - _stage(t, 0, _exitFadeEnd),
                  )
                : (_stage(t, 0, _enterSizeEnd), _stage(t, _enterFadeBegin, 1));
            return ClipRect(
              child: Align(
                // Collapse towards the anchored edge, so the stack does not
                // appear to slide past the corner it is pinned to.
                alignment: widget.entry.position.isTop
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                heightFactor: size,
                child: Opacity(opacity: opacity, child: child),
              ),
            );
          },
          child: toast,
        ),
      ),
    );
  }
}
