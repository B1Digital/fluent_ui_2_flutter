import 'dart:math' as math;

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/router.dart';
import 'package:fluent_2_example/shell/showroom_app.dart';
import 'package:fluent_2_example/shell/showroom_scope.dart';
import 'package:fluent_2_example/shell/vision_filter.dart';
import 'package:fluent_2_example/shell/widgets/docs_scaffold.dart';
import 'package:fluent_2_example/shell/widgets/preview_band.dart';
import 'package:fluent_2_example/shell/widgets/story_canvas.dart';
import 'package:fluent_2_example/shell/widgets/story_outlines.dart';
import 'package:fluent_2_example/shell/widgets/toolbar_parts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mouse.dart';

/// The story canvas (`#/story/<id>`) against Storybook 9.1.17's canvas bar,
/// in the real [ShowroomApp].
///
/// Upstream's canvas set, left to right (live `tools.t15`): Remount, Zoom in,
/// Zoom out, Reset zoom, a separator, Outline, Viewport, Vision simulator,
/// Theme, Direction and Strict mode, with Copy canvas link against the right
/// edge — no Grid and no Background. Measure, Full screen and "Open canvas in
/// new tab" are out of scope. Every press is a real mouse click: the bar sits
/// at y=0, where a synthesised still touch has hidden dead controls before.
void main() {
  const String remount = 'Remount component';
  const String zoomIn = 'Zoom in';
  const String zoomOut = 'Zoom out';
  const String resetZoom = 'Reset zoom';
  const String outline = 'Apply outlines to the preview';
  const String viewport = 'Change the size of the preview';
  const String vision = 'Vision simulator';
  const String theme = 'Change Fluent theme';
  const String direction = 'Change Direction';
  const String strict = 'Toggle React Strict mode';
  const String copy = 'Copy canvas link';

  group('the bar', () {
    testWidgets('upstream canvas tools, left to right, one separator after '
        'the zoom group; no grid, no background', (WidgetTester tester) async {
      await _boot(tester);
      final List<Rect> rects = <Rect>[
        for (final String tooltip in <String>[
          remount,
          zoomIn,
          zoomOut,
          resetZoom,
          outline,
          viewport,
          vision,
          theme,
          direction,
          strict,
          copy,
        ])
          tester.getRect(_control(tooltip)),
      ];
      for (int i = 1; i < rects.length; i++) {
        expect(rects[i].left, greaterThan(rects[i - 1].right), reason: '$i');
      }
      // The bar's 10px inset on both sides.
      expect(rects.first.left, 10);
      expect(rects.last.right, 1600 - 10);
      expect(find.byType(ToolbarSeparator), findsOneWidget);
      final Rect rule = tester.getRect(find.byType(ToolbarSeparator));
      expect(rule.left, greaterThan(rects[3].right));
      expect(rule.right, lessThan(rects[4].left));

      for (final String absent in <String>[
        'Apply a grid to the preview',
        'Change the background of the preview',
        'Toggle grid',
        'Toggle background',
      ]) {
        expect(_control(absent), findsNothing, reason: absent);
      }
      expect(find.byType(PreviewBand), findsNothing);
      // Only while a viewport is set.
      expect(_control('Rotate viewport'), findsNothing);
      expect(_control('Viewport width'), findsNothing);
      expect(_control('Viewport height'), findsNothing);
    });

    testWidgets('the tooltips at both ends land under the bar, inside the '
        'window', (WidgetTester tester) async {
      await _boot(tester);
      for (final String tooltip in <String>[remount, copy]) {
        final Rect rect = await _tooltipRect(tester, tooltip);
        expect(rect.top, greaterThanOrEqualTo(40), reason: tooltip);
        expect(rect.left, greaterThanOrEqualTo(0), reason: tooltip);
        expect(rect.right, lessThanOrEqualTo(1600), reason: tooltip);
      }
    });

    testWidgets('Copy canvas link puts this page on the clipboard', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await mouseClick(tester, _control(copy));
      expect(copied, Uri.base.toString());
    });
  });

  group('Remount', () {
    testWidgets('remounts the story, which still works, and spins its glyph '
        'once over 1000ms ease-out', (WidgetTester tester) async {
      await _boot(tester);
      await mouseClick(tester, find.byType(FluentSwitch));
      expect(_switchOn(tester), isTrue);

      final AnimatedRotation spin = tester.widget<AnimatedRotation>(
        find.descendant(
          of: _control(remount),
          matching: find.byType(AnimatedRotation),
        ),
      );
      expect(spin.duration, const Duration(milliseconds: 1000));
      expect(spin.curve, Curves.easeOut);
      expect(_turns(tester), 0);

      // mouseClick without its settle, to catch the glyph mid-turn.
      final TestGesture press = await tester.startGesture(
        tester.getCenter(_control(remount)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 90));
      await press.moveBy(const Offset(1.5, 1.5));
      await tester.pump(const Duration(milliseconds: 10));
      await press.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Ease-out is past half a turn at half time.
      expect(_turns(tester), inExclusiveRange(0.5, 1));
      await tester.pumpAndSettle();
      expect(_turns(tester), 1);

      expect(_switchOn(tester), isFalse, reason: 'the story remounted');
      await mouseClick(tester, find.byType(FluentSwitch));
      expect(_switchOn(tester), isTrue, reason: 'and still takes a click');
    });
  });

  group('Zoom', () {
    testWidgets('in x1.25, out x0.8, reset to 1 — unclamped; the story '
        'reflows and reports its scaled height', (WidgetTester tester) async {
      // A Wrap, so a narrow layout reflows rather than overflows.
      await _boot(tester, story: _wrapStory);
      final double width = tester.getRect(_primary).width;
      double ratio() => tester.getRect(_primary).width / width;

      for (int i = 0; i < 7; i++) {
        await mouseClick(tester, _control(zoomIn));
      }
      // 4.77: the old canvas stopped at 4.
      final double z = math.pow(1.25, 7).toDouble();
      expect(ratio(), moreOrLessEquals(z, epsilon: 1e-9));
      // Laid out at 1600 / z, then scaled: the body's 16px inset scales with
      // it on both sides, where a bare Transform.scale would run the wrapper
      // z times off the right edge.
      final Rect wrapper = tester.getRect(_wrapper);
      expect(wrapper.left, moreOrLessEquals(16 * z, epsilon: 1e-9));
      expect(wrapper.right, moreOrLessEquals(1600 - 16 * z, epsilon: 1e-9));
      expect(wrapper.top, moreOrLessEquals(40 + 16 * z, epsilon: 1e-9));
      // The page is 16 + wrapper + 16 tall before scaling; the scroll extent
      // covers all of it once scaled, past the 960px stage.
      final double page = 32 + tester.getSize(_wrapper).height;
      expect(page * z, greaterThan(960));
      expect(
        _scroll(tester).maxScrollExtent,
        moreOrLessEquals(page * z - 960, epsilon: 1e-6),
      );

      await mouseClick(tester, _control(zoomOut));
      expect(ratio(), moreOrLessEquals(z * 0.8, epsilon: 1e-9));

      await mouseClick(tester, _control(resetZoom));
      expect(ratio(), 1);
      expect(tester.getRect(_wrapper).left, 16);
    });
  });

  group('Viewport', () {
    testWidgets('Small mobile frames the story at 320x568, centred; rotate '
        'swaps it; Reset only while set', (WidgetTester tester) async {
      await _boot(tester, story: _wrapStory);
      expect(_frame, findsNothing);

      await mouseClick(tester, _control(viewport));
      expect(find.text('Reset viewport'), findsNothing);
      expect(
        _topsOf(tester, <String>[
          'Small mobile',
          'Large mobile',
          'Tablet',
          'Desktop',
        ]),
        _ascending,
      );
      await mouseClick(tester, find.text('Small mobile'));

      // Centred in the 1600x960 stage under the 40px bar.
      expect(tester.getRect(_frame), const Rect.fromLTWH(640, 236, 320, 568));
      expect(tester.getRect(_wrapper).left, 640 + 16);
      expect(tester.getRect(_wrapper).right, 960 - 16);
      expect(find.text('Small mobile (P)'), findsOneWidget);
      expect(_button(tester, viewport).active, isTrue);
      expect(_sizeLabel('Viewport width', '320'), findsOneWidget);
      expect(_sizeLabel('Viewport height', '568'), findsOneWidget);
      // The frame is a box, not a fake window: fluent_2's popups measure
      // their room from MediaQuery.
      expect(
        MediaQuery.sizeOf(tester.element(_primary)),
        const Size(1600, 1000),
      );

      await mouseClick(tester, _control('Rotate viewport'));
      expect(tester.getRect(_frame), const Rect.fromLTWH(516, 360, 568, 320));
      expect(find.text('Small mobile (L)'), findsOneWidget);
      expect(_sizeLabel('Viewport width', '568'), findsOneWidget);
      expect(_sizeLabel('Viewport height', '320'), findsOneWidget);

      // Taller than the stage: flush with its top, still centred across. A
      // pick resets the rotation, as upstream's `{value, isRotated: false}`.
      await mouseClick(tester, _control(viewport));
      expect(
        _topsOf(tester, <String>['Reset viewport', 'Small mobile']),
        _ascending,
      );
      await mouseClick(tester, find.text('Desktop'));
      expect(tester.getRect(_frame), const Rect.fromLTWH(160, 40, 1280, 1024));
      expect(find.text('Desktop (P)'), findsOneWidget);

      await mouseClick(tester, _control(viewport));
      await mouseClick(tester, find.text('Reset viewport'));
      expect(_frame, findsNothing);
      expect(tester.getRect(_wrapper).left, 16);
      expect(tester.getRect(_wrapper).right, 1600 - 16);
      expect(_control('Rotate viewport'), findsNothing);
      expect(_button(tester, viewport).active, isFalse);
    });

    testWidgets('the story keeps its state through a viewport change', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      await mouseClick(tester, find.byType(FluentSwitch));
      await mouseClick(tester, _control(viewport));
      await mouseClick(tester, find.text('Tablet'));
      expect(_frame, findsOneWidget);
      expect(_switchOn(tester), isTrue);
    });
  });

  group('Vision simulator', () {
    testWidgets('filters the story; shares as a second line; Reset color '
        'filter only while set; the story keeps its state', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      await mouseClick(tester, find.byType(FluentSwitch));
      expect(tester.widget<ImageFiltered>(_filtered).enabled, isFalse);

      await mouseClick(tester, _control(vision));
      expect(find.text('Reset color filter'), findsNothing);
      expect(
        _topsOf(tester, <String>[
          for (final VisionFilter f in VisionFilter.values) f.label,
        ]),
        _ascending,
      );
      for (final VisionFilter f in VisionFilter.values) {
        if (f.share != null) {
          final Rect name = tester.getRect(find.text(f.label));
          final Rect share = tester.getRect(find.text('${f.share} of users'));
          expect(share.top, greaterThanOrEqualTo(name.bottom), reason: f.label);
        }
      }
      expect(find.textContaining(' of users'), findsNWidgets(8));

      await mouseClick(tester, find.text('Protanopia'));
      final ImageFiltered filtered = tester.widget<ImageFiltered>(_filtered);
      expect(filtered.enabled, isTrue);
      expect(filtered.imageFilter, VisionFilter.protanopia.imageFilter);
      expect(
        find.descendant(of: _filtered, matching: find.byType(FluentSwitch)),
        findsOneWidget,
      );
      expect(_button(tester, vision).active, isTrue);
      expect(_switchOn(tester), isTrue, reason: 'filtering is paint-only');

      await mouseClick(tester, _control(vision));
      expect(
        _topsOf(tester, <String>['Reset color filter', 'Blurred Vision']),
        _ascending,
      );
      await mouseClick(tester, find.text('Reset color filter'));
      expect(tester.widget<ImageFiltered>(_filtered).enabled, isFalse);
      expect(_button(tester, vision).active, isFalse);
    });
  });

  group('story frame', () {
    testWidgets('16px body padding, then the nb2 wrapper at full width; RTL '
        'puts the story 16 + 24 in from the right', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      final Rect wrapper = tester.getRect(_wrapper);
      expect(wrapper.left, 16);
      expect(wrapper.right, 1600 - 16);
      expect(wrapper.top, 40 + 16);
      expect(
        tester.widget<ColoredBox>(_wrapper).color,
        const Color(0xFFFAFAFA),
      );
      expect(tester.getRect(find.byType(FluentSwitch)).left, 16 + 24);
      expect(tester.getRect(find.byType(FluentSwitch)).top, 40 + 16 + 48);

      await mouseClick(tester, _control(direction));
      expect(find.text('Direction: RTL', findRichText: true), findsOneWidget);
      expect(tester.getRect(find.byType(FluentSwitch)).right, 1600 - 16 - 24);
    });

    testWidgets('Outline and Strict mode are the shared scope', (
      WidgetTester tester,
    ) async {
      await _boot(tester);
      ShowroomScope scope() =>
          ShowroomScope.of(tester.element(find.byType(StoryCanvas)));

      await mouseClick(tester, _control(outline));
      expect(scope().outlines, isTrue);
      expect(_button(tester, outline).active, isTrue);
      expect(tester.widget<StoryOutlines>(_outlines).enabled, isTrue);
      // The wrapper is the outliner's first box, as `.sb-show-main div`
      // outlines upstream's.
      expect(tester.getRect(_outlines), tester.getRect(_wrapper));

      await mouseClick(tester, find.byType(FluentSwitch));
      expect(_switchOn(tester), isTrue);
      await mouseClick(tester, _control(strict));
      expect(scope().strictMode, isTrue);
      expect(_button(tester, strict).active, isTrue);
      expect(_switchOn(tester), isFalse, reason: 'strict mode remounts');
    });
  });
}

