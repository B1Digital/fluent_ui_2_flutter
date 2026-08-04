import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentTooltip].
final StorySection tooltipStories = StorySection(
  component: 'Tooltip',
  description:
      'A short explanation attached to a control, shown on pointer hover and '
      'on keyboard-visible focus. It carries no interaction of its own: the '
      'surface ignores the pointer, appears on the frame the trigger changes, '
      'and never animates.',
  stories: [
    const Story(
      name: 'Default',
      description:
          'Every axis at once. Hover the trigger, or Tab to it — pointer focus '
          'deliberately does not raise a tooltip, exactly as it does not raise '
          'a focus ring.',
      knobs: [
        TextKnob(label: 'Content', id: 'content', initial: _shortText),
        OptionKnob<FluentTooltipAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentTooltipAppearance.normal,
          options: FluentTooltipAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentTooltipPosition>(
          label: 'Position',
          id: 'position',
          initial: FluentTooltipPosition.above,
          options: FluentTooltipPosition.values,
          labelOf: _positionLabel,
        ),
        BoolKnob(label: 'With arrow', id: 'arrow'),
        BoolKnob(label: 'Enabled', id: 'enabled', initial: true),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Appearances',
      description:
          'Normal sits on the ambient surface, brand carries a promotional or '
          'onboarding message, and inverted flips the neutral fill — dark on a '
          'light theme, light on a dark one.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'Positions',
      description:
          'Four sides, named in reading order: before and after follow the '
          'text direction, so they swap when the RTL toggle is on.',
      builder: _positionsBuilder,
    ),
    const Story(
      name: 'With arrow',
      description:
          'The arrow is opt-in and takes the surface fill. It also replaces '
          'the gap: without one the surface is held 4px off the trigger, with '
          'one the arrow occupies that space instead.',
      builder: _withArrowBuilder,
    ),
    const Story(
      name: 'On an icon button',
      description:
          'The case the component exists for: an icon-only button whose name '
          'appears nowhere on screen. The tooltip supplies it visually and the '
          'semantic label supplies it to a screen reader.',
      builder: _iconButtonBuilder,
    ),
    const Story(
      name: 'Long content',
      description:
          'The surface hugs short content and wraps at 240 logical pixels. '
          'Type into the knob to watch it grow to that ceiling and stop.',
      knobs: [TextKnob(label: 'Content', id: 'content', initial: _longText)],
      builder: _longContentBuilder,
    ),
    const Story(
      name: 'Escaping a clip',
      description:
          'The surface is rendered in the app Overlay and anchored to the '
          'trigger, so it escapes an ancestor that clips or scrolls instead of '
          'being cut off by it.',
      builder: _clippedBuilder,
    ),
    const Story(
      name: 'Availability',
      description:
          'Enabled is a real state, not a greyed-out one: a disabled tooltip '
          'never reaches the overlay, and one already showing is torn down the '
          'moment it is switched off.',
      builder: _availabilityBuilder,
    ),
    const Story(
      name: 'Custom style',
      description:
          'Three rungs of customisation: the appearance defaults, a '
          'FluentTooltipTheme over a subtree, and the widget style, which is '
          'merged last and wins. Overrides are per property — restyling the '
          'radius keeps every resolved colour.',
      builder: _styledBuilder,
    ),
  ],
);

const String _shortText = 'Saves the document';

const String _longText =
    'Content wider than 240 logical pixels wraps onto the next line. The '
    'surface hugs anything narrower than that.';

String _appearanceLabel(FluentTooltipAppearance value) => value.name;

String _positionLabel(FluentTooltipPosition value) => value.name;

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final content = knobs.get<String>('content', _shortText);
  return FluentTooltip(
    appearance: knobs.get<FluentTooltipAppearance>(
      'appearance',
      FluentTooltipAppearance.normal,
    ),
    position: knobs.get<FluentTooltipPosition>(
      'position',
      FluentTooltipPosition.above,
    ),
    withArrow: knobs.get<bool>('arrow', false),
    enabled: knobs.get<bool>('enabled', true),
    semanticLabel: content,
    content: Text(content),
    child: FluentButton(onPressed: () {}, child: const Text('Save')),
  );
}

Widget _appearancesBuilder(BuildContext context) => _Cases(
  children: [
    for (final appearance in FluentTooltipAppearance.values)
      (
        appearance.name,
        FluentTooltip(
          appearance: appearance,
          withArrow: true,
          semanticLabel: _shortText,
          content: const Text(_shortText),
          child: FluentButton(
            onPressed: () {},
            child: Text('Hover ${appearance.name}'),
          ),
        ),
      ),
  ],
);

Widget _positionsBuilder(BuildContext context) => _Cases(
  children: [
    for (final position in FluentTooltipPosition.values)
      (
        position.name,
        FluentTooltip(
          position: position,
          withArrow: true,
          semanticLabel: _shortText,
          content: const Text(_shortText),
          child: FluentButton(
            onPressed: () {},
            child: Text('Hover ${position.name}'),
          ),
        ),
      ),
  ],
);

