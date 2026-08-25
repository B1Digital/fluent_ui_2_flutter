import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Accordion docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage accordionPage = DocsPage(
  id: 'components-accordion',
  title: 'Accordion',
  description:
      'An accordion allows users to toggle the display of content by expanding '
      'or collapsing sections.',
  source: 'lib/pages/components_accordion.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-accordion--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-accordion--collapsible',
      title: 'Collapsible',
      description:
          'An accordion can have multiple panels collapsed at the same time.',
      builder: _collapsible,
    ),
    DocsSection(
      id: 'components-accordion--controlled',
      title: 'Controlled',
      description:
          'An accordion can be controlled, to ensure multiple and collapsible '
          'you should use openItems provided through onToggle callback.',
      builder: _controlled,
    ),
    DocsSection(
      id: 'components-accordion--multiple',
      title: 'Multiple',
      description:
          'An accordion supports multiple panels expanded simultaneously. Since '
          "it's not simple to determine which panel will be opened by default, "
          'multiple will also be collapsed by default on the first render',
      builder: _multiple,
    ),
    DocsSection(
      id: 'components-accordion--open-items',
      title: 'Open Items',
      description:
          'An accordion can have defined open items. If no open item is '
          'present, all panels will be closed by default',
      builder: _openItems,
    ),
    DocsSection(
      id: 'components-accordion--sizes',
      title: 'Sizes',
      description:
          'AccordionHeader supports small, medium, large and extra-large sizes.',
      builder: _sizes,
    ),
    DocsSection(
      id: 'components-accordion--heading-levels',
      title: 'Heading Levels',
      description:
          'An accordion header is a <div> by default, but according to WAI-ARIA '
          'specification, we recommend using a proper heading of any level in '
          'markup.',
      builder: _headingLevels,
    ),
    DocsSection(
      id: 'components-accordion--inline',
      title: 'Inline',
      description: 'An accordion header can be set to inline',
      builder: _inline,
    ),
    DocsSection(
      id: 'components-accordion--disabled',
      title: 'Disabled',
      description: 'An accordion item can be disabled',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-accordion--expand-icon',
      title: 'Expand Icon',
      description: 'An accordion item can have a custom expand icon.',
      builder: _expandIcon,
    ),
    DocsSection(
      id: 'components-accordion--expand-icon-position',
      title: 'Expand Icon Position',
      description:
          'The expand icon can be placed at the start or end of the accordian '
          'header.',
      builder: _expandIconPosition,
    ),
    DocsSection(
      id: 'components-accordion--with-icon',
      title: 'With Icon',
      description: 'An accordion header can contain an icon.',
      builder: _withIcon,
    ),
    DocsSection(
      id: 'components-accordion--motion-custom',
      title: 'Motion Custom',
      description:
          "AccordionPanel's collapseMotion slot can directly take Collapse "
          'props, such as duration, easing, animateOpacity and others.',
      builder: _motionCustom,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'children',
      type: 'List<Widget>',
      description: 'The items, in order.',
    ),
    PropRow(
      name: 'multiple',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether more than one panel may be open at once.',
    ),
    PropRow(
      name: 'collapsible',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the last open panel may be closed, leaving none open.',
    ),
    PropRow(
      name: 'openItems',
      type: 'Set<Object>?',
      defaultValue: 'null',
      description:
          'The open set, when the caller owns it. Null leaves the accordion '
          'uncontrolled.',
    ),
    PropRow(
      name: 'defaultOpenItems',
      type: 'Set<Object>',
      defaultValue: '{}',
      description:
          'The initial open set while uncontrolled. Ignored once openItems is '
          'given.',
    ),
    PropRow(
      name: 'onToggle',
      type: 'ValueChanged<Set<Object>>?',
      defaultValue: 'null',
      description:
          'Called with the set the accordion is moving to, before it is '
          'applied.',
    ),
  ],
);

// #docregion components-accordion--default
Widget _default(BuildContext context) => const FluentAccordion(
  children: <Widget>[
    FluentAccordionItem(
      value: '1',
      header: Text('Accordion Header 1'),
      child: Text('Accordion Panel 1'),
    ),
    FluentAccordionItem(
      value: '2',
      header: Text('Accordion Header 2'),
      child: Text('Accordion Panel 2'),
    ),
    FluentAccordionItem(
      value: '3',
      header: Text('Accordion Header 3'),
      child: Text('Accordion Panel 3'),
    ),
  ],
);
// #enddocregion components-accordion--default

