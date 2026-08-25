/// Asserts computed chart geometry against the geometry the live
/// `@fluentui/react-charts` implementation renders.
///
/// ## Why numbers and not pixels
///
/// Charts have no Figma source, so `test/support/spec_fixture.dart` has nothing
/// to read for them (design spec §4.1). Oracle B replaces it: the storybook
/// stories are rendered headlessly and every SVG element's geometry and
/// resolved paint is dumped to `test/fixtures/charts/oracle_b/<story-id>.json`.
/// The comparison is numeric for the same reasons a golden image is not
/// trusted for fidelity — the capture browser resolves different fonts than
/// `flutter test` does, and Skia's antialiasing does not match Chromium's, so a
/// pixel diff would fail on machines that are perfectly correct.
///
/// ## Using it
///
/// ```dart
/// final story = loadOracleStory('charts-areachart--area-chart-basic');
/// final domain = story.soleElement('path', where: (e) => e.parent == 0);
/// expectOracleSvgPath('x-axis domain', domain.d!, myGeometry.domainPath);
/// ```
///
/// Fixtures are captured by `crawlers/storybooks-fluentui/capture_oracle.mjs`;
/// the shape is documented in `test/fixtures/charts/oracle_b/README.md`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tolerance, in logical pixels, for a value the capture read from an SVG
/// **attribute** — `d`, `transform`, `x`, `y`, `width`, `height`, `cx`, `cy`,
/// `r`, `x1`, `y1`, `x2`, `y2`.
///
/// Those are the strings d3 serialised, so they carry authored double
/// precision and the only noise is decimal serialisation. 0.01 is roughly 150
/// float32 ulps at a coordinate of 700, and — the reason it is not larger — it
/// is fifty times smaller than the 0.5px crispness offset of design spec §5.5,
/// so a port that omits or halves that offset still fails.
const double kOracleGeometryTolerance = 0.01;

/// Tolerance, in logical pixels, for a value the browser's renderer measured:
/// [OracleElement.ctm] and [OracleElement.bbox].
///
/// Those come back as float32. Measured: `transform="translate(128.3,0)"`
/// returns `e = 128.300003` from `getCTM()`. Prefer
/// [OracleStory.absoluteTranslate], which composes the exact attribute
/// strings, over comparing a CTM at this tolerance.
const double kOracleMeasuredTolerance = 0.5;

/// The crispness offset both sides sit on.
///
/// `d3-axis` uses `window.devicePixelRatio > 1 ? 0 : 0.5`
/// (`d3-axis/src/axis.js:38`); the corpus is captured at `deviceScaleFactor: 1`
/// and `flutter test` runs at DPR 1, so both are 0.5 (design spec §5.5). Read
/// [OracleStory.crispOffset] in a consuming test rather than this constant —
/// the fixture is the authority, and this is only what it is asserted to be.
const double kOracleCrispOffset = 0.5;

const String _relative = 'test/fixtures/charts/oracle_b';

OracleManifest? _manifestCache;
final Map<String, OracleStory> _storyCache = <String, OracleStory>{};

/// The corpus directory, resolved by walking up from [Directory.current] until
/// one containing `_manifest.json` is found — so this works whether
/// `flutter test` was started from the package root or from a subdirectory of
/// it, exactly as `loadSpec` in `test/support/spec_fixture.dart` does.
Directory _corpusDirectory() {
  var directory = Directory.current;
  while (true) {
    final candidate = Directory('${directory.path}/$_relative');
    if (File('${candidate.path}/_manifest.json').existsSync()) {
      return candidate;
    }
    final parent = directory.parent;
    // Reaching the filesystem root leaves parent == directory.
    if (parent.path == directory.path) {
      break;
    }
    directory = parent;
  }
  throw StateError(
    'No $_relative/_manifest.json found in ${Directory.current.path} or any '
    'ancestor. Capture the corpus with '
    '`cd crawlers/storybooks-fluentui && node capture_oracle.mjs` — see '
    '$_relative/README.md.',
  );
}

/// Reads `_manifest.json`: the capture conditions, the coverage counts and the
/// skip register. Cached, because every consuming test file reads it.
OracleManifest loadOracleManifest() => _manifestCache ??= OracleManifest._(
  _obj(
    jsonDecode(
      File('${_corpusDirectory().path}/_manifest.json').readAsStringSync(),
    ),
  ),
);

/// Every captured story id, sorted, optionally narrowed to one [component]
/// (`AreaChart`, `LineChart`, …).
///
/// Enumerated from disk. Never construct a story id: upstream uses five
/// different naming conventions, and a constructed id yields an empty capture
/// that reads as a passing test (design spec §4.3).
List<String> oracleStoryIds({String? component}) {
  final ids =
      _corpusDirectory()
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('.json') && !name.startsWith('_'))
          .map((name) => name.substring(0, name.length - '.json'.length))
          .toList()
        ..sort();
  if (component == null) {
    return List<String>.unmodifiable(ids);
  }
  return List<String>.unmodifiable(
    ids.where((id) => loadOracleStory(id).component == component),
  );
}

