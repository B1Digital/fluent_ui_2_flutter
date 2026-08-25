import 'package:fluent_2_fonts/fluent_2_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'tokens/global_colors.dart';
import 'tokens/motion.dart';

/// Which theme to apply when both a light and a dark theme are supplied.
enum FluentThemeMode {
  /// Follow the platform's own light/dark setting.
  system,

  /// Always use the light theme.
  light,

  /// Always use the dark theme.
  dark,
}

/// The root of a Fluent application — the replacement for `MaterialApp`.
///
/// Wraps [WidgetsApp] (not `MaterialApp`), so nothing in the tree pulls in
/// Material. It supplies the [FluentTheme], a default text style and icon
/// theme, a scrollbar-free scroll behavior, and Fluent page transitions.
class FluentApp extends StatelessWidget {
  /// Creates a Fluent application.
  const FluentApp({
    super.key,
    this.navigatorKey,
    this.home,
    this.routes = const {},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const [],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.theme,
    this.darkTheme,
    this.themeMode = FluentThemeMode.system,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
  }) : routeInformationProvider = null,
       routeInformationParser = null,
       routerDelegate = null,
       routerConfig = null,
       backButtonDispatcher = null,
       _router = false;

  /// The `Router`-based constructor, for `go_router` and friends.
  const FluentApp.router({
    super.key,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.routerConfig,
    this.backButtonDispatcher,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.theme,
    this.darkTheme,
    this.themeMode = FluentThemeMode.system,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
  }) : navigatorKey = null,
       home = null,
       routes = const {},
       initialRoute = null,
       onGenerateRoute = null,
       onUnknownRoute = null,
       navigatorObservers = const [],
       _router = true;

  final bool _router;

  /// Key for the underlying navigator. Forwarded to `WidgetsApp`.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The widget at the default route.
  final Widget? home;

  /// Named-route table. Forwarded to `WidgetsApp`.
  final Map<String, WidgetBuilder> routes;

  /// Route shown first when the navigator is created.
  final String? initialRoute;

  /// Builds routes not listed in [routes].
  final RouteFactory? onGenerateRoute;

  /// Fallback when [onGenerateRoute] returns null.
  final RouteFactory? onUnknownRoute;

  /// Observers attached to the navigator.
  final List<NavigatorObserver> navigatorObservers;

  /// Router API. Supply these instead of [routes] for declarative routing.
  final RouteInformationProvider? routeInformationProvider;

  /// Parses route information into a configuration object.
  final RouteInformationParser<Object>? routeInformationParser;

  /// Builds the navigator from the parsed configuration.
  final RouterDelegate<Object>? routerDelegate;

  /// Bundles the four Router pieces. Mutually exclusive with them.
  final RouterConfig<Object>? routerConfig;

  /// Decides which router handles a back gesture.
  final BackButtonDispatcher? backButtonDispatcher;

  /// Wraps the navigator, above every route but below the theme.
  final TransitionBuilder? builder;

  /// Application title, used by the task switcher.
  final String title;

  /// Builds a localized [title] once localizations are available.
  final GenerateAppTitle? onGenerateTitle;

  /// Applied when the resolved brightness is light. Defaults to
  /// [FluentThemeData.light].
  final FluentThemeData? theme;

  /// Applied when the resolved brightness is dark. Falls back to [theme] if
  /// null, which keeps a single-theme app from silently switching.
  final FluentThemeData? darkTheme;

  /// Which of [theme] and [darkTheme] applies. Defaults to following the platform.
  final FluentThemeMode themeMode;

  /// Overrides the system locale.
  final Locale? locale;

  /// Localizations to load. Forwarded to `WidgetsApp`.
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// Locales this app can display.
  final Iterable<Locale> supportedLocales;

  /// Shows the frame-timing overlay.
  final bool showPerformanceOverlay;

  /// Shows the accessibility tree overlay.
  final bool showSemanticsDebugger;

  /// Shows the debug banner. Has no effect in release builds.
  final bool debugShowCheckedModeBanner;

  /// App-wide key bindings. Forwarded to `WidgetsApp`.
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// App-wide intent handlers. Forwarded to `WidgetsApp`.
  final Map<Type, Action<Intent>>? actions;

  /// Enables state restoration under this id.
  final String? restorationScopeId;

  /// Overrides [FluentScrollBehavior].
  final ScrollBehavior? scrollBehavior;

