import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per appearance: enabled, disabled, icon and label, icon only.
/// Final row: the three sizes plus the circular shape.
void main() {
  const icon = Icon(FluentIcons.add_20_regular, size: 20);

  goldenGridTest(
    'button',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentButtonAppearance.values) ...<Widget>[
        FluentButton(
          appearance: appearance,
          onPressed: () {},
          child: const Text('Button'),
        ),
        FluentButton(appearance: appearance, child: const Text('Button')),
        FluentButton(
          appearance: appearance,
          icon: icon,
          onPressed: () {},
          child: const Text('Button'),
        ),
        FluentButton.icon(
          appearance: appearance,
          icon: icon,
          semanticLabel: 'Add',
          onPressed: () {},
        ),
      ],
      for (final size in FluentButtonSize.values)
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          size: size,
          icon: icon,
          onPressed: () {},
          child: const Text('Button'),
        ),
      FluentButton(
        appearance: FluentButtonAppearance.primary,
        shape: FluentButtonShape.circular,
        onPressed: () {},
        child: const Text('Button'),
      ),
    ]),
  );
}
