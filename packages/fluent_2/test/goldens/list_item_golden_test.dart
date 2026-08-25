import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Column 1: one-line rows at both sizes — no affordance, checkbox, radio.
/// Column 2: the same three at two lines, with an avatar in the media slot.
/// Row 4: the two states that swap the whole token ramp — a disabled row and a
/// read-only list, which is *not* the same thing and must not look like one.
///
/// Every cell holds three rows so the second one can carry the selection and
/// the third can stay at rest, which is what makes a fill regression visible.
void main() {
  Widget cell({
    FluentListItemSize size = FluentListItemSize.medium,
    FluentListSelection selection = FluentListSelection.none,
    bool twoLine = false,
    bool withMedia = false,
    bool enabled = true,
    bool readOnly = false,
  }) => SizedBox(
    width: 300,
    child: FluentList<String>(
      size: size,
      selection: selection,
      selectedValues: const <String>{'b'},
      onSelectionChange: readOnly ? null : (_) {},
      items: <FluentListItem<String>>[
        for (final value in const <String>['a', 'b', 'c'])
          FluentListItem<String>(
            value: value,
            enabled: enabled,
            media: withMedia
                ? const FluentAvatar(
                    initials: 'AL',
                    size: FluentAvatarSize.size32,
                  )
                : null,
            tertiary: const Text('9:41'),
            secondary: twoLine ? const Text('Sub') : null,
            child: const Text('Title'),
          ),
      ],
    ),
  );

  goldenGridTest(
    'list_item',
    () => goldenGrid(<Widget>[
      cell(size: FluentListItemSize.small),
      cell(size: FluentListItemSize.small, twoLine: true, withMedia: true),
      cell(),
      cell(twoLine: true, withMedia: true),
      cell(
        size: FluentListItemSize.small,
        selection: FluentListSelection.checkbox,
      ),
      cell(selection: FluentListSelection.checkbox, twoLine: true),
      cell(
        size: FluentListItemSize.small,
        selection: FluentListSelection.radio,
      ),
      cell(selection: FluentListSelection.radio, twoLine: true),
      cell(selection: FluentListSelection.checkbox, enabled: false),
      cell(selection: FluentListSelection.checkbox, readOnly: true),
    ], columns: 2),
    surfaceSize: const Size(900, 1400),
  );
}
