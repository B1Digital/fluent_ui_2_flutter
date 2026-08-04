import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per appearance: bare rule, then the same rule with a label.
/// Final rows: inset, the three label alignments, and the vertical rule.
void main() {
  Widget horizontal(Widget divider) => SizedBox(width: 240, child: divider);

  goldenGridTest(
    'divider',
    () => goldenGrid(columns: 2, <Widget>[
      for (final appearance in FluentDividerAppearance.values) ...<Widget>[
        horizontal(FluentDivider(appearance: appearance)),
        horizontal(
          FluentDivider(appearance: appearance, child: const Text('Label')),
        ),
      ],
      horizontal(const FluentDivider(inset: true, child: Text('Inset'))),
      horizontal(
        const FluentDivider(
          icon: Icon(FluentIcons.circle_16_filled, size: 16),
          child: Text('Icon'),
        ),
      ),
      horizontal(
        const FluentDivider(
          alignment: FluentDividerAlignment.start,
          child: Text('Start'),
        ),
      ),
      horizontal(
        const FluentDivider(
          alignment: FluentDividerAlignment.end,
          child: Text('End'),
        ),
      ),
      const SizedBox(height: 64, child: FluentDivider(vertical: true)),
      const SizedBox(
        height: 96,
        child: FluentDivider(vertical: true, child: Text('V')),
      ),
    ]),
  );
}