/// Reads `test/fixtures/charts/oracle_b/<storyId>.json`.
///
/// Throws a [StateError] naming the capture command when the fixture is
/// absent, and [oracleSkippedStoryError] — a different one, naming the
/// recorded reason — when the story is in the skip register. A story that
/// failed to render must never be read as "nothing to check here".
OracleStory loadOracleStory(String storyId) {
  final cached = _storyCache[storyId];
  if (cached != null) {
    return cached;
  }
  final file = File('${_corpusDirectory().path}/$storyId.json');
  if (!file.existsSync()) {
    final reason = loadOracleManifest().skipReasonFor(storyId);
    if (reason != null) {
      throw oracleSkippedStoryError(storyId, reason);
    }
    throw StateError(
      'No Oracle B fixture for $storyId. Story ids are enumerated with '
      'oracleStoryIds(); never construct one, because upstream uses five '
      'naming conventions and a constructed id captures nothing (design spec '
      '§4.3). Re-capture with '
      '`cd crawlers/storybooks-fluentui && node capture_oracle.mjs`.',
    );
  }
  final story = OracleStory._(_obj(jsonDecode(file.readAsStringSync())));
  _storyCache[storyId] = story;
  return story;
}

/// The error [loadOracleStory] throws for a story that is in the skip register.
///
/// Public so it can be asserted directly: while the register is empty — as it
/// is for all 90 captured stories — no call to [loadOracleStory] can reach this
/// branch, and a conditional assertion over an empty register is a vacuous
/// pass. Its wording must stay distinct from the missing-fixture message above,
/// or "no fixture" reads as "nothing to check".
StateError oracleSkippedStoryError(String storyId, String reason) => StateError(
  'The story $storyId is in the Oracle B skip register: $reason. It rendered '
  'nothing capturable, so there is no geometry to assert against. Fix the '
  'capture or assert against a different story — do not skip the check '
  'silently.',
);

/// The corpus-wide record: what was captured, under what conditions, and what
/// was not.
@immutable
class OracleManifest {
  OracleManifest._(Map<String, dynamic> json)
    : upstreamVersion = _str(json['upstreamVersion']),
      deviceScaleFactor = _dbl(json['deviceScaleFactor']).toInt(),
      crispOffset = _dbl(json['crispOffset']),
      indexEntries = _dbl(json['indexEntries']).toInt(),
      storyCount = _dbl(json['storyCount']).toInt(),
      capturedCount = _dbl(json['capturedCount']).toInt(),
      storiesPerComponent = _counts(json['storiesPerComponent']),
      capturedPerComponent = _counts(json['capturedPerComponent']),
      thinComponents = List<String>.unmodifiable(
        _list(json['thinComponents']).map(_str),
      ),
      skipped = List<OracleSkip>.unmodifiable(
        _list(json['skipped']).map((row) => OracleSkip._(_obj(row))),
      );

  /// The `@fluentui/react-charts` version the corpus describes, `9.3.23`.
  final String upstreamVersion;

  /// The Chromium device scale factor the capture ran at. Always 1, which is
  /// what pins [crispOffset] to 0.5 (design spec §5.5).
  final int deviceScaleFactor;

  /// The `d3-axis` crispness offset implied by [deviceScaleFactor].
  final double crispOffset;

  /// Entries in upstream's `index.json` — 111 when the corpus was captured, of
  /// which 21 are documentation pages rather than stories (design spec §4.3).
  final int indexEntries;

  /// Entries of `type: "story"` — 90 when the corpus was captured.
  final int storyCount;

  /// Stories that produced a fixture. `storyCount - skipped.length`.
  final int capturedCount;

  /// Stories upstream has, per component.
  final Map<String, int> storiesPerComponent;

  /// Stories captured, per component. Zero for any component means the corpus
  /// verifies nothing about that chart.
  final Map<String, int> capturedPerComponent;

  /// Components with fewer than three stories upstream, sorted. Their geometry
  /// leans on Oracle A and hand-derivation, and a reviewer must say so rather
  /// than letting a low count pass silently (design spec §4.3).
  final List<String> thinComponents;

  /// Stories that failed to render, each with the reason recorded. Never
  /// empty-but-unexplained: a partial fixture is never written.
  final List<OracleSkip> skipped;

  /// Why [storyId] has no fixture, or null if it was never skipped.
  String? skipReasonFor(String storyId) {
    for (final entry in skipped) {
      if (entry.id == storyId) {
        return entry.reason;
      }
    }
    return null;
  }
}

/// One story the capture could not use, and why.
@immutable
class OracleSkip {
  OracleSkip._(Map<String, dynamic> json)
    : id = _str(json['id']),
      reason = _str(json['reason']);

  /// The story id, as enumerated from `index.json`.
  final String id;

  /// What went wrong — a Storybook error message, an empty root, or no chart
  /// svg on the page.
  final String reason;

  @override
  String toString() => 'OracleSkip($id: $reason)';
}

