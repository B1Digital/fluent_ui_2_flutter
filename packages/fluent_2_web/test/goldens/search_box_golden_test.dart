import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Rows 1-3: every Style at every Size, at rest with a placeholder. Row 4: the
/// disabled ramp across all four styles.
///
/// The cells worth watching are Outline and Transparent, whose bottom rule is
/// a higher-contrast `neutralStrokeAccessible` over (or instead of) the border
/// — and the Filled pair, whose border is a *transparent* token that must turn
/// opaque in the high contrast image and stay invisible in the other two.
///
/// The second grid is the focus state, built through [buildFluentSearchBox]
/// with `focused: true` rather than by driving real focus, because only one
/// widget in a tree can hold it at a time.
void main() {
  const cellWidth = 200.0;

  Widget cell(Widget child) => SizedBox(width: cellWidth, child: child);

  goldenGridTest(
    'search_box',
    () => goldenGrid(<Widget>[
      for (final size in FluentSearchBoxSize.values)
        for (final appearance in FluentSearchBoxAppearance.values)
          cell(
            FluentSearchBox(
              appearance: appearance,
              size: size,
              placeholder: 'Search',
            ),
          ),
      for (final appearance in FluentSearchBoxAppearance.values)
        cell(
          FluentSearchBox(
            appearance: appearance,
            enabled: false,
            placeholder: 'Search',
          ),
        ),
    ], columns: 4),
    surfaceSize: const Size(1200, 900),
  );

  goldenGridTest(
    'search_box',
    suffix: '.focused',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentSearchBoxAppearance.values)
        for (final size in FluentSearchBoxSize.values)
          cell(_FocusedSearchBox(appearance: appearance, size: size)),
    ], columns: 3),
    surfaceSize: const Size(1200, 900),
  );
}

/// A search box rendered in its focused state without holding real focus:
/// Fluent's own state resolution and rendering, driven directly.
class _FocusedSearchBox extends StatelessWidget {
  const _FocusedSearchBox({required this.appearance, required this.size});

  final FluentSearchBoxAppearance appearance;
  final FluentSearchBoxSize size;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final state = resolveFluentSearchBoxState(
      field: const Text('Fluent'),
      focused: true,
      appearance: appearance,
      size: size,
      icon: CustomPaint(
        painter: FluentSearchBoxGlyphPainter(
          glyph: FluentSearchBoxGlyph.search,
          color: theme.colors.neutralForeground3,
        ),
      ),
      clear: CustomPaint(
        painter: FluentSearchBoxGlyphPainter(
          glyph: FluentSearchBoxGlyph.dismiss,
          color: theme.colors.neutralForeground3,
        ),
      ),
    );
    return buildFluentSearchBox(
      state,
      resolveFluentSearchBoxStyle(state, theme),
      const <WidgetState>{},
    );
  }
}
