import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Spacing theme page.
///
/// Upstream splits the ramp into Vertical and Horizontal tables and draws each
/// token as a bar sized by its own value. Ours carries the same split even
/// though `FluentSpacing.vertical` and `.horizontal` currently resolve to
/// identical numbers — the two axes are separate tokens precisely so one can
/// move without the other, and collapsing them here would hide that.
const DocsPage themeSpacingPage = DocsPage(
  id: 'theme-spacing',
  title: 'Spacing',
  description: '',
  source: 'lib/pages/theme_spacing.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// The ramp, in upstream's order. `FluentSpacing` is a set of `static const`
/// doubles with no reflection over them, so the suffixes are written out.
const List<(String, double)> _ramp = <(String, double)>[
  ('None', FluentSpacing.none),
  ('XXS', FluentSpacing.xxs),
  ('XS', FluentSpacing.xs),
  ('SNudge', FluentSpacing.sNudge),
  ('S', FluentSpacing.s),
  ('MNudge', FluentSpacing.mNudge),
  ('M', FluentSpacing.m),
  ('L', FluentSpacing.l),
  ('XL', FluentSpacing.xl),
  ('XXL', FluentSpacing.xxl),
  ('XXXL', FluentSpacing.xxxl),
];

/// The two bar colours are Storybook's own swatches for this page, not Fluent
/// tokens — the page is measuring size, so the fill is arbitrary and only has
/// to separate the two axes.
const Color _verticalBar = Color(0xFFCC006A);
const Color _horizontalBar = Color(0xFF00CC6A);

/// Column widths, measured off the reference: each is its group's widest label
/// plus a 10px gutter. Upstream sizes both columns to content, which is why the
/// two groups do *not* line up — `spacingHorizontal…` is two characters longer
/// than `spacingVertical…`, so its bars start 18px further right.
const double _verticalNameWidth = 158;
const double _horizontalNameWidth = 176;

/// Widest value is `32px`; left-aligned, as upstream has it.
const double _valueWidth = 40;

/// Name column, value column, then the bar.
Widget _row(
  String name,
  double value, {
  required bool vertical,
  required double nameWidth,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    children: <Widget>[
      SizedBox(
        width: nameWidth,
        child: Text(name, style: DocsMetrics.body),
      ),
      SizedBox(
        width: _valueWidth,
        child: Text(
          value == 0 ? '0' : '${value.toStringAsFixed(0)}px',
          style: DocsMetrics.body,
        ),
      ),
      // `none` is 0, so this collapses to nothing visible on either axis. It is
      // still built rather than skipped: on the horizontal axis the box is what
      // gives every row its 28px height, and dropping it would shorten the
      // `None` row alone.
      Container(
        width: vertical ? 280 : value,
        height: vertical ? value : 28,
        color: vertical ? _verticalBar : _horizontalBar,
      ),
    ],
  ),
);

Widget _body(BuildContext context) {
  final TextStyle heading = DocsMetrics.h3.copyWith(
    fontSize: 21,
    height: 28 / 21,
    color: DocsMetrics.headingText,
  );

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: FluentTheme.of(context).colors.neutralBackground1,
      border: Border.all(color: DocsMetrics.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Vertical', style: heading),
        const SizedBox(height: 8),
        for (final (String suffix, double value) in _ramp)
          _row(
            'spacingVertical$suffix',
            value,
            vertical: true,
            nameWidth: _verticalNameWidth,
          ),
        const SizedBox(height: 10),
        Text('Horizontal', style: heading),
        const SizedBox(height: 8),
        for (final (String suffix, double value) in _ramp)
          _row(
            'spacingHorizontal$suffix',
            value,
            vertical: false,
            nameWidth: _horizontalNameWidth,
          ),
      ],
    ),
  );
}