/// One captured story: every svg it rendered, and the HTML boxes of its legend.
@immutable
class OracleStory {
  OracleStory._(Map<String, dynamic> json)
    : id = _str(json['id']),
      component = _str(json['component']),
      name = _str(json['name']),
      title = _str(json['title']),
      upstreamVersion = _str(json['upstreamVersion']),
      deviceScaleFactor = _dbl(json['deviceScaleFactor']).toInt(),
      crispOffset = _dbl(json['crispOffset']),
      width = _dbl(json['width']),
      height = _dbl(json['height']),
      svgs = List<OracleSvg>.unmodifiable(
        _list(json['svgs']).map((row) => OracleSvg._(_obj(row))),
      ),
      htmlBoxes = List<OracleHtmlBox>.unmodifiable(
        _list(json['htmlBoxes']).map((row) => OracleHtmlBox._(_obj(row))),
      );

  /// The Storybook story id, e.g. `charts-areachart--area-chart-basic`.
  final String id;

  /// The component the story belongs to, e.g. `AreaChart`.
  final String component;

  /// The exported story name, e.g. `AreaChartBasic`.
  final String name;

  /// The Storybook title, e.g. `Charts/AreaChart`.
  final String title;

  /// The upstream version this story was captured from.
  final String upstreamVersion;

  /// The Chromium device scale factor, always 1.
  final int deviceScaleFactor;

  /// The `d3-axis` crispness offset in force, always [kOracleCrispOffset].
  ///
  /// Read this, not the constant: it is what the capture actually ran with, so
  /// a re-capture at a different DPR changes every consuming test's expectation
  /// in one place.
  final double crispOffset;

  /// The [primary] svg's CSS width, or — for an HTML-only story, where [svgs]
  /// is empty — the widest box in [htmlBoxes]. Mount the Flutter chart in a
  /// `SizedBox` of [width] × [height] to compare geometry against this story.
  final double width;

  /// The [primary] svg's CSS height, or the widest [htmlBoxes] entry's height
  /// when [svgs] is empty. See [width].
  final double height;

  /// Every captured svg, widest first.
  ///
  /// **Empty for an HTML-only story.** Three of the five Legends stories draw
  /// their swatches as `fui-legend__rect` divs and render no svg at all, so
  /// their whole geometry is in [htmlBoxes]; reach it through [boxes], and
  /// never through [primary]. Use [hasSvg] to branch.
  final List<OracleSvg> svgs;

  /// Bounding boxes of the `fui-legend*` and `fui-*chart*` HTML elements.
  ///
  /// Upstream draws the legend in HTML apart from its shape svg
  /// (`Legends.tsx:113-163` renders the whole legend as `div`s), so an SVG-only
  /// capture would verify none of it.
  final List<OracleHtmlBox> htmlBoxes;

  /// Whether this story rendered any svg at all.
  ///
  /// False for an HTML-only story — see [svgs]. Everything such a story
  /// measured is in [htmlBoxes], reachable through [boxes] without touching
  /// [primary].
  bool get hasSvg => svgs.isNotEmpty;

  /// The widest captured svg — the chart itself. A legend-shape svg, if any,
  /// follows it in [svgs].
  ///
  /// Throws a [StateError] naming the HTML-only case when [hasSvg] is false,
  /// rather than returning an empty svg: `byTag('rect')` on a synthesised
  /// empty svg would come back empty and a test asserting a rect count would
  /// pass having measured nothing.
  OracleSvg get primary {
    if (svgs.isEmpty) {
      throw StateError(
        '$id captured no svg: it is an HTML-only story, which upstream renders '
        'as `fui-legend__rect` divs (three of the five Legends stories do). '
        'Its geometry is in htmlBoxes — read it with boxes("fui-legend"), and '
        'branch on hasSvg rather than on a try/catch.',
      );
    }
    return svgs.first;
  }

  /// [primary]'s elements, in document order.
  List<OracleElement> get elements => primary.elements;

  /// Every element of [primary] with the given SVG tag, e.g. `path`, `rect`,
  /// `circle`, `line`, `text`, `g`.
  List<OracleElement> byTag(String tag) => List<OracleElement>.unmodifiable(
    elements.where((element) => element.tag == tag),
  );

  /// The single element of [primary] matching [tag] and [where].
  ///
  /// Throws rather than guessing: with 128 elements in one chart, silently
  /// taking the first would mean asserting against a shape nobody chose.
  OracleElement soleElement(String tag, {bool Function(OracleElement)? where}) {
    final matches = byTag(
      tag,
    ).where((element) => where == null || where(element)).toList();
    if (matches.length == 1) {
      return matches.single;
    }
    throw StateError(
      '$id has ${matches.length} <$tag> elements matching the predicate, not '
      'one. Narrow it, or use byTag("$tag") and pick deliberately.',
    );
  }

  /// The element [element] is nested inside, or null when it is a direct child
  /// of the svg.
  OracleElement? parentOf(OracleElement element) =>
      element.parent < 0 ? null : elements[element.parent];

  /// The elements nested directly inside [element], in document order.
  List<OracleElement> childrenOf(OracleElement element) =>
      List<OracleElement>.unmodifiable(
        elements.where((child) => child.parent == element.index),
      );

