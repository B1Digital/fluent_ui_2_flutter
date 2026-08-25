import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Whether the user is currently navigating with the keyboard.
///
/// The Dart counterpart of [keyborg][], which `react-tabster` uses to implement
/// focus-visible: one flag per app, set true by a key and false by a pointer,
/// and ANDed with "has focus" to decide whether a focus ring is drawn.
///
/// Flutter's own `FocusHighlightMode` cannot serve. `_HighlightModeManager`
/// distinguishes *touch* from *not-touch*, so a mouse click resolves to
/// `FocusHighlightMode.traditional` — the identical value a key press produces
/// — and `FocusableActionDetector.onShowFocusHighlight` fires for pointer
/// focus on web and desktop. That is the whole defect this exists to fix.
///
/// The flag is global rather than per-widget because upstream's is: keyboard-
/// open a menu, arrow onto a row, then move the mouse over a different row and
/// React still draws the ring, because *hover* does not clear the flag — only
/// a pointer *down* does. A per-widget "suppress while the pointer is here"
/// scheme cannot reproduce that.
///
/// [keyborg]: https://github.com/microsoft/keyborg
abstract final class FluentInputModality {
  static final _ModalityNotifier _keyboard = _ModalityNotifier();

  /// True while the last input was a key rather than a pointer.
  ///
  /// Listen to it: a widget that already holds focus must repaint when the
  /// modality flips even though focus has not moved.
  static ValueListenable<bool> get keyboard => _keyboard;

  /// Drops the global listeners and returns to the pointer-first default.
  ///
  /// Tests only — the flag is process-wide, so one test's key press would
  /// otherwise leak into the next.
  @visibleForTesting
  static void debugReset() {
    _keyboard.debugDropSubscribers();
    _keyboard.value = false;
  }

  static void _install() {
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointer);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  static void _uninstall() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointer);
    HardwareKeyboard.instance.removeHandler(_handleKey);
  }

  static void _handlePointer(PointerEvent event) {
    // Down, not hover: keyborg listens for `mousedown`/`touchstart` and
    // deliberately ignores movement, which is what lets a keyboard-navigated
    // ring survive the mouse passing over the control.
    if (event is PointerDownEvent) _keyboard.value = false;
  }

  static bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent && _isNavigationKey(event.logicalKey)) {
      _keyboard.value = true;
    }
    // Never consume: this observes, it does not handle.
    return false;
  }

  // ponytail: keyborg flips on ANY key whose target is not a text field, which
  // in Flutter would mean walking the focus tree for an EditableText on every
  // keystroke. This lists the keys that actually move or activate focus
  // instead — the observable difference is nil for ring behaviour, and typing
  // into a field still cannot raise a ring elsewhere, which is the property
  // keyborg's text-field exemption exists to protect.
  // Not `const`: LogicalKeyboardKey overrides `==`, so it has no primitive
  // equality and cannot be a constant set element.
  static final Set<LogicalKeyboardKey> _navigationKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.tab,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
    LogicalKeyboardKey.pageUp,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.space,
  };

  static bool _isNavigationKey(LogicalKeyboardKey key) =>
      _navigationKeys.contains(key);
}

/// Registers [FluentInputModality]'s global hooks for exactly as long as
/// something is listening.
///
/// Installation cannot be latched behind a bool. `PointerRouter.addGlobalRoute`
/// asserts the route is absent and `removeGlobalRoute` asserts it is present,
/// while `TestWidgetsFlutterBinding` clears both the router's global routes and
/// `HardwareKeyboard`'s handlers between tests — so a latch goes stale and the
/// hooks are silently gone for every test after the first. Counting
/// subscribers instead ties the registration to widget lifetime, which the
/// binding resets in step with.
final class _ModalityNotifier extends ValueNotifier<bool> {
  _ModalityNotifier() : super(false);

  int _subscribers = 0;

  @override
  void addListener(VoidCallback listener) {
    if (_subscribers == 0) FluentInputModality._install();
    _subscribers++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_subscribers == 0) return;
    _subscribers--;
    if (_subscribers == 0) FluentInputModality._uninstall();
  }

  /// Forgets every subscriber and uninstalls, without touching their callbacks.
  ///
  /// A test that tears down mid-flight can leave the count above zero; this is
  /// how `debugReset` gets back to a clean slate.
  void debugDropSubscribers() {
    if (_subscribers == 0) return;
    _subscribers = 0;
    FluentInputModality._uninstall();
  }
}
