import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../../pages.dart';
import '../catalog.dart';
import '../docs_metrics.dart';
import '../rtl_scope.dart';
import '../showroom_scope.dart';
import 'canvas_toolbar.dart';

/// One story, on its own canvas.
///
/// This is what a preview card's "Open in new tab" opens. Storybook's canvas
/// carries its own toolbar above the story — zoom, grid, background, theme and
/// direction — which is a different bar from the one on a docs page, so it
/// lives here rather than in the docs scaffold.
class StoryCanvas extends StatefulWidget {
  /// Renders the section with id [storyId].
  const StoryCanvas({super.key, required this.storyId});

  /// The section to render.
  final String storyId;

  @override
  State<StoryCanvas> createState() => _StoryCanvasState();
}

class _StoryCanvasState extends State<StoryCanvas> {
  double _zoom = 1;
  bool _grid = false;
  bool _surface = true;

  @override
  Widget build(BuildContext context) {
    final ({DocsPage page, DocsSection section})? found = sectionById(
      widget.storyId,
    );
    if (found == null) {
      return ColoredBox(
        color: DocsMetrics.canvas,
        child: Center(
          child: Text('No story "${widget.storyId}".', style: DocsMetrics.body),
        ),
      );
    }

    final ShowroomScope scope = ShowroomScope.of(context);
    final FluentThemeData data = scope.variant.data;

    final Widget story = FluentTheme(
      data: data,
      child: RtlScope(
        textDirection: scope.textDirection,
        child: DefaultTextStyle(
          style: data.typography.body1,
          child: IconTheme(
            data: IconThemeData(
              color: data.colors.neutralForeground1,
              size: 20,
            ),
            child: Builder(builder: found.section.builder),
          ),
        ),
      ),
    );

    return ColoredBox(
      color: DocsMetrics.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CanvasToolbar(
            zoom: _zoom,
            onZoom: (double? next) =>
                setState(() => _zoom = (next ?? 1).clamp(0.25, 4)),
            grid: _grid,
            onGrid: () => setState(() => _grid = !_grid),
            surface: _surface,
            onSurface: () => setState(() => _surface = !_surface),
            onCopyLink: () => copyToClipboard(Uri.base.toString()),
          ),
          Expanded(
            child: CanvasGrid(
              enabled: _grid,
              child: ColoredBox(
                color: _surface
                    ? data.colors.neutralBackground1
                    : const Color(0x00000000),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    // Scaled about the top-left so the story does not walk off
                    // the canvas as it grows.
                    child: Transform.scale(
                      scale: _zoom,
                      alignment: Alignment.topLeft,
                      child: story,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
