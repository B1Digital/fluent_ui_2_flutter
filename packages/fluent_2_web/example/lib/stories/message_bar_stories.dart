import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentMessageBar].
///
/// The bar itself is inert: it takes no callback, reports no hover, press or
/// focus, and has no disabled rendering. Everything interactive in these
/// stories — the actions and the dismiss button — is a real [FluentButton].
final StorySection messageBarStories = StorySection(
  component: 'Message bar',
  description:
      'A tinted strip reporting a condition — an outage, a saved draft, a '
      'failed sync — with optional actions and a dismiss affordance. The '
      'intent moves the surface, the border and the glyph together onto one '
      'status token family; the layout decides whether the message may wrap.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis at once: intent, layout and shape, plus the optional '
          'title, glyph, actions and dismiss button.',
      knobs: const [
        OptionKnob<FluentMessageBarIntent>(
          label: 'Intent',
          id: 'intent',
          initial: FluentMessageBarIntent.info,
          options: FluentMessageBarIntent.values,
          labelOf: _intentLabel,
        ),
        OptionKnob<FluentMessageBarLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentMessageBarLayout.singleLine,
          options: FluentMessageBarLayout.values,
          labelOf: _layoutLabel,
        ),
        OptionKnob<FluentMessageBarShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentMessageBarShape.rounded,
          options: FluentMessageBarShape.values,
          labelOf: _shapeLabel,
        ),
        TextKnob(label: 'Title', id: 'title', initial: 'Descriptive title'),
        BoolKnob(label: 'Glyph', id: 'icon', initial: true),
        BoolKnob(label: 'Actions', id: 'actions'),
        BoolKnob(label: 'Dismiss button', id: 'dismiss', initial: true),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final title = knobs.get<String>('title', 'Descriptive title');
        return FluentMessageBar(
          intent: knobs.get<FluentMessageBarIntent>(
            'intent',
            FluentMessageBarIntent.info,
          ),
          layout: knobs.get<FluentMessageBarLayout>(
            'layout',
            FluentMessageBarLayout.singleLine,
          ),
          shape: knobs.get<FluentMessageBarShape>(
            'shape',
            FluentMessageBarShape.rounded,
          ),
          showIcon: knobs.get<bool>('icon', true),
          title: title.isEmpty ? null : Text(title),
          actions: knobs.get<bool>('actions', false)
              ? const <Widget>[_Action('Action'), _Action('Dismiss')]
              : const <Widget>[],
          // A no-op: this story is about the slots, and removing the bar would
          // take its own knobs off the screen with it. The Dismiss story wires
          // the callback to real removal.
          onDismiss: knobs.get<bool>('dismiss', true) ? _noop : null,
          child: const Text('Message providing information to the user.'),
        );
      },
    ),
    Story(
      name: 'Intents',
      description:
          'The four conditions a bar can report, each selecting one background, '
          'one border and one glyph. Error binds the *danger* family, and info '
          'binds no status family at all — it is neutral throughout.',
      knobs: const [
        OptionKnob<FluentMessageBarLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentMessageBarLayout.singleLine,
          options: FluentMessageBarLayout.values,
          labelOf: _layoutLabel,
        ),
      ],
      builder: (context) {
        final layout = KnobsScope.of(context).get<FluentMessageBarLayout>(
          'layout',
          FluentMessageBarLayout.singleLine,
        );
        return _Cases(
          children: [
            for (final intent in FluentMessageBarIntent.values)
              (
                _intentLabel(intent),
                FluentMessageBar(
                  intent: intent,
                  layout: layout,
                  title: Text(_intentTitle(intent)),
                  child: const Text(
                    'Message providing information to the user.',
                  ),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Layouts',
      description:
          'Single line pins the bar to 36 high and clips a message too long to '
          'fit; multi line lets it wrap and moves the actions to a second, '
          'right-aligned row. Drag the width to watch the difference appear.',
      knobs: [
        NumberKnob(
          label: 'Available width',
          id: 'width',
          initial: 520,
          min: 240,
          max: 900,
          step: 10,
        ),
      ],
      builder: _layoutsBuilder,
    ),
    const Story(
      name: 'Actions',
      description:
          'Actions are ordinary small buttons the bar lays out for you: inline '
          'before the dismiss button on a single-line bar, on a row of their '
          'own on a multi-line one.',
      builder: _actionsBuilder,
    ),
    const Story(
      name: 'Dismiss',
      description:
          'Passing onDismiss adds a 24-square dismiss button; the callback is '
          'yours, so removing the bar is your state change. Omit it and no '
          'button is rendered.',
      builder: _dismissBuilder,
    ),
    Story(
      name: 'Shape',
      description:
          'Rounded is the 4px default; square is for a bar flush against the '
          'edges of a pane or dialog. There is no circular shape — neither the '
          'component set nor React offers one.',
      knobs: const [
        OptionKnob<FluentMessageBarIntent>(
          label: 'Intent',
          id: 'intent',
          initial: FluentMessageBarIntent.warning,
          options: FluentMessageBarIntent.values,
          labelOf: _intentLabel,
        ),
      ],
      builder: (context) {
        final intent = KnobsScope.of(
          context,
        ).get<FluentMessageBarIntent>('intent', FluentMessageBarIntent.warning);
        return _Cases(
          children: [
            for (final shape in FluentMessageBarShape.values)
              (
                _shapeLabel(shape),
                FluentMessageBar(
                  intent: intent,
                  shape: shape,
                  child: const Text('Message providing information.'),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Icon',
      description:
          'The glyph follows the intent unless you replace it, and showIcon: '
          'false removes it together with its gap.',
      builder: _iconBuilder,
    ),
  ],
);

void _noop() {}

String _intentLabel(FluentMessageBarIntent value) => value.name;

String _layoutLabel(FluentMessageBarLayout value) => value.name;

String _shapeLabel(FluentMessageBarShape value) => value.name;

String _intentTitle(FluentMessageBarIntent intent) => switch (intent) {
  FluentMessageBarIntent.info => 'Scheduled maintenance',
  FluentMessageBarIntent.success => 'Changes saved',
  FluentMessageBarIntent.warning => 'Storage almost full',
  FluentMessageBarIntent.error => 'Sync failed',
};

Widget _layoutsBuilder(BuildContext context) {
  final width = KnobsScope.of(context).get<double>('width', 520);
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: SizedBox(
      width: width,
      child: _Cases(
        children: [
          for (final layout in FluentMessageBarLayout.values)
            (
              _layoutLabel(layout),
              FluentMessageBar(
                layout: layout,
                intent: FluentMessageBarIntent.warning,
                title: const Text('Storage almost full'),
                actions: const <Widget>[_Action('Manage storage')],
                onDismiss: _noop,
                child: const Text(
                  'Delete files you no longer need, or add more storage to '
                  'keep syncing this device.',
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _actionsBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'None',
      FluentMessageBar(
        title: Text('Draft saved'),
        child: Text('Your changes are stored locally.'),
      ),
    ),
    (
      'One action',
      FluentMessageBar(
        intent: FluentMessageBarIntent.error,
        title: Text('Sync failed'),
        actions: <Widget>[_Action('Retry')],
        child: Text('We could not reach the server.'),
      ),
    ),
    (
      'Two actions and a dismiss button',
      FluentMessageBar(
        intent: FluentMessageBarIntent.error,
        title: Text('Sync failed'),
        actions: <Widget>[_Action('Retry'), _Action('Details')],
        onDismiss: _noop,
        child: Text('We could not reach the server.'),
      ),
    ),
    (
      'Multi line moves them to their own row',
      FluentMessageBar(
        layout: FluentMessageBarLayout.multiLine,
        intent: FluentMessageBarIntent.error,
        title: Text('Sync failed'),
        actions: <Widget>[_Action('Retry'), _Action('Details')],
        onDismiss: _noop,
        child: Text(
          'We could not reach the server. Your changes are safe on this '
          'device and will upload once the connection returns.',
        ),
      ),
    ),
    (
      'A disabled action',
      FluentMessageBar(
        intent: FluentMessageBarIntent.warning,
        title: Text('Upload paused'),
        // A FluentButton with no onPressed is genuinely disabled — the bar has
        // no disabled treatment of its own, only its slots do.
        actions: <Widget>[
          FluentButton(size: FluentButtonSize.small, child: Text('Resume')),
        ],
        child: Text('Reconnect to continue.'),
      ),
    ),
  ],
);

Widget _dismissBuilder(BuildContext context) => const _Dismissable();

Widget _iconBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Intent default',
      FluentMessageBar(
        intent: FluentMessageBarIntent.success,
        title: Text('Changes saved'),
        child: Text('Everyone with the link can see them.'),
      ),
    ),
    (
      'Replaced',
      FluentMessageBar(
        intent: FluentMessageBarIntent.success,
        icon: Icon(FluentIcons.person_20_regular),
        title: Text('Invitation sent'),
        child: Text('Ada will get an email shortly.'),
      ),
    ),
    (
      'No glyph',
      FluentMessageBar(
        intent: FluentMessageBarIntent.success,
        showIcon: false,
        title: Text('Changes saved'),
        child: Text('Everyone with the link can see them.'),
      ),
    ),
  ],
);

/// A bar the reader can actually dismiss, with a way to bring it back.
class _Dismissable extends StatefulWidget {
  const _Dismissable();

  @override
  State<_Dismissable> createState() => _DismissableState();
}

class _DismissableState extends State<_Dismissable> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: [
      if (_visible)
        FluentMessageBar(
          intent: FluentMessageBarIntent.warning,
          title: const Text('Storage almost full'),
          onDismiss: () => setState(() => _visible = false),
          dismissSemanticLabel: 'Dismiss storage warning',
          child: const Text('You have used 95% of your quota.'),
        )
      else
        const FluentMessageBar(
          showIcon: false,
          child: Text('Dismissed. Nothing animates — the bar is simply gone.'),
        ),
      FluentButton(
        appearance: FluentButtonAppearance.secondary,
        onPressed: _visible ? null : () => setState(() => _visible = true),
        child: const Text('Bring it back'),
      ),
    ],
  );
}

/// One action slot: a small button, which is what the bar's own geometry is
/// measured against.
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

/// Stacked full-width cases under a caption — a message bar spans its column,
/// so these read top to bottom rather than side by side.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xl,
      children: [
        for (final (caption, child) in children)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
