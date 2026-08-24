import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../../pages.dart';
import '../catalog.dart';
import '../docs_metrics.dart';
import '../showroom_scope.dart';
import 'docs_prose.dart';
import 'docs_toolbar.dart';
import 'markdown_view.dart';
import 'on_this_page.dart';
import 'preview_card.dart';
import 'props_table.dart';
import 'selectable.dart';
import 'shell_toolbar.dart';
import 'sidebar.dart';

/// The whole chrome: sidebar, docs body, anchor rail.
class DocsScaffold extends StatelessWidget {
  /// Renders the page with id [pageId].
  const DocsScaffold({super.key, required this.pageId});

  /// The open page.
  final String pageId;

  @override
  Widget build(BuildContext context) {
    final DocsPage? page = pageById(pageId);
    final ShowroomScope scope = ShowroomScope.of(context);
    final Widget body = page == null
        ? const SizedBox.shrink()
        // Keyed so switching pages resets scroll position and collapses any
        // open code panels, instead of carrying one page's scroll offset into
        // a shorter one.
        : _DocsBody(key: ValueKey<String>(page.id), page: page);

    // Full screen drops the chrome entirely and hands the window to the page.
    if (scope.fullScreen) {
      return ColoredBox(
        color: DocsMetrics.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ShellToolbar(),
            Expanded(child: body),
          ],
        ),
      );
    }

    return ColoredBox(
      color: DocsMetrics.canvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (scope.sidebarVisible) _ResizableSidebar(selectedPageId: pageId),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ShellToolbar(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocsBody extends StatefulWidget {
  const _DocsBody({super.key, required this.page});

  final DocsPage page;

  @override
  State<_DocsBody> createState() => _DocsBodyState();
}

class _DocsBodyState extends State<_DocsBody> {
  /// How far below the viewport top a heading counts as "current".
  static const double _spyInset = 120;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  late Map<String, GlobalKey> _anchors;

  String? _active;
  bool _spyLocked = false;

  @override
  void initState() {
    super.initState();
    _anchors = <String, GlobalKey>{
      for (final DocsSection s in widget.page.sections) s.id: GlobalKey(),
    };
    _scroll.addListener(_syncSpy);
    // The listener only fires on scroll, so without this the rail has no active
    // anchor until the reader moves — and the first section is already on
    // screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncSpy();
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_syncSpy);
    _scroll.dispose();
    super.dispose();
  }

  /// Absolute scroll offset of a section heading, or null when it has not been
  /// laid out.
  double? _offsetOf(GlobalKey key) {
    final RenderObject? box = key.currentContext?.findRenderObject();
    final RenderObject? viewport = _viewportKey.currentContext
        ?.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || !box.attached) {
      return null;
    }
    return box.localToGlobal(Offset.zero, ancestor: viewport).dy +
        _scroll.offset;
  }

  /// Measures on every scroll rather than caching offsets once.
  ///
  /// Cached offsets are wrong the moment anything above changes height, and on
  /// this page that happens constantly: expanding a code panel, zooming a card,
  /// resizing the window, a chart settling. Re-measuring ~15 keys is cheaper
  /// than tracking every cause of invalidation.
  void _syncSpy() {
    // Theme pages render a body instead of sections, so there is no rail to
    // track and `sections.first` below would throw.
    if (_spyLocked || widget.page.sections.isEmpty) {
      return;
    }
    final double probe = _scroll.offset + _spyInset;
    String? active;
    // Sections are in document order, so the last one above the probe wins.
    for (final DocsSection section in widget.page.sections) {
      final double? y = _offsetOf(_anchors[section.id]!);
      if (y != null && y <= probe) {
        active = section.id;
      }
    }
    // At the top of the page no heading has passed the probe yet, but the first
    // section is already on screen and upstream marks it current. Fall back to
    // it rather than showing a rail with nothing selected.
    active ??= widget.page.sections.first.id;
    if (active != _active) {
      setState(() => _active = active);
    }
  }

  Future<void> _scrollTo(String id) async {
    final BuildContext? target = _anchors[id]?.currentContext;
    if (target == null) {
      return;
    }
    setState(() {
      _active = id;
      _spyLocked = true;
    });
    await Scrollable.ensureVisible(
      target,
      duration: FluentDuration.normal,
      curve: FluentCurve.easyEase,
    );
    if (!mounted) {
      return;
    }
    setState(() => _spyLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    final DocsPage page = widget.page;

    // The rail sits OUTSIDE the scroll view. Upstream's is `position: sticky`,
    // which a child of the scrollable cannot be — it would slide away with the
    // article. It reads the offset instead and parks itself at 64px.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: RawScrollbar(
            controller: _scroll,
            thumbColor: DocsMetrics.bodyText.withValues(alpha: 0.28),
            radius: const Radius.circular(4),
            thickness: 8,
            child: SingleChildScrollView(
              key: _viewportKey,
              controller: _scroll,
              // One region for the whole article, so a selection can run across
              // section boundaries the way it does in a browser.
              child: Selectable(
                child: Center(
                  child: ConstrainedBox(
                    // Pages with no sections have no "On this page" rail beside
                    // them, so the article gets the full content width rather
                    // than the narrower story column that leaves room for one.
                    constraints: BoxConstraints(
                      maxWidth:
                          (page.sections.isEmpty
                              ? DocsMetrics.contentMaxWidth
                              : DocsMetrics.storyColumnWidth) +
                          DocsMetrics.contentInset * 2,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DocsMetrics.contentInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 49),
                          Text(page.title, style: DocsMetrics.h1),
                          const SizedBox(height: 16),
                          // Theme pages carry neither the toolbar nor the rule
                          // upstream — they open straight onto their token card,
                          // because there are no stories for a theme control to
                          // act on.
                          if (page.sections.isNotEmpty) ...<Widget>[
                            DocsToolbar(page: page),
                            DocsProse(page.description),
                            const SizedBox(height: DocsMetrics.ruleGap),
                            const _Rule(),
                            const SizedBox(height: DocsMetrics.ruleGap),
                          ] else if (page.description.isNotEmpty) ...<Widget>[
                            DocsProse(page.description),
                            const SizedBox(height: 24),
                          ],
                          // A page that carries its own markdown is rendered
                          // by the viewer, which handles the tables and nested
                          // lists the prose renderer would flatten.
                          if (page.markdown != null)
                            MarkdownBody(
                              source: page.markdown!,
                              skipLeadingHeading: true,
                            ),
                          for (final ProseBlock block
                              in page.prose) ...<Widget>[
                            const SizedBox(height: 32),
                            Text(block.title, style: DocsMetrics.h3),
                            const SizedBox(height: 12),
                            DocsProse(block.body),
                          ],
                          if (page.prose.isNotEmpty)
                            const SizedBox(height: DocsMetrics.ruleGap),
                          if (page.body != null) page.body!(context),
                          for (final DocsSection section in page.sections)
                            _Section(
                              key: _anchors[section.id],
                              section: section,
                              assetPath: page.source,
                            ),
                          if (page.props.isNotEmpty)
                            PropsTable(rows: page.props),
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Only the rail rebuilds as the page scrolls; the article does not.
        ListenableBuilder(
          listenable: _scroll,
          builder: (BuildContext context, _) => OnThisPage(
            sections: page.sections,
            activeId: _active,
            onSelect: _scrollTo,
            scrollOffset: _scroll.hasClients ? _scroll.offset : 0,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.section, required this.assetPath});

  final DocsSection section;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.38),
          child: Text(section.title, style: DocsMetrics.h3),
        ),
        if (section.description != null) DocsProse(section.description!),
        PreviewCard(section: section, assetPath: assetPath),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: DocsMetrics.rule,
    child: SizedBox(height: DocsMetrics.ruleThickness, width: double.infinity),
  );
}

/// The sidebar plus the divider you can drag to resize it.
///
/// Upstream's rail is resizable, and the handle is the divider itself rather
/// than a separate grip. Width lives here rather than in [Sidebar] so the
/// sidebar's own scroll position and expanded folders are untouched by a drag.
class _ResizableSidebar extends StatefulWidget {
  const _ResizableSidebar({required this.selectedPageId});

  final String selectedPageId;

  @override
  State<_ResizableSidebar> createState() => _ResizableSidebarState();
}

class _ResizableSidebarState extends State<_ResizableSidebar> {
  /// Below this the drag is read as "close it", not "make it narrow".
  static const double _collapseAt = 170;
  static const double _minWidth = 220;
  static const double _maxWidth = 560;

  double _width = DocsMetrics.sidebarWidth;

  /// The drag's own running total, unclamped.
  ///
  /// [_width] is clamped for rendering, so accumulating into it would peg at the
  /// minimum and never reach [_collapseAt] — dragging further left would just
  /// recompute the same 220 forever, and the rail could never be closed.
  double _dragWidth = DocsMetrics.sidebarWidth;

  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _dragging;
    return Row(
      children: <Widget>[
        SizedBox(
          width: _width,
          child: Sidebar(selectedPageId: widget.selectedPageId, width: _width),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => setState(() {
              _dragging = true;
              _dragWidth = _width;
            }),
            onHorizontalDragEnd: (_) => setState(() => _dragging = false),
            onHorizontalDragCancel: () => setState(() => _dragging = false),
            onHorizontalDragUpdate: (DragUpdateDetails d) {
              _dragWidth += d.delta.dx;
              if (_dragWidth < _collapseAt) {
                // Hand the rail's visibility to the shared state, so the
                // toolbar's hamburger and this drag cannot disagree about
                // whether it is open.
                setState(() {
                  _dragging = false;
                  _width = DocsMetrics.sidebarWidth;
                  _dragWidth = DocsMetrics.sidebarWidth;
                });
                ShowroomScope.of(context).onToggleSidebar();
                return;
              }
              setState(() => _width = _dragWidth.clamp(_minWidth, _maxWidth));
            },
            // The hit area is wider than the line it draws: a 1px target is
            // unhittable, and upstream's is similarly forgiving.
            child: SizedBox(
              width: 8,
              child: Center(
                child: ColoredBox(
                  color: active ? DocsMetrics.railActive : DocsMetrics.rule,
                  child: SizedBox(
                    width: active ? 2 : 1,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