Widget _withArrowBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Without arrow',
      FluentTooltip(
        semanticLabel: _shortText,
        content: const Text(_shortText),
        child: FluentButton(onPressed: () {}, child: const Text('Hover me')),
      ),
    ),
    (
      'With arrow',
      FluentTooltip(
        withArrow: true,
        semanticLabel: _shortText,
        content: const Text(_shortText),
        child: FluentButton(onPressed: () {}, child: const Text('Hover me')),
      ),
    ),
  ],
);

Widget _iconButtonBuilder(BuildContext context) => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: FluentSpacing.s,
  children: [
    for (final (icon, name) in const <(IconData, String)>[
      (FluentIcons.save_20_regular, 'Save'),
      (FluentIcons.share_20_regular, 'Share'),
      (FluentIcons.delete_20_regular, 'Delete'),
    ])
      FluentTooltip(
        withArrow: true,
        semanticLabel: name,
        content: Text(name),
        child: FluentButton.icon(
          icon: Icon(icon),
          semanticLabel: name,
          appearance: FluentButtonAppearance.subtle,
          onPressed: () {},
        ),
      ),
  ],
);

Widget _longContentBuilder(BuildContext context) {
  final content = KnobsScope.of(context).get<String>('content', _longText);
  return FluentTooltip(
    withArrow: true,
    semanticLabel: content,
    content: Text(content),
    child: FluentButton(
      onPressed: () {},
      child: const Text('Hover for the long version'),
    ),
  );
}

Widget _clippedBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return SizedBox(
    width: 260,
    height: 96,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.neutralBackground3,
        borderRadius: FluentRadius.allMedium,
        border: Border.all(color: theme.colors.neutralStroke2),
      ),
      child: ClipRRect(
        borderRadius: FluentRadius.allMedium,
        child: ListView(
          padding: const EdgeInsets.all(FluentSpacing.m),
          children: [
            for (var i = 1; i <= 6; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: FluentSpacing.xs),
                child: FluentTooltip(
                  position: FluentTooltipPosition.after,
                  withArrow: true,
                  semanticLabel: 'Row $i of the clipped list',
                  content: Text('Row $i of the clipped list'),
                  child: FluentButton(
                    appearance: FluentButtonAppearance.subtle,
                    size: FluentButtonSize.small,
                    onPressed: () {},
                    child: Text('Row $i'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _availabilityBuilder(BuildContext context) => const _Availability();

Widget _styledBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return _Cases(
    children: [
      (
        'Defaults',
        FluentTooltip(
          withArrow: true,
          semanticLabel: _shortText,
          content: const Text(_shortText),
          child: FluentButton(onPressed: () {}, child: const Text('Hover me')),
        ),
      ),
      (
        'Subtree theme',
        FluentTooltipTheme(
          style: FluentTooltipStyle.from(
            backgroundColor: theme.colors.brandBackground2,
            foregroundColor: theme.colors.brandForeground2,
            borderColor: theme.colors.brandStroke2,
          ),
          child: FluentTooltip(
            withArrow: true,
            semanticLabel: _shortText,
            content: const Text(_shortText),
            child: FluentButton(
              onPressed: () {},
              child: const Text('Hover me'),
            ),
          ),
        ),
      ),
      (
        'Widget style',
        FluentTooltip(
          appearance: FluentTooltipAppearance.inverted,
          style: FluentTooltipStyle.from(
            borderRadius: FluentRadius.allCircular,
            padding: const EdgeInsets.symmetric(
              horizontal: FluentSpacing.l,
              vertical: FluentSpacing.s,
            ),
            textStyle: theme.typography.caption1Strong,
          ),
          semanticLabel: _shortText,
          content: const Text(_shortText),
          child: FluentButton(onPressed: () {}, child: const Text('Hover me')),
        ),
      ),
    ],
  );
}

/// A tooltip whose availability is switched live.
///
/// Stateful because the point of the story is the transition: hover the
/// trigger, then switch the tooltip off without moving the pointer and watch
/// the surface leave the overlay.
class _Availability extends StatefulWidget {
  const _Availability();

  @override
  State<_Availability> createState() => _AvailabilityState();
}

class _AvailabilityState extends State<_Availability> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: [
      FluentTooltip(
        enabled: _enabled,
        withArrow: true,
        semanticLabel: _shortText,
        content: const Text(_shortText),
        child: FluentButton(onPressed: () {}, child: const Text('Save')),
      ),
      FluentSwitch(
        checked: _enabled,
        onChanged: (value) => setState(() => _enabled = value),
        label: const Text('Tooltip enabled'),
      ),
    ],
  );
}

/// Side-by-side cases under a caption.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.xxl,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final (caption, child) in children)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
