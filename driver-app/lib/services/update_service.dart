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
          final int latestBuildNumber = data['latestBuildNumber'] ?? 1;
          final String latestVersionName = data['latestVersion'] ?? '1.0.0';
          final String updateMessage = data['updateMessage'] ?? 'Naya update available hai!';
          final String updateUrl = data['updateUrl'] ?? 'https://botad-bus-tracker.onrender.com';
          final bool mandatory = data['mandatoryUpdate'] ?? false;

          final packageInfo = await PackageInfo.fromPlatform();
          final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

          if (latestBuildNumber > currentBuildNumber) {
            if (context.mounted) {
              _showUpdateDialog(context, latestVersionName, updateMessage, updateUrl, mandatory);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String latestVersion,
    String message,
    String downloadUrl,
    bool mandatory,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !mandatory,
      builder: (BuildContext context) {
        return PopScope(
          canPop: !mandatory,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: Color(0xFF0D9488),
                size: 40,
              ),
            ),
            title: const Text(
              '📣 Naya Update Available Hai!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Version: $latestVersion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (!mandatory)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'LATER',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  elevation: 0,
                ),
                onPressed: () async {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download link open nahi ho saki!')),
                      );
                    }
                  }
                },
                child: const Text(
                  'UPDATE NOW',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
