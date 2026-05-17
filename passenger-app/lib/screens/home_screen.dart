import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../widgets/feature_card.dart';
import 'nearby_stations_screen.dart';
import 'timetable_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigateTab});

  final void Function(int tabIndex) onNavigateTab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(),
                  const SizedBox(height: 28),
                  Text(
                    'Botad city bus',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stop choose karein → route ki bus dekhein → live location track karein.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  _FindBusBanner(onTap: () => onNavigateTab(1)),
                  const SizedBox(height: 24),
                  const Text(
                    'More options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildListDelegate([
                FeatureCard(
                  icon: Icons.search_rounded,
                  title: 'Find bus',
                  subtitle: 'Stops & route search',
                  color: AppColors.primary,
                  onTap: () => onNavigateTab(1),
                ),
                FeatureCard(
                  icon: Icons.near_me_rounded,
                  title: 'All stops',
                  subtitle: 'Browse & search list',
                  color: AppColors.accent,
                  onTap: () => _push(context, const NearbyStationsScreen()),
                ),
                FeatureCard(
                  icon: Icons.schedule_rounded,
                  title: 'Timetable',
                  subtitle: 'Admin schedule',
                  color: const Color(0xFF6366F1),
                  onTap: () => _push(context, const TimetableScreen()),
                ),
                FeatureCard(
                  icon: Icons.map_rounded,
                  title: 'Live map',
                  subtitle: 'All active buses',
                  color: const Color(0xFFEC4899),
                  onTap: () => onNavigateTab(2),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _FindBusBanner extends StatelessWidget {
  const _FindBusBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Find your bus',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap stop → search → track live',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