  /// [element]'s position in the svg's own coordinate space, composed from the
  /// exact `transform` **attribute strings** of it and every ancestor.
  ///
  /// Not read from [OracleElement.ctm], which the browser returns as float32.
  /// Throws when any transform in the chain is not a pure `translate`, so a
  /// rotated tick label cannot be compared as though it were unrotated.
  Offset absoluteTranslate(OracleElement element) {
    var offset = Offset.zero;
    OracleElement? current = element;
    while (current != null) {
      final transform = current.transform;
      if (transform != null) {
        final translate = current.translate;
        if (translate == null) {
          throw StateError(
            '$id: <${current.tag}> #${current.index} carries '
            'transform="$transform", which is not a pure translate, so an '
            'absolute offset would be wrong. Compare the transform itself.',
          );
        }
        offset += translate;
      }
      current = parentOf(current);
    }
    return offset;
  }

  /// Every HTML box whose slot starts with [slotPrefix], e.g. `fui-legend`.
  List<OracleHtmlBox> boxes(String slotPrefix) =>
      List<OracleHtmlBox>.unmodifiable(
        htmlBoxes.where((box) => box.slot.startsWith(slotPrefix)),
      );

  @override
  String toString() => 'OracleStory($id)';
}

/// One captured `<svg>`.
@immutable
class OracleSvg {
  OracleSvg._(Map<String, dynamic> json)
    : width = _dbl(json['width']),
      height = _dbl(json['height']),
      viewBox = json['viewBox'] == null ? null : _str(json['viewBox']),
      slot = json['slot'] == null ? null : _str(json['slot']),
      fontFamilies = List<String>.unmodifiable(
        _list(json['fontFamilies']).map(_str),
      ),
      elements = List<OracleElement>.unmodifiable(
        _list(json['elements']).map((row) => OracleElement._(_obj(row))),
      ),
      gradients = List<OracleGradient>.unmodifiable(
        _list(json['gradients']).map((row) => OracleGradient._(_obj(row))),
      );

  /// The svg's CSS box width.
  final double width;

  /// The svg's CSS box height.
  final double height;

  /// The `viewBox` attribute, or null — upstream sets one only on Sparkline.
  final String? viewBox;

  /// The `fui-` class token on the svg, e.g. `fui-cart__chart` — upstream's own
  /// typo, which 59 of the corpus's svgs carry.
  ///
  /// Null for 25 of the 135 captured svgs, all of them ChartTable's and
  /// Sparkline's, which upstream leaves unclassed. Do not select on the slot
  /// for those two.
  final String? slot;

  /// The distinct resolved font stacks of this svg's `<text>` nodes.
  ///
  /// Recorded once rather than per element, and never asserted: the harness
  /// compares text metrics, not glyphs (`test/fixtures/README.md`).
  final List<String> fontFamilies;

  /// Every element under the svg, in document order, gradients excluded.
  final List<OracleElement> elements;

  /// Every `linearGradient` in the svg's `defs`, with its stops.
  final List<OracleGradient> gradients;

  /// The gradient [OracleElement.fillRef] or [OracleElement.strokeRef] names,
  /// or null when the reference is to a def the capture does not record — a
  /// `<pattern>`, for instance.
  OracleGradient? gradient(String id) {
    for (final gradient in gradients) {
      if (gradient.id == id) {
        return gradient;
      }
    }
    return null;
  }
}

/// One captured SVG element: its geometry, its transform and its resolved
/// paint.
@immutable
class OracleElement {
  OracleElement._(Map<String, dynamic> json)
    : tag = _str(json['tag']),
      index = _dbl(json['index']).toInt(),
      parent = _dbl(json['parent']).toInt(),
      transform = json['transform'] == null ? null : _str(json['transform']),
      translate = _translate(json['transform']),
      ctm = json['ctm'] == null
          ? null
          : List<double>.unmodifiable(_list(json['ctm']).map(_dbl)),
      bbox = json['bbox'] == null ? null : _rect(_list(json['bbox'])),
      d = json['d'] == null ? null : _str(json['d']),
      points = json['points'] == null ? null : _str(json['points']),
      text = json['text'] == null ? null : _str(json['text']),
      x = _optDbl(json['x']),
      y = _optDbl(json['y']),
      width = _optDbl(json['width']),
      height = _optDbl(json['height']),
      cx = _optDbl(json['cx']),
      cy = _optDbl(json['cy']),
      r = _optDbl(json['r']),
      x1 = _optDbl(json['x1']),
      y1 = _optDbl(json['y1']),
      x2 = _optDbl(json['x2']),
      y2 = _optDbl(json['y2']),
      fill = _paint(json['fill']),
      stroke = _paint(json['stroke']),
      fillRef = _paintRef(json['fill']),
      strokeRef = _paintRef(json['stroke']),
      fillOpacity = _cssNumber(json['fillOpacity'], 1),
      strokeOpacity = _cssNumber(json['strokeOpacity'], 1),
      opacity = _cssNumber(json['opacity'], 1),
      strokeWidth = _cssNumber(json['strokeWidth'], 1),
      fontSize = _cssNumber(json['fontSize'], 0),
      fontWeight = json['fontWeight'] == null
          ? '400'
          : _str(json['fontWeight']),
      textAnchor = json['textAnchor'] == null
          ? 'start'
          : _str(json['textAnchor']),
      dominantBaseline = json['dominantBaseline'] == null
          ? 'auto'
          : _str(json['dominantBaseline']),
      strokeDasharray = json['strokeDasharray'] == null
          ? 'none'
          : _str(json['strokeDasharray']),
      strokeLinecap = json['strokeLinecap'] == null
          ? 'butt'
          : _str(json['strokeLinecap']);

