import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The AvatarGroup docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage avatarGroupPage = DocsPage(
  id: 'components-avatargroup',
  title: 'AvatarGroup',
  description:
      'An AvatarGroup is a graphical representation of multiple people '
      'associated with a given entity. AvatarGroup leverages the Avatar '
      'component, with each Avatar representing a person and containing their '
      'image, initials, or an icon. An AvatarGroup can be represented in a '
      'spread, stack, or pie layout.',
  source: 'lib/pages/components_avatargroup.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-avatargroup--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-avatargroup--layout',
      title: 'Layout',
      description:
          'An AvatarGroup supports three layouts: spread, stack, and pie. The '
          'default is spread.',
      builder: _layout,
    ),
    DocsSection(
      id: 'components-avatargroup--indicator',
      title: 'Indicator',
      description:
          'An AvatarGroup supports an icon and a count indicator. When size is '
          'less than 24, then icon will be used by default.',
      builder: _indicator,
    ),
    DocsSection(
      id: 'components-avatargroup--size-spread',
      title: 'Size Spread',
      description:
          'An AvatarGroup with spread layout supports a range of sizes from 16 '
          'to 128. The default is 32.',
      builder: _sizeSpread,
    ),
    DocsSection(
      id: 'components-avatargroup--size-stack',
      title: 'Size Stack',
      description:
          'An AvatarGroup with stack layout supports a range of sizes from 16 '
          'to 128. The default is 32. WARNING: do not make multiple avatars in '
          'a stack interactive unless the size is at least 28. Smaller sizes '
          'with overlapping click targets will fail to meet the WCAG target '
          'size requirement.',
      builder: _sizeStack,
    ),
    DocsSection(
      id: 'components-avatargroup--size-pie',
      title: 'Size Pie',
      description:
          'An AvatarGroup with pie layout supports a range of sizes from 16 to '
          '128. The default is 32.',
      builder: _sizePie,
    ),
    DocsSection(
      id: 'components-avatargroup--tooltip',
      title: 'Tooltip',
      description:
          'You can customize the tooltip of the AvatarGroupPopover, for '
          'example for translations.',
      builder: _tooltip,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'children',
      type: 'List<Widget>',
      description:
          'The avatars, in reading order. The pie layout reads the first three.',
    ),
    PropRow(
      name: 'layout',
      type: 'FluentAvatarGroupLayout',
      defaultValue: 'FluentAvatarGroupLayout.spread',
      description: 'How the avatars are arranged.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentAvatarSize',
      defaultValue: 'FluentAvatarSize.size32',
      description: 'The edge length every member is expected to use.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentAvatarGroupStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-avatargroup--default
typedef _DefaultPerson = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

// `FluentAvatar` derives neither initials nor a colour from `name` — upstream's
// `getInitials` is a locale-sensitive parser — so `AvatarGroupItem name={name}`
// is spelled out per person here.
const List<_DefaultPerson> _defaultPeople = <_DefaultPerson>[
  (name: 'Johnie McConnell', initials: 'JM', color: FluentAvatarColor.platinum),
  (name: 'Allan Munger', initials: 'AM', color: FluentAvatarColor.lavender),
  (name: 'Erik Nason', initials: 'EN', color: FluentAvatarColor.steel),
  (name: 'Kristin Patterson', initials: 'KP', color: FluentAvatarColor.teal),
  (name: 'Daisy Phillips', initials: 'DP', color: FluentAvatarColor.seafoam),
  (name: 'Carole Poland', initials: 'CP', color: FluentAvatarColor.marigold),
  (
    name: 'Carlos Slattery',
    initials: 'CS',
    color: FluentAvatarColor.cornflower,
  ),
  (name: 'Robert Tolbert', initials: 'RT', color: FluentAvatarColor.platinum),
  (name: 'Kevin Sturgis', initials: 'KS', color: FluentAvatarColor.lavender),
  (name: 'Charlotte Waltson', initials: 'CW', color: FluentAvatarColor.peach),
  (name: 'Elliot Woodward', initials: 'EW', color: FluentAvatarColor.seafoam),
];

// `partitionAvatarGroupItems`, transcribed: the last four names stay inline and
// the other seven move into the overflow popover.
Widget _default(BuildContext context) => FluentAvatarGroup(
  children: <Widget>[
    for (final _DefaultPerson person in _defaultPeople.sublist(7))
      FluentAvatar(
        name: person.name,
        initials: person.initials,
        color: person.color,
      ),
    _DefaultOverflow(people: _defaultPeople.sublist(0, 7)),
  ],
);

/// `AvatarGroupPopover`: `FluentAvatarGroup` has no popover slot, so the
/// overflow indicator is an ordinary member — an avatar in
/// `FluentAvatarColor.overflow` that owns the `FluentPopover` and its open bit.
class _DefaultOverflow extends StatefulWidget {
  const _DefaultOverflow({required this.people});

  final List<_DefaultPerson> people;

  @override
  State<_DefaultOverflow> createState() => _DefaultOverflowState();
}

class _DefaultOverflowState extends State<_DefaultOverflow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool value) => setState(() => _open = value),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        for (final _DefaultPerson person in widget.people)
          FluentPersona(
            name: person.name,
            initials: person.initials,
            color: person.color,
          ),
      ],
    ),
    child: GestureDetector(
      onTap: () => setState(() => _open = true),
      child: FluentAvatar(
        color: FluentAvatarColor.overflow,
        initials: '+${widget.people.length}',
        name: widget.people
            .map((_DefaultPerson person) => person.name)
            .join(', '),
      ),
    ),
  );
}
// #enddocregion components-avatargroup--default

