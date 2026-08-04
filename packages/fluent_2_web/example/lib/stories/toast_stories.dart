import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentToast] and [FluentToaster].
///
/// Two components, one page, because neither is much use alone: [FluentToast]
/// is an inert surface that renders wherever it is put, and [FluentToaster] is
/// the queue, the corner, the stack, the clock and the motion around it. Every
/// story that raises a real toast owns a [FluentToastController] and a toaster
/// of its own, so pressing a button here puts a toast in the app's own
/// [Overlay] — over the gallery chrome, not inside the canvas box.
final StorySection toastStories = StorySection(
  component: 'Toast',
  description:
      'A raised notification that appears in a corner of the app, announces '
      'itself to assistive technology and leaves on its own. The intent moves '
      'only the glyph — unlike a message bar, the surface stays neutral in '
      'every intent.',
  stories: [
    Story(
      name: 'Default',
      description:
          'One toast raised through a controller, with every per-toast option '
          'of show() live: the intent, the corner, the countdown and whether '
          'the pointer pauses it.',
      knobs: const [
        OptionKnob<FluentToastIntent>(
          label: 'Intent',
          id: 'intent',
          initial: FluentToastIntent.info,
          options: FluentToastIntent.values,
          labelOf: _intentLabel,
        ),
        OptionKnob<FluentToastPosition>(
          label: 'Position',
          id: 'position',
          initial: FluentToastPosition.bottomEnd,
          options: FluentToastPosition.values,
          labelOf: _positionLabel,
        ),
        NumberKnob(
          label: 'Timeout (seconds, 0 never expires)',
          id: 'timeout',
          initial: 3,
          max: 10,
        ),
        BoolKnob(label: 'Pause on hover', id: 'pause', initial: true),
        TextKnob(
          label: 'Body',
          id: 'body',
          initial: 'Your message is on its way.',
        ),
        TextKnob(label: 'Subtitle', id: 'subtitle'),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Intents',
      description:
          'The five statuses, each moving the glyph onto one token family. '
          'Error binds the *danger* family, info is neutral, and custom has no '
          'glyph of its own — you supply one.',
      builder: _intentsBuilder,
    ),
    const Story(
      name: 'Inline',
      description:
          'The surface on its own, with no toaster: a toast renders anywhere '
          'you put it, and the slots stack title, body, subtitle and a footer '
          'action row under one indent.',
      builder: _inlineBuilder,
    ),
    const Story(
      name: 'End slot',
      description:
          'The three things that can sit in the trailing 20-square: a dismiss '
          'button, a timestamp label, or an action affordance such as a link.',
      builder: _endSlotBuilder,
    ),
    const Story(
      name: 'Positions',
      description:
          'Six anchors, each its own stack; a toast raised into a corner grows '
          'the block away from the edge it is pinned to. Turn on RTL and the '
          'start and end corners mirror.',
      builder: _positionsBuilder,
    ),
    const Story(
      name: 'Timeout and pause',
      description:
          'The countdown is a clock, not a transition: resting the pointer on '
          'a toast stops it and moving away resumes it where it stopped, and a '
          'timeout of zero never expires at all.',
      knobs: [
        NumberKnob(
          label: 'Timeout (seconds, 0 never expires)',
          id: 'timeout',
          initial: 5,
          max: 10,
        ),
        BoolKnob(label: 'Pause on hover', id: 'pause', initial: true),
      ],
      builder: _timeoutBuilder,
    ),
    const Story(
      name: 'Dismissing',
      description:
          'Four ways out: the toast\'s own dismiss button, an action inside it, '
          'dismiss(id) from anywhere, and dismissAll(). Escape closes a toast '
          'that holds keyboard focus, and focus goes back to the trigger.',
      builder: _dismissBuilder,
    ),
    const Story(
      name: 'Update in place',
      description:
          'Showing an id that is already queued replaces that toast where it '
          'stands, keeping its slot in the stack instead of re-queueing it at '
          'the end.',
      builder: _updateBuilder,
    ),
    const Story(
      name: 'Progress',
      description:
          'A long task reported as one toast that updates itself: a progress '
          'bar in the body, replaced under the same id on every tick and '
          'swapped for a success toast at the end.',
      builder: _progressBuilder,
    ),
    const Story(
      name: 'Lifecycle',
      description:
          'The controller is a ChangeNotifier, so its queue is observable: '
          'entries stay in it while a dismissed toast runs its 600ms exit and '
          'are dropped only once that finishes.',
      builder: _lifecycleBuilder,
    ),
    const Story(
      name: 'Offset',
      description:
          'How far the stacks sit from the edges of the overlay. The '
          'horizontal component is ignored by the two centred positions.',
      knobs: [
        NumberKnob(
          label: 'Horizontal',
          id: 'horizontal',
          initial: FluentSpacing.xl,
          max: 120,
        ),
        NumberKnob(
          label: 'Vertical',
          id: 'vertical',
          initial: FluentSpacing.l,
          max: 120,
        ),
      ],
      builder: _offsetBuilder,
    ),
    const Story(
      name: 'Multiple toasters',
      description:
          'Two toasters, two controllers, addressed independently — each is a '
          'plain object the app holds, so reaching one rather than the other '
          'needs no ids or event bus.',
      builder: _multipleBuilder,
    ),
    const Story(
      name: 'Styling',
      description:
          'A style on the toaster restyles every toast it renders; a style on '
          'one toast is merged last and wins. Here the toaster inverts the '
          'surface onto the inverted neutral tokens.',
      knobs: [
        BoolKnob(label: 'Invert the toaster', id: 'invert', initial: true),
      ],
      builder: _stylingBuilder,
    ),
  ],
);

// ---- knob labels ----------------------------------------------------------

String _intentLabel(FluentToastIntent value) => value.name;

String _positionLabel(FluentToastPosition value) => value.name;

// ---- shared pieces --------------------------------------------------------

/// A toast wired to dismiss itself through the [controller] that raised it,
/// which is what the `id` handed to a toast builder is for.
FluentToast _demoToast(
  FluentToastController controller,
  Object id, {
  required String title,
  String? body,
  FluentToastIntent intent = FluentToastIntent.info,
}) => FluentToast(
  intent: intent,
  title: Text(title),
  body: body == null ? null : Text(body),
  onDismiss: () => controller.dismiss(id),
);

String _title(FluentToastIntent intent) => switch (intent) {
  FluentToastIntent.info => 'Meeting starts in 5 minutes',
  FluentToastIntent.success => 'Mail sent',
  FluentToastIntent.warning => 'Storage almost full',
  FluentToastIntent.error => 'Sync failed',
  FluentToastIntent.custom => 'Uploading',
};

String _body(FluentToastIntent intent) => switch (intent) {
  FluentToastIntent.info => 'Design review, Teams call.',
  FluentToastIntent.success => 'Ada will get it shortly.',
  FluentToastIntent.warning => 'You have used 95% of your quota.',
  FluentToastIntent.error => 'We could not reach the server.',
  FluentToastIntent.custom => 'Three files left.',
};

// ---- builders -------------------------------------------------------------

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  // Read here rather than inside the toast builder: that one runs inside the
  // Overlay, in a branch of the tree the gallery's KnobsScope does not reach.
  final intent = knobs.get<FluentToastIntent>('intent', FluentToastIntent.info);
  final position = knobs.get<FluentToastPosition>(
    'position',
    FluentToastPosition.bottomEnd,
  );
  final timeout = Duration(
    milliseconds: (knobs.get<double>('timeout', 3) * 1000).round(),
  );
  final pauseOnHover = knobs.get<bool>('pause', true);
  final body = knobs.get<String>('body', 'Your message is on its way.');
  final subtitle = knobs.get<String>('subtitle', '');

  return _Toasted(
    builder: (_, controller) => FluentButton(
      appearance: FluentButtonAppearance.primary,
      onPressed: () => controller.show(
        (_, id) => FluentToast(
          intent: intent,
          title: Text(_title(intent)),
          body: body.isEmpty ? null : Text(body),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          // The custom intent draws no glyph of its own.
          icon: intent == FluentToastIntent.custom
              ? const FluentSpinner(size: FluentSpinnerSize.extraTiny)
              : null,
          onDismiss: () => controller.dismiss(id),
        ),
        position: position,
        timeout: timeout,
        pauseOnHover: pauseOnHover,
      ),
      child: const Text('Show toast'),
    ),
  );
}

