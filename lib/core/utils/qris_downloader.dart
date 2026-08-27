import 'package:url_launcher/url_launcher.dart';

void downloadQris(String url, String fileName) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
