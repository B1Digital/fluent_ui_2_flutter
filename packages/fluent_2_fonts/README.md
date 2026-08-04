# fluent_2_fonts

Platform font facade for Fluent 2 Flutter packages. Each platform descriptor is
published as a separate package:

- `fluent_2_fonts_web` — dynamically loaded Selawik, bundled only on Web
- `fluent_2_fonts_windows` — dynamically loaded Selawik, bundled only on Windows
- `fluent_2_fonts_macos` — native San Francisco system-family descriptors
- `fluent_2_fonts_ios` — native San Francisco system-family descriptors
- `fluent_2_fonts_android` — native Roboto family descriptor

The Web and Windows packages intentionally own separate copies of Selawik.
Flutter 3.41's platform-specific asset filtering ensures that a target includes
only its own copy. Mobile and macOS builds include no Selawik files.

The facade uses a Dart conditional import to compile the Web loader only for
Web and the native implementation only for native builds. Dart has no
compile-time conditions for individual native operating systems, so native
font binaries are selected by Flutter's `platforms` asset metadata instead.
The facade does not re-export the implementation packages; consumers and core
use one stable `FluentFonts` API.

`FluentApp` loads the required family automatically. Applications that need the
font before constructing their root widget can preload it explicitly:

```dart
WidgetsFlutterBinding.ensureInitialized();
await FluentFonts.ensureLoaded();
runApp(const FluentApp(home: Home()));
```

Flutter can tree-shake statically referenced icon glyphs, but ordinary text can
arrive dynamically at runtime. The text faces therefore remain intact; only the
three weights used by Fluent's Web and Windows ramps are bundled automatically.
