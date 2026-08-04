import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Acrylic is a material: what it does is tint and blur whatever is behind it,
/// so each cell puts it over a fixed stripe pattern. The stripes are literal
/// colours rather than tokens on purpose — the backdrop must not move between
/// themes, or a tint regression would be indistinguishable from a backdrop one.
///
/// In high contrast the blur resolves to zero and the tints go opaque, so that
/// image should show hard stripe edges nowhere behind the surface.
void main() {
  const stripes = <Color>[
    Color(0xFFD13438),
    Color(0xFFFFB900),
    Color(0xFF107C10),
    Color(0xFF0078D4),
    Color(0xFF8764B8),
  ];

  Widget over(Widget surface) => SizedBox(
    width: 200,
    height: 120,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Row(
          // Stretch, not the default centre: a childless ColoredBox sizes to
          // nothing on the cross axis and the backdrop silently disappears.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final color in stripes)
              Expanded(child: ColoredBox(color: color)),
          ],
        ),
        Center(child: surface),
      ],
    ),
  );

  goldenGridTest(
    'acrylic',
    () => goldenGrid(columns: 3, <Widget>[
      over(const FluentAcrylicSurface(child: SizedBox(width: 120, height: 60))),
      over(
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(
            borderRadius: FluentRadius.allXLarge,
          ),
          child: const SizedBox(width: 120, height: 60),
        ),
      ),
      over(
        FluentAcrylicSurface(
          style: FluentAcrylicSurfaceStyle.from(backgroundBlur: 0),
          child: const SizedBox(width: 120, height: 60),
        ),
      ),
    ]),
  );
}
