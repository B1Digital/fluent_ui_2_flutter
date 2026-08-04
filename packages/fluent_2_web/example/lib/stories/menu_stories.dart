import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentMenu].
final StorySection menuStories = StorySection(
  component: 'Menu',
  description:
      'A trigger and a chain of overlay surfaces. The menu owns hover, the '
      'keyboard, the focus ring and the submenu chain; a [FluentMenuItem] only '
      'says what a row is — a command, a caption or a rule.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A list of commands hanging off a button. Activating a row closes '
          'the whole chain and then calls its onPressed.',
      knobs: const [
        BoolKnob(label: 'Leading icons', id: 'icons', initial: true),
        BoolKnob(label: 'Shortcuts', id: 'shortcuts', initial: true),
        BoolKnob(label: 'Disable Paste', id: 'disable'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final icons = knobs.get<bool>('icons', true);
        final shortcuts = knobs.get<bool>('shortcuts', true);
        final disablePaste = knobs.get<bool>('disable', false);
        return _CommandMenu(
          items: (invoke) => _editItems(
            invoke,
            icons: icons,
            shortcuts: shortcuts,
            disablePaste: disablePaste,
          ),
        );
      },
    ),
    Story(
      name: 'Items with icons',
      description:
          'The leading slot is one column for the whole level: give one row an '
          'icon and every other label still lines up with it.',
      knobs: const [
        BoolKnob(label: 'Icon on every row', id: 'all', initial: false),
      ],
      builder: (context) {
        final all = KnobsScope.of(context).get<bool>('all', false);
        return _CommandMenu(
          label: 'File',
          items: (invoke) => <FluentMenuItem>[
            FluentMenuItem(
              icon: const Icon(FluentIcons.save_20_regular),
              label: const Text('Save'),
              onPressed: () => invoke('Save'),
            ),
            FluentMenuItem(
              icon: all ? const Icon(FluentIcons.print_20_regular) : null,
              label: const Text('Print'),
              onPressed: () => invoke('Print'),
            ),
            FluentMenuItem(
              icon: const Icon(FluentIcons.share_20_regular),
              label: const Text('Share'),
              onPressed: () => invoke('Share'),
            ),
            FluentMenuItem(
              icon: all ? const Icon(FluentIcons.delete_20_regular) : null,
              label: const Text('Move to bin'),
              onPressed: () => invoke('Move to bin'),
            ),
          ],
        );
      },
    ),
    const Story(
      name: 'Secondary content',
      description:
          'A row can carry a second line under its label and trailing content '
          'beside it — normally the keyboard shortcut.',
      builder: _secondaryBuilder,
    ),
    const Story(
      name: 'Headers and dividers',
      description:
          'Two ways to group: a caption above a run of commands, or a bare '
          'rule between them. Neither is selectable and the arrows skip both.',
      builder: _groupingBuilder,
    ),
    const Story(
      name: 'Checkbox items',
      description:
          'Independent switches: each row paints the checkmark when its value '
          'is on. The menu closes on activation, so reopen it to toggle again.',
      builder: _checkboxBuilder,
    ),
    const Story(
      name: 'Radio items',
      description:
          'One checkmark at a time. The rows share a single value on the '
          'caller, which is what makes the choice exclusive.',
      builder: _radioBuilder,
    ),
    const Story(
      name: 'Selection groups',
      description:
          'A checkable group and an exclusive group in one menu, each under '
          'its own caption and separated by a rule.',
      builder: _selectionGroupsBuilder,
    ),
    const Story(
      name: 'Nested submenus',
      description:
          'A row with submenu rows opens a second surface beside itself, to '
          'any depth. Right opens it, Left closes it and returns to the row.',
      builder: _submenuBuilder,
    ),
    Story(
      name: 'Hover delay',
      description:
          'How long a pointer rests on a row before its submenu opens. The '
          'keyboard never waits — Right and Enter open immediately.',
      knobs: const [
        NumberKnob(
          label: 'Delay (ms)',
          id: 'delay',
          initial: 500,
          max: 1500,
          step: 50,
        ),
      ],
      builder: (context) => _CommandMenu(
        label: 'Insert',
        hoverDelay: Duration(
          milliseconds: KnobsScope.of(
            context,
          ).get<double>('delay', 500).round(),
        ),
        items: _insertItems,
      ),
    ),
    const Story(
      name: 'Disabled rows',
      description:
          'A disabled row keeps its place and its glyph but refuses the '
          'pointer, the keyboard and typeahead. A caption can dim with it.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Custom trigger',
      description:
          'The trigger is whatever the builder returns — the menu only hands '
          'it a toggle and anchors itself to it.',
      builder: _customTriggerBuilder,
    ),
    const Story(
      name: 'Trigger with a tooltip',
      description:
          'An icon-only trigger needs a name: FluentTooltip supplies the '
          'hover text, and semanticLabel the one a screen reader reads.',
      builder: _tooltipTriggerBuilder,
    ),
    const Story(
      name: 'Split button trigger',
      description:
          'The primary half runs the default command; only the chevron half '
          'is wired to the toggle, so the menu opens from there.',
      builder: _splitButtonBuilder,
    ),
    const Story(
      name: 'Opening from elsewhere',
      description:
          'The toggle handed to the builder is a plain callback: keep it and '
          'anything else on the page can open the menu on the trigger.',
      builder: _externalToggleBuilder,
    ),
    const Story(
      name: 'Reduced motion',
      description:
          'The surface fades in and is simply gone on close. Under '
          'disableAnimations it arrives opaque on the frame it is inserted.',
      builder: _motionBuilder,
    ),
    Story(
      name: 'Custom styling',
      description:
          'Surface and rows restyle through the same three rungs: theme '
          'defaults, a subtree theme, then style and itemStyle last.',
      knobs: const [
        NumberKnob(
          label: 'Offset from the trigger',
          id: 'offset',
          initial: 4,
          max: 24,
          step: 1,
        ),
      ],
      builder: (context) =>
          _styledMenu(KnobsScope.of(context).get<double>('offset', 4)),
    ),
    const Story(
      name: 'Keyboard',
      description:
          'Up/Down move and wrap, Home/End jump, Enter activates, Right and '
          'Left walk the submenu chain, Escape closes one level, a letter '
          'jumps to the next row starting with it.',
      builder: _keyboardBuilder,
    ),
  ],
);

