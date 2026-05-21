import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';

class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/config/app-version'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final latestBuild = data['latestBuildNumber'] as int;
          final mandatory = data['mandatoryUpdate'] == true;
          final updateMessage = data['updateMessage']?.toString() ?? 'A new update is available!';
          final updateUrl = data['updateUrl']?.toString() ?? '';

          final packageInfo = await PackageInfo.fromPlatform();
          final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

          if (latestBuild > currentBuild) {
            if (!context.mounted) return;
            _showUpdateDialog(context, updateMessage, updateUrl, mandatory);
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context, String message, String url, bool mandatory) {
    showDialog(
      context: context,
      barrierDismissible: !mandatory,
      builder: (context) => PopScope(
        canPop: !mandatory,
        child: AlertDialog(
          title: const Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            if (!mandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
              ),
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }
}