// #docregion components-avatargroup--layout
typedef _LayoutPerson = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_LayoutPerson> _layoutPeople = <_LayoutPerson>[
  (name: 'Johnie McConnell', initials: 'JM', color: FluentAvatarColor.platinum),
  (name: 'Allan Munger', initials: 'AM', color: FluentAvatarColor.lavender),
  (name: 'Erik Nason', initials: 'EN', color: FluentAvatarColor.steel),
  (name: 'Kristin Patterson', initials: 'KP', color: FluentAvatarColor.teal),
  (name: 'Daisy Phillips', initials: 'DP', color: FluentAvatarColor.seafoam),
  (name: 'Carole Poland', initials: 'CP', color: FluentAvatarColor.marigold),
  (
    name: 'Carlos Slattery',
    initials: 'CS',
    color: FluentAvatarColor.cornflower,
  ),
  (name: 'Robert Tolbert', initials: 'RT', color: FluentAvatarColor.platinum),
  (name: 'Kevin Sturgis', initials: 'KS', color: FluentAvatarColor.lavender),
  (name: 'Charlotte Waltson', initials: 'CW', color: FluentAvatarColor.peach),
  (name: 'Elliot Woodward', initials: 'EW', color: FluentAvatarColor.seafoam),
];

Widget _layout(BuildContext context) {
  // spread and stack partition the same way: four inline, seven in the popover.
  List<Widget> members() => <Widget>[
    for (final _LayoutPerson person in _layoutPeople.sublist(7))
      FluentAvatar(
        name: person.name,
        initials: person.initials,
        color: person.color,
      ),
    _LayoutOverflow(people: _layoutPeople.sublist(0, 7)),
  ];

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10,
    children: <Widget>[
      FluentAvatarGroup(children: members()),
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.stack,
        children: members(),
      ),
      // A pie partition sends *every* name to the popover, and upstream draws
      // no trigger beside the pie — so the pie is just its first three members.
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.pie,
        children: <Widget>[
          for (final _LayoutPerson person in _layoutPeople.sublist(0, 3))
            FluentAvatar(
              name: person.name,
              initials: person.initials,
              color: person.color,
            ),
        ],
      ),
    ],
  );
}

/// `AvatarGroupPopover`: `FluentAvatarGroup` has no popover slot, so the
/// overflow indicator is an ordinary member that owns its own `FluentPopover`.
class _LayoutOverflow extends StatefulWidget {
  const _LayoutOverflow({required this.people});

  final List<_LayoutPerson> people;

  @override
  State<_LayoutOverflow> createState() => _LayoutOverflowState();
}

