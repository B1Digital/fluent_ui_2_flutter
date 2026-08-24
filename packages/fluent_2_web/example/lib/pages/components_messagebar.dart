import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The MessageBar docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream's `MessageBarBody` is an inline paragraph carrying a `Link`, so the
/// Dart body is a [Text.rich] with the link as a baseline-aligned
/// [WidgetSpan] — which is what [FluentMessageBar] flows after its title.
/// There is no `MessageBarGroup` in this package; the two sections built around
/// it compose the bordered, scrolling container by hand.
const DocsPage messageBarPage = DocsPage(
  id: 'components-messagebar',
  title: 'MessageBar',
  description:
      'Communicates important information about the state of the entire '
      'application or surface. For example, the status of a page, panel, '
      "dialog or card. The information shouldn't require someone to take "
      'immediate action, but should persist until the user performs one of '
      'the required actions.',
  source: 'lib/pages/components_messagebar.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-messagebar--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-messagebar--intent',
      title: 'Intent',
      description:
          'MessageBar components come built-in with preset intents that '
          'determine the design and aria live announcement, While it is '
          "recommended to use the preset intents, it's possible to configure "
          'the aria live politeness with the politeness prop.',
      builder: _intent,
    ),
    DocsSection(
      id: 'components-messagebar--shape',
      title: 'Shape',
      description:
          'MessageBar can have either rounded or square corners, please follow '
          'the usage guidance for these shapes:\n'
          '- rounded used for component level message bars\n'
          '- square used for page/app level message bars',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-messagebar--actions',
      title: 'Actions',
      description: 'The MessageBar can have different actions.',
      builder: _actions,
    ),
    DocsSection(
      id: 'components-messagebar--dismiss',
      title: 'Dismiss',
      description:
          'MessageBar components should be used in a MessageBarGroup when '
          'possible to enable exit animations. Once inside a MessageBarGroup '
          'component, the default exit animation will trigger automatically '
          'when the component is unmounted from DOM.',
      builder: _dismiss,
    ),
    DocsSection(
      id: 'components-messagebar--animation',
      title: 'Animation',
      description:
          'Enter animations are also handled within the MessageBarGroup. '
          'However avoid entry animations for MessageBar components on page '
          'load. However, MessageBar components that are mounted during the '
          'lifecycle of an app can use enter animations. Animation will only '
          'function if the only children of MessageBarGroup are MessageBar '
          'components. Do not wrap MessageBar with other components. This is '
          'a known limitation we are actively working on.',
      builder: _animation,
    ),
    DocsSection(
      id: 'components-messagebar--reflow',
      title: 'Reflow',
      description:
          'The MessageBar will reflow by default once the body content wraps '
          'to a second line. This changes the layout of the actions in the '
          'MessageBar.',
      builder: _reflow,
    ),
    DocsSection(
      id: 'components-messagebar--manual-layout',
      title: 'Manual Layout',
      description:
          "It's possible to opt out of automatic reflow with the layout prop. "
          'This can be useful if an application has an existing responsive '
          'design mechanism.',
      builder: _manualLayout,
    ),
  ],
  props: <PropRow>[
    PropRow(name: 'child', type: 'Widget', description: 'The message.'),
    PropRow(
      name: 'intent',
      type: 'FluentMessageBarIntent',
      defaultValue: 'FluentMessageBarIntent.info',
      description:
          'What the message is about. Moves the surface, border and glyph '
          'together.',
    ),
    PropRow(
      name: 'layout',
      type: 'FluentMessageBarLayout',
      defaultValue: 'FluentMessageBarLayout.singleLine',
      description: 'How the bar arranges its glyph, body and actions.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentMessageBarShape',
      defaultValue: 'FluentMessageBarShape.rounded',
      description: 'Corner treatment.',
    ),
    PropRow(
      name: 'title',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'A lead-in flowed inline before child, in the strong ramp.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Overrides the glyph intent would otherwise select.',
    ),
    PropRow(
      name: 'showIcon',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether a glyph is drawn at all. False removes it and its gap.',
    ),
    PropRow(
      name: 'actions',
      type: 'List<Widget>',
      defaultValue: '[]',
      description: 'Action affordances. Usually small FluentButtons.',
    ),
    PropRow(
      name: 'onDismiss',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked by the dismiss button. Null renders no dismiss button.',
    ),
    PropRow(
      name: 'dismissSemanticLabel',
      type: 'String',
      defaultValue: "'Dismiss'",
      description:
          'Announced by assistive technology for the dismiss button, which has '
          'no text of its own.',
    ),
    PropRow(
      name: 'liveRegion',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether assistive technology announces the bar when it appears.',
    ),
  ],
);

