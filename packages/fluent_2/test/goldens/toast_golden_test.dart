import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Two columns of 292-wide toasts: the five `Toast status` modes down the
/// first, then the three `Toast type` modes and the richer body forms.
///
/// The **surface** is what is captured, not the toaster. A toast rendered
/// inline is exactly what `FluentToaster` puts in the overlay, and it has no
/// ticker of its own — so `pumpAndSettle` returns instead of running an
/// auto-dismiss countdown out, and the image is deterministic.
///
/// A toast carries `shadow16`, which spills well past its box, so the cells are
/// laid out with the grid's own 16 gap and the surface is generous.
void main() {
  Widget cell({
    FluentToastIntent intent = FluentToastIntent.info,
    FluentToastType type = FluentToastType.dismiss,
    Widget? body,
    Widget? subtitle,
    List<Widget> footer = const <Widget>[],
    Widget? icon,
    bool showIcon = true,
  }) => SizedBox(
    width: 292,
    child: FluentToast(
      intent: intent,
      type: type,
      icon: icon,
      showIcon: showIcon,
      title: const Text('Email sent'),
      body: body,
      subtitle: subtitle,
      footer: footer,
      onDismiss: () {},
      timestamp: const Text('12:04 PM'),
      action: FluentLink(onPressed: () {}, child: const Text('Undo')),
    ),
  );

  goldenGridTest(
    'toast',
    () => goldenGrid(columns: 2, <Widget>[
      // Every Toast status mode. `custom` covers Figma's Icon, Spinner and
      // Avatar, which differ only in the widget dropped into the slot.
      for (final intent in FluentToastIntent.values)
        cell(
          intent: intent,
          icon: intent == FluentToastIntent.custom
              ? const Icon(FluentIcons.circle_20_filled)
              : null,
        ),
      cell(showIcon: false),

      // Every Toast type mode.
      cell(type: FluentToastType.timestamp),
      cell(type: FluentToastType.action),

      // The body block: secondary line, tertiary line, footer actions.
      cell(body: const Text('Your message is on its way.')),
      cell(
        intent: FluentToastIntent.success,
        body: const Text('Your message is on its way.'),
        subtitle: const Text('Sent to 4 recipients'),
      ),
      cell(
        intent: FluentToastIntent.error,
        body: const Text('We could not reach the server.'),
        footer: <Widget>[
          FluentLink(onPressed: () {}, child: const Text('Retry')),
          FluentLink(onPressed: () {}, child: const Text('Details')),
        ],
      ),
      cell(
        intent: FluentToastIntent.warning,
        type: FluentToastType.timestamp,
        body: const Text('Your licence expires in three days.'),
        subtitle: const Text('Renew before 1 September'),
        footer: <Widget>[
          FluentLink(onPressed: () {}, child: const Text('Renew')),
        ],
      ),
    ]),
    surfaceSize: const Size(760, 1100),
  );
}
