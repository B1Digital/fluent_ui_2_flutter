import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Nav docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage navPage = DocsPage(
  id: 'components-nav',
  title: 'Nav',
  description:
      'A component that provides up to two levels of nesting for navigation.',
  source: 'lib/pages/components_nav.dart',
  sections: <DocsSection>[
    DocsSection(id: 'components-nav--basic', title: 'Basic', builder: _basic),
    DocsSection(
      id: 'components-nav--variable-density-items',
      title: 'Variable Density Items',
      builder: _variableDensityItems,
    ),
    DocsSection(
      id: 'components-nav--controlled',
      title: 'Controlled',
      builder: _controlled,
    ),
    DocsSection(
      id: 'components-nav--split-nav-items',
      title: 'Split Nav Items',
      builder: _splitNavItems,
    ),
    DocsSection(
      id: 'components-nav--custom-motion',
      title: 'Custom Motion',
      description:
          'NavDrawer animations can be customized using the Motion APIs, '
          'together with the surfaceMotion prop.',
      builder: _customMotion,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'children',
      type: 'List<Widget>',
      description: 'The rows, in order.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentNavSize',
      defaultValue: 'FluentNavSize.medium',
      description: 'Row height and density.',
    ),
    PropRow(
      name: 'tabbable',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether every row is a tab stop, rather than the nav being one.',
    ),
    PropRow(
      name: 'selectedValue',
      type: 'Object?',
      defaultValue: 'null',
      description: "The selected row's value, when the caller owns it.",
    ),
    PropRow(
      name: 'defaultSelectedValue',
      type: 'Object?',
      defaultValue: 'null',
      description: 'The initially selected value while uncontrolled.',
    ),
    PropRow(
      name: 'onSelect',
      type: 'ValueChanged<Object>?',
      defaultValue: 'null',
      description:
          'Called with the value the nav is moving to, before it is applied.',
    ),
    PropRow(
      name: 'openCategories',
      type: 'Set<Object>?',
      defaultValue: 'null',
      description: 'The open category set, when the caller owns it.',
    ),
    PropRow(
      name: 'defaultOpenCategories',
      type: 'Set<Object>',
      defaultValue: '{}',
      description: 'The initially open categories while uncontrolled.',
    ),
    PropRow(
      name: 'onOpenChange',
      type: 'ValueChanged<Set<Object>>?',
      defaultValue: 'null',
      description:
          'Called with the open set the nav is moving to, before it is '
          'applied.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology as the name of this navigation '
          'region.',
    ),
  ],
);

// #docregion components-nav--basic
// The demo sits in its own `Overlay` so that picking `Overlay (Default)` opens
// the drawer over this box rather than over the whole docs page — upstream's
// story runs in an iframe and gets that scoping for free.
Widget _basic(BuildContext context) => SizedBox(
  height: 600,
  child: Overlay(
    initialEntries: <OverlayEntry>[
      OverlayEntry(builder: (BuildContext context) => const _Basic()),
    ],
  ),
);

class _Basic extends StatefulWidget {
  const _Basic();

  @override
  State<_Basic> createState() => _BasicState();
}

class _BasicState extends State<_Basic> {
  bool _isOpen = true;
  bool _enabledLinks = true;
  FluentDrawerType _type = FluentDrawerType.inline;
  bool _isMultiple = true;
  Set<Object> _openCategories = <Object>{};

  // Upstream swaps every row's `href` between 'https://www.bing.com' and an
  // empty string. A FluentNavItem is a button rather than an anchor, so the
  // Links switch drives `onPressed`: null still selects the row, it just
  // navigates nowhere.
  VoidCallback? get _onLinkPressed => _enabledLinks ? _openLink : null;

  void _openLink() {
    // An app would route to 'https://www.bing.com' from here.
  }

