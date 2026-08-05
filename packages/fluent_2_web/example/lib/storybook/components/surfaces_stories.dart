import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/material.dart' show Icons, Icon;
import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// Simple visual surfaces and feedback widgets.
List<Story> get surfacesStories => [
  Story(
    name: 'Surfaces/FluentAvatar',
    description: 'An identity glyph: image, initials, icon or fallback.',
    builder: (context) {
      return DemoColumn(
        children: [
          DemoRail(
            title: 'Content',
            children: const [
              FluentAvatar(name: 'Kat Larsson', initials: 'KL'),
              FluentAvatar(name: 'Miguel Garcia', initials: 'MG'),
              FluentAvatar(icon: Icon(Icons.person)),
              FluentAvatar(name: 'Anonymous'),
            ],
          ),
          DemoRail(
            title: 'Sizes',
            children: [
              for (final size in FluentAvatarSize.values)
                FluentAvatar(name: 'Size', initials: 'S', size: size),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentBadge',
    description: 'A short label communicating status or a count.',
    builder: (context) {
      return DemoColumn(
        children: [
          DemoRail(
            title: 'Colors',
            children: [
              for (final color in FluentBadgeColor.values)
                FluentBadge(color: color, child: const Text('Badge')),
            ],
          ),
          DemoRail(
            title: 'With icon',
            children: [
              FluentBadge(
                appearance: FluentBadgeAppearance.filled,
                icon: const Icon(Icons.star, size: 14),
                child: const Text('New'),
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentDivider',
    description:
        'Separates content, horizontally or vertically, with an '
        'optional label or icon.',
    builder: (context) {
      return DemoColumn(
        children: [
          const DemoRail(title: 'Standard', children: [_DividerSample()]),
          DemoRail(
            title: 'With label',
            children: const [
              SizedBox(width: 360, child: FluentDivider(child: Text('OR'))),
            ],
          ),
          DemoRail(
            title: 'Vertical',
            children: const [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Left'),
                  SizedBox(width: 12),
                  FluentDivider(vertical: true, child: Icon(Icons.bolt)),
                  SizedBox(width: 12),
                  Text('Right'),
                ],
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentSpinner',
    description: 'An indeterminate progress indicator.',
    builder: (context) {
      return DemoRail(
        title: 'Variants',
        children: [
          const FluentSpinner(label: Text('Loading…')),
          const FluentSpinner(
            appearance: FluentSpinnerAppearance.subtle,
            label: Text('Loading'),
          ),
          for (final size in FluentSpinnerSize.values)
            FluentSpinner(size: size),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentProgressBar',
    description: 'A linear progress indicator, determinate or indeterminate.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: DemoColumn(
          children: [
            DemoRail(
              title: 'Determinate',
              children: [
                FluentProgressBar(
                  value: context.knobs.slider(
                    label: 'Value',
                    initial: 0.6,
                    min: 0,
                    max: 1,
                  ),
                ),
              ],
            ),
            const DemoRail(
              title: 'Indeterminate',
              children: [FluentProgressBar()],
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentAccordion',
    description: 'Collapsible sections that expand to reveal content.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: FluentAccordion(
          multiple: true,
          defaultOpenItems: const {'1'},
          children: const [
            FluentAccordionItem(
              value: '1',
              header: Text('General'),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Your general account settings.'),
              ),
            ),
            FluentAccordionItem(
              value: '2',
              header: Text('Privacy'),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Control what others can see.'),
              ),
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentAvatarGroup',
    description: 'A set of avatars, spread or stacked.',
    builder: (context) {
      return DemoRail(
        title: 'Layouts',
        children: [
          FluentAvatarGroup(
            children: const [
              FluentAvatar(name: 'A', initials: 'AL'),
              FluentAvatar(name: 'B', initials: 'BT'),
              FluentAvatar(name: 'C', initials: 'GH'),
            ],
          ),
          FluentAvatarGroup(
            layout: FluentAvatarGroupLayout.stack,
            children: const [
              FluentAvatar(name: 'D', initials: 'DW'),
              FluentAvatar(name: 'E', initials: 'ER'),
              FluentAvatar(name: 'F', initials: 'FP'),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentCard',
    description: 'A flexible content container with optional press behavior.',
    builder: (context) {
      return DemoRail(
        title: 'Cards',
        children: [
          const FluentCard(
            header: Text('Card title'),
            preview: SizedBox(height: 120, width: 240),
            footer: Text('Footer'),
            child: Text('Body content goes here.'),
          ),
          FluentCard(
            selected: true,
            onPressed: () {},
            header: const Text('Selectable card'),
            child: const Text('Try selecting via hover.'),
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentCarousel',
    description: 'A rotating set of slides with navigation controls.',
    builder: (context) {
      return FluentCarousel(
        header: const Text('Featured'),
        slides: [
          for (var i = 1; i <= 3; i++)
            Container(
              height: 160,
              alignment: Alignment.center,
              color: FluentTheme.of(context).colors.brandBackground2,
              child: Text(
                'Slide $i',
                style: FluentTheme.of(context).typography.title1,
              ),
            ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentMessageBar',
    description: 'A banner that communicates a brief message.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DemoColumn(
          children: [
            for (final intent in FluentMessageBarIntent.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FluentMessageBar(
                  intent: intent,
                  actions: [
                    FluentButton(
                      appearance: FluentButtonAppearance.primary,
                      onPressed: () {},
                      child: const Text('Action'),
                    ),
                  ],
                  title: const Text('Message title'),
                  child: const Text('This is the message body.'),
                ),
              ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentPersona',
    description: 'An avatar plus identifying text.',
    builder: (context) {
      return DemoRail(
        title: 'Personas',
        children: const [
          FluentPersona(
            name: 'Kat Larsson',
            secondary: Text('Software Engineer'),
            tertiary: Text('Contoso'),
          ),
          FluentPersona(
            name: 'Miguel Garcia',
            secondary: Text('Designer'),
            initials: 'MG',
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentSkeleton',
    description: 'A placeholder shown while content loads.',
    builder: (context) {
      return DemoRail(
        title: 'Shapes',
        children: const [
          FluentSkeleton(width: 200, height: 16),
          FluentSkeleton(
            shape: FluentSkeletonShape.circle,
            width: 48,
            height: 48,
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentTag',
    description: 'A label for classifying or filtering content.',
    builder: (context) {
      return DemoRail(
        title: 'Variants',
        children: [
          for (final appearance in FluentTagAppearance.values)
            FluentTag(
              appearance: appearance,
              onDismiss: () {},
              icon: const Icon(Icons.tag),
              child: const Text('Tag'),
            ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentInteractionTag',
    description: 'A tag that behaves like a button.',
    builder: (context) {
      return DemoRail(
        title: 'Variants',
        children: [
          FluentInteractionTag(onPressed: () {}, child: const Text('Select')),
          FluentInteractionTag(
            selected: true,
            onPressed: () {},
            child: const Text('Selected'),
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentPresenceBadge',
    description: 'Shows a person’s availability.',
    builder: (context) {
      return DemoRail(
        title: 'Statuses',
        children: [
          for (final status in FluentPresenceStatus.values)
            FluentPresenceBadge(status: status),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentStatusIndicator',
    description: 'A labeled status with an icon and intent color.',
    builder: (context) {
      return DemoColumn(
        children: [
          DemoRail(
            title: 'Statuses',
            children: [
              FluentStatusIndicator(
                message: FluentStatusIndicatorMessage.success,
                icon: const Icon(Icons.check_circle),
                label: const Text('Success'),
              ),
              FluentStatusIndicator(
                message: FluentStatusIndicatorMessage.failed,
                icon: const Icon(Icons.cancel),
                label: const Text('Failed'),
              ),
              FluentStatusIndicator(
                message: FluentStatusIndicatorMessage.inProgress,
                icon: const Icon(Icons.sync),
                label: const Text('In progress'),
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Surfaces/FluentAcrylicSurface',
    description: 'A frosted-glass material surface.',
    builder: (context) {
      return SizedBox(
        width: 280,
        height: 160,
        child: FluentAcrylicSurface(
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Acrylic surface'),
          ),
        ),
      );
    },
  ),
];

class _DividerSample extends StatelessWidget {
  const _DividerSample();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 360, child: FluentDivider());
  }
}