  FluentThemeData _resolveTheme(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final wantsDark = switch (themeMode) {
      FluentThemeMode.light => false,
      FluentThemeMode.dark => true,
      FluentThemeMode.system => platformBrightness == Brightness.dark,
    };
    if (wantsDark) {
      return darkTheme ?? theme ?? FluentThemeData.dark();
    }
    return theme ?? FluentThemeData.light();
  }

  @override
  Widget build(BuildContext context) {
    if (!FluentFonts.requiresLoading || FluentFonts.isLoaded) {
      return _buildApp(context);
    }
    return FutureBuilder<void>(
      future: FluentFonts.ensureLoaded(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorWidget(
            'Unable to load the Fluent font family: ${snapshot.error}',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return _buildApp(context);
      },
    );
  }

  Widget _buildApp(BuildContext context) {
    // `WidgetsApp` has no `scrollBehavior` parameter — that convenience only
    // exists on MaterialApp/CupertinoApp — so it goes on as ScrollConfiguration.
    final effectiveScrollBehavior =
        scrollBehavior ?? const FluentScrollBehavior();

    Widget wrap(BuildContext context, Widget? child) {
      final data = _resolveTheme(context);
      // Theme outermost so `builder` and the app body both see it.
      return FluentTheme(
        data: data,
        child: ScrollConfiguration(
          behavior: effectiveScrollBehavior,
          child: DefaultTextStyle(
            style: data.typography.body1,
            child: IconTheme(
              data: IconThemeData(
                color: data.colors.neutralForeground1,
                size: 20,
              ),
              child: Builder(
                builder: (context) =>
                    builder?.call(context, child) ?? child ?? const SizedBox(),
              ),
            ),
          ),
        ),
      );
    }

    if (_router) {
      return WidgetsApp.router(
        routeInformationProvider: routeInformationProvider,
        routeInformationParser: routeInformationParser,
        routerDelegate: routerDelegate,
        routerConfig: routerConfig,
        backButtonDispatcher: backButtonDispatcher,
        builder: wrap,
        title: title,
        onGenerateTitle: onGenerateTitle,
        color: _seedColor,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        showPerformanceOverlay: showPerformanceOverlay,
        showSemanticsDebugger: showSemanticsDebugger,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        shortcuts: shortcuts,
        actions: actions,
        restorationScopeId: restorationScopeId,
      );
    }

    return WidgetsApp(
      navigatorKey: navigatorKey,
      home: home,
      routes: routes,
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      onUnknownRoute: onUnknownRoute,
      navigatorObservers: navigatorObservers,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          FluentPageRoute<T>(settings: settings, builder: builder),
      builder: wrap,
      title: title,
      onGenerateTitle: onGenerateTitle,
      color: _seedColor,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      showPerformanceOverlay: showPerformanceOverlay,
      showSemanticsDebugger: showSemanticsDebugger,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      shortcuts: shortcuts,
      actions: actions,
      restorationScopeId: restorationScopeId,
    );
  }

  /// `WidgetsApp.color` is the OS task-switcher color, not a theme color, and
  /// it must be resolvable before the theme exists.
  Color get _seedColor =>
      (theme ?? darkTheme)?.colors.brandBackground ?? FluentBrandRamp.web[80];
}

/// A page route with Fluent's enter/exit motion: a short fade combined with a
/// small upward slide, decelerating in and accelerating out.
class FluentPageRoute<T> extends PageRoute<T> {
  /// Creates a route that fades its page in.
  FluentPageRoute({required this.builder, super.settings});

  /// Builds the page.
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => FluentDuration.normal;

  @override
  Duration get reverseTransitionDuration => FluentDuration.fast;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: FluentCurve.decelerateMid,
      reverseCurve: FluentCurve.accelerateMid,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Scroll behavior with no Material overscroll glow and no auto-scrollbar.
///
/// Fluent draws its own scrollbar in the UI packages; the framework default
/// would paint a second one on desktop and web.
class FluentScrollBehavior extends ScrollBehavior {
  /// Creates the default Fluent scroll behaviour.
  const FluentScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  // No `dragDevices` override. Adding PointerDeviceKind.mouse to the set — which
  // `PointerDeviceKind.values.toSet()` did — hands every mouse press to the
  // scrollable's drag recogniser, and a PRECISE pointer's drag slop is
  // `kPrecisePointerHitSlop`, which is ONE pixel. A real mouse click moves two
  // or three between press and release, so the drag won the arena, scrolled
  // nothing, and swallowed the tap: buttons, dropdown rows, switches and menu
  // items inside any scrolling page fired only on a pixel-perfect click.
  // The framework default is touch/stylus/trackpad — mouse scrolls with the
  // wheel, which is what a browser does.

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS =>
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        _ => const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
      };
}
