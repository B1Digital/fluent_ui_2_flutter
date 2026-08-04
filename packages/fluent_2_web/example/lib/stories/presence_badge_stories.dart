import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentPresenceBadge].
final StorySection presenceBadgeStories = StorySection(
  component: 'Presence badge',
  description:
      'The availability dot that sits on an avatar: eight statuses, six '
      'diameters, and an out-of-office flag that substitutes the glyph rather '
      'than merely hollowing it. Non-interactive, and always labelled for '
      'assistive technology because the meaning is carried by colour alone.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every design axis at once — a 16px available badge out of the box, '
          'with the status, the out-of-office flag and the diameter live.',
      knobs: const [
        OptionKnob<FluentPresenceStatus>(
          label: 'Status',
          id: 'status',
          initial: FluentPresenceStatus.available,
          options: FluentPresenceStatus.values,
          labelOf: _statusLabel,
        ),
        BoolKnob(label: 'Out of office', id: 'oof'),
        OptionKnob<FluentPresenceBadgeSize>(
          label: 'Size',
          id: 'size',
          initial: FluentPresenceBadgeSize.medium,
          options: FluentPresenceBadgeSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return FluentPresenceBadge(
          status: knobs.get<FluentPresenceStatus>(
            'status',
            FluentPresenceStatus.available,
          ),
          outOfOffice: knobs.get<bool>('oof', false),
          size: knobs.get<FluentPresenceBadgeSize>(
            'size',
            FluentPresenceBadgeSize.medium,
          ),
        );
      },
    ),
    const Story(
      name: 'Statuses',
      description:
          'All eight statuses. Three take a colour their name does not suggest: '
          'busy, do-not-disturb, blocked and unknown all share the danger red, '
          'and offline is the only neutral one.',
      builder: _statusesBuilder,
    ),
    const Story(
      name: 'Out of office',
      description:
          'The flag is not a hollow variant of the same glyph — away out of '
          'office becomes the berry out-of-office glyph outright, and busy out '
          'of office borrows the unknown glyph while keeping the danger red.',
      builder: _outOfOfficeBuilder,
    ),
    Story(
      name: 'Sizes',
      description:
          'Six diameters from 6 to 28. Tiny has no glyph at all — the status '
          'colour becomes the disc itself — so switch the status to see which '
          'sizes still carry a shape.',
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
                _sizeLabel(size),
                FluentPresenceBadge(status: status, size: size),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'On an avatar',
      description:
          'What the component is for: an avatar anchors the badge in its '
          'bottom-right corner and picks the diameter from its own size, so a '
          'caller passes a status rather than a badge.',
      builder: _onAvatarBuilder,
    ),
    const Story(
      name: 'Live status',
      description:
          'A status change lands on the frame — there is no transition here, '
          'because Fluent declares none. Press to cycle a person through every '
          'availability.',
      builder: _liveBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — the status and size defaults, a '
          'FluentPresenceBadgeTheme over a subtree, then the widget style, '
          'which is merged last and wins.',
      builder: _stylingBuilder,
    ),
  ],
);

String _statusLabel(FluentPresenceStatus value) => switch (value) {
  FluentPresenceStatus.available => 'Available',
  FluentPresenceStatus.away => 'Away',
  FluentPresenceStatus.busy => 'Busy',
  FluentPresenceStatus.doNotDisturb => 'Do not disturb',
  FluentPresenceStatus.blocked => 'Blocked',
  FluentPresenceStatus.offline => 'Offline',
  FluentPresenceStatus.outOfOffice => 'Out of office',
  FluentPresenceStatus.unknown => 'Unknown',
};

String _sizeLabel(FluentPresenceBadgeSize value) => switch (value) {
  FluentPresenceBadgeSize.tiny => 'Tiny (6)',
  FluentPresenceBadgeSize.extraSmall => 'Extra small (10)',
  FluentPresenceBadgeSize.small => 'Small (12)',
  FluentPresenceBadgeSize.medium => 'Medium (16)',
  FluentPresenceBadgeSize.large => 'Large (20)',
  FluentPresenceBadgeSize.extraLarge => 'Extra large (28)',
};

Widget _statusesBuilder(BuildContext context) => _Cases(
  children: [
    for (final status in FluentPresenceStatus.values)
      (
        _statusLabel(status),
        FluentPresenceBadge(
          status: status,
          size: FluentPresenceBadgeSize.large,
        ),
      ),
  ],
);

