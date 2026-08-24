import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../../pages.dart';
import '../catalog.dart';
import '../docs_metrics.dart';
import '../router.dart';

/// The left rail: brand, search, and the page tree.
///
/// Its scroll position and expanded groups live in this `State`, which is never
/// disposed — the Navigator holds one page for the app's lifetime and the route
/// arrives by inherited notification, so navigating never rebuilds this widget
/// from scratch. That is the whole reason the router is shaped the way it is.
class Sidebar extends StatefulWidget {
  /// Shows the catalog, highlighting [selectedPageId].
  const Sidebar({
    super.key,
    required this.selectedPageId,
    this.width = DocsMetrics.sidebarWidth,
  });

  /// The page currently open.
  final String selectedPageId;

  /// The current rail width, which the reader can drag.
  final double width;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  late final Set<String> _collapsed = <String>{};

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  List<DocsGroup> get _filtered {
    final String query = _search.text.trim().toLowerCase();
    if (query.isEmpty) {
      return catalog;
    }
    final List<DocsGroup> out = <DocsGroup>[];
    for (final DocsGroup group in catalog) {
      final List<DocsPage> hits = group.pages
          .where((DocsPage p) => p.sidebarLabel.toLowerCase().contains(query))
          .toList();
      if (hits.isNotEmpty) {
        out.add(DocsGroup(title: group.title, pages: hits));
      }
    }
    return out;
  }

