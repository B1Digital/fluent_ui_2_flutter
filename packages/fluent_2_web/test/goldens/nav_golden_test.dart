import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One image per theme of a whole nav at both densities.
///
/// A nav is a column, not a cell, so this grid is two navs side by side rather
/// than one cell per variant: the interesting regressions are the ones between
/// rows — a selection indicator that stopped reserving its column, a sub-item
/// that lost its 46 indent, a divider that grew a margin.
void main() {
  Widget column(FluentNavSize size, {required bool open}) => SizedBox(
    width: 260,
    child: FluentNav(
      size: size,
      selectedValue: open ? 'weekly' : 'home',
      openCategories: open ? const <Object>{'reports'} : const <Object>{},
      children: <Widget>[
        FluentNavAppItem(
          icon: const Icon(FluentIcons.person_circle_32_regular),
          onPressed: () {},
          child: const Text('Contoso'),
        ),
        const FluentNavDivider(),
        const FluentNavItem(
          value: 'home',
          icon: Icon(FluentIcons.home_20_regular),
          child: Text('Home'),
        ),
        FluentNavItem(
          value: 'files',
          icon: const Icon(FluentIcons.document_20_regular),
          secondaryActions: <Widget>[
            FluentButton.icon(
              icon: const Icon(FluentIcons.more_horizontal_20_regular),
              semanticLabel: 'More',
              size: FluentButtonSize.small,
              appearance: FluentButtonAppearance.transparent,
              onPressed: () {},
            ),
          ],
          child: const Text('Files'),
        ),
        const FluentNavItem(
          value: 'archive',
          icon: Icon(FluentIcons.archive_20_regular),
          enabled: false,
          child: Text('Archive'),
        ),
        const FluentNavCategory(
          value: 'reports',
          icon: Icon(FluentIcons.folder_20_regular),
          child: Text('Reports'),
          children: <Widget>[
            FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
            FluentNavSubItem(value: 'monthly', child: Text('Monthly')),
          ],
        ),
      ],
    ),
  );

  goldenGridTest(
    'nav',
    () => goldenGrid(<Widget>[
      column(FluentNavSize.medium, open: false),
      column(FluentNavSize.medium, open: true),
      column(FluentNavSize.small, open: true),
    ], columns: 3),
    surfaceSize: const Size(1200, 900),
  );

  goldenGridTest(
    'nav',
    () => goldenGrid(<Widget>[
      column(FluentNavSize.medium, open: true),
    ], columns: 1),
    suffix: '.reduced_motion',
    reducedMotion: true,
  );
}
