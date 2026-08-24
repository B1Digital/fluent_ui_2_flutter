import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Toast docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream reaches a toaster through an ambient bus keyed by `toasterId` and a
/// `useToastController` hook. `fluent_2_web` hands you the queue itself: a
/// `FluentToastController` the demo owns, and a `FluentToaster` that renders it
/// into the nearest `Overlay`. Every demo below therefore holds its own
/// controller instead of looking one up by id.
const DocsPage toastPage = DocsPage(
  id: 'components-toast',
  title: 'Toast',
  description:
      'A Toasts displays temporary content to the user. Toasts are rendered as '
      'a separate surface that can be dismissed by user action or a '
      'application timeout. Toasts are typically used in the following '
      'situations: Update the user on the status of a task, Display the '
      'progress of a task, Notify the user to take an action, Notify the user '
      'of an application update, Warn the user of an error. The Fluent UI '
      'Toast component uses an imperative API. Once a Toaster has been '
      'rendered, you can use the useToastController hook to get access to '
      'imperative methods to dispatch a Toast. The Toast component itself is '
      'simply a layout component. In order for notifications that use toast to '
      'be fully accessible, developers should make the notifications available '
      'on a permanent surface too. One of the ways to do this in an '
      'application is to implement a notification centre. For live region '
      'debugging help, check our Debugging Notifications docs page.',
  source: 'lib/pages/components_toast.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-toast--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-toast--intent',
      title: 'Intent',
      description:
          'The toast comes by default with 4 different intents: success, info, '
          'warning, error. Each intent affects the default icon in the title '
          'and its colour. These icon slots can be overriden to render other '
          'content such as progress spinners or avatars. intent determines the '
          'urgency of the screen reader aria-live narration. To retain default '
          'intent styles, use the politeness option to override the urgency or '
          'aria-live narration.',
      builder: _intent,
    ),
    DocsSection(
      id: 'components-toast--inverted-appearance',
      title: 'Inverted Appearance',
      builder: _invertedAppearance,
    ),
    DocsSection(
      id: 'components-toast--default-toast-options',
      title: 'Default Toast Options',
      description:
          'Default options for all toasts can be configured on the Toaster. '
          'These options are only defaults and can be overriden using '
          'dispatchToast',
      builder: _defaultToastOptions,
    ),
    DocsSection(
      id: 'components-toast--custom-timeout',
      title: 'Custom Timeout',
      description:
          'The timeout of toasts can be customized in milliseconds. Using a '
          'negative timeout value results in the toast never being '
          'auto-dismissed.',
      builder: _customTimeout,
    ),
    DocsSection(
      id: 'components-toast--dismiss-toast-with-action',
      title: 'Dismiss Toast With Action',
      description:
          'By wrapping a button or link with a ToastTrigger, it\'s possible to '
          'make that actionable element dismiss the toast with a click.',
      builder: _dismissToastWithAction,
    ),
    DocsSection(
      id: 'components-toast--toast-positions',
      title: 'Toast Positions',
      description:
          'Toasts can be dispatched to all four corners of a page. We do not '
          'recommend to use more than one position for toasts in an '
          'application because that could be disorienting for users. Pick one '
          'desired position and configure it in the Toaster.',
      builder: _toastPositions,
    ),
    DocsSection(
      id: 'components-toast--offset',
      title: 'Offset',
      description:
          'You can declare a static offset for toasts relative to the '
          'viewport. This offset can only be set on the Toaster component, '
          'because it wouldn\'t make sense to have separate toast offsets for '
          'a toasts in a single position.',
      builder: _offset,
    ),
    DocsSection(
      id: 'components-toast--dismiss-toast',
      title: 'Dismiss Toast',
      description:
          'Toasts can be dismissed imperatively using the dismissToast API. In '
          'order to imperatively dismiss a Toast, it\'s necessary to dispatch '
          'it with a user provided id. You can use the id to dismiss the '
          'toast. Don\'t use this API to dismiss toats when clicking on an '
          'action inside the toast, use the ToastTrigger instead.',
      builder: _dismissToast,
    ),
    DocsSection(
      id: 'components-toast--update-toast',
      title: 'Update Toast',
      description:
          'Use the updateToast imperative API to make changes to a Toast that '
          'is already visible. To do this you must provide an id when '
          'dispatching the toast. Almost all options of a Toast can be '
          'updated.',
      builder: _updateToast,
    ),
    DocsSection(
      id: 'components-toast--progress-toast',
      title: 'Progress Toast',
      description:
          'In order to avoid excessive toast updates and optimize performance, '
          'we recommend encapsulating progress bars with any state or remove '
          'data sources. That way the progress bar can tick independently and '
          'trigger the toast dismiss when it finishes. You can pass a callback '
          'to your toast content to dismiss to the toast based on any side '
          'effects.',
      builder: _progressToast,
    ),
    DocsSection(
      id: 'components-toast--dismiss-all',
      title: 'Dismiss All',
      description:
          'The dismissAllToasts imperative API will dismiss all rendered '
          'Toasts.',
      builder: _dismissAll,
    ),
    DocsSection(
      id: 'components-toast--pause-and-play',
      title: 'Pause And Play',
      description:
          'Toasts can be paused and played imperatively based on the user '
          'provided id. Toasts paused this way can only be dismissed once the '
          'app plays it again. Make sure that your app will will play a toast '
          'after it has been paused.',
      builder: _pauseAndPlay,
    ),
    DocsSection(
      id: 'components-toast--pause-on-window-blur',
      title: 'Pause On Window Blur',
      description:
          'Use pauseOnWindowBlur option to pause the dismiss timeout of a Toast '
          'when the user moves focus to another window. This option can also '
          'be set on the Toaster as a default.',
      builder: _pauseOnWindowBlur,
    ),
    DocsSection(
      id: 'components-toast--pause-on-hover',
      title: 'Pause On Hover',
      description:
          'The pauseOnHover option will enable users to pause the timeout of a '
          'toast while the mouse cursor is inside the toast. This option can '
          'also be set on the Toaster as a default.',
      builder: _pauseOnHover,
    ),
    DocsSection(
      id: 'components-toast--toast-lifecycle',
      title: 'Toast Lifecycle',
      description:
          'Since toasts are imperative, the way they are mapped to React is '
          'internal, and not reflective of its usage. The Toast API exposes '
          'its own lifecycle that users can hook into, and is already used in '
          'other documentation examples. The lifecycle stages are: queued - '
          'The toast is queued until it can be made visible, visible - The '
          'toast is mounted and rendered, this is instance if the toast limit '
          'is not reached, dismissed - The toast is visually invisible but '
          'still mounted, unounted - The toast has been completely unmounted '
          'and no longer exists. Use the onStatusChange option when '
          'dispatching a toast to listen to lifecycle changes.',
      builder: _toastLifecycle,
    ),
    DocsSection(
      id: 'components-toast--multiple-toasters',
      title: 'Multiple Toasters',
      description:
          'This use case is not recommended. Toasters support a toasterId prop '
          'to support multiple Toasters in an app.',
      builder: _multipleToasters,
    ),
    DocsSection(
      id: 'components-toast--toaster-limit',
      title: 'Toaster Limit',
      description:
          'Use the limit prop on the Toaster to define the maximum number of '
          'toasts that can be rendered at any one time. Any extra toasts will '
          'be queued and rendered when a toast has been dismissed.',
      builder: _toasterLimit,
    ),
    DocsSection(
      id: 'components-toast--focus-keyboard-shortcut',
      title: 'Focus Keyboard Shortcut',
      description:
          'Developers can be define a shortcut to focus on the most recent '
          'visible toast . This example configures the shortcut to be CTRL+M. '
          'Once a toast is focused, all toasts belonging to that toaster are '
          'paused and will not timeout.',
      builder: _focusKeyboardShortcut,
    ),
    DocsSection(
      id: 'components-toast--inline',
      title: 'Inline',
      description:
          'Setting the inline prop on a toaster will render toasts in DOM '
          'order, positioned relative to the closest positioned ancestor. The '
          'simplest way to achieve this is to render the toaster inside an '
          'element with position: relative.',
      builder: _inline,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'title',
      type: 'Widget',
      description: 'The primary line, in body1Strong.',
    ),
    PropRow(
      name: 'intent',
      type: 'FluentToastIntent',
      defaultValue: 'FluentToastIntent.info',
      description:
          'What the toast is about. Moves the glyph, and nothing else.',
    ),
    PropRow(
      name: 'type',
      type: 'FluentToastType',
      defaultValue: 'FluentToastType.dismiss',
      description: 'What sits in the end slot.',
    ),
    PropRow(
      name: 'body',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The secondary line, in body1.',
    ),
    PropRow(
      name: 'subtitle',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The tertiary line, in caption1 and a ramp step quieter.',
    ),
    PropRow(
      name: 'footer',
      type: 'List<Widget>',
      defaultValue: '[]',
      description: 'Action affordances on their own row under the body.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'Overrides the glyph intent would otherwise select. Required for '
          'FluentToastIntent.custom, which has none of its own.',
    ),
    PropRow(
      name: 'showIcon',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether a glyph is drawn at all. False removes it, its gap and the '
          "body's indent.",
    ),
    PropRow(
      name: 'onDismiss',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked by the dismiss button. Null renders no dismiss button, even '
          'when type is FluentToastType.dismiss.',
    ),
    PropRow(
      name: 'timestamp',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          "The end slot's label when type is FluentToastType.timestamp.",
    ),
    PropRow(
      name: 'action',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          "The end slot's affordance when type is FluentToastType.action. "
          'Usually a FluentLink.',
    ),
  ],
);

