import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentTree] and [FluentTreeItem].
final StorySection treeStories = StorySection(
  component: 'Tree',
  description:
      'Nested rows with one 24px indent step per level. The tree is built from '
      'data rather than from widgets, because the ARIA keyboard contract is '
      'defined over the flattened list of *visible* rows: the whole tree is a '
      'single tab stop, and inside it the arrow keys own the traversal. The '
      'open set can be owned by the tree or by the caller, and rows can carry a '
      'leading icon, a selection control and a trailing actions slot.',
  stories: [
    Story(
      name: 'Default',
      description:
          'An uncontrolled tree that owns its own open set: pressing a branch '
          'toggles it, pressing a leaf does nothing to the layout. The knobs '
          'move every axis the tree exposes to a whole subtree at once.',
      knobs: const [
        OptionKnob<FluentTreeSize>(
          label: 'Size',
          id: 'size',
          initial: FluentTreeSize.medium,
          options: FluentTreeSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentTreeAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentTreeAppearance.subtle,
          options: FluentTreeAppearance.values,
          labelOf: _appearanceLabel,
        ),
        BoolKnob(label: 'Leading icons', id: 'icons', initial: true),
        BoolKnob(label: 'Disable a branch', id: 'disabled'),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Medium is 32 high on body1 with a 16px leading icon; small is 24 '
          'high on caption1 with a 12px one. The chevron stays 12 in its 24 '
          'wide column at both, so the indent ramp never moves.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Appearances',
      description:
          'The three fill treatments. Subtle and subtle alpha are both '
          'invisible at rest and differ only once hovered — the alpha ramp is '
          'translucent white, meant for a tree over a coloured surface — while '
          'transparent never fills at all.',
      builder: _appearanceBuilder,
    ),
    const Story(
      name: 'Open by default',
      description:
          'defaultOpenItems seeds an uncontrolled tree, so a subtree can start '
          'open without the caller taking ownership of the set afterwards.',
      builder: _defaultOpenBuilder,
    ),
    const Story(
      name: 'Controlled open state',
      description:
          'Pass openItems and the tree never changes it itself: a press only '
          'reports the set it wants, and nothing opens until the caller applies '
          'it. Expand all and Collapse all drive the same set from outside.',
      builder: _controlledBuilder,
    ),
    Story(
      name: 'Selection',
      description:
          'Multiple renders a checkbox per row and accumulates; single renders '
          'a radio and replaces. Either way the control is excluded from '
          'traversal, so the tree stays one tab stop.',
      knobs: const [
        OptionKnob<FluentTreeSelectionMode>(
          label: 'Selection mode',
          id: 'mode',
          initial: FluentTreeSelectionMode.multiple,
          options: FluentTreeSelectionMode.values,
          labelOf: _selectionLabel,
        ),
      ],
      builder: _selectionBuilder,
    ),
    const Story(
      name: 'Selected without a control',
      description:
          'selectedItems drives the Selected token ramp on its own, with no '
          'selection control in the row — the shape a file browser wants, where '
          'the current file is highlighted rather than ticked.',
      builder: _selectedOnlyBuilder,
    ),
    const Story(
      name: 'Icons and quick actions',
      description:
          'A leading icon sits between the chevron and the label and inherits '
          'the row foreground; the trailing actions slot takes any widget, here '
          'real subtle icon buttons that handle their own press.',
      builder: _actionsBuilder,
    ),
    const Story(
      name: 'Nesting and indent',
      description:
          'Four levels deep. A branch is indented by the levels above it and a '
          'leaf by one step more, so a leaf label lines up with the labels of '
          'the branches beside it rather than with their chevrons.',
      builder: _nestingBuilder,
    ),
    const Story(
      name: 'Disabled rows',
      description:
          'Disabled is a real state, not a fade: the row swaps the whole colour '
          'ramp, reports no hover or press, refuses focus and is stepped over '
          'by the arrow keys. Its subtree stays reachable once opened.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Activation and keyboard',
      description:
          'onInvoke fires on click, Space and Enter, in addition to whatever '
          'the press did to the open set. Tab into the tree, then drive it with '
          'the arrows, Home, End and typeahead.',
      builder: _invokeBuilder,
    ),
    const Story(
      name: 'Lazy loading',
      description:
          'A branch whose children arrive only when it is first opened: the '
          'placeholder row carries a spinner, and onInvoke swaps in the real '
          'children when the load returns.',
      builder: _lazyBuilder,
    ),
    const Story(
      name: 'Manipulation',
      description:
          'Items are plain data, so adding and removing rows is a list edit. '
          'Values are the identity used by the open and selected sets, which is '
          'why a removed row takes its open state with it.',
      builder: _manipulationBuilder,
    ),
    Story(
      name: 'Custom metrics',
      description:
          'The style hook is a full WidgetStateProperty set. Indent, row gap '
          'and row height are live here — the geometry a dense file pane wants '
          'to compress without touching any colour.',
      knobs: const [
        NumberKnob(
          label: 'Indent',
          id: 'indent',
          initial: 24,
          min: 8,
          max: 48,
          step: 4,
        ),
        NumberKnob(label: 'Row gap', id: 'gap', initial: 2, max: 12, step: 2),
        NumberKnob(
          label: 'Row height',
          id: 'height',
          initial: 32,
          min: 20,
          max: 48,
          step: 2,
        ),
      ],
      builder: _metricsBuilder,
    ),
    const Story(
      name: 'Restyled rows',
      description:
          'FluentTreeItemTheme restyles every row of every tree beneath it in '
          'one place, and the widget’s own style still wins over it — the '
          'second and third rungs of the resolution order.',
      builder: _restyledBuilder,
    ),
    const Story(
      name: 'In a scrolling pane',
      description:
          'A long tree inside a bounded, scrollable pane. Every visible row is '
          'built eagerly, so this is the shape to use for a sidebar rather than '
          'for thousands of nodes.',
      builder: _scrollingBuilder,
    ),
  ],
);

String _sizeLabel(FluentTreeSize value) => value.name;

String _appearanceLabel(FluentTreeAppearance value) => value.name;

String _selectionLabel(FluentTreeSelectionMode value) => value.name;

/// The project tree most stories hang off, so the page reads as one document
/// rather than sixteen unrelated fragments.
List<FluentTreeItem> _projectTree({
  bool icons = false,
  bool disabledBranch = false,
}) {
  FluentTreeItem leaf(String name, IconData glyph) => FluentTreeItem(
    value: name,
    label: Text(name),
    searchLabel: name,
    icon: icons ? Icon(glyph) : null,
  );

  return <FluentTreeItem>[
    FluentTreeItem(
      value: 'lib',
      label: const Text('lib'),
      searchLabel: 'lib',
      icon: icons ? const Icon(FluentIcons.folder_20_regular) : null,
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: 'src',
          label: const Text('src'),
          searchLabel: 'src',
          icon: icons ? const Icon(FluentIcons.folder_20_regular) : null,
          children: <FluentTreeItem>[
            leaf('button.dart', FluentIcons.code_20_regular),
            leaf('tree.dart', FluentIcons.code_20_regular),
          ],
        ),
        leaf('main.dart', FluentIcons.code_20_regular),
      ],
    ),
    FluentTreeItem(
      value: 'assets',
      label: Text(disabledBranch ? 'assets — disabled' : 'assets'),
      searchLabel: 'assets',
      enabled: !disabledBranch,
      icon: icons ? const Icon(FluentIcons.image_20_regular) : null,
      children: <FluentTreeItem>[
        leaf('logo.svg', FluentIcons.image_20_regular),
      ],
    ),
    leaf('README.md', FluentIcons.document_20_regular),
  ];
}

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return FluentTree(
    semanticLabel: 'Project files',
    size: knobs.get<FluentTreeSize>('size', FluentTreeSize.medium),
    appearance: knobs.get<FluentTreeAppearance>(
      'appearance',
      FluentTreeAppearance.subtle,
    ),
    defaultOpenItems: const <Object>{'lib'},
    items: _projectTree(
      icons: knobs.get<bool>('icons', true),
      disabledBranch: knobs.get<bool>('disabled', false),
    ),
  );
}

