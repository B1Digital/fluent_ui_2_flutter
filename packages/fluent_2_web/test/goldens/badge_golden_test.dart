import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per colour, one cell per appearance — all 28 pairs. Then a row of the
/// four sizes, and a row of the layouts: icon before, icon after, bare dot.
void main() {
  const icon = Icon(FluentIcons.circle_16_filled, size: 12);

  goldenGridTest(
    'badge',
    () => goldenGrid(<Widget>[
      for (final color in FluentBadgeColor.values)
        for (final appearance in FluentBadgeAppearance.values)
          FluentBadge(
            color: color,
            appearance: appearance,
            child: const Text('99'),
          ),
      for (final size in FluentBadgeSize.values)
        FluentBadge(size: size, icon: icon, child: const Text('99')),
      const FluentBadge(icon: icon, child: Text('99')),
      const FluentBadge(
        icon: icon,
        iconPosition: FluentBadgeIconPosition.after,
        child: Text('99'),
      ),
      const FluentBadge(semanticLabel: 'Unread'),
      const FluentBadge(icon: icon, semanticLabel: 'Icon only'),
    ]),
  );
}
