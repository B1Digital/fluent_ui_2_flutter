import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Toolbar docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// fluent_2_web ships no `FluentToolbarButton`, `FluentToolbarToggleButton` or
/// `FluentToolbarRadioButton`: upstream's are `Button`s with `subtle` and
/// `size: 'medium'` pinned, so every demo here puts `FluentButton`s straight
/// into `FluentToolbar.items`, which is what the widget documents.
const DocsPage toolbarPage = DocsPage(
  id: 'components-toolbar',
  title: 'Toolbar',
  description:
      'A toolbar is a container for grouping a set of controls, such as '
      'buttons, menu buttons, or checkboxes.',
  source: 'lib/pages/components_toolbar.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-toolbar--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-toolbar--small',
      title: 'Small',
      description:
          'The size determines the spacing around the toolbar controls. A '
          'small sized toolbar has no vertical padding and uses 4px for '
          'horizontal padding.',
      builder: _small,
    ),
    DocsSection(
      id: 'components-toolbar--medium',
      title: 'Medium',
      description:
          'The size determines the spacing around the toolbar controls. A '
          'medium sized toolbar uses 4px for vertical padding and 8px for '
          'horizontal padding.',
      builder: _medium,
    ),
    DocsSection(
      id: 'components-toolbar--large',
      title: 'Large',
      description:
          'The size determines the spacing around the toolbar controls. A '
          'large sized toolbar uses 4px for vertical padding and 20px for '
          'horizontal padding.',
      builder: _large,
    ),
    DocsSection(
      id: 'components-toolbar--overflow-items',
      title: 'Overflow Items',
      description:
          'This example uses the Overflow component and utilities, Please '
          'refer to the documentation to achieve more complex scenarios.',
      builder: _overflowItems,
    ),
    DocsSection(
      id: 'components-toolbar--with-tooltip',
      title: 'With Tooltip',
      builder: _withTooltip,
    ),
    DocsSection(
      id: 'components-toolbar--with-popover',
      title: 'With Popover',
      builder: _withPopover,
    ),
    DocsSection(
      id: 'components-toolbar--subtle',
      title: 'Subtle',
      builder: _subtle,
    ),
    DocsSection(
      id: 'components-toolbar--transparent',
      title: 'Transparent',
      builder: _transparent,
    ),
    DocsSection(
      id: 'components-toolbar--controlled-toggle-button',
      title: 'Controlled Toggle Button',
      builder: _controlledToggleButton,
    ),
    DocsSection(
      id: 'components-toolbar--radio',
      title: 'Radio',
      builder: _radio,
    ),
    DocsSection(
      id: 'components-toolbar--controlled-radio',
      title: 'Controlled Radio',
      builder: _controlledRadio,
    ),
    DocsSection(
      id: 'components-toolbar--vertical',
      title: 'Vertical',
      builder: _vertical,
    ),
    DocsSection(
      id: 'components-toolbar--vertical-button',
      title: 'Vertical Button',
      builder: _verticalButton,
    ),
    DocsSection(
      id: 'components-toolbar--far-group',
      title: 'Far Group',
      builder: _farGroup,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'items',
      type: 'List<Widget>',
      description:
          "The row's children, in order. Dividers are ordinary members.",
    ),
    PropRow(
      name: 'size',
      type: 'FluentToolbarSize',
      defaultValue: 'FluentToolbarSize.medium',
      description: 'How far the surface is inset from its content.',
    ),
    PropRow(
      name: 'type',
      type: 'FluentToolbarType',
      defaultValue: 'FluentToolbarType.standard',
      description: 'Whether the surface is elevated.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentToolbarStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology as the name of the group.',
    ),
  ],
);

// #docregion components-toolbar--default
Widget _default(BuildContext context) => FluentToolbar(
  semanticLabel: 'Default',
  items: <Widget>[
    FluentButton.icon(
      icon: const Icon(FluentIcons.font_increase_24_regular),
      semanticLabel: 'Increase Font Size',
      appearance: FluentButtonAppearance.primary,
      onPressed: () {},
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.font_decrease_24_regular),
      semanticLabel: 'Decrease Font Size',
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.text_font_24_regular),
      semanticLabel: 'Reset Font Size',
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
    ),
    const FluentToolbarDivider(),
    FluentMenu(
      items: const <FluentMenuItem>[
        FluentMenuItem(label: Text('New ')),
        FluentMenuItem(label: Text('New Window')),
        FluentMenuItem(label: Text('Open File'), enabled: false),
        FluentMenuItem(label: Text('Open Folder')),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton.icon(
        icon: const Icon(FluentIcons.more_horizontal_24_filled),
        semanticLabel: 'More',
        appearance: FluentButtonAppearance.subtle,
        onPressed: toggle,
      ),
    ),
  ],
);
// #enddocregion components-toolbar--default

