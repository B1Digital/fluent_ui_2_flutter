import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentNav].
final StorySection navStories = StorySection(
  component: 'Nav',
  description:
      'A vertical side navigation: an optional product header, flat '
      'destinations, and collapsible categories of sub-items. Selection and the '
      'open set are each either the nav\'s own or the caller\'s — pass the '
      'value to take it over, leave it out and the nav keeps it. The selected '
      'row raises a brand-coloured indicator in a column that is reserved on '
      'every row, so moving the selection never shifts a label sideways.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A whole nav in one piece: product header, a rule, three flat '
          'destinations and a category that opens onto its sub-items. It owns '
          'its own selection, seeded by defaultSelectedValue.',
      knobs: const [
        OptionKnob<FluentNavSize>(
          label: 'Size',
          id: 'size',
          initial: FluentNavSize.medium,
          options: FluentNavSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'App item', id: 'appItem', initial: true),
        BoolKnob(label: 'Leading icons', id: 'icons', initial: true),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Categories',
      description:
          'A category header carries a chevron and reveals its sub-items on '
          'press; defaultOpenCategories seeds which are open. A closed '
          'category can hold the selection itself — an open one hands the '
          'indicator to whichever sub-item is current. With the header '
          'focused, Right opens and Left closes, mirrored under RTL.',
      builder: _categoriesBuilder,
    ),
    const Story(
      name: 'Density',
      description:
          'The size axis, side by side. Medium is 40-high rows under a 48-high '
          'app item; small is 32 and 40. A sub-item stays 32 in both, because '
          'Figma gives it no size axis at all.',
      builder: _densityBuilder,
    ),
    const Story(
      name: 'Secondary actions',
      description:
          'A row can carry trailing controls. They live inside the row but '
          'outside its press target, so invoking one runs its own callback '
          'without moving the selection.',
      builder: _secondaryActionsBuilder,
    ),
    const Story(
      name: 'Controlled',
      description:
          'Pass selectedValue and openCategories and the caller owns both: '
          'pressing a row only reports the value it wants to move to, and '
          'nothing changes until the caller applies it. The buttons drive the '
          'same two pieces of state as the rows do.',
      builder: _controlledBuilder,
    ),
    const Story(
      name: 'App item',
      description:
          'The product header. With onPressed it is a real button; without '
          'one it is static — no hover, no press, no focus — which is not the '
          'same as disabled, and still paints the rest tokens.',
      builder: _appItemBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabled is a real state, not a fade: the row refuses focus, '
          'reports no hover or press, and cannot be selected by pointer or '
          'keyboard. A disabled category cannot be opened either. Its '
          'neighbours stay live.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Restyled',
      description:
          'FluentNavItemTheme restyles every row under it in one place, '
          'per-property: this one drops the resting fill, rounds the surface '
          'and grows the selection indicator, and every other resolved value — '
          'the type ramp, the padding, the disabled tokens — is untouched.',
      builder: _restyledBuilder,
    ),
  ],
);

String _sizeLabel(FluentNavSize value) => value.name;

/// The destinations every story navigates between, so the page reads as one
/// product rather than eight unrelated fragments.
const _destinations = <(String, IconData, String)>[
  ('home', FluentIcons.home_20_regular, 'Home'),
  ('mail', FluentIcons.mail_20_regular, 'Inbox'),
  ('calendar', FluentIcons.calendar_ltr_20_regular, 'Calendar'),
];

