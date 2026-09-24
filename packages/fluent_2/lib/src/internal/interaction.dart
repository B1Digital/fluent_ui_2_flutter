import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kSecondaryMouseButton;
import 'package:flutter/widgets.dart';

import 'input_modality.dart';

/// Selects a Fluent colour token for the current interaction state.
///
/// Fluent ships explicit `*Hover` / `*Pressed` / `*Selected` / `*Disabled`
/// variants for nearly every colour, so this **selects** a token — it never
/// computes one. If you find yourself reaching for `withOpacity` to make a hover
/// colour, you are using the wrong token.
///
/// ```dart
/// FluentStateColor.tokens(
///   rest: t.colors.neutralBackground1,
///   hover: t.colors.neutralBackground1Hover,
///   pressed: t.colors.neutralBackground1Pressed,
///   disabled: t.colors.neutralBackgroundDisabled,
/// )
/// ```
abstract final class FluentStateColor {
  /// A [WidgetStateProperty] over a Fluent token set.
  ///
  /// Omitted states fall back to [rest] rather than being derived, which keeps
  /// a partially-specified set honest instead of inventing values.
  ///
  /// Precedence matches upstream: disabled, then pressed, then hovered, then
  /// selected.
  static WidgetStateProperty<Color> tokens({
    required Color rest,
    Color? hover,
    Color? pressed,
    Color? selected,
    Color? disabled,
  }) => WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return disabled ?? rest;
    if (states.contains(WidgetState.pressed)) return pressed ?? rest;
    if (states.contains(WidgetState.hovered)) return hover ?? rest;
    if (states.contains(WidgetState.selected)) return selected ?? rest;
    return rest;
  });
}

/// Builds a subtree from the current set of interaction states.
typedef FluentInteractiveBuilder =
    Widget Function(
      BuildContext context,
      Set<WidgetState> states,
      Widget? child,
    );

/// Resolves hover, press, focus and disabled once, for every interactive
/// component to share.
///
/// Reports the framework's own [WidgetState] set rather than a bespoke enum, so
/// component styles can be plain [WidgetStateProperty] structs in the same shape
/// as Material's `ButtonStyle` — familiar to any Flutter developer, and with no
/// Material dependency, since the `WidgetState` family lives in the widgets
/// layer.
///
/// Built on [FocusableActionDetector]. Its `onShowFocusHighlight` is only half
/// of upstream's keyborg-driven `data-fui-focus-visible`: the framework's
/// highlight mode is touch-vs-not-touch, so on desktop and web it fires for
/// pointer focus too. ANDing it with `FluentInputModality.keyboard` gives the
/// upstream behaviour — focus reached by pointer raises no ring, focus reached
/// by keyboard does.
class FluentInteractive extends StatefulWidget {
  /// Creates an interaction surface.
  const FluentInteractive({
    super.key,
    required this.builder,
    this.onPressed,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor = SystemMouseCursors.click,
    this.disabledMouseCursor = SystemMouseCursors.forbidden,
    this.pressedOnSecondary = true,
    this.pressedRequiresHover = false,
    this.child,
  });

  /// Builds the visuals from the live state set.
  ///
  /// While enabled, the set is the controller's own, mutated in place by
  /// [WidgetStatesController]. Every build therefore hands out the *same*
  /// `Set` instance, so a `oldStates != states` comparison in a
  /// `didUpdateWidget` downstream is silently always false. Read it during the
  /// build; copy it if it has to outlive one. While disabled it is just
  /// `{WidgetState.disabled}`.
  final FluentInteractiveBuilder builder;

  /// Invoked on tap and on Space/Enter. Never invoked while disabled.
  final VoidCallback? onPressed;

  /// When false, [WidgetState.disabled] is set, every other interaction state is
  /// suppressed, focus is refused and [onPressed] never fires.
  final bool enabled;

  /// Focus node to use. One is created and disposed here when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Cursor shown while hovering an enabled surface.
  final MouseCursor mouseCursor;

  /// Cursor shown while hovering a disabled surface.
  ///
  /// Upstream's disabled buttons, links, menu items, tabs, tags, swatches and
  /// accordion headers all write `cursor: 'not-allowed'`. Checkbox, Radio,
  /// Switch, Slider, ListItem and listbox options write `cursor: 'default'`
  /// instead, so pass [SystemMouseCursors.basic] there.
  final MouseCursor disabledMouseCursor;

  /// Whether a held right mouse press reports [WidgetState.pressed].
  ///
  /// Chrome sets `:active` under whichever button is held, and upstream's
  /// buttons, menu items, tabs, links and listbox options all paint their
  /// pressed tokens under a right press. Upstream's Combobox-family roots do
  /// not — they lose `:active` a task after the press's `contextmenu` — so
  /// pass false there. A middle press is pressed either way.
  final bool pressedOnSecondary;

  /// Whether a mouse press reports [WidgetState.pressed] only while the
  /// pointer is over the control.
  ///
  /// Upstream's Button family, Switch, Radio, ColorSwatch, InfoButton and
  /// Calendar cells style pressed as `:hover:active`, so a held press dragged
  /// off falls back to rest, and dragged back presses again. Controls styled
  /// with a plain `:active` (tabs, tree items, tags, sliders, text fields)
  /// keep pressed until release, which is the default. A touch press has no
  /// hover to lose and stays pressed either way.
  final bool pressedRequiresHover;

