import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../../pages.dart';
import '../catalog.dart';
import '../docs_metrics.dart';
import '../rtl_scope.dart';
import '../showroom_scope.dart';

/// One story, full-bleed and chrome-free.
///
/// This is what a preview card's "Open in new tab" opens. Storybook's own
/// version of that button loads the story in an isolated iframe; this is the
/// same idea addressed by route instead, which is what makes the button
/// something real rather than decoration.
class StoryCanvas extends StatelessWidget {
  /// Renders the section with id [storyId].
  const StoryCanvas({super.key, required this.storyId});

  /// The section to render.
  final String storyId;

  @override
  Widget build(BuildContext context) {
    final ({DocsPage page, DocsSection section})? found = sectionById(storyId);
    if (found == null) {
      return ColoredBox(
        color: DocsMetrics.canvas,
        child: Center(
          child: Text('No story "$storyId".', style: DocsMetrics.body),
        ),
      );
    }

    final ShowroomScope scope = ShowroomScope.of(context);
    final FluentThemeData data = scope.variant.data;

    return FluentTheme(
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
            child: ColoredBox(
              color: data.colors.neutralBackground1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: found.section.builder(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