// #docregion components-toolbar--small
// Upstream draws a 2px black border with an 8px radius from an inline style.
// FluentToolbarStyle is the same override, one rung lower: it is merged over
// the size defaults, so the padding this section is about is untouched.
Widget _small(BuildContext context) => FluentToolbar(
  semanticLabel: 'Small',
  size: FluentToolbarSize.small,
  style: const FluentToolbarStyle(
    borderColor: WidgetStatePropertyAll<Color?>(Color(0xFF000000)),
    borderWidth: WidgetStatePropertyAll<double?>(2),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      BorderRadius.all(Radius.circular(8)),
    ),
  ),
  items: <Widget>[
    FluentButton.icon(
      icon: const Icon(FluentIcons.font_increase_24_regular),
      semanticLabel: 'Increase Font Size',
      appearance: FluentButtonAppearance.primary,
      onPressed: () {},
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.font_decrease_24_regular),
      semanticLabel: 'Decrease Font Size',
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.text_font_24_regular),
      semanticLabel: 'Reset Font Size',
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
    ),
  ],
);
// #enddocregion components-toolbar--small

// #docregion components-toolbar--medium
// Medium is the default size; it is named here for the same reason upstream
// names it — so the three padding ramps sit side by side in the docs.
Widget _medium(BuildContext context) => FluentToolbar(
  semanticLabel: 'Medium',
  size: FluentToolbarSize.medium,
  style: const FluentToolbarStyle(
    borderColor: WidgetStatePropertyAll<Color?>(Color(0xFF000000)),
    borderWidth: WidgetStatePropertyAll<double?>(2),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      BorderRadius.all(Radius.circular(8)),
    ),
  ),
  items: <Widget>[
    FluentButton.icon(
      icon: const Icon(FluentIcons.font_increase_24_regular),
      semanticLabel: 'Increase Font Size',
      appearance: FluentButtonAppearance.primary,
      onPressed: () {},
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.font_decrease_24_regular),
      semanticLabel: 'Decrease Font Size',
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.text_font_24_regular),
      semanticLabel: 'Reset Font Size',
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
    ),
  ],
);
// #enddocregion components-toolbar--medium

// #docregion components-toolbar--large
Widget _large(BuildContext context) => FluentToolbar(
  semanticLabel: 'Large Toolbar',
  size: FluentToolbarSize.large,
  style: const FluentToolbarStyle(
    borderColor: WidgetStatePropertyAll<Color?>(Color(0xFF000000)),
    borderWidth: WidgetStatePropertyAll<double?>(2),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      BorderRadius.all(Radius.circular(8)),
    ),
  ),
  items: <Widget>[
    FluentButton.icon(
      icon: const Icon(FluentIcons.font_increase_24_regular),
      semanticLabel: 'Increase Font Size',
      appearance: FluentButtonAppearance.primary,
      onPressed: () {},
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.font_decrease_24_regular),
      semanticLabel: 'Decrease Font Size',
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
    ),
    FluentButton.icon(
      icon: const Icon(FluentIcons.text_font_24_regular),
      semanticLabel: 'Reset Font Size',
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
    ),
  ],
);
// #enddocregion components-toolbar--large

