import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/pages.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sweeps a mouse over every section of every page and fails on any error.
///
/// `render_test.dart` proves each section builds; nothing proved it survives a
/// pointer. The hover paths — callouts, tooltips, hover rules, row actions —
/// only run once a mouse arrives, and they are where this package's errors
/// kept turning up: a chart callout taller than its plot overflowed by 454px on
/// every hover of the LineChart "Multiple" story, and only a person moving a
/// real mouse over the page ever saw it.
///
/// A mouse, not `tester.tap`: hover is a mouse-only event, and a touch pointer
/// would never enter a `MouseRegion`. The sweep visits the centre and the
/// top-left corner of every `MouseRegion`, then an 18px raster over every
/// `CustomPaint` large enough to be a chart plot, dwelling one frame at each.
/// That is coarse on purpose — it has to cover ninety pages in about a minute —
/// but every chart mark in the corpus is wider than 18px or sits inside a
/// region whose centre it visits.
void main() {
  for (final DocsPage page in allPages) {
    testWidgets('${page.id} survives a mouse sweep', (tester) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final errors = <String>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) =>
          errors.add(details.exceptionAsString().split('\n').first);
      try {
        for (final DocsSection section in page.sections) {
          await _sweep(tester, section, errors);
        }
      } finally {
        FlutterError.onError = original;
      }
      expect(errors, isEmpty, reason: '${page.id} threw under the mouse');
    });
  }
}

Future<void> _sweep(
  WidgetTester tester,
  DocsSection section,
  List<String> errors,
) async {
  await tester.pumpWidget(
    FluentApp(
      debugShowCheckedModeBanner: false,
      home: SingleChildScrollView(child: Builder(builder: section.builder)),
    ),
  );
  // Not pumpAndSettle: Spinner, ProgressBar and Skeleton animate forever.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(1599, 1599));
  for (final target in _targets()) {
    await mouse.moveTo(target);
    await tester.pump(const Duration(milliseconds: 16));
    final Object? taken = tester.takeException();
    if (taken != null) errors.add('${section.id}: $taken'.split('\n').first);
  }
  await mouse.moveTo(const Offset(1599, 1599));
  await tester.pump(const Duration(milliseconds: 300));
  await mouse.removePointer();

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  final Object? taken = tester.takeException();
  if (taken != null) errors.add('${section.id}: $taken'.split('\n').first);
}

/// Where the sweep points the mouse, capped so a huge section cannot stall it.
///
/// Collected before the first move, not lazily: hovering mounts and unmounts
/// callouts, and a finder walked across that would read defunct elements.
List<Offset> _targets() {
  final targets = <Offset>[
    for (final rect in find.byType(MouseRegion).evaluate().map(_globalRect))
      if (rect != null) ...<Offset>[
        rect.center,
        rect.topLeft + const Offset(1, 1),
      ],
    for (final rect in find.byType(CustomPaint).evaluate().map(_globalRect))
      if (rect != null && rect.width >= 120 && rect.height >= 60)
        for (var y = rect.top + 4; y < rect.bottom && y < 1600; y += 18)
          for (var x = rect.left + 4; x < rect.right; x += 18) Offset(x, y),
  ];
  return targets.take(3000).toList();
}

/// [element]'s box in global coordinates, or null when it is off screen or
/// has no size.
Rect? _globalRect(Element element) {
  final RenderObject? box = element.renderObject;
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  if (rect.isEmpty || rect.top >= 1600) return null;
  return rect;
}