// #docregion components-toast--default
// Upstream's `useToastController(toasterId)` reaches an ambient bus. Ours is a
// plain ChangeNotifier the demo owns and hands to its own `FluentToaster`.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  final FluentToastController _toaster = FluentToastController();

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => FluentToast(
      intent: FluentToastIntent.success,
      // Upstream puts `action` on ToastTitle; ours is the toast's end slot.
      type: FluentToastType.action,
      action: FluentLink(onPressed: () {}, child: const Text('Undo')),
      title: const Text('Email sent'),
      body: const Text('This is a toast body'),
      subtitle: const Text('Subtitle'),
      footer: <Widget>[
        FluentLink(onPressed: () {}, child: const Text('Action')),
        FluentLink(onPressed: () {}, child: const Text('Action')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(onPressed: _notify, child: const Text('Make toast')),
  );
}
// #enddocregion components-toast--default

// #docregion components-toast--intent
Widget _intent(BuildContext context) => const _Intent();

class _Intent extends StatefulWidget {
  const _Intent();

  @override
  State<_Intent> createState() => _IntentState();
}

class _IntentState extends State<_Intent> {
  final FluentToastController _toaster = FluentToastController();
  String _intentValue = 'success';

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() {
    switch (_intentValue) {
      case 'progress':
        // The media slot is `icon`, and `FluentToastIntent.custom` is the
        // intent that ships no glyph of its own for it to replace.
        _toaster.show(
          (BuildContext context, Object id) => const FluentToast(
            intent: FluentToastIntent.custom,
            icon: FluentSpinner(size: FluentSpinnerSize.tiny),
            title: Text('Progress toast'),
          ),
        );
      case 'avatar':
        _toaster.show(
          (BuildContext context, Object id) => const FluentToast(
            intent: FluentToastIntent.custom,
            icon: Center(
              child: FluentAvatar(
                name: 'Erika Mustermann',
                size: FluentAvatarSize.size16,
              ),
            ),
            title: Text('Avatar toast'),
          ),
        );
      default:
        _toaster.show(
          (BuildContext context, Object id) => FluentToast(
            intent: switch (_intentValue) {
              'info' => FluentToastIntent.info,
              'warning' => FluentToastIntent.warning,
              'error' => FluentToastIntent.error,
              _ => FluentToastIntent.success,
            },
            title: Text('Toast intent: $_intentValue'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: <Widget>[
        FluentField(
          label: const Text('Select a intent'),
          child: FluentRadioGroup<String>(
            value: _intentValue,
            onChanged: (String value) => setState(() => _intentValue = value),
            children: const <Widget>[
              FluentRadio<String>(value: 'success', label: Text('success')),
              FluentRadio<String>(value: 'info', label: Text('info')),
              FluentRadio<String>(value: 'warning', label: Text('warning')),
              FluentRadio<String>(value: 'error', label: Text('error')),
              FluentRadio<String>(
                value: 'progress',
                label: Text('progress (custom media slot)'),
              ),
              FluentRadio<String>(
                value: 'avatar',
                label: Text('avatar (custom media slot)'),
              ),
            ],
          ),
        ),
        FluentButton(onPressed: _notify, child: const Text('Make toast')),
      ],
    ),
  );
}
// #enddocregion components-toast--intent

// #docregion components-toast--inverted-appearance
// `FluentToast` has no `appearance` axis. The inverted look is the same surface
// wearing the two tokens upstream's inverted rule names — `neutralBackground
// Static` and `neutralForegroundStaticInverted` — passed through `style`.
Widget _invertedAppearance(BuildContext context) => const _InvertedAppearance();

class _InvertedAppearance extends StatefulWidget {
  const _InvertedAppearance();

  @override
  State<_InvertedAppearance> createState() => _InvertedAppearanceState();
}

class _InvertedAppearanceState extends State<_InvertedAppearance> {
  final FluentToastController _toaster = FluentToastController();

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show((BuildContext context, Object id) {
    final FluentColors colors = FluentTheme.of(context).colors;
    return FluentToast(
      intent: FluentToastIntent.success,
      type: FluentToastType.action,
      style: FluentToastStyle(
        backgroundColor: WidgetStatePropertyAll<Color?>(
          colors.neutralBackgroundStatic,
        ),
        foregroundColor: WidgetStatePropertyAll<Color?>(
          colors.neutralForegroundStaticInverted,
        ),
        subtitleColor: WidgetStatePropertyAll<Color?>(
          colors.neutralForegroundStaticInverted,
        ),
        iconColor: WidgetStatePropertyAll<Color?>(
          colors.neutralForegroundStaticInverted,
        ),
      ),
      action: FluentLink(
        appearance: FluentLinkAppearance.overBrand,
        onPressed: () {},
        child: const Text('Undo'),
      ),
      title: const Text('Email sent'),
      body: const Text('This is a toast body'),
      subtitle: const Text('Subtitle'),
      footer: <Widget>[
        FluentLink(
          appearance: FluentLinkAppearance.overBrand,
          onPressed: () {},
          child: const Text('Action'),
        ),
        FluentLink(
          appearance: FluentLinkAppearance.overBrand,
          onPressed: () {},
          child: const Text('Action'),
        ),
      ],
    );
  });

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(onPressed: _notify, child: const Text('Make toast')),
  );
}
// #enddocregion components-toast--inverted-appearance

// #docregion components-toast--default-toast-options
// Position, timeout and pauseOnHover are arguments to `show` rather than props
// on the toaster, so "defaults configured on the Toaster" become these three
// constants. `pauseOnWindowBlur` has no equivalent — the countdown keeps
// running when the window loses focus.
const FluentToastPosition _defaultOptionsPosition = FluentToastPosition.topEnd;
const Duration _defaultOptionsTimeout = Duration(milliseconds: 1000);
const bool _defaultOptionsPauseOnHover = true;

Widget _defaultToastOptions(BuildContext context) =>
    const _DefaultToastOptions();

class _DefaultToastOptions extends StatefulWidget {
  const _DefaultToastOptions();

  @override
  State<_DefaultToastOptions> createState() => _DefaultToastOptionsState();
}

class _DefaultToastOptionsState extends State<_DefaultToastOptions> {
  final FluentToastController _toaster = FluentToastController();

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) =>
        const FluentToast(title: Text('Options configured in Toaster')),
    position: _defaultOptionsPosition,
    timeout: _defaultOptionsTimeout,
    pauseOnHover: _defaultOptionsPauseOnHover,
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(onPressed: _notify, child: const Text('Make toast')),
  );
}
// #enddocregion components-toast--default-toast-options

// #docregion components-toast--custom-timeout
Widget _customTimeout(BuildContext context) => const _CustomTimeout();

class _CustomTimeout extends StatefulWidget {
  const _CustomTimeout();

  @override
  State<_CustomTimeout> createState() => _CustomTimeoutState();
}

class _CustomTimeoutState extends State<_CustomTimeout> {
  final FluentToastController _toaster = FluentToastController();
  double? _timeout = 1000;

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() {
    final int timeout = (_timeout ?? 0).round();
    _toaster.show(
      (BuildContext context, Object id) => FluentToast(
        type: FluentToastType.action,
        action: FluentLink(
          onPressed: () => _toaster.dismiss(id),
          child: const Text('Dismiss'),
        ),
        title: Text(
          timeout >= 0 ? 'Custom timeout ${timeout}ms' : 'Dismiss manually',
        ),
      ),
      // Upstream's negative timeout is our Duration.zero: never auto-dismiss.
      timeout: timeout >= 0 ? Duration(milliseconds: timeout) : Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: <Widget>[
        SizedBox(
          width: 300,
          child: FluentField(
            label: const Text('Timeout'),
            hint: const Text('Timeout is in milliseconds'),
            child: FluentSpinButton(
              value: _timeout,
              step: 500,
              semanticLabel: 'Timeout',
              onChanged: (double? value) => setState(() => _timeout = value),
            ),
          ),
        ),
        FluentButton(onPressed: _notify, child: const Text('Make toast')),
      ],
    ),
  );
}
// #enddocregion components-toast--custom-timeout

// #docregion components-toast--dismiss-toast-with-action
// Upstream wraps the link in a `ToastTrigger`, which dismisses on click. Our
// builder is handed the toast's own id, so the link dismisses it directly.
Widget _dismissToastWithAction(BuildContext context) =>
    const _DismissToastWithAction();

class _DismissToastWithAction extends StatefulWidget {
  const _DismissToastWithAction();

  @override
  State<_DismissToastWithAction> createState() =>
      _DismissToastWithActionState();
}

class _DismissToastWithActionState extends State<_DismissToastWithAction> {
  final FluentToastController _toaster = FluentToastController();

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => FluentToast(
      intent: FluentToastIntent.success,
      type: FluentToastType.action,
      action: FluentLink(
        onPressed: () => _toaster.dismiss(id),
        child: const Text('Dismiss'),
      ),
      title: const Text('Dismiss me'),
    ),
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(onPressed: _notify, child: const Text('Make toast')),
  );
}
// #enddocregion components-toast--dismiss-toast-with-action

