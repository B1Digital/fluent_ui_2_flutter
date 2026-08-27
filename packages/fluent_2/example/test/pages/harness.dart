import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/pages.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:fluent_2_example/shell/docs_metrics.dart';
import 'package:fluent_2_example/shell/widgets/markdown_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The scaffolding every per-page suite in `test/pages/` shares.
///
/// `render_test.dart` already proves each section *mounts*. These suites prove
/// each section *works*: that a knob moves what it claims to move, that a
/// button does what its label says, and that nothing throws on the way in, on
/// the way through, or on the way out. So the helpers here are all about
/// driving a demo and reading what changed, and every one of them asserts the
/// tree stayed clean.

/// Mounts [section] on its own, under a real [FluentApp].
///
/// A bare [FluentTheme] is not enough: popovers, menus, dialogs, drawers and
/// toasts all resolve `Overlay.of(context)`, which only exists below the app's
/// Navigator.
///
/// [inset] pads the demo away from the corner. A surface anchored *above* its
/// trigger lands at a negative y when the trigger sits at the top of the
/// viewport, and a render box outside the view is not merely invisible — it
/// hit-tests to nothing, so its buttons cannot be tapped or clicked at all.
/// Padding buys the surface room without changing anything the demo does.
///
/// [loose] hands the demo the constraints the real showroom hands it. The story
/// stage aligns each demo to `centerStart`, so a demo's own
/// `ConstrainedBox(maxWidth: 400)` bites; a bare scroll view instead gives its
/// child a TIGHT width, and `enforce` clamps that maxWidth straight back up to
/// the viewport. Set this on any section whose subject is its own width —
/// truncation, wrapping, an intrinsic — or it will be measured at 1600 wide and
/// prove the opposite of what it renders in the app.
Future<void> pumpSection(
  WidgetTester tester,
  DocsSection section, {
  Size size = const Size(1600, 1400),
  bool scroll = true,
  bool loose = false,
  EdgeInsets inset = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget demo = Padding(
    padding: inset,
    child: Builder(builder: section.builder),
  );
  if (loose) {
    demo = Align(alignment: AlignmentDirectional.centerStart, child: demo);
  }
  await tester.pumpWidget(
    FluentApp(
      debugShowCheckedModeBanner: false,
      home: scroll ? SingleChildScrollView(child: demo) : demo,
    ),
  );
  // Not pumpAndSettle: Spinner, ProgressBar and Skeleton animate forever.
  // Three bounded frames resolve FluentApp's web-font future and run a build,
  // a layout and a paint pass, which is all any assertion here needs.
  await settle(tester);
  expectClean(tester, 'mounting ${section.id}');
}

/// The section with [id], or a failure naming the id that did not resolve.
DocsSection sectionOf(String id) {
  final ({DocsPage page, DocsSection section})? found = sectionById(id);
  if (found == null) {
    fail('no section "$id" in the catalog');
  }
  return found.section;
}

/// Every section of the page with [id], in declaration order.
List<DocsSection> sectionsOf(String pageId) {
  final DocsPage? page = pageById(pageId);
  if (page == null) fail('no page "$pageId" in the catalog');
  return page.sections;
}

/// Pumps a bounded number of frames.
///
/// The forever-animating demos make `pumpAndSettle` a hang rather than a wait,
/// so nothing in these suites may call it unconditionally.
Future<void> settle(WidgetTester tester, {int frames = 4}) async {
  await tester.pump();
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Fails if the tree threw since the last check.
void expectClean(WidgetTester tester, String what) {
  final Object? error = tester.takeException();
  expect(error, isNull, reason: '$what threw: $error');
}

/// [expectClean], but a horizontal `RenderFlex` overflow is drained rather than
/// failed.
///
/// `flutter_test` measures with FlutterTest, a face whose every glyph is a
/// square of the font size — roughly twice Selawik's average advance — so a
/// surface with a *fixed* content width overflows here on labels that fit
/// comfortably in a browser. A teaching popover is 288 wide whatever its
/// buttons say, and `Previous` + `Next` measure 312 under a square font and
/// ~200 under a real one; the same arithmetic sinks a `FluentField` label
/// inside a 320-wide box. That is the harness's metric, not the page's layout.
///
/// Use it only where the cause has actually been traced to text metrics —
/// widen the viewport first, and if the overflow survives, it is real. Every
/// other exception still fails, and a vertical overflow still fails: a surface
/// that runs off the bottom is a layout defect no font explains.
void expectCleanExceptOverflow(WidgetTester tester, String what) {
  final Object? error = tester.takeException();
  if (error != null && '$error'.contains('overflowed by')) {
    expect(
      '$error',
      contains('on the right'),
      reason: '$what overflowed somewhere text metrics cannot explain: $error',
    );
    return;
  }
  expect(error, isNull, reason: '$what threw: $error');
}

/// Taps [finder] and pumps, then asserts nothing threw.
Future<void> tapAndSettle(
  WidgetTester tester,
  Finder finder, {
  String? what,
  bool warnIfMissed = true,
}) async {
  await tester.ensureVisible(finder.first);
  await settle(tester);
  await tester.tap(finder.first, warnIfMissed: warnIfMissed);
  await settle(tester);
  expectClean(tester, what ?? 'tapping ${finder.describeMatch(Plurality.one)}');
}

/// Opens [dropdown] and picks the row whose label reads [optionText].
///
/// Returns the value the dropdown holds afterwards, so a caller can assert both
/// that the pick committed and that the demo moved.
Future<T?> pickDropdown<T>(
  WidgetTester tester,
  Finder dropdown,
  String optionText,
) async {
  await tester.ensureVisible(dropdown);
  await settle(tester);
  await tester.tap(dropdown, warnIfMissed: false);
  await settle(tester);

  final Finder row = find.text(optionText);
  expect(
    row,
    findsWidgets,
    reason: 'the open dropdown has no option labelled "$optionText"',
  );
  await tester.tap(row.last, warnIfMissed: false);
  await settle(tester);
  expectClean(tester, 'picking "$optionText"');
  return tester.widget<FluentDropdown<T>>(dropdown).value;
}

/// Drives a real mouse: hover, press, release — the sequence a browser sends.
///
/// Synthetic `tap` skips the hover, and several Fluent controls only reveal
/// their affordance on hover, so a knob can pass under `tap` and be unreachable
/// with a mouse.
Future<void> mouseClick(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await settle(tester);
  await mouseClickAt(
    tester,
    tester.getCenter(finder.first),
    what: finder.describeMatch(Plurality.one),
  );
}

/// [mouseClick] at an arbitrary point rather than at a widget's centre.
///
/// Some controls are one hit target whose *meaning* varies across it — a
/// rating's fourth star, the left half of a half-step shape, one swatch in a
/// wrapped grid — so the centre of the finder is the wrong place to press.
Future<void> mouseClickAt(
  WidgetTester tester,
  Offset target, {
  String what = 'the target',
}) async {
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  // Added and removed inside one call rather than torn down at the end of the
  // test: MouseTracker asserts that every add is preceded by the previous
  // device's remove, so two clicks in a test would trip it.
  await mouse.addPointer(location: target);
  await settle(tester);
  await mouse.down(target);
  await tester.pump(const Duration(milliseconds: 16));
  // The travel is the point. A hand moves the mouse two or three pixels between
  // press and release, and a scrollable's drag recogniser gives a PRECISE
  // pointer only `kPrecisePointerHitSlop` — one pixel — before it claims the
  // gesture. `FluentScrollBehavior` used to list the mouse as a drag device, so
  // every one of those clicks was swallowed by the page instead of reaching the
  // control. A zero-travel click cannot catch that; this one can.
  await mouse.moveTo(target + const Offset(2, 2));
  await tester.pump(const Duration(milliseconds: 16));
  await mouse.up();
  await settle(tester);
  await mouse.removePointer();
  await settle(tester);
  expectClean(tester, 'clicking $what');
}

/// The decoration painted by the [at]-th [DecoratedBox] under [finder].
///
/// A purely visual knob — appearance, selection, disabled, hover — only proves
/// itself in what was painted: a widget's own property flipping says nothing
/// about the fill that reached the screen. On a Fluent surface index 0 is the
/// outer box, which carries the fill and the shadow, and index 1 is the
/// foreground box, which carries the border and the focus ring.
BoxDecoration decorationUnder(
  WidgetTester tester,
  Finder finder, {
  int at = 0,
}) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(of: finder, matching: find.byType(DecoratedBox))
                  .at(at),
            )
            .decoration
        as BoxDecoration;

/// Calls [read] while a real mouse rests on [finder], and returns what it read.
///
/// Hover is unreachable through `tester.tap`, so a control whose only
/// affordance appears under the pointer — and a container that claims it has
/// *no* hover response — can pass every synthetic test and still be wrong in a
/// browser. The pointer is removed before returning, because MouseTracker
/// asserts each device is removed before the next is added.
Future<T> whileHovering<T>(
  WidgetTester tester,
  Finder finder,
  T Function() read,
) async {
  await tester.ensureVisible(finder.first);
  await settle(tester);
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await mouse.addPointer(location: tester.getCenter(finder.first));
  await settle(tester);
  final T value = read();
  await mouse.removePointer();
  await settle(tester);
  expectClean(tester, 'hovering ${finder.describeMatch(Plurality.one)}');
  return value;
}

/// [mouseHover], but at an arbitrary point rather than at a widget's centre.
///
/// A chart paints its whole series onto one [CustomPaint]: every bar, cell,
/// marker and stream shares a single hit target, so "hover the widget" always
/// means the middle of the plot and can never reach the mark a test is about.
/// The coordinates come from the painter's own geometry, which is the only
/// description of where a mark actually landed.
///
/// The pointer is left parked, exactly as [mouseHover] leaves it and for the
/// same reason: a chart popover lives only while the pointer is inside the
/// plot, and lifting the device fires the `onExit` that closes it — so a helper
/// that tidied up after itself could never observe one. The caller owns the
/// returned gesture and must hand it to [mouseAway].
Future<TestGesture> hoverAt(
  WidgetTester tester,
  Offset target, {
  Duration dwell = const Duration(milliseconds: 400),
  String what = 'the target',
}) async {
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  // Entered from off-screen, so the component sees a real enter transition
  // rather than an add that happens to land on it.
  await mouse.addPointer(location: const Offset(-1, -1));
  await tester.pump();
  await mouse.moveTo(target);
  await tester.pump();
  await tester.pump(dwell);
  await settle(tester);
  expectClean(tester, 'hovering $what');
  return mouse;
}

/// The cartesian chart painter mounted under [within], or anywhere.
///
/// Every chart built on the cartesian shell — Gantt, HeatMap, Scatter and the
/// rest — paints its series, its axes and its gridlines into one [CustomPaint]
/// and exposes nothing as a widget. The painter carries the solved layout, the
/// two axis specs and the chart's own delegate, so it is the only place a test
/// can read what a knob did to the geometry: without it, a slider that resized
/// the box while leaving the plot on a stale scale would pass every assertion a
/// widget tree can express.
FluentCartesianChartPainter cartesianPainter(
  WidgetTester tester, [
  Finder? within,
]) {
  final Finder plots = find.byWidgetPredicate(
    (Widget widget) =>
        widget is CustomPaint && widget.painter is FluentCartesianChartPainter,
  );
  final Finder scoped = within == null
      ? plots
      : find.descendant(of: within, matching: plots);
  expect(scoped, findsWidgets, reason: 'no cartesian chart is mounted');
  return tester.widget<CustomPaint>(scoped.first).painter!
      as FluentCartesianChartPainter;
}

/// The scales [painter] paints its marks through.
///
/// Rebuilt exactly as `FluentCartesianChartPainter.paint` builds it, so a
/// delegate asked for its bars, cells or markers here answers with the same
/// geometry that reached the canvas.
FluentCartesianChildContext cartesianContext(
  FluentCartesianChartPainter painter,
) => FluentCartesianChildContext(
  xScale: painter.xAxis.scale,
  yScalePrimary: painter.yAxisPrimary.scale,
  yScaleSecondary: painter.yAxisSecondary?.scale,
  containerWidth: painter.layout.size.width,
  containerHeight: painter.layout.size.height,
);

/// Rests a real mouse on [finder] for [dwell], then lifts it away.
///
/// The counterpart of [mouseClick] for the affordances that never take a press:
/// a tooltip that appears after 250ms, a menu row that opens its submenu after
/// 500ms, a row whose fill only changes under a pointer. `tester.tap` synthesises
/// no hover at all, so none of those can be reached with it.
Future<void> hoverOver(
  WidgetTester tester,
  Finder finder, {
  Duration dwell = const Duration(milliseconds: 600),
}) async {
  await tester.ensureVisible(finder.first);
  await settle(tester);
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  // Added and removed inside one call, for the reason [mouseClick] gives.
  await mouse.addPointer(location: tester.getCenter(finder.first));
  await settle(tester);
  await tester.pump(dwell);
  await settle(tester);
  await mouse.removePointer();
  await settle(tester);
  expectClean(tester, 'hovering ${finder.describeMatch(Plurality.one)}');
}

/// Presses [trigger] and waits for the overlay surface it raises to land.
///
/// Menu, popover and dropdown surfaces all fade in over 400ms while sliding
/// along their opening axis, so a geometry assertion taken on the frame after
/// the press reads a position no user ever sees. [settle]'s four frames are not
/// enough on their own.
Future<void> openOverlay(WidgetTester tester, Finder trigger) async {
  await tapAndSettle(tester, trigger, what: 'the overlay trigger');
  await tester.pump(const Duration(milliseconds: 450));
  await settle(tester);
}

/// Clicks the far corner of the viewport, which is how a user dismisses one.
///
/// A Fluent overlay no longer paints an opaque full-screen barrier behind its
/// surface — dismissal is a `TapRegion` group, so the click that dismisses also
/// **lands on whatever is under it**, the way upstream's document-level
/// `useOnClickOutside` behaves. The far corner is chosen because it is the one
/// spot no showroom page puts a control; if a page ever does, this will press it
/// as well as dismissing, and should aim somewhere else instead.
Future<void> dismissOverlay(WidgetTester tester) async {
  final Size view = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.tapAt(Offset(view.width - 10, view.height - 10));
  await settle(tester);
}

/// Parks a real mouse on [finder] and leaves it there.
///
/// [hoverOver] and [whileHovering] both lift the pointer before they return, so
/// neither can drive what happens *during* a hover that outlives one statement:
/// a tooltip that must still be up a second later, a toast whose countdown is
/// supposed to be paused for as long as the pointer rests on it, a trigger that
/// scrolls out from under a stationary cursor. This leaves the device down and
/// hands it back.
///
/// The pointer is added off-screen and then moved onto the target, so the
/// component sees a genuine enter transition rather than an add that happens to
/// land on it. The caller owns the returned gesture and must hand it to
/// [mouseAway] before starting another: MouseTracker asserts one live device at
/// a time.
Future<TestGesture> mouseHover(
  WidgetTester tester,
  Finder finder, {
  Duration dwell = const Duration(milliseconds: 400),
}) async {
  await tester.ensureVisible(finder.first);
  await settle(tester);
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await mouse.addPointer(location: const Offset(-1, -1));
  await tester.pump();
  await mouse.moveTo(tester.getCenter(finder.first));
  await tester.pump();
  await tester.pump(dwell);
  expectClean(tester, 'hovering ${finder.describeMatch(Plurality.one)}');
  return mouse;
}

/// [mouseHover] at an arbitrary point rather than at a widget's centre.
///
/// A chart's hover targets are canvas ink — a bar, a marker, a heat map cell —
/// so there is no widget to name and no centre to take. The point comes from
/// the display list plus the plot's own origin.
///
/// Hovering and *staying* is what a chart popover needs: it is raised by the
/// plot's `MouseRegion.onHover` and torn down again by its `onExit`, so a click
/// that adds and removes a pointer in one call leaves nothing on screen.
Future<TestGesture> mouseHoverAt(
  WidgetTester tester,
  Offset target, {
  String what = 'the target',
  Duration dwell = const Duration(milliseconds: 400),
}) async {
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  // Added off-screen and then moved in, so the region sees a genuine enter
  // transition rather than an add that happens to land inside it.
  await mouse.addPointer(location: const Offset(-1, -1));
  await tester.pump();
  await mouse.moveTo(target);
  await tester.pump();
  await tester.pump(dwell);
  expectClean(tester, 'hovering $what');
  return mouse;
}

/// Moves [mouse] off every target, waits out the hide delay, and removes it.
Future<void> mouseAway(
  WidgetTester tester,
  TestGesture mouse, {
  Duration dwell = const Duration(milliseconds: 400),
}) async {
  // Outside the view entirely: RenderBox.hitTest bounds-checks, so nothing is
  // under the pointer and every MouseRegion it was inside reports an exit.
  await mouse.moveTo(const Offset(-1, -1));
  await tester.pump();
  await tester.pump(dwell);
  await mouse.removePointer();
  await settle(tester);
  expectClean(tester, 'moving the mouse away');
}

/// The style the label matched by [text] actually rendered with.
///
/// Reads the paragraph, not the `Text` widget: every Fluent component colours
/// its label through an inherited `DefaultTextStyle`, so the widget's own
/// `style` is null exactly where the interesting answer lives.
TextStyle? textStyleOf(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text.first).text.style;

/// A stable description of what the demo currently renders.
///
/// Every visible `Text` in tree order, joined. Comparing this before and after
/// a knob is the cheapest honest answer to "did anything change?" — it needs no
/// knowledge of the demo's internals and it does not go stale when one is
/// restyled.
String textSnapshot(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((String s) => s.isNotEmpty)
    .join('␟');

/// The value the editable inside [finder] currently holds.
///
/// Every field on the Input, SearchBox and Textarea pages keeps its value in an
/// [EditableText] rather than a [Text], so [textSnapshot] cannot see it: a suite
/// that only compared rendered text would pass on a field that silently refused
/// every keystroke.
String editedText(WidgetTester tester, Finder finder) => tester
    .widget<EditableText>(
      find.descendant(of: finder, matching: find.byType(EditableText)).first,
    )
    .controller
    .text;

/// The rect of the first widget matching [finder], or null when it is absent.
Rect? rectOrNull(WidgetTester tester, Finder finder) =>
    finder.evaluate().isEmpty ? null : tester.getRect(finder.first);

/// Every painter of type [P] in the tree, in tree order, optionally scoped to
/// the subtree under [within].
///
/// Checkbox, Radio and Slider each draw their whole indicator with a
/// [CustomPainter] rather than a widget per part, so a glyph, a selection dot
/// or a rail fraction cannot be read off the widget tree at all — the painter's
/// own fields are the only honest answer to "what is on screen", and every one
/// of them is public for exactly this. Reads `painter` and not
/// `foregroundPainter`, which is where `FluentFocusRing` lives.
List<P> paintersOf<P extends CustomPainter>(
  WidgetTester tester, [
  Finder? within,
]) => tester
    .widgetList<CustomPaint>(
      within == null
          ? find.byType(CustomPaint)
          : find.descendant(of: within, matching: find.byType(CustomPaint)),
    )
    .map((CustomPaint paint) => paint.painter)
    .whereType<P>()
    .toList();

/// The [CustomPaint] a painter of type [P] is mounted on.
///
/// [paintersOf] answers what a plot drew; this answers *where*. A painted mark
/// — a donut arc, a gauge band, a funnel trapezium, a polar marker — carries
/// its geometry in the painter's own coordinates, which are measured from this
/// widget's top-left corner, so it is the only offset that turns a path bound
/// into a point [hoverAt] or [mouseClickAt] can be aimed at.
Finder plotOf<P extends CustomPainter>() => find.byWidgetPredicate(
  (Widget widget) => widget is CustomPaint && widget.painter is P,
);

/// The first *filled* [BoxDecoration] under [finder].
///
/// A Fluent surface is a `DecoratedBox`, but it is rarely the only one in a
/// component: seams, dividers and one-sided rules are drawn as border-only
/// decorations wrapped around the surface, and they come first in tree order.
/// Skipping the fill-less ones is what makes "did this knob repaint the
/// surface?" answerable without knowing which part of which component drew
/// what. Narrow [finder] to one widget — a fill from the wrong tag is worse
/// than none.
BoxDecoration? fillOf(WidgetTester tester, Finder finder) {
  for (final DecoratedBox box in tester.widgetList<DecoratedBox>(
    find.descendant(of: finder, matching: find.byType(DecoratedBox)),
  )) {
    final Decoration decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration;
    }
  }
  return null;
}

/// The sine of the angle the nearest [Transform] above [glyph] is turning it by.
///
/// Fluent's chevrons never swap their glyph — Accordion and Tree both rotate one
/// `chevron_right` icon rather than exchanging two — so the rotation is the only
/// place "this thing is open" reaches the paint, and the matrix's sin term
/// separates the three angles a chevron ever rests at (0, a quarter turn either
/// way) without a trigonometry import.
double chevronTurn(WidgetTester tester, Finder glyph) => tester
    .widget<Transform>(
      find.ancestor(of: glyph, matching: find.byType(Transform)).first,
    )
    .transform
    .storage[1];

/// Drops [slider]'s thumb at [fraction] of its rail, 0 being `min` and 1 `max`.
///
/// A tap on the rail is the gesture `FluentSlider` maps straight onto a value,
/// so this reaches both ends exactly rather than accumulating drag deltas that
/// snap to the nearest step and land somewhere approximate. Driving a slider to
/// its ends is the only way to prove a duration or a count knob moved anything.
Future<void> dropSliderAt(
  WidgetTester tester,
  Finder slider,
  double fraction,
) async {
  await tester.ensureVisible(slider.first);
  await settle(tester);
  final Rect rail = tester.getRect(slider.first);
  // Held half a pixel inside the box: a rect is exclusive at its right edge, so
  // `fraction: 1` lands on the first pixel that hit-tests to nothing and the tap
  // is silently swallowed. The rail clamps anything past its ends to `max`
  // anyway, so the inset costs no reach.
  await tester.tapAt(
    Offset(
      (rail.left + rail.width * fraction)
          .clamp(rail.left + 0.5, rail.right - 0.5)
          .toDouble(),
      rail.center.dy,
    ),
  );
  await settle(tester);
  expectClean(tester, 'moving ${slider.describeMatch(Plurality.one)}');
}

/// Types [text] into [field] and then drops focus.
///
/// Both `FluentDatePicker` and `FluentTimePicker` validate and commit on
/// **blur**, never per keystroke — that is a browser's `change` event, not its
/// `input` event — so a test that only calls `enterText` proves nothing about
/// what the field accepted.
Future<void> typeAndBlur(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field.first);
  await settle(tester);
  await tester.enterText(field.first, text);
  await settle(tester);
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
  expectClean(tester, 'typing "$text"');
}

