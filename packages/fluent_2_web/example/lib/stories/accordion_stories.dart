import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentAccordion] and [FluentAccordionItem].
final StorySection accordionStories = StorySection(
  component: 'Accordion',
  description:
      'A stack of headers, each revealing a panel. Two independent flags decide '
      'what a header press does — whether more than one panel may be open, and '
      'whether the last open panel may be closed — and the same accordion can '
      'either own that set itself or hand it to the caller.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A plain accordion with its real defaults: one panel open at a time, '
          'and no way to close the open one except by opening another. Every '
          'size is 44 high, so the knob changes the type ramp and nothing else.',
      knobs: const [
        OptionKnob<FluentAccordionSize>(
          label: 'Size',
          id: 'size',
          initial: FluentAccordionSize.medium,
          options: FluentAccordionSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentAccordionExpandIconPosition>(
          label: 'Chevron',
          id: 'position',
          initial: FluentAccordionExpandIconPosition.start,
          options: FluentAccordionExpandIconPosition.values,
          labelOf: _positionLabel,
        ),
        BoolKnob(label: 'Leading icon', id: 'icon'),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Small, medium, large and extra large. Only the label ramp moves — '
          'caption1, body1, subtitle2, subtitle1, semibold from large up — '
          'while the header box stays 44 high at every step.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Chevron position',
      description:
          'The chevron leads the label by default, or sits at the trailing '
          'edge. Its rotation differs with it: leading points right then down, '
          'trailing points down then up.',
      builder: _positionBuilder,
    ),
    const Story(
      name: 'With icon',
      description:
          'An optional icon sits between the chevron and the label, and takes '
          'the header foreground token — including the disabled one — without '
          'being told to.',
      builder: _withIconBuilder,
    ),
    Story(
      name: 'Multiple and collapsible',
      description:
          'The two expansion flags, live. Multiple allows more than one open '
          'panel; collapsible allows the last open one to be closed. Off and '
          'off — the default — means a panel is always open.',
      knobs: const [
        BoolKnob(label: 'Multiple', id: 'multiple'),
        BoolKnob(label: 'Collapsible', id: 'collapsible'),
      ],
      builder: _expansionBuilder,
    ),
    const Story(
      name: 'Open by default',
      description:
          'defaultOpenItems seeds an uncontrolled accordion. A single-expansion '
          'accordion keeps only the first of several defaults rather than '
          'opening two panels it could never close.',
      builder: _defaultOpenBuilder,
    ),
    const Story(
      name: 'Controlled',
      description:
          'Pass openItems and the caller owns the set: pressing a header only '
          'reports the set it wants to move to, and nothing opens until the '
          'caller applies it. Expand all and Collapse all drive the same set.',
      builder: _controlledBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabled is a real state, not a fade: the header refuses focus, '
          'reports no hover or press, and cannot be toggled by pointer or '
          'keyboard. Its neighbours stay live.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Panel content',
      description:
          'A panel takes any widget, and the panel is deliberately outside the '
          'interactive surface — pressing a control inside an open panel does '
          'not collapse it.',
      builder: _panelContentBuilder,
    ),
    const Story(
      name: 'Restyled header',
      description:
          'A Fluent header is flat by design: upstream declares no hover rule '
          'at all. FluentAccordionItemTheme adds one in a line, over a whole '
          'subtree, without touching any other resolved value.',
      builder: _restyledBuilder,
    ),
  ],
);

String _sizeLabel(FluentAccordionSize value) => value.name;

String _positionLabel(FluentAccordionExpandIconPosition value) => value.name;

/// The three sections every story hangs its panels off, so the page reads as
/// one document rather than ten unrelated fragments.
const _sections = <(String, String)>[
  (
    'Delivery',
    'Standard delivery arrives within three working days. Express is next '
        'working day when ordered before 4pm.',
  ),
  (
    'Payment',
    'Cards, bank transfer and gift vouchers. Nothing is charged until the '
        'order leaves the warehouse.',
  ),
  (
    'Returns',
    'Anything unopened can go back within thirty days, postage paid.',
  ),
];

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final size = knobs.get<FluentAccordionSize>(
    'size',
    FluentAccordionSize.medium,
  );
  final position = knobs.get<FluentAccordionExpandIconPosition>(
    'position',
    FluentAccordionExpandIconPosition.start,
  );
  final icon = knobs.get<bool>('icon', false);
  final enabled = !knobs.get<bool>('disabled', false);

  return FluentAccordion(
    children: [
      for (final (title, body) in _sections)
        FluentAccordionItem(
          value: title,
          size: size,
          expandIconPosition: position,
          enabled: enabled,
          icon: icon ? const Icon(FluentIcons.box_20_regular) : null,
          header: Text(title),
          child: _Panel(body),
        ),
    ],
  );
}

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('small — caption1', _OneItem(size: FluentAccordionSize.small)),
    ('medium — body1', _OneItem()),
    ('large — subtitle2 semibold', _OneItem(size: FluentAccordionSize.large)),
    (
      'extra large — subtitle1 semibold',
      _OneItem(size: FluentAccordionSize.extraLarge),
    ),
  ],
);