// --- shared row sets --------------------------------------------------------

/// The reference menu: four commands and a rule, with both optional slots
/// behind flags so the Default story's knobs can turn them off.
List<FluentMenuItem> _editItems(
  void Function(String command) invoke, {
  bool icons = true,
  bool shortcuts = true,
  bool disablePaste = false,
}) => <FluentMenuItem>[
  FluentMenuItem(
    icon: icons ? const Icon(FluentIcons.cut_20_regular) : null,
    label: const Text('Cut'),
    trailing: shortcuts ? const Text('Ctrl+X') : null,
    onPressed: () => invoke('Cut'),
  ),
  FluentMenuItem(
    icon: icons ? const Icon(FluentIcons.copy_20_regular) : null,
    label: const Text('Copy'),
    trailing: shortcuts ? const Text('Ctrl+C') : null,
    onPressed: () => invoke('Copy'),
  ),
  FluentMenuItem(
    icon: icons ? const Icon(FluentIcons.clipboard_paste_20_regular) : null,
    label: const Text('Paste'),
    trailing: shortcuts ? const Text('Ctrl+V') : null,
    enabled: !disablePaste,
    onPressed: () => invoke('Paste'),
  ),
  const FluentMenuItem.divider(),
  FluentMenuItem(
    icon: icons ? const Icon(FluentIcons.document_20_regular) : null,
    label: const Text('Select all'),
    trailing: shortcuts ? const Text('Ctrl+A') : null,
    onPressed: () => invoke('Select all'),
  ),
];

/// Three levels of submenu, used by the submenu and hover-delay stories.
List<FluentMenuItem> _insertItems(void Function(String command) invoke) =>
    <FluentMenuItem>[
      FluentMenuItem(
        icon: const Icon(FluentIcons.image_20_regular),
        label: const Text('Picture'),
        submenu: <FluentMenuItem>[
          FluentMenuItem(
            label: const Text('From this device'),
            onPressed: () => invoke('Picture from this device'),
          ),
          FluentMenuItem(
            icon: const Icon(FluentIcons.globe_20_regular),
            label: const Text('Stock images'),
            submenu: <FluentMenuItem>[
              FluentMenuItem(
                label: const Text('Illustrations'),
                onPressed: () => invoke('Stock illustrations'),
              ),
              FluentMenuItem(
                label: const Text('Photographs'),
                onPressed: () => invoke('Stock photographs'),
              ),
            ],
          ),
        ],
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.link_20_regular),
        label: const Text('Link'),
        onPressed: () => invoke('Link'),
      ),
      FluentMenuItem(
        icon: const Icon(FluentIcons.calendar_20_regular),
        label: const Text('Date'),
        submenu: <FluentMenuItem>[
          FluentMenuItem(
            label: const Text('Today'),
            onPressed: () => invoke('Today'),
          ),
          FluentMenuItem(
            label: const Text('Last modified'),
            onPressed: () => invoke('Last modified'),
          ),
        ],
      ),
    ];