// #docregion components-toolbar--overflow-items
// Upstream measures the row with the `Overflow` package and moves whatever no
// longer fits into the menu. FluentToolbar models no overflow — it lays its
// items out in a row that hugs its content and documents "supply your own
// overflow menu as the last item" — so every button stays visible and the
// "More items" menu lists the same commands, grouped exactly as upstream
// groups them. Recorded as `reduced`.
Widget _overflowItems(BuildContext context) => FluentToolbar(
  semanticLabel: 'Overflow',
  size: FluentToolbarSize.small,
  items: <Widget>[
    _overflowButton(
      FluentIcons.font_increase_24_regular,
      'Increase Font Size ( Group 1 )',
    ),
    _overflowButton(
      FluentIcons.font_decrease_24_regular,
      'Decrease Font Size ( Group 1 )',
    ),
    const FluentToolbarDivider(),
    _overflowButton(
      FluentIcons.font_increase_24_regular,
      'Increase Font Size ( Group 2 )',
    ),
    _overflowButton(
      FluentIcons.font_decrease_24_regular,
      'Decrease Font Size ( Group 2 )',
    ),
    _overflowButton(
      FluentIcons.text_font_24_regular,
      'Reset Font Size ( Group 2 )',
    ),
    _overflowButton(
      FluentIcons.font_increase_24_regular,
      'Increase Font Size ( Group 2 )',
    ),
    _overflowButton(
      FluentIcons.font_decrease_24_regular,
      'Decrease Font Size ( Group 2 )',
    ),
    const FluentToolbarDivider(),
    _overflowButton(
      FluentIcons.font_increase_24_regular,
      'Increase Font Size ( Group 3 )',
    ),
    _overflowButton(
      FluentIcons.font_decrease_24_regular,
      'Decrease Font Size ( Group 3 )',
    ),
    _overflowButton(
      FluentIcons.text_font_24_regular,
      'Reset Font Size ( Group 3 )',
    ),
    FluentMenu(
      items: const <FluentMenuItem>[
        FluentMenuItem(
          label: Text('Increase Font Size'),
          icon: Icon(FluentIcons.font_increase_24_regular),
        ),
        FluentMenuItem(
          label: Text('Decrease Font Size'),
          icon: Icon(FluentIcons.font_decrease_24_regular),
        ),
        FluentMenuItem.divider(),
        FluentMenuItem(
          label: Text('Increase Font Size'),
          icon: Icon(FluentIcons.font_increase_24_regular),
        ),
        FluentMenuItem(
          label: Text('Decrease Font Size'),
          icon: Icon(FluentIcons.font_decrease_24_regular),
        ),
        FluentMenuItem(
          label: Text('Reset Font Size'),
          icon: Icon(FluentIcons.text_font_24_regular),
        ),
        FluentMenuItem(
          label: Text('Increase Font Size'),
          icon: Icon(FluentIcons.font_increase_24_regular),
        ),
        FluentMenuItem(
          label: Text('Decrease Font Size'),
          icon: Icon(FluentIcons.font_decrease_24_regular),
        ),
        FluentMenuItem.divider(),
        FluentMenuItem(
          label: Text('Increase Font Size'),
          icon: Icon(FluentIcons.font_increase_24_regular),
        ),
        FluentMenuItem(
          label: Text('Decrease Font Size'),
          icon: Icon(FluentIcons.font_decrease_24_regular),
        ),
        FluentMenuItem(
          label: Text('Reset Font Size'),
          icon: Icon(FluentIcons.text_font_24_regular),
        ),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton.icon(
        icon: const Icon(FluentIcons.more_horizontal_20_filled),
        semanticLabel: 'More items',
        appearance: FluentButtonAppearance.subtle,
        onPressed: toggle,
      ),
    ),
  ],
);

Widget _overflowButton(IconData icon, String label) => FluentButton.icon(
  icon: Icon(icon),
  semanticLabel: label,
  appearance: FluentButtonAppearance.subtle,
  onPressed: () {},
);
// #enddocregion components-toolbar--overflow-items

// #docregion components-toolbar--with-tooltip
Widget _withTooltip(BuildContext context) => const _WithTooltip();

class _WithTooltip extends StatefulWidget {
  const _WithTooltip();

  @override
  State<_WithTooltip> createState() => _WithTooltipState();
}

class _WithTooltipState extends State<_WithTooltip> {
  // Upstream's `checkedValues`: a set of checked values per toggle-group name.
  final Map<String, Set<String>> _checkedValues = <String, Set<String>>{
    'textOptions': <String>{},
  };

  void _toggle(String name, String value) => setState(() {
    final Set<String> values = _checkedValues.putIfAbsent(
      name,
      () => <String>{},
    );
    if (!values.remove(value)) {
      values.add(value);
    }
  });

  // fluent_2_web ships no toggle button. A checked one is a FluentButton whose
  // colours are the button's own, re-resolved with WidgetState.selected folded
  // into the live interaction states — the state Fluent's *Selected tokens key
  // on. Folding it in rather than pinning a colour keeps hover, press and
  // disabled winning as they should.
  FluentButtonStyle _selectedStyle(FluentButtonAppearance appearance) {
    final FluentButtonStyle base = resolveFluentButtonStyle(
      resolveFluentButtonState(appearance: appearance),
      FluentTheme.of(context),
    );
    WidgetStateProperty<Color?> selected(WidgetStateProperty<Color?>? color) =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              color?.resolve(<WidgetState>{...states, WidgetState.selected}),
        );
    return FluentButtonStyle(
      backgroundColor: selected(base.backgroundColor),
      foregroundColor: selected(base.foregroundColor),
      borderColor: selected(base.borderColor),
    );
  }

  Widget _toggleButton({
    required String name,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final bool checked = _checkedValues[name]?.contains(value) ?? false;
    return FluentButton.icon(
      icon: Icon(icon),
      semanticLabel: label,
      appearance: FluentButtonAppearance.subtle,
      style: checked ? _selectedStyle(FluentButtonAppearance.subtle) : null,
      onPressed: () => _toggle(name, value),
    );
  }

  @override
  Widget build(BuildContext context) => FluentToolbar(
    semanticLabel: 'with Tooltip',
    size: FluentToolbarSize.small,
    items: <Widget>[
      FluentTooltip(
        withArrow: true,
        content: const Text('Makes selected text Bold'),
        semanticLabel: 'Makes selected text Bold',
        child: _toggleButton(
          name: 'textOptions',
          value: 'bold',
          icon: FluentIcons.text_bold_20_regular,
          label: 'Bold',
        ),
      ),
      FluentTooltip(
        withArrow: true,
        content: const Text('Makes selected text Italic'),
        semanticLabel: 'Makes selected text Italic',
        child: _toggleButton(
          name: 'textOptions',
          value: 'italic',
          icon: FluentIcons.text_italic_20_regular,
          label: 'Italic',
        ),
      ),
      FluentTooltip(
        withArrow: true,
        content: const Text('Makes selected text Underline'),
        semanticLabel: 'Makes selected text Underline',
        child: _toggleButton(
          name: 'textOptions',
          value: 'underline',
          icon: FluentIcons.text_underline_20_regular,
          label: 'Underline',
        ),
      ),
      const FluentToolbarDivider(),
      FluentTooltip(
        withArrow: true,
        content: const Text('Highlights the selected text'),
        semanticLabel: 'Highlights the selected text',
        child: FluentButton.icon(
          icon: const Icon(FluentIcons.highlight_20_filled),
          semanticLabel: 'Highlight',
          appearance: FluentButtonAppearance.subtle,
          onPressed: () {},
        ),
      ),
    ],
  );
}
// #enddocregion components-toolbar--with-tooltip

// #docregion components-toolbar--with-popover
Widget _withPopover(BuildContext context) => const _WithPopover();

class _WithPopover extends StatefulWidget {
  const _WithPopover();

  @override
  State<_WithPopover> createState() => _WithPopoverState();
}

class _WithPopoverState extends State<_WithPopover> {
  // Upstream's `open` state: which of the four popovers is showing, if any.
  String? _open;

  Widget _surface(String title) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(title, style: FluentTheme.of(context).typography.subtitle2),
      const SizedBox(height: 12),
      FluentButton(
        onPressed: () => setState(() => _open = null),
        child: const Text('Close'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => FluentToolbar(
    semanticLabel: 'with Popover',
    size: FluentToolbarSize.small,
    items: <Widget>[
      FluentPopover(
        withArrow: true,
        open: _open == 'first',
        onOpenChanged: (bool open) =>
            setState(() => _open = open ? 'first' : null),
        content: _surface('Insert Image'),
        child: FluentButton.icon(
          icon: const Icon(FluentIcons.image_24_regular),
          semanticLabel: 'Insert image',
          appearance: FluentButtonAppearance.subtle,
          onPressed: () => setState(() => _open = 'first'),
        ),
      ),
      FluentPopover(
        withArrow: true,
        open: _open == 'second',
        onOpenChanged: (bool open) =>
            setState(() => _open = open ? 'second' : null),
        content: _surface('Insert Table'),
        child: FluentButton.icon(
          icon: const Icon(FluentIcons.table_24_filled),
          semanticLabel: 'Insert Table',
          appearance: FluentButtonAppearance.primary,
          onPressed: () => setState(() => _open = 'second'),
        ),
      ),
      FluentPopover(
        withArrow: true,
        open: _open == 'third',
        onOpenChanged: (bool open) =>
            setState(() => _open = open ? 'third' : null),
        content: _surface('Insert Formula'),
        child: FluentButton.icon(
          icon: const Icon(FluentIcons.math_format_linear_24_regular),
          semanticLabel: 'Insert Formula',
          appearance: FluentButtonAppearance.subtle,
          onPressed: () => setState(() => _open = 'third'),
        ),
      ),
      const FluentToolbarDivider(),
      FluentPopover(
        withArrow: true,
        open: _open == 'fourth',
        onOpenChanged: (bool open) =>
            setState(() => _open = open ? 'fourth' : null),
        content: _surface('Quick Actions'),
        child: FluentButton(
          appearance: FluentButtonAppearance.subtle,
          onPressed: () => setState(() => _open = 'fourth'),
          child: const Text('Quick Actions'),
        ),
      ),
    ],
  );
}
// #enddocregion components-toolbar--with-popover

// #docregion components-toolbar--subtle
Widget _subtle(BuildContext context) => const _Subtle();

class _Subtle extends StatefulWidget {
  const _Subtle();

  @override
  State<_Subtle> createState() => _SubtleState();
}

class _SubtleState extends State<_Subtle> {
  // Upstream's `checkedValues`: a set of checked values per toggle-group name.
  final Map<String, Set<String>> _checkedValues = <String, Set<String>>{
    'textOptions': <String>{},
  };

  void _toggle(String name, String value) => setState(() {
    final Set<String> values = _checkedValues.putIfAbsent(
      name,
      () => <String>{},
    );
    if (!values.remove(value)) {
      values.add(value);
    }
  });

  // fluent_2_web ships no toggle button. A checked one is a FluentButton whose
  // colours are the button's own, re-resolved with WidgetState.selected folded
  // into the live interaction states — the state Fluent's *Selected tokens key
  // on.
  FluentButtonStyle _selectedStyle(FluentButtonAppearance appearance) {
    final FluentButtonStyle base = resolveFluentButtonStyle(
      resolveFluentButtonState(appearance: appearance),
      FluentTheme.of(context),
    );
    WidgetStateProperty<Color?> selected(WidgetStateProperty<Color?>? color) =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              color?.resolve(<WidgetState>{...states, WidgetState.selected}),
        );
    return FluentButtonStyle(
      backgroundColor: selected(base.backgroundColor),
      foregroundColor: selected(base.foregroundColor),
      borderColor: selected(base.borderColor),
    );
  }

  Widget _toggleButton({
    required String name,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final bool checked = _checkedValues[name]?.contains(value) ?? false;
    return FluentButton.icon(
      icon: Icon(icon),
      semanticLabel: label,
      appearance: FluentButtonAppearance.subtle,
      style: checked ? _selectedStyle(FluentButtonAppearance.subtle) : null,
      onPressed: () => _toggle(name, value),
    );
  }

  @override
  Widget build(BuildContext context) => FluentToolbar(
    semanticLabel: 'Subtle',
    items: <Widget>[
      _toggleButton(
        name: 'textOptions',
        value: 'bold',
        icon: FluentIcons.text_bold_24_regular,
        label: 'Bold',
      ),
      _toggleButton(
        name: 'textOptions',
        value: 'italic',
        icon: FluentIcons.text_italic_24_regular,
        label: 'Italic',
      ),
      _toggleButton(
        name: 'textOptions',
        value: 'underline',
        icon: FluentIcons.text_underline_24_regular,
        label: 'Underline',
      ),
    ],
  );
}
// #enddocregion components-toolbar--subtle

// #docregion components-toolbar--transparent
Widget _transparent(BuildContext context) => const _Transparent();

class _Transparent extends StatefulWidget {
  const _Transparent();

  @override
  State<_Transparent> createState() => _TransparentState();
}

class _TransparentState extends State<_Transparent> {
  // Upstream's `checkedValues`: a set of checked values per toggle-group name.
  final Map<String, Set<String>> _checkedValues = <String, Set<String>>{
    'textOptions': <String>{},
  };

  void _toggle(String name, String value) => setState(() {
    final Set<String> values = _checkedValues.putIfAbsent(
      name,
      () => <String>{},
    );
    if (!values.remove(value)) {
      values.add(value);
    }
  });

  // fluent_2_web ships no toggle button. A checked one is a FluentButton whose
  // colours are the button's own, re-resolved with WidgetState.selected folded
  // into the live interaction states — the state Fluent's *Selected tokens key
  // on.
  FluentButtonStyle _selectedStyle(FluentButtonAppearance appearance) {
    final FluentButtonStyle base = resolveFluentButtonStyle(
      resolveFluentButtonState(appearance: appearance),
      FluentTheme.of(context),
    );
    WidgetStateProperty<Color?> selected(WidgetStateProperty<Color?>? color) =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              color?.resolve(<WidgetState>{...states, WidgetState.selected}),
        );
    return FluentButtonStyle(
      backgroundColor: selected(base.backgroundColor),
      foregroundColor: selected(base.foregroundColor),
      borderColor: selected(base.borderColor),
    );
  }

  Widget _toggleButton({
    required String name,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final bool checked = _checkedValues[name]?.contains(value) ?? false;
    return FluentButton.icon(
      icon: Icon(icon),
      semanticLabel: label,
      appearance: FluentButtonAppearance.transparent,
      style: checked
          ? _selectedStyle(FluentButtonAppearance.transparent)
          : null,
      onPressed: () => _toggle(name, value),
    );
  }

  @override
  Widget build(BuildContext context) => FluentToolbar(
    semanticLabel: 'transparent',
    items: <Widget>[
      _toggleButton(
        name: 'textOptions',
        value: 'bold',
        icon: FluentIcons.text_bold_24_regular,
        label: 'Bold',
      ),
      _toggleButton(
        name: 'textOptions',
        value: 'italic',
        icon: FluentIcons.text_italic_24_regular,
        label: 'Italic',
      ),
      _toggleButton(
        name: 'textOptions',
        value: 'underline',
        icon: FluentIcons.text_underline_24_regular,
        label: 'Underline',
      ),
    ],
  );
}
// #enddocregion components-toolbar--transparent

// #docregion components-toolbar--controlled-toggle-button
Widget _controlledToggleButton(BuildContext context) =>
    const _ControlledToggleButton();

class _ControlledToggleButton extends StatefulWidget {
  const _ControlledToggleButton();

  @override
  State<_ControlledToggleButton> createState() =>
      _ControlledToggleButtonState();
}

class _ControlledToggleButtonState extends State<_ControlledToggleButton> {
  // Upstream owns `checkedValues` in the story and feeds it back through
  // `onCheckedValueChange`. In Flutter the caller already owns the state, so
  // this is the same story with the round trip written out as setState.
  final Map<String, Set<String>> _checkedValues = <String, Set<String>>{
    'textOptions': <String>{'bold', 'italic'},
  };

  void _toggle(String name, String value) => setState(() {
    final Set<String> values = _checkedValues.putIfAbsent(
      name,
      () => <String>{},
    );
    if (!values.remove(value)) {
      values.add(value);
    }
  });

  // fluent_2_web ships no toggle button. A checked one is a FluentButton whose
  // colours are the button's own, re-resolved with WidgetState.selected folded
  // into the live interaction states — the state Fluent's *Selected tokens key
  // on.
  FluentButtonStyle _selectedStyle(FluentButtonAppearance appearance) {
    final FluentButtonStyle base = resolveFluentButtonStyle(
      resolveFluentButtonState(appearance: appearance),
      FluentTheme.of(context),
    );
    WidgetStateProperty<Color?> selected(WidgetStateProperty<Color?>? color) =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              color?.resolve(<WidgetState>{...states, WidgetState.selected}),
        );
    return FluentButtonStyle(
      backgroundColor: selected(base.backgroundColor),
      foregroundColor: selected(base.foregroundColor),
      borderColor: selected(base.borderColor),
    );
  }

  Widget _toggleButton({
    required String name,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final bool checked = _checkedValues[name]?.contains(value) ?? false;
    return FluentButton.icon(
      icon: Icon(icon),
      semanticLabel: label,
      appearance: FluentButtonAppearance.subtle,
      style: checked ? _selectedStyle(FluentButtonAppearance.subtle) : null,
      onPressed: () => _toggle(name, value),
    );
  }

  @override
  Widget build(BuildContext context) => FluentToolbar(
    semanticLabel: 'with controlled Toggle Button',
    items: <Widget>[
      _toggleButton(
        name: 'textOptions',
        value: 'bold',
        icon: FluentIcons.text_bold_24_regular,
        label: 'Bold',
      ),
      _toggleButton(
        name: 'textOptions',
        value: 'italic',
        icon: FluentIcons.text_italic_24_regular,
        label: 'Italic',
      ),
      _toggleButton(
        name: 'textOptions',
        value: 'underline',
        icon: FluentIcons.text_underline_24_regular,
        label: 'Underline',
      ),
    ],
  );
}
// #enddocregion components-toolbar--controlled-toggle-button

// #docregion components-toolbar--radio
Widget _radio(BuildContext context) => const _Radio();

class _Radio extends StatefulWidget {
  const _Radio();

  @override
  State<_Radio> createState() => _RadioState();
}

class _RadioState extends State<_Radio> {
  // Upstream's `defaultCheckedValues`. One value per group rather than a set,
  // which is the whole difference between a radio group and a toggle group.
  final Map<String, String> _checkedValues = <String, String>{
    'textOptions': 'center',
  };

  // fluent_2_web ships no toolbar radio button. A checked one is a
  // FluentButton whose colours are the button's own, re-resolved with
  // WidgetState.selected folded into the live interaction states — the state
  // Fluent's *Selected tokens key on.
  FluentButtonStyle _selectedStyle(FluentButtonAppearance appearance) {
    final FluentButtonStyle base = resolveFluentButtonStyle(
      resolveFluentButtonState(appearance: appearance),
      FluentTheme.of(context),
    );
    WidgetStateProperty<Color?> selected(WidgetStateProperty<Color?>? color) =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              color?.resolve(<WidgetState>{...states, WidgetState.selected}),
        );
    return FluentButtonStyle(
      backgroundColor: selected(base.backgroundColor),
      foregroundColor: selected(base.foregroundColor),
      borderColor: selected(base.borderColor),
    );
  }

  Widget _radioButton({
    required String name,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final bool checked = _checkedValues[name] == value;
    return FluentButton.icon(
      icon: Icon(icon),
      semanticLabel: label,
      appearance: FluentButtonAppearance.subtle,
      style: checked ? _selectedStyle(FluentButtonAppearance.subtle) : null,
      onPressed: () => setState(() => _checkedValues[name] = value),
    );
  }

  @override
  Widget build(BuildContext context) => FluentToolbar(
    semanticLabel: 'with Radio Buttons',
    items: <Widget>[
      _radioButton(
        name: 'textOptions',
        value: 'left',
        icon: FluentIcons.align_left_24_regular,
        label: 'Align left',
      ),
      _radioButton(
        name: 'textOptions',
        value: 'center',
        icon: FluentIcons.align_center_horizontal_24_regular,
        label: 'Align Center',
      ),
      _radioButton(
        name: 'textOptions',
        value: 'right',
        icon: FluentIcons.align_right_24_regular,
        label: 'Align Right',
      ),
    ],
  );
}
// #enddocregion components-toolbar--radio

// #docregion components-toolbar--controlled-radio
Widget _controlledRadio(BuildContext context) => const _ControlledRadio();

class _ControlledRadio extends StatefulWidget {
  const _ControlledRadio();

  @override
  State<_ControlledRadio> createState() => _ControlledRadioState();
}

class _ControlledRadioState extends State<_ControlledRadio> {
  // Upstream owns `checkedValues` in the story and feeds it back through
  // `onCheckedValueChange`. In Flutter the caller already owns the state, so
  // this is the same story with the round trip written out as setState.
  final Map<String, String> _checkedValues = <String, String>{
    'textOptions': 'center',
  };

  // fluent_2_web ships no toolbar radio button. A checked one is a
  // FluentButton whose colours are the button's own, re-resolved with
  // WidgetState.selected folded into the live interaction states — the state
  // Fluent's *Selected tokens key on.
  FluentButtonStyle _selectedStyle(FluentButtonAppearance appearance) {
    final FluentButtonStyle base = resolveFluentButtonStyle(
      resolveFluentButtonState(appearance: appearance),
      FluentTheme.of(context),
    );
    WidgetStateProperty<Color?> selected(WidgetStateProperty<Color?>? color) =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              color?.resolve(<WidgetState>{...states, WidgetState.selected}),
        );
    return FluentButtonStyle(
      backgroundColor: selected(base.backgroundColor),
      foregroundColor: selected(base.foregroundColor),
      borderColor: selected(base.borderColor),
    );
  }

  Widget _radioButton({
    required String name,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final bool checked = _checkedValues[name] == value;
    return FluentButton.icon(
      icon: Icon(icon),
      semanticLabel: label,
      appearance: FluentButtonAppearance.subtle,
      style: checked ? _selectedStyle(FluentButtonAppearance.subtle) : null,
      onPressed: () => setState(() => _checkedValues[name] = value),
    );
  }

  @override
  Widget build(BuildContext context) => FluentToolbar(
    semanticLabel: 'with controlled Radio Button',
    items: <Widget>[
      _radioButton(
        name: 'textOptions',
        value: 'left',
        icon: FluentIcons.align_left_24_regular,
        label: 'Align left',
      ),
      _radioButton(
        name: 'textOptions',
        value: 'center',
        icon: FluentIcons.align_center_horizontal_24_regular,
        label: 'Align Center',
      ),
      _radioButton(
        name: 'textOptions',
        value: 'right',
        icon: FluentIcons.align_right_24_regular,
        label: 'Align Right',
      ),
    ],
  );
}
// #enddocregion components-toolbar--controlled-radio

// #docregion components-toolbar--vertical
Widget _vertical(BuildContext context) => const _Vertical();

class _Vertical extends StatefulWidget {
  const _Vertical();

  @override
  State<_Vertical> createState() => _VerticalState();
}

class _VerticalState extends State<_Vertical> {
  // Upstream's `checkedValues`: a set of checked values per toggle-group name.
  final Map<String, Set<String>> _checkedValues = <String, Set<String>>{
    'text': <String>{},
  };

  void _toggle(String name, String value) => setState(() {
    final Set<String> values = _checkedValues.putIfAbsent(
      name,
      () => <String>{},
    );
    if (!values.remove(value)) {
      values.add(value);
    }
  });

  // fluent_2_web ships no toggle button. A checked one is a FluentButton whose
  // colours are the button's own, re-resolved with WidgetState.selected folded
  // into the live interaction states — the state Fluent's *Selected tokens key
  // on.
  FluentButtonStyle _selectedStyle(FluentButtonAppearance appearance) {
    final FluentButtonStyle base = resolveFluentButtonStyle(
      resolveFluentButtonState(appearance: appearance),
      FluentTheme.of(context),
    );
    WidgetStateProperty<Color?> selected(WidgetStateProperty<Color?>? color) =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              color?.resolve(<WidgetState>{...states, WidgetState.selected}),
        );
    return FluentButtonStyle(
      backgroundColor: selected(base.backgroundColor),
      foregroundColor: selected(base.foregroundColor),
      borderColor: selected(base.borderColor),
    );
  }

  Widget _toggleButton({
    required String name,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final bool checked = _checkedValues[name]?.contains(value) ?? false;
    return FluentButton.icon(
      icon: Icon(icon),
      semanticLabel: label,
      appearance: FluentButtonAppearance.subtle,
      style: checked ? _selectedStyle(FluentButtonAppearance.subtle) : null,
      onPressed: () => _toggle(name, value),
    );
  }

  // FluentToolbar has no `vertical` axis — `buildFluentToolbar` lays its items
  // out in a Row, and putting a Column inside a single item would collapse the
  // three buttons into one roving-focus stop. So the vertical toolbar is a
  // Column of the same buttons, each keeping its own tab stop. Recorded as
  // `nearest-widget`.
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Vertical',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _toggleButton(
          name: 'text',
          value: 'bold',
          icon: FluentIcons.text_bold_24_regular,
          label: 'Bold',
        ),
        _toggleButton(
          name: 'text',
          value: 'italic',
          icon: FluentIcons.text_italic_24_regular,
          label: 'Italic',
        ),
        _toggleButton(
          name: 'text',
          value: 'underline',
          icon: FluentIcons.text_underline_24_regular,
          label: 'Underline',
        ),
      ],
    ),
  );
}
// #enddocregion components-toolbar--vertical