Widget _sizesBuilder(BuildContext context) => _Cases(
  children: [
    (
      'medium — 32 high, body1, 16px icon',
      FluentTree(
        defaultOpenItems: const <Object>{'lib'},
        items: _projectTree(icons: true),
      ),
    ),
    (
      'small — 24 high, caption1, 12px icon',
      FluentTree(
        size: FluentTreeSize.small,
        defaultOpenItems: const <Object>{'lib'},
        items: _projectTree(icons: true),
      ),
    ),
  ],
);

Widget _appearanceBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return _Cases(
    children: [
      (
        'subtle — an opaque grey on hover',
        FluentTree(items: _projectTree(icons: true)),
      ),
      (
        'subtle alpha — translucent white, shown over a filled surface',
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.neutralBackground4,
            borderRadius: FluentRadius.allMedium,
          ),
          child: Padding(
            padding: const EdgeInsets.all(FluentSpacing.s),
            child: FluentTree(
              appearance: FluentTreeAppearance.subtleAlpha,
              items: _projectTree(icons: true),
            ),
          ),
        ),
      ),
      (
        'transparent — no fill in any state',
        FluentTree(
          appearance: FluentTreeAppearance.transparent,
          items: _projectTree(icons: true),
        ),
      ),
    ],
  );
}