/// Every canvas call the render object under [finder] makes, in paint order.
///
/// A chart draws its entire subject — bars, ticks, labels, lines — into a
/// single `CustomPaint`, so none of it exists in the widget tree: no finder can
/// see a bar and `textSnapshot` cannot see a tick label. The display list is
/// the only honest answer to "what did this knob change on screen", and it is
/// the same list the engine would have rasterised. Pair with [countOps] and
/// [opArgs].
List<RecordedInvocation> paintOps(WidgetTester tester, Finder finder) {
  final TestRecordingCanvas canvas = TestRecordingCanvas();
  tester
      .renderObject(finder.first)
      .paint(TestRecordingPaintingContext(canvas), Offset.zero);
  return canvas.invocations;
}

/// How many of [ops] are calls to [method] — `#drawRect`, `#drawParagraph`.
int countOps(List<RecordedInvocation> ops, Symbol method) => ops
    .where((RecordedInvocation op) => op.invocation.memberName == method)
    .length;

/// The [at]-th positional argument of every [method] call in [ops].
///
/// `opArgs<Rect>(ops, #drawRect)` is every bar a bar chart drew;
/// `opArgs<Paint>(ops, #drawRect, at: 1)` is the fill each was drawn with.
List<T> opArgs<T>(List<RecordedInvocation> ops, Symbol method, {int at = 0}) =>
    <T>[
      for (final RecordedInvocation op in ops)
        if (op.invocation.memberName == method)
          op.invocation.positionalArguments[at] as T,
    ];