// #docregion components-toolbar--vertical-button
Widget _verticalButton(BuildContext context) => FluentToolbar(
  semanticLabel: 'Vertical Button',
  items: <Widget>[
    FluentButton(
      appearance: FluentButtonAppearance.primary,
      onPressed: () {},
      child: _stacked(
        context,
        FluentButtonAppearance.primary,
        FluentIcons.font_increase_20_regular,
        'Increase',
      ),
    ),
    FluentButton(
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
      child: _stacked(
        context,
        FluentButtonAppearance.subtle,
        FluentIcons.font_decrease_20_regular,
        'Decrease',
      ),
    ),
    FluentButton(
      appearance: FluentButtonAppearance.subtle,
      onPressed: () {},
      child: _stacked(
        context,
        FluentButtonAppearance.subtle,
        FluentIcons.text_font_20_regular,
        'Reset',
      ),
    ),
  ],
);

// FluentButton's `iconPosition` is before/after only, so a vertical button is
// built as the button's label: an icon stacked over the text. The `icon` slot
// is what carries the button's foreground colour to a glyph, so a stacked icon
// has to read that colour itself — it is taken from the button's own resolved
// style at rest, which means it tracks the theme but not hover.
Widget _stacked(
  BuildContext context,
  FluentButtonAppearance appearance,
  IconData icon,
  String label,
) {
  final Color? foreground = resolveFluentButtonStyle(
    resolveFluentButtonState(appearance: appearance),
    FluentTheme.of(context),
  ).foregroundColor?.resolve(const <WidgetState>{});

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, color: foreground),
      const SizedBox(height: 2),
      Text(label),
    ],
  );
}
// #enddocregion components-toolbar--vertical-button

