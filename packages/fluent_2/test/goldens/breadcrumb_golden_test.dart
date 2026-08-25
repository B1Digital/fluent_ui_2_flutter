import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The trail grid is one row per `Size`, plus a truncated trail and a disabled
/// crumb. The overflow popup is captured separately because an open popup lives
/// in the [Overlay], which sits above the RepaintBoundary these images are
/// cropped to — rendering the surface through its own builder captures the same
/// pixels without one.
void main() {
  List<FluentBreadcrumbItem> items({bool disabled = false}) =>
      <FluentBreadcrumbItem>[
        FluentBreadcrumbItem(
          label: const Text('Home'),
          icon: const Icon(FluentIcons.home_20_regular),
          onPressed: () {},
        ),
        FluentBreadcrumbItem(
          label: const Text('Reports'),
          enabled: !disabled,
          onPressed: () {},
        ),
        const FluentBreadcrumbItem(label: Text('Q3')),
      ];

  goldenGridTest(
    'breadcrumb',
    () => goldenGrid(<Widget>[
      for (final size in FluentBreadcrumbSize.values)
        FluentBreadcrumb(size: size, items: items()),
      // Disabled is a real state, not a treatment: it swaps the whole ramp.
      FluentBreadcrumb(items: items(disabled: true)),
      // Truncated: the root stays pinned, the tail stays visible, and the
      // middle folds behind the overflow trigger.
      FluentBreadcrumb(
        maxDisplayedItems: 3,
        items: <FluentBreadcrumbItem>[
          for (var i = 0; i < 5; i++)
            FluentBreadcrumbItem(
              label: Text('Level $i'),
              onPressed: i == 4 ? null : () {},
            ),
        ],
      ),
    ], columns: 1),
  );

  goldenGridTest(
    'breadcrumb',
    suffix: '.overflow',
    () => Builder(
      builder: (context) {
        final style = resolveFluentBreadcrumbStyle(
          resolveFluentBreadcrumbState(overflow: true),
          FluentTheme.of(context),
        );
        const states = <WidgetState>{};
        final rowStyle = resolveFluentBreadcrumbStyle(
          resolveFluentBreadcrumbState(),
          FluentTheme.of(context),
        );

        return SizedBox(
          width: 180,
          child: buildFluentBreadcrumbSurface(
            style,
            states,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: rowStyle.surfaceGap!.resolve(states)!,
              children: <Widget>[
                for (final label in <String>['Level 1', 'Level 2', 'Level 3'])
                  buildFluentBreadcrumb(
                    resolveFluentBreadcrumbState(label: Text(label)),
                    rowStyle,
                    // The middle row shows the keyboard-active treatment.
                    label == 'Level 2'
                        ? const <WidgetState>{WidgetState.focused}
                        : states,
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