/// The rects a chart painted as *marks*, each with the fill it took.
///
/// Every bar chart draws its bars with `Canvas.drawRect` — and so does one
/// piece of chrome: `FluentChartTitlePainter` backs an axis title with a rect.
/// That one is drawn around the origin of a canvas already translated to the
/// title's anchor, so it is the only rect in the list that starts at a negative
/// x, while a mark always sits inside the plot. Separating them on that keeps
/// "how many bars are there" from silently counting two axis titles.
List<({Rect rect, Paint paint})> paintedRects(List<RecordedInvocation> ops) =>
    <({Rect rect, Paint paint})>[
      for (final RecordedInvocation op in ops)
        if (op.invocation.memberName == #drawRect &&
            (op.invocation.positionalArguments[0] as Rect).left >= 0)
          (
            rect: op.invocation.positionalArguments[0] as Rect,
            paint: op.invocation.positionalArguments[1] as Paint,
          ),
    ];

/// Types [text] into the spin button [finder] and commits it.
///
/// `FluentSpinButton` reports through `onChanged` on the editing action, never
/// per keystroke, so `enterText` alone leaves the demo holding its old number
/// and proves nothing about what the field accepted.
Future<void> typeAndCommit(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.ensureVisible(finder.first);
  await settle(tester);
  await tester.enterText(finder.first, text);
  await settle(tester);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settle(tester);
  expectClean(tester, 'committing "$text"');
}

