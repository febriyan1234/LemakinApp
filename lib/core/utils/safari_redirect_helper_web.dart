import 'dart:html' as html;

class SafariRedirectHelper {
  static html.WindowBase? _windowRef;

  static void openBlankWindow() {
    try {
      _windowRef = html.window.open('redirect.html', '_blank');
    } catch (e) {
      print("Failed to open redirect window: $e");
    }
  }

  static void redirectTo(String url) {
    if (_windowRef != null) {
      try {
        _windowRef!.location.href = url;
      } catch (e) {
        // Fallback: if browser blocks the location change, try opening directly
        html.window.open(url, '_blank');
      }
      _windowRef = null;
    } else {
      // Fallback
      html.window.open(url, '_blank');
    }
  }

  static void closeWindow() {
    if (_windowRef != null) {
      try {
        _windowRef!.close();
      } catch (_) {}
      _windowRef = null;
    }
  }
}
