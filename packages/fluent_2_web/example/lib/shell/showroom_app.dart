import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import 'router.dart';
import 'showroom_scope.dart';
import 'theme_variants.dart';

/// The showroom: a Flutter rendering of the Fluent UI React Storybook.
class ShowroomApp extends StatefulWidget {
  /// Creates the app.
  const ShowroomApp({super.key});

  @override
  State<ShowroomApp> createState() => _ShowroomAppState();
}

class _ShowroomAppState extends State<ShowroomApp> {
  late final DocsRouterDelegate _delegate;
  late final PlatformRouteInformationProvider _provider;

  ThemeVariant _variant = ThemeVariant.webLight;
  TextDirection _textDirection = TextDirection.ltr;
  bool _grid = false;
  bool _background = true;
  bool _outlines = false;
  PreviewViewport _viewport = PreviewViewport.responsive;
  bool _locked = false;
  bool _fullScreen = false;
  bool _sidebarVisible = true;

  @override
  void initState() {
    super.initState();
    // On web this is the hash, stripped of its `#`, so a deep link works with
    // no server-side rewrite — which matters because GitHub Pages cannot do
    // one. Under `flutter test` it is `/`, which resolves to the first page.
    // No `kIsWeb` branch is needed anywhere.
    final Uri initial = Uri.parse(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    );
    _delegate = DocsRouterDelegate(DocsRoute.parse(initial));
    _provider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: initial),
    );
  }

  @override
  void dispose() {
    _delegate.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShowroomScope(
      variant: _variant,
      textDirection: _textDirection,
      grid: _grid,
      background: _background,
      outlines: _outlines,
      viewport: _viewport,
      locked: _locked,
      fullScreen: _fullScreen,
      sidebarVisible: _sidebarVisible,
      onVariantChanged: (ThemeVariant value) =>
          setState(() => _variant = value),
      onTextDirectionChanged: (TextDirection value) =>
          setState(() => _textDirection = value),
      onToggleGrid: () => setState(() => _grid = !_grid),
      onToggleBackground: () => setState(() => _background = !_background),
      onToggleOutlines: () => setState(() => _outlines = !_outlines),
      onViewportChanged: (PreviewViewport value) =>
          setState(() => _viewport = value),
      onToggleLocked: () => setState(() => _locked = !_locked),
      onToggleFullScreen: () => setState(() => _fullScreen = !_fullScreen),
      onToggleSidebar: () => setState(() => _sidebarVisible = !_sidebarVisible),
      child: FluentApp.router(
        title: 'Fluent UI Flutter v9',
        debugShowCheckedModeBanner: false,
        // The chrome is pinned light and never follows the Theme dropdown.
        // Storybook's own chrome does not change with the selected story theme
        // either, and more practically the sidebar has to stay readable while a
        // preview renders High Contrast.
        theme: FluentThemeData.light(),
        themeMode: FluentThemeMode.light,
        routeInformationProvider: _provider,
        routeInformationParser: const DocsRouteParser(),
        routerDelegate: _delegate,
      ),
    );
  }
}
