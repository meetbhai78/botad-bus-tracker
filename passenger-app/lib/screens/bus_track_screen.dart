import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'map_screen.dart';

/// Full-screen live tracking for one bus after user picks it from route results.
class BusTrackScreen extends StatelessWidget {
  const BusTrackScreen({
    super.key,
    required this.busId,
    required this.busName,
    required this.busNumber,
    required this.routeName,
    required this.fromStop,
    required this.toStop,
  });

  final String busId;
  final String busName;
  final String busNumber;
  final String routeName;
  final String fromStop;
  final String toStop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(busName, style: const TextStyle(fontSize: 17)),
            Text(busNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MapScreen(embedded: true, targetBusId: busId),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE TRACKING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(routeName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$fromStop → $toStop',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Map par bus ki current location dikhegi jab driver trip start kare.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