/// A stateful story: a switch the demo owns.
const String _switchStory = 'components-switch--default';

/// Five buttons in a Wrap, one of them the brand-filled Primary.
const String _wrapStory = 'components-button-button--appearance';

Future<void> _boot(WidgetTester tester, {String story = _switchStory}) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const ShowroomApp());
  // FluentApp renders SizedBox.shrink() until its web-font future resolves.
  await tester.pumpAndSettle();
  DocsRouterScope.of(
    tester.element(find.byType(DocsScaffold)),
  ).go(DocsRoute.story(story));
  await tester.pumpAndSettle();
  expect(find.byType(StoryCanvas), findsOneWidget);
}

/// The bar control, or size label, whose tooltip is [tooltip].
Finder _control(String tooltip) => find.byWidgetPredicate(
  (Widget w) =>
      w is FluentTooltip &&
      w.content is Text &&
      (w.content as Text).data == tooltip,
);

ToolbarButton _button(WidgetTester tester, String tooltip) =>
    tester.widget<ToolbarButton>(
      find.byWidgetPredicate(
        (Widget w) => w is ToolbarButton && w.tooltip == tooltip,
      ),
    );

Finder _sizeLabel(String tooltip, String value) =>
    find.descendant(of: _control(tooltip), matching: find.text(value));