// #docregion components-toolbar--far-group
// Upstream is one Toolbar with `justifyContent: space-between` and two
// ToolbarGroups. FluentToolbar hugs its content — `buildFluentToolbar` builds a
// Row with `mainAxisSize.min` — so it can never spread its own items. The two
// groups are therefore two toolbars pushed apart by the Row that holds them,
// which is the same picture and keeps each group's arrow navigation intact.
Widget _farGroup(BuildContext context) => Semantics(
  container: true,
  label: 'with Separeted Groups',
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      FluentToolbar(
        items: <Widget>[
          _farGroupButton(
            FluentIcons.font_increase_20_regular,
            'Increase Font Size',
            primary: true,
          ),
          _farGroupButton(
            FluentIcons.font_decrease_20_regular,
            'Decrease Font Size',
          ),
          _farGroupButton(FluentIcons.text_font_20_regular, 'Reset Font Size'),
          const FluentToolbarDivider(),
          _farGroupButton(
            FluentIcons.font_increase_20_regular,
            'Increase Font Size',
            primary: true,
          ),
          _farGroupButton(
            FluentIcons.font_decrease_20_regular,
            'Decrease Font Size',
          ),
          _farGroupButton(FluentIcons.text_font_20_regular, 'Reset Font Size'),
        ],
      ),
      FluentToolbar(
        items: <Widget>[
          _farGroupButton(
            FluentIcons.font_increase_20_regular,
            'Increase Font Size',
            primary: true,
          ),
          _farGroupButton(
            FluentIcons.font_decrease_20_regular,
            'Decrease Font Size',
          ),
          _farGroupButton(FluentIcons.text_font_20_regular, 'Reset Font Size'),
        ],
      ),
    ],
  ),
);

Widget _farGroupButton(IconData icon, String label, {bool primary = false}) =>
    FluentButton.icon(
      icon: Icon(icon),
      semanticLabel: label,
      appearance: primary
          ? FluentButtonAppearance.primary
          : FluentButtonAppearance.subtle,
      onPressed: () {},
    );
// #enddocregion components-toolbar--far-group