// #docregion components-toast--toast-positions
const Map<String, FluentToastPosition> _toastPositionsByName =
    <String, FluentToastPosition>{
      'bottom': FluentToastPosition.bottom,
      'bottom-start': FluentToastPosition.bottomStart,
      'bottom-end': FluentToastPosition.bottomEnd,
      'top': FluentToastPosition.top,
      'top-start': FluentToastPosition.topStart,
      'top-end': FluentToastPosition.topEnd,
    };

Widget _toastPositions(BuildContext context) => const _ToastPositions();

class _ToastPositions extends StatefulWidget {
  const _ToastPositions();

  @override
  State<_ToastPositions> createState() => _ToastPositionsState();
}

class _ToastPositionsState extends State<_ToastPositions> {
  final FluentToastController _toaster = FluentToastController();
  String _position = 'top';

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => FluentToast(
      intent: FluentToastIntent.success,
      title: Text('This toast is $_position'),
    ),
    position: _toastPositionsByName[_position]!,
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: <Widget>[
        FluentField(
          label: const Text('Select a position'),
          child: FluentRadioGroup<String>(
            value: _position,
            onChanged: (String value) => setState(() => _position = value),
            children: <Widget>[
              for (final String name in _toastPositionsByName.keys)
                FluentRadio<String>(value: name, label: Text(name)),
            ],
          ),
        ),
        FluentButton(onPressed: _notify, child: const Text('Make toast')),
      ],
    ),
  );
}
// #enddocregion components-toast--toast-positions

