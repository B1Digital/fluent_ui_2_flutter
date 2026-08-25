import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/pages.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('carousel alignment knob moves the card', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final DocsSection s = pageById("components-carousel-carousel")!.sections.firstWhere(
      (e) => e.id.endsWith('--alignment-and-whitespace'),
    );

    await tester.pumpWidget(
      FluentApp(
        debugShowCheckedModeBanner: false,
        home: Builder(builder: s.builder),
      ),
    );
    await tester.pumpAndSettle();

    Rect cardRect() {
      final f = find.byType(FluentPersona).first;
      return tester.getRect(f);
    }

    final Rect centerRect = cardRect();
    // ignore: avoid_print
    print('CENTER: $centerRect');

    // open dropdown
    await tester.tap(find.byType(FluentDropdown<String>));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('options found: ${find.text('start').evaluate().length}');
    await tester.tap(find.text('start').last);
    await tester.pumpAndSettle();

    final Rect startRect = cardRect();
    // ignore: avoid_print
    print('START: $startRect');

    expect(startRect.left, lessThan(centerRect.left),
        reason: 'selecting start should move the card left');
  });
}
