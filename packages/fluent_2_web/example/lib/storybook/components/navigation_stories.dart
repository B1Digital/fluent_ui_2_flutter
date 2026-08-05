import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// Navigation components — breadcrumb, data grid, list, nav, tab list,
/// toolbar and tree.
List<Story> get navigationStories => [
  Story(
    name: 'Navigation/FluentBreadcrumb',
    description: 'A trail of navigation showing the path to the current page.',
    builder: (context) {
      return DemoRail(
        title: 'Breadcrumb',
        children: [
          FluentBreadcrumb(
            items: const [
              FluentBreadcrumbItem(label: Text('Home'), onPressed: null),
              FluentBreadcrumbItem(label: Text('Library'), onPressed: null),
              FluentBreadcrumbItem(label: Text('Fluent 2'), onPressed: null),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Navigation/FluentDataGrid',
    description: 'A tabular view of data with optional selection and sorting.',
    builder: (context) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: FluentDataGrid(
          columns: const [
            FluentDataGridColumn(header: Text('Name')),
            FluentDataGridColumn(header: Text('Job title')),
            FluentDataGridColumn(header: Text('Status')),
          ],
          rows: const [
            FluentDataGridRow(
              cells: [Text('Ada Lovelace'), Text('Engineer'), Text('Active')],
            ),
            FluentDataGridRow(
              cells: [
                Text('Alan Turing'),
                Text('Mathematician'),
                Text('Active'),
              ],
            ),
            FluentDataGridRow(
              cells: [Text('Grace Hopper'), Text('Admiral'), Text('Inactive')],
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Navigation/FluentList',
    description: 'A vertical list of items with optional multi-selection.',
    builder: (context) {
      return SizedBox(
        width: 320,
        child: FluentList<String>(
          selection: FluentListSelection.checkbox,
          items: const [
            FluentListItem<String>(
              value: 'item-1',
              secondary: Text('Fruit'),
              child: Text('Apple'),
            ),
            FluentListItem<String>(
              value: 'item-2',
              secondary: Text('Vegetable'),
              child: Text('Carrot'),
            ),
            FluentListItem<String>(
              value: 'item-3',
              secondary: Text('Grain'),
              child: Text('Rice'),
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Navigation/FluentNav',
    description: 'Primary navigation with items and categories.',
    builder: (context) {
      return SizedBox(
        width: 240,
        child: FluentNav(
          selectedValue: 'inbox',
          children: const [
            FluentNavAppItem(icon: Icon(Icons.apps), child: Text('All apps')),
            FluentNavItem(
              value: 'inbox',
              icon: Icon(Icons.inbox),
              child: Text('Inbox'),
            ),
            FluentNavItem(
              value: 'sent',
              icon: Icon(Icons.send),
              child: Text('Sent'),
            ),
            FluentNavItem(
              value: 'trash',
              icon: Icon(Icons.delete),
              child: Text('Trash'),
            ),
            FluentNavDivider(),
            FluentNavCategory(
              value: 'manage',
              children: [
                FluentNavSubItem(value: 'members', child: Text('Members')),
                FluentNavSubItem(value: 'settings', child: Text('Settings')),
              ],
              child: Text('Manage'),
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Navigation/FluentTabList',
    description: 'A list of tabs, selectable to switch views.',
    builder: (context) {
      return FluentTabList<String>(
        selectedValue: 'tab-2',
        onSelect: (value) {},
        tabs: const [
          FluentTab<String>(
            value: 'tab-1',
            icon: Icon(Icons.home),
            child: Text('Home'),
          ),
          FluentTab<String>(
            value: 'tab-2',
            icon: Icon(Icons.person),
            child: Text('Profile'),
          ),
          FluentTab<String>(
            value: 'tab-3',
            enabled: false,
            child: Text('Disabled'),
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Navigation/FluentToolbar',
    description: 'A horizontal bar of action controls.',
    builder: (context) {
      return FluentToolbar(
        items: const [
          FluentButton.icon(
            icon: Icon(Icons.format_bold),
            semanticLabel: 'Bold',
            appearance: FluentButtonAppearance.subtle,
          ),
          FluentButton.icon(
            icon: Icon(Icons.format_italic),
            semanticLabel: 'Italic',
            appearance: FluentButtonAppearance.subtle,
          ),
          FluentToolbarDivider(),
          FluentButton.icon(
            icon: Icon(Icons.format_underline),
            semanticLabel: 'Underline',
            appearance: FluentButtonAppearance.subtle,
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Navigation/FluentTree',
    description: 'A hierarchical tree of expandable nodes.',
    builder: (context) {
      return SizedBox(
        width: 320,
        child: FluentTree(
          defaultOpenItems: const {'dir'},
          items: [
            FluentTreeItem(
              value: 'dir',
              label: const Text('Documents'),
              children: [
                FluentTreeItem(value: 'f1', label: const Text('Report.pdf')),
                FluentTreeItem(value: 'f2', label: const Text('Notes.md')),
              ],
            ),
            FluentTreeItem(value: 'f3', label: const Text('Images')),
            FluentTreeItem(value: 'f4', label: const Text('readme.txt')),
          ],
        ),
      );
    },
  ),
];
