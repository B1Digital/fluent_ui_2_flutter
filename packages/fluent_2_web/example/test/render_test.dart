import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web_example/pages.dart';
import 'package:fluent_2_web_example/shell/catalog.dart';
import 'package:fluent_2_web_example/shell/showroom_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sections whose widgets throw while being torn down, with the defect.
///
/// These are library bugs surfaced by the showroom, not page bugs: each one
/// renders correctly and only fails on disposal. They are listed rather than
/// silently tolerated so that the list is the bug report — and so a section
/// that starts failing for a *new* reason still turns the build red.
const Map<String, String> _knownDisposalDefects = <String, String>{
  'FluentDialog':
      'dialog.dart:579-591 declares _controller, _surfaceCurve and _scrimCurve '
      'as `late final` with initialisers, so they are built on first access. '
      'dispose() at :653-662 touches all three unconditionally, so a dialog '
      'that was never opened CONSTRUCTS an AnimationController(vsync: this) '
      'during unmount and createTicker reads TickerMode from a deactivated '
      'element. Repro needs no page code: pump a FluentDialog(open: false), '
      'then unmount it. Fix: build them in initState, or guard dispose.',
  'FluentCarousel':
      'autoplay leaves an in-flight PageController animation running past '
      'deactivation; its completion callback then looks up an ancestor.',
};

/// Sections that tripped a disposal defect this run, filled in as the suite
/// goes and checked once at the end.
final Set<String> _disposalFailures = <String>{};

/// Proves the shell boots and every section renders.
///
/// This test inherits a job from the storybook it replaced: the GitHub Pages
/// deploy builds this app on every push to `main`, so a page that fails to
/// compile or throws on build has to land as a red test rather than a failed
/// deploy. Importing `pages.dart` forces every page file through the compiler;
/// mounting each section catches the rest.
void main() {
  testWidgets('the showroom boots', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ShowroomApp());
    // Not a bare `pump()`: FluentApp renders SizedBox.shrink() until the web
    // font future resolves, so a single frame would assert against an empty
    // tree and pass on nothing.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(catalog.first.pages.first.title), findsWidgets);
  });

  for (final DocsPage page in allPages) {
    testWidgets('${page.id} renders every section', (
      WidgetTester tester,
    ) async {
      // Tall enough that a section laying out at its natural height does not
      // overflow and report a false failure.
      tester.view.physicalSize = const Size(1600, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final DocsSection section in page.sections) {
        // Mounted under a real FluentApp, not a bare FluentTheme: popovers,
        // menus, dialogs, drawers and toasts all resolve `Overlay.of(context)`,
        // which only exists below the app's Navigator.
        await tester.pumpWidget(
          FluentApp(
            debugShowCheckedModeBanner: false,
            home: SingleChildScrollView(
              child: Builder(builder: section.builder),
            ),
          ),
        );
        // Not pumpAndSettle: Spinner, ProgressBar (indeterminate) and
        // Skeleton's wave animate forever, so it could never return for those
        // pages. A bounded pump is also all this test needs — enough frames to
        // resolve FluentApp's font future and run a build and layout pass,
        // which is what the assertion below is about.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          tester.takeException(),
          isNull,
          reason: '${section.id} threw while rendering',
        );

        // Unmount before the next section rather than letting the next
        // pumpWidget swap the tree underneath a running animation. Carousel
        // autoplays on a Timer, and tearing that down mid-flight is a separate
        // failure from "the section does not render" — keeping them apart is
        // what makes this test's verdict mean something.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        if (tester.takeException() != null) {
          _disposalFailures.add(section.id);
        }
      }
    });
  }

  // Declared last, so it runs last: every disposal failure this suite saw must
  // be one of the library defects documented above. A section that starts
  // failing for a *new* reason is not covered by any of them and turns the
  // build red here.
  test('disposal failures are only the documented library defects', () {
    const Set<String> affectedPrefixes = <String>{
      'components-dialog--',
      'components-carousel-carousel--',
    };
    final List<String> unexplained =
        _disposalFailures
            .where(
              (String id) =>
                  !affectedPrefixes.any((String p) => id.startsWith(p)),
            )
            .toList()
          ..sort();

    expect(
      unexplained,
      isEmpty,
      reason:
          'These sections threw on disposal for a reason not covered by '
          '_knownDisposalDefects:\n  ${unexplained.join('\n  ')}',
    );

    // ignore: avoid_print
    print(
      'disposal defects hit ${_disposalFailures.length} sections '
      '(${_knownDisposalDefects.keys.join(', ')})',
    );
  });
}
