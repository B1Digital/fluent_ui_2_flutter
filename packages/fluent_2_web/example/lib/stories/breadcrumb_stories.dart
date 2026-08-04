import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentBreadcrumb].
final StorySection breadcrumbStories = StorySection(
  component: 'Breadcrumb',
  description:
      'A trail of subtle buttons with a chevron between them, showing where a '
      'page sits in a hierarchy. The last crumb is the current page: semibold, '
      'chevron-less and inert. A trail too long to show whole folds its middle '
      'behind an overflow trigger that opens a popup.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A three-level trail with the current page last. Size, leading icons '
          'and the disabled state are live.',
      knobs: const [
        OptionKnob<FluentBreadcrumbSize>(
          label: 'Size',
          id: 'size',
          initial: FluentBreadcrumbSize.medium,
          options: FluentBreadcrumbSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'Leading icons', id: 'icons'),
        BoolKnob(label: 'Disable the middle crumb', id: 'disabled'),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Three heights — 24, 32 and 40 — each with its own type ramp, its own '
          'chevron (12 / 16 / 20) and its own leading inset.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'With icons',
      description:
          'Any crumb may lead with an icon. It tightens that crumb’s '
          'leading inset, and it is the only part that takes a brand colour on '
          'hover — the label deliberately holds at its rest token.',
      builder: _iconsBuilder,
    ),
    const Story(
      name: 'Current page and disabled crumbs',
      description:
          'The last crumb is the current page: it never fires its callback, '
          'carries no chevron and refuses focus. A disabled crumb is a separate '
          'state that stops responding entirely while the chevron beside it '
          'keeps its colour.',
      builder: _statesBuilder,
    ),
    Story(
      name: 'Overflow',
      description:
          'Past the display limit the root stays pinned, the tail stays '
          'visible and the middle folds behind a trigger. Press it — or focus '
          'it and press Down — to open the popup; Escape closes it.',
      knobs: const [
        NumberKnob(
          label: 'Max displayed items',
          id: 'max',
          initial: 3,
          min: 1,
          max: 6,
        ),
        OptionKnob<FluentBreadcrumbSize>(
          label: 'Size',
          id: 'size',
          initial: FluentBreadcrumbSize.medium,
          options: FluentBreadcrumbSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: _overflowBuilder,
    ),
    const Story(
      name: 'With a tooltip',
      description:
          'A crumb clipped to one ellipsised line can still be read in full: '
          'the label slot takes any widget, so a FluentTooltip wraps it and '
          'hover or keyboard focus reveals the whole path segment.',
      builder: _tooltipBuilder,
    ),
    const Story(
      name: 'Navigating',
      description:
          'What the component is for: pressing a crumb makes it the current '
          'page and drops everything after it.',
      builder: _navigatingBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — the size defaults, a FluentBreadcrumbTheme '
          'over a subtree (which reaches the overflow popup too), then the '
          'widget style, which is merged last and wins.',
      builder: _stylingBuilder,
    ),
  ],
);

String _sizeLabel(FluentBreadcrumbSize value) => value.name;

/// The path every story without its own data walks.
const List<String> _path = <String>[
  'Home',
  'Marketing',
  'Campaigns',
  'Autumn 2026',
  'Assets',
];

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final icons = knobs.get<bool>('icons', false);
  final disabled = knobs.get<bool>('disabled', false);

  return FluentBreadcrumb(
    size: knobs.get<FluentBreadcrumbSize>('size', FluentBreadcrumbSize.medium),
    semanticLabel: 'Example breadcrumb',
    items: <FluentBreadcrumbItem>[
      FluentBreadcrumbItem(
        label: const Text('Home'),
        icon: icons ? const Icon(FluentIcons.home_20_regular) : null,
        onPressed: () {},
      ),
      FluentBreadcrumbItem(
        label: const Text('Marketing'),
        icon: icons ? const Icon(FluentIcons.folder_20_regular) : null,
        enabled: !disabled,
        onPressed: () {},
      ),
      FluentBreadcrumbItem(
        label: const Text('Campaigns'),
        icon: icons ? const Icon(FluentIcons.document_20_regular) : null,
      ),
    ],
  );
}

