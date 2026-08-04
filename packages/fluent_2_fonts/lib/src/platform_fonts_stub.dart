// ignore_for_file: public_member_api_docs

import 'font_models.dart';

FluentFontPlatform get currentFontPlatform => FluentFontPlatform.linux;

FluentFontFamilies fontFamiliesFor(FluentFontPlatform platform) =>
    switch (platform) {
      FluentFontPlatform.web || FluentFontPlatform.windows =>
        const FluentFontFamilies(text: 'Selawik', display: 'Selawik'),
      FluentFontPlatform.macOS ||
      FluentFontPlatform.iOS => const FluentFontFamilies(
        text: 'CupertinoSystemText',
        display: 'CupertinoSystemDisplay',
      ),
      FluentFontPlatform.android => const FluentFontFamilies(
        text: 'Roboto',
        display: 'Roboto',
      ),
      FluentFontPlatform.linux => const FluentFontFamilies(
        text: 'sans-serif',
        display: 'sans-serif',
      ),
    };

bool get requiresFontLoading => false;

bool get isFontLoaded => true;

Future<void> ensureFontLoaded() => Future<void>.value();
