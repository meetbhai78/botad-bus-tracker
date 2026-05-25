import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Feature card with graceful offline image fallback.
/// When the network image fails or is loading, shows a solid color background
/// instead of a broken/grey tile (WARN-3 fix).
class FeatureCard extends StatefulWidget {
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
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    // hasImage is true only when a URL is provided AND it loaded successfully
    final bool hasImage = widget.bgImageUrl != null && !_imageError;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ── Layer 1: Always-visible fallback color background ──────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.15),
                        widget.color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // ── Layer 2: Network image (transparent until loaded) ──────────
              if (widget.bgImageUrl != null)
                Positioned.fill(
                  child: Image.network(
                    widget.bgImageUrl!,
                    fit: BoxFit.cover,
                    // While loading → show nothing (fallback color shows through)
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox.shrink();
                    },
                    // On error → mark failed so UI switches to fallback
                    errorBuilder: (_, __, ___) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _imageError = true);
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                ),

              // ── Layer 3: Dark scrim (only when image loaded successfully) ──
              if (hasImage)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),

              // ── Layer 4: Card content ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasImage
                            ? Colors.white.withValues(alpha: 0.25)
                            : widget.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: hasImage
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Icon(
                        widget.icon,
                        color: hasImage ? Colors.white : widget.color,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: hasImage ? Colors.white : AppColors.textPrimary,
                        shadows: hasImage
                            ? [const Shadow(color: Colors.black87, blurRadius: 4)]
                            : [],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasImage
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.textSecondary,
                        shadows: hasImage
                            ? [const Shadow(color: Colors.black87, blurRadius: 3)]
                            : [],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
