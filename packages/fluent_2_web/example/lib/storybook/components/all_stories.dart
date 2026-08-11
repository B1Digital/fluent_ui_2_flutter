import 'package:storybook_flutter/storybook_flutter.dart';

import '../theme_stories.dart';
import 'button_stories.dart';
import 'charts_showcase_stories.dart';
import 'charts_stories.dart';
import 'inputs_stories.dart';
import 'navigation_stories.dart';
import 'overlays_stories.dart';
import 'surfaces_stories.dart';

/// The full set of stories, ordered to match `crawlers/.../out/side-menu.md`:
/// Theme first, then Components grouped by category.
List<Story> get allStories => [
  ...themeStories,
  ...buttonStories,
  ...inputsStories,
  ...surfacesStories,
  ...navigationStories,
  ...overlaysStories,
  ...chartsStories,
  ...chartsShowcaseStories,
];