/// Unmounts the tree and asserts nothing threw on the way out.
///
/// Disposal is where the library's lifecycle bugs live — a controller built in
/// `dispose`, a timer that outlives its widget — and they only surface here.
Future<void> expectCleanTeardown(WidgetTester tester, String what) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  expectClean(tester, 'unmounting $what');
}

/// Whether the node holding the primary focus lives inside [finder]'s subtree.
///
/// Deliberately not "is the focused node an ancestor of this widget": the root
/// [FocusScopeNode] is an ancestor of everything, and it is what holds focus
/// when *nothing* does — so that question answers yes on a tree where focus was
/// never moved at all, and every autofocus assertion written that way passes
/// for the wrong reason.
bool focusIsInside(WidgetTester tester, Finder finder) {
  final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  return find
      .descendant(of: finder, matching: find.byWidget(focused.widget))
      .evaluate()
      .isNotEmpty;
}

/// Whether the node holding the primary focus *encloses* [finder].
///
/// The other direction, and the one a focus trap needs: an overlay surface
/// takes focus on its own `FocusScope` rather than on anything inside it, so
/// "focus is on a node that contains this button" is what "Tab cannot leave the
/// surface" actually looks like. Pair it with a negative — the scope that
/// encloses the surface must *not* enclose the trigger — or the root scope,
/// which encloses everything, satisfies it too.
bool focusEncloses(WidgetTester tester, Finder finder) {
  final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  return find
      .descendant(of: find.byWidget(focused.widget), matching: finder)
      .evaluate()
      .isNotEmpty;
}