  /// The SVG tag name, e.g. `path`, `rect`, `g`, `text`.
  final String tag;

  /// This element's position in its svg's `elements` list.
  final int index;

  /// The [index] of the element this one is nested in, or -1 for a direct child
  /// of the svg.
  final int parent;

  /// The raw `transform` attribute, or null.
  final String? transform;

  /// [transform] parsed, when it is a pure `translate`. Null when the element
  /// has no transform **or** when it carries a rotate, scale, matrix or a
  /// compound list — so a consumer that needs the offset must handle the
  /// rotated case explicitly. 37 rotates and 4 `translate(…)rotate(…)`
  /// compounds are in the corpus, all of them axis titles and rotated x labels.
  final Offset? translate;

  /// The matrix `getCTM()` returned, `[a, b, c, d, e, f]`, or null.
  ///
  /// Renderer-measured and therefore float32: compare at
  /// [kOracleMeasuredTolerance], or prefer [OracleStory.absoluteTranslate].
  final List<double>? ctm;

  /// The box `getBBox()` returned, or null.
  ///
  /// Advisory only for `<text>`: a glyph box depends on the fonts the capture
  /// browser resolved, so it is a property of the capture machine rather than
  /// of upstream's geometry.
  final Rect? bbox;

  /// The `d` attribute of a `path`, or null. Compare with
  /// [expectOracleSvgPath], never as a string.
  final String? d;

  /// The `points` attribute of a `polygon` or `polyline`, or null.
  final String? points;

  /// The text content of a `text`, `tspan` or `title`, or null.
  final String? text;

  /// The `x` attribute, or null when the element has none.
  final double? x;

  /// The `y` attribute, or null.
  final double? y;

  /// The `width` attribute, or null.
  final double? width;

  /// The `height` attribute, or null.
  final double? height;

  /// The `cx` attribute of a `circle`, or null.
  final double? cx;

  /// The `cy` attribute of a `circle`, or null.
  final double? cy;

  /// The `r` attribute of a `circle`, or null.
  final double? r;

  /// The `x1` attribute of a `line`, or null.
  final double? x1;

  /// The `y1` attribute of a `line`, or null.
  final double? y1;

  /// The `x2` attribute of a `line`, or null.
  final double? x2;

  /// The `y2` attribute of a `line`, or null.
  final double? y2;

  /// The resolved `fill`, or null for `fill: none` **and** for a `url(#…)`
  /// reference, whose target is in [fillRef].
  ///
  /// Null is an absence, not a transparent colour — the distinction matters in
  /// high contrast, where a Fluent transparent token becomes opaque.
  final Color? fill;

  /// The resolved `stroke`, or null for `stroke: none` and for a `url(#…)`
  /// reference, whose target is in [strokeRef].
  final Color? stroke;

  /// The id `fill: url(#…)` points at, or null when the fill is a colour or
  /// absent.
  ///
  /// Resolve it through [OracleSvg.gradient]; a null result there means the
  /// reference is to a def the capture does not record. Two rects of
  /// `charts-linechart--line-chart-multiple` and two of
  /// `charts-linechart--line-chart-custom-accessibility` reference
  /// `colorFillBarPattern_r_6__1`, a `<pattern>` rather than a gradient, and
  /// recording the id is what stops that being read as a plain colour.
  final String? fillRef;

  /// The id `stroke: url(#…)` points at, or null. See [fillRef].
  final String? strokeRef;

  /// The resolved `fill-opacity`, defaulting to 1.
  final double fillOpacity;

  /// The resolved `stroke-opacity`, defaulting to 1.
  final double strokeOpacity;

  /// The resolved element `opacity`, defaulting to 1. Not inherited: a `g` at
  /// 0.2 and its children at 1 is what upstream's grid lines look like.
  final double opacity;

  /// The resolved `stroke-width` in logical pixels, unit stripped.
  final double strokeWidth;

  /// The resolved `font-size` in logical pixels, unit stripped. 0 when the
  /// element records none.
  final double fontSize;

  /// The resolved `font-weight` as CSS states it, e.g. `600`.
  final String fontWeight;

  /// The resolved `text-anchor`: `start`, `middle` or `end`.
  final String textAnchor;

  /// The resolved `dominant-baseline`.
  final String dominantBaseline;

