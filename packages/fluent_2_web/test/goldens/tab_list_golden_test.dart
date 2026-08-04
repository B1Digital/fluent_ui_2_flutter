import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Rows 1-2: the four appearances horizontally, medium then small.
/// Rows 3-4: the same four vertically, medium then small.
/// Row 5: a disabled tab, an icon-only list, a list with nothing selected, and
/// a vertical pill list — the four cases where a token drops out of the table.
void main() {
  Widget tabs({
    FluentTabOrientation orientation = FluentTabOrientation.horizontal,
    FluentTabSize size = FluentTabSize.medium,
    FluentTabAppearance appearance = FluentTabAppearance.transparent,
    String? selected = 'a',
    bool disabled = false,
    bool iconOnly = false,
  }) => FluentTabList<String>(
    orientation: orientation,
    size: size,
    appearance: appearance,
    selectedValue: selected,
    onSelect: (_) {},
    tabs: <FluentTab<String>>[
      FluentTab<String>(
        value: 'a',
        icon: const Icon(FluentIcons.calendar_20_regular),
        semanticLabel: 'Calendar',
        child: iconOnly ? null : const Text('First'),
      ),
      FluentTab<String>(
        value: 'b',
        enabled: !disabled,
        icon: const Icon(FluentIcons.calendar_20_regular),
        semanticLabel: 'Second',
        child: iconOnly ? null : const Text('Second'),
      ),
      FluentTab<String>(
        value: 'c',
        icon: const Icon(FluentIcons.calendar_20_regular),
        semanticLabel: 'Third',
        child: iconOnly ? null : const Text('Third'),
      ),
    ],
  );

  goldenGridTest(
    'tab_list',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentTabAppearance.values)
        tabs(appearance: appearance),
      for (final appearance in FluentTabAppearance.values)
        tabs(appearance: appearance, size: FluentTabSize.small),
      for (final appearance in FluentTabAppearance.values)
        tabs(
          orientation: FluentTabOrientation.vertical,
          appearance: appearance,
        ),
      for (final appearance in FluentTabAppearance.values)
        tabs(
          orientation: FluentTabOrientation.vertical,
          appearance: appearance,
          size: FluentTabSize.small,
        ),
      tabs(disabled: true),
      tabs(iconOnly: true),
      tabs(selected: null),
      tabs(
        orientation: FluentTabOrientation.vertical,
        appearance: FluentTabAppearance.filledCircular,
        disabled: true,
      ),
    ]),
    // The placeholder test font draws every glyph at the same width, so keep a
    // generous surface for the three-tab rows.
    surfaceSize: const Size(2000, 1000),
  );
}