/// Moves the keyboard focus onto [finder].
///
/// A press does not move focus in this package — `FluentInteractive` never asks
/// for it — so after a synthetic tap the root scope still holds focus and an
/// `Actions` bound around a trigger is unreachable: `DismissIntent` is
/// dispatched from the focused node outwards. A keyboard user arrives at that
/// trigger by tabbing to it, and this is that state, restored explicitly so a
/// test about Escape is testing Escape rather than testing what a tap happens
/// to focus.
Future<void> focusOn(WidgetTester tester, Finder finder) async {
  final Iterable<Focus> nodes = tester.widgetList<Focus>(
    find.descendant(of: finder.first, matching: find.byType(Focus)),
  );
  final FocusNode? node = nodes
      .map((Focus focus) => focus.focusNode)
      .whereType<FocusNode>()
      .firstOrNull;
  expect(
    node,
    isNotNull,
    reason: 'nothing focusable under ${finder.describeMatch(Plurality.one)}',
  );
  node!.requestFocus();
  await settle(tester);
}

/// Mounts a whole *page*, the way `DocsScaffold` mounts one that has no
/// sections.
///
/// The seven Theme pages and the two Concepts pages declare `sections: []` —
/// upstream writes them as token tables and prose rather than as a list of
/// demos — so [pumpSection] has nothing to take, and [sectionsOf] returns an
/// empty list a `for` loop silently skips. What the scaffold renders for them
/// is `page.body`, or a [MarkdownBody] over `page.markdown` with the leading
/// `#` heading dropped because the scaffold has already drawn the title. This
/// mounts exactly that, so a suite measures the page a reader sees rather than
/// a second rendering of the same tokens.
///
/// [width] is the content column and not the viewport. The scaffold caps a
/// section-less page at [DocsMetrics.contentMaxWidth] and every one of these
/// tables lays its columns out against that width, so measuring one at the full
/// 1600 would prove a geometry the app never shows.
Future<void> pumpPageBody(
  WidgetTester tester,
  String pageId, {
  Size size = const Size(1600, 1400),
  double width = DocsMetrics.contentMaxWidth,
}) async {
  final DocsPage? page = pageById(pageId);
  if (page == null) fail('no page "$pageId" in the catalog');
  final String? markdown = page.markdown;
  final WidgetBuilder? body = page.body;
  if (markdown == null && body == null) {
    fail('page "$pageId" carries neither a body nor markdown');
  }

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    FluentApp(
      debugShowCheckedModeBanner: false,
      home: SingleChildScrollView(
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: width,
            child: markdown != null
                ? MarkdownBody(source: markdown, skipLeadingHeading: true)
                : Builder(builder: body!),
          ),
        ),
      ),
    ),
  );
  await settle(tester);
  expectClean(tester, 'mounting $pageId');
}

/// Every inline run inside [finder]'s paragraph whose style [test] accepts.
///
/// A markdown document's bold, code and link runs are spans inside one
/// `Text.rich`, not widgets, so no finder can reach them and [textStyleOf]
/// answers only for the paragraph's base style — it says nothing about the four
/// words inside it that are supposed to be monospace. Walking the span tree is
/// the only way to assert both what was styled and, by returning the runs
/// themselves rather than a bool, what was *not*.
List<TextSpan> inlineRuns(
  WidgetTester tester,
  Finder finder,
  bool Function(TextStyle style) test,
) {
  final List<TextSpan> found = <TextSpan>[];
  // `visitChildren` already recurses, and skips the root when it carries no
  // text of its own — which is exactly the shape `Text.rich` builds.
  tester.renderObject<RenderParagraph>(finder.first).text.visitChildren((
    InlineSpan span,
  ) {
    if (span is TextSpan &&
        (span.text ?? '').isNotEmpty &&
        span.style != null &&
        test(span.style!)) {
      found.add(span);
    }
    return true;
  });
  return found;
}
