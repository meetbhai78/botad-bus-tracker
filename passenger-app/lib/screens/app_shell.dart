import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'find_bus_screen.dart';
import 'more_screen.dart';
import '../services/update_service.dart';
import '../services/ad_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
      // Trigger Startup Rewarded/Interstitial Video Ad
      AdService.showRewardedVideo(
        onComplete: () {
          debugPrint('Startup Video Ad completed/skipped.');
        },
      );
    });
  }

  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onNavigateTab: goToTab),
          const FindBusScreen(embedded: true),
          const MapScreen(embedded: true),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdService.getBannerAd(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_bus_outlined),
                selectedIcon: Icon(Icons.directions_bus_rounded),
                label: 'Find bus',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Live map',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'More',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