// --- story builders ---------------------------------------------------------

Widget _secondaryBuilder(BuildContext context) => _CommandMenu(
  label: 'Send',
  items: (invoke) => <FluentMenuItem>[
    FluentMenuItem(
      icon: const Icon(FluentIcons.mail_20_regular),
      label: const Text('Send now'),
      secondary: const Text('Delivered to 12 people'),
      trailing: const Text('Ctrl+Enter'),
      onPressed: () => invoke('Send now'),
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.calendar_20_regular),
      label: const Text('Schedule'),
      secondary: const Text('Tomorrow at 08:00'),
      onPressed: () => invoke('Schedule'),
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.chat_20_regular),
      label: const Text('Send as a chat message instead of an email'),
      secondary: const Text('Wraps over as many lines as it needs'),
      onPressed: () => invoke('Send as a chat message'),
    ),
  ],
);

Widget _groupingBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Captions',
      _CommandMenu(
        label: 'View',
        items: (invoke) => <FluentMenuItem>[
          const FluentMenuItem.header(label: Text('Layout')),
          FluentMenuItem(
            label: const Text('Reading view'),
            onPressed: () => invoke('Reading view'),
          ),
          FluentMenuItem(
            label: const Text('Web view'),
            onPressed: () => invoke('Web view'),
          ),
          const FluentMenuItem.header(label: Text('Zoom')),
          FluentMenuItem(
            label: const Text('Fit to width'),
            onPressed: () => invoke('Fit to width'),
          ),
          FluentMenuItem(
            label: const Text('Actual size'),
            onPressed: () => invoke('Actual size'),
          ),
        ],
      ),
    ),
    (
      'Rules only',
      _CommandMenu(
        label: 'Organise',
        items: (invoke) => <FluentMenuItem>[
          FluentMenuItem(
            icon: const Icon(FluentIcons.arrow_sort_20_regular),
            label: const Text('Sort'),
            onPressed: () => invoke('Sort'),
          ),
          FluentMenuItem(
            icon: const Icon(FluentIcons.filter_20_regular),
            label: const Text('Filter'),
            onPressed: () => invoke('Filter'),
          ),
          const FluentMenuItem.divider(),
          FluentMenuItem(
            icon: const Icon(FluentIcons.folder_20_regular),
            label: const Text('Move to folder'),
            onPressed: () => invoke('Move to folder'),
          ),
          const FluentMenuItem.divider(),
          FluentMenuItem(
            icon: const Icon(FluentIcons.delete_20_regular),
            label: const Text('Delete'),
            onPressed: () => invoke('Delete'),
          ),
        ],
      ),
    ),
  ],
);

Widget _checkboxBuilder(BuildContext context) =>
    const _SelectionMenu(radios: false);

Widget _radioBuilder(BuildContext context) =>
    const _SelectionMenu(checkboxes: false);

Widget _selectionGroupsBuilder(BuildContext context) =>
    const _SelectionMenu(headers: true);

Widget _submenuBuilder(BuildContext context) =>
    _CommandMenu(label: 'Insert', items: _insertItems);

Widget _disabledBuilder(BuildContext context) => _CommandMenu(
  label: 'Review',
  items: (invoke) => <FluentMenuItem>[
    FluentMenuItem(
      icon: const Icon(FluentIcons.edit_20_regular),
      label: const Text('Add a comment'),
      onPressed: () => invoke('Add a comment'),
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.eye_20_regular),
      label: const Text('Track changes'),
      enabled: false,
      onPressed: () => invoke('Track changes'),
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.arrow_download_20_regular),
      label: const Text('Export'),
      enabled: false,
      submenu: <FluentMenuItem>[
        FluentMenuItem(
          label: const Text('PDF'),
          onPressed: () => invoke('PDF'),
        ),
      ],
    ),
    const FluentMenuItem.divider(),
    const FluentMenuItem.header(label: Text('Sharing'), enabled: false),
    FluentMenuItem(
      icon: const Icon(FluentIcons.person_20_regular),
      label: const Text('Invite people'),
      enabled: false,
      onPressed: () => invoke('Invite people'),
    ),
  ],
);

