import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentStatusIndicator].
///
/// The component has no React counterpart — it exists only in the Figma
/// `.StatusIndicator` set — so the stories are derived from its three design
/// axes: `Message` (16 values), `Size` (3) and `Category` (5). Message and
/// category are not independent: the set's 48 variants are 16 messages times 3
/// sizes, so every message ships under exactly one category unless the caller
/// overrides it.
final StorySection statusIndicatorStories = StorySection(
  component: 'Status indicator',
  description:
      'A tinted glyph and a label reporting the state of something. It is '
      'non-interactive by design — the Figma set has no State axis, so there '
      'is no hover, pressed, focused or disabled rendering to show. The glyph '
      'is always supplied by the caller: Fluent’s icon set is not part of '
      'this package, and the component only tints and sizes what it is given.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis at once. The message picks both the glyph and, through '
          'its paired category, the tint; the label is optional.',
      knobs: [
        OptionKnob<FluentStatusIndicatorMessage>(
          label: 'Message',
          id: 'message',
          initial: FluentStatusIndicatorMessage.success,
          options: FluentStatusIndicatorMessage.values,
          labelOf: _messageLabel,
        ),
        const OptionKnob<FluentStatusIndicatorSize>(
          label: 'Size',
          id: 'size',
          initial: FluentStatusIndicatorSize.medium,
          options: FluentStatusIndicatorSize.values,
          labelOf: _sizeLabel,
        ),
        const BoolKnob(label: 'Label', id: 'label', initial: true),
        const TextKnob(label: 'Label text', id: 'text', initial: 'Success'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final message = knobs.get<FluentStatusIndicatorMessage>(
          'message',
          FluentStatusIndicatorMessage.success,
        );
        final labelled = knobs.get<bool>('label', true);
        final text = knobs.get<String>('text', 'Success');
        return _Start(
          child: FluentStatusIndicator(
            message: message,
            size: knobs.get<FluentStatusIndicatorSize>(
              'size',
              FluentStatusIndicatorSize.medium,
            ),
            icon: Icon(_glyph(message)),
            label: labelled ? Text(text) : null,
            semanticLabel: labelled ? null : _messageLabel(message),
          ),
        );
      },
    ),
    Story(
      name: 'Messages',
      description:
          'All sixteen statuses with the glyph Figma pairs each one with. Note '
          'the tints: only success, error and warning come from the status '
          'token layer.',
      knobs: const [
        OptionKnob<FluentStatusIndicatorSize>(
          label: 'Size',
          id: 'size',
          initial: FluentStatusIndicatorSize.medium,
          options: FluentStatusIndicatorSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) {
        final size = KnobsScope.of(context).get<FluentStatusIndicatorSize>(
          'size',
          FluentStatusIndicatorSize.medium,
        );
        return _Cases(
          children: [
            for (final message in FluentStatusIndicatorMessage.values)
              (
                _categoryLabel(message.category),
                FluentStatusIndicator(
                  message: message,
                  size: size,
                  icon: Icon(_glyph(message)),
                  label: Text(_messageLabel(message)),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Sizes',
      description:
          'Three ramps in step: a 12, 16 or 20 glyph in a 16, 20 or 24 line '
          'box, with caption, body and larger body type beside it.',
      knobs: [
        OptionKnob<FluentStatusIndicatorMessage>(
          label: 'Message',
          id: 'message',
          initial: FluentStatusIndicatorMessage.syncing,
          options: FluentStatusIndicatorMessage.values,
          labelOf: _messageLabel,
        ),
      ],
      builder: (context) {
        final message = KnobsScope.of(context)
            .get<FluentStatusIndicatorMessage>(
              'message',
              FluentStatusIndicatorMessage.syncing,
            );
        return _Cases(
          children: [
            for (final size in FluentStatusIndicatorSize.values)
              (
                _sizeLabel(size),
                FluentStatusIndicator(
                  message: message,
                  size: size,
                  icon: Icon(_glyph(message)),
                  label: Text(_messageLabel(message)),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Categories',
      description:
          'The five tint families. Informational reads from the neutral layer '
          'and active from the brand layer — work in flight is the product '
          'acting, not a condition being reported.',
      builder: _categoriesBuilder,
    ),
    const Story(
      name: 'Category override',
      description:
          'One message under all five categories: passing a category replaces '
          'the pairing, so a stale sync can carry the warning tint without '
          'inventing a new message.',
      builder: _overrideBuilder,
    ),
    const Story(
      name: 'Glyph only',
      description:
          'Dropping the label leaves the glyph alone — and colour is not '
          'information, so the meaning has to move into a semantic label.',
      builder: _glyphOnlyBuilder,
    ),
    const Story(
      name: 'Advancing status',
      description:
          'A status that changes as work progresses. The tint lands on the '
          'next frame: Fluent specs no transition for this component.',
      builder: _advancingBuilder,
    ),
    const Story(
      name: 'Actionable',
      description:
          'The indicator never takes a callback. Wrap it in a button when the '
          'status has to be pressable.',
      builder: _actionableBuilder,
    ),
    const Story(
      name: 'Custom style',
      description:
          'A partial style override. Merging is per-property, so changing the '
          'gap or the glyph size keeps the resolved tint and type ramp.',
      builder: _customStyleBuilder,
    ),
    const Story(
      name: 'Themed subtree',
      description:
          'A status indicator theme restyles every indicator below it — here a '
          'legend that mutes each glyph to the neutral foreground.',
      builder: _themedBuilder,
    ),
  ],
);

/// The glyph Figma pairs with [message].
///
/// One [IconData] per message rather than one per message and size: the
/// component pushes its own edge length down through [IconTheme], so a single
/// 20px glyph renders correctly at all three sizes.
IconData _glyph(FluentStatusIndicatorMessage message) => switch (message) {
  FluentStatusIndicatorMessage.archived =>
    FluentIcons.arrow_circle_down_right_20_regular,
  FluentStatusIndicatorMessage.cancelled =>
    FluentIcons.subtract_circle_20_regular,
  FluentStatusIndicatorMessage.draft => FluentIcons.circle_half_fill_20_regular,
  // Figma asks for Diamond Dismiss, which fluentui_system_icons does not ship
  // at any size; Dismiss Circle is the nearest glyph in the same family.
  FluentStatusIndicatorMessage.failed => FluentIcons.dismiss_circle_20_regular,
  FluentStatusIndicatorMessage.inProgress =>
    FluentIcons.circle_half_fill_20_regular,
  FluentStatusIndicatorMessage.newItem => FluentIcons.circle_20_regular,
  FluentStatusIndicatorMessage.notStarted => FluentIcons.circle_20_regular,
  FluentStatusIndicatorMessage.pause => FluentIcons.pause_circle_20_regular,
  FluentStatusIndicatorMessage.pending =>
    FluentIcons.arrow_clockwise_dashes_20_regular,
  FluentStatusIndicatorMessage.scheduled => FluentIcons.clock_20_regular,
  FluentStatusIndicatorMessage.success =>
    FluentIcons.checkmark_circle_20_regular,
  FluentStatusIndicatorMessage.synced => FluentIcons.arrow_sync_20_regular,
  FluentStatusIndicatorMessage.syncing => FluentIcons.arrow_sync_20_regular,
  FluentStatusIndicatorMessage.unknown =>
    FluentIcons.question_circle_20_regular,
  FluentStatusIndicatorMessage.warning => FluentIcons.warning_20_regular,
  FluentStatusIndicatorMessage.genericInformation =>
    FluentIcons.info_20_regular,
};

/// The Figma name of [message], as a reader would write it.
String _messageLabel(FluentStatusIndicatorMessage message) => switch (message) {
  FluentStatusIndicatorMessage.archived => 'Archived',
  FluentStatusIndicatorMessage.cancelled => 'Cancelled',
  FluentStatusIndicatorMessage.draft => 'Draft',
  FluentStatusIndicatorMessage.failed => 'Failed',
  FluentStatusIndicatorMessage.inProgress => 'In progress',
  FluentStatusIndicatorMessage.newItem => 'New',
  FluentStatusIndicatorMessage.notStarted => 'Not started',
  FluentStatusIndicatorMessage.pause => 'Paused',
  FluentStatusIndicatorMessage.pending => 'Pending',
  FluentStatusIndicatorMessage.scheduled => 'Scheduled',
  FluentStatusIndicatorMessage.success => 'Success',
  FluentStatusIndicatorMessage.synced => 'Synced',
  FluentStatusIndicatorMessage.syncing => 'Syncing',
  FluentStatusIndicatorMessage.unknown => 'Unknown',
  FluentStatusIndicatorMessage.warning => 'Warning',
  FluentStatusIndicatorMessage.genericInformation => 'Generic information',
};

/// The Figma name of [size].
String _sizeLabel(FluentStatusIndicatorSize size) => switch (size) {
  FluentStatusIndicatorSize.small => 'Small',
  FluentStatusIndicatorSize.medium => 'Medium (default)',
  FluentStatusIndicatorSize.large => 'Large',
};

/// The Figma name of [category], including the token family it binds to.
String _categoryLabel(FluentStatusIndicatorCategory category) =>
    switch (category) {
      FluentStatusIndicatorCategory.informational => 'Informational — neutral',
      FluentStatusIndicatorCategory.success => 'Success — status',
      FluentStatusIndicatorCategory.error => 'Error — danger status',
      FluentStatusIndicatorCategory.active => 'Active — brand',
      FluentStatusIndicatorCategory.warning => 'Warning — status',
    };

/// One message per category, so the five tint families sit side by side.
const Map<FluentStatusIndicatorCategory, FluentStatusIndicatorMessage>
_perCategory = {
  FluentStatusIndicatorCategory.informational:
      FluentStatusIndicatorMessage.genericInformation,
  FluentStatusIndicatorCategory.success: FluentStatusIndicatorMessage.success,
  FluentStatusIndicatorCategory.error: FluentStatusIndicatorMessage.failed,
  FluentStatusIndicatorCategory.active: FluentStatusIndicatorMessage.inProgress,
  FluentStatusIndicatorCategory.warning: FluentStatusIndicatorMessage.warning,
};

Widget _categoriesBuilder(BuildContext context) => _Cases(
  children: [
    for (final entry in _perCategory.entries)
      (
        _categoryLabel(entry.key),
        FluentStatusIndicator(
          message: entry.value,
          icon: Icon(_glyph(entry.value)),
          label: Text(_messageLabel(entry.value)),
        ),
      ),
  ],
);

Widget _overrideBuilder(BuildContext context) => _Cases(
  children: [
    for (final category in FluentStatusIndicatorCategory.values)
      (
        _categoryLabel(category),
        FluentStatusIndicator(
          message: FluentStatusIndicatorMessage.synced,
          category: category,
          icon: const Icon(FluentIcons.arrow_sync_20_regular),
          label: const Text('Synced'),
        ),
      ),
  ],
);

Widget _glyphOnlyBuilder(BuildContext context) => _Cases(
  children: [
    for (final size in FluentStatusIndicatorSize.values)
      (
        _sizeLabel(size),
        FluentStatusIndicator(
          message: FluentStatusIndicatorMessage.failed,
          size: size,
          icon: const Icon(FluentIcons.dismiss_circle_20_regular),
          semanticLabel: 'Failed',
        ),
      ),
  ],
);

Widget _advancingBuilder(BuildContext context) => const _Workflow();

Widget _actionableBuilder(BuildContext context) => const _Actionable();

Widget _customStyleBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Default',
      const FluentStatusIndicator(
        message: FluentStatusIndicatorMessage.warning,
        icon: Icon(FluentIcons.warning_20_regular),
        label: Text('Warning'),
      ),
    ),
    (
      'Wider gap',
      FluentStatusIndicator(
        message: FluentStatusIndicatorMessage.warning,
        icon: const Icon(FluentIcons.warning_20_regular),
        label: const Text('Warning'),
        style: FluentStatusIndicatorStyle.from(gap: FluentSpacing.l),
      ),
    ),
    (
      'Larger glyph',
      FluentStatusIndicator(
        message: FluentStatusIndicatorMessage.warning,
        icon: const Icon(FluentIcons.warning_20_regular),
        label: const Text('Warning'),
        style: FluentStatusIndicatorStyle.from(iconSize: FluentSize.size240),
      ),
    ),
  ],
);

Widget _themedBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return FluentStatusIndicatorTheme(
    style: FluentStatusIndicatorStyle.from(
      iconColor: theme.colors.neutralForeground3,
      gap: FluentSpacing.m,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.s,
      children: [
        for (final message in const [
          FluentStatusIndicatorMessage.success,
          FluentStatusIndicatorMessage.failed,
          FluentStatusIndicatorMessage.inProgress,
        ])
          FluentStatusIndicator(
            message: message,
            size: FluentStatusIndicatorSize.small,
            icon: Icon(_glyph(message)),
            label: Text(_messageLabel(message)),
          ),
      ],
    ),
  );
}

/// A status that moves through a real workflow, driven by a button.
///
/// Stateful rather than a static row because the point of the story is the
/// change itself: glyph, label and tint all swap on the next frame.
class _Workflow extends StatefulWidget {
  const _Workflow();

  @override
  State<_Workflow> createState() => _WorkflowState();
}

class _WorkflowState extends State<_Workflow> {
  static const _steps = <FluentStatusIndicatorMessage>[
    FluentStatusIndicatorMessage.notStarted,
    FluentStatusIndicatorMessage.scheduled,
    FluentStatusIndicatorMessage.inProgress,
    FluentStatusIndicatorMessage.pause,
    FluentStatusIndicatorMessage.success,
  ];

  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final message = _steps[_step];
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxl,
      children: [
        FluentStatusIndicator(
          message: message,
          size: FluentStatusIndicatorSize.large,
          icon: Icon(_glyph(message)),
          label: Text(_messageLabel(message)),
        ),
        FluentButton(
          onPressed: () => setState(() => _step = (_step + 1) % _steps.length),
          child: const Text('Advance'),
        ),
      ],
    );
  }
}

/// An indicator used as a button's label, which is how a status becomes
/// pressable without the component growing a callback.
class _Actionable extends StatefulWidget {
  const _Actionable();

  @override
  State<_Actionable> createState() => _ActionableState();
}

class _ActionableState extends State<_Actionable> {
  bool _retried = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: [
        FluentButton(
          appearance: FluentButtonAppearance.subtle,
          onPressed: () => setState(() => _retried = true),
          child: const FluentStatusIndicator(
            message: FluentStatusIndicatorMessage.failed,
            icon: Icon(FluentIcons.dismiss_circle_20_regular),
            label: Text('Failed — retry'),
          ),
        ),
        if (_retried)
          Text(
            'Retry requested',
            style: theme.typography.caption1.copyWith(
              color: theme.colors.neutralForeground3,
            ),
          ),
      ],
    );
  }
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
