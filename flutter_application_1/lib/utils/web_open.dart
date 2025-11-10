// Conditional export: use dart:html implementation on web, stub elsewhere
export 'web_open_stub.dart' if (dart.library.html) 'web_open_html.dart';
