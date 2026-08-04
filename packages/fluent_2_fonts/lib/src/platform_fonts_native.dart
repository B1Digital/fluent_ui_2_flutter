// ignore_for_file: public_member_api_docs

import 'package:fluent_2_fonts_android/fluent_2_fonts_android.dart';
import 'package:fluent_2_fonts_ios/fluent_2_fonts_ios.dart';
import 'package:fluent_2_fonts_macos/fluent_2_fonts_macos.dart';
import 'package:fluent_2_fonts_windows/fluent_2_fonts_windows.dart';
import 'package:flutter/foundation.dart';

import 'font_models.dart';

FluentFontPlatform get currentFontPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.windows => FluentFontPlatform.windows,
  TargetPlatform.macOS => FluentFontPlatform.macOS,
  TargetPlatform.iOS => FluentFontPlatform.iOS,
  TargetPlatform.android ||
  TargetPlatform.fuchsia => FluentFontPlatform.android,
  TargetPlatform.linux => FluentFontPlatform.linux,
};

FluentFontFamilies fontFamiliesFor(FluentFontPlatform platform) =>
    switch (platform) {
      FluentFontPlatform.web ||
      FluentFontPlatform.windows => const FluentFontFamilies(
        text: FluentWindowsFonts.family,
        display: FluentWindowsFonts.family,
      ),
      FluentFontPlatform.macOS => const FluentFontFamilies(
        text: FluentMacOSFonts.textFamily,
        display: FluentMacOSFonts.displayFamily,
      ),
      FluentFontPlatform.iOS => const FluentFontFamilies(
        text: FluentIOSFonts.textFamily,
        display: FluentIOSFonts.displayFamily,
      ),
      FluentFontPlatform.android => const FluentFontFamilies(
        text: FluentAndroidFonts.family,
        display: FluentAndroidFonts.family,
      ),
      FluentFontPlatform.linux => const FluentFontFamilies(
        text: 'sans-serif',
        display: 'sans-serif',
      ),
    };

bool get requiresFontLoading =>
    currentFontPlatform == FluentFontPlatform.windows;

bool get isFontLoaded => !requiresFontLoading || FluentWindowsFonts.isLoaded;

Future<void> ensureFontLoaded() => requiresFontLoading
    ? FluentWindowsFonts.ensureLoaded()
    : Future<void>.value();