Widget _sizesBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    for (final size in FluentBreadcrumbSize.values)
      (
        size.name,
        FluentBreadcrumb(
          size: size,
          items: <FluentBreadcrumbItem>[
            FluentBreadcrumbItem(
              label: const Text('Home'),
              icon: const Icon(FluentIcons.home_20_regular),
              onPressed: () {},
            ),
            FluentBreadcrumbItem(
              label: const Text('Marketing'),
              onPressed: () {},
            ),
            const FluentBreadcrumbItem(label: Text('Campaigns')),
          ],
        ),
      ),
  ],
);

Widget _iconsBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    (
      'an icon on every crumb — hover one to move its glyph, not its label',
      FluentBreadcrumb(
        items: <FluentBreadcrumbItem>[
          FluentBreadcrumbItem(
            label: const Text('Home'),
            icon: const Icon(FluentIcons.home_20_regular),
            onPressed: () {},
          ),
          FluentBreadcrumbItem(
            label: const Text('Marketing'),
            icon: const Icon(FluentIcons.folder_20_regular),
            onPressed: () {},
          ),
          const FluentBreadcrumbItem(
            label: Text('Campaigns'),
            icon: Icon(FluentIcons.document_20_regular),
          ),
        ],
      ),
    ),
    (
      'only the root — the rest keep the symmetric inset',
      FluentBreadcrumb(
        items: <FluentBreadcrumbItem>[
          FluentBreadcrumbItem(
            label: const Text('Home'),
            icon: const Icon(FluentIcons.home_20_regular),
            onPressed: () {},
          ),
          FluentBreadcrumbItem(
            label: const Text('Marketing'),
            onPressed: () {},
          ),
          const FluentBreadcrumbItem(label: Text('Campaigns')),
        ],
      ),
    ),
  ],
);

Widget _statesBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    (
      'the last crumb is the current page',
      FluentBreadcrumb(
        items: <FluentBreadcrumbItem>[
          FluentBreadcrumbItem(label: const Text('Home'), onPressed: () {}),
          FluentBreadcrumbItem(
            label: const Text('Marketing'),
            onPressed: () {},
          ),
          // A callback here is never called: the current page is a marker.
          FluentBreadcrumbItem(
            label: const Text('Campaigns'),
            onPressed: () {},
          ),
        ],
      ),
    ),
    (
      'a disabled crumb in the middle',
      FluentBreadcrumb(
        items: <FluentBreadcrumbItem>[
          FluentBreadcrumbItem(
            label: const Text('Home'),
            icon: const Icon(FluentIcons.home_20_regular),
            onPressed: () {},
          ),
          FluentBreadcrumbItem(
            label: const Text('Marketing'),
            icon: const Icon(FluentIcons.folder_20_regular),
            enabled: false,
            onPressed: () {},
          ),
          const FluentBreadcrumbItem(label: Text('Campaigns')),
        ],
      ),
    ),
    (
      'a crumb with no callback is inert without being disabled',
      FluentBreadcrumb(
        items: <FluentBreadcrumbItem>[
          FluentBreadcrumbItem(label: const Text('Home'), onPressed: () {}),
          const FluentBreadcrumbItem(label: Text('Marketing')),
          const FluentBreadcrumbItem(label: Text('Campaigns')),
        ],
      ),
    ),
  ],
);

Widget _overflowBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final max = knobs.get<double>('max', 3).round();

  return FluentBreadcrumb(
    size: knobs.get<FluentBreadcrumbSize>('size', FluentBreadcrumbSize.medium),
    maxDisplayedItems: max,
    items: <FluentBreadcrumbItem>[
      for (var i = 0; i < _path.length; i++)
        FluentBreadcrumbItem(
          label: Text(_path[i]),
          icon: i == 0 ? const Icon(FluentIcons.home_20_regular) : null,
          onPressed: () {},
        ),
    ],
  );
}

