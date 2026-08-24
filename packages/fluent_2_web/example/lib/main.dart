import 'package:flutter/widgets.dart';

import 'shell/showroom_app.dart';

/// Entry point for the Fluent 2 showroom.
///
/// Must stay at `lib/main.dart`: the GitHub Pages workflow runs
/// `flutter build web` from this directory and relies on the default target.
void main() {
  runApp(const ShowroomApp());
}