class _LayoutOverflowState extends State<_LayoutOverflow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool value) => setState(() => _open = value),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        for (final _LayoutPerson person in widget.people)
          FluentPersona(
            name: person.name,
            initials: person.initials,
            color: person.color,
          ),
      ],
    ),
    child: GestureDetector(
      onTap: () => setState(() => _open = true),
      child: FluentAvatar(
        color: FluentAvatarColor.overflow,
        initials: '+${widget.people.length}',
        name: widget.people
            .map((_LayoutPerson person) => person.name)
            .join(', '),
      ),
    ),
  );
}
// #enddocregion components-avatargroup--layout

// #docregion components-avatargroup--indicator
typedef _IndicatorPerson = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_IndicatorPerson> _indicatorPeople = <_IndicatorPerson>[
  (name: 'Johnie McConnell', initials: 'JM', color: FluentAvatarColor.platinum),
  (name: 'Allan Munger', initials: 'AM', color: FluentAvatarColor.lavender),
  (name: 'Erik Nason', initials: 'EN', color: FluentAvatarColor.steel),
  (name: 'Kristin Patterson', initials: 'KP', color: FluentAvatarColor.teal),
  (name: 'Daisy Phillips', initials: 'DP', color: FluentAvatarColor.seafoam),
  (name: 'Carole Poland', initials: 'CP', color: FluentAvatarColor.marigold),
  (
    name: 'Carlos Slattery',
    initials: 'CS',
    color: FluentAvatarColor.cornflower,
  ),
  (name: 'Robert Tolbert', initials: 'RT', color: FluentAvatarColor.platinum),
  (name: 'Kevin Sturgis', initials: 'KS', color: FluentAvatarColor.lavender),
  (name: 'Charlotte Waltson', initials: 'CW', color: FluentAvatarColor.peach),
  (name: 'Elliot Woodward', initials: 'EW', color: FluentAvatarColor.seafoam),
];

Widget _indicator(BuildContext context) {
  List<Widget> members({required bool icon}) => <Widget>[
    for (final _IndicatorPerson person in _indicatorPeople.sublist(7))
      FluentAvatar(
        name: person.name,
        initials: person.initials,
        color: person.color,
      ),
    _IndicatorOverflow(people: _indicatorPeople.sublist(0, 7), icon: icon),
  ];

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10,
    children: <Widget>[
      FluentAvatarGroup(children: members(icon: false)),
      FluentAvatarGroup(children: members(icon: true)),
    ],
  );
}

/// `AvatarGroupPopover`: `FluentAvatarGroup` has no popover slot, so the
/// overflow indicator is an ordinary member that owns its own `FluentPopover`.
/// [icon] is upstream's `indicator` — the count, or the ellipsis glyph.
class _IndicatorOverflow extends StatefulWidget {
  const _IndicatorOverflow({required this.people, required this.icon});

  final List<_IndicatorPerson> people;
  final bool icon;

  @override
  State<_IndicatorOverflow> createState() => _IndicatorOverflowState();
}

class _IndicatorOverflowState extends State<_IndicatorOverflow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool value) => setState(() => _open = value),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        for (final _IndicatorPerson person in widget.people)
          FluentPersona(
            name: person.name,
            initials: person.initials,
            color: person.color,
          ),
      ],
    ),
    child: GestureDetector(
      onTap: () => setState(() => _open = true),
      child: FluentAvatar(
        color: FluentAvatarColor.overflow,
        initials: widget.icon ? null : '+${widget.people.length}',
        icon: widget.icon
            ? const Icon(FluentIcons.more_horizontal_20_regular)
            : null,
        name: widget.people
            .map((_IndicatorPerson person) => person.name)
            .join(', '),
      ),
    ),
  );
}
// #enddocregion components-avatargroup--indicator

