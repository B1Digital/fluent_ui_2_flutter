import 'package:flutter/widgets.dart';

import '../chrome/legend.dart';

/// A live legend, as the export strip that replaces it needs to see it.
///
/// Upstream never photographs the live legend: `cloneStyledSVG` keeps only the
/// chart's first `<svg>` (`image-export-utils.ts:156`) and `cloneLegendsToSVG`
/// redraws EVERY legend beneath it (`:280-393`), so the "+N more" overflow a
/// narrow screen shows is never what the image carries.
typedef FluentChartExportLegend = ({
  RenderBox box,
  List<FluentChartLegendItem> legends,
  Set<String> selectedLegends,
  bool centerLegends,
  bool isRtl,
  TextStyle textStyle,
});

/// A scroll viewport, and the key of the boundary round its whole content.
///
/// `isRtl` because a horizontal scroll view anchors its content at the
/// viewport's right edge under right-to-left, not its left.
typedef FluentChartExportViewport = ({
  RenderBox box,
  GlobalKey content,
  bool isRtl,
});

/// What the charts inside an exported figure tell the exporter it cannot see
/// in a snapshot: the legend it must redraw in full, and the scroll viewports
/// whose whole content it must draw instead of their visible window.
///
/// Each entry is keyed by the [State] that registered it, so a registrant only
/// ever removes its own entry, and is read through a callback at export time so
/// the selection and geometry are the live ones.
class FluentChartExportRegistry {
  /// Registered legends.
  final Map<Object, FluentChartExportLegend Function()> legends =
      <Object, FluentChartExportLegend Function()>{};

  /// Registered scroll viewports.
  final Map<Object, FluentChartExportViewport Function()> viewports =
      <Object, FluentChartExportViewport Function()>{};
}

/// Hands a [FluentChartExportRegistry] to the charts below it.
class FluentChartExportScope extends InheritedWidget {
  /// Creates an export scope.
  const FluentChartExportScope({
    required this.registry,
    required super.child,
    super.key,
  });

  /// The registry the charts below register with.
  final FluentChartExportRegistry registry;

  /// The nearest registry, or null outside an exported figure.
  static FluentChartExportRegistry? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentChartExportScope>()
      ?.registry;

  @override
  bool updateShouldNotify(FluentChartExportScope oldWidget) =>
      !identical(registry, oldWidget.registry);
}

/// A scroll viewport whose export shows its whole [content], not its window.
///
/// [viewportBuilder] receives [content] wrapped in a [RepaintBoundary] and
/// returns the scroll views round it. A scroll view paints its whole child into
/// that child's layer and only clips above it, so the boundary holds every row
/// and column at full size wherever the viewport is scrolled — the same reason
/// `sankey_chart.dart` puts its own export boundary inside its scroller.
class FluentChartExportViewportHost extends StatefulWidget {
  /// Creates a viewport host.
  const FluentChartExportViewportHost({
    required this.content,
    required this.viewportBuilder,
    super.key,
  });

  /// The full content the viewport scrolls over.
  final Widget content;

  /// Builds the scroll views round the boundary-wrapped [content].
  final Widget Function(Widget content) viewportBuilder;

  @override
  State<FluentChartExportViewportHost> createState() =>
      _FluentChartExportViewportHostState();
}

class _FluentChartExportViewportHostState
    extends State<FluentChartExportViewportHost> {
  final GlobalKey _contentKey = GlobalKey();
  FluentChartExportRegistry? _registry;

  @override
  void dispose() {
    _registry?.viewports.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = FluentChartExportScope.maybeOf(context);
    if (!identical(registry, _registry)) {
      _registry?.viewports.remove(this);
      _registry = registry;
    }
    final isRtl = Directionality.maybeOf(context) == TextDirection.rtl;
    registry?.viewports[this] = () => (
      box: context.findRenderObject()! as RenderBox,
      content: _contentKey,
      isRtl: isRtl,
    );
    return widget.viewportBuilder(
      RepaintBoundary(key: _contentKey, child: widget.content),
    );
  }
}
