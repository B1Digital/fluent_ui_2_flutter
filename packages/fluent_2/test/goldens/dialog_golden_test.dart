import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The surface is built through the recomposition contract rather than by
/// opening a `FluentDialog`: the real widget puts itself in an `Overlay`, which
/// paints outside the captured subtree. `buildFluentDialog` renders the
/// identical surface inline, which is what these images are for.
///
/// One cell per row: the 600 surface with both action groups, the same without
/// a close button, the 320 surface with its stacked actions, and finally the
/// 320 surface over the scrim — which is the cell the high-contrast image is
/// really for, since a scrim that had been hardcoded transparent would vanish
/// there and nowhere else.
void main() {
  Widget action(String label) =>
      FluentButton(onPressed: () {}, child: Text(label));

  Widget primary(String label) => FluentButton(
    appearance: FluentButtonAppearance.primary,
    onPressed: () {},
    child: Text(label),
  );

  Widget close() => FluentButton.icon(
    icon: const Icon(fluentDialogCloseIcon),
    semanticLabel: 'Close',
    appearance: FluentButtonAppearance.subtle,
    onPressed: () {},
  );

  Widget surface({
    required FluentDialogSize size,
    bool withClose = true,
    List<Widget> actions = const <Widget>[],
    List<Widget> secondaryActions = const <Widget>[],
  }) => Builder(
    builder: (context) {
      final state = resolveFluentDialogState(
        size: size,
        content: const Text('Body copy'),
        title: const Text('Title'),
        closeButton: withClose ? close() : null,
        actions: actions,
        secondaryActions: secondaryActions,
      );
      return buildFluentDialog(
        state,
        resolveFluentDialogStyle(state, FluentTheme.of(context)),
        const <WidgetState>{},
      );
    },
  );

  Widget overScrim(Widget child) => Builder(
    builder: (context) {
      final state = resolveFluentDialogState(content: const SizedBox.shrink());
      final style = resolveFluentDialogStyle(state, FluentTheme.of(context));
      return SizedBox(
        width: 600,
        height: 220,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ColoredBox(
                color: style.scrimColor!.resolve(const <WidgetState>{})!,
              ),
            ),
            Center(child: child),
          ],
        ),
      );
    },
  );

  goldenGridTest(
    'dialog',
    () => goldenGrid(<Widget>[
      surface(
        size: FluentDialogSize.medium,
        actions: <Widget>[primary('Ok'), action('No')],
        secondaryActions: <Widget>[action('Help')],
      ),
      surface(
        size: FluentDialogSize.medium,
        withClose: false,
        actions: <Widget>[primary('Ok')],
      ),
      surface(
        size: FluentDialogSize.small,
        actions: <Widget>[primary('Ok')],
        secondaryActions: <Widget>[action('No')],
      ),
      overScrim(
        surface(size: FluentDialogSize.small, actions: <Widget>[primary('Ok')]),
      ),
    ], columns: 1),
    surfaceSize: const Size(900, 1100),
  );
}
