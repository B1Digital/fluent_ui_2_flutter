import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Stroke Widths theme page.
const DocsPage themeStrokeWidthsPage = DocsPage(
  id: 'theme-stroke-widths',
  title: 'Stroke Widths',
  description: '',
  source: 'lib/pages/theme_stroke_widths.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// The four widths React's web token set exposes, in ramp order. `FluentStroke`
/// also carries `none`, `hairline`, `width15` and `width60` for the mobile
/// surfaces; upstream's page does not print them, so neither does this one.
const List<(String, double)> _ramp = <(String, double)>[
  ('strokeWidthThin', FluentStroke.thin),
  ('strokeWidthThick', FluentStroke.thick),
  ('strokeWidthThicker', FluentStroke.thicker),
  ('strokeWidthThickest', FluentStroke.thickest),
];

/// Measured off the reference: the rule starts 132px in from the card's content
/// edge, whatever the label reads.
const double _labelWidth = 132;

/// A row is the label's own 14/20 line box; the rule centres in it. The gap
/// below puts consecutive rules on the reference's 30px pitch and leaves no
/// slack under the last one.
const double _rowHeight = 20;
const double _rowGap = 10;

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
        for (final (int index, (String name, double width)) in _ramp.indexed)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : _rowGap),
            child: SizedBox(
              height: _rowHeight,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: _labelWidth,
                    child: Text(
                      name,
                      style: DocsMetrics.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: width,
                      // Chrome, not a token: upstream's rule is pure black, and
                      // headingText is the chrome's black.
                      color: DocsMetrics.headingText,
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