  /// Emits a group's rows, opening a folder node wherever consecutive pages
  /// share one. Contract order already groups them, so a single pass is enough.
  List<Widget> _rowsFor(BuildContext context, DocsGroup group, bool searching) {
    final List<Widget> rows = <Widget>[];
    String? openFolder;

    for (final DocsPage page in group.pages) {
      final String? folder = page.folder;

      if (folder != null && folder != openFolder) {
        openFolder = folder;
        final String key = '${group.title}/$folder';
        rows.add(
          _FolderRow(
            title: folder,
            collapsed: !searching && _collapsed.contains(key),
            onToggle: () => setState(() {
              if (!_collapsed.remove(key)) {
                _collapsed.add(key);
              }
            }),
          ),
        );
      } else if (folder == null) {
        openFolder = null;
      }

      final bool hidden =
          folder != null &&
          !searching &&
          _collapsed.contains('${group.title}/$folder');
      if (hidden) {
        continue;
      }

      rows.add(
        _PageRow(
          page: page,
          selected: page.id == widget.selectedPageId,
          indented: folder != null,
          onPressed: () =>
              DocsRouterScope.of(context).go(DocsRoute.docs(page.id)),
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final bool searching = _search.text.trim().isNotEmpty;
    final List<DocsGroup> groups = _filtered;

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _BrandHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              height: DocsMetrics.searchHeight,
              child: FluentSearchBox(
                controller: _search,
                size: FluentSearchBoxSize.small,
                placeholder: 'Find components',
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
              ),
            ),
          ),
          Expanded(
            // `FluentScrollBehavior` strips the framework scrollbar app-wide,
            // so the chrome has to bring its own. `RawScrollbar` lives in
            // `package:flutter/widgets.dart` — the Material one would drag in
            // exactly the dependency this app just shed.
            child: RawScrollbar(
              controller: _scroll,
              thumbColor: DocsMetrics.bodyText.withValues(alpha: 0.28),
              radius: const Radius.circular(4),
              thickness: 6,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 24),
                children: <Widget>[
                  for (final DocsGroup group in groups) ...<Widget>[
                    _GroupHeader(
                      title: group.title,
                      collapsed: !searching && _collapsed.contains(group.title),
                      onToggle: () => setState(() {
                        if (!_collapsed.remove(group.title)) {
                          _collapsed.add(group.title);
                        }
                      }),
                      onToggleAll: () => setState(() {
                        final Iterable<String> folders = group.pages
                            .map((DocsPage p) => p.folder)
                            .whereType<String>()
                            .map((String f) => '${group.title}/$f')
                            .toSet();
                        if (folders.every(_collapsed.contains)) {
                          _collapsed.removeAll(folders);
                        } else {
                          _collapsed.addAll(folders);
                        }
                      }),
                    ),
                    if (searching || !_collapsed.contains(group.title))
                      // Six upstream groups nest a folder level — Badge,
                      // Button, Card, Carousel, Menu, Tag — so a page's rows
                      // are emitted through the folder walker rather than
                      // flat.
                      ..._rowsFor(context, group, searching),
                  ],
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 12, 12),
                      child: Text(
                        'No components found.',
                        style: DocsMetrics.sidebarItem,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
      child: Row(
        children: <Widget>[
          // Square source, so the box is square too and the image is asked for
          // at the size it is drawn — a 1254px logo decoded to fill a 22px slot
          // would cost the same memory as a full-screen image for nothing.
          const SizedBox(
            width: 22,
            height: 22,
            child: Image(
              image: ResizeImage(
                AssetImage('assets/storybook/fluent_2_flutter.png'),
                width: 44,
                height: 44,
              ),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fluent UI Flutter v9',
              style: DocsMetrics.sidebarGroup.copyWith(fontSize: 16),
            ),
          ),
          Icon(
            FluentIcons.settings_20_regular,
            size: 18,
            color: DocsMetrics.bodyText.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.collapsed,
    required this.onToggle,
    required this.onToggleAll,
  });

  final String title;
  final bool collapsed;
  final VoidCallback onToggle;

  /// Collapses or expands every folder in the group at once — the small
  /// chevron-pair on the right of upstream's group headings.
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 4),
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            children: <Widget>[
              Icon(
                collapsed
                    ? FluentIcons.chevron_right_20_regular
                    : FluentIcons.chevron_down_20_regular,
                size: 14,
                color: DocsMetrics.headingText,
              ),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: DocsMetrics.sidebarGroup)),
              GestureDetector(
                onTap: onToggleAll,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    FluentIcons.chevron_up_down_20_regular,
                    size: 14,
                    color: DocsMetrics.sidebarText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageRow extends StatefulWidget {
  const _PageRow({
    required this.page,
    required this.selected,
    required this.onPressed,
    this.indented = false,
  });

  final DocsPage page;
  final bool selected;
  final VoidCallback onPressed;

  /// Pages inside a folder sit one level in.
  final bool indented;

  @override
  State<_PageRow> createState() => _PageRowState();
}

class _PageRowState extends State<_PageRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color background = widget.selected
        ? DocsMetrics.sidebarSelected
        : _hovered
        ? DocsMetrics.border.withValues(alpha: 0.35)
        : const Color(0x00000000);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: DocsMetrics.sidebarItemHeight,
            padding: DocsMetrics.sidebarItemPadding.add(
              EdgeInsetsDirectional.only(
                start: widget.indented ? DocsMetrics.sidebarIndent : 0,
              ),
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  FluentIcons.document_20_regular,
                  size: 14,
                  color: widget.selected
                      ? DocsMetrics.sidebarSelectedText
                      : DocsMetrics.sidebarText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.page.sidebarLabel,
                    overflow: TextOverflow.ellipsis,
                    style: widget.selected
                        ? DocsMetrics.sidebarItem.copyWith(
                            color: DocsMetrics.sidebarSelectedText,
                            fontWeight: FontWeight.w600,
                          )
                        : DocsMetrics.sidebarItem,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A folder node: chevron, folder glyph, and the family name.
class _FolderRow extends StatefulWidget {
  const _FolderRow({
    required this.title,
    required this.collapsed,
    required this.onToggle,
  });

  final String title;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  State<_FolderRow> createState() => _FolderRowState();
}

class _FolderRowState extends State<_FolderRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: DocsMetrics.sidebarItemHeight,
            padding: const EdgeInsets.only(left: 4, top: 5, bottom: 4),
            decoration: BoxDecoration(
              color: _hovered
                  ? DocsMetrics.border.withValues(alpha: 0.35)
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  widget.collapsed
                      ? FluentIcons.chevron_right_20_regular
                      : FluentIcons.chevron_down_20_regular,
                  size: 12,
                  color: DocsMetrics.sidebarText,
                ),
                const SizedBox(width: 4),
                Icon(
                  FluentIcons.folder_20_regular,
                  size: 14,
                  color: DocsMetrics.sidebarText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: DocsMetrics.sidebarItem,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