Widget _tooltipBuilder(BuildContext context) => _Cases(
  children: const <(String, Widget)>[
    (
      'each label clipped to 96 wide, with the full text in a tooltip',
      _TooltipTrail(),
    ),
  ],
);

Widget _navigatingBuilder(BuildContext context) => const _NavigatingTrail();

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  final trail = <FluentBreadcrumbItem>[
    for (var i = 0; i < _path.length; i++)
      FluentBreadcrumbItem(label: Text(_path[i]), onPressed: () {}),
  ];

  return _Cases(
    children: <(String, Widget)>[
      ('the size defaults', FluentBreadcrumb(items: trail)),
      (
        'a subtree theme — square corners and a brand chevron, which the '
            'overflow popup inherits as well',
        FluentBreadcrumbTheme(
          style: FluentBreadcrumbStyle.from(
            borderRadius: BorderRadius.zero,
            separatorColor: colors.brandForeground1,
            surfaceColor: colors.neutralBackground3,
          ),
          child: FluentBreadcrumb(maxDisplayedItems: 3, items: trail),
        ),
      ),
      (
        'the widget style, merged last',
        FluentBreadcrumbTheme(
          style: FluentBreadcrumbStyle.from(
            borderRadius: BorderRadius.zero,
            separatorColor: colors.brandForeground1,
          ),
          child: FluentBreadcrumb(
            style: FluentBreadcrumbStyle.from(
              borderRadius: FluentRadius.allLarge,
              foregroundColor: colors.brandForeground1,
            ),
            items: trail,
          ),
        ),
      ),
    ],
  );
}

/// A trail whose labels are clipped, each wrapped in a [FluentTooltip].
///
/// The tooltip goes in the label slot rather than around the crumb, because the
/// crumb itself is built by [FluentBreadcrumb] from data.
class _TooltipTrail extends StatelessWidget {
  const _TooltipTrail();

  static const List<String> _long = <String>[
    'Marketing and communications',
    'Autumn 2026 product campaign',
    'Approved brand assets',
  ];

  @override
  Widget build(BuildContext context) => FluentBreadcrumb(
    items: <FluentBreadcrumbItem>[
      for (var i = 0; i < _long.length; i++)
        FluentBreadcrumbItem(
          label: FluentTooltip(
            content: Text(_long[i]),
            semanticLabel: _long[i],
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(_long[i]),
            ),
          ),
          semanticLabel: _long[i],
          onPressed: i == _long.length - 1 ? null : () {},
        ),
    ],
  );
}

/// A trail that really navigates: pressing a crumb drops everything after it.
class _NavigatingTrail extends StatefulWidget {
  const _NavigatingTrail();

  @override
  State<_NavigatingTrail> createState() => _NavigatingTrailState();
}

class _NavigatingTrailState extends State<_NavigatingTrail> {
  List<String> _here = _path;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: <Widget>[
        FluentBreadcrumb(
          maxDisplayedItems: 4,
          semanticLabel: 'Folder path',
          items: <FluentBreadcrumbItem>[
            for (var i = 0; i < _here.length; i++)
              FluentBreadcrumbItem(
                label: Text(_here[i]),
                icon: i == 0 ? const Icon(FluentIcons.home_20_regular) : null,
                onPressed: () =>
                    setState(() => _here = _path.sublist(0, i + 1)),
              ),
          ],
        ),
        Text(
          'Current page: ${_here.last}',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
        FluentButton(
          onPressed: _here.length == _path.length
              ? null
              : () => setState(() => _here = _path),
          child: const Text('Back to the full path'),
        ),
      ],
    );
  }
}

/// Stacked cases under a caption, so several trails can be compared at once.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxl,
      children: <Widget>[
        for (final (caption, child) in children)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: FluentSpacing.xs,
            children: <Widget>[
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