// #docregion components-avatargroup--size-spread
typedef _SizeSpreadPerson = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_SizeSpreadPerson> _sizeSpreadPeople = <_SizeSpreadPerson>[
  (name: 'Johnie McConnell', initials: 'JM', color: FluentAvatarColor.platinum),
  (name: 'Allan Munger', initials: 'AM', color: FluentAvatarColor.lavender),
  (name: 'Erik Nason', initials: 'EN', color: FluentAvatarColor.steel),
  (name: 'Kristin Patterson', initials: 'KP', color: FluentAvatarColor.teal),
  (name: 'Daisy Phillips', initials: 'DP', color: FluentAvatarColor.seafoam),
  (name: 'Carole Poland', initials: 'CP', color: FluentAvatarColor.marigold),
  (
    name: 'Carlos Slattery',
    initials: 'CS',
    color: FluentAvatarColor.cornflower,
  ),
  (name: 'Robert Tolbert', initials: 'RT', color: FluentAvatarColor.platinum),
  (name: 'Kevin Sturgis', initials: 'KS', color: FluentAvatarColor.lavender),
  (name: 'Charlotte Waltson', initials: 'CW', color: FluentAvatarColor.peach),
  (name: 'Elliot Woodward', initials: 'EW', color: FluentAvatarColor.seafoam),
];

// Upstream's ladder is 16, 20, 24, 28, 32, 36, 40, 48, 56, 64, 72, 96, 120,
// 128 — every `FluentAvatarSize` plus one more, because Figma never draws the
// 128 variant, so the last row repeats 120.
const List<FluentAvatarSize> _sizeSpreadSizes = <FluentAvatarSize>[
  ...FluentAvatarSize.values,
  FluentAvatarSize.size120,
];

Widget _sizeSpread(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 10,
  children: <Widget>[
    for (final FluentAvatarSize size in _sizeSpreadSizes)
      FluentAvatarGroup(
        size: size,
        children: <Widget>[
          for (final _SizeSpreadPerson person in _sizeSpreadPeople.sublist(7))
            FluentAvatar(
              name: person.name,
              initials: person.initials,
              color: person.color,
              size: size,
            ),
          _SizeSpreadOverflow(
            people: _sizeSpreadPeople.sublist(0, 7),
            size: size,
          ),
        ],
      ),
  ],
);

/// `AvatarGroupPopover`: `FluentAvatarGroup` has no popover slot, so the
/// overflow indicator is an ordinary member that owns its own `FluentPopover`.
class _SizeSpreadOverflow extends StatefulWidget {
  const _SizeSpreadOverflow({required this.people, required this.size});

  final List<_SizeSpreadPerson> people;
  final FluentAvatarSize size;

  @override
  State<_SizeSpreadOverflow> createState() => _SizeSpreadOverflowState();
}

class _SizeSpreadOverflowState extends State<_SizeSpreadOverflow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    // "When size is less than 24, then icon will be used by default."
    final bool icon = widget.size.edge < 24;

    return FluentPopover(
      open: _open,
      onOpenChanged: (bool value) => setState(() => _open = value),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: <Widget>[
          for (final _SizeSpreadPerson person in widget.people)
            FluentPersona(
              name: person.name,
              initials: person.initials,
              color: person.color,
            ),
        ],
      ),
      child: GestureDetector(
        onTap: () => setState(() => _open = true),
        child: FluentAvatar(
          size: widget.size,
          color: FluentAvatarColor.overflow,
          initials: icon ? null : '+${widget.people.length}',
          icon: icon
              ? const Icon(FluentIcons.more_horizontal_20_regular)
              : null,
          name: widget.people
              .map((_SizeSpreadPerson person) => person.name)
              .join(', '),
        ),
      ),
    );
  }
}
// #enddocregion components-avatargroup--size-spread

// #docregion components-avatargroup--size-stack
typedef _SizeStackPerson = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_SizeStackPerson> _sizeStackPeople = <_SizeStackPerson>[
  (name: 'Johnie McConnell', initials: 'JM', color: FluentAvatarColor.platinum),
  (name: 'Allan Munger', initials: 'AM', color: FluentAvatarColor.lavender),
  (name: 'Erik Nason', initials: 'EN', color: FluentAvatarColor.steel),
  (name: 'Kristin Patterson', initials: 'KP', color: FluentAvatarColor.teal),
  (name: 'Daisy Phillips', initials: 'DP', color: FluentAvatarColor.seafoam),
  (name: 'Carole Poland', initials: 'CP', color: FluentAvatarColor.marigold),
  (
    name: 'Carlos Slattery',
    initials: 'CS',
    color: FluentAvatarColor.cornflower,
  ),
  (name: 'Robert Tolbert', initials: 'RT', color: FluentAvatarColor.platinum),
  (name: 'Kevin Sturgis', initials: 'KS', color: FluentAvatarColor.lavender),
  (name: 'Charlotte Waltson', initials: 'CW', color: FluentAvatarColor.peach),
  (name: 'Elliot Woodward', initials: 'EW', color: FluentAvatarColor.seafoam),
];

