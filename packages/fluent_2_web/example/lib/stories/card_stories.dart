import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentCard].
///
/// A card fills the width it is given, exactly as upstream's block-level `div`
/// does, so every example here sits in a bounded box. That is the card's
/// contract rather than a quirk of the gallery: a preview cannot bleed to an
/// edge the card has not claimed.
final StorySection cardStories = StorySection(
  component: 'Card',
  description:
      'A container that groups a preview, a header, a body and a footer onto '
      'one surface. A card is interactive only when given an onPressed; '
      'disabled is a third state again, and an inert card can be disabled too.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every design axis at once: appearance, size, orientation, and the '
          'three states — interactive, selected and disabled — that decide how '
          'the card responds to a pointer.',
      knobs: const [
        OptionKnob<FluentCardAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentCardAppearance.filled,
          options: FluentCardAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentCardSize>(
          label: 'Size',
          id: 'size',
          initial: FluentCardSize.medium,
          options: FluentCardSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentCardOrientation>(
          label: 'Orientation',
          id: 'orientation',
          initial: FluentCardOrientation.vertical,
          options: FluentCardOrientation.values,
          labelOf: _orientationLabel,
        ),
        BoolKnob(label: 'Preview', id: 'preview', initial: true),
        BoolKnob(label: 'Interactive', id: 'interactive', initial: true),
        BoolKnob(label: 'Selected', id: 'selected'),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final orientation = knobs.get<FluentCardOrientation>(
          'orientation',
          FluentCardOrientation.vertical,
        );
        final horizontal = orientation == FluentCardOrientation.horizontal;
        return _Bounded(
          width: horizontal ? 420 : 280,
          child: FluentCard(
            appearance: knobs.get<FluentCardAppearance>(
              'appearance',
              FluentCardAppearance.filled,
            ),
            size: knobs.get<FluentCardSize>('size', FluentCardSize.medium),
            orientation: orientation,
            selected: knobs.get<bool>('selected', false),
            disabled: knobs.get<bool>('disabled', false),
            onPressed: knobs.get<bool>('interactive', true) ? () {} : null,
            semanticLabel: 'Quarterly revenue',
            preview: knobs.get<bool>('preview', true)
                ? _Preview(square: horizontal)
                : null,
            header: const _Title('Quarterly revenue'),
            footer: const _Caption('Updated 2 minutes ago'),
            child: const Text('Revenue is up 4% against the same week in Q3.'),
          ),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'Filled, filled alternative, outline and subtle. Only the two filled '
          'appearances are elevated; outline signals state through its border '
          'and subtle shows a fill only on hover.',
      knobs: const [
        BoolKnob(label: 'Interactive', id: 'interactive', initial: true),
      ],
      builder: (context) {
        final interactive = KnobsScope.of(
          context,
        ).get<bool>('interactive', true);
        return _Cases(
          children: [
            for (final appearance in FluentCardAppearance.values)
              (
                _appearanceLabel(appearance),
                FluentCard(
                  appearance: appearance,
                  onPressed: interactive ? () {} : null,
                  semanticLabel: _appearanceLabel(appearance),
                  header: _Title(_appearanceLabel(appearance)),
                  child: const Text('Hover to see the interactive tokens.'),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Sizes',
      description:
          'Small, medium and large. One number drives the inset, the gap '
          'between slots and the corner radius at every step, so the three '
          'move together.',
      knobs: const [
        OptionKnob<FluentCardAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentCardAppearance.filled,
          options: FluentCardAppearance.values,
          labelOf: _appearanceLabel,
        ),
      ],
      builder: (context) {
        final appearance = KnobsScope.of(
          context,
        ).get<FluentCardAppearance>('appearance', FluentCardAppearance.filled);
        return _Cases(
          children: [
            for (final size in FluentCardSize.values)
              (
                _sizeLabel(size),
                FluentCard(
                  size: size,
                  appearance: appearance,
                  preview: const _Preview(),
                  header: _Title(_sizeLabel(size)),
                  child: const Text('Inset, gap and radius all move together.'),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Orientation',
      description:
          'Vertical stacks the preview above the slots; horizontal puts it '
          'first on the inline axis and centres everything on the cross axis.',
      builder: _orientationBuilder,
    ),
    const Story(
      name: 'Interactive',
      description:
          'An onPressed turns the card into a button: it takes focus, raises a '
          'focus ring on Tab, lifts on hover and fires on Space or Enter. '
          'Without one the card is inert and ignores the pointer entirely.',
      builder: _interactiveBuilder,
    ),
    Story(
      name: 'Disabled',
      description:
          'Disabled is a real state, not a missing callback: the card refuses '
          'focus, never invokes onPressed and paints the disabled tokens. Only '
          'outline keeps a visible border.',
      knobs: const [BoolKnob(label: 'Disabled', id: 'disabled', initial: true)],
      builder: (context) {
        final disabled = KnobsScope.of(context).get<bool>('disabled', true);
        return _Cases(
          children: [
            for (final appearance in FluentCardAppearance.values)
              (
                _appearanceLabel(appearance),
                FluentCard(
                  appearance: appearance,
                  disabled: disabled,
                  onPressed: () {},
                  semanticLabel: _appearanceLabel(appearance),
                  header: _Title(_appearanceLabel(appearance)),
                  child: const Text('This card cannot be pressed.'),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Selectable',
      description:
          'Press a card to select it. Selection outranks hover — a hovered '
          'selected card keeps the Selected fill — and is announced to '
          'assistive technology.',
      builder: _selectableBuilder,
    ),
    const Story(
      name: 'Selection indicator',
      description:
          'A card has no indicator slot of its own, so the checkbox is a '
          'widget in the header. Card and checkbox drive the same value, which '
          'keeps the two in step.',
      builder: _indicatorBuilder,
    ),
    const Story(
      name: 'Preview',
      description:
          'The preview bleeds to the card edge and is clipped to its radius, '
          'while every other slot is inset. A card can be nothing but a '
          'preview.',
      builder: _previewBuilder,
    ),
    const Story(
      name: 'Header',
      description:
          'The header is a plain widget, so the familiar avatar, title, '
          'subtitle and trailing action arrangement is a composition rather '
          'than a fixed grid.',
      builder: _headerBuilder,
    ),
    const Story(
      name: 'Footer',
      description:
          'The footer holds the card actions. It is inset and gapped like the '
          'other slots, so a row of buttons needs no padding of its own.',
      builder: _footerBuilder,
    ),
    const Story(
      name: 'Templates',
      description:
          'Three arrangements built only from the four slots: an announcement, '
          'a horizontal file row and a media tile.',
      builder: _templatesBuilder,
    ),
  ],
);

String _appearanceLabel(FluentCardAppearance value) =>
    value == FluentCardAppearance.filledAlternative
    ? 'filled alternative'
    : value.name;

String _sizeLabel(FluentCardSize value) => value.name;

String _orientationLabel(FluentCardOrientation value) => value.name;

Widget _orientationBuilder(BuildContext context) => const _Cases(
  width: 380,
  children: [
    (
      'vertical',
      FluentCard(
        preview: _Preview(),
        header: _Title('Design review'),
        child: Text('The preview spans the full width of the card.'),
      ),
    ),
    (
      'horizontal',
      FluentCard(
        orientation: FluentCardOrientation.horizontal,
        preview: _Preview(square: true),
        header: _Title('Design review'),
        child: Text('The preview leads and the slots sit beside it.'),
      ),
    ),
  ],
);

Widget _interactiveBuilder(BuildContext context) => const _PressCounter();

Widget _selectableBuilder(BuildContext context) => const _SelectableRow();

Widget _indicatorBuilder(BuildContext context) => const _IndicatorCard();

Widget _previewBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Preview and slots',
      FluentCard(
        preview: _Preview(),
        header: _Title('Cover'),
        child: Text('Slots are inset; the preview is not.'),
      ),
    ),
    ('Preview only', FluentCard(preview: _Preview(height: 140))),
    (
      'No preview',
      FluentCard(
        header: _Title('Text only'),
        child: Text('Without a preview the card is its padded slots.'),
      ),
    ),
  ],
);

Widget _headerBuilder(BuildContext context) => _Bounded(
  width: 340,
  child: FluentCard(
    header: Row(
      spacing: FluentSpacing.m,
      children: [
        const FluentAvatar(initials: 'AC', name: 'Ada Coburn'),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title('Ada Coburn'),
              _Caption('Shared a file · 3:14 PM'),
            ],
          ),
        ),
        FluentButton.icon(
          icon: const Icon(FluentIcons.more_horizontal_20_regular),
          semanticLabel: 'More actions',
          appearance: FluentButtonAppearance.subtle,
          size: FluentButtonSize.small,
          onPressed: () {},
        ),
      ],
    ),
    child: const Text('Q4 planning deck.pptx'),
  ),
);

Widget _footerBuilder(BuildContext context) => _Bounded(
  width: 320,
  child: FluentCard(
    header: const _Title('Storage almost full'),
    footer: Row(
      spacing: FluentSpacing.s,
      children: [
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          size: FluentButtonSize.small,
          onPressed: () {},
          child: const Text('Upgrade'),
        ),
        FluentButton(
          appearance: FluentButtonAppearance.subtle,
          size: FluentButtonSize.small,
          onPressed: () {},
          child: const Text('Not now'),
        ),
      ],
    ),
    child: const Text('You have used 94% of your 5 GB plan.'),
  ),
);

Widget _templatesBuilder(BuildContext context) => _Cases(
  width: 320,
  children: [
    (
      'Announcement',
      FluentCard(
        preview: const _Preview(height: 96),
        header: const _Title('Fluent 2 is here'),
        footer: FluentButton(
          appearance: FluentButtonAppearance.primary,
          size: FluentButtonSize.small,
          onPressed: () {},
          child: const Text('Read the notes'),
        ),
        child: const Text('New tokens, new motion, the same components.'),
      ),
    ),
    (
      'File row',
      FluentCard(
        orientation: FluentCardOrientation.horizontal,
        size: FluentCardSize.small,
        appearance: FluentCardAppearance.outline,
        onPressed: () {},
        semanticLabel: 'Budget 2026.xlsx',
        header: const Icon(FluentIcons.save_32_regular),
        footer: const _Caption('2.4 MB'),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_Title('Budget 2026.xlsx'), _Caption('Edited yesterday')],
        ),
      ),
    ),
    (
      'Media tile',
      FluentCard(
        onPressed: () {},
        semanticLabel: 'Weekly sync recording',
        preview: const _Preview(height: 120),
        header: const _Title('Weekly sync'),
        footer: Row(
          spacing: FluentSpacing.s,
          children: [
            const FluentAvatar(
              initials: 'MK',
              name: 'Mira Kaur',
              size: FluentAvatarSize.size24,
            ),
            const Expanded(child: _Caption('Mira Kaur · 42 min')),
            FluentButton.icon(
              icon: const Icon(FluentIcons.share_20_regular),
              semanticLabel: 'Share recording',
              appearance: FluentButtonAppearance.subtle,
              size: FluentButtonSize.small,
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
  ],
);

/// An interactive card and an inert one, so the difference is a press apart.
class _PressCounter extends StatefulWidget {
  const _PressCounter();

  @override
  State<_PressCounter> createState() => _PressCounterState();
}

class _PressCounterState extends State<_PressCounter> {
  int _presses = 0;

  @override
  Widget build(BuildContext context) => _Cases(
    children: [
      (
        'Interactive',
        FluentCard(
          onPressed: () => setState(() => _presses++),
          semanticLabel: 'Press me',
          header: const _Title('Press me'),
          child: Text('Pressed $_presses times.'),
        ),
      ),
      (
        'Inert',
        const FluentCard(
          header: _Title('Read only'),
          child: Text('No hover, no focus, no ring.'),
        ),
      ),
    ],
  );
}

/// Three cards in one selection group, so selection can be seen moving.
class _SelectableRow extends StatefulWidget {
  const _SelectableRow();

  @override
  State<_SelectableRow> createState() => _SelectableRowState();
}

class _SelectableRowState extends State<_SelectableRow> {
  final Set<String> _selected = <String>{'Balanced'};

  @override
  Widget build(BuildContext context) => _Cases(
    children: [
      for (final plan in const <String>['Quiet', 'Balanced', 'Performance'])
        (
          plan,
          FluentCard(
            selected: _selected.contains(plan),
            semanticLabel: plan,
            onPressed: () => setState(
              () => _selected.contains(plan)
                  ? _selected.remove(plan)
                  : _selected.add(plan),
            ),
            header: _Title(plan),
            child: const Text('Press to select, press again to clear.'),
          ),
        ),
    ],
  );
}

/// A selectable card whose indicator is a real checkbox in the header slot.
class _IndicatorCard extends StatefulWidget {
  const _IndicatorCard();

  @override
  State<_IndicatorCard> createState() => _IndicatorCardState();
}

class _IndicatorCardState extends State<_IndicatorCard> {
  bool _selected = false;

  void _toggle() => setState(() => _selected = !_selected);

  @override
  Widget build(BuildContext context) => _Bounded(
    width: 300,
    child: FluentCard(
      selected: _selected,
      onPressed: _toggle,
      semanticLabel: 'Notify me on mention',
      header: Row(
        spacing: FluentSpacing.m,
        children: [
          const Expanded(child: _Title('Notify me on mention')),
          FluentCheckbox(
            checked: _selected,
            semanticLabel: 'Notify me on mention',
            onChanged: (_) => _toggle(),
          ),
        ],
      ),
      child: const Text('Both the card and the checkbox drive one value.'),
    ),
  );
}

/// A stand-in for cover art: a branded block, filled from the theme rather than
/// a colour of its own.
class _Preview extends StatelessWidget {
  const _Preview({this.height = 72, this.square = false});

  final double height;

  /// Constrains the width too, for a horizontal card's leading preview.
  final bool square;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: square ? 88 : height,
    width: square ? 88 : null,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: FluentTheme.of(context).colors.brandBackground2,
      ),
    ),
  );
}

/// The title line of a card slot.
class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: FluentTheme.of(context).typography.body1Strong);
}

/// Secondary text inside a card slot.
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Text(
      text,
      style: theme.typography.caption1.copyWith(
        // The card's own foreground colour wins on hover and selection, so this
        // only softens the resting state.
        color: theme.colors.neutralForeground3,
      ),
    );
  }
}

/// Gives a card the bounded width it needs — it fills what it is given.
class _Bounded extends StatelessWidget {
  const _Bounded({required this.width, required this.child});

  final double width;

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: SizedBox(width: width, child: child),
  );
}

/// Side-by-side cards under a caption, each in a box of its own.
class _Cases extends StatelessWidget {
  const _Cases({required this.children, this.width = 240});

  final List<(String, Widget)> children;

  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xl,
      runSpacing: FluentSpacing.l,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final (caption, child) in children)
          SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ),
      ],
    );
  }
}
