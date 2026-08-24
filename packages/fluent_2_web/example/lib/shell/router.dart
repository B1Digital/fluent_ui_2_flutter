import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../pages.dart';
import 'widgets/docs_scaffold.dart';
import 'widgets/markdown_view.dart';
import 'widgets/story_canvas.dart';

/// Where the app is: a docs page, or one story on its own.
@immutable
class DocsRoute {
  /// A docs page, by [DocsPage.id].
  const DocsRoute.docs(this.pageId) : storyId = null, isMarkdown = false;

  /// A single story, full-bleed. This is what the preview card's "Open in new
  /// tab" opens, and it exists so that button has something real to point at.
  const DocsRoute.story(this.storyId) : pageId = null, isMarkdown = false;

  /// A page's raw markdown on a bare page. What "View as Markdown" opens, in a
  /// new tab — upstream navigates to a plain `.txt`, so this has no chrome.
  const DocsRoute.markdown(this.pageId) : storyId = null, isMarkdown = true;

  /// The page id, or null when this is a story route.
  final String? pageId;

  /// The story id, or null when this is a docs route.
  final String? storyId;

  /// True when this route renders the page's markdown rather than the page.
  final bool isMarkdown;

  /// True when this route renders one story with no chrome.
  bool get isCanvas => storyId != null;

  /// The first page in the catalog — where `/` lands.
  static DocsRoute get initial => DocsRoute.docs(catalog.first.pages.first.id);

  /// Parses `/docs/<pageId>` or `/story/<storyId>`, falling back to [initial].
  ///
  /// Anything unrecognised resolves rather than throwing: a stale bookmark
  /// should open the showroom, not a crash screen.
  factory DocsRoute.parse(Uri uri) {
    final List<String> segments = uri.pathSegments;
    if (segments.length >= 2) {
      if (segments[0] == 'docs' && pageById(segments[1]) != null) {
        return DocsRoute.docs(segments[1]);
      }
      if (segments[0] == 'story') {
        return DocsRoute.story(segments[1]);
      }
      if (segments[0] == 'markdown' && pageById(segments[1]) != null) {
        return DocsRoute.markdown(segments[1]);
      }
    }
    return initial;
  }

  /// The location this route occupies in the address bar.
  Uri get uri => Uri(
    path: isCanvas
        ? '/story/$storyId'
        : isMarkdown
        ? '/markdown/$pageId'
        : '/docs/$pageId',
  );

  @override
  bool operator ==(Object other) =>
      other is DocsRoute &&
      other.pageId == pageId &&
      other.storyId == storyId &&
      other.isMarkdown == isMarkdown;

  @override
  int get hashCode => Object.hash(pageId, storyId, isMarkdown);
}

/// Translates between the browser location and a [DocsRoute].
class DocsRouteParser extends RouteInformationParser<DocsRoute> {
  /// Creates a parser.
  const DocsRouteParser();

  @override
  Future<DocsRoute> parseRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture<DocsRoute>(DocsRoute.parse(routeInformation.uri));

  @override
  RouteInformation restoreRouteInformation(DocsRoute configuration) =>
      RouteInformation(uri: configuration.uri);
}

/// Owns the current route and rebuilds the shell in place when it changes.
///
/// ## Why a Router and not `Navigator.pushNamed`
///
/// `pushNamed` does update the address bar — `WidgetsApp` builds its `Navigator`
/// with `reportsRouteUpdateToEngine: true`. But pushing also puts the web engine
/// into *single-entry* history mode, where it keeps two history entries and
/// converts a browser Back into a `popRoute` message. In that mode browser
/// Forward can never work, and you are left choosing between a nav stack that
/// grows by one route per sidebar click and a Back button that leaves the app.
///
/// `PlatformRouteInformationProvider` calls `selectMultiEntryHistory()` instead,
/// which gives real history entries and therefore real Back *and* Forward.
///
/// ## Why the Navigator holds one page forever
///
/// Swapping the `Page` on every navigation would tear down and rebuild the
/// shell's `State` — losing the sidebar's scroll position, its expanded groups,
/// and every open code panel. Instead the page list is a constant, and the
/// current route reaches the shell through [DocsRouterScope]. The shell rebuilds;
/// it is never recreated.
class DocsRouterDelegate extends RouterDelegate<DocsRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<DocsRoute> {
  /// Starts at [route].
  DocsRouterDelegate(this._route);

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  DocsRoute _route;

  /// Where the app currently is.
  DocsRoute get route => _route;

  @override
  DocsRoute get currentConfiguration => _route;

  /// Navigates, adding a browser history entry.
  void go(DocsRoute next) {
    if (next == _route) {
      return;
    }
    _route = next;
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(DocsRoute configuration) {
    // Deep links, Back and Forward all arrive here.
    _route = configuration;
    return SynchronousFuture<void>(null);
  }

  @override
  Widget build(BuildContext context) => DocsRouterScope(
    delegate: this,
    child: Navigator(
      key: navigatorKey,
      pages: const <Page<void>>[_ShellPage()],
      onDidRemovePage: _onDidRemovePage,
    ),
  );

  // The single page is never removed; the callback exists because Navigator
  // requires one when driven by `pages:`.
  static void _onDidRemovePage(Page<Object?> page) {}
}

class _ShellPage extends Page<void> {
  const _ShellPage() : super(key: const ValueKey<String>('shell'));

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    // No transition: the shell is not replaced, only its body changes, and
    // cross-fading a whole docs site on every sidebar click reads as lag.
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (BuildContext context, _, _) {
      final DocsRoute route = DocsRouterScope.of(context).route;
      if (route.isCanvas) {
        return StoryCanvas(storyId: route.storyId!);
      }
      if (route.isMarkdown) {
        return MarkdownView(pageId: route.pageId!);
      }
      return DocsScaffold(pageId: route.pageId!);
    },
  );
}

/// Exposes the [DocsRouterDelegate] to the shell, rebuilding dependents when the
/// route changes without ever replacing the page.
class DocsRouterScope extends InheritedNotifier<DocsRouterDelegate> {
  /// Provides [delegate] to [child].
  const DocsRouterScope({
    super.key,
    required DocsRouterDelegate delegate,
    required super.child,
  }) : super(notifier: delegate);

  /// The nearest delegate.
  static DocsRouterDelegate of(BuildContext context) {
    final DocsRouterScope? scope = context
        .dependOnInheritedWidgetOfExactType<DocsRouterScope>();
    assert(scope != null, 'No DocsRouterScope above this widget');
    return scope!.notifier!;
  }
}