/// The sub-items of the `reports` category, used by several stories.
const _reports = <(String, String)>[
  ('weekly', 'Weekly'),
  ('quarterly', 'Quarterly'),
  ('archive', 'Archive'),
];

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final size = knobs.get<FluentNavSize>('size', FluentNavSize.medium);
  final appItem = knobs.get<bool>('appItem', true);
  final icons = knobs.get<bool>('icons', true);

  return _NavFrame(
    child: FluentNav(
      size: size,
      semanticLabel: 'Main',
      defaultSelectedValue: 'home',
      defaultOpenCategories: const <Object>{'reports'},
      children: <Widget>[
        if (appItem)
          FluentNavAppItem(
            icon: icons
                ? Icon(
                    size == FluentNavSize.small
                        ? FluentIcons.person_circle_24_regular
                        : FluentIcons.person_circle_32_regular,
                  )
                : null,
            onPressed: () {},
            child: const Text('Contoso'),
          ),
        if (appItem) const FluentNavDivider(),
        for (final (value, icon, label) in _destinations)
          FluentNavItem(
            value: value,
            icon: icons ? Icon(icon) : null,
            child: Text(label),
          ),
        FluentNavCategory(
          value: 'reports',
          icon: icons
              ? const Icon(FluentIcons.chart_multiple_20_regular)
              : null,
          child: const Text('Reports'),
          children: <Widget>[
            for (final (value, label) in _reports)
              FluentNavSubItem(value: value, child: Text(label)),
          ],
        ),
      ],
    ),
  );
}

Widget _categoriesBuilder(BuildContext context) => const _Cases(
  children: <(String, Widget)>[
    (
      'one category seeded open, the other closed and selected',
      _NavFrame(
        child: FluentNav(
          defaultSelectedValue: 'people',
          defaultOpenCategories: <Object>{'reports'},
          children: <Widget>[
            FluentNavItem(
              value: 'home',
              icon: Icon(FluentIcons.home_20_regular),
              child: Text('Home'),
            ),
            FluentNavCategory(
              value: 'reports',
              icon: Icon(FluentIcons.chart_multiple_20_regular),
              child: Text('Reports'),
              children: <Widget>[
                FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
                FluentNavSubItem(value: 'quarterly', child: Text('Quarterly')),
              ],
            ),
            FluentNavCategory(
              value: 'people',
              icon: Icon(FluentIcons.people_team_20_regular),
              child: Text('People'),
              children: <Widget>[
                FluentNavSubItem(value: 'directory', child: Text('Directory')),
                FluentNavSubItem(value: 'teams', child: Text('Teams')),
              ],
            ),
          ],
        ),
      ),
    ),
  ],
);

Widget _densityBuilder(BuildContext context) => const _Cases(
  axis: Axis.horizontal,
  children: <(String, Widget)>[
    ('medium — 40-high rows, 48-high app item', _DensityNav()),
    (
      'small — 32-high rows, 40-high app item',
      _DensityNav(size: FluentNavSize.small),
    ),
  ],
);

Widget _secondaryActionsBuilder(BuildContext context) =>
    const _SecondaryActionsNav();

Widget _controlledBuilder(BuildContext context) => const _ControlledNav();

