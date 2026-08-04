// ignore_for_file: public_member_api_docs

import 'package:fluent_2_fonts_web/fluent_2_fonts_web.dart';

import 'font_models.dart';

FluentFontPlatform get currentFontPlatform => FluentFontPlatform.web;

FluentFontFamilies fontFamiliesFor(FluentFontPlatform platform) =>
    switch (platform) {
      FluentFontPlatform.web ||
      FluentFontPlatform.windows => const FluentFontFamilies(
        text: FluentWebFonts.family,
        display: FluentWebFonts.family,
      ),
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

bool get requiresFontLoading => true;

bool get isFontLoaded => FluentWebFonts.isLoaded;

Future<void> ensureFontLoaded() => FluentWebFonts.ensureLoaded();
