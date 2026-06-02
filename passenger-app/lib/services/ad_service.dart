import 'package:flutter/material.dart';
import 'package:startapp_sdk/startapp.dart';

class AdService {
  static final sdk = StartAppSdk();
  
  // Session Capping: Max 3 video ads per app use (per session)
  static int _sessionVideoAdCount = 0;
  static const int maxVideoAdsPerSession = 3;

  /// Returns whether we can show another video ad in the current session
  static bool get canShowVideoAd => _sessionVideoAdCount < maxVideoAdsPerSession;

  /// Increments the session video ad count
  static void incrementVideoAdCount() {
    _sessionVideoAdCount++;
    debugPrint('Video ad displayed. Session video ad count: $_sessionVideoAdCount');
  }

  /// Helper to get a beautiful Banner Ad widget (uncapped)
  static Widget getBannerAd() {
    return const StartAppBannerWidget();
  }

  /// Loads and displays a Rewarded Video Ad with automated capping and callbacks.
  /// If the cap is reached or loading fails, it instantly runs the callback to bypass.
  static void showRewardedVideo({
    required VoidCallback onComplete,
  }) {
    if (!canShowVideoAd) {
      debugPrint('Video ad cap reached ($_sessionVideoAdCount/$maxVideoAdsPerSession). Bypassing rewarded video.');
      onComplete();
      return;
    }

    debugPrint('Loading Start.io Rewarded Video Ad...');
    sdk.loadRewardedVideoAd(
      onAdDisplayed: () {
        debugPrint('Start.io Rewarded Video displayed.');
        incrementVideoAdCount();
      },
      onAdNotDisplayed: () {
        debugPrint('Start.io Rewarded Video failed to display.');
        onComplete();
      },
      onAdHidden: () {
        debugPrint('Start.io Rewarded Video closed.');
        onComplete();
      },
      onVideoCompleted: () {
        debugPrint('Start.io Rewarded Video completed.');
      },
      onAdClicked: () {
        debugPrint('Start.io Rewarded Video clicked.');
      },
    ).then((ad) {
      ad.show().then((shown) {
        if (!shown) {
          debugPrint('Failed to show loaded rewarded video ad.');
          onComplete();
        }
      }).catchError((err) {
        debugPrint('Error showing rewarded video ad: $err');
        onComplete();
      });
    }).catchError((err) {
      debugPrint('Failed to load rewarded video ad: $err');
      onComplete();
    });
  }
}

/// A self-contained stateful widget to load and display the banner ad safely (uncapped)
class StartAppBannerWidget extends StatefulWidget {
  const StartAppBannerWidget({super.key});

  @override
  State<StartAppBannerWidget> createState() => _StartAppBannerWidgetState();
}

class _StartAppBannerWidgetState extends State<StartAppBannerWidget> {
  StartAppBannerAd? _bannerAd;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    AdService.sdk.loadBannerAd(
      StartAppBannerType.BANNER,
      onAdImpression: () {
        debugPrint('Banner impression recorded.');
      },
      onAdClicked: () {
        debugPrint('Banner clicked.');
      },
    ).then((ad) {
      if (mounted) {
        setState(() {
          _bannerAd = ad;
        });
      }
    }).catchError((err) {
      debugPrint('Failed to load banner ad: $err');
      if (mounted) {
        setState(() {
          _failed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: StartAppBanner(_bannerAd!),
    );
  }
}