// #docregion components-messagebar--default
Widget _default(BuildContext context) => FluentMessageBar(
  title: const Text('Descriptive title'),
  actions: <Widget>[
    FluentButton(
      size: FluentButtonSize.small,
      onPressed: () {},
      child: const Text('Action'),
    ),
    FluentButton(
      size: FluentButtonSize.small,
      onPressed: () {},
      child: const Text('Action'),
    ),
  ],
  onDismiss: () {},
  dismissSemanticLabel: 'dismiss',
  child: Text.rich(
    TextSpan(
      children: <InlineSpan>[
        const TextSpan(
          text:
              'Message providing information to the user with actionable insights. ',
        ),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: FluentLink(
            inline: true,
            onPressed: () {},
            child: const Text('Link'),
          ),
        ),
      ],
    ),
  ),
);
// #enddocregion components-messagebar--default

// #docregion components-messagebar--intent
Widget _intent(BuildContext context) {
  // Upstream maps over `["info", "warning", "error", "success"]` and prints the
  // string in the title, so the label travels with the enum value rather than
  // being read back off it — our enum declares `success` second.
  const intents = <(FluentMessageBarIntent, String)>[
    (FluentMessageBarIntent.info, 'info'),
    (FluentMessageBarIntent.warning, 'warning'),
    (FluentMessageBarIntent.error, 'error'),
    (FluentMessageBarIntent.success, 'success'),
  ];

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 10,
    children: <Widget>[
      for (final (FluentMessageBarIntent intent, String name) in intents)
        FluentMessageBar(
          intent: intent,
          title: Text('Intent $name'),
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(
                  text:
                      'Message providing information to the user with actionable insights. ',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: FluentLink(
                    inline: true,
                    onPressed: () {},
                    child: const Text('Link'),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
// #enddocregion components-messagebar--intent

// #docregion components-messagebar--shape
Widget _shape(BuildContext context) => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: 10,
  children: <Widget>[
    FluentMessageBar(
      title: Text('Rounded shape'),
      child: Text('This message has rounded shape.'),
    ),
    FluentMessageBar(
      shape: FluentMessageBarShape.square,
      title: Text('Square shape'),
      child: Text('This message has square shape.'),
    ),
  ],
);
// #enddocregion components-messagebar--shape

// #docregion components-messagebar--actions
Widget _actions(BuildContext context) => FluentMessageBar(
  title: const Text('Descriptive title'),
  actions: <Widget>[
    FluentButton(
      size: FluentButtonSize.small,
      onPressed: () {},
      child: const Text('Action'),
    ),
    FluentButton(
      size: FluentButtonSize.small,
      onPressed: () {},
      child: const Text('Action'),
    ),
  ],
  onDismiss: () {},
  dismissSemanticLabel: 'Dismiss',
  child: Text.rich(
    TextSpan(
      children: <InlineSpan>[
        const TextSpan(
          text:
              'Message providing information to the user with actionable insights. ',
        ),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: FluentLink(
            inline: true,
            onPressed: () {},
            child: const Text('Link'),
          ),
        ),
      ],
    ),
  ),
);
// #enddocregion components-messagebar--actions

// #docregion components-messagebar--dismiss
// There is no `MessageBarGroup` in this package, so the bordered, scrolling
// container upstream styles onto it is built here from a SizedBox and a
// DecoratedBox. Dismissing removes the bar immediately: the exit animation the
// group exists to provide has no Dart counterpart.
Widget _dismiss(BuildContext context) => const _Dismiss();

class _Dismiss extends StatefulWidget {
  const _Dismiss();

  @override
  State<_Dismiss> createState() => _DismissState();
}

class _DismissState extends State<_Dismiss> {
  static const List<FluentMessageBarIntent> _intents = <FluentMessageBarIntent>[
    FluentMessageBarIntent.info,
    FluentMessageBarIntent.warning,
    FluentMessageBarIntent.error,
    FluentMessageBarIntent.success,
  ];

  final List<(FluentMessageBarIntent, int)> _messages =
      <(FluentMessageBarIntent, int)>[];
  int _counter = 0;

  // Upstream picks the intent at random. Cycling keeps the demo reproducible.
  void _addMessage() => setState(() {
    final id = _counter++;
    _messages.insert(0, (_intents[id % _intents.length], id));
  });

  void _clearMessages() => setState(_messages.clear);

  void _dismissMessage(int messageId) =>
      setState(() => _messages.removeWhere((entry) => entry.$2 == messageId));

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 10,
    children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 5,
        children: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: _addMessage,
            child: const Text('Add message'),
          ),
          FluentButton(onPressed: _clearMessages, child: const Text('Clear')),
        ],
      ),
      SizedBox(
        height: 300,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: FluentTheme.of(context).colors.brandForeground1,
              width: 2,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(FluentSpacing.mNudge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: <Widget>[
                for (final (FluentMessageBarIntent intent, int id) in _messages)
                  FluentMessageBar(
                    key: ValueKey<int>(id),
                    intent: intent,
                    title: const Text('Descriptive title'),
                    onDismiss: () => _dismissMessage(id),
                    dismissSemanticLabel: 'dismiss',
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          const TextSpan(
                            text:
                                'Message providing information to the user with actionable insights. ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: FluentLink(
                              inline: true,
                              onPressed: () {},
                              child: const Text('Link'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-messagebar--dismiss

// #docregion components-messagebar--animation
// `MessageBarGroup` has no Dart counterpart, so the group's two animations are
// approximated: "both" fades each bar in as it mounts, and neither value can
// animate a bar out, because removal from the list is immediate. Upstream's
// horizontal `Field` is a Row of a FluentLabel and the radios — FluentField
// stacks its label above the control.
Widget _animation(BuildContext context) => const _Animation();

class _Animation extends StatefulWidget {
  const _Animation();

  @override
  State<_Animation> createState() => _AnimationState();
}

class _AnimationState extends State<_Animation> {
  static const List<FluentMessageBarIntent> _intents = <FluentMessageBarIntent>[
    FluentMessageBarIntent.info,
    FluentMessageBarIntent.warning,
    FluentMessageBarIntent.error,
    FluentMessageBarIntent.success,
  ];

  final List<(FluentMessageBarIntent, int)> _messages =
      <(FluentMessageBarIntent, int)>[];
  String _animate = 'both';
  int _counter = 0;

  // Upstream picks the intent at random. Cycling keeps the demo reproducible.
  void _addMessage() => setState(() {
    final id = _counter++;
    _messages.insert(0, (_intents[id % _intents.length], id));
  });

  void _clearMessages() => setState(_messages.clear);

  void _dismissMessage(int messageId) =>
      setState(() => _messages.removeWhere((entry) => entry.$2 == messageId));

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 10,
    children: <Widget>[
      Row(
        spacing: 10,
        children: <Widget>[
          const FluentLabel(child: Text('Select animation type:')),
          Expanded(
            child: FluentRadioGroup<String>(
              layout: FluentRadioGroupLayout.horizontal,
              value: _animate,
              onChanged: (value) => setState(() => _animate = value),
              children: const <Widget>[
                FluentRadio<String>(value: 'both', label: Text('both')),
                FluentRadio<String>(
                  value: 'exit-only',
                  label: Text('exit-only'),
                ),
              ],
            ),
          ),
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: _addMessage,
            child: const Text('Add message'),
          ),
          FluentButton(onPressed: _clearMessages, child: const Text('Clear')),
        ],
      ),
      SizedBox(
        height: 300,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: FluentTheme.of(context).colors.brandForeground1,
              width: 2,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(FluentSpacing.mNudge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: <Widget>[
                for (final (FluentMessageBarIntent intent, int id) in _messages)
                  _AnimatedEntry(
                    key: ValueKey<int>(id),
                    animate: _animate == 'both',
                    child: FluentMessageBar(
                      intent: intent,
                      title: const Text('Descriptive title'),
                      onDismiss: () => _dismissMessage(id),
                      dismissSemanticLabel: 'dismiss',
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            const TextSpan(
                              text:
                                  'Message providing information to the user with actionable insights. ',
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: FluentLink(
                                inline: true,
                                onPressed: () {},
                                child: const Text('Link'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({required this.animate, required this.child, super.key});

  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) => animate
      ? TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: FluentDuration.normal,
          curve: FluentCurve.decelerateMid,
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: child,
        )
      : child;
}
// #enddocregion components-messagebar--animation

// #docregion components-messagebar--reflow
// FluentMessageBar takes its layout as a parameter and never measures itself,
// so the automatic reflow upstream gets for free is done here by a
// LayoutBuilder that switches to multiLine below upstream's 600px compact
// width.
Widget _reflow(BuildContext context) => const _Reflow();

class _Reflow extends StatefulWidget {
  const _Reflow();

  @override
  State<_Reflow> createState() => _ReflowState();
}

class _ReflowState extends State<_Reflow> {
  bool _compact = true;

  @override
  Widget build(BuildContext context) {
    final colors = FluentTheme.of(context).colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: FluentSwitch(
            checked: _compact,
            label: Text(_compact ? 'Compact width' : 'Full width'),
            onChanged: (value) => setState(() => _compact = value),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: _compact ? 600 : double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.brandBackground, width: 2),
              ),
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 10,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) => FluentMessageBar(
                        intent: FluentMessageBarIntent.success,
                        layout: constraints.maxWidth < 600
                            ? FluentMessageBarLayout.multiLine
                            : FluentMessageBarLayout.singleLine,
                        title: const Text('Descriptive title'),
                        actions: <Widget>[
                          FluentButton(
                            size: FluentButtonSize.small,
                            onPressed: () {},
                            child: const Text('Action'),
                          ),
                          FluentButton(
                            size: FluentButtonSize.small,
                            onPressed: () {},
                            child: const Text('Action'),
                          ),
                        ],
                        onDismiss: () {},
                        dismissSemanticLabel: 'dismiss',
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              const TextSpan(
                                text:
                                    'Message providing information to the user with actionable insights. ',
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: FluentLink(
                                  inline: true,
                                  onPressed: () {},
                                  child: const Text('Link'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ColoredBox(
                      color: colors.brandBackground,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 1, 4, 1),
                        child: Text(
                          'Resizable Area',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: 1,
                            color: colors.neutralForegroundOnBrand,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion components-messagebar--reflow

// #docregion components-messagebar--manual-layout
Widget _manualLayout(BuildContext context) => const _ManualLayout();

class _ManualLayout extends StatefulWidget {
  const _ManualLayout();

  @override
  State<_ManualLayout> createState() => _ManualLayoutState();
}

class _ManualLayoutState extends State<_ManualLayout> {
  static const List<FluentMessageBarIntent> _intents = <FluentMessageBarIntent>[
    FluentMessageBarIntent.info,
    FluentMessageBarIntent.warning,
    FluentMessageBarIntent.error,
    FluentMessageBarIntent.success,
  ];

  bool _single = true;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 10,
    children: <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: FluentSwitch(
          checked: _single,
          label: Text(_single ? 'Single line layout' : 'Multi line layout'),
          onChanged: (value) => setState(() => _single = value),
        ),
      ),
      for (final intent in _intents)
        FluentMessageBar(
          intent: intent,
          layout: _single
              ? FluentMessageBarLayout.singleLine
              : FluentMessageBarLayout.multiLine,
          title: const Text('Descriptive title'),
          actions: <Widget>[
            FluentButton(
              size: FluentButtonSize.small,
              onPressed: () {},
              child: const Text('Action'),
            ),
            FluentButton(
              size: FluentButtonSize.small,
              onPressed: () {},
              child: const Text('Action'),
            ),
          ],
          onDismiss: () {},
          dismissSemanticLabel: 'dismiss',
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(
                  text:
                      'Message providing information to the user with actionable insights. ',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: FluentLink(
                    inline: true,
                    onPressed: () {},
                    child: const Text('Link'),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

// #enddocregion components-messagebar--manual-layout