Widget _defaultOpenBuilder(BuildContext context) => _Cases(
  children: [
    (
      'nothing seeded — every branch starts closed',
      FluentTree(items: _projectTree()),
    ),
    (
      'defaultOpenItems: lib, src',
      FluentTree(
        defaultOpenItems: const <Object>{'lib', 'src'},
        items: _projectTree(),
      ),
    ),
  ],
);

Widget _controlledBuilder(BuildContext context) => const _ControlledTree();

Widget _selectionBuilder(BuildContext context) {
  final mode = KnobsScope.of(
    context,
  ).get<FluentTreeSelectionMode>('mode', FluentTreeSelectionMode.multiple);
  // Re-keyed on the mode: a multi-selection carried into single mode would show
  // two chosen radios, which no radio group can ever reach on its own.
  return _SelectionTree(
    key: ValueKey<FluentTreeSelectionMode>(mode),
    mode: mode,
  );
}

Widget _selectedOnlyBuilder(BuildContext context) => FluentTree(
  defaultOpenItems: const <Object>{'lib', 'src'},
  selectedItems: const <Object>{'tree.dart'},
  items: _projectTree(icons: true),
);

Widget _actionsBuilder(BuildContext context) => const _ActionsTree();

Widget _nestingBuilder(BuildContext context) => const FluentTree(
  defaultOpenItems: <Object>{'l1', 'l2', 'l3'},
  items: <FluentTreeItem>[
    FluentTreeItem(
      value: 'l1',
      label: Text('level 1 — branch, no indent'),
      children: <FluentTreeItem>[
        FluentTreeItem(
          value: 'l2',
          label: Text('level 2 — branch, 24'),
          children: <FluentTreeItem>[
            FluentTreeItem(
              value: 'l3',
              label: Text('level 3 — branch, 48'),
              children: <FluentTreeItem>[
                FluentTreeItem(value: 'l4', label: Text('level 4 — leaf, 96')),
              ],
            ),
            FluentTreeItem(value: 'l3-leaf', label: Text('level 3 — leaf, 72')),
          ],
        ),
        FluentTreeItem(value: 'l2-leaf', label: Text('level 2 — leaf, 48')),
      ],
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => FluentTree(
  defaultOpenItems: const <Object>{'lib'},
  items: _projectTree(icons: true, disabledBranch: true),
);

Widget _invokeBuilder(BuildContext context) => const _InvokeTree();

Widget _lazyBuilder(BuildContext context) => const _LazyTree();

Widget _manipulationBuilder(BuildContext context) => const _ManipulationTree();

Widget _metricsBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return FluentTree(
    defaultOpenItems: const <Object>{'lib', 'src'},
    items: _projectTree(icons: true),
    style: FluentTreeItemStyle.from(
      indent: knobs.get<double>('indent', 24),
      rowGap: knobs.get<double>('gap', 2),
      minimumSize: Size(0, knobs.get<double>('height', 32)),
    ),
  );
}

Widget _restyledBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  final colors = theme.colors;
  return FluentTreeItemTheme(
    style: FluentTreeItemStyle(
      backgroundColor: FluentStateColor.tokens(
        rest: colors.subtleBackground,
        hover: colors.brandBackground2,
        pressed: colors.brandBackground2,
        selected: colors.brandBackground2,
        disabled: colors.subtleBackground,
      ),
      expandIconColor: FluentStateColor.tokens(
        rest: colors.brandForeground1,
        hover: colors.brandForeground1,
        pressed: colors.brandForeground1,
        selected: colors.brandForeground1,
        disabled: colors.neutralForegroundDisabled,
      ),
      borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
        FluentRadius.allLarge,
      ),
    ),
    child: _Cases(
      children: [
        (
          'the subtree theme — a brand chevron and a brand hover fill',
          FluentTree(
            defaultOpenItems: const <Object>{'lib'},
            items: _projectTree(icons: true),
          ),
        ),
        (
          'the same subtree, with style passed on the tree itself — style wins',
          FluentTree(
            defaultOpenItems: const <Object>{'lib'},
            items: _projectTree(icons: true),
            style: FluentTreeItemStyle(
              textStyle: WidgetStatePropertyAll<TextStyle?>(
                theme.typography.body1Strong,
              ),
              borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
                FluentRadius.allSmall,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _scrollingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: colors.neutralBackground1,
      border: Border.all(color: colors.neutralStroke2),
      borderRadius: FluentRadius.allMedium,
    ),
    child: SizedBox(
      height: 260,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(FluentSpacing.s),
        child: FluentTree(
          items: <FluentTreeItem>[
            for (var i = 1; i <= 30; i++)
              FluentTreeItem(
                value: 'day-$i',
                label: Text('Day $i'),
                searchLabel: 'Day $i',
                icon: const Icon(FluentIcons.calendar_20_regular),
                children: <FluentTreeItem>[
                  FluentTreeItem(
                    value: 'day-$i-morning',
                    label: const Text('Morning'),
                  ),
                  FluentTreeItem(
                    value: 'day-$i-evening',
                    label: const Text('Evening'),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

/// A controlled tree: the open set lives here, not in the widget.
class _ControlledTree extends StatefulWidget {
  const _ControlledTree();

  @override
  State<_ControlledTree> createState() => _ControlledTreeState();
}

class _ControlledTreeState extends State<_ControlledTree> {
  Set<Object> _open = <Object>{'lib'};
  Set<Object> _refused = <Object>{};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: [
      Wrap(
        spacing: FluentSpacing.s,
        runSpacing: FluentSpacing.s,
        children: [
          FluentButton(
            onPressed: () =>
                setState(() => _open = <Object>{'lib', 'src', 'assets'}),
            child: const Text('Expand all'),
          ),
          FluentButton(
            onPressed: () => setState(() => _open = <Object>{}),
            child: const Text('Collapse all'),
          ),
          FluentButton(
            appearance: FluentButtonAppearance.subtle,
            onPressed: _refused.isEmpty
                ? null
                : () => setState(() => _open = _refused),
            child: const Text('Apply the last request'),
          ),
        ],
      ),
      FluentTree(
        openItems: _open,
        // Held rather than applied, so the story shows what "controlled" means:
        // the tree asked, and nothing moved until the caller agreed.
        onOpenChange: (next) => setState(() => _refused = next),
        items: _projectTree(icons: true),
      ),
      _Status(
        'Open: ${_describe(_open)} · last requested: ${_describe(_refused)}',
      ),
    ],
  );
}

/// A tree whose selection lives here, so the control is real rather than a
/// static tick.
class _SelectionTree extends StatefulWidget {
  const _SelectionTree({super.key, required this.mode});

  final FluentTreeSelectionMode mode;

  @override
  State<_SelectionTree> createState() => _SelectionTreeState();
}

class _SelectionTreeState extends State<_SelectionTree> {
  Set<Object> _selected = <Object>{'main.dart'};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: [
      FluentTree(
        selectionMode: widget.mode,
        selectedItems: _selected,
        onSelectionChange: (next) => setState(() => _selected = next),
        defaultOpenItems: const <Object>{'lib', 'src'},
        items: _projectTree(),
      ),
      _Status('Selected: ${_describe(_selected)}'),
    ],
  );
}

/// Rows carrying both a leading icon and a live actions slot.
class _ActionsTree extends StatefulWidget {
  const _ActionsTree();

  @override
  State<_ActionsTree> createState() => _ActionsTreeState();
}

class _ActionsTreeState extends State<_ActionsTree> {
  String _last = 'Nothing pressed yet';

  FluentTreeItem _item(String name, IconData glyph) => FluentTreeItem(
    value: name,
    label: Text(name),
    searchLabel: name,
    icon: Icon(glyph),
    actions: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: [
        FluentButton.icon(
          icon: const Icon(FluentIcons.star_20_regular),
          semanticLabel: 'Star $name',
          appearance: FluentButtonAppearance.subtle,
          size: FluentButtonSize.small,
          onPressed: () => setState(() => _last = 'Starred $name'),
        ),
        FluentButton.icon(
          icon: const Icon(FluentIcons.more_horizontal_20_regular),
          semanticLabel: 'More actions for $name',
          appearance: FluentButtonAppearance.subtle,
          size: FluentButtonSize.small,
          onPressed: () => setState(() => _last = 'More on $name'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: [
      FluentTree(
        defaultOpenItems: const <Object>{'Reports'},
        items: <FluentTreeItem>[
          FluentTreeItem(
            value: 'Reports',
            label: const Text('Reports'),
            searchLabel: 'Reports',
            icon: const Icon(FluentIcons.folder_20_regular),
            actions: FluentButton.icon(
              icon: const Icon(FluentIcons.add_20_regular),
              semanticLabel: 'New report',
              appearance: FluentButtonAppearance.subtle,
              size: FluentButtonSize.small,
              onPressed: () => setState(() => _last = 'New report'),
            ),
            children: <FluentTreeItem>[
              _item('Q1.pdf', FluentIcons.document_pdf_20_regular),
              _item('Q2.pdf', FluentIcons.document_pdf_20_regular),
            ],
          ),
          _item('Notes.md', FluentIcons.document_20_regular),
        ],
      ),
      _Status(_last),
    ],
  );
}

/// A tree reporting every activation, whatever raised it.
class _InvokeTree extends StatefulWidget {
  const _InvokeTree();

  @override
  State<_InvokeTree> createState() => _InvokeTreeState();
}

class _InvokeTreeState extends State<_InvokeTree> {
  final List<Object> _log = <Object>[];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: [
      FluentTree(
        semanticLabel: 'Project files',
        defaultOpenItems: const <Object>{'lib'},
        items: _projectTree(icons: true),
        onInvoke: (value) => setState(() {
          _log.insert(0, value);
          if (_log.length > 5) _log.removeLast();
        }),
      ),
      _Status(
        _log.isEmpty
            ? 'Nothing invoked yet — click a row, or Tab in and press Enter'
            : 'Invoked, newest first: ${_log.join(', ')}',
      ),
    ],
  );
}

/// A branch whose children arrive on first open.
class _LazyTree extends StatefulWidget {
  const _LazyTree();

  @override
  State<_LazyTree> createState() => _LazyTreeState();
}

class _LazyTreeState extends State<_LazyTree> {
  final Set<Object> _loading = <Object>{};
  final Map<Object, List<FluentTreeItem>> _loaded =
      <Object, List<FluentTreeItem>>{};

  static const List<String> _branches = <String>['Inbox', 'Archive'];

  void _load(Object value) {
    // onInvoke fires for every row, leaves included; only the two lazy branches
    // have anything to fetch.
    if (!_branches.contains(value)) return;
    if (_loaded.containsKey(value) || !_loading.add(value)) return;
    setState(() {});
    // A stand-in for a fetch. Nothing to cancel: the timer only calls setState,
    // which is guarded by the mounted check.
    Timer(FluentDuration.slower * 4, () {
      if (!mounted) return;
      setState(() {
        _loading.remove(value);
        _loaded[value] = <FluentTreeItem>[
          for (var i = 1; i <= 3; i++)
            FluentTreeItem(
              value: '$value-$i',
              label: Text('$value message $i'),
              searchLabel: '$value message $i',
              icon: const Icon(FluentIcons.mail_20_regular),
            ),
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: [
      FluentTree(
        onInvoke: _load,
        items: <FluentTreeItem>[
          for (final branch in _branches)
            FluentTreeItem(
              value: branch,
              label: Text(branch),
              searchLabel: branch,
              icon: const Icon(FluentIcons.folder_20_regular),
              children:
                  _loaded[branch] ??
                  <FluentTreeItem>[
                    FluentTreeItem(
                      value: '$branch-placeholder',
                      label: const _LoadingRow(),
                      enabled: false,
                    ),
                  ],
            ),
        ],
      ),
      FluentButton(
        appearance: FluentButtonAppearance.subtle,
        icon: const Icon(FluentIcons.arrow_sync_20_regular),
        onPressed: _loaded.isEmpty && _loading.isEmpty
            ? null
            : () => setState(() {
                _loaded.clear();
                _loading.clear();
              }),
        child: const Text('Forget what was loaded'),
      ),
    ],
  );
}

/// The placeholder a lazy branch shows while its children are in flight.
class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.xs,
    children: [
      FluentSpinner(size: FluentSpinnerSize.extraTiny),
      Text('Loading…'),
    ],
  );
}

/// Adding and removing rows, to show that items are data and values are
/// identity.
class _ManipulationTree extends StatefulWidget {
  const _ManipulationTree();

  @override
  State<_ManipulationTree> createState() => _ManipulationTreeState();
}

class _ManipulationTreeState extends State<_ManipulationTree> {
  final List<String> _files = <String>['notes.txt', 'todo.md'];
  Set<Object> _selected = <Object>{};
  int _next = 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.m,
    children: [
      Wrap(
        spacing: FluentSpacing.s,
        runSpacing: FluentSpacing.s,
        children: [
          FluentButton(
            icon: const Icon(FluentIcons.add_20_regular),
            onPressed: () => setState(() => _files.add('new-${_next++}.txt')),
            child: const Text('Add a file'),
          ),
          FluentButton(
            icon: const Icon(FluentIcons.delete_20_regular),
            onPressed: _selected.isEmpty
                ? null
                : () => setState(() {
                    _files.removeWhere(_selected.contains);
                    _selected = <Object>{};
                  }),
            child: const Text('Remove selected'),
          ),
        ],
      ),
      FluentTree(
        selectionMode: FluentTreeSelectionMode.multiple,
        selectedItems: _selected,
        onSelectionChange: (next) => setState(() => _selected = next),
        defaultOpenItems: const <Object>{'Documents'},
        items: <FluentTreeItem>[
          FluentTreeItem(
            value: 'Documents',
            label: const Text('Documents'),
            searchLabel: 'Documents',
            icon: const Icon(FluentIcons.folder_20_regular),
            children: <FluentTreeItem>[
              for (final file in _files)
                FluentTreeItem(
                  value: file,
                  label: Text(file),
                  searchLabel: file,
                  icon: const Icon(FluentIcons.document_20_regular),
                ),
              // A branch with no children is a leaf, so an emptied folder loses
              // its chevron rather than opening onto nothing.
            ],
          ),
        ],
      ),
      _Status('${_files.length} file(s) · selected: ${_describe(_selected)}'),
    ],
  );
}

String _describe(Set<Object> values) =>
    values.isEmpty ? 'none' : values.join(', ');

/// The quiet line each stateful story reports through.
///
/// Plain `Text` on the caption ramp rather than a `FluentLabel`: a label lays
/// its content out in a min-width row so its asterisk can hug the text, which
/// means a sentence this long would overflow rather than wrap.
class _Status extends StatelessWidget {
  const _Status(this.text);

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

/// Captioned cases stacked down the page — a tree is a full-width block, so
/// these read badly side by side and well one under another.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FluentSpacing.xl,
    children: [
      for (final (caption, child) in children)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FluentSpacing.xs,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _Status(caption),
            ),
            child,
          ],
        ),
    ],
  );
}