  /// The resolved `stroke-dasharray`, or `none`.
  final String strokeDasharray;

  /// The resolved `stroke-linecap`.
  final String strokeLinecap;

  /// [x], [y], [width] and [height] as a [Rect].
  ///
  /// Throws when any of the four is absent: a rect with three of them is a
  /// misread element, not a rect at the origin.
  Rect get rect {
    final left = x;
    final top = y;
    final w = width;
    final h = height;
    if (left == null || top == null || w == null || h == null) {
      throw StateError(
        '<$tag> #$index does not carry all four of x, y, width and height.',
      );
    }
    return Rect.fromLTWH(left, top, w, h);
  }

  /// [cx] and [cy] as an [Offset]. Throws when the element is not a circle.
  Offset get centre {
    final centreX = cx;
    final centreY = cy;
    if (centreX == null || centreY == null) {
      throw StateError('<$tag> #$index carries no cx/cy.');
    }
    return Offset(centreX, centreY);
  }

  /// [x1] and [y1] as an [Offset]. Absent endpoints are 0, as SVG defines.
  Offset get start => Offset(x1 ?? 0, y1 ?? 0);

  /// [x2] and [y2] as an [Offset]. Absent endpoints are 0, as SVG defines.
  Offset get end => Offset(x2 ?? 0, y2 ?? 0);

  /// [fill] with [fillOpacity] and [opacity] folded into its alpha — the
  /// colour that actually reached the pixel.
  Color? get effectiveFill =>
      fill == null ? null : _scaleAlpha(fill!, fillOpacity * opacity);

  /// [stroke] with [strokeOpacity] and [opacity] folded into its alpha.
  Color? get effectiveStroke =>
      stroke == null ? null : _scaleAlpha(stroke!, strokeOpacity * opacity);

  @override
  String toString() => '<$tag> #$index';
}

/// One `linearGradient` def.
@immutable
class OracleGradient {
  OracleGradient._(Map<String, dynamic> json)
    : id = _str(json['id']),
      units = json['units'] == null ? null : _str(json['units']),
      x1 = _optDbl(json['x1']),
      y1 = _optDbl(json['y1']),
      x2 = _optDbl(json['x2']),
      y2 = _optDbl(json['y2']),
      stops = List<OracleGradientStop>.unmodifiable(
        _list(json['stops']).map((row) => OracleGradientStop._(_obj(row))),
      );

  /// The `id` the paint refers to, e.g. `gradient-link_r_1_-0`.
  final String id;

  /// The `gradientUnits` attribute, or null for the SVG default
  /// (`objectBoundingBox`).
  final String? units;

  /// The gradient vector's start x.
  final double? x1;

  /// The gradient vector's start y.
  final double? y1;

  /// The gradient vector's end x.
  final double? x2;

  /// The gradient vector's end y.
  final double? y2;

  /// The stops, in document order.
  final List<OracleGradientStop> stops;

  @override
  String toString() => 'OracleGradient($id)';
}

/// One `stop` of an [OracleGradient].
@immutable
class OracleGradientStop {
  OracleGradientStop._(Map<String, dynamic> json)
    : offset = _dbl(json['offset']),
      color = _paint(json['color']) ?? const Color(0x00000000),
      opacity = _cssNumber(json['opacity'], 1);

  /// The `offset` attribute as authored. Upstream's sankey gradients use
  /// `0`/`100`, not `0`/`1`: `SankeyChart.tsx:755-756` authors `offset="0"` and
  /// `offset="100%"`, so this is not normalised.
  final double offset;

  /// The resolved `stop-color`.
  final Color color;

  /// The resolved `stop-opacity`.
  final double opacity;
}

/// One HTML element of the chart's chrome, with the box it occupied relative to
/// `#storybook-root`.
@immutable
class OracleHtmlBox {
  OracleHtmlBox._(Map<String, dynamic> json)
    : slot = _str(json['slot']),
      tag = _str(json['tag']),
      rect = _rect(_list(json['rect'])),
      text = json['text'] == null ? null : _str(json['text']),
      color = _paint(json['color']),
      backgroundColor = _paint(json['backgroundColor']),
      fontFamily = _str(json['fontFamily']),
      fontSize = _cssNumber(json['fontSize'], 0),
      fontWeight = _str(json['fontWeight']),
      forcedColorAdjust = _str(json['forcedColorAdjust']);

  /// The Fluent slot class, e.g. `fui-legend__text`.
  final String slot;

  /// The HTML tag, lower case.
  final String tag;

  /// The element's box relative to `#storybook-root`.
  ///
  /// Advisory for text-bearing slots: a label's width depends on the fonts the
  /// capture browser resolved. Assert layout that d3 or CSS computed from
  /// numbers, not a measured glyph run.
  final Rect rect;

  /// The text content, when the element has no element children.
  final String? text;

  /// The resolved `color`.
  final Color? color;

  /// The resolved `background-color`. `rgba(0, 0, 0, 0)` is a real fully
  /// transparent black here, not an absence — only `none` and `transparent`
  /// come back null.
  final Color? backgroundColor;

