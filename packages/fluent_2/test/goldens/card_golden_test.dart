import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per appearance: inert, interactive, selected, disabled.
/// Then the three sizes plus the horizontal orientation, then the slot
/// combinations — preview vertical, preview horizontal, all three text slots,
/// and a card that is nothing but a full-bleed preview.
void main() {
  Widget cell(Widget card) => SizedBox(width: 200, child: card);

  Widget preview() => Builder(
    builder: (context) => SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FluentTheme.of(context).colors.brandBackground,
        ),
      ),
    ),
  );

  goldenGridTest(
    'card',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentCardAppearance.values) ...<Widget>[
        cell(
          FluentCard(
            appearance: appearance,
            header: const Text('Header'),
            child: const Text('Body'),
          ),
        ),
        cell(
          FluentCard(
            appearance: appearance,
            onPressed: () {},
            header: const Text('Header'),
            child: const Text('Body'),
          ),
        ),
        cell(
          FluentCard(
            appearance: appearance,
            selected: true,
            onPressed: () {},
            header: const Text('Header'),
            child: const Text('Body'),
          ),
        ),
        cell(
          FluentCard(
            appearance: appearance,
            disabled: true,
            onPressed: () {},
            header: const Text('Header'),
            child: const Text('Body'),
          ),
        ),
      ],
      for (final size in FluentCardSize.values)
        cell(
          FluentCard(
            size: size,
            header: const Text('Header'),
            child: const Text('Body'),
          ),
        ),
      cell(
        const FluentCard(
          orientation: FluentCardOrientation.horizontal,
          header: Text('H'),
          child: Text('B'),
        ),
      ),
      cell(
        FluentCard(
          preview: preview(),
          header: const Text('Header'),
          child: const Text('Body'),
        ),
      ),
      cell(
        FluentCard(
          orientation: FluentCardOrientation.horizontal,
          preview: SizedBox(width: 56, child: preview()),
          child: const Text('Body'),
        ),
      ),
      cell(
        const FluentCard(
          header: Text('Header'),
          footer: Text('Footer'),
          child: Text('Body'),
        ),
      ),
      cell(FluentCard(preview: preview())),
    ]),
    surfaceSize: const Size(1200, 1600),
  );
}