  // FluentNav has no `multiple` flag, so single-expand is expressed by keeping
  // only the category that was just opened.
  void _onOpenChange(Set<Object> next) {
    final opened = next.difference(_openCategories);
    setState(
      () => _openCategories = _isMultiple || opened.isEmpty ? next : opened,
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      FluentNavDrawer(
        open: _isOpen,
        type: _type,
        separator: true,
        onDismiss: () => setState(() => _isOpen = false),
        semanticLabel: 'Contoso HR',
        header: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentTooltip(
              content: const Text('Close Navigation'),
              child: FluentHamburger(
                onPressed: () => setState(() => _isOpen = !_isOpen),
                semanticLabel: 'Close Navigation',
              ),
            ),
          ),
        ],
        child: SingleChildScrollView(
          child: FluentNav(
            defaultSelectedValue: '2',
            openCategories: _openCategories,
            onOpenChange: _onOpenChange,
            children: <Widget>[
              FluentNavAppItem(
                icon: const Icon(FluentIcons.person_circle_32_regular),
                onPressed: _onLinkPressed,
                child: const Text('Contoso HR'),
              ),
              FluentNavItem(
                value: '1',
                icon: const Icon(FluentIcons.board_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Dashboard'),
              ),
              FluentNavItem(
                value: '2',
                icon: const Icon(FluentIcons.megaphone_loud_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Announcements'),
              ),
              FluentNavItem(
                value: '3',
                icon: const Icon(FluentIcons.person_lightbulb_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Employee Spotlight'),
              ),
              FluentNavItem(
                value: '4',
                icon: const Icon(FluentIcons.person_search_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Profile Search'),
              ),
              FluentNavItem(
                value: '5',
                icon: const Icon(FluentIcons.preview_link_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Performance Reviews'),
              ),
              const FluentNavSectionHeader(child: Text('Employee Management')),
              FluentNavCategory(
                value: '6',
                icon: const Icon(FluentIcons.note_pin_20_regular),
                child: const Text('Job Postings'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '7',
                    onPressed: _onLinkPressed,
                    child: const Text(
                      'Lorem ipsum dolor sit amet, consectetuer adipiscing elit',
                    ),
                  ),
                  FluentNavSubItem(
                    value: '8',
                    onPressed: _onLinkPressed,
                    child: const Text(
                      'Lorem ipsum dolor sit amet, consectetuer adipiscing elit',
                    ),
                  ),
                ],
              ),
              const FluentNavItem(
                value: '9',
                icon: Icon(FluentIcons.people_20_regular),
                child: Text('Interviews'),
              ),
              const FluentNavSectionHeader(child: Text('Benefits')),
              const FluentNavItem(
                value: '10',
                icon: Icon(FluentIcons.heart_pulse_20_regular),
                child: Text('Health Plans'),
              ),
              FluentNavCategory(
                value: '11',
                icon: const Icon(FluentIcons.person_20_regular),
                child: const Text('Retirement'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '13',
                    onPressed: _onLinkPressed,
                    child: const Text('Plan Information'),
                  ),
                  FluentNavSubItem(
                    value: '14',
                    onPressed: _onLinkPressed,
                    child: const Text('Fund Performance'),
                  ),
                ],
              ),
              const FluentNavSectionHeader(child: Text('Learning')),
              const FluentNavItem(
                value: '15',
                icon: Icon(FluentIcons.box_multiple_20_regular),
                child: Text('Training Programs'),
              ),
              FluentNavCategory(
                value: '16',
                icon: const Icon(FluentIcons.people_star_20_regular),
                child: const Text('Career Development'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '17',
                    onPressed: _onLinkPressed,
                    child: const Text('Career Paths'),
                  ),
                  FluentNavSubItem(
                    value: '18',
                    onPressed: _onLinkPressed,
                    child: const Text('Planning'),
                  ),
                ],
              ),
              const FluentNavDivider(),
              const FluentNavItem(
                value: '19',
                icon: Icon(FluentIcons.data_area_20_regular),
                child: Text('Workforce Data'),
              ),
              FluentNavItem(
                value: '20',
                icon: const Icon(
                  FluentIcons.document_bullet_list_multiple_20_regular,
                ),
                onPressed: _onLinkPressed,
                child: const Text('Reports'),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FluentTooltip(
                content: const Text('Toggle navigation pane'),
                child: FluentHamburger(
                  onPressed: () => setState(() => _isOpen = !_isOpen),
                  expanded: _isOpen,
                  semanticLabel: 'Toggle navigation pane',
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, start: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: <Widget>[
                    const FluentLabel(child: Text('Type')),
                    FluentRadioGroup<FluentDrawerType>(
                      value: _type,
                      onChanged: (FluentDrawerType value) =>
                          setState(() => _type = value),
                      semanticLabel: 'Type',
                      children: const <Widget>[
                        FluentRadio<FluentDrawerType>(
                          value: FluentDrawerType.overlay,
                          label: Text('Overlay (Default)'),
                        ),
                        FluentRadio<FluentDrawerType>(
                          value: FluentDrawerType.inline,
                          label: Text('Inline'),
                        ),
                      ],
                    ),
                    const FluentLabel(child: Text('Links')),
                    FluentSwitch(
                      checked: _enabledLinks,
                      onChanged: (bool value) =>
                          setState(() => _enabledLinks = value),
                      label: Text(_enabledLinks ? 'Enabled' : 'Disabled'),
                      semanticLabel: 'Links',
                    ),
                    const FluentLabel(
                      child: Text('Allow multiple expanded categories'),
                    ),
                    FluentSwitch(
                      checked: _isMultiple,
                      onChanged: (bool value) =>
                          setState(() => _isMultiple = value),
                      label: Text(_isMultiple ? 'Multiple' : 'Single'),
                      semanticLabel: 'Allow multiple expanded categories',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-nav--basic

// #docregion components-nav--variable-density-items
Widget _variableDensityItems(BuildContext context) =>
    const SizedBox(height: 600, child: _VariableDensityItems());

class _VariableDensityItems extends StatefulWidget {
  const _VariableDensityItems();

  @override
  State<_VariableDensityItems> createState() => _VariableDensityItemsState();
}

class _VariableDensityItemsState extends State<_VariableDensityItems> {
  FluentNavSize _density = FluentNavSize.small;
  bool _enabledLinks = true;
  bool _isAppItemIconPresent = true;
  bool _isAppItemStatic = true;

  // Upstream swaps every row's `href` between 'https://www.bing.com' and an
  // empty string. A FluentNavItem is a button rather than an anchor, so the
  // Links switch drives `onPressed`.
  VoidCallback? get _onLinkPressed => _enabledLinks ? _openLink : null;

  void _openLink() {
    // An app would route to 'https://www.bing.com' from here.
  }

  Widget? _appItemIcon() {
    if (!_isAppItemIconPresent) return null;
    return _density == FluentNavSize.small
        ? const Icon(FluentIcons.person_circle_24_regular)
        : const Icon(FluentIcons.person_circle_32_regular);
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      FluentNavDrawer(
        open: true,
        type: FluentDrawerType.inline,
        separator: true,
        semanticLabel: 'Contoso HR',
        header: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentTooltip(
              content: const Text('Navigation'),
              child: FluentHamburger(
                onPressed: () {},
                semanticLabel: 'Navigation',
              ),
            ),
          ),
        ],
        child: SingleChildScrollView(
          child: FluentNav(
            size: _density,
            defaultSelectedValue: '7',
            defaultOpenCategories: const <Object>{'6'},
            children: <Widget>[
              FluentNavAppItem(
                icon: _appItemIcon(),
                // A static app item is one with nothing to activate; upstream
                // switches between `AppItemStatic` and an `AppItem` link.
                onPressed: _isAppItemStatic ? null : _onLinkPressed,
                child: const Text('Contoso HR'),
              ),
              FluentNavItem(
                value: '1',
                icon: const Icon(FluentIcons.board_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Dashboard'),
              ),
              FluentNavItem(
                value: '2',
                icon: const Icon(FluentIcons.megaphone_loud_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Announcements'),
              ),
              FluentNavItem(
                value: '3',
                icon: const Icon(FluentIcons.person_lightbulb_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Employee Spotlight'),
              ),
              FluentNavItem(
                value: '4',
                icon: const Icon(FluentIcons.person_search_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Profile Search'),
              ),
              FluentNavItem(
                value: '5',
                icon: const Icon(FluentIcons.preview_link_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Performance Reviews'),
              ),
              const FluentNavSectionHeader(child: Text('Employee Management')),
              FluentNavCategory(
                value: '6',
                icon: const Icon(FluentIcons.note_pin_20_regular),
                child: const Text('Job Postings'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '7',
                    onPressed: _onLinkPressed,
                    child: const Text('Openings'),
                  ),
                  FluentNavSubItem(
                    value: '8',
                    onPressed: _onLinkPressed,
                    child: const Text('Submissions'),
                  ),
                ],
              ),
              const FluentNavItem(
                value: '9',
                icon: Icon(FluentIcons.people_20_regular),
                child: Text('Interviews'),
              ),
              const FluentNavSectionHeader(child: Text('Benefits')),
              const FluentNavItem(
                value: '10',
                icon: Icon(FluentIcons.heart_pulse_20_regular),
                child: Text('Health Plans'),
              ),
              FluentNavCategory(
                value: '11',
                icon: const Icon(FluentIcons.person_20_regular),
                child: const Text('Retirement'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '13',
                    onPressed: _onLinkPressed,
                    child: const Text('Plan Information'),
                  ),
                  FluentNavSubItem(
                    value: '14',
                    onPressed: _onLinkPressed,
                    child: const Text('Fund Performance'),
                  ),
                ],
              ),
              const FluentNavDivider(),
              const FluentNavItem(
                value: '15',
                icon: Icon(FluentIcons.box_multiple_20_regular),
                child: Text('Training Programs'),
              ),
              FluentNavCategory(
                value: '16',
                icon: const Icon(FluentIcons.people_star_20_regular),
                child: const Text('Career Development'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '17',
                    onPressed: _onLinkPressed,
                    child: const Text('Career Paths'),
                  ),
                  FluentNavSubItem(
                    value: '18',
                    onPressed: _onLinkPressed,
                    child: const Text('Planning'),
                  ),
                ],
              ),
              const FluentNavItem(
                value: '19',
                icon: Icon(FluentIcons.data_area_20_regular),
                child: Text('Workforce Data'),
              ),
              FluentNavItem(
                value: '20',
                icon: const Icon(
                  FluentIcons.document_bullet_list_multiple_20_regular,
                ),
                onPressed: _onLinkPressed,
                child: const Text('Reports'),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 4, start: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: <Widget>[
                const FluentLabel(child: Text('Density')),
                FluentRadioGroup<FluentNavSize>(
                  value: _density,
                  onChanged: (FluentNavSize value) =>
                      setState(() => _density = value),
                  semanticLabel: 'Density',
                  children: const <Widget>[
                    FluentRadio<FluentNavSize>(
                      value: FluentNavSize.medium,
                      label: Text('Medium'),
                    ),
                    FluentRadio<FluentNavSize>(
                      value: FluentNavSize.small,
                      label: Text('Small'),
                    ),
                  ],
                ),
                const FluentLabel(child: Text('Links')),
                FluentSwitch(
                  checked: _enabledLinks,
                  onChanged: (bool value) =>
                      setState(() => _enabledLinks = value),
                  label: Text(_enabledLinks ? 'Enabled' : 'Disabled'),
                  semanticLabel: 'Links',
                ),
                const FluentLabel(child: Text('App Item')),
                FluentSwitch(
                  checked: _isAppItemStatic,
                  onChanged: (bool value) =>
                      setState(() => _isAppItemStatic = value),
                  label: Text(_isAppItemStatic ? 'Static' : 'Href'),
                  semanticLabel: 'App Item',
                ),
                const FluentLabel(child: Text('App Item Icon')),
                FluentSwitch(
                  checked: _isAppItemIconPresent,
                  onChanged: (bool value) =>
                      setState(() => _isAppItemIconPresent = value),
                  label: Text(_isAppItemIconPresent ? 'Present' : 'Absent'),
                  semanticLabel: 'App Item Icon',
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-nav--variable-density-items

// #docregion components-nav--controlled
// A list of navItemValues and their potential children.
// It exactly matches the NavDrawer in the story below.
// This is how a consumer might store them in their app.
const List<(String, List<String>)> _navItemValueList = <(String, List<String>)>[
  ('1', <String>[]),
  ('2', <String>[]),
  ('3', <String>[]),
  ('4', <String>[]),
  ('5', <String>[]),
  ('6', <String>['7', '8']),
  ('9', <String>[]),
  ('10', <String>[]),
  ('11', <String>['12', '13']),
  ('14', <String>[]),
  ('15', <String>[]),
  ('16', <String>['17', '18']),
  ('19', <String>[]),
  ('20', <String>[]),
];

Widget _controlled(BuildContext context) =>
    const SizedBox(height: 600, child: _Controlled());

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  Set<Object> _openCategories = <Object>{'6', '11'};
  Object _selectedValue = '7';
  bool _isMultiple = true;
  int _page = 0;

  // Upstream picks a page at random. `dart:math` is outside this example's
  // imports, so Navigate walks the list instead — same shape, no surprise.
  (String?, String) _pageAt(int index) {
    final (parent, children) =
        _navItemValueList[index % _navItemValueList.length];
    if (children.isEmpty) return (null, parent);
    return (parent, children[index % children.length]);
  }

  void _handleNavigationClick() {
    setState(() {
      _page++;
      final (category, value) = _pageAt(_page);
      _selectedValue = value;
      // A sub-item is only reachable while its category is open, so navigating
      // into one opens it. Upstream stores the category instead.
      if (category != null) {
        _openCategories = <Object>{..._openCategories, category};
      }
    });
  }

  void _handleCategoryToggle(Set<Object> next) {
    final opened = next.difference(_openCategories);
    setState(
      () => _openCategories = _isMultiple || opened.isEmpty ? next : opened,
    );
  }

  void _handleMultipleChange(bool checked) {
    setState(() {
      _isMultiple = checked;
      _openCategories = checked ? <Object>{'6', '11'} : <Object>{'6'};
    });
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      FluentNavDrawer(
        open: true,
        type: FluentDrawerType.inline,
        separator: true,
        semanticLabel: 'Contoso HR',
        header: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentTooltip(
              content: const Text('Navigation'),
              child: FluentHamburger(
                onPressed: () {},
                semanticLabel: 'Navigation',
              ),
            ),
          ),
        ],
        child: SingleChildScrollView(
          child: FluentNav(
            // This is a controlled example, so the value and the open set are
            // both owned here rather than by the nav.
            tabbable: true,
            selectedValue: _selectedValue,
            onSelect: (Object value) => setState(() => _selectedValue = value),
            openCategories: _openCategories,
            onOpenChange: _handleCategoryToggle,
            children: const <Widget>[
              FluentNavAppItem(
                icon: Icon(FluentIcons.person_circle_32_regular),
                child: Text('Contoso HR'),
              ),
              FluentNavItem(
                value: '1',
                icon: Icon(FluentIcons.board_20_regular),
                child: Text('Dashboard'),
              ),
              FluentNavItem(
                value: '2',
                icon: Icon(FluentIcons.megaphone_loud_20_regular),
                child: Text('Announcements'),
              ),
              FluentNavItem(
                value: '3',
                icon: Icon(FluentIcons.person_lightbulb_20_regular),
                child: Text('Employee Spotlight'),
              ),
              FluentNavItem(
                value: '4',
                icon: Icon(FluentIcons.person_search_20_regular),
                child: Text('Profile Search'),
              ),
              FluentNavItem(
                value: '5',
                icon: Icon(FluentIcons.preview_link_20_regular),
                child: Text('Performance Reviews'),
              ),
              FluentNavSectionHeader(child: Text('Employee Management')),
              FluentNavCategory(
                value: '6',
                icon: Icon(FluentIcons.note_pin_20_regular),
                child: Text('Job Postings'),
                children: <Widget>[
                  FluentNavSubItem(value: '7', child: Text('Openings')),
                  FluentNavSubItem(value: '8', child: Text('Submissions')),
                ],
              ),
              FluentNavItem(
                value: '9',
                icon: Icon(FluentIcons.people_20_regular),
                child: Text('Interviews'),
              ),
              FluentNavSectionHeader(child: Text('Benefits')),
              FluentNavItem(
                value: '10',
                icon: Icon(FluentIcons.heart_pulse_20_regular),
                child: Text('Health Plans'),
              ),
              FluentNavCategory(
                value: '11',
                icon: Icon(FluentIcons.person_20_regular),
                child: Text('Retirement'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '13',
                    child: Text('Plan Information'),
                  ),
                  FluentNavSubItem(
                    value: '14',
                    child: Text('Fund Performance'),
                  ),
                ],
              ),
              FluentNavSectionHeader(child: Text('Learning')),
              FluentNavItem(
                value: '15',
                icon: Icon(FluentIcons.box_multiple_20_regular),
                child: Text('Training Programs'),
              ),
              FluentNavCategory(
                value: '16',
                icon: Icon(FluentIcons.people_star_20_regular),
                child: Text('Career Development'),
                children: <Widget>[
                  FluentNavSubItem(value: '17', child: Text('Career Paths')),
                  FluentNavSubItem(value: '18', child: Text('Planning')),
                ],
              ),
              FluentNavDivider(),
              FluentNavItem(
                value: '19',
                icon: Icon(FluentIcons.data_area_20_regular),
                child: Text('Workforce Data'),
              ),
              FluentNavItem(
                value: '20',
                icon: Icon(
                  FluentIcons.document_bullet_list_multiple_20_regular,
                ),
                child: Text('Reports'),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 4, start: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: <Widget>[
                FluentButton(
                  appearance: FluentButtonAppearance.primary,
                  onPressed: _handleNavigationClick,
                  child: const Text('Navigate'),
                ),
                const FluentLabel(child: Text('Categories')),
                FluentSwitch(
                  checked: _isMultiple,
                  onChanged: _handleMultipleChange,
                  label: Text(_isMultiple ? 'Multiple' : 'Single'),
                  semanticLabel: 'Categories',
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-nav--controlled

// #docregion components-nav--split-nav-items
Widget _splitNavItems(BuildContext context) =>
    const SizedBox(height: 600, child: _SplitNavItems());

class _SplitNavItems extends StatefulWidget {
  const _SplitNavItems();

  @override
  State<_SplitNavItems> createState() => _SplitNavItemsState();
}

class _SplitNavItemsState extends State<_SplitNavItems> {
  FluentNavSize _density = FluentNavSize.small;
  bool _enabledLinks = true;
  bool _isAppItemIconPresent = true;
  bool _isAppItemStatic = true;
  Set<String> _pinnedValues = <String>{};

  // Upstream swaps every row's `href` between 'https://www.bing.com' and an
  // empty string. A FluentNavItem is a button rather than an anchor, so the
  // Links switch drives `onPressed`.
  VoidCallback? get _onLinkPressed => _enabledLinks ? _openLink : null;

  void _openLink() {
    // An app would route to 'https://www.bing.com' from here.
  }

  Widget? _appItemIcon() {
    if (!_isAppItemIconPresent) return null;
    return _density == FluentNavSize.small
        ? const Icon(FluentIcons.person_circle_24_regular)
        : const Icon(FluentIcons.person_circle_32_regular);
  }

  // Upstream's `SplitNavItem` is a nav row plus up to two trailing buttons.
  // FluentNavItem carries them in `secondaryActions`, so there is no separate
  // widget to reach for.
  Widget _pin(String value) {
    final isPinned = _pinnedValues.contains(value);
    return FluentButton.icon(
      icon: Icon(
        isPinned ? FluentIcons.pin_20_filled : FluentIcons.pin_20_regular,
      ),
      semanticLabel: isPinned ? 'Unpin' : 'Pin',
      appearance: FluentButtonAppearance.subtle,
      size: FluentButtonSize.small,
      onPressed: () => setState(() {
        _pinnedValues = isPinned
            ? (<String>{..._pinnedValues}..remove(value))
            : <String>{value, ..._pinnedValues};
      }),
    );
  }

  Widget _more() => FluentMenu(
    items: const <FluentMenuItem>[
      FluentMenuItem(label: Text('New ')),
      FluentMenuItem(label: Text('New Window')),
    ],
    builder: (BuildContext context, VoidCallback toggle) => FluentButton.icon(
      icon: const Icon(FluentIcons.more_horizontal_20_regular),
      semanticLabel: 'More options',
      appearance: FluentButtonAppearance.subtle,
      size: FluentButtonSize.small,
      onPressed: toggle,
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      FluentNavDrawer(
        open: true,
        type: FluentDrawerType.inline,
        separator: true,
        semanticLabel: 'Contoso HR',
        header: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentTooltip(
              content: const Text('Navigation'),
              child: FluentHamburger(
                onPressed: () {},
                semanticLabel: 'Navigation',
              ),
            ),
          ),
        ],
        child: SingleChildScrollView(
          child: FluentNav(
            size: _density,
            defaultSelectedValue: '5',
            children: <Widget>[
              FluentNavAppItem(
                icon: _appItemIcon(),
                onPressed: _isAppItemStatic ? null : _onLinkPressed,
                child: const Text('Contoso HR'),
              ),
              // The top four rows are deliberately not pinnable.
              FluentNavItem(
                value: '1',
                icon: const Icon(FluentIcons.board_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Dashboard'),
              ),
              FluentNavItem(
                value: '2',
                icon: const Icon(FluentIcons.megaphone_loud_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Announcements'),
              ),
              FluentNavItem(
                value: '3',
                icon: const Icon(FluentIcons.person_lightbulb_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Employee Spotlight'),
              ),
              FluentNavItem(
                value: '4',
                icon: const Icon(FluentIcons.person_search_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Profile Search'),
              ),
              const FluentNavDivider(),
              FluentNavItem(
                value: '5',
                icon: const Icon(FluentIcons.preview_link_20_regular),
                onPressed: _onLinkPressed,
                secondaryActions: <Widget>[_pin('5')],
                child: const Text('Performance Reviews'),
              ),
              FluentNavCategory(
                value: '6',
                icon: const Icon(FluentIcons.note_pin_20_regular),
                child: const Text('Job Postings'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '7',
                    onPressed: _onLinkPressed,
                    secondaryActions: <Widget>[_more(), _pin('7')],
                    child: const Text('Openings'),
                  ),
                  FluentNavSubItem(
                    value: '8',
                    onPressed: _onLinkPressed,
                    secondaryActions: <Widget>[_more(), _pin('8')],
                    child: const Text('Submissions'),
                  ),
                ],
              ),
              FluentNavItem(
                value: '9',
                icon: const Icon(FluentIcons.people_20_regular),
                onPressed: _onLinkPressed,
                secondaryActions: <Widget>[_pin('9')],
                child: const Text('Interviews'),
              ),
              FluentNavItem(
                value: '10',
                icon: const Icon(FluentIcons.heart_pulse_20_regular),
                onPressed: _onLinkPressed,
                secondaryActions: <Widget>[_pin('10')],
                child: const Text('Health Plans'),
              ),
              FluentNavCategory(
                value: '11',
                icon: const Icon(FluentIcons.person_20_regular),
                child: const Text('Retirement'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '13',
                    onPressed: _onLinkPressed,
                    secondaryActions: <Widget>[_more(), _pin('13')],
                    child: const Text('Plan Information'),
                  ),
                  FluentNavSubItem(
                    value: '14',
                    onPressed: _onLinkPressed,
                    secondaryActions: <Widget>[_more(), _pin('14')],
                    child: const Text('Fund Performance'),
                  ),
                ],
              ),
              FluentNavItem(
                value: '15',
                icon: const Icon(FluentIcons.box_multiple_20_regular),
                onPressed: _onLinkPressed,
                secondaryActions: <Widget>[_pin('15')],
                child: const Text('Training Programs'),
              ),
              FluentNavCategory(
                value: '16',
                icon: const Icon(FluentIcons.people_star_20_regular),
                child: const Text('Career Development'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '17',
                    onPressed: _onLinkPressed,
                    secondaryActions: <Widget>[_more(), _pin('17')],
                    child: const Text('Career Paths'),
                  ),
                  FluentNavSubItem(
                    value: '18',
                    onPressed: _onLinkPressed,
                    secondaryActions: <Widget>[_more(), _pin('18')],
                    child: const Text('Planning'),
                  ),
                ],
              ),
              FluentNavItem(
                value: '19',
                icon: const Icon(FluentIcons.data_area_20_regular),
                onPressed: _onLinkPressed,
                secondaryActions: <Widget>[_pin('19')],
                child: const Text('Workforce Data'),
              ),
              FluentNavItem(
                value: '20',
                icon: const Icon(
                  FluentIcons.document_bullet_list_multiple_20_regular,
                ),
                onPressed: _onLinkPressed,
                secondaryActions: <Widget>[_pin('20')],
                child: const Text('Reports'),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 4, start: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: <Widget>[
                const FluentLabel(child: Text('Density')),
                FluentRadioGroup<FluentNavSize>(
                  value: _density,
                  onChanged: (FluentNavSize value) =>
                      setState(() => _density = value),
                  semanticLabel: 'Density',
                  children: const <Widget>[
                    FluentRadio<FluentNavSize>(
                      value: FluentNavSize.medium,
                      label: Text('Medium'),
                    ),
                    FluentRadio<FluentNavSize>(
                      value: FluentNavSize.small,
                      label: Text('Small'),
                    ),
                  ],
                ),
                const FluentLabel(child: Text('Links')),
                FluentSwitch(
                  checked: _enabledLinks,
                  onChanged: (bool value) =>
                      setState(() => _enabledLinks = value),
                  label: Text(_enabledLinks ? 'Enabled' : 'Disabled'),
                  semanticLabel: 'Links',
                ),
                const FluentLabel(child: Text('App Item')),
                FluentSwitch(
                  checked: _isAppItemStatic,
                  onChanged: (bool value) =>
                      setState(() => _isAppItemStatic = value),
                  label: Text(_isAppItemStatic ? 'Static' : 'Href'),
                  semanticLabel: 'App Item',
                ),
                const FluentLabel(child: Text('App Item Icon')),
                FluentSwitch(
                  checked: _isAppItemIconPresent,
                  onChanged: (bool value) =>
                      setState(() => _isAppItemIconPresent = value),
                  label: Text(_isAppItemIconPresent ? 'Present' : 'Absent'),
                  semanticLabel: 'App Item Icon',
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-nav--split-nav-items

// #docregion components-nav--custom-motion
// Upstream builds two `createPresenceComponent` motions — one for the drawer
// surface, one for the content — and hands the first to `surfaceMotion`.
// FluentNavDrawer exposes no motion slot, so this renders the same nav with the
// drawer's own slide-and-fade and the content pane held still.
Widget _customMotion(BuildContext context) => SizedBox(
  height: 600,
  child: Overlay(
    initialEntries: <OverlayEntry>[
      OverlayEntry(builder: (BuildContext context) => const _CustomMotion()),
    ],
  ),
);

class _CustomMotion extends StatefulWidget {
  const _CustomMotion();

  @override
  State<_CustomMotion> createState() => _CustomMotionState();
}

class _CustomMotionState extends State<_CustomMotion> {
  bool _isOpen = true;
  bool _enabledLinks = true;
  FluentDrawerType _type = FluentDrawerType.inline;
  bool _isMultiple = true;
  Set<Object> _openCategories = <Object>{};

  VoidCallback? get _onLinkPressed => _enabledLinks ? _openLink : null;

  void _openLink() {
    // An app would route to 'https://www.bing.com' from here.
  }

  void _onOpenChange(Set<Object> next) {
    final opened = next.difference(_openCategories);
    setState(
      () => _openCategories = _isMultiple || opened.isEmpty ? next : opened,
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      FluentNavDrawer(
        open: _isOpen,
        type: _type,
        separator: true,
        onDismiss: () => setState(() => _isOpen = false),
        semanticLabel: 'Contoso HR',
        child: SingleChildScrollView(
          child: FluentNav(
            defaultSelectedValue: '2',
            openCategories: _openCategories,
            onOpenChange: _onOpenChange,
            children: <Widget>[
              FluentNavAppItem(
                icon: const Icon(FluentIcons.person_circle_32_regular),
                onPressed: _onLinkPressed,
                child: const Text('Contoso HR'),
              ),
              FluentNavItem(
                value: '1',
                icon: const Icon(FluentIcons.board_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Dashboard'),
              ),
              FluentNavItem(
                value: '2',
                icon: const Icon(FluentIcons.megaphone_loud_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Announcements'),
              ),
              FluentNavItem(
                value: '3',
                icon: const Icon(FluentIcons.person_lightbulb_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Employee Spotlight'),
              ),
              FluentNavItem(
                value: '4',
                icon: const Icon(FluentIcons.person_search_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Profile Search'),
              ),
              FluentNavItem(
                value: '5',
                icon: const Icon(FluentIcons.preview_link_20_regular),
                onPressed: _onLinkPressed,
                child: const Text('Performance Reviews'),
              ),
              const FluentNavSectionHeader(child: Text('Employee Management')),
              FluentNavCategory(
                value: '6',
                icon: const Icon(FluentIcons.note_pin_20_regular),
                child: const Text('Job Postings'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '7',
                    onPressed: _onLinkPressed,
                    child: const Text('Openings'),
                  ),
                  FluentNavSubItem(
                    value: '8',
                    onPressed: _onLinkPressed,
                    child: const Text('Submissions'),
                  ),
                ],
              ),
              const FluentNavItem(
                value: '9',
                icon: Icon(FluentIcons.people_20_regular),
                child: Text('Interviews'),
              ),
              const FluentNavSectionHeader(child: Text('Benefits')),
              const FluentNavItem(
                value: '10',
                icon: Icon(FluentIcons.heart_pulse_20_regular),
                child: Text('Health Plans'),
              ),
              FluentNavCategory(
                value: '11',
                icon: const Icon(FluentIcons.person_20_regular),
                child: const Text('Retirement'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '13',
                    onPressed: _onLinkPressed,
                    child: const Text('Plan Information'),
                  ),
                  FluentNavSubItem(
                    value: '14',
                    onPressed: _onLinkPressed,
                    child: const Text('Fund Performance'),
                  ),
                ],
              ),
              const FluentNavSectionHeader(child: Text('Learning')),
              const FluentNavItem(
                value: '15',
                icon: Icon(FluentIcons.box_multiple_20_regular),
                child: Text('Training Programs'),
              ),
              FluentNavCategory(
                value: '16',
                icon: const Icon(FluentIcons.people_star_20_regular),
                child: const Text('Career Development'),
                children: <Widget>[
                  FluentNavSubItem(
                    value: '17',
                    onPressed: _onLinkPressed,
                    child: const Text('Career Paths'),
                  ),
                  FluentNavSubItem(
                    value: '18',
                    onPressed: _onLinkPressed,
                    child: const Text('Planning'),
                  ),
                ],
              ),
              const FluentNavDivider(),
              const FluentNavItem(
                value: '19',
                icon: Icon(FluentIcons.data_area_20_regular),
                child: Text('Workforce Data'),
              ),
              FluentNavItem(
                value: '20',
                icon: const Icon(
                  FluentIcons.document_bullet_list_multiple_20_regular,
                ),
                onPressed: _onLinkPressed,
                child: const Text('Reports'),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FluentTooltip(
                content: const Text('Toggle navigation pane'),
                child: FluentHamburger(
                  onPressed: () => setState(() => _isOpen = !_isOpen),
                  expanded: _isOpen,
                  semanticLabel: 'Toggle navigation pane',
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, start: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: <Widget>[
                    const FluentLabel(child: Text('Type')),
                    FluentRadioGroup<FluentDrawerType>(
                      value: _type,
                      onChanged: (FluentDrawerType value) =>
                          setState(() => _type = value),
                      semanticLabel: 'Type',
                      children: const <Widget>[
                        FluentRadio<FluentDrawerType>(
                          value: FluentDrawerType.overlay,
                          label: Text('Overlay (Default)'),
                        ),
                        FluentRadio<FluentDrawerType>(
                          value: FluentDrawerType.inline,
                          label: Text('Inline'),
                        ),
                      ],
                    ),
                    const FluentLabel(child: Text('Links')),
                    FluentSwitch(
                      checked: _enabledLinks,
                      onChanged: (bool value) =>
                          setState(() => _enabledLinks = value),
                      label: Text(_enabledLinks ? 'Enabled' : 'Disabled'),
                      semanticLabel: 'Links',
                    ),
                    const FluentLabel(
                      child: Text('Allow multiple expanded categories'),
                    ),
                    FluentSwitch(
                      checked: _isMultiple,
                      onChanged: (bool value) =>
                          setState(() => _isMultiple = value),
                      label: Text(_isMultiple ? 'Multiple' : 'Single'),
                      semanticLabel: 'Allow multiple expanded categories',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// #enddocregion components-nav--custom-motion
