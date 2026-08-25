import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row 1: the four sizes, collapsed, chevron at the start.
/// Row 2: expanded, chevron at each end, then a disabled header.
/// Row 3: a leading icon at each chevron position, and a two-item accordion
/// with both panels open.
void main() {
  const icon = Icon(FluentIcons.calendar_20_regular, size: 20);

  Widget cell(Widget child) => SizedBox(width: 250, child: child);

  Widget accordion({
    bool expanded = false,
    bool enabled = true,
    FluentAccordionSize size = FluentAccordionSize.medium,
    FluentAccordionExpandIconPosition position =
        FluentAccordionExpandIconPosition.start,
    Widget? leading,
  }) => cell(
    FluentAccordion(
      defaultOpenItems: expanded ? const <Object>{'a'} : const <Object>{},
      children: <Widget>[
        FluentAccordionItem(
          value: 'a',
          size: size,
          expandIconPosition: position,
          enabled: enabled,
          icon: leading,
          header: const Text('Header'),
          child: const Text('Panel'),
        ),
      ],
    ),
  );

  goldenGridTest(
    'accordion',
    () => goldenGrid(<Widget>[
      for (final size in FluentAccordionSize.values) accordion(size: size),
      accordion(expanded: true),
      accordion(
        expanded: true,
        position: FluentAccordionExpandIconPosition.end,
      ),
      accordion(position: FluentAccordionExpandIconPosition.end),
      accordion(enabled: false),
      accordion(leading: icon),
      accordion(
        leading: icon,
        expanded: true,
        position: FluentAccordionExpandIconPosition.end,
      ),
      cell(
        const FluentAccordion(
          multiple: true,
          defaultOpenItems: <Object>{'a', 'b'},
          children: <Widget>[
            FluentAccordionItem(
              value: 'a',
              header: Text('First'),
              child: Text('Panel one'),
            ),
            FluentAccordionItem(
              value: 'b',
              header: Text('Second'),
              child: Text('Panel two'),
            ),
          ],
        ),
      ),
    ]),
  );
}
