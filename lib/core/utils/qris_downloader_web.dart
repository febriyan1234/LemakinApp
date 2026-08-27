import 'dart:html' as html;

void downloadQris(String url, String fileName) {
  html.HttpRequest.request(url, responseType: 'blob').then((xhr) {
    final blob = xhr.response as html.Blob;
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: blobUrl)
      ..setAttribute("download", fileName)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(blobUrl);
  }).catchError((e) {
    html.window.open(url, '_blank');
  });
}
