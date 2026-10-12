import 'package:flutter/material.dart';

Widget buildStreetViewIframe({
  required String url,
  required String viewId,
}) {
  return Container(
    color: const Color(0xff18221f),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public, size: 48, color: Colors.white70),
          const SizedBox(height: 12),
          const Text(
            'Google Street View веб-шолғышта қолжетімді',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

void openExternalUrl(String url) {}