Widget _customTriggerBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Icon only',
      _CommandMenu(
        label: 'More actions',
        trigger: (context, toggle) => FluentButton.icon(
          icon: const Icon(FluentIcons.more_horizontal_20_regular),
          semanticLabel: 'More actions',
          appearance: FluentButtonAppearance.subtle,
          onPressed: toggle,
        ),
        items: _editItems,
      ),
    ),
    (
      'Primary, with a chevron',
      _CommandMenu(
        label: 'New',
        trigger: (context, toggle) => FluentButton(
          appearance: FluentButtonAppearance.primary,
          iconPosition: FluentButtonIconPosition.after,
          icon: fluentMenuChevron,
          onPressed: toggle,
          child: const Text('New'),
        ),
        items: (invoke) => <FluentMenuItem>[
          FluentMenuItem(
            icon: const Icon(FluentIcons.document_20_regular),
            label: const Text('Document'),
            onPressed: () => invoke('Document'),
          ),
          FluentMenuItem(
            icon: const Icon(FluentIcons.folder_20_regular),
            label: const Text('Folder'),
            onPressed: () => invoke('Folder'),
          ),
        ],
      ),
    ),
  ],
);

Widget _tooltipTriggerBuilder(BuildContext context) => _CommandMenu(
  label: 'More actions',
  trigger: (context, toggle) => FluentTooltip(
    content: const Text('More actions'),
    withArrow: true,
    child: FluentButton.icon(
      icon: const Icon(FluentIcons.more_horizontal_20_regular),
      semanticLabel: 'More actions',
      onPressed: toggle,
    ),
  ),
  items: _editItems,
);

Widget _splitButtonBuilder(BuildContext context) => _CommandMenu(
  label: 'Save',
  trigger: (context, toggle) => _SplitTrigger(toggle: toggle),
  items: (invoke) => <FluentMenuItem>[
    FluentMenuItem(
      icon: const Icon(FluentIcons.save_20_regular),
      label: const Text('Save a copy'),
      onPressed: () => invoke('Save a copy'),
    ),
    FluentMenuItem(
      icon: const Icon(FluentIcons.arrow_download_20_regular),
      label: const Text('Download as PDF'),
      onPressed: () => invoke('Download as PDF'),
    ),
  ],
);

Widget _externalToggleBuilder(BuildContext context) => const _ExternalToggle();

Widget _motionBuilder(BuildContext context) => _Cases(
  children: [
    ('Default', _CommandMenu(label: 'Edit', items: _editItems)),
    (
      'disableAnimations',
      MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: _CommandMenu(label: 'Edit', items: _editItems),
      ),
    ),
  ],
);

Widget _keyboardBuilder(BuildContext context) =>
    _CommandMenu(label: 'Insert', autofocus: true, items: _insertItems);

/// A menu wearing a rounded surface and taller rows, with the gap between the
/// trigger and the surface driven by [offset].
Widget _styledMenu(double offset) => _CommandMenu(
  label: 'Edit',
  style: FluentMenuStyle.from(
    borderRadius: FluentRadius.allXLarge,
    padding: const EdgeInsets.all(FluentSpacing.s),
    gap: FluentSpacing.xxs,
    offset: offset,
  ),
  itemStyle: FluentMenuItemStyle.from(
    borderRadius: FluentRadius.allCircular,
    minimumSize: const Size(0, 40),
    gap: FluentSpacing.m,
  ),
  items: _editItems,
);

// --- supporting widgets -----------------------------------------------------

/// A menu plus a line reporting the last row activated, so a story shows a
/// live control rather than a frozen one.
class _CommandMenu extends StatefulWidget {
  const _CommandMenu({
    required this.items,
    this.label = 'Edit',
    this.trigger,
    this.hoverDelay = fluentMenuHoverDelay,
    this.style,
    this.itemStyle,
    this.autofocus = false,
  });

  /// Builds the rows. `invoke` records what was chosen.
  final List<FluentMenuItem> Function(void Function(String command) invoke)
  items;

  /// The default trigger's label, and the menu's own accessible name.
  final String label;

  /// Replaces the default button trigger.
  final FluentMenuTriggerBuilder? trigger;

  final Duration hoverDelay;
  final FluentMenuStyle? style;
  final FluentMenuItemStyle? itemStyle;
  final bool autofocus;

  @override
  State<_CommandMenu> createState() => _CommandMenuState();
}

class _CommandMenuState extends State<_CommandMenu> {
  String? _last;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.s,
    children: [
      FluentMenu(
        items: widget.items((command) => setState(() => _last = command)),
        hoverDelay: widget.hoverDelay,
        style: widget.style,
        itemStyle: widget.itemStyle,
        semanticLabel: widget.label,
        builder:
            widget.trigger ??
            (context, toggle) => FluentButton(
              onPressed: toggle,
              autofocus: widget.autofocus,
              iconPosition: FluentButtonIconPosition.after,
              icon: fluentMenuChevron,
              child: Text(widget.label),
            ),
      ),
      _Caption(_last == null ? 'Nothing chosen yet' : 'Chose: $_last'),
    ],
  );
}