Widget _intentsBuilder(BuildContext context) => _Toasted(
  builder: (_, controller) => _Buttons(
    children: [
      for (final intent in FluentToastIntent.values)
        (
          _intentLabel(intent),
          () => controller.show(
            (_, id) => FluentToast(
              intent: intent,
              title: Text(_title(intent)),
              body: Text(_body(intent)),
              // Custom is the mode Figma splits into Icon, Spinner and Avatar:
              // same neutral tint, different widget in the status slot.
              icon: intent == FluentToastIntent.custom
                  ? const FluentSpinner(size: FluentSpinnerSize.extraTiny)
                  : null,
              onDismiss: () => controller.dismiss(id),
            ),
            timeout: Duration.zero,
          ),
        ),
    ],
  ),
);

Widget _inlineBuilder(BuildContext context) => const _Cases(
  children: [
    ('Title only', FluentToast(title: Text('Mail sent'))),
    (
      'Title and body',
      FluentToast(
        intent: FluentToastIntent.success,
        title: Text('Mail sent'),
        body: Text('Ada will get it shortly.'),
      ),
    ),
    (
      'With a subtitle',
      FluentToast(
        intent: FluentToastIntent.success,
        title: Text('Mail sent'),
        body: Text('Ada will get it shortly.'),
        subtitle: Text('Sent from Outlook for Windows'),
      ),
    ),
    (
      'With footer actions',
      FluentToast(
        intent: FluentToastIntent.warning,
        title: Text('Message moved to Archive'),
        body: Text('You can put it back for the next 30 days.'),
        footer: <Widget>[_Action('Undo'), _Action('Open folder')],
      ),
    ),
    (
      'No glyph',
      FluentToast(
        showIcon: false,
        title: Text('Draft saved'),
        body: Text('The body loses its indent along with the glyph.'),
      ),
    ),
  ],
);

