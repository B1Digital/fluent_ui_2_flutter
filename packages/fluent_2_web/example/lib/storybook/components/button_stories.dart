import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// The Fluent 2 button family — [FluentButton], [FluentCompoundButton],
/// [FluentSplitButton] and [FluentMenu]/[FluentMenuItem].
List<Story> get buttonStories => [
  Story(
    name: 'Buttons/FluentButton',
    description:
        'A single action. Primary, secondary, outline, subtle and '
        'transparent appearances across sizes.',
    builder: (context) {
      final label = context.knobs.text(label: 'Label', initial: 'Button');
      final disabled = context.knobs.boolean(label: 'Disabled', initial: false);

      return DemoColumn(
        children: [
          DemoRail(
            title: 'Appearances',
            children: [
              for (final appearance in FluentButtonAppearance.values)
                FluentButton(
                  appearance: appearance,
                  onPressed: disabled ? null : () {},
                  child: Text(label),
                ),
            ],
          ),
          DemoRail(
            title: 'Sizes',
            children: [
              for (final size in FluentButtonSize.values)
                FluentButton(
                  size: size,
                  appearance: FluentButtonAppearance.primary,
                  onPressed: disabled ? null : () {},
                  child: Text(label),
                ),
            ],
          ),
          DemoRail(
            title: 'With icon',
            children: [
              FluentButton(
                appearance: FluentButtonAppearance.primary,
                onPressed: disabled ? null : () {},
                icon: const Icon(Icons.add),
                child: const Text('Add'),
              ),
              FluentButton(
                onPressed: disabled ? null : () {},
                iconPosition: FluentButtonIconPosition.after,
                icon: const Icon(Icons.chevron_right),
                child: const Text('Continue'),
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Buttons/FluentCompoundButton',
    description: 'A button with a second, explanatory line.',
    builder: (context) {
      return DemoColumn(
        children: [
          DemoRail(
            title: 'Appearances',
            children: [
              for (final appearance in FluentButtonAppearance.values)
                FluentCompoundButton(
                  appearance: appearance,
                  onPressed: () {},
                  icon: const Icon(Icons.cloud_download),
                  secondaryContent: const Text('Secondary line of text'),
                  child: const Text('Compound button'),
                ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Buttons/FluentSplitButton',
    description: 'A default action plus a menu in one container.',
    builder: (context) {
      return DemoRail(
        title: 'Variants',
        children: [
          for (final size in FluentButtonSize.values)
            FluentSplitButton(
              size: size,
              appearance: FluentButtonAppearance.secondary,
              menuSemanticLabel: 'More options',
              onPressed: () {},
              onMenuPressed: () {},
              child: const Text('Send'),
            ),
        ],
      );
    },
  ),
  Story(
    name: 'Buttons/FluentMenu',
    description: 'A menu surface anchored to a trigger, with menu items.',
    builder: (context) {
      return FluentMenu(
        semanticLabel: 'Edit',
        items: [
          FluentMenuItem(
            label: const Text('Cut'),
            icon: const Icon(Icons.content_cut),
            onPressed: () {},
          ),
          FluentMenuItem(
            label: const Text('Copy'),
            icon: const Icon(Icons.copy),
            onPressed: () {},
          ),
          FluentMenuItem(
            label: const Text('Paste'),
            icon: const Icon(Icons.content_paste),
            checked: true,
            onPressed: () {},
          ),
        ],
        builder: (context, toggle) => FluentButton(
          onPressed: toggle,
          icon: const Icon(Icons.more_horiz),
          child: const Text('Edit'),
        ),
      );
    },
  ),
];
