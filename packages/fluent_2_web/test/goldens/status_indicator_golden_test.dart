import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per category, one cell per size. Final row: the icon-only rendering of
/// each category, which is the form with no label to carry the colour.
void main() {
  const icon = Icon(FluentIcons.circle_16_filled, size: 16);

  goldenGridTest(
    'status_indicator',
    () => goldenGrid(columns: 3, <Widget>[
      for (final category in FluentStatusIndicatorCategory.values)
        for (final size in FluentStatusIndicatorSize.values)
          FluentStatusIndicator(
            message: FluentStatusIndicatorMessage.genericInformation,
            category: category,
            size: size,
            icon: icon,
            label: const Text('Status'),
          ),
      for (final category in FluentStatusIndicatorCategory.values)
        FluentStatusIndicator(
          message: FluentStatusIndicatorMessage.genericInformation,
          category: category,
          icon: icon,
        ),
    ]),
  );
}