// #docregion components-toast--offset
const Map<String, FluentToastPosition> _offsetPositionsByName =
    <String, FluentToastPosition>{
      'bottom': FluentToastPosition.bottom,
      'bottom-start': FluentToastPosition.bottomStart,
      'bottom-end': FluentToastPosition.bottomEnd,
      'top': FluentToastPosition.top,
      'top-start': FluentToastPosition.topStart,
      'top-end': FluentToastPosition.topEnd,
    };

Widget _offset(BuildContext context) => const _Offset();

class _Offset extends StatefulWidget {
  const _Offset();

  @override
  State<_Offset> createState() => _OffsetState();
}

class _OffsetState extends State<_Offset> {
  final FluentToastController _toaster = FluentToastController();
  double? _horizontal = 20;
  double? _vertical = 16;
  String _position = 'bottom-end';

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => FluentToast(
      title: Text(
        'Offset: ${(_horizontal ?? 0).round()}, ${(_vertical ?? 0).round()}',
      ),
    ),
    position: _offsetPositionsByName[_position]!,
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    // Upstream's `offset={{ horizontal, vertical }}`. Ours is an EdgeInsets,
    // and like upstream the horizontal half is ignored by the two centred
    // positions.
    offset: EdgeInsets.symmetric(
      horizontal: _horizontal ?? 0,
      vertical: _vertical ?? 0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: <Widget>[
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: <Widget>[
                  FluentField(
                    label: const Text('Horizontal offset'),
                    child: FluentSpinButton(
                      value: _horizontal,
                      semanticLabel: 'Horizontal offset',
                      onChanged: (double? value) =>
                          setState(() => _horizontal = value),
                    ),
                  ),
                  FluentField(
                    label: const Text('Vertical offset'),
                    child: FluentSpinButton(
                      value: _vertical,
                      semanticLabel: 'Vertical offset',
                      onChanged: (double? value) =>
                          setState(() => _vertical = value),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 300,
              child: FluentField(
                label: const Text('Toast position'),
                child: FluentRadioGroup<String>(
                  value: _position,
                  onChanged: (String value) =>
                      setState(() => _position = value),
                  children: <Widget>[
                    for (final String name in _offsetPositionsByName.keys)
                      FluentRadio<String>(value: name, label: Text(name)),
                  ],
                ),
              ),
            ),
          ],
        ),
        FluentButton(onPressed: _notify, child: const Text('Make toast')),
      ],
    ),
  );
}
// #enddocregion components-toast--offset