  /// The resolved font stack. Recorded, never asserted.
  final String fontFamily;

  /// The resolved `font-size` in logical pixels.
  final double fontSize;

  /// The resolved `font-weight`.
  final String fontWeight;

  /// The resolved `forced-color-adjust`.
  ///
  /// `auto` on every box in the corpus, all 902 of them. Upstream opts out of
  /// high-contrast flattening deliberately (design spec §5.3) but does so
  /// inside a `HighContrastSelector` block —
  /// `Legends/useLegendsStyles.styles.ts:60-62` and `:69-71` — and the capture
  /// did not run under forced colours. So this records what normal mode
  /// resolves, and the opt-out itself is not verifiable from this corpus.
  final String forcedColorAdjust;

  @override
  String toString() => 'OracleHtmlBox($slot)';
}

/// Fails naming [what] when [actual] differs from [expected] by more than
/// [tolerance].
void expectOracleNumber(
  String what,
  double expected,
  double actual, {
  double tolerance = kOracleGeometryTolerance,
}) {
  if ((expected - actual).abs() <= tolerance) {
    return;
  }
  fail(
    '$what: expected ${_format(expected)}, got ${_format(actual)} '
    '(tolerance ${_format(tolerance)})',
  );
}

/// [expectOracleNumber] on both axes of an [Offset].
void expectOracleOffset(
  String what,
  Offset expected,
  Offset actual, {
  double tolerance = kOracleGeometryTolerance,
}) {
  expectOracleNumber('$what.dx', expected.dx, actual.dx, tolerance: tolerance);
  expectOracleNumber('$what.dy', expected.dy, actual.dy, tolerance: tolerance);
}

/// [expectOracleNumber] on all four edges of a [Rect].
void expectOracleRect(
  String what,
  Rect expected,
  Rect actual, {
  double tolerance = kOracleGeometryTolerance,
}) {
  expectOracleNumber(
    '$what.left',
    expected.left,
    actual.left,
    tolerance: tolerance,
  );
  expectOracleNumber(
    '$what.top',
    expected.top,
    actual.top,
    tolerance: tolerance,
  );
  expectOracleNumber(
    '$what.width',
    expected.width,
    actual.width,
    tolerance: tolerance,
  );
  expectOracleNumber(
    '$what.height',
    expected.height,
    actual.height,
    tolerance: tolerance,
  );
}

/// Compares two colours as ARGB, printing both in hex on failure.
///
/// Null is a legitimate expectation: `fill: none` is an absence, not a
/// transparent colour.
void expectOracleColour(String what, Color? expected, Color? actual) {
  if (expected == null || actual == null) {
    if (expected == actual) {
      return;
    }
    fail(
      '$what: expected ${expected == null ? 'no paint' : _hex(expected)}, got '
      '${actual == null ? 'no paint' : _hex(actual)}',
    );
  }
  if (expected.toARGB32() != actual.toARGB32()) {
    fail('$what: expected ${_hex(expected)}, got ${_hex(actual)}');
  }
}

/// Compares two SVG path strings command-by-command, numbers within
/// [tolerance].
///
/// Not a string comparison: `M64.5,6V0.5` and `M 64.5 6 V 0.5` are the same
/// path, while `V0.5` and `V1` are not — and that half-pixel is exactly the
/// crispness-offset bug class of design spec §5.5.
void expectOracleSvgPath(
  String what,
  String expected,
  String actual, {
  double tolerance = kOracleGeometryTolerance,
}) {
  final wanted = tokeniseSvgPath(expected);
  final got = tokeniseSvgPath(actual);
  if (wanted.length != got.length) {
    fail(
      '$what: expected ${wanted.length} path tokens, got ${got.length}\n'
      '  expected: $expected\n'
      '  actual:   $actual',
    );
  }
  for (var i = 0; i < wanted.length; i++) {
    final a = wanted[i];
    final b = got[i];
    final wantedNumber = double.tryParse(a);
    final gotNumber = double.tryParse(b);
    if (wantedNumber == null || gotNumber == null) {
      if (a != b) {
        fail(
          '$what: token $i expected "$a", got "$b"\n'
          '  expected: $expected\n'
          '  actual:   $actual',
        );
      }
      continue;
    }
    if ((wantedNumber - gotNumber).abs() > tolerance) {
      fail(
        '$what: token $i expected ${_format(wantedNumber)}, got '
        '${_format(gotNumber)} (tolerance ${_format(tolerance)})\n'
        '  expected: $expected\n'
        '  actual:   $actual',
      );
    }
  }
}

/// Splits an SVG `d` string into command letters and number literals.
///
/// Public because the tokeniser is the one piece of parsing in this harness,
/// and a differential oracle whose comparator is untested is decoration.
List<String> tokeniseSvgPath(String d) => List<String>.unmodifiable(
  _pathToken.allMatches(d).map((match) => match[0]!),
);

