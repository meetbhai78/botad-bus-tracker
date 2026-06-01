import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class EmergencyAlert {
  final bool active;
  final String message;
  final String updatedAt;

  EmergencyAlert({
    required this.active,
    required this.message,
    required this.updatedAt,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      active: json['active'] ?? false,
      message: json['message'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class AlertService {
  static const String _prefKey = 'last_seen_alert_time';

  static Future<EmergencyAlert?> fetchAlert() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/config/emergency-alert'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EmergencyAlert.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching emergency alert: $e');
    }
    return null;
  }

  static Future<bool> hasUnseenAlert(EmergencyAlert alert) async {
    if (!alert.active) return false;
    final prefs = await SharedPreferences.getInstance();
    final String? lastSeenTime = prefs.getString(_prefKey);
    return lastSeenTime != alert.updatedAt;
  }

  static Future<void> acknowledgeAlert(EmergencyAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, alert.updatedAt);
  }
}