// #docregion components-toast--dismiss-toast
Widget _dismissToast(BuildContext context) => const _DismissToast();

class _DismissToast extends StatefulWidget {
  const _DismissToast();

  @override
  State<_DismissToast> createState() => _DismissToastState();
}

class _DismissToastState extends State<_DismissToast> {
  static const String _toastId = 'components-toast--dismiss-toast';

  final FluentToastController _toaster = FluentToastController();
  bool _unmounted = true;

  @override
  void initState() {
    super.initState();
    // Upstream reads the lifecycle off `onStatusChange`. Ours is a
    // ChangeNotifier, so the same fact is read off the queue itself.
    _toaster.addListener(_handleQueueChanged);
  }

  @override
  void dispose() {
    _toaster
      ..removeListener(_handleQueueChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueueChanged() {
    final bool unmounted = !_toaster.entries.any(
      (FluentToastEntry entry) => entry.id == _toastId,
    );
    if (unmounted != _unmounted) {
      setState(() => _unmounted = unmounted);
    }
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => const FluentToast(
      intent: FluentToastIntent.success,
      title: Text('This is a toast'),
    ),
    id: _toastId,
  );

  void _dismiss() => _toaster.dismiss(_toastId);

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(
      onPressed: _unmounted ? _notify : _dismiss,
      child: Text('${_unmounted ? 'Make' : 'Dismiss'} toast'),
    ),
  );
}
// #enddocregion components-toast--dismiss-toast

// #docregion components-toast--update-toast
// `show` with an id that is already queued replaces that toast in place,
// keeping its slot in the stack — which is upstream's `updateToast`.
Widget _updateToast(BuildContext context) => const _UpdateToast();

class _UpdateToast extends StatefulWidget {
  const _UpdateToast();

  @override
  State<_UpdateToast> createState() => _UpdateToastState();
}

class _UpdateToastState extends State<_UpdateToast> {
  static const String _toastId = 'components-toast--update-toast';

  final FluentToastController _toaster = FluentToastController();
  bool _unmounted = true;

  @override
  void initState() {
    super.initState();
    _toaster.addListener(_handleQueueChanged);
  }

  @override
  void dispose() {
    _toaster
      ..removeListener(_handleQueueChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueueChanged() {
    final bool unmounted = !_toaster.entries.any(
      (FluentToastEntry entry) => entry.id == _toastId,
    );
    if (unmounted != _unmounted) {
      setState(() => _unmounted = unmounted);
    }
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => const FluentToast(
      intent: FluentToastIntent.warning,
      title: Text('This toast never closes'),
    ),
    id: _toastId,
    timeout: Duration.zero,
  );

  void _update() => _toaster.show(
    (BuildContext context, Object id) => const FluentToast(
      intent: FluentToastIntent.success,
      title: Text('This toast will close soon'),
    ),
    id: _toastId,
    timeout: const Duration(milliseconds: 2000),
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(
      onPressed: _unmounted ? _notify : _update,
      child: Text(_unmounted ? 'Make toast' : 'Update toast'),
    ),
  );
}
// #enddocregion components-toast--update-toast

// #docregion components-toast--progress-toast
const int _progressIntervalDelay = 100;
const int _progressIntervalIncrement = 5;

/// Ticks 100 down to 0 on its own and reports when it lands, so the toast is
/// updated by the bar rather than by the page that dispatched it.
class _DownloadProgressBar extends StatelessWidget {
  const _DownloadProgressBar({required this.onDownloadEnd});

  final VoidCallback onDownloadEnd;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 100, end: 0),
    // Upstream steps by `intervalIncrement` every `intervalDelay`; a single
    // linear tween covers the same wall-clock run without a timer.
    duration: const Duration(
      milliseconds:
          _progressIntervalDelay * (100 ~/ _progressIntervalIncrement),
    ),
    onEnd: onDownloadEnd,
    builder: (BuildContext context, double value, Widget? child) =>
        FluentProgressBar(
          value: value / 100,
          semanticLabel: 'Downloading file',
        ),
  );
}

Widget _progressToast(BuildContext context) => const _ProgressToast();

class _ProgressToast extends StatefulWidget {
  const _ProgressToast();

  @override
  State<_ProgressToast> createState() => _ProgressToastState();
}

class _ProgressToastState extends State<_ProgressToast> {
  static const String _toastId = 'components-toast--progress-toast';