Widget _positionBuilder(BuildContext context) => const _Cases(
  children: [
    ('start — leads the label', _OneItem()),
    (
      'end — trailing edge',
      _OneItem(position: FluentAccordionExpandIconPosition.end),
    ),
  ],
);

Widget _withIconBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'chevron at the start',
      FluentAccordion(
        multiple: true,
        collapsible: true,
        defaultOpenItems: <Object>{'Payment'},
        children: [
          FluentAccordionItem(
            value: 'Delivery',
            icon: Icon(FluentIcons.vehicle_truck_20_regular),
            header: Text('Delivery'),
            child: _Panel('Standard, express or collection in store.'),
          ),
          FluentAccordionItem(
            value: 'Payment',
            icon: Icon(FluentIcons.payment_20_regular),
            header: Text('Payment'),
            child: _Panel('Cards, bank transfer and gift vouchers.'),
          ),
          FluentAccordionItem(
            value: 'Security',
            enabled: false,
            icon: Icon(FluentIcons.lock_closed_20_regular),
            header: Text('Security — disabled, and so is its icon'),
            child: _Panel('Unreachable.'),
          ),
        ],
      ),
    ),
    (
      'chevron at the end',
      FluentAccordion(
        collapsible: true,
        children: [
          FluentAccordionItem(
            value: 'Account',
            expandIconPosition: FluentAccordionExpandIconPosition.end,
            icon: Icon(FluentIcons.person_20_regular),
            header: Text('Account'),
            child: _Panel('Name, email and sign-in method.'),
          ),
          FluentAccordionItem(
            value: 'Preferences',
            expandIconPosition: FluentAccordionExpandIconPosition.end,
            icon: Icon(FluentIcons.settings_20_regular),
            header: Text('Preferences'),
            child: _Panel('Language, time zone and notifications.'),
          ),
        ],
      ),
    ),
  ],
);

Widget _expansionBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final multiple = knobs.get<bool>('multiple', false);
  final collapsible = knobs.get<bool>('collapsible', false);
  return FluentAccordion(
    // The open set is seeded once, so re-keying on the flags re-seeds it and a
    // reader always sees the new rules from a clean start rather than from
    // whatever the previous ones left open.
    key: ValueKey<String>('$multiple-$collapsible'),
    multiple: multiple,
    collapsible: collapsible,
    defaultOpenItems: const <Object>{'Delivery'},
    children: [
      for (final (title, body) in _sections)
        FluentAccordionItem(
          value: title,
          header: Text(title),
          child: _Panel(body),
        ),
    ],
  );
}

Widget _defaultOpenBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'single — keeps only the first default',
      FluentAccordion(
        defaultOpenItems: <Object>{'Delivery', 'Payment'},
        children: [
          FluentAccordionItem(
            value: 'Delivery',
            header: Text('Delivery'),
            child: _Panel('Open, because it was named first.'),
          ),
          FluentAccordionItem(
            value: 'Payment',
            header: Text('Payment'),
            child: _Panel('Dropped from the seed set.'),
          ),
        ],
      ),
    ),
    (
      'multiple — opens both',
      FluentAccordion(
        multiple: true,
        collapsible: true,
        defaultOpenItems: <Object>{'Delivery', 'Payment'},
        children: [
          FluentAccordionItem(
            value: 'Delivery',
            header: Text('Delivery'),
            child: _Panel('Open from the seed set.'),
          ),
          FluentAccordionItem(
            value: 'Payment',
            header: Text('Payment'),
            child: _Panel('Open from the seed set too.'),
          ),
        ],
      ),
    ),
  ],
);

Widget _controlledBuilder(BuildContext context) => const _ControlledAccordion();

Widget _disabledBuilder(BuildContext context) => FluentAccordion(
  multiple: true,
  collapsible: true,
  defaultOpenItems: const <Object>{'Delivery'},
  children: [
    for (final (title, body) in _sections)
      FluentAccordionItem(
        value: title,
        enabled: title != 'Payment',
        header: Text(title == 'Payment' ? '$title — disabled' : title),
        child: _Panel(body),
      ),
  ],
);