// #docregion components-accordion--collapsible
Widget _collapsible(BuildContext context) => const FluentAccordion(
  collapsible: true,
  children: <Widget>[
    FluentAccordionItem(
      value: '1',
      header: Text('Accordion Header 1'),
      child: Text('Accordion Panel 1'),
    ),
    FluentAccordionItem(
      value: '2',
      header: Text('Accordion Header 2'),
      child: Text('Accordion Panel 2'),
    ),
    FluentAccordionItem(
      value: '3',
      header: Text('Accordion Header 3'),
      child: Text('Accordion Panel 3'),
    ),
  ],
);
// #enddocregion components-accordion--collapsible

// #docregion components-accordion--controlled
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  Set<Object> _openItems = <Object>{'1'};

  @override
  Widget build(BuildContext context) => FluentAccordion(
    openItems: _openItems,
    onToggle: (Set<Object> next) => setState(() => _openItems = next),
    multiple: true,
    collapsible: true,
    children: const <Widget>[
      FluentAccordionItem(
        value: '1',
        header: Text('Accordion Header 1'),
        child: Text('Accordion Panel 1'),
      ),
      FluentAccordionItem(
        value: '2',
        header: Text('Accordion Header 2'),
        child: Text('Accordion Panel 2'),
      ),
      FluentAccordionItem(
        value: '3',
        header: Text('Accordion Header 3'),
        child: Text('Accordion Panel 3'),
      ),
    ],
  );
}
// #enddocregion components-accordion--controlled

// #docregion components-accordion--multiple
Widget _multiple(BuildContext context) => const FluentAccordion(
  multiple: true,
  children: <Widget>[
    FluentAccordionItem(
      value: '1',
      header: Text('Accordion Header 1'),
      child: Text('Accordion Panel 1'),
    ),
    FluentAccordionItem(
      value: '2',
      header: Text('Accordion Header 2'),
      child: Text('Accordion Panel 2'),
    ),
    FluentAccordionItem(
      value: '3',
      header: Text('Accordion Header 3'),
      child: Text('Accordion Panel 3'),
    ),
  ],
);
// #enddocregion components-accordion--multiple

// #docregion components-accordion--open-items
Widget _openItems(BuildContext context) => const FluentAccordion(
  defaultOpenItems: <Object>{'2'},
  children: <Widget>[
    FluentAccordionItem(
      value: '1',
      header: Text('Accordion Header 1'),
      child: Text('Accordion Panel 1'),
    ),
    FluentAccordionItem(
      value: '2',
      header: Text('Accordion Header 2'),
      child: Text('Accordion Panel 2'),
    ),
    FluentAccordionItem(
      value: '3',
      header: Text('Accordion Header 3'),
      child: Text('Accordion Panel 3'),
    ),
  ],
);
// #enddocregion components-accordion--open-items

// #docregion components-accordion--sizes
Widget _sizes(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentAccordion(
      collapsible: true,
      children: <Widget>[
        FluentAccordionItem(
          value: '1',
          size: FluentAccordionSize.small,
          header: Text('Small Header'),
          child: Text('Accordion Panel'),
        ),
      ],
    ),
    FluentAccordion(
      collapsible: true,
      children: <Widget>[
        FluentAccordionItem(
          value: '1',
          header: Text('Medium Header'),
          child: Text('Accordion Panel'),
        ),
      ],
    ),
    FluentAccordion(
      collapsible: true,
      children: <Widget>[
        FluentAccordionItem(
          value: '1',
          size: FluentAccordionSize.large,
          header: Text('Large Header'),
          child: Text('Accordion Panel'),
        ),
      ],
    ),
    FluentAccordion(
      collapsible: true,
      children: <Widget>[
        FluentAccordionItem(
          value: '1',
          size: FluentAccordionSize.extraLarge,
          header: Text('Extra-Large Header'),
          child: Text('Accordion Panel'),
        ),
      ],
    ),
  ],
);
// #enddocregion components-accordion--sizes

