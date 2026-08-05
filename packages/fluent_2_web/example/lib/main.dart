import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'storybook/components/all_stories.dart';
import 'storybook/fluent_wrapper.dart';

void main() {
  runApp(const StorybookApp());
}

/// Entry point for the Fluent 2 web storybook.
///
/// The outer [MaterialApp] only hosts `storybook_flutter`'s own chrome
/// (sidebar, bottom plugin bar and knob panel). Every individual story is
/// rendered inside a real Fluent app shell via [fluentWrapper].
class StorybookApp extends StatelessWidget {
  const StorybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluent 2 Storybook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F6CBD),
      ),
      home: Storybook(
        stories: allStories,
        wrapperBuilder: fluentWrapper,
        initialStory: 'Theme/Colors',
      ),
    );
  }
}
