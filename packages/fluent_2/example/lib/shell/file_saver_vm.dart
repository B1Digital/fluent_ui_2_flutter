import 'dart:typed_data';

/// The Dart VM has no browser download to start. The showroom is web-only, so
/// this only compiles the tests, which replace `saveFile` with a recorder.
void saveFile(Uint8List bytes, String fileName) {}
