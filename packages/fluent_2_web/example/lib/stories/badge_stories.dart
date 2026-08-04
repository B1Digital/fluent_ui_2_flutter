import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentBadge] and [FluentPresenceBadge].
///
/// The two share a page here for the same reason they share a Figma page and a
/// test file: a presence badge is the availability dot that sits on an avatar,
/// and a reader comparing the two wants them side by side.
final StorySection badgeStories = StorySection(
  component: 'Badge',
  description:
      'A small, non-interactive marker for status, counts and metadata. It has '
      'no hover, pressed or disabled treatment — Fluent ships no such tokens '
      'for Badge — so wrap it in your own gesture surface if it has to be '
      'tappable.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every design axis at once: colour, size, appearance and an optional '
          'icon on either side of the label.',
      knobs: const [
        TextKnob(label: 'Label', id: 'label', initial: 'New'),
        OptionKnob<FluentBadgeColor>(
          label: 'Color',
          id: 'color',
          initial: FluentBadgeColor.brand,
          options: FluentBadgeColor.values,
          labelOf: _colorLabel,
        ),
        OptionKnob<FluentBadgeSize>(
          label: 'Size',
          id: 'size',
          initial: FluentBadgeSize.medium,
          options: FluentBadgeSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentBadgeAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentBadgeAppearance.filled,
          options: FluentBadgeAppearance.values,
          labelOf: _appearanceLabel,
        ),
        BoolKnob(label: 'Icon', id: 'icon'),
        OptionKnob<FluentBadgeIconPosition>(
          label: 'Icon position',
          id: 'iconPosition',
          initial: FluentBadgeIconPosition.before,
          options: FluentBadgeIconPosition.values,
          labelOf: _iconPositionLabel,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _Start(
          child: FluentBadge(
            color: knobs.get<FluentBadgeColor>('color', FluentBadgeColor.brand),
            size: knobs.get<FluentBadgeSize>('size', FluentBadgeSize.medium),
            appearance: knobs.get<FluentBadgeAppearance>(
              'appearance',
              FluentBadgeAppearance.filled,
            ),
            iconPosition: knobs.get<FluentBadgeIconPosition>(
              'iconPosition',
              FluentBadgeIconPosition.before,
            ),
            icon: knobs.get<bool>('icon', false)
                ? const Icon(FluentIcons.checkmark_12_filled)
                : null,
            child: Text(knobs.get<String>('label', 'New')),
          ),
        );
      },
    ),
    Story(
      name: 'Colors',
      description:
          'Seven semantic families. Switch the appearance knob to see that '
          'colour and appearance are independent axes: every family renders in '
          'all four treatments.',
      knobs: const [
        OptionKnob<FluentBadgeAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentBadgeAppearance.filled,
          options: FluentBadgeAppearance.values,
          labelOf: _appearanceLabel,
        ),
      ],
      builder: (context) {
        final appearance = KnobsScope.of(context).get<FluentBadgeAppearance>(
          'appearance',
          FluentBadgeAppearance.filled,
        );
        return _Cases(
          children: [
            for (final color in FluentBadgeColor.values)
              (
                _colorLabel(color),
                FluentBadge(
                  color: color,
                  appearance: appearance,
                  child: const Text('Badge'),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'Filled, tint, outline and subtle. Only filled brand carries a '
          'border — Figma binds it to the same colour as its fill, so it is '
          'invisible until high contrast makes it opaque.',
      knobs: const [
        OptionKnob<FluentBadgeColor>(
          label: 'Color',
          id: 'color',
          initial: FluentBadgeColor.brand,
          options: FluentBadgeColor.values,
          labelOf: _colorLabel,
        ),
      ],
      builder: (context) {
        final color = KnobsScope.of(
          context,
        ).get<FluentBadgeColor>('color', FluentBadgeColor.brand);
        return _Cases(
          children: [
            for (final appearance in FluentBadgeAppearance.values)
              (
                _appearanceLabel(appearance),
                FluentBadge(
                  color: color,
                  appearance: appearance,
                  child: const Text('Badge'),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Sizes',
      description:
          'Four heights — 16, 20, 24 and 32 — each with its own type ramp. Turn '
          'the icon on to see the icon ramp move with it: 12, 12, 16, 20.',
      knobs: const [BoolKnob(label: 'Icon', id: 'icon', initial: true)],
      builder: (context) {
        final icon = KnobsScope.of(context).get<bool>('icon', true);
        return _Cases(
          children: [
            for (final size in FluentBadgeSize.values)
              (
                _sizeLabel(size),
                FluentBadge(
                  size: size,
                  icon: icon
                      ? const Icon(FluentIcons.checkmark_12_filled)
                      : null,
                  child: const Text('Badge'),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Icon',
      description:
          'The icon leads the label by default and can follow it instead. With '
          'no label at all the badge is square, sized to its own height.',
      builder: _iconBuilder,
    ),
    const Story(
      name: 'Dot',
      description:
          'A badge with neither icon nor label collapses to a dot as wide as it '
          'is tall. It has nothing to announce, so give it a semantic label.',
      builder: _dotBuilder,
    ),
    const Story(
      name: 'Counts',
      description:
          'A count is just the label. The minimum width is pinned to the '
          'height, so a single digit stays round and only a longer count grows.',
      builder: _countsBuilder,
    ),
    const Story(
      name: 'Custom shape',
      description:
          'Badge has no shape axis; every variant is a 4px radius. A circular '
          'or square badge is a style override, and merging is per-property so '
          'the resolved colours survive.',
      builder: _shapeBuilder,
    ),
    Story(
      name: 'Presence status',
      description:
          'Eight availability states. Three do not use the token their name '
          'suggests: unknown, blocked and do-not-disturb all take the danger '
          'colour.',
      knobs: const [
        OptionKnob<FluentPresenceBadgeSize>(
          label: 'Size',
          id: 'size',
          initial: FluentPresenceBadgeSize.large,
          options: FluentPresenceBadgeSize.values,
          labelOf: _presenceSizeLabel,
        ),
      ],
      builder: (context) {
        final size = KnobsScope.of(
          context,
        ).get<FluentPresenceBadgeSize>('size', FluentPresenceBadgeSize.large);
        return _Cases(
          children: [
            for (final status in FluentPresenceStatus.values)
              (
                _statusLabel(status),
                FluentPresenceBadge(status: status, size: size),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Presence out of office',
      description:
          'Out of office swaps the glyph, not only its fill: away becomes the '
          'berry out-of-office glyph outright, and busy borrows the unknown '
          'glyph while keeping the danger colour.',
      builder: _outOfOfficeBuilder,
    ),
    Story(
      name: 'Presence sizes',
      description:
          'Six diameters, 6 to 28. Tiny has no glyph at all — the status colour '
          'becomes the disc — and takes a 1px ring where the rest take 2.',
      knobs: const [
        OptionKnob<FluentPresenceStatus>(
          label: 'Status',
          id: 'status',
          initial: FluentPresenceStatus.available,
          options: FluentPresenceStatus.values,
          labelOf: _statusLabel,
        ),
      ],
      builder: (context) {
        final status = KnobsScope.of(
          context,
        ).get<FluentPresenceStatus>('status', FluentPresenceStatus.available);
        return _Cases(
          children: [
            for (final size in FluentPresenceBadgeSize.values)
              (
                _presenceSizeLabel(size),
                FluentPresenceBadge(status: status, size: size),
              ),
          ],
        );
      },
    ),
  ],
);

String _colorLabel(FluentBadgeColor value) => value.name;

String _sizeLabel(FluentBadgeSize value) => value.name;

String _appearanceLabel(FluentBadgeAppearance value) => value.name;

String _iconPositionLabel(FluentBadgeIconPosition value) => value.name;

String _presenceSizeLabel(FluentPresenceBadgeSize value) => value.name;

String _statusLabel(FluentPresenceStatus value) => value.name;

Widget _iconBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Before (default)',
      FluentBadge(
        size: FluentBadgeSize.large,
        icon: Icon(FluentIcons.checkmark_16_filled),
        child: Text('Done'),
      ),
    ),
    (
      'After',
      FluentBadge(
        size: FluentBadgeSize.large,
        iconPosition: FluentBadgeIconPosition.after,
        icon: Icon(FluentIcons.checkmark_16_filled),
        child: Text('Done'),
      ),
    ),
    (
      'Icon only',
      FluentBadge(
        size: FluentBadgeSize.large,
        color: FluentBadgeColor.danger,
        icon: Icon(FluentIcons.alert_16_filled),
        semanticLabel: 'Alerts',
      ),
    ),
  ],
);

Widget _dotBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Small',
      FluentBadge(
        size: FluentBadgeSize.small,
        color: FluentBadgeColor.danger,
        semanticLabel: 'Unread',
      ),
    ),
    (
      'Medium',
      FluentBadge(color: FluentBadgeColor.danger, semanticLabel: 'Unread'),
    ),
    (
      'Large',
      FluentBadge(
        size: FluentBadgeSize.large,
        color: FluentBadgeColor.danger,
        semanticLabel: 'Unread',
      ),
    ),
    (
      'Extra large',
      FluentBadge(
        size: FluentBadgeSize.extraLarge,
        color: FluentBadgeColor.danger,
        semanticLabel: 'Unread',
      ),
    ),
  ],
);

Widget _countsBuilder(BuildContext context) => const _Cases(
  children: [
    (
      '1',
      FluentBadge(
        color: FluentBadgeColor.danger,
        semanticLabel: '1 unread',
        child: Text('1'),
      ),
    ),
    (
      '9',
      FluentBadge(
        color: FluentBadgeColor.danger,
        semanticLabel: '9 unread',
        child: Text('9'),
      ),
    ),
    (
      '99+',
      FluentBadge(
        color: FluentBadgeColor.danger,
        semanticLabel: 'More than 99 unread',
        child: Text('99+'),
      ),
    ),
    (
      'Informative',
      FluentBadge(color: FluentBadgeColor.informative, child: Text('12')),
    ),
  ],
);

Widget _shapeBuilder(BuildContext context) => _Cases(
  children: [
    ('Default (4px)', const FluentBadge(child: Text('Badge'))),
    (
      'Circular',
      FluentBadge(
        style: FluentBadgeStyle.from(borderRadius: FluentRadius.allCircular),
        child: const Text('Badge'),
      ),
    ),
    (
      'Square',
      FluentBadge(
        style: FluentBadgeStyle.from(
          borderRadius: const BorderRadius.all(FluentRadius.none),
        ),
        child: const Text('Badge'),
      ),
    ),
  ],
);

Widget _outOfOfficeBuilder(BuildContext context) => const _Cases(
  children: [
    ('Available', _OutOfOfficePair(status: FluentPresenceStatus.available)),
    ('Away', _OutOfOfficePair(status: FluentPresenceStatus.away)),
    ('Busy', _OutOfOfficePair(status: FluentPresenceStatus.busy)),
    (
      'Do not disturb',
      _OutOfOfficePair(status: FluentPresenceStatus.doNotDisturb),
    ),
  ],
);

/// One status in office and out of office, so the glyph swap is visible in the
/// same glance rather than across a knob change.
class _OutOfOfficePair extends StatelessWidget {
  const _OutOfOfficePair({required this.status});

  final FluentPresenceStatus status;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.m,
    children: [
      FluentPresenceBadge(status: status, size: FluentPresenceBadgeSize.large),
      FluentPresenceBadge(
        status: status,
        outOfOffice: true,
        size: FluentPresenceBadgeSize.large,
      ),
    ],
  );
}

/// Keeps a single example at its intrinsic width instead of letting the canvas
/// stretch it across the page.
class _Start extends StatelessWidget {
  const _Start({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: AlignmentDirectional.centerStart, child: child);
}

/// Side-by-side cases under a caption, the layout most of these stories want.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.l,
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
