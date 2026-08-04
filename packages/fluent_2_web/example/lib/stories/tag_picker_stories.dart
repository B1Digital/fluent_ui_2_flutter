import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentTagPicker].
///
/// The picker is a composition rather than a control: a `FluentInput` with its
/// chrome switched off, a wrap of `FluentInteractionTag` chips, and an overlay
/// list of dropdown rows. Every story here is a live picker — the selection is
/// real state, so chips can actually be added with the keyboard and removed
/// with Backspace or the chip's own dismiss glyph.
///
/// One thing to know before reading any of them: the popup opens from the
/// keyboard. Focus the field and press Down or Enter.
final StorySection tagPickerStories = StorySection(
  component: 'Tag picker',
  description:
      'A text field whose value is a list of chips, with a listbox of '
      'candidates underneath. Choosing a row turns it into a chip and drops it '
      'out of the list; Backspace on an empty field takes the last one back.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A working multi-select picker. Press Down to open the list, Enter '
          'to commit the active row, Backspace on an empty field to remove the '
          'last chip.',
      knobs: const [
        OptionKnob<FluentTagPickerAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentTagPickerAppearance.outline,
          options: FluentTagPickerAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentTagPickerSize>(
          label: 'Size',
          id: 'size',
          initial: FluentTagPickerSize.medium,
          options: FluentTagPickerSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'Enabled', id: 'enabled', initial: true),
        BoolKnob(label: 'Clear all action', id: 'clear'),
        TextKnob(
          label: 'Placeholder',
          id: 'placeholder',
          initial: 'Select employees',
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _Picker(
          appearance: knobs.get<FluentTagPickerAppearance>(
            'appearance',
            FluentTagPickerAppearance.outline,
          ),
          size: knobs.get<FluentTagPickerSize>(
            'size',
            FluentTagPickerSize.medium,
          ),
          enabled: knobs.get<bool>('enabled', true),
          clearAll: knobs.get<bool>('clear', false),
          placeholder: knobs.get<String>('placeholder', 'Select employees'),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'Four fills. Outline is the only one with a box border; transparent '
          'drops the fill and keeps the bottom rule; both filled forms drop the '
          'rule and keep a fill.',
      knobs: const [
        OptionKnob<FluentTagPickerSize>(
          label: 'Size',
          id: 'size',
          initial: FluentTagPickerSize.medium,
          options: FluentTagPickerSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) {
        final size = KnobsScope.of(
          context,
        ).get<FluentTagPickerSize>('size', FluentTagPickerSize.medium);
        return _Cases(
          children: [
            for (final appearance in FluentTagPickerAppearance.values)
              (
                _appearanceLabel(appearance),
                _Picker(
                  appearance: appearance,
                  size: size,
                  initial: const ['katri'],
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Sizes',
      description:
          'Three control heights — 32, 40 and 48 — and only the chips ramp with '
          'them. The type step holds at body across all three, unlike '
          '`FluentInput`.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Grouped',
      description:
          'Header options divide the list into sections. A header carries no '
          'value, never highlights and is skipped by the arrow keys.',
      builder: _groupedBuilder,
    ),
    const Story(
      name: 'Filtering',
      description:
          'Filtering is the caller\'s: hand the picker a controller and narrow '
          'the option list as the query changes. Open with Down, then type.',
      builder: _filteringBuilder,
    ),
    const Story(
      name: 'Option media',
      description:
          'An option can carry leading media — normally an avatar. The same '
          'widget is reused as the chip\'s icon once the option is chosen.',
      builder: _mediaBuilder,
    ),
    const Story(
      name: 'Secondary action',
      description:
          'The trailing slot takes any widget; a "Clear all" link is the '
          'conventional one. It appears here only once something is selected.',
      builder: _secondaryBuilder,
    ),
    const Story(
      name: 'Single select',
      description:
          'One chip at a time, by keeping only the last value in `onChanged`. '
          'The picker has no selection limit of its own.',
      builder: _singleSelectBuilder,
    ),
    Story(
      name: 'Truncated text',
      description:
          'A long label is bounded by the option\'s own widget: the picker '
          'never clamps it, so an ellipsis is a `Text` decision made in the '
          'option.',
      knobs: const [BoolKnob(label: 'Truncate', id: 'truncate', initial: true)],
      builder: (context) => _Picker(
        options: KnobsScope.of(context).get<bool>('truncate', true)
            ? _long
            : _longUnbounded,
        placeholder: 'Select a workstream',
        initial: const ['migration'],
      ),
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabled is a real state, not a tint: the control refuses focus and '
          'edits, its chips lose both halves, and the focus bar is gone '
          'entirely. A single option can be disabled on its own instead.',
      builder: _disabledBuilder,
    ),
  ],
);

String _appearanceLabel(FluentTagPickerAppearance value) => switch (value) {
  FluentTagPickerAppearance.outline => 'outline',
  FluentTagPickerAppearance.transparent => 'transparent',
  FluentTagPickerAppearance.filledDarker => 'filled darker',
  FluentTagPickerAppearance.filledLighter => 'filled lighter',
};

String _sizeLabel(FluentTagPickerSize value) => switch (value) {
  FluentTagPickerSize.medium => 'medium',
  FluentTagPickerSize.large => 'large',
  FluentTagPickerSize.extraLarge => 'extra large',
};

/// The one list of people every story picks from, so a reader recognises the
/// same names moving between them.
const List<(String, String)> _names = [
  ('katri', 'Katri Athokas'),
  ('ben', 'Ben Howard'),
  ('cecil', 'Cecil Folk'),
  ('daisy', 'Daisy Phillips'),
  ('elvia', 'Elvia Atkins'),
  ('mona', 'Mona Kane'),
];

final List<FluentTagPickerOption<String>> _people = [
  for (final (value, name) in _names)
    FluentTagPickerOption<String>(value: value, label: Text(name), text: name),
];

final List<FluentTagPickerOption<String>> _withAvatars = [
  for (final (value, name) in _names)
    FluentTagPickerOption<String>(
      value: value,
      label: Text(name),
      text: name,
      media: FluentAvatar(
        name: name,
        color: FluentAvatarColor.cranberry,
        size: FluentAvatarSize.size20,
      ),
    ),
];

final List<FluentTagPickerOption<String>> _grouped = [
  FluentTagPickerOption<String>.header(label: Text('Design'), text: 'Design'),
  FluentTagPickerOption<String>(
    value: 'katri',
    label: Text('Katri Athokas'),
    text: 'Katri Athokas',
  ),
  FluentTagPickerOption<String>(
    value: 'daisy',
    label: Text('Daisy Phillips'),
    text: 'Daisy Phillips',
  ),
  FluentTagPickerOption<String>.header(
    label: Text('Engineering'),
    text: 'Engineering',
  ),
  FluentTagPickerOption<String>(
    value: 'ben',
    label: Text('Ben Howard'),
    text: 'Ben Howard',
  ),
  FluentTagPickerOption<String>(
    value: 'mona',
    label: Text('Mona Kane'),
    text: 'Mona Kane',
  ),
];

const List<(String, String)> _workstreams = [
  ('migration', 'Migrating the identity service off the legacy gateway'),
  ('audit', 'Quarterly accessibility audit and remediation backlog'),
  ('tokens', 'Design token pipeline'),
];

/// Labels bounded to 180 and ellipsised, which is what makes them truncate.
final List<FluentTagPickerOption<String>> _long = [
  for (final (value, label) in _workstreams)
    FluentTagPickerOption<String>(
      value: value,
      label: SizedBox(
        width: 180,
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      text: label,
    ),
];

/// The same labels with nothing bounding them, so they wrap instead.
final List<FluentTagPickerOption<String>> _longUnbounded = [
  for (final (value, label) in _workstreams)
    FluentTagPickerOption<String>(
      value: value,
      label: Text(label),
      text: label,
    ),
];

Widget _sizesBuilder(BuildContext context) => _Cases(
  children: [
    for (final size in FluentTagPickerSize.values)
      (_sizeLabel(size), _Picker(size: size, initial: const ['katri'])),
  ],
);

Widget _groupedBuilder(BuildContext context) =>
    _Picker(options: _grouped, placeholder: 'Select a reviewer');

Widget _mediaBuilder(BuildContext context) => _Picker(
  options: _withAvatars,
  initial: const ['katri'],
  placeholder: 'Select employees',
);

Widget _filteringBuilder(BuildContext context) => const _FilteringPicker();

Widget _secondaryBuilder(BuildContext context) =>
    const _Picker(clearAll: true, initial: ['katri', 'ben']);

Widget _singleSelectBuilder(BuildContext context) => const _Picker(
  singleSelect: true,
  placeholder: 'Select an owner',
  initial: ['katri'],
);

Widget _disabledBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Disabled control',
      const _Picker(enabled: false, initial: ['katri', 'ben']),
    ),
    ('One disabled option', _Picker(options: _partlyDisabled)),
  ],
);

/// Ola cannot be chosen: the row greys out and the arrow keys step over it.
final List<FluentTagPickerOption<String>> _partlyDisabled = [
  _people.first,
  const FluentTagPickerOption<String>(
    value: 'ola',
    label: Text('Ola Odetunde'),
    text: 'Ola Odetunde',
    enabled: false,
  ),
  _people[1],
];

/// A live picker holding its own selection.
///
/// One widget rather than eight, because every story here wants the same thing
/// — real state — and differs only in the axes it puts on top.
class _Picker extends StatefulWidget {
  const _Picker({
    this.options,
    this.appearance = FluentTagPickerAppearance.outline,
    this.size = FluentTagPickerSize.medium,
    this.enabled = true,
    this.initial = const [],
    this.clearAll = false,
    this.singleSelect = false,
    this.placeholder = 'Select employees',
  });

  final List<FluentTagPickerOption<String>>? options;
  final FluentTagPickerAppearance appearance;
  final FluentTagPickerSize size;
  final bool enabled;
  final List<String> initial;
  final bool clearAll;
  final bool singleSelect;
  final String placeholder;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late List<String> _selected = widget.initial;

  @override
  Widget build(BuildContext context) => _Frame(
    child: FluentTagPicker<String>(
      options: widget.options ?? _people,
      selected: _selected,
      appearance: widget.appearance,
      size: widget.size,
      semanticLabel: 'People',
      placeholder: Text(widget.placeholder),
      secondaryAction: widget.clearAll && _selected.isNotEmpty
          ? FluentLink(
              onPressed: () => setState(() => _selected = const []),
              child: const Text('Clear all'),
            )
          : null,
      onChanged: widget.enabled
          ? (values) => setState(() {
              // The picker has no selection limit; a single-select one is this
              // line and nothing else.
              _selected = widget.singleSelect && values.length > 1
                  ? [values.last]
                  : values;
            })
          : null,
    ),
  );
}

/// A picker whose option list narrows as the query is typed.
class _FilteringPicker extends StatefulWidget {
  const _FilteringPicker();

  @override
  State<_FilteringPicker> createState() => _FilteringPickerState();
}

class _FilteringPickerState extends State<_FilteringPicker> {
  final TextEditingController _controller = TextEditingController();
  List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final options = [
      for (final (value, name) in _names)
        // A chosen value has to survive the filter even when it stops matching:
        // the control looks its chips up in `options`, and one that is not
        // there is skipped rather than drawn.
        if (_selected.contains(value) || name.toLowerCase().contains(query))
          FluentTagPickerOption<String>(
            value: value,
            label: Text(name),
            text: name,
          ),
    ];

    return _Frame(
      child: FluentTagPicker<String>(
        options: options,
        selected: _selected,
        controller: _controller,
        semanticLabel: 'People',
        placeholder: const Text('Type to filter'),
        onChanged: (values) => setState(() => _selected = values),
      ),
    );
  }
}

/// Keeps a picker at a form-like width instead of letting the canvas stretch it
/// across the page, and leaves room under it for the popup.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: SizedBox(width: 320, child: child),
  );
}

/// Side-by-side cases under a caption.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) => Wrap(
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
            FluentLabel(size: FluentLabelSize.small, child: Text(caption)),
            child,
          ],
        ),
    ],
  );
}
