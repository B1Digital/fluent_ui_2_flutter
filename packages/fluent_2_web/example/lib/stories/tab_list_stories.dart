import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentTabList] and [FluentTab].
final StorySection tabListStories = StorySection(
  component: 'TabList',
  description:
      'A row or column of tabs where exactly one is selected. The list owns the '
      'selection, the keyboard handling and the indicator bar — a tab on its '
      'own is inert — and the bar animates from the outgoing tab to the '
      'incoming one as a single transform.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A horizontal transparent list of three tabs. Every design axis is a '
          'knob, so one control shows how orientation, size and appearance '
          'change the same list.',
      knobs: const [
        OptionKnob<FluentTabAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentTabAppearance.transparent,
          options: FluentTabAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentTabSize>(
          label: 'Size',
          id: 'size',
          initial: FluentTabSize.medium,
          options: FluentTabSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentTabOrientation>(
          label: 'Orientation',
          id: 'orientation',
          initial: FluentTabOrientation.horizontal,
          options: FluentTabOrientation.values,
          labelOf: _orientationLabel,
        ),
        BoolKnob(label: 'Leading icon', id: 'icon'),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Appearances',
      description:
          'The four fill treatments. The two flat ones butt their tabs together '
          'and show selection with the indicator bar; the two pills space theirs '
          'out, drop the bar entirely and carry the selection in the fill.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Medium and small, flat and pill. Only the small pill steps down the '
          'type ramp to caption1 and its icon slot to 16; a small flat tab keeps '
          'body1 and shrinks by padding alone.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Orientation',
      description:
          'Horizontal runs the indicator along the bottom edge, vertical along '
          'the leading edge — and the arrow keys follow the axis, so a vertical '
          'list answers up and down rather than left and right.',
      builder: _orientationBuilder,
    ),
    const Story(
      name: 'With icon',
      description:
          'A leading icon beside the label. The glyph does not follow the text: '
          'on every selected tab but the filled pill it takes the compound brand '
          'token while the label stays neutral.',
      builder: _withIconBuilder,
    ),
    const Story(
      name: 'Icon only',
      description:
          'Omit the label and the tab becomes a square icon slot. It has no text '
          'to announce, so each one carries a semanticLabel instead.',
      builder: _iconOnlyBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabled is a real state, not a fade: the tab refuses focus, reports '
          'no hover or press, is stepped over by the arrow keys and cannot be '
          'selected. A null onSelect disables the whole list the same way.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Keyboard',
      description:
          'Click a tab, then use the arrow keys: Fluent moves the selection '
          'rather than only the focus, Home and End jump to the ends, and the '
          'ends do not wrap. Turn on RTL above to see the horizontal arrows '
          'mirror.',
      builder: _keyboardBuilder,
    ),
    const Story(
      name: 'With panels',
      description:
          'The list reports a selection; the panel below it is the caller\'s. '
          'This is the whole pattern — one piece of state driving both the tab '
          'list and the content under it.',
      builder: _panelsBuilder,
    ),
  ],
);

String _appearanceLabel(FluentTabAppearance value) => value.name;

String _sizeLabel(FluentTabSize value) => value.name;

String _orientationLabel(FluentTabOrientation value) => value.name;

/// The sections every story tabs between, so the page reads as one document.
const _items = <(String, String, IconData)>[
  ('home', 'Home', FluentIcons.home_20_regular),
  ('pages', 'Pages', FluentIcons.document_20_regular),
  ('documents', 'Documents', FluentIcons.folder_20_regular),
];

/// Five sections, so Home and End have somewhere to jump to.
const _longer = <(String, String, IconData)>[
  ('home', 'Home', FluentIcons.home_20_regular),
  ('pages', 'Pages', FluentIcons.document_20_regular),
  ('documents', 'Documents', FluentIcons.folder_20_regular),
  ('people', 'People', FluentIcons.people_20_regular),
  ('settings', 'Settings', FluentIcons.settings_20_regular),
];

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return _Tabs(
    appearance: knobs.get<FluentTabAppearance>(
      'appearance',
      FluentTabAppearance.transparent,
    ),
    size: knobs.get<FluentTabSize>('size', FluentTabSize.medium),
    orientation: knobs.get<FluentTabOrientation>(
      'orientation',
      FluentTabOrientation.horizontal,
    ),
    icons: knobs.get<bool>('icon', false),
    enabled: !knobs.get<bool>('disabled', false),
  );
}

Widget _appearancesBuilder(BuildContext context) => const _Cases(
  children: [
    ('transparent — no fill, indicator only', _Tabs()),
    (
      'subtle — a neutral fill on hover and press',
      _Tabs(appearance: FluentTabAppearance.subtle),
    ),
    (
      'filledCircular — a brand pill, no indicator',
      _Tabs(appearance: FluentTabAppearance.filledCircular),
    ),
    (
      'subtleCircular — a light brand pill with a brand outline',
      _Tabs(appearance: FluentTabAppearance.subtleCircular),
    ),
  ],
);

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('medium flat — 44 high, body1', _Tabs()),
    ('small flat — 32 high, still body1', _Tabs(size: FluentTabSize.small)),
    (
      'medium pill — 32 high, body1',
      _Tabs(appearance: FluentTabAppearance.filledCircular),
    ),
    (
      'small pill — 24 high, caption1 and a 16 icon slot',
      _Tabs(
        appearance: FluentTabAppearance.filledCircular,
        size: FluentTabSize.small,
        icons: true,
      ),
    ),
  ],
);