// Upstream's ladder is 16, 20, 24, 28, 32, 36, 40, 48, 56, 64, 72, 96, 120,
// 128 — every `FluentAvatarSize` plus one more, because Figma never draws the
// 128 variant, so the last row repeats 120.
const List<FluentAvatarSize> _sizeStackSizes = <FluentAvatarSize>[
  ...FluentAvatarSize.values,
  FluentAvatarSize.size120,
];

Widget _sizeStack(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 10,
  children: <Widget>[
    for (final FluentAvatarSize size in _sizeStackSizes)
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.stack,
        size: size,
        children: <Widget>[
          for (final _SizeStackPerson person in _sizeStackPeople.sublist(7))
            FluentAvatar(
              name: person.name,
              initials: person.initials,
              color: person.color,
              size: size,
            ),
          _SizeStackOverflow(
            people: _sizeStackPeople.sublist(0, 7),
            size: size,
          ),
        ],
      ),
  ],
);

/// `AvatarGroupPopover`: `FluentAvatarGroup` has no popover slot, so the
/// overflow indicator is an ordinary member that owns its own `FluentPopover`.
class _SizeStackOverflow extends StatefulWidget {
  const _SizeStackOverflow({required this.people, required this.size});

  final List<_SizeStackPerson> people;
  final FluentAvatarSize size;

  @override
  State<_SizeStackOverflow> createState() => _SizeStackOverflowState();
}

class _SizeStackOverflowState extends State<_SizeStackOverflow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    // "When size is less than 24, then icon will be used by default."
    final bool icon = widget.size.edge < 24;

    return FluentPopover(
      open: _open,
      onOpenChanged: (bool value) => setState(() => _open = value),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: <Widget>[
          for (final _SizeStackPerson person in widget.people)
            FluentPersona(
              name: person.name,
              initials: person.initials,
              color: person.color,
            ),
        ],
      ),
      child: GestureDetector(
        onTap: () => setState(() => _open = true),
        child: FluentAvatar(
          size: widget.size,
          color: FluentAvatarColor.overflow,
          initials: icon ? null : '+${widget.people.length}',
          icon: icon
              ? const Icon(FluentIcons.more_horizontal_20_regular)
              : null,
          name: widget.people
              .map((_SizeStackPerson person) => person.name)
              .join(', '),
        ),
      ),
    );
  }
}
// #enddocregion components-avatargroup--size-stack

// #docregion components-avatargroup--size-pie
typedef _SizePiePerson = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_SizePiePerson> _sizePiePeople = <_SizePiePerson>[
  (name: 'Johnie McConnell', initials: 'JM', color: FluentAvatarColor.platinum),
  (name: 'Allan Munger', initials: 'AM', color: FluentAvatarColor.lavender),
  (name: 'Erik Nason', initials: 'EN', color: FluentAvatarColor.steel),
  (name: 'Kristin Patterson', initials: 'KP', color: FluentAvatarColor.teal),
  (name: 'Daisy Phillips', initials: 'DP', color: FluentAvatarColor.seafoam),
  (name: 'Carole Poland', initials: 'CP', color: FluentAvatarColor.marigold),
  (
    name: 'Carlos Slattery',
    initials: 'CS',
    color: FluentAvatarColor.cornflower,
  ),
  (name: 'Robert Tolbert', initials: 'RT', color: FluentAvatarColor.platinum),
  (name: 'Kevin Sturgis', initials: 'KS', color: FluentAvatarColor.lavender),
  (name: 'Charlotte Waltson', initials: 'CW', color: FluentAvatarColor.peach),
  (name: 'Elliot Woodward', initials: 'EW', color: FluentAvatarColor.seafoam),
];

