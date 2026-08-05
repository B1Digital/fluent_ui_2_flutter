import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/material.dart' show Icons, Icon;
import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// Overlay and feedback components — dialog, popover, tooltip.
List<Story> get overlaysStories => [
  Story(
    name: 'Overlays/FluentDialog',
    description: 'A modal surface for focused, blocking interactions.',
    builder: (context) {
      final open = context.knobs.boolean(label: 'Open', initial: false);
      return FluentDialog(
        open: open,
        onOpenChange: (value) {},
        title: const Text('Order lunch'),
        content: const Text(
          'You should eat more vegetables. '
          'Have you had a salad today?',
        ),
        actions: [
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () {},
            child: const Text('Order'),
          ),
          FluentButton(onPressed: () {}, child: const Text('Cancel')),
        ],
        child: const Center(
          child: SizedBox(
            width: 120,
            child: FluentButton(
              onPressed: null,
              child: Text('Open the dialog via the knob'),
            ),
          ),
        ),
      );
    },
  ),
  Story(
    name: 'Overlays/FluentPopover',
    description: 'Non-modal content anchored to a trigger.',
    builder: (context) {
      final open = context.knobs.boolean(label: 'Open', initial: true);
      return FluentPopover(
        open: open,
        onOpenChanged: (value) {},
        content: const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Popover content goes here.'),
        ),
        child: const FluentButton(child: Text('Toggle popover with the knob')),
      );
    },
  ),
  Story(
    name: 'Overlays/FluentTooltip',
    description: 'A short hint shown on hover or focus.',
    builder: (context) {
      return DemoColumn(
        children: [
          DemoRail(
            title: 'Position',
            children: [
              for (final position in FluentTooltipPosition.values)
                FluentTooltip(
                  position: position,
                  content: Text(position.name),
                  child: FluentButton(
                    onPressed: () {},
                    child: Text(position.name),
                  ),
                ),
            ],
          ),
          DemoRail(
            title: 'With arrow',
            children: [
              FluentTooltip(
                withArrow: true,
                content: const Text('I have an arrow'),
                child: const FluentButton(
                  onPressed: null,
                  child: Text('Hover me'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Overlays/FluentMenu',
    description: 'A menu surfaced from a trigger with items and submenus.',
    builder: (context) {
      return FluentMenu(
        semanticLabel: 'Actions',
        items: [
          FluentMenuItem(
            label: const Text('New'),
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
          FluentMenuItem(
            label: const Text('Rename'),
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
          FluentMenuItem(
            label: const Text('Share'),
            icon: const Icon(Icons.share),
            submenu: [
              FluentMenuItem(label: const Text('Email'), onPressed: () {}),
              FluentMenuItem(label: const Text('Copy link'), onPressed: () {}),
            ],
          ),
        ],
        builder: (context, toggle) =>
            FluentButton(onPressed: toggle, child: const Text('Actions')),
      );
    },
  ),
  Story(
    name: 'Overlays/FluentDrawer',
    description: 'A slide-in panel for navigation or secondary content.',
    builder: (context) {
      final open = context.knobs.boolean(label: 'Open', initial: false);
      return FluentDrawer(
        open: open,
        onDismiss: () {},
        header: const [Text('Drawer title')],
        footer: const [
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: null,
            child: Text('Done'),
          ),
        ],
        child: const Center(child: Text('Toggle the drawer with the knob')),
      );
    },
  ),
  Story(
    name: 'Overlays/FluentTeachingPopover',
    description: 'A guided, action-oriented popover used in onboarding.',
    builder: (context) {
      final open = context.knobs.boolean(label: 'Open', initial: true);
      return FluentTeachingPopover(
        open: open,
        onOpenChanged: (value) {},
        title: const Text('Learn to use the app'),
        body: const Text('Here is how to get the most out of this feature.'),
        primaryAction: const FluentButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: null,
          child: Text('Next'),
        ),
        secondaryAction: const FluentButton(
          onPressed: null,
          child: Text('Skip'),
        ),
        child: const FluentButton(
          child: Text('Toggle teaching popover with the knob'),
        ),
      );
    },
  ),
  Story(
    name: 'Overlays/FluentToaster',
    description: 'A stack of transient toast notifications over content.',
    builder: (context) {
      return _ToasterStory();
    },
  ),
];

class _ToasterStory extends StatefulWidget {
  @override
  State<_ToasterStory> createState() => _ToasterStoryState();
}

class _ToasterStoryState extends State<_ToasterStory> {
  final _controller = FluentToastController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show(String message) {
    _controller.show(
      (context, id) => FluentToast(
        intent: FluentToastIntent.success,
        title: Text(message),
        onDismiss: () => _controller.dismiss(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FluentToaster(
      controller: _controller,
      child: FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => _show('Message sent'),
        child: const Text('Show a toast'),
      ),
    );
  }
}