Widget _appItemBuilder(BuildContext context) => const _Cases(
  axis: Axis.horizontal,
  children: <(String, Widget)>[
    (
      'pressable — hovers, presses and takes focus',
      _NavFrame(
        child: FluentNav(
          children: <Widget>[
            FluentNavAppItem(
              icon: Icon(FluentIcons.person_circle_32_regular),
              onPressed: _noop,
              child: Text('Contoso'),
            ),
            FluentNavDivider(),
            FluentNavItem(
              value: 'home',
              icon: Icon(FluentIcons.home_20_regular),
              child: Text('Home'),
            ),
          ],
        ),
      ),
    ),
    (
      'static — no onPressed, and still the rest tokens',
      _NavFrame(
        child: FluentNav(
          children: <Widget>[
            FluentNavAppItem(
              icon: Icon(FluentIcons.person_circle_32_regular),
              child: Text('Contoso'),
            ),
            FluentNavDivider(),
            FluentNavItem(
              value: 'home',
              icon: Icon(FluentIcons.home_20_regular),
              child: Text('Home'),
            ),
          ],
        ),
      ),
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => const _NavFrame(
  child: FluentNav(
    defaultSelectedValue: 'home',
    defaultOpenCategories: <Object>{'reports'},
    children: <Widget>[
      FluentNavItem(
        value: 'home',
        icon: Icon(FluentIcons.home_20_regular),
        child: Text('Home'),
      ),
      FluentNavItem(
        value: 'mail',
        enabled: false,
        icon: Icon(FluentIcons.mail_20_regular),
        child: Text('Inbox — disabled'),
      ),
      FluentNavCategory(
        value: 'reports',
        enabled: false,
        icon: Icon(FluentIcons.chart_multiple_20_regular),
        child: Text('Reports — disabled'),
        children: <Widget>[
          FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
        ],
      ),
      FluentNavCategory(
        value: 'people',
        icon: Icon(FluentIcons.people_team_20_regular),
        child: Text('People'),
        children: <Widget>[
          FluentNavSubItem(value: 'directory', child: Text('Directory')),
          FluentNavSubItem(
            value: 'teams',
            enabled: false,
            child: Text('Teams — disabled'),
          ),
        ],
      ),
    ],
  ),
);

Widget _restyledBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentNavItemTheme(
    style: FluentNavItemStyle(
      backgroundColor: FluentStateColor.tokens(
        rest: colors.transparentBackground,
        hover: colors.neutralBackground1Hover,
        pressed: colors.neutralBackground1Pressed,
        selected: colors.brandBackground2,
        disabled: colors.transparentBackground,
      ),
      borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
        FluentRadius.allCircular,
      ),
      indicatorSize: const WidgetStatePropertyAll<Size?>(
        Size(FluentSize.size40, FluentSize.size240),
      ),
    ),
    child: const _NavFrame(
      child: FluentNav(
        defaultSelectedValue: 'weekly',
        defaultOpenCategories: <Object>{'reports'},
        children: <Widget>[
          FluentNavItem(
            value: 'home',
            icon: Icon(FluentIcons.home_20_regular),
            child: Text('Home'),
          ),
          FluentNavCategory(
            value: 'reports',
            icon: Icon(FluentIcons.chart_multiple_20_regular),
            child: Text('Reports'),
            children: <Widget>[
              FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
              FluentNavSubItem(value: 'quarterly', child: Text('Quarterly')),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Nothing to do — the app item only needs *an* action to stop being static.
void _noop() {}

/// One nav at each density, so the two can be compared row for row.
class _DensityNav extends StatelessWidget {
  const _DensityNav({this.size = FluentNavSize.medium});

  /// The density under demonstration.
  final FluentNavSize size;

  @override
  Widget build(BuildContext context) => _NavFrame(
    child: FluentNav(
      size: size,
      defaultSelectedValue: 'home',
      defaultOpenCategories: const <Object>{'reports'},
      children: <Widget>[
        FluentNavAppItem(
          icon: Icon(
            size == FluentNavSize.small
                ? FluentIcons.person_circle_24_regular
                : FluentIcons.person_circle_32_regular,
          ),
          onPressed: _noop,
          child: const Text('Contoso'),
        ),
        const FluentNavDivider(),
        for (final (value, icon, label) in _destinations)
          FluentNavItem(value: value, icon: Icon(icon), child: Text(label)),
        const FluentNavCategory(
          value: 'reports',
          icon: Icon(FluentIcons.chart_multiple_20_regular),
          child: Text('Reports'),
          children: <Widget>[
            FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
          ],
        ),
      ],
    ),
  );
}

/// Rows with trailing controls, and a running note of what each one did — the
/// point being that pressing an action never moves the selection.
class _SecondaryActionsNav extends StatefulWidget {
  const _SecondaryActionsNav();

  @override
  State<_SecondaryActionsNav> createState() => _SecondaryActionsNavState();
}

class _SecondaryActionsNavState extends State<_SecondaryActionsNav> {
  String? _last;
  Object _selected = 'home';

  List<Widget> _actions(String label) => <Widget>[
    FluentButton.icon(
      icon: const Icon(FluentIcons.pin_20_regular),
      semanticLabel: 'Pin $label',
      size: FluentButtonSize.small,
      appearance: FluentButtonAppearance.transparent,
      onPressed: () => setState(() => _last = 'Pinned $label'),
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.more_horizontal_20_regular),
      semanticLabel: 'More options for $label',
      size: FluentButtonSize.small,
      appearance: FluentButtonAppearance.transparent,
      onPressed: () => setState(() => _last = 'Opened the $label menu'),
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: <Widget>[
      _NavFrame(
        child: FluentNav(
          selectedValue: _selected,
          onSelect: (value) => setState(() => _selected = value),
          defaultOpenCategories: const <Object>{'reports'},
          children: <Widget>[
            for (final (value, icon, label) in _destinations)
              FluentNavItem(
                value: value,
                icon: Icon(icon),
                secondaryActions: _actions(label),
                child: Text(label),
              ),
            FluentNavCategory(
              value: 'reports',
              icon: const Icon(FluentIcons.chart_multiple_20_regular),
              child: const Text('Reports'),
              children: <Widget>[
                FluentNavSubItem(
                  value: 'weekly',
                  secondaryActions: _actions('Weekly'),
                  child: const Text('Weekly'),
                ),
              ],
            ),
          ],
        ),
      ),
      _Caption('Selected: $_selected — last action: ${_last ?? 'none'}'),
    ],
  );
}

/// A controlled nav: both the selection and the open set live here, not in the
/// widget.
class _ControlledNav extends StatefulWidget {
  const _ControlledNav();

  @override
  State<_ControlledNav> createState() => _ControlledNavState();
}

class _ControlledNavState extends State<_ControlledNav> {
  Object? _selected = 'home';
  Set<Object> _open = <Object>{};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.s,
        children: <Widget>[
          FluentButton(
            onPressed: () => setState(() {
              _selected = 'quarterly';
              _open = <Object>{'reports'};
            }),
            child: const Text('Go to Quarterly'),
          ),
          FluentButton(
            onPressed: () => setState(() => _open = <Object>{'reports'}),
            child: const Text('Expand'),
          ),
          FluentButton(
            onPressed: () => setState(() => _open = <Object>{}),
            child: const Text('Collapse'),
          ),
        ],
      ),
      _NavFrame(
        child: FluentNav(
          selectedValue: _selected,
          onSelect: (value) => setState(() => _selected = value),
          openCategories: _open,
          // A new set every time: the nav compares open sets by value, and a
          // set mutated in place can never differ from itself.
          onOpenChange: (next) => setState(() => _open = <Object>{...next}),
          children: <Widget>[
            const FluentNavItem(
              value: 'home',
              icon: Icon(FluentIcons.home_20_regular),
              child: Text('Home'),
            ),
            FluentNavCategory(
              value: 'reports',
              icon: const Icon(FluentIcons.chart_multiple_20_regular),
              child: const Text('Reports'),
              children: <Widget>[
                for (final (value, label) in _reports)
                  FluentNavSubItem(value: value, child: Text(label)),
              ],
            ),
          ],
        ),
      ),
      _Caption(
        'selectedValue: $_selected — openCategories: '
        '${_open.isEmpty ? 'none' : _open.join(', ')}',
      ),
    ],
  );
}

/// The 260-wide column a Fluent nav is designed to sit in. A nav fills the
/// width it is given, so without this every story would stretch to the canvas.
class _NavFrame extends StatelessWidget {
  const _NavFrame({required this.child});

  /// The nav.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FluentTheme.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.neutralBackground4,
        borderRadius: FluentRadius.allMedium,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FluentSpacing.s),
        child: SizedBox(width: 260, child: child),
      ),
    );
  }
}

/// A quiet line under an example, for reporting live state.
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  /// What to say.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Text(
      text,
      style: theme.typography.caption1.copyWith(
        color: theme.colors.neutralForeground3,
      ),
    );
  }
}

/// Captioned cases, stacked down the page or laid out across it.
class _Cases extends StatelessWidget {
  const _Cases({required this.children, this.axis = Axis.vertical});

  /// Caption and example, in order.
  final List<(String, Widget)> children;

  /// Whether the cases run down the page or across it.
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final cases = <Widget>[
      for (final (caption, child) in children)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.xs,
          children: <Widget>[_Caption(caption), child],
        ),
    ];
    return axis == Axis.vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FluentSpacing.xl,
            children: cases,
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FluentSpacing.xl,
            children: cases,
          );
  }
}
