import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per appearance: enabled, disabled, inline (underlined), with icon.
///
/// `overBrand` is drawn on a brand fill, because that is the only surface it is
/// legible on — on the page background it would read as a regression rather
/// than as the token doing its job.
void main() {
  const icon = Icon(FluentIcons.open_16_regular, size: 16);

  Widget cell(FluentLinkAppearance appearance, Widget link) =>
      appearance == FluentLinkAppearance.overBrand
      ? Builder(
          builder: (context) => ColoredBox(
            color: FluentTheme.of(context).colors.brandBackground,
            child: Padding(
              padding: const EdgeInsets.all(FluentSpacing.xs),
              child: link,
            ),
          ),
        )
      : link;

  goldenGridTest(
    'link',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentLinkAppearance.values) ...<Widget>[
        cell(
          appearance,
          FluentLink(
            appearance: appearance,
            onPressed: () {},
            child: const Text('Link'),
          ),
        ),
        cell(
          appearance,
          FluentLink(appearance: appearance, child: const Text('Link')),
        ),
        cell(
          appearance,
          FluentLink(
            appearance: appearance,
            inline: true,
            onPressed: () {},
            child: const Text('Link'),
          ),
        ),
        cell(
          appearance,
          FluentLink(
            appearance: appearance,
            icon: icon,
            onPressed: () {},
            child: const Text('Link'),
          ),
        ),
      ],
    ]),
  );
}