/// Every number in an SVG `d` string, in source order, commands dropped.
///
/// The form the axis tests compare a captured domain path in: the same path
/// written from Dart doubles serialises `6` as `6.0`, so the commands are
/// checked by [expectOracleSvgPath] and the numbers by list equality here.
List<double> svgPathNumbers(String d) => List<double>.unmodifiable(
  tokeniseSvgPath(d).map(double.tryParse).whereType<double>(),
);

/// A path command letter, or a number in any form `d3-path` emits — including
/// a leading dot and an exponent.
final RegExp _pathToken = RegExp(
  r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
);

/// `translate(x, y)` or `translate(x)`, with the y defaulting to 0 as SVG
/// defines. Anything else — rotate, scale, matrix, a compound list — does not
/// match, and [OracleElement.translate] is then null on purpose.
final RegExp _translatePattern = RegExp(
  r'^\s*translate\(\s*([-+0-9.eE]+)\s*(?:[,\s]\s*([-+0-9.eE]+)\s*)?\)\s*$',
);

Offset? _translate(Object? transform) {
  if (transform == null) {
    return null;
  }
  final match = _translatePattern.firstMatch(_str(transform));
  if (match == null) {
    return null;
  }
  final dx = double.tryParse(match[1]!);
  final dy = match[2] == null ? 0.0 : double.tryParse(match[2]!);
  if (dx == null || dy == null) {
    return null;
  }
  return Offset(dx, dy);
}

/// `rgb(r, g, b)` and `rgba(r, g, b, a)` as `getComputedStyle` normalises them.
/// `none` and `transparent` are an absence of paint, not a colour.
final RegExp _rgbPattern = RegExp(
  r'^rgba?\(\s*([0-9.]+)[,\s]+([0-9.]+)[,\s]+([0-9.]+)\s*(?:[,/]\s*([0-9.%]+)\s*)?\)$',
);

/// `url("#id")` and `url(#id)`, as a paint that refers to a `defs` entry.
final RegExp _urlPattern = RegExp(r'''^url\(\s*["']?#([^"')]+)["']?\s*\)$''');

String? _paintRef(Object? value) {
  if (value == null) {
    return null;
  }
  return _urlPattern.firstMatch(_str(value).trim())?[1];
}

Color? _paint(Object? value) {
  if (value == null) {
    return null;
  }
  final text = _str(value).trim();
  if (text.isEmpty || text == 'none' || text == 'transparent') {
    return null;
  }
  if (_urlPattern.hasMatch(text)) {
    // A url(#…) paint is not a colour. The referenced id is recorded on the
    // element as fillRef/strokeRef and resolved through OracleSvg.gradient.
    return null;
  }
  final match = _rgbPattern.firstMatch(text);
  if (match == null) {
    throw ArgumentError.value(
      text,
      'value',
      'not an rgb()/rgba() or url(#id) string. getComputedStyle normalises '
          'every paint to one of those.',
    );
  }
  var alpha = 1.0;
  final rawAlpha = match[4];
  if (rawAlpha != null) {
    alpha = rawAlpha.endsWith('%')
        // A percentage alpha is out of 100.
        ? double.parse(rawAlpha.substring(0, rawAlpha.length - 1)) / 100
        : double.parse(rawAlpha);
  }
  return Color.fromARGB(
    (alpha * 255).round().clamp(0, 255),
    double.parse(match[1]!).round(),
    double.parse(match[2]!).round(),
    double.parse(match[3]!).round(),
  );
}

/// Multiplies a colour's alpha, via ARGB bits so no deprecated channel getter
/// is touched.
Color _scaleAlpha(Color colour, double factor) {
  final argb = colour.toARGB32();
  // 0xFF000000 >> 24 is the alpha byte.
  final alpha = ((argb >> 24) * factor).round().clamp(0, 255);
  return Color((alpha << 24) | (argb & 0x00FFFFFF));
}

/// A CSS numeric value, unit stripped: `"1px"` is 1, `"0.2"` is 0.2.
double _cssNumber(Object? value, double fallback) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toDouble();
  }
  final text = _str(value).trim();
  final parsed = double.tryParse(text.replaceAll(RegExp(r'[a-z%]+$'), ''));
  if (parsed == null) {
    // `stroke-width: medium` and friends never appear on upstream's charts; if
    // one ever does, the fallback would silently invent a number.
    throw ArgumentError.value(text, 'value', 'not a CSS length or number');
  }
  return parsed;
}

Rect _rect(List<Object?> box) =>
    Rect.fromLTWH(_dbl(box[0]), _dbl(box[1]), _dbl(box[2]), _dbl(box[3]));

Map<String, int> _counts(Object? value) =>
    Map<String, int>.unmodifiable(<String, int>{
      for (final entry in _obj(value).entries)
        entry.key: _dbl(entry.value).toInt(),
    });

String _format(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toString();

String _hex(Color colour) =>
    '#${colour.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}';

Map<String, dynamic> _obj(Object? value) => value! as Map<String, dynamic>;

List<Object?> _list(Object? value) => value! as List<Object?>;

String _str(Object? value) => value! as String;

double _dbl(Object? value) => (value! as num).toDouble();

double? _optDbl(Object? value) => value == null ? null : _dbl(value);
