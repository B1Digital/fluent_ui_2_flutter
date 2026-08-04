import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for `FluentToolbar`.
final StorySection toolbarStories = StorySection(
  component: 'Toolbar',
  description:
      'A row of commands on one surface: subtle buttons, rules between the '
      'groups, and a single tab stop with the arrow keys moving inside it. The '
      'toolbar composes rather than wraps — its items are ordinary widgets, so '
      'a menu, a tooltip or a popover goes in the row like anything else.',
  stories: <Story>[
    const Story(
      name: 'Default',
      description:
          'A formatting toolbar. Size moves the surface inset only — the '
          'buttons stay 32 high at every size — and type raises the whole thing '
          'onto a shadow.',
      knobs: <Knob<Object?>>[
        OptionKnob<FluentToolbarSize>(
          label: 'Size',
          id: 'size',
          initial: FluentToolbarSize.medium,
          options: FluentToolbarSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentToolbarType>(
          label: 'Type',
          id: 'type',
          initial: FluentToolbarType.standard,
          options: FluentToolbarType.values,
          labelOf: _typeLabel,
        ),
        BoolKnob(label: 'Dividers', id: 'dividers', initial: true),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'The whole size axis at once: small is a tighter frame around the '
          'same controls, not a smaller set of them.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Floating',
      description:
          'The contextual toolbar — the same surface on an elevation, for a '
          'bar that hovers over the content it acts on rather than sitting in '
          'the page.',
      builder: _floatingBuilder,
    ),
    const Story(
      name: 'Item appearances',
      description:
          'Every Figma variant is built from subtle buttons, which show a fill '
          'only on hover. Transparent never fills, and secondary — the button '
          'default — is too heavy for a row of them.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'Groups',
      description:
          'A divider separates groups of commands. It is an ordinary item, is '
          'never announced, and the arrow keys step straight over it.',
      builder: _groupsBuilder,
    ),
    const Story(
      name: 'Overflow',
      description:
          'Overflow is not built in: either end the row with your own menu of '
          'the commands that did not fit, or let the row scroll.',
      builder: _overflowBuilder,
    ),
    const Story(
      name: 'With tooltip',
      description:
          'Icon-only commands need a name. The tooltip supplies it on hover '
          'and on keyboard focus; the semantic label supplies it to a screen '
          'reader.',
      builder: _tooltipBuilder,
    ),
    const Story(
      name: 'With popover',
      description:
          'A toolbar item that opens a surface — here a colour picker anchored '
          'to the button that owns it. Press the highlight button to open it.',
      builder: _popoverBuilder,
    ),
    const Story(
      name: 'Selected item',
      description:
          'A one-of-many group. The port has no pressed state on a button, so '
          'the current choice is carried by the appearance: secondary for the '
          'active item, subtle for the rest.',
      builder: _selectionBuilder,
    ),
    const Story(
      name: 'Keyboard',
      description:
          'Tab enters the toolbar once and leaves it once; the arrows move '
          'between items and wrap around, skipping dividers and disabled '
          'commands.',
      knobs: <Knob<Object?>>[
        BoolKnob(label: 'Underline enabled', id: 'underline'),
      ],
      builder: _keyboardBuilder,
    ),
  ],
);

String _sizeLabel(FluentToolbarSize value) => switch (value) {
  FluentToolbarSize.small => 'Small',
  FluentToolbarSize.medium => 'Medium',
  FluentToolbarSize.large => 'Large',
};

String _typeLabel(FluentToolbarType value) => switch (value) {
  FluentToolbarType.standard => 'Standard',
  FluentToolbarType.floating => 'Floating',
};

/// One toolbar command: a 32-high subtle icon button, which is what every
/// Figma variant of the toolbar is made of.
Widget _item(
  IconData icon,
  String label, {
  VoidCallback? onPressed = _noop,
  FluentButtonAppearance appearance = FluentButtonAppearance.subtle,
}) => FluentButton.icon(
  icon: Icon(icon),
  semanticLabel: label,
  appearance: appearance,
  onPressed: onPressed,
);

/// Bold, italic and underline — the group every one of these stories opens
/// with, so the differences between them are the toolbar's and not the items'.
List<Widget> get _formatting => <Widget>[
  _item(FluentIcons.text_bold_20_regular, 'Bold'),
  _item(FluentIcons.text_italic_20_regular, 'Italic'),
  _item(FluentIcons.text_underline_20_regular, 'Underline'),
];

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final dividers = knobs.get<bool>('dividers', true);
  return FluentToolbar(
    semanticLabel: 'Formatting',
    size: knobs.get<FluentToolbarSize>('size', FluentToolbarSize.medium),
    type: knobs.get<FluentToolbarType>('type', FluentToolbarType.standard),
    items: <Widget>[
      ..._formatting,
      if (dividers) const FluentToolbarDivider(),
      _item(FluentIcons.text_bullet_list_20_regular, 'Bulleted list'),
      _item(FluentIcons.text_number_list_ltr_20_regular, 'Numbered list'),
      if (dividers) const FluentToolbarDivider(),
      _item(FluentIcons.link_20_regular, 'Insert link'),
      _item(FluentIcons.image_20_regular, 'Insert image'),
    ],
  );
}

Widget _sizesBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    for (final size in FluentToolbarSize.values)
      (
        '${_sizeLabel(size)} — ${switch (size) {
          FluentToolbarSize.small => '32 high',
          FluentToolbarSize.medium => '40 high',
          FluentToolbarSize.large => '48 high',
        }}',
        FluentToolbar(
          size: size,
          semanticLabel: 'Formatting',
          items: <Widget>[
            ..._formatting,
            const FluentToolbarDivider(),
            _item(FluentIcons.link_20_regular, 'Insert link'),
          ],
        ),
      ),
  ],
);