  final FluentToastController _toaster = FluentToastController();
  bool _unmounted = true;

  @override
  void initState() {
    super.initState();
    _toaster.addListener(_handleQueueChanged);
  }

  @override
  void dispose() {
    _toaster
      ..removeListener(_handleQueueChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueueChanged() {
    final bool unmounted = !_toaster.entries.any(
      (FluentToastEntry entry) => entry.id == _toastId,
    );
    if (unmounted != _unmounted) {
      setState(() => _unmounted = unmounted);
    }
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => FluentToast(
      intent: FluentToastIntent.success,
      type: FluentToastType.action,
      action: FluentLink(
        onPressed: () => _toaster.dismiss(id),
        child: const Text('Dismiss'),
      ),
      title: const Text('Downloading file'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xs,
        children: <Widget>[
          const Text('This may take a while'),
          _DownloadProgressBar(onDownloadEnd: () => _toaster.dismiss(id)),
        ],
      ),
      footer: <Widget>[
        FluentLink(onPressed: () {}, child: const Text('Action')),
        FluentLink(onPressed: () {}, child: const Text('Action')),
      ],
    ),
    id: _toastId,
    timeout: Duration.zero,
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(
      onPressed: _unmounted ? _notify : null,
      child: const Text('Make toast'),
    ),
  );
}
// #enddocregion components-toast--progress-toast

// #docregion components-toast--dismiss-all
Widget _dismissAll(BuildContext context) => const _DismissAll();

class _DismissAll extends StatefulWidget {
  const _DismissAll();

  @override
  State<_DismissAll> createState() => _DismissAllState();
}

class _DismissAllState extends State<_DismissAll> {
  final FluentToastController _toaster = FluentToastController();

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) =>
        const FluentToast(title: Text('This is a toast')),
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.s,
      children: <Widget>[
        FluentButton(onPressed: _notify, child: const Text('Make toast')),
        FluentButton(
          onPressed: _toaster.dismissAll,
          child: const Text('Dismiss all toasts'),
        ),
      ],
    ),
  );
}
// #enddocregion components-toast--dismiss-all

// #docregion components-toast--pause-and-play
// There is no `pauseToast` / `playToast` pair. There does not need to be: a
// toast re-shown under its own id keeps its slot AND its part-run countdown, so
// re-showing it with `Duration.zero` pauses the clock and re-showing it with
// the original timeout resumes from where it stopped.
const Duration _pauseAndPlayTimeout = Duration(milliseconds: 3000);

Widget _pauseAndPlay(BuildContext context) => const _PauseAndPlay();

class _PauseAndPlay extends StatefulWidget {
  const _PauseAndPlay();

  @override
  State<_PauseAndPlay> createState() => _PauseAndPlayState();
}

class _PauseAndPlayState extends State<_PauseAndPlay> {
  static const String _toastId = 'components-toast--pause-and-play';

  final FluentToastController _toaster = FluentToastController();
  bool _unmounted = true;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _toaster.addListener(_handleQueueChanged);
  }

  @override
  void dispose() {
    _toaster
      ..removeListener(_handleQueueChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueueChanged() {
    final bool unmounted = !_toaster.entries.any(
      (FluentToastEntry entry) => entry.id == _toastId,
    );
    if (unmounted != _unmounted) {
      setState(() {
        _unmounted = unmounted;
        if (unmounted) _paused = false;
      });
    }
  }

  Widget _buildToast(BuildContext context, Object id) => const FluentToast(
    intent: FluentToastIntent.success,
    title: Text('This is a toast'),
  );

  void _notify() =>
      _toaster.show(_buildToast, id: _toastId, timeout: _pauseAndPlayTimeout);

  void _toggle() {
    setState(() => _paused = !_paused);
    _toaster.show(
      _buildToast,
      id: _toastId,
      timeout: _paused ? Duration.zero : _pauseAndPlayTimeout,
    );
  }

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.s,
      children: <Widget>[
        FluentButton(
          onPressed: _unmounted ? _notify : null,
          child: const Text('Make toast'),
        ),
        // fluent_2_web ships no toggle button, so the checked state is said
        // with the primary appearance.
        FluentButton(
          appearance: _paused
              ? FluentButtonAppearance.primary
              : FluentButtonAppearance.secondary,
          icon: Icon(
            _paused ? FluentIcons.play_20_filled : FluentIcons.pause_20_filled,
          ),
          onPressed: _unmounted ? null : _toggle,
          child: Text('${_paused ? 'Play' : 'Pause'} toast'),
        ),
      ],
    ),
  );
}
// #enddocregion components-toast--pause-and-play

// #docregion components-toast--pause-on-window-blur
// `FluentToastController.show` has no `pauseOnWindowBlur`: the countdown is a
// ticker on the scheduler's clock and keeps running while another window has
// focus. The toast is upstream's; the pause is not.
Widget _pauseOnWindowBlur(BuildContext context) => const _PauseOnWindowBlur();

class _PauseOnWindowBlur extends StatefulWidget {
  const _PauseOnWindowBlur();

  @override
  State<_PauseOnWindowBlur> createState() => _PauseOnWindowBlurState();
}

class _PauseOnWindowBlurState extends State<_PauseOnWindowBlur> {
  final FluentToastController _toaster = FluentToastController();

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) =>
        const FluentToast(title: Text('Click on another window!')),
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(onPressed: _notify, child: const Text('Make toast')),
  );
}
// #enddocregion components-toast--pause-on-window-blur