// #docregion components-accordion--heading-levels
// Upstream renders each header as a real `<h1>`..`<h4>` so assistive technology
// reports a document outline. Flutter has no element to swap, but it has the
// property the element was there to carry: `Semantics.headingLevel`.
Widget _headingLevels(BuildContext context) => FluentAccordion(
  children: <Widget>[
    Semantics(
      headingLevel: 1,
      child: const FluentAccordionItem(
        value: '1',
        header: Text('Accordion Header as h1'),
        child: Text('Accordion Panel 1'),
      ),
    ),
    Semantics(
      headingLevel: 2,
      child: const FluentAccordionItem(
        value: '2',
        header: Text('Accordion Header as h2'),
        child: Text('Accordion Panel 2'),
      ),
    ),
    Semantics(
      headingLevel: 3,
      child: const FluentAccordionItem(
        value: '3',
        header: Text('Accordion Header as h3'),
        child: Text('Accordion Panel 3'),
      ),
    ),
    Semantics(
      headingLevel: 4,
      child: const FluentAccordionItem(
        value: '4',
        header: Text('Accordion Header as h4'),
        child: Text('Accordion Panel 4'),
      ),
    ),
  ],
);
// #enddocregion components-accordion--heading-levels

// #docregion components-accordion--inline
Widget _inline(BuildContext context) => const FluentAccordion(
  children: <Widget>[
    FluentAccordionItem(
      value: '1',
      expandIconPosition: FluentAccordionExpandIconPosition.end,
      header: Text('Accordion Header 1'),
      child: Text('Accordion Panel 1'),
    ),
    FluentAccordionItem(
      value: '2',
      expandIconPosition: FluentAccordionExpandIconPosition.end,
      header: Text('Accordion Header 2'),
      child: Text('Accordion Panel 2'),
    ),
    FluentAccordionItem(
      value: '3',
      expandIconPosition: FluentAccordionExpandIconPosition.end,
      header: Text('Accordion Header 3'),
      child: Text('Accordion Panel 3'),
    ),
  ],
);
// #enddocregion components-accordion--inline

// #docregion components-accordion--disabled
Widget _disabled(BuildContext context) => const FluentAccordion(
  children: <Widget>[
    FluentAccordionItem(
      value: '1',
      enabled: false,
      header: Text('Accordion Header 1'),
      child: Text('Accordion Panel 1'),
    ),
    FluentAccordionItem(
      value: '2',
      enabled: false,
      header: Text('Accordion Header 2'),
      child: Text('Accordion Panel 2'),
    ),
    FluentAccordionItem(
      value: '3',
      enabled: false,
      header: Text('Accordion Header 3'),
      child: Text('Accordion Panel 3'),
    ),
  ],
);
// #enddocregion components-accordion--disabled

// #docregion components-accordion--expand-icon
Widget _expandIcon(BuildContext context) => const _ExpandIcon();

class _ExpandIcon extends StatefulWidget {
  const _ExpandIcon();

  @override
  State<_ExpandIcon> createState() => _ExpandIconState();
}

class _ExpandIconState extends State<_ExpandIcon> {
  Set<Object> _openItems = <Object>{};

  Widget _icon(Object value) => Icon(
    _openItems.contains(value)
        ? FluentIcons.subtract_20_filled
        : FluentIcons.add_20_filled,
    size: 20,
  );

  @override
  Widget build(BuildContext context) => FluentAccordion(
    openItems: _openItems,
    onToggle: (Set<Object> next) => setState(() => _openItems = next),
    children: <Widget>[
      FluentAccordionItem(
        value: 1,
        icon: _icon(1),
        header: const Text('Accordion Header 1'),
        child: const Text('Accordion Panel 1'),
      ),
      FluentAccordionItem(
        value: 2,
        icon: _icon(2),
        header: const Text('Accordion Header 2'),
        child: const Text('Accordion Panel 2'),
      ),
      FluentAccordionItem(
        value: 3,
        icon: _icon(3),
        header: const Text('Accordion Header 3'),
        child: const Text('Accordion Panel 3'),
      ),
    ],
  );
}
// #enddocregion components-accordion--expand-icon