// Upstream's ladder is 16, 20, 24, 28, 32, 36, 40, 48, 56, 64, 72, 96, 120,
// 128 — every `FluentAvatarSize` plus one more, because Figma never draws the
// 128 variant, so the last row repeats 120.
const List<FluentAvatarSize> _sizePieSizes = <FluentAvatarSize>[
  ...FluentAvatarSize.values,
  FluentAvatarSize.size120,
];

// A pie partition sends every name to the `AvatarGroupPopover`, and upstream
// draws no trigger beside a pie — so each row is exactly the first three names.
// `FluentAvatarGroup` cuts the pie from its first three children.
Widget _sizePie(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 10,
  children: <Widget>[
    for (final FluentAvatarSize size in _sizePieSizes)
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.pie,
        size: size,
        children: <Widget>[
          for (final _SizePiePerson person in _sizePiePeople.sublist(0, 3))
            FluentAvatar(
              name: person.name,
              initials: person.initials,
              color: person.color,
              size: size,
            ),
        ],
      ),
  ],
);
// #enddocregion components-avatargroup--size-pie

// #docregion components-avatargroup--tooltip
typedef _TooltipPerson = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_TooltipPerson> _tooltipPeople = <_TooltipPerson>[
  (name: 'Johnie McConnell', initials: 'JM', color: FluentAvatarColor.platinum),
  (name: 'Allan Munger', initials: 'AM', color: FluentAvatarColor.lavender),
  (name: 'Erik Nason', initials: 'EN', color: FluentAvatarColor.steel),
  (name: 'Kristin Patterson', initials: 'KP', color: FluentAvatarColor.teal),
  (name: 'Daisy Phillips', initials: 'DP', color: FluentAvatarColor.seafoam),
  (name: 'Carole Poland', initials: 'CP', color: FluentAvatarColor.marigold),
  (
    name: 'Carlos Slattery',
    initials: 'CS',
    color: FluentAvatarColor.cornflower,
  ),
  (name: 'Robert Tolbert', initials: 'RT', color: FluentAvatarColor.platinum),
  (name: 'Kevin Sturgis', initials: 'KS', color: FluentAvatarColor.lavender),
  (name: 'Charlotte Waltson', initials: 'CW', color: FluentAvatarColor.peach),
  (name: 'Elliot Woodward', initials: 'EW', color: FluentAvatarColor.seafoam),
];

Widget _tooltip(BuildContext context) => FluentAvatarGroup(
  children: <Widget>[
    for (final _TooltipPerson person in _tooltipPeople.sublist(7))
      FluentAvatar(
        name: person.name,
        initials: person.initials,
        color: person.color,
      ),
    _TooltipOverflow(people: _tooltipPeople.sublist(0, 7)),
  ],
);

/// `AvatarGroupPopover`: `FluentAvatarGroup` has no popover slot, so the
/// overflow indicator is an ordinary member that owns its own `FluentPopover`
/// and — upstream's `tooltip={{ content, relationship: 'label' }}` — its own
/// `FluentTooltip`.
class _TooltipOverflow extends StatefulWidget {
  const _TooltipOverflow({required this.people});

  final List<_TooltipPerson> people;

  @override
  State<_TooltipOverflow> createState() => _TooltipOverflowState();
}

class _TooltipOverflowState extends State<_TooltipOverflow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => FluentPopover(
    open: _open,
    onOpenChanged: (bool value) => setState(() => _open = value),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        for (final _TooltipPerson person in widget.people)
          FluentPersona(
            name: person.name,
            initials: person.initials,
            color: person.color,
          ),
      ],
    ),
    child: FluentTooltip(
      content: const Text('My custom tooltip'),
      semanticLabel: 'My custom tooltip',
      child: GestureDetector(
        onTap: () => setState(() => _open = true),
        child: FluentAvatar(
          color: FluentAvatarColor.overflow,
          initials: '+${widget.people.length}',
          name: 'My custom tooltip',
        ),
      ),
    ),
  );
}

// #enddocregion components-avatargroup--tooltip
