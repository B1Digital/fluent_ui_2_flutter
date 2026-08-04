import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// First row: every status in office. Second row: the same statuses out of
/// office, which substitutes the glyph for away and busy rather than merely
/// hollowing it. Third row: the six diameters.
///
/// The status glyphs render as placeholder boxes — the icon font is not loaded
/// in `flutter test`, same as the text font. What this image regresses is the
/// disc colour, the ring and the diameter, which is where the tokens live.
void main() {
  goldenGridTest(
    'presence_badge',
    () => goldenGrid(columns: 8, <Widget>[
      for (final outOfOffice in <bool>[false, true])
        for (final status in FluentPresenceStatus.values)
          FluentPresenceBadge(
            status: status,
            outOfOffice: outOfOffice,
            size: FluentPresenceBadgeSize.extraLarge,
          ),
      for (final size in FluentPresenceBadgeSize.values)
        FluentPresenceBadge(status: FluentPresenceStatus.available, size: size),
    ]),
  );
}
