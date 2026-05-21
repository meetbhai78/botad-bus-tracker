import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.bgImageUrl,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? bgImageUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: bgImageUrl == null ? color.withValues(alpha: 0.1) : Colors.transparent,
            image: bgImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(bgImageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.45),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgImageUrl != null
                        ? Colors.white.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: bgImageUrl != null
                        ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                        : null,
                  ),
                  child: Icon(icon, color: bgImageUrl != null ? Colors.white : color, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: bgImageUrl != null ? Colors.white : AppColors.textPrimary,
                    shadows: bgImageUrl != null ? [const Shadow(color: Colors.black87, blurRadius: 4)] : [],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: bgImageUrl != null ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondary,
                    shadows: bgImageUrl != null ? [const Shadow(color: Colors.black87, blurRadius: 3)] : [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