Widget _panelContentBuilder(BuildContext context) => const _PanelContent();

Widget _restyledBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentAccordionItemTheme(
    style: FluentAccordionItemStyle(
      backgroundColor: FluentStateColor.tokens(
        rest: colors.transparentBackground,
        hover: colors.neutralBackground1Hover,
        pressed: colors.neutralBackground1Pressed,
        disabled: colors.transparentBackground,
      ),
    ),
    child: FluentAccordion(
      multiple: true,
      collapsible: true,
      children: [
        for (final (title, body) in _sections)
          FluentAccordionItem(
            value: title,
            header: Text(title),
            child: _Panel(body),
          ),
      ],
    ),
  );
}

/// A controlled accordion: the open set lives here, not in the widget.
class _ControlledAccordion extends StatefulWidget {
  const _ControlledAccordion();

  @override
  State<_ControlledAccordion> createState() => _ControlledAccordionState();
}

class _ControlledAccordionState extends State<_ControlledAccordion> {
  Set<Object> _open = <Object>{'Delivery'};

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: [
            FluentButton(
              onPressed: () => setState(
                () => _open = <Object>{for (final (t, _) in _sections) t},
              ),
              child: const Text('Expand all'),
            ),
            FluentButton(
              onPressed: () => setState(() => _open = <Object>{}),
              child: const Text('Collapse all'),
            ),
          ],
        ),
        FluentAccordion(
          multiple: true,
          collapsible: true,
          openItems: _open,
          onToggle: (next) => setState(() => _open = next),
          children: [
            for (final (title, body) in _sections)
              FluentAccordionItem(
                value: title,
                header: Text(title),
                child: _Panel(body),
              ),
          ],
        ),
        Text(
          _open.isEmpty ? 'Open: none' : 'Open: ${_open.join(', ')}',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// A panel holding real controls, to show that pressing one does not collapse
/// the item around it.
class _PanelContent extends StatefulWidget {
  const _PanelContent();

  @override
  State<_PanelContent> createState() => _PanelContentState();
}

class _PanelContentState extends State<_PanelContent> {
  bool _express = false;
  String? _last;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentAccordion(
      multiple: true,
      collapsible: true,
      defaultOpenItems: const <Object>{'Delivery'},
      children: [
        FluentAccordionItem(
          value: 'Delivery',
          icon: const Icon(FluentIcons.vehicle_truck_20_regular),
          header: const Text('Delivery'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FluentSpacing.s,
            children: [
              FluentSwitch(
                checked: _express,
                onChanged: (v) => setState(() => _express = v),
                label: const Text('Express delivery'),
              ),
              FluentButton(
                appearance: FluentButtonAppearance.primary,
                onPressed: () => setState(
                  () => _last = _express ? 'Express saved' : 'Standard saved',
                ),
                child: const Text('Save'),
              ),
              Text(
                _last ?? 'Nothing saved yet',
                style: theme.typography.caption1.copyWith(
                  color: theme.colors.neutralForeground3,
                ),
              ),
            ],
          ),
        ),
        const FluentAccordionItem(
          value: 'Returns',
          icon: Icon(FluentIcons.document_20_regular),
          header: Text('Returns'),
          child: _Panel('Anything unopened can go back within thirty days.'),
        ),
      ],
    );
  }
}

/// One-item accordion, the shape the size and chevron comparisons want.
class _OneItem extends StatelessWidget {
  const _OneItem({
    this.size = FluentAccordionSize.medium,
    this.position = FluentAccordionExpandIconPosition.start,
  });

  final FluentAccordionSize size;
  final FluentAccordionExpandIconPosition position;

  @override
  Widget build(BuildContext context) => FluentAccordion(
    collapsible: true,
    children: [
      FluentAccordionItem(
        value: 'a',
        size: size,
        expandIconPosition: position,
        header: const Text('Delivery'),
        child: const _Panel('Standard delivery arrives within three days.'),
      ),
    ],
  );
}

/// Panel body text, one step quieter than the header.
class _Panel extends StatelessWidget {
  const _Panel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Text(
      text,
      style: theme.typography.body1.copyWith(
        color: theme.colors.neutralForeground2,
      ),
    );
  }
}

/// Captioned cases stacked down the page — an accordion is a full-width block,
/// so these read side by side badly and one under another well.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FluentSpacing.xl,
      children: [
        for (final (caption, child) in children)
          Column(
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
      ],
    );
  }
}