// #docregion components-toast--pause-on-hover
Widget _pauseOnHover(BuildContext context) => const _PauseOnHover();

class _PauseOnHover extends StatefulWidget {
  const _PauseOnHover();

  @override
  State<_PauseOnHover> createState() => _PauseOnHoverState();
}

class _PauseOnHoverState extends State<_PauseOnHover> {
  final FluentToastController _toaster = FluentToastController();

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  // Passed explicitly, though it is also our default: a notification that
  // expires under the pointer resting on it is unreadable.
  void _notify() => _toaster.show(
    (BuildContext context, Object id) =>
        const FluentToast(title: Text('Hover me!')),
    pauseOnHover: true,
  );

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: FluentButton(onPressed: _notify, child: const Text('Make toast')),
  );
}
// #enddocregion components-toast--pause-on-hover

// #docregion components-toast--toast-lifecycle
// There is no `onStatusChange`; the queue is a ChangeNotifier, so the status is
// derived from it. Three of upstream's four stages are observable this way —
// `queued` is not, because our controller renders every toast it is given
// rather than holding a limit and a queue behind it.
Widget _toastLifecycle(BuildContext context) => const _ToastLifecycle();

class _ToastLifecycle extends StatefulWidget {
  const _ToastLifecycle();

  @override
  State<_ToastLifecycle> createState() => _ToastLifecycleState();
}

class _ToastLifecycleState extends State<_ToastLifecycle> {
  static const String _toastId = 'components-toast--toast-lifecycle';

  final FluentToastController _toaster = FluentToastController();
  final List<String> _statusLog = <String>[];
  String _status = 'unmounted';
  bool _dismissed = true;

  @override
  void initState() {
    super.initState();
    _toaster.addListener(_handleQueueChanged);
  }

