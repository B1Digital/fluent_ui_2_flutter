import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentListItem] and the [FluentList] that owns them.
final StorySection listItemStories = StorySection(
  component: 'List item',
  description:
      'A row in a list, and the list that owns its selection, its keyboard '
      'handling and its roving focus. A row is inert on its own: it reads '
      'everything from the nearest FluentList.',
  stories: [
    Story(
      name: 'Default',
      description:
          'The list owns the selection and reports the whole new set. Arrows '
          'move focus without selecting, Home and End jump to the ends, and '
          'Space or Enter takes the focused row.',
      knobs: const [
        OptionKnob<FluentListItemSize>(
          label: 'Size',
          id: 'size',
          initial: FluentListItemSize.medium,
          options: FluentListItemSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentListSelection>(
          label: 'Selection',
          id: 'selection',
          initial: FluentListSelection.checkbox,
          options: FluentListSelection.values,
          labelOf: _selectionLabel,
        ),
        BoolKnob(label: 'Second line', id: 'twoLine'),
        BoolKnob(label: 'Disable the third row', id: 'disable'),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Small and medium, one line and two. Only the small one-line title '
          'steps down to the caption ramp; every other variant is body text.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Slots',
      description:
          'Leading media, a title, a second line, trailing metadata beside the '
          'title, and trailing controls at the end of the row.',
      builder: _slotsBuilder,
    ),
    const Story(
      name: 'Multi-select',
      description:
          'A checkbox list is additive: any number of rows can be held at '
          'once, and activating a selected row lets it go again.',
      builder: _multiSelectBuilder,
    ),
    const Story(
      name: 'Single select',
      description:
          'A radio list takes exactly one row, and re-activating the selected '
          'row keeps it selected — the Fluent radio rule.',
      builder: _singleSelectBuilder,
    ),
    const Story(
      name: 'Controlled selection',
      description:
          'The selection is a plain value the caller holds, so anything else '
          'on the page can read and write it.',
      builder: _controlledBuilder,
    ),
    const Story(
      name: 'Active row',
      description:
          'With no affordance at all the selected row still takes the Selected '
          'fill and a semibold title, which is how Fluent draws a navigation '
          'list.',
      builder: _activeBuilder,
    ),
    const Story(
      name: 'Row actions',
      description:
          'Buttons in the trailing slot keep their own tap target and their '
          'own focus stop: pressing one runs its action and leaves the row\'s '
          'selection alone.',
      builder: _actionsBuilder,
    ),
    const Story(
      name: 'Disabled and read-only',
      description:
          'A disabled row takes the disabled ramp, refuses focus and is '
          'skipped by the arrows. A list with no callback is not disabled — it '
          'is simply not a control, and stays at rest.',
      builder: _disabledBuilder,
    ),
    Story(
      name: 'Long list',
      description:
          'A long list scrolls inside a bounded box. Every row is built up '
          'front; there is no virtualised variant.',
      knobs: const [
        NumberKnob(
          label: 'Rows',
          id: 'rows',
          initial: 40,
          min: 10,
          max: 200,
          step: 10,
        ),
      ],
      builder: _longBuilder,
    ),
  ],
);

/// Name, second line, trailing metadata, avatar tone.
typedef _Person = (String, String, String, FluentAvatarColor);

const List<_Person> _people = <_Person>[
  (
    'Ada Lovelace',
    'Notes on the analytical engine',
    '9:41',
    FluentAvatarColor.cornflower,
  ),
  (
    'Grace Hopper',
    'Compiler review, take two',
    '9:12',
    FluentAvatarColor.forest,
  ),
  ('Alan Turing', 'On computable numbers', 'Tue', FluentAvatarColor.marigold),
  (
    'Katherine Johnson',
    'Re-entry figures attached',
    'Mon',
    FluentAvatarColor.grape,
  ),
];

String _sizeLabel(FluentListItemSize value) => value.name;

String _selectionLabel(FluentListSelection value) => value.name;

/// The rows every story starts from, in one line or two.
List<FluentListItem<String>> _rows({
  bool twoLine = false,
  bool media = false,
  bool tertiary = true,
  Set<String> disabled = const <String>{},
  int count = 4,
}) => <FluentListItem<String>>[
  for (final (name, line2, time, colour) in _people.take(count))
    FluentListItem<String>(
      value: name,
      enabled: !disabled.contains(name),
      media: media
          ? FluentAvatar(
              name: name,
              color: colour,
              size: twoLine ? FluentAvatarSize.size32 : FluentAvatarSize.size20,
            )
          : null,
      secondary: twoLine ? Text(line2) : null,
      tertiary: tertiary ? Text(time) : null,
      child: Text(name),
    ),
];

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final twoLine = knobs.get<bool>('twoLine', false);
  return _Framed(
    child: _SelectableList(
      size: knobs.get<FluentListItemSize>('size', FluentListItemSize.medium),
      selection: knobs.get<FluentListSelection>(
        'selection',
        FluentListSelection.checkbox,
      ),
      initial: const <String>{'Grace Hopper'},
      items: _rows(
        twoLine: twoLine,
        media: twoLine,
        disabled: knobs.get<bool>('disable', false)
            ? const <String>{'Alan Turing'}
            : const <String>{},
      ),
    ),
  );
}

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('Small, one line', _SelectableList(size: FluentListItemSize.small)),
    ('Medium, one line', _SelectableList()),
    ('Small, two lines', _TwoLineSample(size: FluentListItemSize.small)),
    ('Medium, two lines', _TwoLineSample()),
  ],
);

