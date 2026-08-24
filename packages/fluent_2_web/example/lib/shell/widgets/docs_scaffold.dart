import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../../pages.dart';
import '../catalog.dart';
import '../docs_metrics.dart';
import 'docs_prose.dart';
import 'docs_toolbar.dart';
import 'on_this_page.dart';
import 'preview_card.dart';
import 'props_table.dart';
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
    return ColoredBox(
      color: DocsMetrics.canvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Sidebar(selectedPageId: pageId),
          Expanded(
            child: page == null
                ? const SizedBox.shrink()
                // Keyed so switching pages resets scroll position and collapses
                // any open code panels, instead of carrying one page's scroll
                // offset into a shorter one.
                : _DocsBody(key: ValueKey<String>(page.id), page: page),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth:
                        DocsMetrics.storyColumnWidth +
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
                        DocsToolbar(page: page),
                        DocsProse(page.description),
                        const SizedBox(height: DocsMetrics.ruleGap),
                        const _Rule(),
                        const SizedBox(height: DocsMetrics.ruleGap),
                        for (final ProseBlock block in page.prose) ...<Widget>[
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
                        if (page.props.isNotEmpty) PropsTable(rows: page.props),
                        const SizedBox(height: 96),
                      ],
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