Widget _endSlotBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Dismiss — a button, rendered only when onDismiss is given',
      FluentToast(
        title: Text('Mail sent'),
        body: Text('Ada will get it shortly.'),
        onDismiss: _noop,
      ),
    ),
    (
      'Timestamp — a caption label',
      FluentToast(
        type: FluentToastType.timestamp,
        title: Text('Ada Lovelace'),
        body: Text('Are we still on for Thursday?'),
        timestamp: Text('2m ago'),
      ),
    ),
    (
      'Action — usually a link',
      FluentToast(
        intent: FluentToastIntent.error,
        type: FluentToastType.action,
        title: Text('Sync failed'),
        body: Text('We could not reach the server.'),
        action: FluentLink(onPressed: _noop, child: Text('Retry')),
      ),
    ),
  ],
);

Widget _positionsBuilder(BuildContext context) => _Toasted(
  builder: (_, controller) => _Buttons(
    children: [
      for (final position in FluentToastPosition.values)
        (
          _positionLabel(position),
          () => controller.show(
            (_, id) => _demoToast(
              controller,
              id,
              title: _positionLabel(position),
              body: 'Raised into this corner.',
            ),
            position: position,
            timeout: Duration.zero,
          ),
        ),
      ('Dismiss all', controller.dismissAll),
    ],
  ),
);