Widget _slotsBuilder(BuildContext context) => _Framed(
  child: _SelectableList(
    selection: FluentListSelection.checkbox,
    initial: const <String>{'Ada Lovelace'},
    items: <FluentListItem<String>>[
      for (final (name, line2, time, colour) in _people)
        FluentListItem<String>(
          value: name,
          media: FluentAvatar(name: name, color: colour),
          secondary: Text(line2),
          tertiary: Text(time),
          trailing: FluentButton.icon(
            icon: const Icon(FluentIcons.more_horizontal_20_regular),
            semanticLabel: 'More options for $name',
            appearance: FluentButtonAppearance.subtle,
            size: FluentButtonSize.small,
            onPressed: _noop,
          ),
          child: Text(name),
        ),
    ],
  ),
);

Widget _multiSelectBuilder(BuildContext context) => _Framed(
  child: _SelectableList(
    selection: FluentListSelection.checkbox,
    initial: const <String>{'Ada Lovelace', 'Alan Turing'},
    items: _rows(tertiary: false),
  ),
);

Widget _singleSelectBuilder(BuildContext context) => _Framed(
  child: _SelectableList(
    selection: FluentListSelection.radio,
    initial: const <String>{'Ada Lovelace'},
    items: _rows(tertiary: false),
  ),
);

Widget _controlledBuilder(BuildContext context) => const _ControlledSelection();

Widget _activeBuilder(BuildContext context) => _Framed(
  child: _SelectableList(
    initial: const <String>{'Grace Hopper'},
    items: _rows(tertiary: false, media: true),
  ),
);

Widget _actionsBuilder(BuildContext context) => const _RowActions();

Widget _disabledBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Disabled rows',
      _Framed(
        child: _SelectableList(
          selection: FluentListSelection.checkbox,
          initial: const <String>{'Ada Lovelace'},
          items: _rows(
            tertiary: false,
            disabled: const <String>{'Grace Hopper', 'Katherine Johnson'},
          ),
        ),
      ),
    ),
    (
      'Read-only list',
      _Framed(child: FluentList<String>(items: _rows(tertiary: false))),
    ),
  ],
);