  /// Passed through to [builder] unchanged, for subtrees that do not depend on
  /// state and should not rebuild with it.
  final Widget? child;

  @override
  State<FluentInteractive> createState() => _FluentInteractiveState();
}

class _FluentInteractiveState extends State<FluentInteractive> {
  final WidgetStatesController _controller = WidgetStatesController();
  FocusNode? _internalNode;

  /// A press is held on the surface, and whether a mouse holds it. With
  /// [FluentInteractive.pressedRequiresHover], [_syncPressed] turns these and
  /// the hover into [WidgetState.pressed].
  bool _held = false;
  bool _heldByMouse = false;

  /// The framework's own answer to "should a focus highlight be drawn", which
  /// is only half of focus-visible — see [_syncFocusVisible].
  bool _highlight = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _enabled => widget.enabled && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStatesChanged);
    FluentInputModality.keyboard.addListener(_syncFocusVisible);
  }

  @override
  void didUpdateWidget(FluentInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chrome drops a held <button>'s `:active` as it is disabled, and a
    // re-enable under the same press does not bring it back. Only on that
    // edge: a press that lands while disabled is `:active` once enabled.
    if (oldWidget.enabled && oldWidget.onPressed != null && !_enabled) {
      _held = false;
      _controller.update(WidgetState.pressed, false);
    }
  }

  @override
  void dispose() {
    FluentInputModality.keyboard.removeListener(_syncFocusVisible);
    _controller
      ..removeListener(_onStatesChanged)
      ..dispose();
    _internalNode?.dispose();
    super.dispose();
  }

  void _onStatesChanged() => setState(() {});

  /// States are tracked while disabled too and filtered in [build], because
  /// Chrome keeps a disabled element's `:hover`: re-enabled under a resting
  /// mouse, the control hovers at once. A press released after `dispose` still
  /// reaches the detached `Listener`.
  void _set(WidgetState state, {required bool value}) {
    if (mounted) _controller.update(state, value);
  }

  /// Pressed is the held press, except that a mouse dragged off a
  /// [FluentInteractive.pressedRequiresHover] surface is not `:hover:active`.
  void _syncPressed() => _set(
    WidgetState.pressed,
    value:
        _held &&
        (!widget.pressedRequiresHover ||
            !_heldByMouse ||
            _controller.value.contains(WidgetState.hovered)),
  );

  /// `focused` is the AND of "the framework wants a highlight" and "the last
  /// input was a key". Re-run on either changing: the modality can flip while
  /// focus stands still, and upstream repaints when it does.
  void _syncFocusVisible() => _set(
    WidgetState.focused,
    value: _highlight && FluentInputModality.keyboard.value,
  );

  void _release() {
    _held = false;
    _syncPressed();
  }

  void _handleTap() {
    if (!_enabled) return;
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: _enabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      mouseCursor: _enabled ? widget.mouseCursor : widget.disabledMouseCursor,
      // Deliberately wired from onShowFocusHighlight, not onFocusChange — but
      // that alone is NOT enough. Flutter's highlight mode only distinguishes
      // touch from not-touch, so on desktop and web it reads `traditional`
      // whether focus arrived by mouse or by key, and this fires for pointer
      // focus. FluentInputModality supplies the missing half, matching
      // upstream's keyborg-driven data-fui-focus-visible.
      //
      // WidgetState.selected is deliberately left untouched — Fluent has real
      // *Selected tokens (tabs, menu items, toggle buttons) and borrowing it
      // for focus would paint rings on selected items.
      onShowFocusHighlight: (value) {
        _highlight = value;
        _syncFocusVisible();
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleTap();
            return null;
          },
        ),
      },
      // Hover comes off MouseRegion rather than FocusableActionDetector's
      // onShowHoverHighlight, which is gated on the focus HIGHLIGHT MODE and so
      // reports nothing until the mode flips to `traditional`. Hover is a
      // pointer affordance: if a mouse is over the control, Fluent shows the
      // hover token regardless of how focus is being visualised.
      child: MouseRegion(
        onEnter: (_) {
          _set(WidgetState.hovered, value: true);
          _syncPressed();
        },
        onExit: (_) {
          _set(WidgetState.hovered, value: false);
          _syncPressed();
        },
        child: Listener(
          // Any button, as Chrome's `:active`; only the tap below is
          // primary-only, so a middle or right click never activates. The
          // release comes through here whatever the gesture arena decides.
          onPointerDown: (event) {
            _held =
                widget.pressedOnSecondary ||
                event.buttons != kSecondaryMouseButton;
            _heldByMouse = event.kind == PointerDeviceKind.mouse;
            _syncPressed();
          },
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Null, not a no-op handler, when disabled: an attached onTap puts a
            // tap ACTION in the semantics tree, so a screen reader announces a
            // disabled control as activatable.
            onTap: _enabled ? _handleTap : null,
            child: widget.builder(
              context,
              _enabled
                  ? _controller.value
                  : const <WidgetState>{WidgetState.disabled},
              widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