  @override
  void dispose() {
    _toaster
      ..removeListener(_handleQueueChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueueChanged() {
    final Iterable<FluentToastEntry> matches = _toaster.entries.where(
      (FluentToastEntry entry) => entry.id == _toastId,
    );
    final String status = matches.isEmpty
        ? 'unmounted'
        : matches.first.visible
        ? 'visible'
        : 'dismissed';
    if (status == _status) return;
    setState(() {
      _status = status;
      _dismissed = status == 'unmounted';
      _statusLog.insert(0, '${_now()} $status');
    });
  }

  static String _now() {
    final DateTime time = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => FluentToast(
      intent: FluentToastIntent.success,
      type: FluentToastType.action,
      action: FluentLink(onPressed: () {}, child: const Text('Undo')),
      title: const Text('Email sent'),
      body: const Text('This is a toast body'),
      subtitle: const Text('Subtitle'),
      footer: <Widget>[
        FluentLink(onPressed: () {}, child: const Text('Action')),
        FluentLink(onPressed: () {}, child: const Text('Action')),
      ],
    ),
    id: _toastId,
    timeout: const Duration(milliseconds: 1000),
  );

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    return FluentToaster(
      controller: _toaster,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 20,
        children: <Widget>[
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: FluentSpacing.xs,
              children: <Widget>[
                FluentButton(
                  onPressed: _dismissed ? _notify : null,
                  child: const Text('Make toast'),
                ),
                FluentButton(
                  onPressed: () => setState(_statusLog.clear),
                  child: const Text('Clear log'),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                color: theme.colors.brandBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                child: Text(
                  'Status log',
                  style: theme.typography.body1Strong.copyWith(
                    color: theme.colors.neutralForegroundOnBrand,
                  ),
                ),
              ),
              Container(
                width: 230,
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colors.brandBackground,
                    width: 2,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final String entry in _statusLog) Text(entry),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// #enddocregion components-toast--toast-lifecycle

// #docregion components-toast--multiple-toasters
// Upstream needs a `toasterId` because the DOM gives it no other handle on a
// particular toaster. A controller IS the handle, so two toasters are two
// controllers and two nested `FluentToaster`s.
Widget _multipleToasters(BuildContext context) => const _MultipleToasters();

class _MultipleToasters extends StatefulWidget {
  const _MultipleToasters();

  @override
  State<_MultipleToasters> createState() => _MultipleToastersState();
}

class _MultipleToastersState extends State<_MultipleToasters> {
  final FluentToastController _first = FluentToastController();
  final FluentToastController _second = FluentToastController();
  String _toasterName = 'First toaster';

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _notify() {
    if (_toasterName == 'First toaster') {
      _first.show(
        (BuildContext context, Object id) =>
            const FluentToast(title: Text('First toaster')),
        position: FluentToastPosition.bottomEnd,
      );
    } else {
      _second.show(
        (BuildContext context, Object id) =>
            const FluentToast(title: Text('Second toaster')),
        position: FluentToastPosition.topEnd,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _first,
    child: FluentToaster(
      controller: _second,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.l,
        children: <Widget>[
          FluentField(
            label: const Text('Choose toaster'),
            child: FluentRadioGroup<String>(
              value: _toasterName,
              onChanged: (String value) => setState(() => _toasterName = value),
              children: const <Widget>[
                FluentRadio<String>(
                  value: 'First toaster',
                  label: Text('First toaster'),
                ),
                FluentRadio<String>(
                  value: 'Second toaster',
                  label: Text('Second toaster'),
                ),
              ],
            ),
          ),
          FluentButton(onPressed: _notify, child: const Text('Make toast')),
        ],
      ),
    ),
  );
}
// #enddocregion components-toast--multiple-toasters

// #docregion components-toast--toaster-limit
// `FluentToaster` has no `limit`, and no queue behind one. The nearest
// behaviour the public API can express is to dismiss the oldest visible toast
// once the limit is exceeded — dropped rather than queued.
Widget _toasterLimit(BuildContext context) => const _ToasterLimit();

class _ToasterLimit extends StatefulWidget {
  const _ToasterLimit();

  @override
  State<_ToasterLimit> createState() => _ToasterLimitState();
}

class _ToasterLimitState extends State<_ToasterLimit> {
  final FluentToastController _toaster = FluentToastController();
  double? _limit = 3;

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() {
    _toaster.show(
      (BuildContext context, Object id) => const FluentToast(
        intent: FluentToastIntent.success,
        title: Text('Limited to 3 toasts'),
      ),
    );
    final int limit = (_limit ?? 0).round();
    final List<FluentToastEntry> visible = _toaster.entries
        .where((FluentToastEntry entry) => entry.visible)
        .toList();
    for (int i = 0; i < visible.length - limit; i += 1) {
      _toaster.dismiss(visible[i].id);
    }
  }

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: <Widget>[
        SizedBox(
          width: 300,
          child: FluentField(
            label: const Text('Toaster Limit'),
            child: FluentSpinButton(
              value: _limit,
              min: 1,
              semanticLabel: 'Toaster Limit',
              onChanged: (double? value) => setState(() => _limit = value),
            ),
          ),
        ),
        FluentButton(onPressed: _notify, child: const Text('Make toast')),
      ],
    ),
  );
}
// #enddocregion components-toast--toaster-limit

// #docregion components-toast--focus-keyboard-shortcut
// `FluentToaster` exposes no `shortcuts` slot, so the demo puts a focus node
// inside each toast it dispatches and moves focus to the most recent one
// itself. Upstream binds that move to CTRL+M; a key binding needs
// `LogicalKeyboardKey` from `package:flutter/services.dart`, which these
// examples do not import, so it is offered as a second button instead.
// Upstream also pauses every toast in the toaster once one is focused; ours
// pauses on hover only. Every toast is a real tab stop either way, and Escape
// dismisses the focused one.
Widget _focusKeyboardShortcut(BuildContext context) =>
    const _FocusKeyboardShortcut();

class _FocusKeyboardShortcut extends StatefulWidget {
  const _FocusKeyboardShortcut();

  @override
  State<_FocusKeyboardShortcut> createState() => _FocusKeyboardShortcutState();
}

class _FocusKeyboardShortcutState extends State<_FocusKeyboardShortcut> {
  final FluentToastController _toaster = FluentToastController();
  final List<FocusNode> _nodes = <FocusNode>[];
  FocusNode? _mostRecent;

  @override
  void dispose() {
    for (final FocusNode node in _nodes) {
      node.dispose();
    }
    _toaster.dispose();
    super.dispose();
  }

  void _notify() {
    final FocusNode node = FocusNode(debugLabel: 'Toast');
    _nodes.add(node);
    _mostRecent = node;
    _toaster.show(
      (BuildContext context, Object id) => Focus(
        focusNode: node,
        child: FluentToast(
          intent: FluentToastIntent.success,
          type: FluentToastType.action,
          action: FluentLink(
            onPressed: () => _toaster.dismiss(id),
            child: const Text('Dismiss'),
          ),
          title: const Text('Email sent'),
          body: const Text('This is a toast body'),
          subtitle: const Text('Subtitle'),
          footer: <Widget>[
            FluentLink(onPressed: () {}, child: const Text('Action')),
            FluentLink(onPressed: () {}, child: const Text('Action')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _toaster,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.s,
      children: <Widget>[
        FluentButton(onPressed: _notify, child: const Text('Make toast')),
        FluentButton(
          onPressed: () => _mostRecent?.requestFocus(),
          child: const Text('Focus most recent toast'),
        ),
      ],
    ),
  );
}
// #enddocregion components-toast--focus-keyboard-shortcut

// #docregion components-toast--inline
// `FluentToaster` always renders into the nearest `Overlay`, so "inline" is not
// a flag — it is a nearer overlay. `Overlay.wrap` gives the box one of its own
// and the toasts stack inside it. The dashed border upstream draws is solid
// here; a `BoxDecoration` border has no dash pattern.
Widget _inline(BuildContext context) => const _Inline();

class _Inline extends StatefulWidget {
  const _Inline();

  @override
  State<_Inline> createState() => _InlineState();
}

class _InlineState extends State<_Inline> {
  final FluentToastController _toaster = FluentToastController();

  @override
  void dispose() {
    _toaster.dispose();
    super.dispose();
  }

  void _notify() => _toaster.show(
    (BuildContext context, Object id) => FluentToast(
      intent: FluentToastIntent.success,
      type: FluentToastType.action,
      action: FluentLink(onPressed: () {}, child: const Text('Undo')),
      title: const Text('Email sent'),
    ),
    position: FluentToastPosition.bottom,
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 20,
    children: <Widget>[
      FluentButton(onPressed: _notify, child: const Text('Make toast')),
      SizedBox(
        width: 500,
        height: 500,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF008000), width: 2),
          ),
          child: Overlay.wrap(
            child: FluentToaster(
              controller: _toaster,
              child: Center(
                child: Text(
                  'Toasts appear here',
                  style: FluentTheme.of(context).typography.body1Strong,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// #enddocregion components-toast--inline