Widget _timeoutBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final seconds = knobs.get<double>('timeout', 5);
  final pauseOnHover = knobs.get<bool>('pause', true);
  final timeout = Duration(milliseconds: (seconds * 1000).round());

  return _Toasted(
    builder: (_, controller) => _Buttons(
      children: [
        (
          seconds == 0 ? 'Show (never expires)' : 'Show (${seconds.round()}s)',
          () => controller.show(
            (_, id) => _demoToast(
              controller,
              id,
              intent: FluentToastIntent.success,
              title: 'Mail sent',
              body: pauseOnHover
                  ? 'Rest the pointer here to hold the clock.'
                  : 'The clock runs even under the pointer.',
            ),
            timeout: timeout,
            pauseOnHover: pauseOnHover,
          ),
        ),
        (
          'Show the default 3s',
          () => controller.show(
            (_, id) => _demoToast(
              controller,
              id,
              title: 'Default timeout',
              body: 'fluentToastTimeout is 3000ms.',
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _dismissBuilder(BuildContext context) => const _Dismissing();

Widget _updateBuilder(BuildContext context) => const _Updating();

Widget _progressBuilder(BuildContext context) => const _Progress();

Widget _lifecycleBuilder(BuildContext context) => const _Lifecycle();

Widget _offsetBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return _Toasted(
    offset: EdgeInsets.symmetric(
      horizontal: knobs.get<double>('horizontal', FluentSpacing.xl),
      vertical: knobs.get<double>('vertical', FluentSpacing.l),
    ),
    builder: (_, controller) => _Buttons(
      children: [
        (
          'Corner',
          () => controller.show(
            (_, id) => _demoToast(
              controller,
              id,
              title: 'Bottom end',
              body: 'Inset by both components.',
            ),
            timeout: Duration.zero,
          ),
        ),
        (
          'Centred',
          () => controller.show(
            (_, id) => _demoToast(
              controller,
              id,
              title: 'Bottom centre',
              body: 'The horizontal inset is ignored here.',
            ),
            position: FluentToastPosition.bottom,
            timeout: Duration.zero,
          ),
        ),
        ('Dismiss all', controller.dismissAll),
      ],
    ),
  );
}

Widget _multipleBuilder(BuildContext context) => const _MultipleToasters();

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  final inverted = KnobsScope.of(context).get<bool>('invert', true);

  return _Toasted(
    style: inverted
        ? FluentToastStyle.from(
            backgroundColor: colors.neutralBackgroundInverted,
            foregroundColor: colors.neutralForegroundInverted,
            subtitleColor: colors.neutralForegroundInverted,
            iconColor: colors.neutralForegroundInverted,
          )
        : null,
    builder: (_, controller) => _Buttons(
      children: [
        (
          'Toaster style',
          () => controller.show(
            (_, id) => _demoToast(
              controller,
              id,
              title: 'Styled by the toaster',
              body: 'Every toast this toaster renders picks it up.',
            ),
            timeout: Duration.zero,
          ),
        ),
        (
          'This toast only',
          () => controller.show(
            (_, id) => FluentToast(
              title: const Text('Styled by itself'),
              body: const Text('A wider surface, merged last so it wins.'),
              style: const FluentToastStyle(
                width: WidgetStatePropertyAll<double?>(360),
              ),
              onDismiss: () => controller.dismiss(id),
            ),
            timeout: Duration.zero,
          ),
        ),
        ('Dismiss all', controller.dismissAll),
      ],
    ),
  );
}

void _noop() {}

// ---- stateful stories -----------------------------------------------------

/// A toaster and the controller its buttons drive, owned for as long as the
/// story is on screen.
///
/// The toasts go into the app's own [Overlay], so they paint over the whole
/// gallery rather than inside the canvas box — which is exactly what a toast
/// does in a real app.
class _Toasted extends StatefulWidget {
  const _Toasted({
    required this.builder,
    this.style,
    this.offset = const EdgeInsets.symmetric(
      horizontal: FluentSpacing.xl,
      vertical: FluentSpacing.l,
    ),
  });

  /// Builds the story's own content, given the controller to raise toasts on.
  final Widget Function(BuildContext context, FluentToastController controller)
  builder;

  /// Applied to every toast this toaster renders.
  final FluentToastStyle? style;

  /// Inset from the edges of the overlay.
  final EdgeInsets offset;

  @override
  State<_Toasted> createState() => _ToastedState();
}

class _ToastedState extends State<_Toasted> {
  final FluentToastController _controller = FluentToastController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _controller,
    style: widget.style,
    offset: widget.offset,
    child: widget.builder(context, _controller),
  );
}

/// Every exit the API offers, including one driven from inside a toast.
class _Dismissing extends StatefulWidget {
  const _Dismissing();

  @override
  State<_Dismissing> createState() => _DismissingState();
}

class _DismissingState extends State<_Dismissing> {
  Object? _last;

  @override
  Widget build(BuildContext context) => _Toasted(
    builder: (_, controller) => _Buttons(
      children: [
        (
          'Show a sticky toast',
          () => setState(() {
            _last = controller.show(
              (_, id) => FluentToast(
                title: const Text('Message moved to Archive'),
                body: const Text('It stays until something dismisses it.'),
                footer: <Widget>[
                  FluentButton(
                    size: FluentButtonSize.small,
                    onPressed: () => controller.dismiss(id),
                    child: const Text('Undo'),
                  ),
                ],
                onDismiss: () => controller.dismiss(id),
              ),
              timeout: Duration.zero,
            );
          }),
        ),
        (
          'Dismiss the last one',
          _last == null ? null : () => controller.dismiss(_last!),
        ),
        ('Dismiss all', controller.dismissAll),
      ],
    ),
  );
}

/// One id, shown over and over — upstream's `updateToast`.
class _Updating extends StatefulWidget {
  const _Updating();

  @override
  State<_Updating> createState() => _UpdatingState();
}

class _UpdatingState extends State<_Updating> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => _Toasted(
    builder: (_, controller) => _Buttons(
      children: [
        (
          'Add a message',
          () {
            setState(() => _count++);
            final count = _count;
            controller.show(
              (_, id) => _demoToast(
                controller,
                id,
                title: '$count unread ${count == 1 ? 'message' : 'messages'}',
                body: 'Same id, same slot in the stack.',
              ),
              id: 'unread',
              timeout: Duration.zero,
            );
          },
        ),
        (
          'Queue a second toast',
          () => controller.show(
            (_, id) => _demoToast(
              controller,
              id,
              title: 'A different toast',
              body: 'A new id, so it takes a new slot.',
            ),
            timeout: Duration.zero,
          ),
        ),
        (
          'Reset',
          () {
            setState(() => _count = 0);
            controller.dismissAll();
          },
        ),
      ],
    ),
  );
}

/// A toast that reports its own progress by replacing itself under one id.
class _Progress extends StatefulWidget {
  const _Progress();

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  static const Object _id = 'upload';

  final FluentToastController _controller = FluentToastController();
  Timer? _timer;
  double _value = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _value = 0;
    _showProgress();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _value += 0.125;
      if (_value >= 1) {
        timer.cancel();
        _showDone();
        return;
      }
      _showProgress();
    });
  }

  void _showProgress() {
    final value = _value;
    _controller.show(
      (_, id) => FluentToast(
        intent: FluentToastIntent.custom,
        icon: const FluentSpinner(size: FluentSpinnerSize.extraTiny),
        title: const Text('Uploading photos'),
        body: FluentProgressBar(value: value, semanticLabel: 'Upload'),
        subtitle: Text('${(value * 100).round()}% complete'),
        onDismiss: _stop,
      ),
      id: _id,
      timeout: Duration.zero,
    );
  }

  void _showDone() => _controller.show(
    (_, id) => _demoToast(
      _controller,
      id,
      intent: FluentToastIntent.success,
      title: 'Photos uploaded',
      body: 'The same toast, swapped to its finished state.',
    ),
    id: _id,
  );

  void _stop() {
    _timer?.cancel();
    _controller.dismiss(_id);
  }

  @override
  Widget build(BuildContext context) => FluentToaster(
    controller: _controller,
    child: _Buttons(
      children: [('Start the upload', _start), ('Cancel', _stop)],
    ),
  );
}

