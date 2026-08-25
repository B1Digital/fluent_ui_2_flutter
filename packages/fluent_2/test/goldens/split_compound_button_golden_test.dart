import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Split button: a row per appearance — both halves live, action disabled,
/// menu disabled, both disabled. Final row: the three sizes plus the circular
/// shape, where the divider has to land between two semicircular ends.
///
/// Compound button: a row per appearance — enabled, disabled, with an icon,
/// second line omitted. Final row: the three sizes.
void main() {
  const icon = Icon(FluentIcons.add_20_regular, size: 40);

  goldenGridTest(
    'split_button',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentButtonAppearance.values) ...<Widget>[
        FluentSplitButton(
          appearance: appearance,
          menuSemanticLabel: 'More',
          onPressed: () {},
          onMenuPressed: () {},
          child: const Text('Send'),
        ),
        FluentSplitButton(
          appearance: appearance,
          menuSemanticLabel: 'More',
          onMenuPressed: () {},
          child: const Text('Send'),
        ),
        FluentSplitButton(
          appearance: appearance,
          menuSemanticLabel: 'More',
          onPressed: () {},
          child: const Text('Send'),
        ),
        FluentSplitButton(
          appearance: appearance,
          menuSemanticLabel: 'More',
          child: const Text('Send'),
        ),
      ],
      for (final size in FluentButtonSize.values)
        FluentSplitButton(
          appearance: FluentButtonAppearance.primary,
          size: size,
          menuSemanticLabel: 'More',
          onPressed: () {},
          onMenuPressed: () {},
          child: const Text('Send'),
        ),
      FluentSplitButton(
        appearance: FluentButtonAppearance.primary,
        shape: FluentButtonShape.circular,
        menuSemanticLabel: 'More',
        onPressed: () {},
        onMenuPressed: () {},
        child: const Text('Send'),
      ),
    ]),
  );

  goldenGridTest(
    'compound_button',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentButtonAppearance.values) ...<Widget>[
        FluentCompoundButton(
          appearance: appearance,
          secondaryContent: const Text('Secondary'),
          onPressed: () {},
          child: const Text('Button'),
        ),
        FluentCompoundButton(
          appearance: appearance,
          secondaryContent: const Text('Secondary'),
          child: const Text('Button'),
        ),
        FluentCompoundButton(
          appearance: appearance,
          icon: icon,
          secondaryContent: const Text('Secondary'),
          onPressed: () {},
          child: const Text('Button'),
        ),
        FluentCompoundButton(
          appearance: appearance,
          onPressed: () {},
          child: const Text('Button'),
        ),
      ],
      for (final size in FluentButtonSize.values)
        FluentCompoundButton(
          appearance: FluentButtonAppearance.primary,
          size: size,
          secondaryContent: const Text('Secondary'),
          onPressed: () {},
          child: const Text('Button'),
        ),
    ], columns: 4),
  );
}