// #docregion components-accordion--expand-icon-position
Widget _expandIconPosition(BuildContext context) => const FluentAccordion(
  children: <Widget>[
    FluentAccordionItem(
      value: '1',
      expandIconPosition: FluentAccordionExpandIconPosition.end,
      header: Text('Accordion Header 1'),
      child: Text('Accordion Panel 1'),
    ),
    FluentAccordionItem(
      value: '2',
      header: Text('Accordion Header 2'),
      child: Text('Accordion Panel 2'),
    ),
  ],
);
// #enddocregion components-accordion--expand-icon-position

// #docregion components-accordion--with-icon
Widget _withIcon(BuildContext context) => const FluentAccordion(
  children: <Widget>[
    FluentAccordionItem(
      value: '1',
      icon: Icon(FluentIcons.rocket_20_regular),
      header: Text('Accordion Header 1'),
      child: Text('Accordion Panel 1'),
    ),
    FluentAccordionItem(
      value: '2',
      icon: Icon(FluentIcons.rocket_20_regular),
      header: Text('Accordion Header 2'),
      child: Text('Accordion Panel 2'),
    ),
    FluentAccordionItem(
      value: '3',
      icon: Icon(FluentIcons.rocket_20_regular),
      header: Text('Accordion Header 3'),
      child: Text('Accordion Panel 3'),
    ),
  ],
);
// #enddocregion components-accordion--with-icon

// #docregion components-accordion--motion-custom
// Upstream drives `AccordionPanel`'s `collapseMotion` slot from these controls.
// `FluentAccordionItem` exposes no motion hook, so the controls are live and the
// panel animation is not — recorded as `reduced` in storybook_adaptations.json
// rather than dressed up as working.
Widget _motionCustom(BuildContext context) => const _MotionCustom();

class _MotionCustom extends StatefulWidget {
  const _MotionCustom();

  @override
  State<_MotionCustom> createState() => _MotionCustomState();
}

class _MotionCustomState extends State<_MotionCustom> {
  double _duration = 1000;
  bool _animateOpacity = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentField(
        label: Text('Duration: ${_duration.round()}ms'),
        child: FluentSlider(
          min: 100,
          max: 2000,
          step: 50,
          value: _duration,
          onChanged: (double value) => setState(() => _duration = value),
        ),
      ),
      const SizedBox(height: 12),
      FluentSwitch(
        checked: _animateOpacity,
        label: const Text('Animate opacity'),
        onChanged: (bool value) => setState(() => _animateOpacity = value),
      ),
      const SizedBox(height: 16),
      const FluentAccordion(
        multiple: true,
        collapsible: true,
        children: <Widget>[
          FluentAccordionItem(
            value: '1',
            header: Text('Team A'),
            child: _PersonaList(),
          ),
          FluentAccordionItem(
            value: '2',
            header: Text('Team B'),
            child: _PersonaList(),
          ),
          FluentAccordionItem(
            value: '3',
            header: Text('Team C'),
            child: _PersonaList(),
          ),
        ],
      ),
    ],
  );
}

class _PersonaList extends StatelessWidget {
  const _PersonaList();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentPersona(
        name: 'Kevin Sturgis',
        secondary: Text('Available'),
        status: FluentPresenceStatus.available,
        image: AssetImage('assets/storybook/persona-male.png'),
      ),
      SizedBox(height: 8),
      FluentPersona(
        name: 'Sarah Chen',
        secondary: Text('In a meeting'),
        status: FluentPresenceStatus.busy,
      ),
      SizedBox(height: 8),
      FluentPersona(
        name: 'Jessica Brown',
        secondary: Text('Do not disturb'),
        status: FluentPresenceStatus.busy,
        image: AssetImage('assets/storybook/persona-female.png'),
      ),
      SizedBox(height: 8),
      FluentPersona(
        name: 'Emily Johnson',
        secondary: Text('Available'),
        status: FluentPresenceStatus.available,
      ),
      SizedBox(height: 8),
      FluentPersona(
        name: 'David Kim',
        secondary: Text('Offline'),
        status: FluentPresenceStatus.offline,
      ),
      SizedBox(height: 8),
      FluentPersona(
        name: 'Michael Rodriguez',
        secondary: Text('Away'),
        status: FluentPresenceStatus.away,
        image: AssetImage('assets/storybook/persona-male.png'),
      ),
    ],
  );
}

// #enddocregion components-accordion--motion-custom
