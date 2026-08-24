import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Border Radii theme page.
const DocsPage themeBorderRadiiPage = DocsPage(
  id: 'theme-border-radii',
  title: 'Border Radii',
  description: '',
  source: 'lib/pages/theme_border_radii.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// The ramp under upstream's names. React flattens everything past XLarge into
/// `borderRadius2XLarge`..`6XLarge`; the same stops are spelled
/// `FluentRadius.xxLarge`..`xxxxxxLarge` here.
const List<(String, Radius)> _ramp = <(String, Radius)>[
  ('borderRadiusNone', FluentRadius.none),
  ('borderRadiusSmall', FluentRadius.small),
  ('borderRadiusMedium', FluentRadius.medium),
  ('borderRadiusLarge', FluentRadius.large),
  ('borderRadiusXLarge', FluentRadius.xLarge),
  ('borderRadius2XLarge', FluentRadius.xxLarge),
  ('borderRadius3XLarge', FluentRadius.xxxLarge),
  ('borderRadius4XLarge', FluentRadius.xxxxLarge),
  ('borderRadius5XLarge', FluentRadius.xxxxxLarge),
  ('borderRadius6XLarge', FluentRadius.xxxxxxLarge),
  ('borderRadiusCircular', FluentRadius.circular),
];

/// Measured off the reference: name and value share a 204px column, the value
/// pushed to its right edge, then 20px to each swatch.
const double _labelWidth = 204;
const double _gap = 20;

/// Both swatches box 42x42 of content. Flutter insets a border, so the
/// outlined one is declared 44 across for its 1px stroke to land outside the
/// same 42px area — which is what upstream's `border` does to a 42px div.
const double _swatch = 42;
const double _outlinedSwatch = _swatch + 2;

/// Row pitch: a 44px row plus the 10px that separates it from the next.
const double _rowHeight = 44;
const double _rowGap = 10;

/// Chrome, not a token: upstream's filled swatch is a flat `#bbb`, which is not
/// a stop on the Fluent grey ramp. Its outline is pure black, and
/// [DocsMetrics.headingText] is the chrome's black.
const Color _swatchFill = Color(0xFFBBBBBB);

/// What upstream prints in the value column.
///
/// `borderRadiusCircular` reads "10000px" because that is the literal React
/// ships; `FluentRadius.circular` is 9999, and both mean "as round as the box
/// allows", so the printed string follows upstream rather than the Dart value.
String _label(Radius radius) {
  if (radius == FluentRadius.none) {
    return '0';
  }
  if (radius == FluentRadius.circular) {
    return '10000px';
  }
  return '${radius.x.toStringAsFixed(0)}px';
}

Widget _body(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: FluentTheme.of(context).colors.neutralBackground1,
      border: Border.all(color: DocsMetrics.border),
      borderRadius: BorderRadius.circular(DocsMetrics.cardRadius),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final (int index, (String name, Radius radius)) in _ramp.indexed)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : _rowGap),
            child: SizedBox(
              height: _rowHeight,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: _labelWidth,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            name,
                            style: DocsMetrics.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(_label(radius), style: DocsMetrics.body),
                      ],
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Container(
                    width: _swatch,
                    height: _swatch,
                    decoration: BoxDecoration(
                      color: _swatchFill,
                      borderRadius: BorderRadius.all(radius),
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Container(
                    width: _outlinedSwatch,
                    height: _outlinedSwatch,
                    decoration: BoxDecoration(
                      color: DocsMetrics.canvas,
                      border: Border.all(color: DocsMetrics.headingText),
                      borderRadius: BorderRadius.all(radius),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