Widget _outOfOfficeBuilder(BuildContext context) => _Cases(
  children: [
    for (final status in <FluentPresenceStatus>[
      FluentPresenceStatus.available,
      FluentPresenceStatus.away,
      FluentPresenceStatus.busy,
      FluentPresenceStatus.doNotDisturb,
    ])
      (
        _statusLabel(status),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.l,
          children: [
            FluentPresenceBadge(
              status: status,
              size: FluentPresenceBadgeSize.large,
            ),
            FluentPresenceBadge(
              status: status,
              outOfOffice: true,
              size: FluentPresenceBadgeSize.large,
            ),
          ],
        ),
      ),
  ],
);

Widget _onAvatarBuilder(BuildContext context) => const _Cases(
  children: [
    (
      '24',
      FluentAvatar(
        initials: 'AC',
        name: 'Ada Chen',
        size: FluentAvatarSize.size24,
        status: FluentPresenceStatus.available,
      ),
    ),
    (
      '40',
      FluentAvatar(
        initials: 'MB',
        name: 'Mona Baptiste',
        size: FluentAvatarSize.size40,
        status: FluentPresenceStatus.busy,
      ),
    ),
    (
      '56, out of office',
      FluentAvatar(
        initials: 'RK',
        name: 'Rafi Kaur',
        size: FluentAvatarSize.size56,
        status: FluentPresenceStatus.away,
        outOfOffice: true,
      ),
    ),
    (
      'Persona',
      FluentPersona(
        initials: 'AC',
        primary: Text('Ada Chen'),
        secondary: Text('Available'),
        size: FluentPersonaSize.large,
        status: FluentPresenceStatus.available,
      ),
    ),
    (
      'Persona, badge only',
      FluentPersona(
        primary: Text('Ada Chen'),
        secondary: Text('Available'),
        size: FluentPersonaSize.large,
        status: FluentPresenceStatus.available,
        presenceOnly: true,
      ),
    ),
  ],
);

Widget _liveBuilder(BuildContext context) => const _LiveStatus();

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentPresenceBadgeTheme(
    style: FluentPresenceBadgeStyle.from(
      diameter: 28,
      borderColor: colors.neutralBackground3,
      borderWidth: FluentStroke.thicker,
    ),
    child: _Cases(
      children: [
        (
          'Default',
          const FluentPresenceBadge(status: FluentPresenceStatus.available),
        ),
        (
          'Subtree theme',
          const FluentPresenceBadge(status: FluentPresenceStatus.available),
        ),
        (
          'Widget style wins',
          FluentPresenceBadge(
            status: FluentPresenceStatus.available,
            style: FluentPresenceBadgeStyle.from(
              foregroundColor: colors.brandForeground1,
              borderColor: colors.brandBackground,
            ),
          ),
        ),
      ],
    ),
  );
}

/// One person whose availability the reader can cycle, so the badge is watched
/// changing rather than seen in eight fixed copies.
class _LiveStatus extends StatefulWidget {
  const _LiveStatus();

  @override
  State<_LiveStatus> createState() => _LiveStatusState();
}

class _LiveStatusState extends State<_LiveStatus> {
  int _index = 0;
  bool _outOfOffice = false;

  FluentPresenceStatus get _status => FluentPresenceStatus.values[_index];

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: [
        FluentAvatar(
          initials: 'AC',
          name: 'Ada Chen',
          size: FluentAvatarSize.size48,
          status: _status,
          outOfOffice: _outOfOffice,
        ),
        Text(_statusLabel(_status), style: theme.typography.body1Strong),
        FluentButton(
          onPressed: () => setState(
            () => _index = (_index + 1) % FluentPresenceStatus.values.length,
          ),
          child: const Text('Next status'),
        ),
        FluentSwitch(
          checked: _outOfOffice,
          onChanged: (v) => setState(() => _outOfOffice = v),
          label: const Text('Out of office'),
        ),
      ],
    );
  }
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
              // The cut-out ring paints outside the badge's box, so leave it
              // room rather than letting the next case clip it.
              Padding(
                padding: const EdgeInsets.all(FluentSpacing.xs),
                child: child,
              ),
            ],
          ),
      ],
    );
  }
}
