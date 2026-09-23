import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The analogue of Storybook's outline tool ("Apply outlines to the preview",
/// `outline/OutlineSelector.tsx`): every element under the story gets
/// `outline: 1px solid <tag colour>`.
///
/// Upstream injects `outlineCSS.ts:6-402` (pesticide v1.3.0) as one rule per
/// tag, scoped to `[data-story-block="true"] <tag>` in docs and
/// `.sb-show-main <tag>` on the canvas (`withOutline.ts:15,21`), so only the
/// story's *descendants* are outlined, never the story block itself. Here the
/// descendants are the render boxes under this widget, and the tag is read off
/// the render object's role.
///
/// The render tree is not the DOM: Padding, Align and friends add boxes the
/// DOM would express as CSS on one element, and a text-only button label gets
/// a text box where upstream's bare text node gets none.
class StoryOutlines extends StatelessWidget {
  /// Outlines every box in [child] while [enabled].
  const StoryOutlines({super.key, required this.enabled, required this.child});

  /// Whether to outline. Off paints [child] as-is and skips the ring walk —
  /// the tree shape stays the same either way, so toggling this never
  /// remounts [child] (`test/story_outlines_test.dart`'s stateful-child
  /// case).
  final bool enabled;

  /// The story.
  final Widget child;

  /// `div` (`outlineCSS.ts`, `[data-story-block="true"] div`): every box
  /// without a more specific role.
  static const Color boxColor = Color(0xFF036CDB);

  /// `button`: a box annotated `Semantics(button: true)`, which is how
  /// FluentButton marks itself (`fluent_2/lib/src/buttons/button.dart`).
  static const Color buttonColor = Color(0xFFDA8301);

  /// `span`: a text paragraph. Icon glyphs are exempt, as upstream has no
  /// rule for `svg`.
  static const Color textColor = Color(0xFFCC2643);

  /// `input`: an editable text line.
  static const Color inputColor = Color(0xFFFCA600);

  /// `img`: a raster image.
  static const Color imageColor = Color(0xFF22746B);

  @override
  Widget build(BuildContext context) {
    // Always the same tree shape, enabled or not: branching to bare [child]
    // here would change the tree shape on every toggle and remount it —
    // exactly the bug this widget used to have (see the field doc above).
    return _Outlines(
      enabled: enabled,
      // A scroll viewport is a repaint boundary: scrolling repaints only its
      // own layer, so the rings, which are recorded in this box's layer,
      // would stay where the content used to be. `context` is this widget's
      // element, whose nearest render object is `_RenderOutlines`.
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          context.findRenderObject()?.markNeedsPaint();
          return false;
        },
        child: child,
      ),
    );
  }
}

class _Outlines extends SingleChildRenderObjectWidget {
  const _Outlines({required this.enabled, required super.child});

  final bool enabled;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOutlines(enabled);

  @override
  void updateRenderObject(BuildContext context, _RenderOutlines renderObject) {
    renderObject.enabled = enabled;
  }
}

// ponytail: every paint walks every painted descendant, O(n) in the story's
// render tree, and the rings only refresh when this box repaints. Scrolling is
// relayed (see StoryOutlines.build); a descendant repaint boundary that
// repaints on its own without scrolling or relayout (charts, color_area,
// animations) can leave stale rings until the next repaint here. Upgrade path:
// a persistent frame callback that re-collects the rings and calls
// markNeedsPaint when the set changes.
class _RenderOutlines extends RenderProxyBox {
  _RenderOutlines(this._enabled);

  bool _enabled;

  /// While false, [paint] skips the ring walk entirely: no rings, no
  /// per-paint walk cost.
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    markNeedsPaint();
  }

  /// Indexed by [_rank]: identical rects keep the most specific role.
  static const List<Color> _colours = <Color>[
    StoryOutlines.boxColor,
    StoryOutlines.textColor,
    StoryOutlines.imageColor,
    StoryOutlines.inputColor,
    StoryOutlines.buttonColor,
  ];

  /// button > input > image > text > box.
  static int _rank(RenderBox box) => switch (box) {
    RenderSemanticsAnnotations(:final SemanticsProperties properties)
        when properties.button ?? false =>
      4,
    RenderEditable() => 3,
    RenderImage() => 2,
    RenderParagraph() => 1,
    _ => 0,
  };

  /// An Icon's glyph. `Icon` sets the family with `package:`, so the style
  /// reads `packages/fluentui_system_icons/FluentSystemIcons-Regular`.
  static bool _isGlyph(RenderBox box) =>
      box is RenderParagraph &&
      (box.text.style?.fontFamily?.contains('FluentSystemIcons') ?? false);

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (!_enabled) return;

    // Rect in this box's coordinates -> (rank, clip). The clip is the first
    // one seen: the outermost box of a stack of identical rects is the least
    // clipped, and a ClipRect's own bounds must not swallow its child's ring.
    final Map<Rect, (int, Rect?)> rings = <Rect, (int, Rect?)>{};

    void visit(RenderObject node, Matrix4 transform, Rect? clip) {
      node.visitChildren((RenderObject child) {
        // Offstage, zero opacity, the hidden children of an IndexedStack.
        if (!node.paintsChild(child)) {
          return;
        }
        if (child is RenderBox && !child.hasSize) {
          return;
        }
        // CSS outlines are clipped by an ancestor's overflow, so carry every
        // paint clip down, in this box's coordinates.
        final Rect? local = node.describeApproximatePaintClip(child);
        Rect? childClip = clip;
        if (local != null) {
          final Rect mapped = MatrixUtils.transformRect(transform, local);
          childClip = clip == null ? mapped : clip.intersect(mapped);
        }
        // Built up on the way down, which is what getTransformTo(this) does
        // per node, without re-walking the path each time.
        final Matrix4 childTransform = transform.clone();
        node.applyPaintTransform(child, childTransform);

        // Zero-area boxes are layout spacers (SizedBox gaps) that the DOM
        // would express as margin or gap, not as an element.
        if (child is RenderBox && !child.size.isEmpty && !_isGlyph(child)) {
          final Rect rect = MatrixUtils.transformRect(
            childTransform,
            Offset.zero & child.size,
          );
          if (childClip == null || childClip.overlaps(rect.inflate(1))) {
            final int rank = _rank(child);
            final (int, Rect?)? seen = rings[rect];
            if (seen == null) {
              rings[rect] = (rank, childClip);
            } else if (seen.$1 < rank) {
              rings[rect] = (rank, seen.$2);
            }
          }
        }
        visit(child, childTransform, childClip);
      });
    }

    visit(this, Matrix4.identity(), null);

    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final MapEntry<Rect, (int, Rect?)> ring in rings.entries) {
      final (int rank, Rect? clip) = ring.value;
      paint.color = _colours[rank];
      if (clip != null) {
        canvas
          ..save()
          ..clipRect(clip.shift(offset));
      }
      // `outline-offset: 0`: a 1px stroke centred half a pixel out covers
      // exactly the pixels just outside the box.
      canvas.drawRect(ring.key.shift(offset).inflate(0.5), paint);
      if (clip != null) {
        canvas.restore();
      }
    }
  }
}
