import 'package:flutter/widgets.dart';

import '../catalog.dart';
import '../docs_metrics.dart';

/// The right-hand anchor rail.
///
/// Upstream's is `position: sticky; top: 64px` — it travels with the page until
/// it reaches 64px from the top, then holds there while the article keeps
/// scrolling. That is why this widget lives *outside* the docs scroll view and
/// takes [scrollOffset] instead: a rail inside the scrollable would slide away
/// with the content.
///
/// The vertical line is one continuous rule down the whole list, with the
/// current section's segment painted over it — not a per-row border. Sampled
/// from the live rail: the rule is `#EDEBE9`, the active segment `#436DCD`.
class OnThisPage extends StatelessWidget {
  /// Lists [sections], marking [activeId] and reporting taps to [onSelect].
  const OnThisPage({
    super.key,
    required this.sections,
    required this.activeId,
    required this.onSelect,
    required this.scrollOffset,
  });

  /// The page's sections, in order.
  final List<DocsSection> sections;

  /// The section currently under the scroll probe.
  final String? activeId;

  /// Called with a section id when a row is clicked.
  final ValueChanged<String> onSelect;

  /// How far the docs body has scrolled, which is what drives the stick.
  final double scrollOffset;

  /// Where the rail sits before it starts sticking — level with the first
  /// section heading.
  static const double _restingTop = 145;

  /// Where it stops, upstream's `top: 64px`.
  static const double _stuckTop = 64;

  /// Height of one anchor row; the active segment matches it exactly.
  static const double _rowHeight = 36;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox(width: DocsMetrics.railWidth);
    }

    final double top = (_restingTop - scrollOffset).clamp(
      _stuckTop,
      _restingTop,
    );
    final int activeIndex = sections.indexWhere(
      (DocsSection s) => s.id == activeId,
    );

    return SizedBox(
      width: DocsMetrics.railWidth,
      child: Padding(
        padding: EdgeInsets.only(top: top, left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('ON THIS PAGE', style: DocsMetrics.railLabel),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Stack(
                  children: <Widget>[
                    // One rule for the whole list, then the active segment over
                    // it — the two are separate so the line stays continuous
                    // behind the highlight.
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 2, color: DocsMetrics.railLine),
                    ),
                    if (activeIndex >= 0)
                      Positioned(
                        left: 0,
                        top: activeIndex * _rowHeight,
                        child: Container(
                          width: 2,
                          height: _rowHeight,
                          color: DocsMetrics.railActive,
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final DocsSection section in sections)
                          _RailRow(
                            title: section.title,
                            active: section.id == activeId,
                            onPressed: () => onSelect(section.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailRow extends StatefulWidget {
  const _RailRow({
    required this.title,
    required this.active,
    required this.onPressed,
  });

  final String title;
  final bool active;
  final VoidCallback onPressed;

  @override
  State<_RailRow> createState() => _RailRowState();
}

class _RailRowState extends State<_RailRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: OnThisPage._rowHeight,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DocsMetrics.body.copyWith(
                  color: widget.active || _hovered
                      ? DocsMetrics.headingText
                      : DocsMetrics.bodyText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
