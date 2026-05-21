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
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1570125909232-eb263c188f7e?q=80&w=2000&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      AppColors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLogo(),
                    const Spacer(),
                    const Text(
                      'Welcome to',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Botad Smart Bus',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Search routes, view timetables, and track buses live.',
                      style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: _FindBusBanner(onTap: () => onNavigateTab(1)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Explore Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate([
                FeatureCard(
                  icon: Icons.search_rounded,
                  title: 'Find Bus',
                  subtitle: 'Search routes & stops',
                  color: AppColors.primary,
                  bgImageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=800&auto=format&fit=crop',
                  onTap: () => onNavigateTab(1),
                ),
                FeatureCard(
                  icon: Icons.map_rounded,
                  title: 'Live Map',
                  subtitle: 'Track active buses',
                  color: const Color(0xFFEC4899),
                  bgImageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=800&auto=format&fit=crop',
                  onTap: () => onNavigateTab(2),
                ),
                FeatureCard(
                  icon: Icons.schedule_rounded,
                  title: 'Timetable',
                  subtitle: 'View schedules',
                  color: const Color(0xFF6366F1),
                  bgImageUrl: 'https://images.unsplash.com/photo-1501139083538-0139583c060f?q=80&w=800&auto=format&fit=crop',
                  onTap: () => _push(context, const TimetableScreen()),
                ),
                FeatureCard(
                  icon: Icons.near_me_rounded,
                  title: 'All Stops',
                  subtitle: 'Browse locations',
                  color: AppColors.accent,
                  bgImageUrl: 'https://images.unsplash.com/photo-1515155075601-23009d0cb6d4?q=80&w=800&auto=format&fit=crop',
                  onTap: () => _push(context, const NearbyStationsScreen()),
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
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: const NetworkImage('https://images.unsplash.com/photo-1494515843206-f3117d3f51b7?q=80&w=1000&auto=format&fit=crop'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                AppColors.primaryDark.withValues(alpha: 0.85),
                BlendMode.srcOver,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Where to?',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to search buses for your route',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
