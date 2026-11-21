import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service managing AdMob ads (Rewarded, Interstitial, and Banners).
///
/// Monetizes the app while keeping 100% of features free for all users.
class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;

  // Standard Google AdMob test IDs for Android.
  // Replace these with your production AdMob Unit IDs before release:
  // https://apps.admob.com/
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static String get bannerAdUnitId => testBannerId;
  static String get interstitialAdUnitId => testInterstitialId;
  static String get rewardedAdUnitId => testRewardedId;

  /// Initialize AdMob SDK and preload initial ads.
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      loadRewardedAd();
      loadInterstitialAd();
      debugPrint('[AdService] MobileAds initialized successfully');
    } catch (e) {
      debugPrint('[AdService] Failed to initialize MobileAds: $e');
    }
  }

  /// Preload a Rewarded Ad so it's ready when user requests it.
  void loadRewardedAd() {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          debugPrint('[AdService] Rewarded ad loaded');
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              debugPrint('[AdService] Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  /// Preload an Interstitial Ad.
  void loadInterstitialAd() {
    if (_isInterstitialAdLoading || _interstitialAd != null) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          debugPrint('[AdService] Interstitial ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  /// Show a rewarded ad. If not ready, calls [onRewardEarned] gracefully so user is never blocked.
  Future<void> showRewardedAd({required VoidCallback onRewardEarned}) async {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned();
        },
      );
    } else {
      onRewardEarned();
      loadRewardedAd();
    }
  }

  /// Show an interstitial ad if ready. Always invokes [onComplete].
  Future<void> showInterstitialAd({VoidCallback? onComplete}) async {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onComplete?.call();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          debugPrint('[AdService] Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onComplete?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      onComplete?.call();
      loadInterstitialAd();
    }
  }
}
