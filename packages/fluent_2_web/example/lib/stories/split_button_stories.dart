import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for `FluentSplitButton`.
final StorySection splitButtonStories = StorySection(
  component: 'Split button',
  description:
      'A default action and a menu in one container: two separate hit targets, '
      'two callbacks, two disabled states, sharing one rounded surface with a '
      'rule between them.',
  stories: <Story>[
    Story(
      name: 'Default',
      description:
          'Both halves live, with every design axis on a knob. Hover one half '
          'and the other stays at rest — they are separate controls.',
      knobs: <Knob<Object?>>[
        const OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
        const OptionKnob<FluentButtonSize>(
          label: 'Size',
          id: 'size',
          initial: FluentButtonSize.medium,
          options: FluentButtonSize.values,
          labelOf: _sizeLabel,
        ),
        const OptionKnob<FluentButtonShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentButtonShape.rounded,
          options: FluentButtonShape.values,
          labelOf: _shapeLabel,
        ),
        const BoolKnob(label: 'Icon', id: 'icon'),
        const BoolKnob(label: 'Action disabled', id: 'disabled'),
        const BoolKnob(label: 'Menu disabled', id: 'menuDisabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return FluentSplitButton(
          appearance: knobs.get<FluentButtonAppearance>(
            'appearance',
            FluentButtonAppearance.secondary,
          ),
          size: knobs.get<FluentButtonSize>('size', FluentButtonSize.medium),
          shape: knobs.get<FluentButtonShape>(
            'shape',
            FluentButtonShape.rounded,
          ),
          icon: knobs.get<bool>('icon', false)
              ? const Icon(FluentIcons.send_20_regular)
              : null,
          menuSemanticLabel: 'More send options',
          onPressed: knobs.get<bool>('disabled', false) ? null : () {},
          onMenuPressed: knobs.get<bool>('menuDisabled', false) ? null : () {},
          child: const Text('Send'),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'The five fills, verbatim from the button. Subtle and transparent '
          'carry no rule between the halves — Figma paints no stroke there.',
      builder: (context) => Wrap(
        spacing: FluentSpacing.xxl,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          for (final appearance in FluentButtonAppearance.values)
            _Labelled(
              label: _appearanceLabel(appearance),
              child: FluentSplitButton(
                appearance: appearance,
                menuSemanticLabel: 'More send options',
                onPressed: () {},
                onMenuPressed: () {},
                child: const Text('Send'),
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Sizes',
      description:
          'Small, medium and large move the height and the type ramp of the '
          'action half; the chevron half stays 24 wide at every size.',
      knobs: <Knob<Object?>>[
        const OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
      ],
      builder: (context) {
        final appearance = KnobsScope.of(context).get<FluentButtonAppearance>(
          'appearance',
          FluentButtonAppearance.secondary,
        );
        return Wrap(
          spacing: FluentSpacing.xxl,
          runSpacing: FluentSpacing.l,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final size in FluentButtonSize.values)
              _Labelled(
                label: _sizeLabel(size),
                child: FluentSplitButton(
                  size: size,
                  appearance: appearance,
                  menuSemanticLabel: 'More send options',
                  onPressed: () {},
                  onMenuPressed: () {},
                  child: const Text('Send'),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Shapes',
      description:
          'The corner treatment applies to the pair’s outer corners only — '
          'the two inner corners stay square so the halves read as one box.',
      builder: (context) => Wrap(
        spacing: FluentSpacing.xxl,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          for (final shape in FluentButtonShape.values)
            _Labelled(
              label: _shapeLabel(shape),
              child: FluentSplitButton(
                shape: shape,
                menuSemanticLabel: 'More send options',
                onPressed: () {},
                onMenuPressed: () {},
                child: const Text('Send'),
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'With an icon',
      description:
          'The action half takes an icon on either side of its label. The '
          'chevron half is unaffected — it always trails.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.xxl,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _Labelled(
            label: 'Before',
            child: FluentSplitButton(
              icon: Icon(FluentIcons.send_20_regular),
              menuSemanticLabel: 'More send options',
              onPressed: _noop,
              onMenuPressed: _noop,
              child: Text('Send'),
            ),
          ),
          _Labelled(
            label: 'After',
            child: FluentSplitButton(
              icon: Icon(FluentIcons.arrow_download_20_regular),
              iconPosition: FluentButtonIconPosition.after,
              menuSemanticLabel: 'More download options',
              onPressed: _noop,
              onMenuPressed: _noop,
              child: Text('Download'),
            ),
          ),
        ],
      ),
    ),
    Story(
      name: 'Disabled',
      description:
          'Disabling is per half: an unavailable default action can still leave '
          'the menu reachable. A disabled half refuses focus and fires nothing.',
      knobs: <Knob<Object?>>[
        const OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
      ],
      builder: (context) {
        final appearance = KnobsScope.of(context).get<FluentButtonAppearance>(
          'appearance',
          FluentButtonAppearance.secondary,
        );
        return Wrap(
          spacing: FluentSpacing.xxl,
          runSpacing: FluentSpacing.l,
          children: <Widget>[
            _Labelled(
              label: 'Action only',
              child: FluentSplitButton(
                appearance: appearance,
                menuSemanticLabel: 'More send options',
                onMenuPressed: () {},
                child: const Text('Send'),
              ),
            ),
            _Labelled(
              label: 'Menu only',
              child: FluentSplitButton(
                appearance: appearance,
                menuSemanticLabel: 'More send options',
                onPressed: () {},
                child: const Text('Send'),
              ),
            ),
            _Labelled(
              label: 'Both',
              child: FluentSplitButton(
                appearance: appearance,
                menuSemanticLabel: 'More send options',
                child: const Text('Send'),
              ),
            ),
          ],
        );
      },
    ),
    Story(
      name: 'Opens a menu',
      description:
          'What the chevron is for: the action half runs the default command, '
          'the chevron half opens the menu of the others.',
      builder: (context) => const _SplitButtonMenuDemo(),
    ),
    Story(
      name: 'Long label',
      description:
          'The action half grows and wraps with its label while the chevron '
          'half holds its 24, so the target never shrinks under the text.',
      builder: (context) => const SizedBox(
        width: 260,
        child: FluentSplitButton(
          icon: Icon(FluentIcons.mail_20_regular),
          menuSemanticLabel: 'More reply options',
          onPressed: _noop,
          onMenuPressed: _noop,
          child: Text('Reply to everyone on this thread'),
        ),
      ),
    ),
    Story(
      name: 'Custom chevron',
      description:
          'The chevron is a widget like any other: swap it for the affordance '
          'the menu actually offers.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.xxl,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _Labelled(
            label: 'Default',
            child: FluentSplitButton(
              menuSemanticLabel: 'More save options',
              onPressed: _noop,
              onMenuPressed: _noop,
              child: Text('Save'),
            ),
          ),
          _Labelled(
            label: 'Overflow',
            child: FluentSplitButton(
              menuIcon: Icon(FluentIcons.more_horizontal_20_regular),
              menuSemanticLabel: 'More save options',
              onPressed: _noop,
              onMenuPressed: _noop,
              child: Text('Save'),
            ),
          ),
        ],
      ),
    ),
    Story(
      name: 'Menu button',
      description:
          'A menu button is not a component of its own: it is a button wearing '
          'the same shared chevron, with one hit target rather than two.',
      knobs: <Knob<Object?>>[
        const OptionKnob<FluentButtonSize>(
          label: 'Size',
          id: 'size',
          initial: FluentButtonSize.medium,
          options: FluentButtonSize.values,
          labelOf: _sizeLabel,
        ),
        const OptionKnob<FluentButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentButtonAppearance.secondary,
          options: FluentButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return FluentMenu(
          items: _shareItems,
          builder: (context, toggle) => FluentButton(
            size: knobs.get<FluentButtonSize>('size', FluentButtonSize.medium),
            appearance: knobs.get<FluentButtonAppearance>(
              'appearance',
              FluentButtonAppearance.secondary,
            ),
            icon: fluentMenuChevron,
            iconPosition: FluentButtonIconPosition.after,
            onPressed: toggle,
            child: const Text('Share'),
          ),
        );
      },
    ),
    Story(
      name: 'Styling',
      description:
          'The rule between the halves is the one thing a split button adds to '
          'a button, and it is overridable — here from the brand stroke token.',
      builder: (context) {
        final colors = FluentTheme.of(context).colors;
        return Wrap(
          spacing: FluentSpacing.xxl,
          runSpacing: FluentSpacing.l,
          children: <Widget>[
            _Labelled(
              label: 'Per widget',
              child: FluentSplitButton(
                style: FluentSplitButtonStyle.from(
                  dividerColor: colors.brandStroke1,
                ),
                menuSemanticLabel: 'More send options',
                onPressed: () {},
                onMenuPressed: () {},
                child: const Text('Send'),
              ),
            ),
            _Labelled(
              label: 'Per subtree',
              child: FluentSplitButtonTheme(
                style: FluentSplitButtonStyle.from(
                  dividerColor: colors.brandStroke1,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: FluentSpacing.m,
                  children: <Widget>[
                    FluentSplitButton(
                      menuSemanticLabel: 'More send options',
                      onPressed: () {},
                      onMenuPressed: () {},
                      child: const Text('Send'),
                    ),
                    FluentSplitButton(
                      menuSemanticLabel: 'More save options',
                      onPressed: () {},
                      onMenuPressed: () {},
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  ],
);

/// A callback that does nothing, so the axis stories can stay `const`.
///
/// The alternative is a closure per button, which makes every one of them a
/// non-const rebuild for a story that never reacts to a press.
void _noop() {}

String _appearanceLabel(FluentButtonAppearance value) => switch (value) {
  FluentButtonAppearance.secondary => 'Secondary',
  FluentButtonAppearance.primary => 'Primary',
  FluentButtonAppearance.outline => 'Outline',
  FluentButtonAppearance.subtle => 'Subtle',
  FluentButtonAppearance.transparent => 'Transparent',
};

String _sizeLabel(FluentButtonSize value) => switch (value) {
  FluentButtonSize.small => 'Small',
  FluentButtonSize.medium => 'Medium',
  FluentButtonSize.large => 'Large',
};

String _shapeLabel(FluentButtonShape value) => switch (value) {
  FluentButtonShape.rounded => 'Rounded',
  FluentButtonShape.circular => 'Circular',
  FluentButtonShape.square => 'Square',
};

/// The rows both menu stories hang off.
const List<FluentMenuItem> _shareItems = <FluentMenuItem>[
  FluentMenuItem(
    icon: Icon(FluentIcons.mail_20_regular),
    label: Text('Share by email'),
    onPressed: _noop,
  ),
  FluentMenuItem(
    icon: Icon(FluentIcons.link_20_regular),
    label: Text('Copy link'),
    onPressed: _noop,
  ),
  FluentMenuItem.divider(),
  FluentMenuItem(
    icon: Icon(FluentIcons.people_20_regular),
    label: Text('Manage access'),
    onPressed: _noop,
  ),
];

/// One example under a caption, for the stories that show a whole axis at once.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.s,
    children: <Widget>[
      FluentLabel(size: FluentLabelSize.small, child: Text(label)),
      child,
    ],
  );
}

/// A split button whose chevron opens a real menu, and whose action half runs
/// the default command directly.
class _SplitButtonMenuDemo extends StatefulWidget {
  const _SplitButtonMenuDemo();

  @override
  State<_SplitButtonMenuDemo> createState() => _SplitButtonMenuDemoState();
}

class _SplitButtonMenuDemoState extends State<_SplitButtonMenuDemo> {
  String? _last;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: <Widget>[
        FluentMenu(
          semanticLabel: 'Send options',
          items: <FluentMenuItem>[
            FluentMenuItem(
              icon: const Icon(FluentIcons.calendar_20_regular),
              label: const Text('Send later'),
              onPressed: () => _record('Send later'),
            ),
            FluentMenuItem(
              icon: const Icon(FluentIcons.arrow_reply_all_20_regular),
              label: const Text('Send and archive'),
              onPressed: () => _record('Send and archive'),
            ),
            const FluentMenuItem.divider(),
            FluentMenuItem(
              icon: const Icon(FluentIcons.edit_20_regular),
              label: const Text('Save as draft'),
              onPressed: () => _record('Save as draft'),
            ),
          ],
          builder: (context, toggle) => FluentSplitButton(
            appearance: FluentButtonAppearance.primary,
            icon: const Icon(FluentIcons.send_20_regular),
            menuSemanticLabel: 'More send options',
            onPressed: () => _record('Send'),
            onMenuPressed: toggle,
            child: const Text('Send'),
          ),
        ),
        Text(
          _last == null ? 'Nothing run yet' : 'Ran: $_last',
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground2,
          ),
        ),
      ],
    );
  }

  void _record(String action) => setState(() => _last = action);
}
