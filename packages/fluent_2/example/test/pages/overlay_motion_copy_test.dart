import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// The overlay Motion sections are ported from React stories built on
/// `surfaceMotion` / `backdropMotion` presence slots. FluentDialog,
/// FluentPopover, FluentDrawer, FluentMenu and FluentNavDrawer have none of
/// them: each plays its own fixed motion and only MediaQuery.disableAnimations
/// turns it off. So the copy must describe that, not teach a slot a Flutter
/// reader cannot find.
void main() {
  const List<String> ids = <String>[
    'components-dialog--motion-custom',
    'components-popover--motion-custom',
    'components-popover--motion-disabled',
    'components-drawer--motion-custom',
    'components-drawer--motion-disabled',
    'components-menu-menu--motion-custom',
    'components-menu-menu--motion-disabled',
    'components-nav--custom-motion',
  ];

  for (final String id in ids) {
    test('$id does not teach a motion slot Flutter lacks', () {
      final String description = sectionOf(id).description ?? '';
      expect(description, isNotEmpty);
      expect(description, isNot(contains('surfaceMotion')));
      expect(description, isNot(contains('backdropMotion')));
    });
  }

  testWidgets('the popover motion custom body does not claim a blur-out', (
    WidgetTester tester,
  ) async {
    await pumpSection(
      tester,
      sectionOf('components-popover--motion-custom'),
      inset: const EdgeInsets.all(400),
    );
    await mouseClick(tester, find.text('Open popover'));
    await settle(tester);
    expect(find.text('Popover content'), findsOneWidget);
    expect(
      find.textContaining('blurs out'),
      findsNothing,
      reason: 'FluentPopover has no exit animation, blurred or otherwise',
    );
  });
}