/// A checkable group, an exclusive group, or both under captions.
///
/// One widget rather than three near-identical ones: the rows differ only in
/// which value they read, which is the point the three stories make.
class _SelectionMenu extends StatefulWidget {
  const _SelectionMenu({
    this.checkboxes = true,
    this.radios = true,
    this.headers = false,
  });

  final bool checkboxes;
  final bool radios;
  final bool headers;

  @override
  State<_SelectionMenu> createState() => _SelectionMenuState();
}

class _SelectionMenuState extends State<_SelectionMenu> {
  final Set<String> _shown = <String>{'grid'};
  String _sort = 'name';

  void _toggle(String id) =>
      setState(() => _shown.contains(id) ? _shown.remove(id) : _shown.add(id));

  FluentMenuItem _checkbox(String id, String label) => FluentMenuItem(
    label: Text(label),
    checked: _shown.contains(id),
    onPressed: () => _toggle(id),
  );

  FluentMenuItem _radio(String id, String label) => FluentMenuItem(
    label: Text(label),
    checked: _sort == id,
    onPressed: () => setState(() => _sort = id),
  );

  @override
  Widget build(BuildContext context) {
    final items = <FluentMenuItem>[
      if (widget.checkboxes) ...[
        if (widget.headers) const FluentMenuItem.header(label: Text('Show')),
        _checkbox('grid', 'Grid'),
        _checkbox('rulers', 'Rulers'),
        _checkbox('guides', 'Guides'),
      ],
      if (widget.checkboxes && widget.radios) const FluentMenuItem.divider(),
      if (widget.radios) ...[
        if (widget.headers) const FluentMenuItem.header(label: Text('Sort by')),
        _radio('name', 'Name'),
        _radio('date', 'Date modified'),
        _radio('size', 'Size'),
      ],
    ];

    final shown = _shown.isEmpty
        ? 'nothing'
        : (_shown.toList()..sort()).join(', ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.s,
      children: [
        FluentMenu(
          items: items,
          semanticLabel: 'View options',
          builder: (context, toggle) => FluentButton(
            onPressed: toggle,
            iconPosition: FluentButtonIconPosition.after,
            icon: fluentMenuChevron,
            child: const Text('View'),
          ),
        ),
        _Caption(
          <String>[
            if (widget.checkboxes) 'showing $shown',
            if (widget.radios) 'sorted by $_sort',
          ].join(' · '),
        ),
      ],
    );
  }
}

/// The trigger is a split button, so only the chevron half opens the menu.
class _SplitTrigger extends StatefulWidget {
  const _SplitTrigger({required this.toggle});

  final VoidCallback toggle;

  @override
  State<_SplitTrigger> createState() => _SplitTriggerState();
}

class _SplitTriggerState extends State<_SplitTrigger> {
  int _saves = 0;

  @override
  Widget build(BuildContext context) => FluentSplitButton(
    appearance: FluentButtonAppearance.primary,
    menuSemanticLabel: 'More save options',
    icon: const Icon(FluentIcons.save_20_regular),
    onPressed: () => setState(() => _saves++),
    onMenuPressed: widget.toggle,
    child: Text(_saves == 0 ? 'Save' : 'Saved ($_saves)'),
  );
}

/// Keeps the toggle the menu hands its builder, so a button beside the trigger
/// can open the menu too.
class _ExternalToggle extends StatefulWidget {
  const _ExternalToggle();

  @override
  State<_ExternalToggle> createState() => _ExternalToggleState();
}

class _ExternalToggleState extends State<_ExternalToggle> {
  VoidCallback? _toggle;
  String? _last;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.s,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.m,
        children: [
          FluentMenu(
            semanticLabel: 'Edit',
            items: _editItems(
              (command) => setState(() => _last = command),
              shortcuts: false,
            ),
            builder: (context, toggle) {
              _toggle = toggle;
              return FluentButton(
                onPressed: toggle,
                iconPosition: FluentButtonIconPosition.after,
                icon: fluentMenuChevron,
                child: const Text('Edit'),
              );
            },
          ),
          FluentButton(
            appearance: FluentButtonAppearance.subtle,
            onPressed: () => _toggle?.call(),
            child: const Text('Toggle from here'),
          ),
        ],
      ),
      _Caption(_last == null ? 'Nothing chosen yet' : 'Chose: $_last'),
    ],
  );
}

/// A dimmed line of running commentary under a story.
class _Caption extends StatelessWidget {
  const _Caption(this.text);

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
          children: [_Caption(caption), child],
        ),
    ],
  );
}
