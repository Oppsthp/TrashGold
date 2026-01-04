import 'package:flutter/material.dart';
import '../screens/QrScanScreen.dart';

class QrScannerService {
  static Future<String?> scan(BuildContext context) async {
    final code = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );

    if (code == null || code.trim().isEmpty) return null;
    return code.trim();
  }
}