/// The controller's queue, read live off the [ChangeNotifier] it is.
class _Lifecycle extends StatefulWidget {
  const _Lifecycle();

  @override
  State<_Lifecycle> createState() => _LifecycleState();
}

class _LifecycleState extends State<_Lifecycle> {
  final FluentToastController _controller = FluentToastController();
  int _serial = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentToaster(
      controller: _controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.l,
        children: [
          _Buttons(
            children: [
              (
                'Raise one (3s)',
                () {
                  final n = ++_serial;
                  _controller.show(
                    (_, id) => _demoToast(
                      _controller,
                      id,
                      title: 'Toast $n',
                      body: 'Watch it leave the queue below.',
                    ),
                  );
                },
              ),
              ('Dismiss all', _controller.dismissAll),
            ],
          ),
          FluentDivider(),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final entries = _controller.entries;
              if (entries.isEmpty) {
                return Text(
                  'The queue is empty.',
                  style: theme.typography.body1.copyWith(
                    color: theme.colors.neutralForeground3,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: FluentSpacing.xs,
                children: [
                  for (final entry in entries)
                    Text(
                      '${entry.id}  ·  ${entry.position.name}  ·  '
                      '${entry.visible ? 'visible' : 'leaving'}',
                      style: theme.typography.body1.copyWith(
                        color: entry.visible
                            ? theme.colors.neutralForeground1
                            : theme.colors.neutralForeground3,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Two toasters over one app, each addressed through its own controller.
class _MultipleToasters extends StatefulWidget {
  const _MultipleToasters();

  @override
  State<_MultipleToasters> createState() => _MultipleToastersState();
}

class _MultipleToastersState extends State<_MultipleToasters> {
  final FluentToastController _notifications = FluentToastController();
  final FluentToastController _system = FluentToastController();

  @override
  void dispose() {
    _notifications.dispose();
    _system.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FluentTheme.of(context).colors;
    return FluentToaster(
      controller: _notifications,
      child: FluentToaster(
        controller: _system,
        // The second toaster carries its own style, so which one raised a
        // toast is visible at a glance.
        style: FluentToastStyle.from(
          backgroundColor: colors.neutralBackgroundInverted,
          foregroundColor: colors.neutralForegroundInverted,
          subtitleColor: colors.neutralForegroundInverted,
          iconColor: colors.neutralForegroundInverted,
        ),
        child: _Buttons(
          children: [
            (
              'Notification (bottom end)',
              () => _notifications.show(
                (_, id) => _demoToast(
                  _notifications,
                  id,
                  intent: FluentToastIntent.success,
                  title: 'Mail sent',
                  body: 'From the notifications toaster.',
                ),
                timeout: Duration.zero,
              ),
            ),
            (
              'System (top start)',
              () => _system.show(
                (_, id) => _demoToast(
                  _system,
                  id,
                  title: 'Update available',
                  body: 'From the system toaster.',
                ),
                position: FluentToastPosition.topStart,
                timeout: Duration.zero,
              ),
            ),
            ('Clear notifications', _notifications.dismissAll),
            ('Clear system', _system.dismissAll),
          ],
        ),
      ),
    );
  }
}

// ---- layout helpers -------------------------------------------------------

/// A row of triggers. A null callback disables its button, which is what a
/// [FluentButton] with no `onPressed` already means.
class _Buttons extends StatelessWidget {
  const _Buttons({required this.children});

  final List<(String, VoidCallback?)> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: FluentSpacing.m,
    runSpacing: FluentSpacing.m,
    children: [
      for (final (label, onPressed) in children)
        FluentButton(onPressed: onPressed, child: Text(label)),
    ],
  );
}

/// One footer action: a small button, which is what the footer row's geometry
/// is measured against.
class _Action extends StatelessWidget {
  const _Action(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => FluentButton(
    size: FluentButtonSize.small,
    onPressed: _noop,
    child: Text(label),
  );
}

/// Inline surfaces under a caption, left-aligned — a toast carries its own
/// 292 width, so these do not stretch.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xl,
      children: [
        for (final (caption, child) in children)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: FluentSpacing.xs,
            children: [
              Text(
                caption,
                style: theme.typography.caption1.copyWith(
                  color: theme.colors.neutralForeground3,
                ),
              ),
              child,
            ],
          ),
      ],
    );
  }
}