Widget _floatingBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return _Cases(
    children: <(String, Widget)>[
      for (final type in FluentToolbarType.values)
        (
          _typeLabel(type),
          // The page behind a floating toolbar is what its shadow reads
          // against, so these sit on the ambient canvas rather than on the
          // story card's own surface.
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colors.neutralBackground3,
              borderRadius: FluentRadius.allMedium,
            ),
            child: Padding(
              padding: const EdgeInsets.all(FluentSpacing.xl),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FluentToolbar(
                  type: type,
                  semanticLabel: 'Formatting',
                  items: <Widget>[
                    ..._formatting,
                    const FluentToolbarDivider(),
                    _item(FluentIcons.highlight_20_regular, 'Highlight'),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

Widget _appearancesBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    for (final appearance in const <FluentButtonAppearance>[
      FluentButtonAppearance.subtle,
      FluentButtonAppearance.transparent,
      FluentButtonAppearance.secondary,
    ])
      (
        appearance.name,
        FluentToolbar(
          semanticLabel: 'Formatting',
          items: <Widget>[
            _item(
              FluentIcons.text_bold_20_regular,
              'Bold',
              appearance: appearance,
            ),
            _item(
              FluentIcons.text_italic_20_regular,
              'Italic',
              appearance: appearance,
            ),
            _item(
              FluentIcons.text_underline_20_regular,
              'Underline',
              appearance: appearance,
            ),
          ],
        ),
      ),
  ],
);

Widget _groupsBuilder(BuildContext context) => FluentToolbar(
  semanticLabel: 'Document',
  items: <Widget>[
    _item(FluentIcons.arrow_undo_20_regular, 'Undo'),
    _item(FluentIcons.arrow_redo_20_regular, 'Redo'),
    const FluentToolbarDivider(),
    _item(FluentIcons.cut_20_regular, 'Cut'),
    _item(FluentIcons.copy_20_regular, 'Copy'),
    _item(FluentIcons.clipboard_paste_20_regular, 'Paste'),
    const FluentToolbarDivider(),
    _item(FluentIcons.text_align_left_20_regular, 'Align left'),
    _item(FluentIcons.text_align_center_20_regular, 'Align centre'),
    _item(FluentIcons.text_align_right_20_regular, 'Align right'),
  ],
);

Widget _overflowBuilder(BuildContext context) => _Cases(
  children: <(String, Widget)>[
    (
      'A menu of what did not fit',
      FluentToolbar(
        semanticLabel: 'Formatting',
        items: <Widget>[
          ..._formatting,
          const FluentToolbarDivider(),
          FluentMenu(
            semanticLabel: 'More commands',
            items: <FluentMenuItem>[
              FluentMenuItem(
                label: const Text('Insert link'),
                text: 'Insert link',
                icon: const Icon(FluentIcons.link_20_regular),
                onPressed: _noop,
              ),
              FluentMenuItem(
                label: const Text('Insert image'),
                text: 'Insert image',
                icon: const Icon(FluentIcons.image_20_regular),
                onPressed: _noop,
              ),
              const FluentMenuItem.divider(),
              FluentMenuItem(
                label: const Text('Print'),
                text: 'Print',
                icon: const Icon(FluentIcons.print_20_regular),
                onPressed: _noop,
              ),
            ],
            builder: (context, toggle) => FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More commands',
              appearance: FluentButtonAppearance.subtle,
              onPressed: toggle,
            ),
          ),
        ],
      ),
    ),
    (
      'Or let the row scroll',
      SizedBox(
        width: 240,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _groupsBuilder(context),
        ),
      ),
    ),
  ],
);

Widget _tooltipBuilder(BuildContext context) => FluentToolbar(
  semanticLabel: 'Formatting',
  items: <Widget>[
    for (final (icon, name) in const <(IconData, String)>[
      (FluentIcons.text_bold_20_regular, 'Bold'),
      (FluentIcons.text_italic_20_regular, 'Italic'),
      (FluentIcons.text_underline_20_regular, 'Underline'),
    ])
      FluentTooltip(
        withArrow: true,
        semanticLabel: name,
        content: Text(name),
        child: _item(icon, name),
      ),
  ],
);

Widget _popoverBuilder(BuildContext context) => const _HighlightToolbar();

Widget _selectionBuilder(BuildContext context) => const _AlignmentToolbar();

Widget _keyboardBuilder(BuildContext context) {
  final enabled = KnobsScope.of(context).get<bool>('underline', false);
  return _Cases(
    children: <(String, Widget)>[
      (
        'Tab in, arrow between, Tab out',
        FluentToolbar(
          semanticLabel: 'Formatting',
          items: <Widget>[
            _item(FluentIcons.text_bold_20_regular, 'Bold'),
            _item(FluentIcons.text_italic_20_regular, 'Italic'),
            // A disabled item refuses focus outright, so the arrows skip it
            // rather than parking on something that cannot be pressed.
            _item(
              FluentIcons.text_underline_20_regular,
              'Underline',
              onPressed: enabled ? _noop : null,
            ),
            const FluentToolbarDivider(),
            _item(FluentIcons.link_20_regular, 'Insert link'),
          ],
        ),
      ),
      (
        'A second toolbar — a second tab stop, not a second row of them',
        FluentToolbar(
          semanticLabel: 'Clipboard',
          items: <Widget>[
            _item(FluentIcons.cut_20_regular, 'Cut'),
            _item(FluentIcons.copy_20_regular, 'Copy'),
            _item(FluentIcons.clipboard_paste_20_regular, 'Paste'),
          ],
        ),
      ),
    ],
  );
}

/// A toolbar whose highlight command opens a popover anchored to its button.
///
/// The open flag is the caller's, which is what `FluentPopover` asks for: the
/// button opens it and the popover closes itself on Escape or an outside tap,
/// and both report through the same callback.
class _HighlightToolbar extends StatefulWidget {
  const _HighlightToolbar();

  @override
  State<_HighlightToolbar> createState() => _HighlightToolbarState();
}

class _HighlightToolbarState extends State<_HighlightToolbar> {
  bool _open = false;
  String _colour = 'none';

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        FluentToolbar(
          semanticLabel: 'Formatting',
          items: <Widget>[
            ..._formatting,
            const FluentToolbarDivider(),
            FluentPopover(
              open: _open,
              onOpenChanged: (value) => setState(() => _open = value),
              withArrow: true,
              semanticLabel: 'Highlight colour',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FluentSpacing.xs,
                children: <Widget>[
                  const FluentLabel(child: Text('Highlight colour')),
                  for (final name in const <String>['Yellow', 'Green', 'None'])
                    FluentButton(
                      appearance: FluentButtonAppearance.subtle,
                      size: FluentButtonSize.small,
                      onPressed: () => setState(() {
                        _colour = name.toLowerCase();
                        _open = false;
                      }),
                      child: Text(name),
                    ),
                ],
              ),
              child: _item(
                FluentIcons.highlight_20_regular,
                'Highlight',
                onPressed: () => setState(() => _open = !_open),
              ),
            ),
          ],
        ),
        Text(
          'Highlight: $_colour',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// A one-of-many group carried by the item appearance.
class _AlignmentToolbar extends StatefulWidget {
  const _AlignmentToolbar();

  @override
  State<_AlignmentToolbar> createState() => _AlignmentToolbarState();
}

class _AlignmentToolbarState extends State<_AlignmentToolbar> {
  static const _options = <(IconData, String)>[
    (FluentIcons.text_align_left_20_regular, 'Align left'),
    (FluentIcons.text_align_center_20_regular, 'Align centre'),
    (FluentIcons.text_align_right_20_regular, 'Align right'),
  ];

  String _selected = 'Align left';

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: <Widget>[
        FluentToolbar(
          semanticLabel: 'Alignment',
          items: <Widget>[
            for (final (icon, name) in _options)
              _item(
                icon,
                name,
                appearance: name == _selected
                    ? FluentButtonAppearance.secondary
                    : FluentButtonAppearance.subtle,
                onPressed: () => setState(() => _selected = name),
              ),
          ],
        ),
        Text(
          'Selected: $_selected',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// Several toolbars in one story, each under a caption.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.xxl,
      children: <Widget>[
        for (final (caption, child) in children)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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

void _noop() {}