Widget _orientationBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'horizontal — indicator on the bottom edge, left and right arrows',
      _Tabs(),
    ),
    (
      'vertical — indicator on the leading edge, up and down arrows',
      _Tabs(orientation: FluentTabOrientation.vertical),
    ),
  ],
);

Widget _withIconBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'flat — the selected glyph goes compound brand, the label stays neutral',
      _Tabs(icons: true),
    ),
    (
      'filled pill — the glyph and the label are both on-brand',
      _Tabs(icons: true, appearance: FluentTabAppearance.filledCircular),
    ),
    (
      'vertical, with icons',
      _Tabs(icons: true, orientation: FluentTabOrientation.vertical),
    ),
  ],
);

Widget _iconOnlyBuilder(BuildContext context) => const _Cases(
  children: [
    ('flat — a 40 wide slot at medium', _Tabs(labels: false)),
    (
      'subtle pill',
      _Tabs(labels: false, appearance: FluentTabAppearance.subtleCircular),
    ),
    (
      'small pill — a 32 wide slot',
      _Tabs(
        labels: false,
        size: FluentTabSize.small,
        appearance: FluentTabAppearance.filledCircular,
      ),
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'one disabled tab — the arrows step straight over Pages',
      _Tabs(disabled: 'pages'),
    ),
    ('the whole list, from a null onSelect', _Tabs(enabled: false)),
    (
      'a disabled selected tab keeps its indicator',
      _Tabs(disabled: 'home', appearance: FluentTabAppearance.subtle),
    ),
  ],
);

Widget _keyboardBuilder(BuildContext context) =>
    const _Tabs(items: _longer, icons: true);

Widget _panelsBuilder(BuildContext context) => const _WithPanels();

/// The one live tab list every story is built from: it owns the selection,
/// which is what makes the indicator animate rather than jump.
class _Tabs extends StatefulWidget {
  const _Tabs({
    this.orientation = FluentTabOrientation.horizontal,
    this.size = FluentTabSize.medium,
    this.appearance = FluentTabAppearance.transparent,
    this.icons = false,
    this.labels = true,
    this.enabled = true,
    this.disabled,
    this.items = _items,
  });

  final FluentTabOrientation orientation;
  final FluentTabSize size;
  final FluentTabAppearance appearance;

  /// Whether every tab carries its leading icon.
  final bool icons;

  /// Whether the tabs are labelled. False makes them icon-only.
  final bool labels;

  /// False passes a null `onSelect`, which disables every tab.
  final bool enabled;

  /// The value of the one tab that is disabled on its own.
  final String? disabled;

  final List<(String, String, IconData)> items;

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  String _selected = _items.first.$1;

  @override
  Widget build(BuildContext context) => FluentTabList<String>(
    orientation: widget.orientation,
    size: widget.size,
    appearance: widget.appearance,
    selectedValue: _selected,
    semanticLabel: 'Sections',
    onSelect: widget.enabled
        ? (value) => setState(() => _selected = value)
        : null,
    tabs: [
      for (final (value, label, icon) in widget.items)
        FluentTab<String>(
          value: value,
          enabled: value != widget.disabled,
          // An icon-only tab has nothing else to draw, so the icon is forced on.
          icon: widget.icons || !widget.labels ? Icon(icon) : null,
          semanticLabel: widget.labels ? null : label,
          child: widget.labels ? Text(label) : null,
        ),
    ],
  );
}

/// One selection driving both the list and the content under it.
class _WithPanels extends StatefulWidget {
  const _WithPanels();

  @override
  State<_WithPanels> createState() => _WithPanelsState();
}

class _WithPanelsState extends State<_WithPanels> {
  static const _panels = <String, String>{
    'home': 'Everything that changed since you were last here.',
    'pages': 'Eleven pages, four of them shared with the wider team.',
    'documents': 'Drafts, signed contracts and the archive.',
  };

  String _selected = _items.first.$1;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: [
        FluentTabList<String>(
          selectedValue: _selected,
          semanticLabel: 'Sections',
          onSelect: (value) => setState(() => _selected = value),
          tabs: [
            for (final (value, label, icon) in _items)
              FluentTab<String>(
                value: value,
                icon: Icon(icon),
                child: Text(label),
              ),
          ],
        ),
        FluentCard(
          child: Text(
            _panels[_selected]!,
            style: theme.typography.body1.copyWith(
              color: theme.colors.neutralForeground2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Captioned cases stacked down the page.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.xl,
      children: [
        for (final (caption, child) in children)
          Column(
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