final Finder _primary = find.widgetWithText(FluentButton, 'Primary');

bool _switchOn(WidgetTester tester) =>
    tester.widget<FluentSwitch>(find.byType(FluentSwitch)).checked;

/// The outliner sits right around the wrapper, so its box is the wrapper's.
final Finder _outlines = find.byType(StoryOutlines);

/// Upstream's `FluentExampleContainer`: the nb2 box around the story.
final Finder _wrapper = find
    .descendant(of: _outlines, matching: find.byType(ColoredBox))
    .first;

/// The viewport frame: the one box casting the backdrop shadow.
final Finder _frame = find.descendant(
  of: find.byType(StoryCanvas),
  matching: find.byWidgetPredicate(
    (Widget w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).boxShadow != null,
  ),
);

final Finder _filtered = find.descendant(
  of: find.byType(StoryCanvas),
  matching: find.byType(ImageFiltered),
);

ScrollPosition _scroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(StoryCanvas),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

double _turns(WidgetTester tester) => tester
    .widget<RotationTransition>(
      find.descendant(
        of: find.byType(AnimatedRotation),
        matching: find.byType(RotationTransition),
      ),
    )
    .turns
    .value;

/// Hovers the control past the 250ms show delay and returns where its
/// tooltip text landed, then moves the mouse away and lets it close.
Future<Rect> _tooltipRect(WidgetTester tester, String tooltip) async {
  final TestGesture mouse = await mouseHover(tester, _control(tooltip));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  expect(find.text(tooltip), findsOneWidget, reason: '"$tooltip" shows');
  final Rect rect = tester.getRect(find.text(tooltip));
  await mouse.removePointer();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  return rect;
}

/// The top edge of each label, in the order given.
List<double> _topsOf(WidgetTester tester, List<String> labels) => <double>[
  for (final String label in labels) tester.getRect(find.text(label)).top,
];

/// Strictly increasing, i.e. the rows are in the order listed.
final Matcher _ascending = predicate<List<double>>((List<double> tops) {
  for (int i = 1; i < tops.length; i++) {
    if (tops[i] <= tops[i - 1]) {
      return false;
    }
  }
  return true;
}, 'rows in the listed order');