Widget _longBuilder(BuildContext context) {
  final rows = KnobsScope.of(context).get<double>('rows', 40).round();
  return _Framed(
    child: SizedBox(
      height: 280,
      child: SingleChildScrollView(
        child: _SelectableList(
          selection: FluentListSelection.checkbox,
          items: <FluentListItem<String>>[
            for (var i = 1; i <= rows; i++)
              FluentListItem<String>(
                value: 'Item $i',
                tertiary: Text('#$i'),
                child: Text('Item $i'),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A trailing button is a demonstration of the slot, not of the button.
void _noop() {}

/// A list that keeps its own selection, so the gallery shows a real control
/// rather than a frozen one.
class _SelectableList extends StatefulWidget {
  const _SelectableList({
    this.items,
    this.selection = FluentListSelection.none,
    this.size = FluentListItemSize.medium,
    this.initial = const <String>{},
  });

  final List<FluentListItem<String>>? items;
  final FluentListSelection selection;
  final FluentListItemSize size;
  final Set<String> initial;

  @override
  State<_SelectableList> createState() => _SelectableListState();
}

class _SelectableListState extends State<_SelectableList> {
  late Set<String> _selected = widget.initial;

  @override
  void didUpdateWidget(_SelectableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching the knob to radio mid-story would otherwise leave two rows
    // showing a filled dot, which the mode cannot reach on its own.
    if (widget.selection == FluentListSelection.radio && _selected.length > 1) {
      _selected = <String>{_selected.first};
    }
  }

  @override
  Widget build(BuildContext context) => FluentList<String>(
    size: widget.size,
    selection: widget.selection,
    selectedValues: _selected,
    onSelectionChange: (values) => setState(() => _selected = values),
    semanticLabel: 'People',
    items: widget.items ?? _rows(tertiary: false),
  );
}

/// The two-line rows the Sizes story compares.
class _TwoLineSample extends StatelessWidget {
  const _TwoLineSample({this.size = FluentListItemSize.medium});

  final FluentListItemSize size;

  @override
  Widget build(BuildContext context) => _SelectableList(
    size: size,
    items: _rows(twoLine: true, media: true, count: 3),
  );
}

/// A list whose selection is held outside it and driven from both sides.
class _ControlledSelection extends StatefulWidget {
  const _ControlledSelection();

  @override
  State<_ControlledSelection> createState() => _ControlledSelectionState();
}

class _ControlledSelectionState extends State<_ControlledSelection> {
  Set<String> _selected = <String>{'Ada Lovelace'};

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: [
            FluentButton(
              size: FluentButtonSize.small,
              onPressed: () => setState(
                () => _selected = <String>{
                  for (final (name, _, _, _) in _people) name,
                },
              ),
              child: const Text('Select all'),
            ),
            FluentButton(
              size: FluentButtonSize.small,
              onPressed: () => setState(() => _selected = <String>{}),
              child: const Text('Clear'),
            ),
          ],
        ),
        Text(
          '${_selected.length} of ${_people.length} selected',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
        _Framed(
          child: FluentList<String>(
            selection: FluentListSelection.checkbox,
            selectedValues: _selected,
            onSelectionChange: (values) => setState(() => _selected = values),
            items: _rows(tertiary: false),
          ),
        ),
      ],
    );
  }
}

/// Rows whose trailing slot holds real buttons, with a readout of the last one
/// pressed so the reader can see the row's own selection stay put.
class _RowActions extends StatefulWidget {
  const _RowActions();

  @override
  State<_RowActions> createState() => _RowActionsState();
}

class _RowActionsState extends State<_RowActions> {
  Set<String> _selected = <String>{'Ada Lovelace'};
  String _last = 'Nothing pressed yet';

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: [
        _Framed(
          child: FluentList<String>(
            selection: FluentListSelection.checkbox,
            selectedValues: _selected,
            onSelectionChange: (values) => setState(() => _selected = values),
            items: <FluentListItem<String>>[
              for (final (name, _, _, colour) in _people)
                FluentListItem<String>(
                  value: name,
                  media: FluentAvatar(
                    name: name,
                    color: colour,
                    size: FluentAvatarSize.size20,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FluentButton.icon(
                        icon: const Icon(FluentIcons.pin_20_regular),
                        semanticLabel: 'Pin $name',
                        appearance: FluentButtonAppearance.subtle,
                        size: FluentButtonSize.small,
                        onPressed: () => setState(() => _last = 'Pinned $name'),
                      ),
                      FluentButton.icon(
                        icon: const Icon(FluentIcons.archive_20_regular),
                        semanticLabel: 'Archive $name',
                        appearance: FluentButtonAppearance.subtle,
                        size: FluentButtonSize.small,
                        onPressed: () =>
                            setState(() => _last = 'Archived $name'),
                      ),
                    ],
                  ),
                  child: Text(name),
                ),
            ],
          ),
        ),
        Text(
          _last,
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// A list wants a width: a row stretches to its parent, and the Figma frames
/// are 340 wide.
class _Framed extends StatelessWidget {
  const _Framed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: 340, child: child);
}

/// Side-by-side cases under a caption.
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
          SizedBox(
            width: 340,
            child: Column(
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
          ),
      ],
    );
  }
}
