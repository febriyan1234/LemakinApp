import 'dart:html' as html;

class SafariRedirectHelper {
  static html.WindowBase? _windowRef;

  static bool isMobile() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod') ||
        userAgent.contains('android') ||
        userAgent.contains('webos') ||
        userAgent.contains('blackberry') ||
        userAgent.contains('iemobile') ||
        userAgent.contains('opera mini');
  }

  static String _convertToWhatsAppScheme(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host == 'wa.me' || uri.host == 'api.whatsapp.com') {
        // Extract phone number from path (e.g. /6283819309651)
        final phone = uri.path.replaceAll('/', '');
        final text = uri.queryParameters['text'];
        if (phone.isNotEmpty) {
          String newUrl = 'whatsapp://send?phone=$phone';
          if (text != null && text.isNotEmpty) {
            newUrl += '&text=${Uri.encodeComponent(text)}';
          }
          return newUrl;
        }
      }
    } catch (e) {
      print("Error converting to whatsapp scheme: $e");
    }
    return url;
  }

  static void openBlankWindow() {
    try {
      _windowRef = html.window.open('redirect.html', '_blank');
    } catch (e) {
      print("Failed to open redirect window: $e");
    }
  }

  static void redirectTo(String url) {
    String finalUrl = url;
    final bool mobile = isMobile();
    if (mobile) {
      finalUrl = _convertToWhatsAppScheme(url);
    }

    if (_windowRef != null) {
      try {
        _windowRef!.location.href = finalUrl;
        if (mobile) {
          // On mobile web, once we trigger the native app redirect,
          // we can close this blank redirect helper tab after a brief delay
          // so the user returns directly to the main app when they go back.
          Future.delayed(const Duration(milliseconds: 1500), () {
            closeWindow();
          });
        }
      } catch (e) {
        if (mobile) {
          html.window.location.href = finalUrl;
        } else {
          html.window.open(finalUrl, '_blank');
        }
      }
      if (!mobile) {
        _windowRef = null;
      }
    } else {
      if (mobile) {
        html.window.location.href = finalUrl;
      } else {
        html.window.open(finalUrl, '_blank');
      }
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
