import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One column, one cell per intent, twice over: single line then multi line,
/// then the square shape and the glyphless form.
///
/// A message bar is a full-width strip, so the grid is one cell wide and every
/// cell is pinned to 560 — the Figma frame is 800, which does not fit the
/// capture surface beside its margins.
void main() {
  Widget cell({
    required FluentMessageBarIntent intent,
    FluentMessageBarLayout layout = FluentMessageBarLayout.singleLine,
    FluentMessageBarShape shape = FluentMessageBarShape.rounded,
    bool showIcon = true,
  }) => SizedBox(
    width: 560,
    child: FluentMessageBar(
      intent: intent,
      layout: layout,
      shape: shape,
      showIcon: showIcon,
      title: const Text('Descriptive title'),
      onDismiss: () {},
      actions: <Widget>[
        FluentButton(
          size: FluentButtonSize.small,
          onPressed: () {},
          child: const Text('Action'),
        ),
      ],
      child: const Text('Message providing information to the user.'),
    ),
  );

  goldenGridTest(
    'message_bar',
    () => goldenGrid(columns: 1, <Widget>[
      for (final intent in FluentMessageBarIntent.values) cell(intent: intent),
      for (final intent in FluentMessageBarIntent.values)
        cell(intent: intent, layout: FluentMessageBarLayout.multiLine),
      cell(
        intent: FluentMessageBarIntent.error,
        shape: FluentMessageBarShape.square,
      ),
      cell(intent: FluentMessageBarIntent.success, showIcon: false),
    ]),
    surfaceSize: const Size(700, 1000),
  );
}
