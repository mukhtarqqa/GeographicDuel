import 'package:flutter/material.dart';
import 'street_view_iframe_stub.dart'
    if (dart.library.html) 'street_view_iframe_web.dart' as platform;

class StreetViewIframe extends StatelessWidget {
  const StreetViewIframe({
    super.key,
    required this.url,
    required this.viewId,
  });

  final String url;
  final String viewId;

  @override
  Widget build(BuildContext context) {
    return platform.buildStreetViewIframe(
      url: url,
      viewId: viewId,
    );
  }
}

void openExternalUrl(String url) => platform.openExternalUrl(url);
